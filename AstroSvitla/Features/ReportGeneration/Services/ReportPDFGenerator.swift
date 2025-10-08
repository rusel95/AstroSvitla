import SwiftUI

struct ReportPDFGenerator {

    enum Error: Swift.Error {
        case renderFailed
        case exportFailed
    }

    @MainActor
    func makePDF(
        birthDetails: BirthDetails,
        natalChart: NatalChart,
        report: GeneratedReport
    ) throws -> Data {
        let pageWidth: CGFloat = 612 // 8.5" at 72 DPI
        let horizontalPadding: CGFloat = 40

        let content = ReportPDFContentView(
            birthDetails: birthDetails,
            natalChart: natalChart,
            report: report
        )
        .frame(width: pageWidth - horizontalPadding * 2, alignment: .center)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 48)
        .background(Color.white)
        .environment(\.colorScheme, .light)

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
            throw Error.renderFailed
        }
        return data
    }
}

// MARK: - PDF Content View

private struct ReportPDFContentView: View {
    let birthDetails: BirthDetails
    let natalChart: NatalChart
    let report: GeneratedReport

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            chartSection
            summarySection
            influencesSection
            analysisSection
            recommendationsSection
            footer
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Персональний натальний звіт")
                .font(.title.bold())
            Text("\(birthDetails.displayName) • \(birthDetails.formattedBirthDate) • \(birthDetails.formattedBirthTime)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(birthDetails.formattedLocation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Натальна карта")
                .font(.headline)
            NatalChartWheelView(chart: natalChart)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Короткий огляд")
                .font(.headline)
            Text(report.summary)
                .font(.body)
        }
    }

    private var influencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ключові впливи")
                .font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(report.keyInfluences, id: \.self) { influence in
                    Text("• \(influence)")
                        .font(.body)
                }
            }
        }
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Детальний аналіз")
                .font(.headline)
            Text(report.detailedAnalysis)
                .font(.body)
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Рекомендації")
                .font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(report.recommendations, id: \.self) { recommendation in
                    Text("• \(recommendation)")
                        .font(.body)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("Згенеровано \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
