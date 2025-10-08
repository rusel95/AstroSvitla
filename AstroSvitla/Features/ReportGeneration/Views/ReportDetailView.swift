import SwiftUI

struct ReportDetailView: View {
    let birthDetails: BirthDetails
    let natalChart: NatalChart
    let report: GeneratedReport
    var onGenerateAnother: (() -> Void)?
    var onStartOver: (() -> Void)?

    @State private var isExportingPDF = false
    @State private var exportErrorMessage: String?
    @State private var isShowingErrorAlert = false
    @State private var shareURL: URL?
    @State private var isPresentingShareSheet = false
    @State private var isShowingSuccessAlert = false

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
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Звіт: \(report.area.displayName)")
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
        .alert("Не вдалося експортувати", isPresented: $isShowingErrorAlert, actions: {
            Button("Закрити", role: .cancel) {
                isShowingErrorAlert = false
            }
        }, message: {
            Text(exportErrorMessage ?? "Спробуйте ще раз трохи пізніше.")
        })
        .alert("Збережено", isPresented: $isShowingSuccessAlert, actions: {
            Button("Гаразд", role: .cancel) {
                isShowingSuccessAlert = false
            }
        }, message: {
            Text("PDF збережено або надіслано успішно.")
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
            Text("Натальна карта")
                .font(.headline)
            NatalChartWheelView(chart: natalChart)
                .frame(height: 350)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Короткий огляд")
                .font(.headline)
            Text(report.summary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var influencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ключові впливи")
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
            Text("Детальний аналіз")
                .font(.headline)
            Text(report.detailedAnalysis)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Рекомендації")
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

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                exportReport()
            } label: {
                if isExportingPDF {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Label("Експортувати у PDF", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(isExportingPDF)

            if let onGenerateAnother {
                Button("Згенерувати для іншої сфери") {
                    onGenerateAnother()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let onStartOver {
                Button("Почати спочатку") {
                    onStartOver()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.secondary)
            }
        }
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
                ]
            ),
            onGenerateAnother: {},
            onStartOver: {}
        )
    }
}
