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
                    Text(String(localized: "purchase.generate_report", table: "Localizable") + " «\(area.displayName)»")
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
        .navigationTitle(String(localized: "purchase.title", table: "Localizable"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let onBack {
                    Button(String(localized: "action.back", table: "Localizable"), action: onBack)
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
                Text("\(birthDetails.formattedBirthDate) " + String(localized: "purchase.at_time", table: "Localizable") + " \(birthDetails.formattedBirthTime)")
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
            Text(String(localized: "purchase.what_next", table: "Localizable"))
                .font(.headline)

            Label(String(localized: "purchase.info.birth_data", table: "Localizable"), systemImage: "sparkles")
            Label(String(localized: "purchase.info.one_time", table: "Localizable"), systemImage: "doc.text.magnifyingglass")
            Label(String(localized: "purchase.info.preview_build", table: "Localizable"), systemImage: "lock.open")
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
