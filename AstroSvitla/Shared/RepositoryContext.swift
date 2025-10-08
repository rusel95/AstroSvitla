import Foundation

struct RepositoryContext {
    static let shared = RepositoryContext()

    let summary: String = {
        """
        AstroSvitla iOS application (SwiftUI, SwiftData, StoreKit-ready). Core modules:
        - Features/Main – tab navigation, onboarding flow, chart/report pipeline.
        - Features/ChartInput – birth data form, location search, chart calculation.
        - Features/ReportGeneration – AI prompt builder, OpenAI service, report views, PDF export.
        - Models/SwiftData – persistent birth charts and purchased reports.
        - Shared utilities – AppPreferences, localization helper.
        Knowledge snippets are fetched from AstrologyKnowledgeProvider (stubbed vector store).
        """
    }()
}
