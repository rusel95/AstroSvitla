import Foundation
import SwiftData

@Model
final class ReportPurchase {
    @Attribute(.unique)
    var id: UUID

    var area: String
    var reportText: String
    var summary: String
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData")) var keyInfluences: [String]
    var detailedAnalysis: String
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData")) var recommendations: [String]
    var language: String
    var knowledgeVectorUsed: Bool = false
    var knowledgeNotes: String?
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData")) var knowledgeSourceTitles: [String]?
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData")) var knowledgeSourceAuthors: [String]?
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData")) var knowledgeSourcePages: [String]?

    var price: Decimal
    var currency: String
    var transactionId: String
    var purchaseDate: Date

    var generatedAt: Date
    var wordCount: Int

    @Relationship(inverse: \UserProfile.reports)
    var profile: UserProfile?

    init(
        id: UUID = UUID(),
        area: String,
        reportText: String,
        summary: String,
        keyInfluences: [String] = [],
        detailedAnalysis: String,
        recommendations: [String] = [],
        language: String,
        knowledgeVectorUsed: Bool = false,
        knowledgeNotes: String? = nil,
        knowledgeSourceTitles: [String]? = nil,
        knowledgeSourceAuthors: [String]? = nil,
        knowledgeSourcePages: [String]? = nil,
        price: Decimal,
        currency: String = "USD",
        transactionId: String
    ) {
        self.id = id
        self.area = area
        self.reportText = reportText
        self.summary = summary
        self.keyInfluences = keyInfluences
        self.detailedAnalysis = detailedAnalysis
        self.recommendations = recommendations
        self.language = language
        self.knowledgeVectorUsed = knowledgeVectorUsed
        self.knowledgeNotes = knowledgeNotes
        self.knowledgeSourceTitles = knowledgeSourceTitles
        self.knowledgeSourceAuthors = knowledgeSourceAuthors
        self.knowledgeSourcePages = knowledgeSourcePages
        self.price = price
        self.currency = currency
        self.transactionId = transactionId
        self.purchaseDate = Date()
        self.generatedAt = Date()
        self.wordCount = reportText.split(whereSeparator: \.isWhitespace).count
    }

    var areaDisplayName: String {
        switch area {
        case ReportArea.finances.rawValue:
            return ReportArea.finances.displayName
        case ReportArea.career.rawValue:
            return ReportArea.career.displayName
        case ReportArea.relationships.rawValue:
            return ReportArea.relationships.displayName
        case ReportArea.health.rawValue:
            return ReportArea.health.displayName
        case ReportArea.general.rawValue:
            return ReportArea.general.displayName
        default:
            return area.capitalized
        }
    }

    var estimatedReadingTime: Int {
        let minutes = Int(ceil(Double(wordCount) / 200.0))
        return max(1, minutes)
    }

    func isForArea(_ reportArea: ReportArea) -> Bool {
        area == reportArea.rawValue
    }

    var generatedReport: GeneratedReport? {
        guard let reportArea = ReportArea(rawValue: area) else { return nil }

        // Convert stored arrays to KnowledgeSource objects
        var sources: [KnowledgeSource]? = nil
        if let titles = knowledgeSourceTitles,
           let authors = knowledgeSourceAuthors,
           let pages = knowledgeSourcePages,
           !titles.isEmpty {
            var sourcesArray: [KnowledgeSource] = []
            for i in 0..<min(titles.count, authors.count, pages.count) {
                // Create a KnowledgeSource from stored data
                // Note: snippet will be empty as we don't store it separately
                sourcesArray.append(KnowledgeSource(
                    bookTitle: titles[i],
                    author: authors[i].isEmpty ? nil : authors[i],
                    section: nil,
                    pageRange: pages[i].isEmpty ? nil : pages[i],
                    snippet: "",
                    relevanceScore: nil
                ))
            }
            sources = sourcesArray
        }

        return GeneratedReport(
            area: reportArea,
            summary: summary,
            keyInfluences: keyInfluences,
            detailedAnalysis: detailedAnalysis,
            recommendations: recommendations,
            knowledgeUsage: KnowledgeUsage(
                vectorSourceUsed: knowledgeVectorUsed,
                notes: knowledgeNotes,
                sources: sources
            )
        )
    }
}
