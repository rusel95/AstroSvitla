import Foundation

struct GeneratedReport: Identifiable, Sendable {
    let id = UUID()
    let area: ReportArea
    let summary: String
    let keyInfluences: [String]
    let detailedAnalysis: String
    let recommendations: [String]
}
