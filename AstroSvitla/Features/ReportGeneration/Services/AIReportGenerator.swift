import Foundation

final class AIReportGenerator: @unchecked Sendable {

    private let openAIService: OpenAIService
    private let knowledgeProvider: KnowledgeSourceProvider

    @MainActor
    init(
        openAIService: OpenAIService? = nil,
        knowledgeProvider: KnowledgeSourceProvider? = nil
    ) {
        self.openAIService = openAIService ?? OpenAIService()
        self.knowledgeProvider = knowledgeProvider ?? AstrologyKnowledgeProvider()
    }

    func generateReport(
        for area: ReportArea,
        birthDetails: BirthDetails,
        natalChart: NatalChart,
        languageCode: String,
        languageDisplayName: String,
        repositoryContext: String,
        selectedModel: AppPreferences.OpenAIModel
    ) async throws -> GeneratedReport {
        let knowledgeSnippets = await knowledgeProvider.loadSnippets(
            for: area,
            birthDetails: birthDetails,
            natalChart: natalChart
        )

        return try await openAIService.generateReport(
            for: area,
            birthDetails: birthDetails,
            natalChart: natalChart,
            knowledgeSnippets: knowledgeSnippets,
            languageCode: languageCode,
            languageDisplayName: languageDisplayName,
            repositoryContext: repositoryContext,
            selectedModel: selectedModel
        )
    }
}
