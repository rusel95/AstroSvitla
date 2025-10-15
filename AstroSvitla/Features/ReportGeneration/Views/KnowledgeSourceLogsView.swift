import SwiftUI

struct KnowledgeSourceLogsView: View {
    let knowledgeUsage: KnowledgeUsage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusSection

                    if let sources = knowledgeUsage.sources, !sources.isEmpty {
                        sourcesSection(sources)
                    } else {
                        emptySourcesSection
                    }

                    if let notes = knowledgeUsage.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                }
                .padding()
            }
            .navigationTitle(Text("knowledge_logs.title", tableName: "Localizable"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.close", table: "Localizable")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("knowledge_logs.status.title", tableName: "Localizable")
                .font(.headline)

            HStack {
                Image(systemName: knowledgeUsage.vectorSourceUsed ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(knowledgeUsage.vectorSourceUsed ? .green : .secondary)
                Text(knowledgeUsage.vectorSourceUsed ?
                     String(localized: "knowledge_logs.status.used", table: "Localizable") :
                     String(localized: "knowledge_logs.status.not_used", table: "Localizable"))
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sourcesSection(_ sources: [KnowledgeSource]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("knowledge_logs.sources.title", tableName: "Localizable")
                .font(.headline)
            + Text(" (\(sources.count))")
                .font(.headline)

            ForEach(sources) { source in
                sourceCard(source)
            }
        }
    }

    private func sourceCard(_ source: KnowledgeSource) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book title
            HStack(alignment: .top) {
                Image(systemName: "book.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(source.bookTitle)
                        .font(.headline)

                    if let author = source.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Section and page
            if source.section != nil || source.pageRange != nil {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    if let section = source.section {
                        HStack {
                            Image(systemName: "text.book.closed")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            (Text("knowledge_logs.source.section", tableName: "Localizable") + Text(": \(section)"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let pageRange = source.pageRange {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            (Text("knowledge_logs.source.pages", tableName: "Localizable") + Text(": \(pageRange)"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Snippet
            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("knowledge_logs.source.snippet", tableName: "Localizable")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(source.snippet)
                    .font(.body)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Relevance score
            if let score = source.relevanceScore {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    (Text("knowledge_logs.source.relevance", tableName: "Localizable") + Text(": \(String(format: "%.1f%%", score * 100))"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptySourcesSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("knowledge_logs.empty.title", tableName: "Localizable")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("knowledge_logs.empty.message", tableName: "Localizable")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("knowledge_logs.notes.title", tableName: "Localizable")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    KnowledgeSourceLogsView(
        knowledgeUsage: KnowledgeUsage(
            vectorSourceUsed: true,
            notes: "Використано 3 джерела з векторної бази знань",
            sources: [
                KnowledgeSource(
                    bookTitle: "Астрологія для початківців",
                    author: "Джоанна Мартін Вулфолк",
                    section: "Глава 5: Планети в домах",
                    pageRange: "142-156",
                    snippet: "Венера в сьомому домі вказує на гармонійні відносини та любов до партнерства. Людина з таким розташуванням часто знаходить задоволення у створенні естетичного середовища для своєї пари.",
                    relevanceScore: 0.95
                ),
                KnowledgeSource(
                    bookTitle: "Транзити та прогресії",
                    author: "Ян Спіллер",
                    section: "Розділ 3: Кармічні вузли",
                    pageRange: "78-92",
                    snippet: "Північний вузол у Близнюках закликає до розвитку комунікаційних навичок та гнучкості мислення.",
                    relevanceScore: 0.87
                ),
            ]
        )
    )
}
