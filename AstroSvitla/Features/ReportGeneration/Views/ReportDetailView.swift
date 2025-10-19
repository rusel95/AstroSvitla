import SwiftUI

struct ReportDetailView: View {
    let birthDetails: BirthDetails
    let natalChart: NatalChart
    let report: GeneratedReport
    @Environment(\.dismiss) private var dismiss

    @State private var isExportingPDF = false
    @State private var exportErrorMessage: String?
    @State private var isShowingErrorAlert = false
    @State private var shareURL: URL?
    @State private var isPresentingShareSheet = false
    @State private var isShowingSuccessAlert = false
    @State private var isShowingKnowledgeLogs = false

    private let pdfGenerator = ReportPDFGenerator()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                chartSection
                summarySection
                influencesSection
                analysisSection
                recommendationsSection
                if Config.isDebugMode {
                    knowledgeLogsButton
                }
                actionButtons
            }
            .padding()
        }
        .navigationTitle(Text(localized("report.navigation_title", report.area.displayName)))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url]) { completed in
                    if completed {
                        isShowingSuccessAlert = true
                    }
                    cleanupShareURL()
                }
            }
        }
        .alert(localized("alert.pdf_failed.title"), isPresented: $isShowingErrorAlert, actions: {
            Button(localized("action.close"), role: .cancel) {
                isShowingErrorAlert = false
            }
        }, message: {
            Text(exportErrorMessage ?? localized("alert.pdf_failed.message"))
        })
        .alert(localized("alert.pdf_saved.title"), isPresented: $isShowingSuccessAlert, actions: {
            Button(localized("action.ok"), role: .cancel) {
                isShowingSuccessAlert = false
            }
        }, message: {
            Text(localized("alert.pdf_saved.message"))
        })
    }

    private var header: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(birthDetails.displayName)
                    .font(.title2.bold())
                Text("\(birthDetails.formattedBirthDate) • \(birthDetails.formattedBirthTime)")
                    .foregroundStyle(.secondary)
                Text(birthDetails.formattedLocation)
                    .foregroundStyle(.secondary)
            }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("report.section.chart", tableName: "Localizable")
                .font(.headline)
            NatalChartWheelView(chart: natalChart)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("report.section.summary", tableName: "Localizable")
                .font(.headline)
            Text(report.summary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var influencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("report.section.influences", tableName: "Localizable")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.keyInfluences, id: \.self) { influence in
                    Label(influence, systemImage: "sparkle")
                        .alignmentGuide(.leading) { _ in 0 }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("report.section.analysis", tableName: "Localizable")
                .font(.headline)
            Text(report.detailedAnalysis)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("report.section.recommendations", tableName: "Localizable")
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.recommendations, id: \.self) { recommendation in
                    Label(recommendation, systemImage: "checkmark.seal.fill")
                        .alignmentGuide(.leading) { _ in 0 }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var knowledgeLogsButton: some View {
        Button {
            isShowingKnowledgeLogs = true
        } label: {
            HStack {
                Image(systemName: "book.closed")
                Text("knowledge_logs.button.title", tableName: "Localizable")
                Spacer()
                if report.knowledgeUsage.vectorSourceUsed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $isShowingKnowledgeLogs) {
            ReportGenerationLogsView(report: report)
        }
    }

    private var actionButtons: some View {
        Button {
            exportReport()
        } label: {
            if isExportingPDF {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Label(localized("report.action.export_pdf"), systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .disabled(isExportingPDF)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exportReport() {
        guard isExportingPDF == false else { return }

        Task { @MainActor in
            isExportingPDF = true
            do {
                let pdfData = try pdfGenerator.makePDF(
                    birthDetails: birthDetails,
                    natalChart: natalChart,
                    report: report
                )
                let url = try writePDFToTemporaryLocation(data: pdfData)
                shareURL = url
                isPresentingShareSheet = true
            } catch {
                exportErrorMessage = error.localizedDescription
                isShowingErrorAlert = true
            }
            isExportingPDF = false
        }
    }

    private func writePDFToTemporaryLocation(data: Data) throws -> URL {
        let filename = "AstroSvitla-\(report.area.rawValue)-\(UUID().uuidString).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func cleanupShareURL() {
        if let url = shareURL {
            try? FileManager.default.removeItem(at: url)
        }
        shareURL = nil
    }
}

#Preview {
    NavigationStack {
        ReportDetailView(
            birthDetails: BirthDetails(
                name: "Alex",
                birthDate: .now,
                birthTime: .now,
                location: "Kyiv, Ukraine"
            ),
            natalChart: NatalChart(
                birthDate: .now,
                birthTime: .now,
                latitude: 50.4501,
                longitude: 30.5234,
                locationName: "Kyiv",
                planets: [],
                houses: [],
                aspects: [],
                houseRulers: [],
                ascendant: 127.5,
                midheaven: 215.3,
                calculatedAt: .now
            ),
            report: GeneratedReport(
                area: .career,
                summary: "Sample summary.",
                keyInfluences: [
                    "First House (Self): Aquarius 12° — inventive instincts help you stand out.",
                    "Jupiter trine Moon — faith and intuition collaborate, sustaining momentum."
                ],
                detailedAnalysis: "Detailed analysis goes here.",
                recommendations: [
                    "Highlight transformation stories.",
                    "Pitch a bold improvement project."
                ],
                knowledgeUsage: KnowledgeUsage(vectorSourceUsed: true, notes: "Used demo snippet 1."),
                metadata: GenerationMetadata(
                    modelName: "gpt-4o-mini",
                    promptTokens: 1500,
                    completionTokens: 800,
                    totalTokens: 2300,
                    estimatedCost: 0.001610,
                    processingTimeSeconds: 3.5,
                    knowledgeSnippetsProvided: 6,
                    totalSourcesCited: 8,
                    vectorDatabaseSourcesCount: 5,
                    externalSourcesCount: 3
                )
            )
        )
    }
}
