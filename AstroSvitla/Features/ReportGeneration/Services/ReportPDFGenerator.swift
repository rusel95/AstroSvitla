import SwiftUI
import Sentry

struct ReportPDFGenerator {

    enum Error: Swift.Error {
        case renderFailed
        case exportFailed
    }

    enum PDFTheme {
        case light
        case dark

        var colorScheme: ColorScheme {
            switch self {
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    @MainActor
    func makePDF(
        birthDetails: BirthDetails,
        natalChart: NatalChart,
        report: GeneratedReport,
        theme: PDFTheme = .light
    ) throws -> Data {
        let pageWidth: CGFloat = 612 // 8.5" at 72 DPI
        let horizontalPadding: CGFloat = 32

        // Pre-load chart image synchronously for PDF rendering
        let chartImage = loadChartImage(for: natalChart)

        let content = ReportPDFContentView(
            birthDetails: birthDetails,
            natalChart: natalChart,
            report: report,
            chartImage: chartImage,
            theme: theme
        )
        .frame(width: pageWidth - horizontalPadding * 2, alignment: .center)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 40)
        .background(theme == .dark ? Color(red: 0.08, green: 0.06, blue: 0.15) : Color.white)
        .environment(\.colorScheme, theme.colorScheme)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        var data = Data()

        renderer.render { size, render in
            guard let mutableData = NSMutableData() as CFMutableData?,
                  let consumer = CGDataConsumer(data: mutableData),
                  var mediaBox = Optional(CGRect(origin: .zero, size: size)),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                return
            }

            context.beginPDFPage(nil)
            render(context)
            context.endPDFPage()
            context.closePDF()

            data = mutableData as Data
        }

        guard data.isEmpty == false else {
            // Log PDF rendering failure
            SentrySDK.capture(message: "Unexpected: PDF rendering failed") { scope in
                scope.setLevel(.error)
                scope.setTag(value: "report_generation", key: "service")
                scope.setTag(value: "pdf_generation", key: "operation")
                scope.setExtra(value: "Generated PDF data is empty", key: "error_details")
                scope.setExtra(value: birthDetails.displayName, key: "subject")
            }
            throw Error.renderFailed
        }
        return data
    }

    /// Load chart image synchronously for PDF rendering
    /// This is needed because ImageRenderer doesn't support async loading
    private func loadChartImage(for chart: NatalChart) -> UIImage? {
        guard let imageFileID = chart.imageFileID else {
            print("[ReportPDFGenerator] No cached image metadata found")
            return nil
        }

        let imageCacheService = ImageCacheService()

        // First try to load PNG version (pre-rendered for PDF)
        if imageCacheService.imageExists(fileID: imageFileID, format: "png") {
            do {
                let pngData = try imageCacheService.loadImage(fileID: imageFileID, format: "png")
                if let image = UIImage(data: pngData) {
                    print("[ReportPDFGenerator] ✅ Loaded PNG chart image (\(pngData.count) bytes)")
                    return image
                }
            } catch {
                print("[ReportPDFGenerator] Failed to load PNG: \(error)")
            }
        }

        // Fallback: try to load original format
        guard let imageFormat = chart.imageFormat else {
            return nil
        }

        do {
            let imageData = try imageCacheService.loadImage(fileID: imageFileID, format: imageFormat)

            // For SVG, we can't render synchronously - will show fallback
            if imageFormat.lowercased() == "svg" {
                print("[ReportPDFGenerator] ⚠️ SVG found but no PNG cache - chart will show fallback info")
                return nil
            } else {
                return UIImage(data: imageData)
            }
        } catch {
            print("[ReportPDFGenerator] Failed to load chart image: \(error)")
            return nil
        }
    }

    /// Convert SVG data to UIImage for PDF rendering using Core Graphics
    private func convertSVGToImage(data: Data, theme: PDFTheme) -> UIImage? {
        // This is deprecated - we now use pre-rendered PNG from NatalChartService
        print("[ReportPDFGenerator] ⚠️ SVG conversion deprecated - using PNG cache instead")
        return nil
    }
}

// MARK: - PDF Content View

private struct ReportPDFContentView: View {
    let birthDetails: BirthDetails
    let natalChart: NatalChart
    let report: GeneratedReport
    let chartImage: UIImage?
    let theme: ReportPDFGenerator.PDFTheme

