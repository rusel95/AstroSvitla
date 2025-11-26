import SwiftUI

struct AreaCard: View {
    let area: ReportArea

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 18) {
            // Premium icon container with glass effect
            ZStack {
                // Gradient background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                areaColor.opacity(0.2),
                                areaColor.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Glass overlay
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .frame(width: 56, height: 56)

                // Border
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [areaColor.opacity(0.4), areaColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: area.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [areaColor, areaColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(area.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(priceString)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    // Small decorative dot
                    Circle()
                        .fill(areaColor.opacity(0.5))
                        .frame(width: 4, height: 4)

                    Text(area.shortDescription)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Premium chevron with glow
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 32, height: 32)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1)
    }

    private var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: area.price as NSNumber) ?? "$0.00"
    }

    // Color coding for each area
    private var areaColor: Color {
        switch area {
        case .finances:
            return Color(red: 0.3, green: 0.7, blue: 0.4)
        case .career:
            return Color(red: 0.4, green: 0.5, blue: 0.9)
        case .relationships:
            return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .health:
            return Color(red: 0.4, green: 0.8, blue: 0.8)
        case .general:
            return Color.accentColor
        }
    }
}

// MARK: - ReportArea Extension

extension ReportArea {
    var shortDescription: String {
        switch self {
        case .finances:
            return "Гроші та достаток"
        case .career:
            return "Професія та успіх"
        case .relationships:
            return "Любов та партнерство"
        case .health:
            return "Здоров'я та енергія"
        case .general:
            return "Загальний огляд"
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        ForEach(ReportArea.allCases, id: \.self) { area in
            AreaCard(area: area)
        }
    }
    .padding()
    .background(CosmicBackgroundView())
}
