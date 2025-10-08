import Foundation

actor AIReportGenerator {

    private let openAIService: OpenAIService
    private let knowledgeProvider: AstrologyKnowledgeProvider

    init(
        openAIService: OpenAIService = OpenAIService(),
        knowledgeProvider: AstrologyKnowledgeProvider = AstrologyKnowledgeProvider()
    ) {
        self.openAIService = openAIService
        self.knowledgeProvider = knowledgeProvider
    }

    func generateReport(for area: ReportArea, birthDetails: BirthDetails) async throws -> GeneratedReport {
        let knowledgeSnippets = await knowledgeProvider.loadSnippets(for: area, birthDetails: birthDetails)

        guard openAIService.isConfigured else {
            throw ReportGenerationError.missingAPIKey
        }

        return try await openAIService.generateReport(
            for: area,
            birthDetails: birthDetails,
            knowledgeSnippets: knowledgeSnippets
        )
    }
}
