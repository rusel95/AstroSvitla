import SwiftUI

struct KnowledgeSourceLogsView: View {
    let knowledgeUsage: KnowledgeUsage
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBookId: UUID?
    @State private var expandedChunks: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                statusSection

                if let sources = knowledgeUsage.sources, !sources.isEmpty {
                    usedSourcesSection(sources)
                }

                if let availableBooks = knowledgeUsage.availableBooks, !availableBooks.isEmpty {
                    availableBooksSection(availableBooks)
                } else {
                    emptyDatabaseSection
                }

                if let notes = knowledgeUsage.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .listStyle(.insetGrouped)
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
        Section {
            HStack {
                Image(systemName: knowledgeUsage.vectorSourceUsed ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(knowledgeUsage.vectorSourceUsed ? .green : .secondary)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(knowledgeUsage.vectorSourceUsed ?
                         String(localized: "knowledge_logs.status.used", table: "Localizable") :
                         String(localized: "knowledge_logs.status.not_used", table: "Localizable"))
                        .font(.headline)

                    if let sources = knowledgeUsage.sources, !sources.isEmpty {
                        Text("knowledge_logs.status.sources_count", tableName: "Localizable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        + Text(": \(sources.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("knowledge_logs.status.title", tableName: "Localizable")
        }
    }

    private func usedSourcesSection(_ sources: [KnowledgeSource]) -> some View {
        Section {
            ForEach(sources) { source in
                VStack(alignment: .leading, spacing: 12) {
                    // Header with book info
                    HStack(alignment: .top, spacing: 8) {
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

                    // Metadata
                    if source.section != nil || source.pageRange != nil || source.chunkId != nil {
                        VStack(alignment: .leading, spacing: 4) {
                            if let section = source.section {
                                Label(section, systemImage: "text.book.closed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let pageRange = source.pageRange {
                                Label(pageRange, systemImage: "doc.text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let chunkId = source.chunkId {
                                Label("ID: \(chunkId)", systemImage: "number")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Snippet
                    Text(source.snippet)
                        .font(.callout)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Relevance score
                    if let score = source.relevanceScore {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text("knowledge_logs.source.relevance", tableName: "Localizable")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            + Text(": \(String(format: "%.0f%%", score * 100))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("knowledge_logs.used_sources.title", tableName: "Localizable")
                + Text(" (\(sources.count))")
        }
    }

    private func availableBooksSection(_ books: [BookMetadata]) -> some View {
        Section {
            ForEach(books) { book in
                VStack(alignment: .leading, spacing: 0) {
                    // Book header - always visible
                    Button {
                        withAnimation {
                            if selectedBookId == book.id {
                                selectedBookId = nil
                            } else {
                                selectedBookId = book.id
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(book.bookTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                if let author = book.author {
                                    Text(author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 12) {
                                    Label("\(book.totalChunks) chunks", systemImage: "square.stack.3d.up")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    if !book.usedChunks.isEmpty {
                                        Label("\(book.usedChunks.count) used", systemImage: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: selectedBookId == book.id ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)

                    // Expandable chunks list
                    if selectedBookId == book.id {
                        Divider()
                            .padding(.vertical, 8)

                        chunksListView(for: book)
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            HStack {
                Text("knowledge_logs.database.title", tableName: "Localizable")
                Spacer()
                Text("(\(books.count) books)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func chunksListView(for book: BookMetadata) -> some View {
        ForEach(book.availableChunks) { chunk in
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation {
                        if expandedChunks.contains(chunk.chunkId) {
                            expandedChunks.remove(chunk.chunkId)
                        } else {
                            expandedChunks.insert(chunk.chunkId)
                        }
                    }
                } label: {
                    HStack(alignment: .top) {
                        // Status indicator
                        Circle()
                            .fill(chunk.wasUsed ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            // Section and page info
                            HStack {
                                if let section = chunk.section {
                                    Text(section)
                                        .font(.subheadline)
                                        .fontWeight(chunk.wasUsed ? .semibold : .regular)
                                        .foregroundStyle(chunk.wasUsed ? .primary : .secondary)
                                }

                                if let pageRange = chunk.pageRange {
                                    Text("• \(pageRange)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // Preview (first line only when collapsed)
                            if !expandedChunks.contains(chunk.chunkId) {
                                Text(chunk.preview)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Image(systemName: expandedChunks.contains(chunk.chunkId) ? "chevron.up.circle" : "chevron.down.circle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)

                // Full text when expanded
                if expandedChunks.contains(chunk.chunkId) {
                    Text(chunk.fullText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.top, 8)
                        .padding(.leading, 16)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(chunk.wasUsed ? Color.green.opacity(0.05) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var emptyDatabaseSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "books.vertical")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("knowledge_logs.database.empty", tableName: "Localizable")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("knowledge_logs.database.empty_message", tableName: "Localizable")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private func notesSection(_ notes: String) -> some View {
        Section {
            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
        } header: {
            Text("knowledge_logs.notes.title", tableName: "Localizable")
        }
    }
}
