import SwiftUI

struct AreaCard: View {
    let area: ReportArea
    var isPurchased: Bool = false
    var hasCredit: Bool = false
    var onViewReport: (() -> Void)? = nil
    var purchaseService: PurchaseService?

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

                // Main area icon (always show original icon)
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
                    if isPurchased {
                        // Show "Already purchased" badge
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                            Text("area.badge.purchased")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.green)
                    } else if hasCredit {
                        // User has credit - don't show price, just description
                        Text(area.shortDescription)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        // No credit - show price and description
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
        if let service = purchaseService {
            return service.getProductPrice()
        }
        // Fallback if service not provided
        return String(localized: "purchase.price.unavailable", defaultValue: "Payment Unavailable")
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
            return String(localized: "area.finances.description")
        case .career:
            return String(localized: "area.career.description")
        case .relationships:
            return String(localized: "area.relationships.description")
        case .health:
            return String(localized: "area.health.description")
        case .general:
            return String(localized: "area.general.description")
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