    // MARK: - Theme Colors

    private var backgroundColor: Color {
        theme == .dark ? Color(red: 0.08, green: 0.06, blue: 0.15) : Color.white
    }

    private var cardBackground: Color {
        theme == .dark ? Color.white.opacity(0.08) : Color(red: 0.96, green: 0.95, blue: 0.98)
    }

    private var primaryTextColor: Color {
        theme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
    }

    private var secondaryTextColor: Color {
        theme == .dark ? Color.white.opacity(0.7) : Color(red: 0.4, green: 0.4, blue: 0.45)
    }

    private var accentColor: Color {
        Color(red: 0.5, green: 0.4, blue: 0.8) // Astro purple
    }

    private var borderColor: Color {
        theme == .dark ? Color.white.opacity(0.15) : Color(red: 0.85, green: 0.83, blue: 0.88)
    }

    var body: some View {
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

            footer
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Logo and title
            HStack(spacing: 12) {
                // App icon placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
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

                    Text("report.header.subtitle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(accentColor)
                }

                Spacer()

                // Report type badge
                Text(report.area.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.12))
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
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(secondaryTextColor)

                Label(birthDetails.formattedLocation, systemImage: "mappin.circle.fill")
                    .font(.system(size: 12, weight: .medium))
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
            sectionHeader(title: String(localized: "report.section.natal_chart"), icon: "circle.hexagongrid.fill")

            if let image = chartImage {
                // Calculate proper aspect ratio from the actual image
                let imageAspectRatio = image.size.width / image.size.height

                // Display the pre-loaded chart image with correct proportions
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(imageAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(theme == .dark ? Color.white.opacity(0.05) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
            } else {
                // Fallback: show basic chart info
                VStack(spacing: 16) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(accentColor.opacity(0.5))

                    VStack(spacing: 8) {
                        HStack(spacing: 24) {
                            chartInfoItem(label: "ASC", value: formatDegree(natalChart.ascendant), sign: ZodiacSign.from(degree: natalChart.ascendant))
                            chartInfoItem(label: "MC", value: formatDegree(natalChart.midheaven), sign: ZodiacSign.from(degree: natalChart.midheaven))
                        }

                        Text("\(natalChart.planets.count) планет • \(natalChart.aspects.count) аспектів")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(secondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
            }
        }
    }

    private func chartInfoItem(label: String, value: String, sign: ZodiacSign) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(accentColor)
            Text("\(value) \(sign.symbol)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(primaryTextColor)
        }
    }

    private func formatDegree(_ degree: Double) -> String {
        let normalized = degree.truncatingRemainder(dividingBy: 360)
        let degrees = Int(normalized) % 30
        let minutes = Int((normalized - Double(Int(normalized))) * 60)
        return String(format: "%d°%02d'", degrees, minutes)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: String(localized: "report.section.summary"), icon: "text.alignleft")

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
            sectionHeader(title: String(localized: "report.section.key_influences"), icon: "sparkle")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(report.keyInfluences.enumerated()), id: \.offset) { index, influence in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(accentColor)
                            .frame(width: 18)

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
            .padding(18)
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
            sectionHeader(title: String(localized: "report.section.detailed_analysis"), icon: "doc.text.magnifyingglass")

            Text(report.detailedAnalysis)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(primaryTextColor)
                .lineSpacing(5)
                .padding(18)
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
            sectionHeader(title: String(localized: "report.section.recommendations"), icon: "checkmark.seal.fill")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(report.recommendations.enumerated()), id: \.offset) { index, recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 24, height: 24)

                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(accentColor)
                        }

                        Text(recommendation)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(primaryTextColor)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [accentColor.opacity(0.08), accentColor.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
            )
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
                    Text("report.footer.generated_with")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(secondaryTextColor)

                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(secondaryTextColor.opacity(0.7))
                }

                Spacer()
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accentColor)

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(primaryTextColor)
        }
    }
}
