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
        knowledgeSnippets: [String]
    ) async throws -> GeneratedReport {
        guard let client = clientProvider.client else {
            throw ReportGenerationError.missingAPIKey
        }

        let prompt = promptBuilder.makePrompt(
            for: area,
            birthDetails: birthDetails,
            natalChart: natalChart,
            knowledgeSnippets: knowledgeSnippets
        )
        let query = makeChatQuery(systemPrompt: prompt.system, userPrompt: prompt.user)

        let maxAttempts = 3
        var lastError: ReportGenerationError?

        for attempt in 0..<maxAttempts {
            do {
                let (payload, usage) = try await performRequest(client: client, query: query)
                logUsage(usage)
                return GeneratedReport(
                    area: area,
                    summary: payload.summary,
                    keyInfluences: payload.keyInfluences,
                    detailedAnalysis: payload.detailedAnalysis,
                    recommendations: payload.recommendations
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

    private func makeChatQuery(systemPrompt: String, userPrompt: String) -> ChatQuery {
        let systemMessage = ChatQuery.ChatCompletionMessageParam.system(
            .init(content: .textContent(systemPrompt))
        )
        let userMessage = ChatQuery.ChatCompletionMessageParam.user(
            .init(content: .string(userPrompt))
        )

        return ChatQuery(
            messages: [systemMessage, userMessage],
            model: "gpt-4o-mini",
            maxCompletionTokens: 900,
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
        let totalTokens = usage.totalTokens ?? (usage.promptTokens ?? 0) + (usage.completionTokens ?? 0)
        let estimatedCost = Double(totalTokens) / 1000.0 * 0.0007
        debugPrint("ℹ️ OpenAI usage — prompt: \(usage.promptTokens ?? 0) tokens, completion: \(usage.completionTokens ?? 0) tokens, total: \(totalTokens), est. cost $\(String(format: "%.6f", estimatedCost))")
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
        case .statusError(let response, let statusCode):
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

    private enum CodingKeys: String, CodingKey {
        case summary
        case keyInfluences = "key_influences"
        case detailedAnalysis = "detailed_analysis"
        case recommendations
    }
}
