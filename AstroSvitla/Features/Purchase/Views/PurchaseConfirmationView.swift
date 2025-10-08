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
                    Text("Згенерувати звіт «\(area.displayName)»")
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
        .navigationTitle("Підтвердження покупки")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let onBack {
                    Button("Назад", action: onBack)
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
                Text("\(birthDetails.formattedBirthDate) о \(birthDetails.formattedBirthTime)")
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
            Text("Що далі")
                .font(.headline)

            Label("Ми використаємо ваші дані народження та експертні астрологічні правила, щоб створити персональний звіт.", systemImage: "sparkles")
            Label("Це одноразова покупка. Ви зможете повертатися до згенерованого звіту в розділі «Звіти» (незабаром).", systemImage: "doc.text.magnifyingglass")
            Label("У цьому прев'ю-збірці з вас не стягуватиметься плата.", systemImage: "lock.open")
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
