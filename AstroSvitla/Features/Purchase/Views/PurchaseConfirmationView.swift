import SwiftUI

struct PurchaseConfirmationView: View {
    let birthDetails: BirthDetails
    let area: ReportArea
    var onBack: (() -> Void)?
    var onGenerateReport: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summaryCard
                purchaseInfo
                Button(action: onGenerateReport) {
                    Text("Generate \(area.displayName) Report")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Confirm Purchase")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let onBack {
                    Button("Back", action: onBack)
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: area.icon)
                    .font(.title)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(area.displayName)
                        .font(.title3.bold())
                    Text(priceString)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(birthDetails.displayName)
                    .font(.headline)
                Text("\(birthDetails.formattedBirthDate) at \(birthDetails.formattedBirthTime)")
                    .foregroundStyle(.secondary)
                Text(birthDetails.formattedLocation)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var purchaseInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What happens next")
                .font(.headline)

            Label("We will use your birth details with expert astrology rules to craft a personalized report.", systemImage: "sparkles")
            Label("This is a one-time purchase. You can revisit the generated report anytime from the Reports tab (coming soon).", systemImage: "doc.text.magnifyingglass")
            Label("You will not be charged during this preview build.", systemImage: "lock.open")
        }
    }

    private var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: area.price as NSNumber) ?? "$0.00"
    }
}

#Preview {
    NavigationStack {
        PurchaseConfirmationView(
            birthDetails: BirthDetails(
                name: "Alex",
                birthDate: .now,
                birthTime: .now,
                location: "Kyiv, Ukraine"
            ),
            area: .career,
            onBack: {},
            onGenerateReport: {}
        )
    }
}
