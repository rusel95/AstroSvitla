import SwiftUI

struct ReportDetailView: View {
    let birthDetails: BirthDetails
    let report: GeneratedReport
    var onGenerateAnother: (() -> Void)?
    var onStartOver: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                summarySection
                influencesSection
                analysisSection
                recommendationsSection
                actionButtons
            }
            .padding()
        }
        .navigationTitle("\(report.area.displayName) Report")
        .navigationBarTitleDisplayMode(.inline)
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

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.headline)
            Text(report.summary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var influencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Influences")
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
            Text("Detailed Analysis")
                .font(.headline)
            Text(report.detailedAnalysis)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
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
            if let onGenerateAnother {
                Button("Generate another area") {
                    onGenerateAnother()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let onStartOver {
                Button("Start over") {
                    onStartOver()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
