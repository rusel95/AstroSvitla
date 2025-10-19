import Foundation
import OpenAI

struct OpenAIService {

    private let clientProvider: OpenAIClientProviding
    private let promptBuilder: AIPromptBuilder
    private let jsonDecoder: JSONDecoder

    init(
        clientProvider: OpenAIClientProviding = OpenAIClientProvider.shared,
        promptBuilder: AIPromptBuilder = AIPromptBuilder(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.clientProvider = clientProvider
        self.promptBuilder = promptBuilder
        self.jsonDecoder = jsonDecoder
    }

    var isConfigured: Bool {
        clientProvider.client != nil
    }

    func generateReport(
        for area: ReportArea,
        birthDetails: BirthDetails,
        natalChart: NatalChart,
        knowledgeSnippets: [String],
        languageCode: String,
        languageDisplayName: String,
        repositoryContext: String,
        selectedModel: AppPreferences.OpenAIModel
    ) async throws -> GeneratedReport {
        guard let client = clientProvider.client else {
            throw ReportGenerationError.missingAPIKey
        }

        let prompt = promptBuilder.makePrompt(
            for: area,
            birthDetails: birthDetails,
            natalChart: natalChart,
            knowledgeSnippets: knowledgeSnippets,
            languageCode: languageCode,
            languageDisplayName: languageDisplayName,
            repositoryContext: repositoryContext
        )
        let query = makeChatQuery(systemPrompt: prompt.system, userPrompt: prompt.user, model: selectedModel)

        let maxAttempts = 3
        var lastError: ReportGenerationError?
        let startTime = Date()

        for attempt in 0..<maxAttempts {
            do {
                let (payload, usage) = try await performRequest(client: client, query: query)
                logUsage(usage)
                let processingTime = Date().timeIntervalSince(startTime)

                let fallbackNotes = knowledgeSnippets.isEmpty ? "Фрагменти знань не знайдені" : nil
                let usagePayload = payload.knowledgeUsage ?? OpenAIReportPayload.KnowledgeUsagePayload(vectorSourceUsed: knowledgeSnippets.isEmpty == false, notes: fallbackNotes, sources: nil, availableBooks: nil)

                let sources = usagePayload.sources?.map { sourcePayload in
                    KnowledgeSource(
                        bookTitle: sourcePayload.bookTitle,
                        author: sourcePayload.author,
                        section: sourcePayload.section,
                        pageRange: sourcePayload.pageRange,
                        snippet: sourcePayload.snippet,
                        relevanceScore: sourcePayload.relevanceScore,
                        chunkId: sourcePayload.chunkId
                    )
                }

                let availableBooks = usagePayload.availableBooks?.map { bookPayload in
                    BookMetadata(
                        bookTitle: bookPayload.bookTitle,
                        author: bookPayload.author,
                        totalChunks: bookPayload.totalChunks,
                        usedChunks: bookPayload.usedChunks,
                        availableChunks: bookPayload.availableChunks.map { chunkPayload in
                            ChunkOption(
                                chunkId: chunkPayload.chunkId,
                                section: chunkPayload.section,
                                pageRange: chunkPayload.pageRange,
                                preview: chunkPayload.preview,
                                fullText: chunkPayload.fullText,
                                wasUsed: chunkPayload.wasUsed
                            )
                        }
                    )
                }

                // Calculate metadata
                let totalSourcesCited = sources?.count ?? 0
                let vectorDBSourcesCount = sources?.filter { $0.isFromVectorDatabase }.count ?? 0
                let externalSourcesCount = totalSourcesCited - vectorDBSourcesCount

                let metadata = GenerationMetadata(
                    modelName: query.model,
                    promptTokens: usage?.promptTokens ?? 0,
                    completionTokens: usage?.completionTokens ?? 0,
                    totalTokens: usage?.totalTokens ?? 0,
                    estimatedCost: Double(usage?.totalTokens ?? 0) / 1000.0 * selectedModel.estimatedCostPer1000Tokens,
                    generationDate: Date(),
                    processingTimeSeconds: processingTime,
                    knowledgeSnippetsProvided: knowledgeSnippets.count,
                    totalSourcesCited: totalSourcesCited,
                    vectorDatabaseSourcesCount: vectorDBSourcesCount,
                    externalSourcesCount: externalSourcesCount
                )

                return GeneratedReport(
                    area: area,
                    summary: payload.summary,
                    keyInfluences: payload.keyInfluences,
                    detailedAnalysis: payload.detailedAnalysis,
                    recommendations: payload.recommendations,
                    knowledgeUsage: KnowledgeUsage(
                        vectorSourceUsed: usagePayload.vectorSourceUsed,
                        notes: usagePayload.notes,
                        sources: sources,
                        availableBooks: availableBooks
                    ),
                    metadata: metadata
                )
            } catch let error as ReportGenerationError {
                lastError = error
                if attempt < maxAttempts - 1 && shouldRetry(after: error) {
                    let backoff = pow(2.0, Double(attempt)) * 0.75
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    throw error
                }
            }
        }

        throw lastError ?? ReportGenerationError.invalidResponse
    }

    // MARK: - Helpers

    private func performRequest(client: OpenAI, query: ChatQuery) async throws -> (OpenAIReportPayload, ChatResult.CompletionUsage?) {
        do {
            let result = try await client.chats(query: query)
            guard let text = extractContent(from: result) else {
                throw ReportGenerationError.noContent
            }
            let payload = try decodePayload(from: text)
            return (payload, result.usage)
        } catch is CancellationError {
            throw ReportGenerationError.cancelled
        } catch let apiError as APIErrorResponse {
            throw mapAPIError(apiError.error)
        } catch let openAIError as OpenAIError {
            throw mapOpenAIError(openAIError)
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch let decodingError as DecodingError {
            #if DEBUG
            debugPrint("🔎 OpenAIService decoding error: \(decodingError)")
            #endif
            throw ReportGenerationError.invalidResponse
        } catch let error as ReportGenerationError {
            throw error
        } catch {
            #if DEBUG
            debugPrint("⚠️ OpenAIService unexpected error: \(error)")
            #endif
            throw ReportGenerationError.network(underlying: error)
        }
    }

    private func makeChatQuery(systemPrompt: String, userPrompt: String, model: AppPreferences.OpenAIModel) -> ChatQuery {
        let systemMessage = ChatQuery.ChatCompletionMessageParam.system(
            .init(content: .textContent(systemPrompt))
        )
        let userMessage = ChatQuery.ChatCompletionMessageParam.user(
            .init(content: .string(userPrompt))
        )

        // Use 10000 or model's max, whichever is smaller
        let maxTokens = min(10000, model.maxTokens)

        return ChatQuery(
            messages: [systemMessage, userMessage],
            model: model.rawValue,
            maxCompletionTokens: maxTokens,
            responseFormat: .jsonObject,
            temperature: 0.7,
            topP: 0.9
        )
    }

    private func extractContent(from result: ChatResult) -> String? {
        for choice in result.choices {
            if let content = choice.message.content, content.isEmpty == false {
                return content
            }
            if let toolCalls = choice.message.toolCalls, toolCalls.isEmpty == false {
                continue
            }
        }
        return nil
    }

    private func decodePayload(from text: String) throws -> OpenAIReportPayload {
        let cleaned = sanitize(jsonString: text)
        guard let data = cleaned.data(using: .utf8) else {
            throw ReportGenerationError.invalidResponse
        }
        return try jsonDecoder.decode(OpenAIReportPayload.self, from: data)
    }

    private func sanitize(jsonString: String) -> String {
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutBackticks = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "`")).trimmingCharacters(in: .whitespacesAndNewlines)

        if withoutBackticks.hasPrefix("{") && withoutBackticks.hasSuffix("}") {
            return withoutBackticks
        }

        guard let opening = withoutBackticks.firstIndex(of: "{"),
              let closing = withoutBackticks.lastIndex(of: "}") else {
            return withoutBackticks
        }

        return String(withoutBackticks[opening...closing])
    }

