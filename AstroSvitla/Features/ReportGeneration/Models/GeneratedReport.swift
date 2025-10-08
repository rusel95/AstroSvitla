import Foundation

struct GeneratedReport: Identifiable, Sendable, Codable {
    let id = UUID()
    let area: ReportArea
    let summary: String
    let keyInfluences: [String]
    let detailedAnalysis: String
    let recommendations: [String]
    let knowledgeUsage: KnowledgeUsage
}

struct KnowledgeUsage: Codable, Sendable {
    let vectorSourceUsed: Bool
    let notes: String?
}
