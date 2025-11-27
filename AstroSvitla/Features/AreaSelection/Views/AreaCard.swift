import SwiftUI

struct AreaCard: View {
    let area: ReportArea
    var isPurchased: Bool = false
    var onViewReport: (() -> Void)? = nil

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
                                iconColor.opacity(0.2),
                                iconColor.opacity(0.08)
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
                            colors: [iconColor.opacity(0.4), iconColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 56, height: 56)

                // Main area icon (keep original icon even when purchased)
                Image(systemName: area.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isPurchased 
                                ? [Color.green, Color.green.opacity(0.7)]
                                : [areaColor, areaColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Checkmark badge overlay for purchased (bottom-right corner)
                if isPurchased {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 20, y: 20)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(area.displayName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    if isPurchased {
                        // Show "Already purchased" badge
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                            Text("Вже придбано")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.green)
                    } else {
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
            }

            Spacer()

            // Action indicator
            ZStack {
                Circle()
                    .fill(isPurchased ? Color.green.opacity(0.1) : Color.accentColor.opacity(0.08))
                    .frame(width: 32, height: 32)

                Image(systemName: isPurchased ? "eye.fill" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isPurchased ? Color.green : Color.accentColor)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isPurchased 
                            ? [Color.green.opacity(0.3), Color.green.opacity(0.1)]
                            : [Color.white.opacity(0.2), Color.white.opacity(0.08)],
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

    // Color for the icon - green if purchased
    private var iconColor: Color {
        isPurchased ? .green : areaColor
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
        // Not purchased
        AreaCard(area: .finances, isPurchased: false)
        AreaCard(area: .career, isPurchased: false)
        
        // Already purchased
        AreaCard(area: .relationships, isPurchased: true)
        AreaCard(area: .health, isPurchased: true)
        
        AreaCard(area: .general, isPurchased: false)
    }
    .padding()
    .background(CosmicBackgroundView())
}
