import Foundation
import SwiftData

@Model
final class ReportPurchase {
    @Attribute(.unique)
    var id: UUID

    var area: String
    var reportText: String
    var summary: String
    var keyInfluences: [String]
    var detailedAnalysis: String
    var recommendations: [String]
    var language: String

    var price: Decimal
    var currency: String
    var transactionId: String
    var purchaseDate: Date

    var generatedAt: Date
    var wordCount: Int

    @Relationship(inverse: \BirthChart.reports)
    var chart: BirthChart?

    init(
        id: UUID = UUID(),
        area: String,
        reportText: String,
        summary: String,
        keyInfluences: [String] = [],
        detailedAnalysis: String,
        recommendations: [String] = [],
        language: String,
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
        return GeneratedReport(
            area: reportArea,
            summary: summary,
            keyInfluences: keyInfluences,
            detailedAnalysis: detailedAnalysis,
            recommendations: recommendations
        )
    }
}
