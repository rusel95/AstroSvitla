import SwiftUI

struct ReportGenerationLogsView: View {
    let report: GeneratedReport
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBookId: UUID?
    @State private var expandedChunks: Set<String> = []
    @State private var expandedSources: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                generationMetadataSection
                sourcesOverviewSection
                citedSourcesSection
                availableBooksSection

                if let notes = report.knowledgeUsage.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("logs.title", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Generation Metadata Section

    private var generationMetadataSection: some View {
        Section {
            VStack(spacing: 12) {
                // Model info
                HStack {
                    Label("logs.model", systemImage: "cpu")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(report.metadata.modelName)
                        .fontWeight(.medium)
                }

                Divider()

                // Token usage
                VStack(spacing: 8) {
                    HStack {
                        Text("logs.tokens.prompt")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(report.metadata.promptTokens)")
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("logs.tokens.completion")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(report.metadata.completionTokens)")
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("logs.tokens.total")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(report.metadata.totalTokens)")
                            .fontWeight(.semibold)
                    }
                }

                Divider()

                // Cost & Time
                HStack {
                    Label("logs.cost", systemImage: "dollarsign.circle")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.6f", report.metadata.estimatedCost))")
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }

                HStack {
                    Label("logs.processing_time", systemImage: "clock")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: String(localized: "logs.seconds %@"), String(format: "%.2f", report.metadata.processingTimeSeconds)))
                        .fontWeight(.medium)
                }

                HStack {
                    Label("logs.generation_date", systemImage: "calendar")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(report.metadata.generationDate, style: .date)
                        .fontWeight(.medium)
                }
            }
            .font(.subheadline)
        } header: {
            Text("logs.section.metadata")
        }
    }

    // MARK: - Sources Overview

    private var sourcesOverviewSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(report.metadata.knowledgeSnippetsProvided)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("logs.snippets_provided")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(report.metadata.totalSourcesCited)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("logs.sources_cited")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)

            Divider()

            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(report.metadata.vectorDatabaseSourcesCount)")
                            .fontWeight(.semibold)
                        Text("logs.from_our_db")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "book.circle.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(report.metadata.externalSourcesCount)")
                            .fontWeight(.semibold)
                        Text("logs.external_books")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.subheadline)
        } header: {
            Text("logs.section.sources_overview")
        }
    }

    // MARK: - Cited Sources Section

    private var citedSourcesSection: some View {
        Section {
            if let sources = report.knowledgeUsage.sources, !sources.isEmpty {
                ForEach(sources) { source in
                    citedSourceRow(source)
                }
            } else {
                Text("logs.no_sources_cited")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        } header: {
            HStack {
                Text("logs.section.cited_sources")
                Spacer()
                if let sources = report.knowledgeUsage.sources {
                    Text("(\(sources.count))")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func citedSourceRow(_ source: KnowledgeSource) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    if expandedSources.contains(source.id) {
                        expandedSources.remove(source.id)
                    } else {
                        expandedSources.insert(source.id)
                    }
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Checkmark for vector DB sources
                    if source.isFromVectorDatabase {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    } else {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.blue)
                            .font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(source.bookTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if let author = source.author {
                            Text(author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 12) {
                            if let section = source.section {
                                Label(section, systemImage: "text.book.closed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            if let pageRange = source.pageRange {
                                Label(pageRange, systemImage: "doc.text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if source.isFromVectorDatabase, let chunkId = source.chunkId {
                            Label("ID: \(chunkId)", systemImage: "number")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        if let score = source.relevanceScore {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption2)
                                Text(String(format: String(localized: "logs.relevance %@"), String(format: "%.0f", score * 100)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: expandedSources.contains(source.id) ? "chevron.up.circle" : "chevron.down.circle")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
            }
            .buttonStyle(.plain)

            // Expanded snippet
            if expandedSources.contains(source.id) {
                Text(source.snippet)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(source.isFromVectorDatabase ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Available Books Section

    private var availableBooksSection: some View {
        Section {
            if let books = report.knowledgeUsage.availableBooks, !books.isEmpty {
                ForEach(books) { book in
                    VStack(alignment: .leading, spacing: 0) {
                        // Book header
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
                                        Label(String(format: String(localized: "logs.chunks %lld"), book.totalChunks), systemImage: "square.stack.3d.up")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if !book.usedChunks.isEmpty {
                                            Label(String(format: String(localized: "logs.chunks_used %lld"), book.usedChunks.count), systemImage: "checkmark.circle.fill")
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
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("logs.database_empty")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("logs.database_empty.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        } header: {
            HStack {
                Text("logs.section.vector_database")
                Spacer()
                if let books = report.knowledgeUsage.availableBooks {
                    Text(String(format: String(localized: "logs.books_count %lld"), books.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        Section {
            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
        } header: {
            Text("logs.section.notes")
        }
    }
}
