import SwiftUI

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query: String
    @State private var results: [LocationSuggestion] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    private let service = LocationSearchService()
    var onSelection: (LocationSuggestion) -> Void

    init(initialQuery: String = "", onSelection: @escaping (LocationSuggestion) -> Void) {
        _query = State(initialValue: initialQuery)
        self.onSelection = onSelection
    }

    var body: some View {
        List {
            if isSearching {
                ProgressView("Searching…")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            } else if results.isEmpty {
                Section {
                    Text(query.count < 3
                         ? "Start typing a city and country. Minimum 3 characters."
                         : "No matches found. Try a different spelling.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(results) { suggestion in
                        Button {
                            onSelection(suggestion)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.headline)
                                if suggestion.subtitle.isEmpty == false {
                                    Text(suggestion.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search Locations")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: query) { newValue in
            scheduleSearch(for: newValue)
        }
        .task {
            if query.isEmpty == false {
                await search(for: query)
            }
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }

    private func scheduleSearch(for text: String) {
        searchTask?.cancel()

        let task = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            await search(for: text)
        }

        searchTask = task
    }

    private func search(for text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 3 {
            await MainActor.run {
                results = []
                errorMessage = nil
                isSearching = false
            }
            return
        }

        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }

        do {
            let suggestions = try await service.search(query: trimmed)
            if Task.isCancelled { return }
            await MainActor.run {
                results = suggestions
                isSearching = false
            }
        } catch {
            if Task.isCancelled { return }
            await MainActor.run {
                errorMessage = (error as NSError).localizedDescription
                results = []
                isSearching = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        LocationSearchView(initialQuery: "Kyiv") { _ in }
    }
}
