import SwiftUI
import UIKit

struct ReportDetailView: View {
    let birthDetails: BirthDetails
    let natalChart: NatalChart
    let report: GeneratedReport
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isExportingPDF = false
    @State private var exportErrorMessage: String?
    @State private var isShowingErrorAlert = false
    @State private var shareURL: URL?
    @State private var isPresentingShareSheet = false
    @State private var isShowingSuccessAlert = false
    @State private var isShowingKnowledgeLogs = false
    
    // Instagram Share State
    @State private var isShowingInstagramShareSheet = false
    @State private var selectedTemplateType: ShareTemplateType?
    @State private var isShowingTemplatePreview = false
    @State private var instagramShareImages: [GeneratedShareImage] = []
    @State private var chartImage: UIImage?

    private let pdfGenerator = ReportPDFGenerator()

    // MARK: - Theme Colors

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.96, green: 0.95, blue: 0.98)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color(red: 0.4, green: 0.4, blue: 0.45)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color(red: 0.85, green: 0.83, blue: 0.88)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 24)

                chartSection
                    .padding(.bottom, 24)

                summarySection
                    .padding(.bottom, 20)

                influencesSection
                    .padding(.bottom, 20)

                analysisSection
                    .padding(.bottom, 20)

                recommendationsSection
                    .padding(.bottom, 24)

                if AppPreferences.shared.isDevModeEnabled {
                    knowledgeLogsButton
                        .padding(.bottom, 16)
                }

                actionButtons
                    .padding(.bottom, 24)

                footer
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle(Text("Звіт: \(report.area.displayName)"))
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
        .alert("Помилка експорту", isPresented: $isShowingErrorAlert, actions: {
            Button("Закрити", role: .cancel) {
                isShowingErrorAlert = false
            }
        }, message: {
            Text(exportErrorMessage ?? "Не вдалося експортувати PDF")
        })
        .alert("PDF збережено", isPresented: $isShowingSuccessAlert, actions: {
            Button("OK", role: .cancel) {
                isShowingSuccessAlert = false
            }
        }, message: {
            Text("Звіт успішно експортовано")
        })
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Logo and title
            HStack(spacing: 12) {
                // App icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AstroSvitla")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryTextColor)

                    Text("Астрологічний звіт")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }

                Spacer()

                // Report type badge
                Text(report.area.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // User info card
            VStack(alignment: .leading, spacing: 8) {
                Text(birthDetails.displayName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTextColor)

                HStack(spacing: 16) {
                    Label(birthDetails.formattedBirthDate, systemImage: "calendar")
                    Label(birthDetails.formattedBirthTime, systemImage: "clock")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(secondaryTextColor)

                Label(birthDetails.formattedLocation, systemImage: "mappin.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Натальна карта", icon: "circle.hexagongrid.fill", hint: "Натисніть для збільшення")

            NatalChartWheelView(chart: natalChart, allowsZoom: true)
                .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Резюме", icon: "text.alignleft")

            Text(report.summary)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(primaryTextColor)
                .lineSpacing(5)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        }
    }

    // MARK: - Influences Section

    private var influencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Ключові впливи", icon: "sparkle")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(report.keyInfluences.enumerated()), id: \.offset) { index, influence in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 20)

                        Text(influence)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(primaryTextColor)
                            .lineSpacing(4)
                    }

                    if index < report.keyInfluences.count - 1 {
                        Divider()
                            .background(borderColor)
                    }
                }
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Детальний аналіз", icon: "doc.text.magnifyingglass")

            Text(report.detailedAnalysis)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(primaryTextColor)
                .lineSpacing(5)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        }
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Рекомендації", icon: "checkmark.seal.fill")

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(report.recommendations.enumerated()), id: \.offset) { index, recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 24, height: 24)

                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Text(recommendation)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(primaryTextColor)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.08), Color.accentColor.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Knowledge Logs Button

    private var knowledgeLogsButton: some View {
        Button {
            isShowingKnowledgeLogs = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "book.closed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text("Логи генерування")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(primaryTextColor)

                Spacer()

                if report.knowledgeUsage.vectorSourceUsed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $isShowingKnowledgeLogs) {
            ReportGenerationLogsView(report: report)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // PDF Export Button
            Button {
                exportReport()
            } label: {
                HStack(spacing: 12) {
                    if isExportingPDF {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text(isExportingPDF ? "Генерування PDF..." : "Експортувати PDF")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isExportingPDF
                            ? [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.4)]
                            : [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isExportingPDF)
            .animation(.easeInOut(duration: 0.2), value: isExportingPDF)
            
            // Instagram Share Button
            if report.shareContent != nil {
                instagramShareButton
            }
        }
    }
    
    private var instagramShareButton: some View {
        Button {
            openInstagramShareSheet()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Поділитись в Instagram")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(primaryTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .sheet(isPresented: $isShowingInstagramShareSheet) {
            InstagramShareSheet(
                report: report,
                birthDetails: birthDetails,
                chartImage: chartImage,
                onSelectTemplate: { templateType, images in
                    selectedTemplateType = templateType
                    instagramShareImages = images
                    isShowingInstagramShareSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowingTemplatePreview = true
                    }
                },
                onDismiss: {
                    isShowingInstagramShareSheet = false
                }
            )
        }
        .sheet(isPresented: $isShowingTemplatePreview) {
            if let templateType = selectedTemplateType {
                InstagramTemplatePreview(
                    templateType: templateType,
                    images: instagramShareImages,
                    onShare: {
                        shareInstagramImages()
                    },
                    onDismiss: {
                        isShowingTemplatePreview = false
                    }
                )
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(borderColor)
                .frame(height: 1)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Згенеровано за допомогою AstroSvitla")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(secondaryTextColor)

                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(secondaryTextColor.opacity(0.7))
                }

                Spacer()
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String, hint: String? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(primaryTextColor)

            if let hint = hint {
                Spacer()
                Text(hint)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(secondaryTextColor)
            }
        }
    }

    // MARK: - Actions

    private func exportReport() {
        guard isExportingPDF == false else { return }

        isExportingPDF = true

        // Schedule PDF generation after UI has updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.generateAndSharePDF()
        }
    }

    private func generateAndSharePDF() {
        let pdfTheme: ReportPDFGenerator.PDFTheme = colorScheme == .dark ? .dark : .light

        do {
            let pdfData = try pdfGenerator.makePDF(
                birthDetails: birthDetails,
                natalChart: natalChart,
                report: report,
                theme: pdfTheme
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

    private func writePDFToTemporaryLocation(data: Data) throws -> URL {
        // Sanitize name for filename (remove special characters)
        let sanitizedName = birthDetails.displayName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespaces)
        
        let filename = "AstroSvitla_\(sanitizedName)_\(report.area.displayName).pdf"
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
    
    // MARK: - Instagram Share Actions
    
    private func openInstagramShareSheet() {
        guard report.shareContent != nil else { return }
        isShowingInstagramShareSheet = true
    }
    
    private func shareInstagramImages() {
        let imagesToShare = instagramShareImages.map { $0.image }
        guard !imagesToShare.isEmpty else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: imagesToShare,
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Find the topmost presented view controller
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            // Configure for iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(
                    x: topController.view.bounds.midX,
                    y: topController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            
            topController.present(activityVC, animated: true) {
                // Close the preview after presenting share sheet
                self.isShowingTemplatePreview = false
            }
        }
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
                summary: "Sample summary text that describes the overall findings of the astrological analysis for career.",
                keyInfluences: [
                    "First House (Self): Aquarius 12° — inventive instincts help you stand out.",
                    "Jupiter trine Moon — faith and intuition collaborate, sustaining momentum.",
                    "Saturn in 10th House — discipline and structure in career matters."
                ],
                detailedAnalysis: "Detailed analysis goes here with comprehensive information about planetary positions and their influence on career path.",
                recommendations: [
                    "Highlight transformation stories in your professional narrative.",
                    "Pitch a bold improvement project to showcase your innovative thinking.",
                    "Network with like-minded professionals during favorable planetary transits."
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
