import Foundation

actor AIReportGenerator {

    private let openAIService: OpenAIService
    private let fallbackGenerator: HardcodedReportGenerator
    private let knowledgeProvider: AstrologyKnowledgeProvider

    init(
        openAIService: OpenAIService = OpenAIService(),
        fallbackGenerator: HardcodedReportGenerator = HardcodedReportGenerator(),
        knowledgeProvider: AstrologyKnowledgeProvider = AstrologyKnowledgeProvider()
    ) {
        self.openAIService = openAIService
        self.fallbackGenerator = fallbackGenerator
        self.knowledgeProvider = knowledgeProvider
    }

    func generateReport(for area: ReportArea, birthDetails: BirthDetails) async throws -> GeneratedReport {
        let knowledgeSnippets = await knowledgeProvider.loadSnippets(for: area, birthDetails: birthDetails)

        if openAIService.isConfigured {
            do {
                return try await openAIService.generateReport(
                    for: area,
                    birthDetails: birthDetails,
                    knowledgeSnippets: knowledgeSnippets
                )
            } catch ReportGenerationError.missingAPIKey {
                return try await fallbackGenerator.generateReport(
                    for: area,
                    birthDetails: birthDetails,
                    knowledgeSnippets: knowledgeSnippets
                )
            } catch ReportGenerationError.serviceUnavailable {
                return try await fallbackGenerator.generateReport(
                    for: area,
                    birthDetails: birthDetails,
                    knowledgeSnippets: knowledgeSnippets
                )
            } catch ReportGenerationError.rateLimited {
                return try await fallbackGenerator.generateReport(
                    for: area,
                    birthDetails: birthDetails,
                    knowledgeSnippets: knowledgeSnippets
                )
            } catch {
                #if DEBUG
                debugPrint("⚠️ Falling back to hardcoded report after OpenAI error: \(error)")
                #endif
                return try await fallbackGenerator.generateReport(
                    for: area,
                    birthDetails: birthDetails,
                    knowledgeSnippets: knowledgeSnippets
                )
            }
        } else {
            return try await fallbackGenerator.generateReport(
                for: area,
                birthDetails: birthDetails,
                knowledgeSnippets: knowledgeSnippets
            )
        }
    }
}
