import SwiftUI
import SwiftData

struct ReportListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ReportListViewModel()
    @State private var isShowingErrorAlert = false
    private let allowsDismiss: Bool
    private let showsTitle: Bool

    init(allowsDismiss: Bool = false, showsTitle: Bool = false) {
        self.allowsDismiss = allowsDismiss
        self.showsTitle = showsTitle
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sections.isEmpty {
                    emptyState
                } else {
                    listView
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .navigationTitle(showsTitle ? localized("nav.reports") : "")
            .toolbar {
                if allowsDismiss {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(localized("action.close")) {
                            dismiss()
                        }
                    }
                }
            }
            .task {
                viewModel.configureIfNeeded(with: modelContext)
            }
            .refreshable {
                viewModel.refresh()
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                isShowingErrorAlert = newValue != nil
            }
            .alert(localized("alert.generic.title"), isPresented: $isShowingErrorAlert, actions: {
                Button(localized("action.close"), role: .cancel) {
                    isShowingErrorAlert = false
                }
            }, message: {
                Text(viewModel.errorMessage ?? localized("alert.generic.message"))
            })
        }
    }

    private var listView: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.reports) { item in
                        NavigationLink {
                            SavedReportDetailView(item: item)
                        } label: {
                            ReportListRow(item: item)
                        }
                    }
                } header: {
                    ReportSectionHeader(title: section.chartName, subtitle: section.chartSubtitle, isOrphan: section.isOrphan)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "reports.empty.title",
            systemImage: "doc.text.magnifyingglass",
            description: Text("reports.empty.description", tableName: "Localizable")
        )
        .padding()
    }
}

// MARK: - Row & Header Views

private struct ReportListRow: View {
    let item: ReportListViewModel.Item

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.areaIconName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.areaDisplayName)
                    .font(.headline)
                Text(item.purchaseDateText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.readingTimeText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(item.languageDisplay)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct ReportSectionHeader: View {
    let title: String
    let subtitle: String
    let isOrphan: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.callout.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            if isOrphan {
                Text("reports.section.orphan_notice", tableName: "Localizable")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .textCase(nil)
    }
}

// MARK: - Saved Report Detail

private struct SavedReportDetailView: View {
    let item: ReportListViewModel.Item

    var body: some View {
        Group {
            if let prepared = preparedViewData {
                ReportDetailView(
                    birthDetails: prepared.birthDetails,
                    natalChart: prepared.natalChart,
                    report: prepared.generatedReport,
                    onGenerateAnother: nil,
                    onStartOver: nil
                )
                .background(Color(.systemBackground))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.areaDisplayName)
                                .font(.title2.bold())
                            Text("\(item.purchaseDateText) • \(item.readingTimeText) • \(item.languageDisplay)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        Text(item.report.reportText)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(Text(item.areaDisplayName))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var preparedViewData: PreparedViewData? {
        guard
            let generatedReport = item.report.generatedReport,
            let chartEntity = item.report.chart,
            let natalChart = chartEntity.decodedNatalChart()
        else {
            return nil
        }

        let birthDetails = chartEntity.makeBirthDetails()

        return PreparedViewData(
            birthDetails: birthDetails,
            natalChart: natalChart,
            generatedReport: generatedReport
        )
    }

    private struct PreparedViewData {
        let birthDetails: BirthDetails
        let natalChart: NatalChart
        let generatedReport: GeneratedReport
    }
}
