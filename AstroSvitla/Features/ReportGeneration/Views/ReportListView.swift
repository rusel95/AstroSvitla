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
            ZStack {
                // Premium cosmic background
                CosmicBackgroundView()
                
                Group {
                    if viewModel.sections.isEmpty {
                        emptyState
                    } else {
                        listView
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .navigationTitle(showsTitle ? Text("report.list.title") : Text(""))
            .toolbar {
                if allowsDismiss {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("action.close") {
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
            .alert(Text("error.title"), isPresented: $isShowingErrorAlert, actions: {
                Button("action.close", role: .cancel) {
                    isShowingErrorAlert = false
                }
            }, message: {
                Text(viewModel.errorMessage ?? String(localized: "error.generic"))
            })
        }
    }

    private var listView: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(viewModel.sections) { section in
                    // Glass card for each profile section
                    VStack(alignment: .leading, spacing: 16) {
                        // Section header
                        ReportSectionHeader(
                            title: section.chartName,
                            subtitle: section.chartSubtitle,
                            isOrphan: section.isOrphan
                        )
                        
                        // Report cards
                        VStack(spacing: 12) {
                            ForEach(section.reports) { item in
                                NavigationLink {
                                    SavedReportDetailView(item: item)
                                } label: {
                                    ReportListRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .glassCard(cornerRadius: 20, padding: 18, intensity: .regular)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            // Glass icon container
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("report.empty.title", bundle: .main)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("report.empty.description", bundle: .main)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .glassCard(cornerRadius: 24, padding: 0, intensity: .regular)
        .padding(.horizontal, 20)
    }
}

// MARK: - Row & Header Views

private struct ReportListRow: View {
    let item: ReportListViewModel.Item

    var body: some View {
        HStack(spacing: 18) {
            // Premium icon container with glass effect
            ZStack {
                // Gradient background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                areaColor.opacity(0.2),
                                areaColor.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Glass overlay
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .frame(width: 56, height: 56)

                // Border
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [areaColor.opacity(0.4), areaColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 56, height: 56)

                // Icon
                Image(systemName: item.areaIconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [areaColor, areaColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.areaDisplayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(item.purchaseDateText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    Circle()
                        .fill(areaColor.opacity(0.5))
                        .frame(width: 4, height: 4)
                    
                    Text(item.languageDisplay)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Action indicator - eye to view
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 32, height: 32)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
    }
    
    // Color coding for each area
    private var areaColor: Color {
        guard let area = ReportArea(rawValue: item.report.area) else {
            return Color.accentColor
        }
        
        switch area {
        case .finances:
            return Color(red: 0.3, green: 0.7, blue: 0.4)
        case .career:
            return Color(red: 0.4, green: 0.5, blue: 0.9)
        case .relationships:
            return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .health:
            return Color(red: 0.4, green: 0.8, blue: 0.8)
        case .general:
            return Color.accentColor
        }
    }
}

private struct ReportSectionHeader: View {
    let title: String
    let subtitle: String
    let isOrphan: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Profile icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .frame(width: 44, height: 44)
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: isOrphan ? "person.crop.circle.badge.questionmark" : "person.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                
                if isOrphan {
                    Text("report.orphan.label", bundle: .main)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
        }
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
                    languageCode: item.report.language
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
        // Debug: Check what's nil
        print("[SavedReportDetailView] Checking report data availability:")
        print("  - report.generatedReport: \(item.report.generatedReport != nil)")
        print("  - report.profile: \(item.report.profile != nil)")

        guard let generatedReport = item.report.generatedReport else {
            print("  ❌ generatedReport is nil")
            return nil
        }

        guard let profile = item.report.profile else {
            print("  ❌ profile is nil")
            return nil
        }

        guard let chartEntity = profile.chart else {
            print("  ❌ profile.chart is nil")
            return nil
        }

        print("  - chartDataJSON length: \(chartEntity.chartDataJSON.count)")

        guard let natalChart = chartEntity.decodedNatalChart() else {
            print("  ❌ decodedNatalChart() returned nil")
            return nil
        }

        guard let birthDetails = chartEntity.makeBirthDetails() else {
            print("  ❌ makeBirthDetails() returned nil")
            return nil
        }

        print("  ✅ All data available, showing full report with chart")
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
