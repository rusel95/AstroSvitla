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
    let sources: [KnowledgeSource]?

    init(vectorSourceUsed: Bool, notes: String? = nil, sources: [KnowledgeSource]? = nil) {
        self.vectorSourceUsed = vectorSourceUsed
        self.notes = notes
        self.sources = sources
    }
}

struct KnowledgeSource: Codable, Sendable, Identifiable {
    let id = UUID()
    let bookTitle: String
    let author: String?
    let section: String?
    let pageRange: String?
    let snippet: String
    let relevanceScore: Double?

    enum CodingKeys: String, CodingKey {
        case bookTitle = "book_title"
        case author
        case section
        case pageRange = "page_range"
        case snippet
        case relevanceScore = "relevance_score"
    }

    init(bookTitle: String, author: String? = nil, section: String? = nil, pageRange: String? = nil, snippet: String = "", relevanceScore: Double? = nil) {
        self.bookTitle = bookTitle
        self.author = author
        self.section = section
        self.pageRange = pageRange
        self.snippet = snippet
        self.relevanceScore = relevanceScore
    }
}
