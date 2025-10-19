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
    let availableBooks: [BookMetadata]?  // Вся доступна база знань

    enum CodingKeys: String, CodingKey {
        case vectorSourceUsed = "vector_source_used"
        case notes
        case sources
        case availableBooks = "available_books"
    }

    init(vectorSourceUsed: Bool, notes: String? = nil, sources: [KnowledgeSource]? = nil, availableBooks: [BookMetadata]? = nil) {
        self.vectorSourceUsed = vectorSourceUsed
        self.notes = notes
        self.sources = sources
        self.availableBooks = availableBooks
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
    let chunkId: String?  // ID чанку в векторній базі

    enum CodingKeys: String, CodingKey {
        case bookTitle = "book_title"
        case author
        case section
        case pageRange = "page_range"
        case snippet
        case relevanceScore = "relevance_score"
        case chunkId = "chunk_id"
    }

    init(bookTitle: String, author: String? = nil, section: String? = nil, pageRange: String? = nil, snippet: String = "", relevanceScore: Double? = nil, chunkId: String? = nil) {
        self.bookTitle = bookTitle
        self.author = author
        self.section = section
        self.pageRange = pageRange
        self.snippet = snippet
        self.relevanceScore = relevanceScore
        self.chunkId = chunkId
    }
}

struct BookMetadata: Codable, Sendable, Identifiable {
    let id = UUID()
    let bookTitle: String
    let author: String?
    let totalChunks: Int
    let usedChunks: [String]  // IDs використаних чанків
    let availableChunks: [ChunkOption]  // Варіанти доступних чанків

    enum CodingKeys: String, CodingKey {
        case bookTitle = "book_title"
        case author
        case totalChunks = "total_chunks"
        case usedChunks = "used_chunks"
        case availableChunks = "available_chunks"
    }

    init(bookTitle: String, author: String? = nil, totalChunks: Int = 0, usedChunks: [String] = [], availableChunks: [ChunkOption] = []) {
        self.bookTitle = bookTitle
        self.author = author
        self.totalChunks = totalChunks
        self.usedChunks = usedChunks
        self.availableChunks = availableChunks
    }
}

struct ChunkOption: Codable, Sendable, Identifiable {
    let id = UUID()
    let chunkId: String
    let section: String?
    let pageRange: String?
    let preview: String  // Короткий preview тексту для списку
    let fullText: String  // Повний текст чанку
    let wasUsed: Bool

    enum CodingKeys: String, CodingKey {
        case chunkId = "chunk_id"
        case section
        case pageRange = "page_range"
        case preview
        case fullText = "full_text"
        case wasUsed = "was_used"
    }

    init(chunkId: String, section: String? = nil, pageRange: String? = nil, preview: String = "", fullText: String = "", wasUsed: Bool = false) {
        self.chunkId = chunkId
        self.section = section
        self.pageRange = pageRange
        self.preview = preview
        self.fullText = fullText
        self.wasUsed = wasUsed
    }
}
