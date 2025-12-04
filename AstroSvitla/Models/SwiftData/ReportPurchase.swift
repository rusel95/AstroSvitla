import Foundation
import SwiftData

// File-level decoder and helper functions to avoid @MainActor isolation issues
private let reportDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder
}()

// File-level helper functions - these are nonisolated by default
private func decodeKnowledgeSources(from data: Data) -> [KnowledgeSource]? {
    try? reportDecoder.decode([KnowledgeSource].self, from: data)
}

private func decodeGenerationMetadata(from data: Data) -> GenerationMetadata? {
    try? reportDecoder.decode(GenerationMetadata.self, from: data)
}

private func decodeBookMetadata(from data: Data) -> [BookMetadata]? {
    try? reportDecoder.decode([BookMetadata].self, from: data)
}

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
    var knowledgeVectorUsed: Bool = false
    var knowledgeNotes: String?
    var knowledgeSourceTitles: [String]?
    var knowledgeSourceAuthors: [String]?
    var knowledgeSourcePages: [String]?
    
    /// ISO language code used when this report was generated (e.g., "en", "uk", "de")
    /// Used for FR-021: Store language used when generating each report
    /// Default "en" for backward compatibility with existing reports
    var languageCode: String = "en"

    var price: Decimal
    var currency: String
    var transactionId: String
    var purchaseDate: Date

    var generatedAt: Date
    var wordCount: Int

    // Logging data - stored as JSON strings for full persistence
    var metadataJSON: String?  // GenerationMetadata as JSON
    var knowledgeSourcesJSON: String?  // Complete [KnowledgeSource] as JSON
    var availableBooksJSON: String?  // Complete [BookMetadata] as JSON

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
        languageCode: String = "en",
        knowledgeVectorUsed: Bool = false,
        knowledgeNotes: String? = nil,
        knowledgeSourceTitles: [String]? = nil,
        knowledgeSourceAuthors: [String]? = nil,
        knowledgeSourcePages: [String]? = nil,
        price: Decimal,
        currency: String = "USD",
        transactionId: String,
        metadataJSON: String? = nil,
        knowledgeSourcesJSON: String? = nil,
        availableBooksJSON: String? = nil
    ) {
        self.id = id
        self.area = area
        self.reportText = reportText
        self.summary = summary
        self.keyInfluences = keyInfluences
        self.detailedAnalysis = detailedAnalysis
        self.recommendations = recommendations
        self.language = language
        self.languageCode = languageCode
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
        self.metadataJSON = metadataJSON
        self.knowledgeSourcesJSON = knowledgeSourcesJSON
        self.availableBooksJSON = availableBooksJSON
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

        // Try to decode full sources from JSON
        var sources: [KnowledgeSource]? = nil
        if let sourcesJSON = knowledgeSourcesJSON,
           let data = sourcesJSON.data(using: .utf8) {
            sources = decodeKnowledgeSources(from: data)
        }

        // Fallback to legacy stored arrays if JSON not available
        if sources == nil,
           let titles = knowledgeSourceTitles,
           let authors = knowledgeSourceAuthors,
           let pages = knowledgeSourcePages,
           !titles.isEmpty {
            var sourcesArray: [KnowledgeSource] = []
            for i in 0..<min(titles.count, authors.count, pages.count) {
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

        // Try to decode metadata from JSON
        var metadata = GenerationMetadata(
            modelName: "unknown",
            promptTokens: 0,
            completionTokens: 0,
            totalTokens: 0,
            estimatedCost: 0.0,
            generationDate: generatedAt,
            processingTimeSeconds: 0.0,
            knowledgeSnippetsProvided: sources?.count ?? 0,
            totalSourcesCited: sources?.count ?? 0,
            vectorDatabaseSourcesCount: knowledgeVectorUsed ? (sources?.count ?? 0) : 0,
            externalSourcesCount: 0
        )

        if let metadataJSON = metadataJSON,
           let data = metadataJSON.data(using: .utf8) {
            if let decodedMetadata = decodeGenerationMetadata(from: data) {
                metadata = decodedMetadata
            }
        }

        // Try to decode available books from JSON
        var availableBooks: [BookMetadata]? = nil
        if let booksJSON = availableBooksJSON,
           let data = booksJSON.data(using: .utf8) {
            availableBooks = decodeBookMetadata(from: data)
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
                sources: sources,
                availableBooks: availableBooks
            ),
            metadata: metadata
        )
    }
}
