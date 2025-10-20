import Foundation

actor AIReportGenerator {

    private let openAIService: OpenAIService
    private let knowledgeProvider: KnowledgeSourceProvider

    nonisolated private static let defaultOpenAIService = OpenAIService()
    nonisolated private static let defaultKnowledgeProvider = AstrologyKnowledgeProvider()

    init(
        openAIService: OpenAIService = AIReportGenerator.defaultOpenAIService,
        knowledgeProvider: KnowledgeSourceProvider = AIReportGenerator.defaultKnowledgeProvider
    ) {
        self.openAIService = openAIService
        self.knowledgeProvider = knowledgeProvider
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
