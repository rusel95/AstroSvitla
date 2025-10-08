import SwiftUI

struct AreaCard: View {
    let area: ReportArea
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: area.icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(area.displayName)
                    .font(.headline)
                Text(priceString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: area.price as NSNumber) ?? "$0.00"
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    AreaCard(area: .general)
        .padding()
}
