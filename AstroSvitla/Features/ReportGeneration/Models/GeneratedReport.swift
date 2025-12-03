import Foundation

struct GeneratedReport: Identifiable, Sendable, Codable {
    let id = UUID()
    let area: ReportArea
    let summary: String
    let keyInfluences: [String]
    let detailedAnalysis: String
    let recommendations: [String]
    let knowledgeUsage: KnowledgeUsage
    let metadata: GenerationMetadata
    
    // Feature: 006-instagram-share-templates
    /// AI-generated content optimized for social sharing (nil for legacy reports)
    var shareContent: ShareContent?

    enum CodingKeys: String, CodingKey {
        case area, summary, keyInfluences, detailedAnalysis, recommendations, knowledgeUsage, metadata, shareContent
    }
    
    init(
        area: ReportArea,
        summary: String,
        keyInfluences: [String],
        detailedAnalysis: String,
        recommendations: [String],
        knowledgeUsage: KnowledgeUsage,
        metadata: GenerationMetadata,
        shareContent: ShareContent? = nil
    ) {
        self.area = area
        self.summary = summary
        self.keyInfluences = keyInfluences
        self.detailedAnalysis = detailedAnalysis
        self.recommendations = recommendations
        self.knowledgeUsage = knowledgeUsage
        self.metadata = metadata
        self.shareContent = shareContent
    }
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

    /// Чи джерело з нашої векторної бази даних (має chunk_id)
    var isFromVectorDatabase: Bool {
        chunkId != nil && !chunkId!.isEmpty
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

struct GenerationMetadata: Codable, Sendable {
    let modelName: String
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let estimatedCost: Double
    let generationDate: Date
    let processingTimeSeconds: Double
    let knowledgeSnippetsProvided: Int
    let totalSourcesCited: Int
    let vectorDatabaseSourcesCount: Int
    let externalSourcesCount: Int

    enum CodingKeys: String, CodingKey {
        case modelName = "model_name"
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case estimatedCost = "estimated_cost"
        case generationDate = "generation_date"
        case processingTimeSeconds = "processing_time_seconds"
        case knowledgeSnippetsProvided = "knowledge_snippets_provided"
        case totalSourcesCited = "total_sources_cited"
        case vectorDatabaseSourcesCount = "vector_database_sources_count"
        case externalSourcesCount = "external_sources_count"
    }

    init(
        modelName: String,
        promptTokens: Int,
        completionTokens: Int,
        totalTokens: Int,
        estimatedCost: Double,
        generationDate: Date = Date(),
        processingTimeSeconds: Double,
        knowledgeSnippetsProvided: Int,
        totalSourcesCited: Int,
        vectorDatabaseSourcesCount: Int,
        externalSourcesCount: Int
    ) {
        self.modelName = modelName
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
        self.estimatedCost = estimatedCost
        self.generationDate = generationDate
        self.processingTimeSeconds = processingTimeSeconds
        self.knowledgeSnippetsProvided = knowledgeSnippetsProvided
        self.totalSourcesCited = totalSourcesCited
        self.vectorDatabaseSourcesCount = vectorDatabaseSourcesCount
        self.externalSourcesCount = externalSourcesCount
    }
}