    private func logUsage(_ usage: ChatResult.CompletionUsage?) {
        #if DEBUG
        guard Config.debugLoggingEnabled, let usage else { return }
        let promptTokens = usage.promptTokens
        let completionTokens = usage.completionTokens
        let totalTokens = usage.totalTokens
        let estimatedCost = Double(totalTokens) / 1000.0 * 0.0007
        debugPrint("ℹ️ OpenAI usage — prompt: \(promptTokens) tokens, completion: \(completionTokens) tokens, total: \(totalTokens), est. cost $\(String(format: "%.6f", estimatedCost))")
        #endif
    }

    private func mapAPIError(_ error: APIError) -> ReportGenerationError {
        switch error.code {
        case "rate_limit_exceeded":
            return .rateLimited
        case "server_error", "service_unavailable":
            return .serviceUnavailable
        default:
            return .network(underlying: error)
        }
    }

    private func mapOpenAIError(_ error: OpenAIError) -> ReportGenerationError {
        switch error {
        case .emptyData:
            return .noContent
        case .statusError(_, let statusCode):
            switch statusCode {
            case 401:
                return .missingAPIKey
            case 429:
                return .rateLimited
            case 500...599:
                return .serviceUnavailable
            default:
                return .network(underlying: error)
            }
        }
    }

    private func mapURLError(_ error: URLError) -> ReportGenerationError {
        switch error.code {
        case .timedOut, .cannotFindHost, .cannotConnectToHost:
            return .serviceUnavailable
        case .notConnectedToInternet:
            return .network(underlying: error)
        case .cancelled:
            return .cancelled
        default:
            return .network(underlying: error)
        }
    }

    private func shouldRetry(after error: ReportGenerationError) -> Bool {
        switch error {
        case .rateLimited, .serviceUnavailable:
            return true
        case .network:
            return true
        default:
            return false
        }
    }
}

private struct OpenAIReportPayload: Decodable {
    let summary: String
    let keyInfluences: [String]
    let detailedAnalysis: String
    let recommendations: [String]
    let knowledgeUsage: KnowledgeUsagePayload?

    private enum CodingKeys: String, CodingKey {
        case summary
        case keyInfluences = "key_influences"
        case detailedAnalysis = "detailed_analysis"
        case recommendations
        case knowledgeUsage = "knowledge_usage"
    }

    struct KnowledgeUsagePayload: Decodable {
        let vectorSourceUsed: Bool
        let notes: String?
        let sources: [KnowledgeSourcePayload]?
        let availableBooks: [BookMetadataPayload]?

        private enum CodingKeys: String, CodingKey {
            case vectorSourceUsed = "vector_source_used"
            case notes
            case sources
            case availableBooks = "available_books"
        }
    }

    struct KnowledgeSourcePayload: Decodable {
        let bookTitle: String
        let author: String?
        let section: String?
        let pageRange: String?
        let snippet: String
        let relevanceScore: Double?
        let chunkId: String?

        private enum CodingKeys: String, CodingKey {
            case bookTitle = "book_title"
            case author
            case section
            case pageRange = "page_range"
            case snippet
            case relevanceScore = "relevance_score"
            case chunkId = "chunk_id"
        }
    }

    struct BookMetadataPayload: Decodable {
        let bookTitle: String
        let author: String?
        let totalChunks: Int
        let usedChunks: [String]
        let availableChunks: [ChunkOptionPayload]

        private enum CodingKeys: String, CodingKey {
            case bookTitle = "book_title"
            case author
            case totalChunks = "total_chunks"
            case usedChunks = "used_chunks"
            case availableChunks = "available_chunks"
        }
    }

    struct ChunkOptionPayload: Decodable {
        let chunkId: String
        let section: String?
        let pageRange: String?
        let preview: String
        let fullText: String
        let wasUsed: Bool

        private enum CodingKeys: String, CodingKey {
            case chunkId = "chunk_id"
            case section
            case pageRange = "page_range"
            case preview
            case fullText = "full_text"
            case wasUsed = "was_used"
        }
    }
}
