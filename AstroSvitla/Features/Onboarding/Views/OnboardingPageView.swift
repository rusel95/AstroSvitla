import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    @State private var animateIcon = false
    @State private var animateRing = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            // Badge (if present) - appears at top
            if let badge = page.badge {
                OnboardingBadgeView(badge: badge)
                    .padding(.bottom, 12)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -10)
            }

            // Premium icon area with layered effects
            ZStack {
                    // Subtle outer glow (no ring/circle stroke)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    accentColor.opacity(0.12),
                                    accentColor.opacity(0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)

                    // Glass inner circle (main icon container)
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 110, height: 110)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: accentColor.opacity(0.2), radius: 20, x: 0, y: 10)

                    // Main icon with gradient
                    Image(systemName: page.symbolName)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: iconGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                }
                .frame(height: 180)
                .padding(.bottom, 16)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)

                // Content area with improved typography
                VStack(spacing: 12) {
                    // Title with better styling
                    Text(page.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .tracking(0.2)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Description
                    Text(page.message)
                        .font(.system(size: 14, weight: .regular))
                        .lineSpacing(4)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Time estimate pill (if present)
                    if let timeEstimate = page.timeEstimate {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 12, weight: .semibold))
                            Text(timeEstimate)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(accentColor.opacity(0.12), in: Capsule())
                        .padding(.top, 4)
                        .opacity(showContent ? 1 : 0)
                    }

                    // Highlights/Features with enhanced glass cards
                    if page.highlights.isEmpty == false {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(page.highlights.enumerated()), id: \.element) { index, highlight in
                                HStack(alignment: .center, spacing: 12) {
                                    // Animated checkmark or number
                                    ZStack {
                                        Circle()
                                            .fill(accentColor.opacity(0.15))
                                            .frame(width: 24, height: 24)

                                        if highlight.hasPrefix("📝") || highlight.hasPrefix("🎯") || highlight.hasPrefix("✨") {
                                            // Show emoji as-is for step indicators
                                            Text(String(highlight.prefix(2)))
                                                .font(.system(size: 12))
                                        } else {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(accentColor)
                                        }
                                    }

                                    Text(cleanHighlightText(highlight))
                                        .font(.system(size: 13, weight: .medium))
                                        .lineSpacing(2)
                                        .lineLimit(2)
                                        .foregroundStyle(.primary.opacity(0.9))

                                    Spacer(minLength: 0)
                                }
                                .opacity(showContent ? 1 : 0)
                                .offset(x: showContent ? 0 : -20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(0.3 + Double(index) * 0.08),
                                    value: showContent
                                )
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 16)
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Staggered content appearance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }

            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                animateIcon = true
            }
            withAnimation(
                .linear(duration: 15)
                .repeatForever(autoreverses: false)
            ) {
                animateRing = true
            }
        }
        .onDisappear {
            showContent = false
        }
    }

    // MARK: - Helper Properties

    private var accentColor: Color {
        switch page.accentColor {
        case .primary: return .accentColor
        case .cosmic: return Color(red: 0.5, green: 0.4, blue: 0.9)
        case .warm: return Color(red: 0.9, green: 0.6, blue: 0.3)
        case .success: return Color(red: 0.3, green: 0.75, blue: 0.5)
        }
    }

    private var accentGradientColors: [Color] {
        [
            accentColor.opacity(0.1),
            accentColor.opacity(0.4),
            accentColor.opacity(0.7),
            accentColor.opacity(0.4),
            accentColor.opacity(0.1)
        ]
    }

    private var iconGradientColors: [Color] {
        [accentColor, accentColor.opacity(0.7)]
    }

    private func cleanHighlightText(_ text: String) -> String {
        // Remove leading emoji if present (for step indicators)
        let emojis = ["📝 ", "🎯 ", "✨ ", "💰 ", "💼 ", "❤️ ", "🏥 ", "⭐️ ", "🔒 ", "⚡️ ", "📚 "]
        for emoji in emojis {
            if text.hasPrefix(emoji) {
                return String(text.dropFirst(emoji.count))
            }
        }
        return text
    }
}

// MARK: - Badge View

struct OnboardingBadgeView: View {
    let badge: OnboardingPage.Badge

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: badge.icon)
                .font(.system(size: 13, weight: .semibold))

            Text(badge.text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(badgeTextColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(badgeBackground, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(badgeBorderColor, lineWidth: 1)
        )
        .shadow(color: badgeShadowColor, radius: 8, x: 0, y: 4)
    }

    private var badgeTextColor: Color {
        switch badge.style {
        case .time: return Color(red: 0.2, green: 0.5, blue: 0.8)
        case .trust: return Color(red: 0.3, green: 0.65, blue: 0.45)
        case .value: return Color(red: 0.85, green: 0.55, blue: 0.2)
        case .action: return Color(red: 0.55, green: 0.35, blue: 0.85)
        }
    }

    private var badgeBackground: some ShapeStyle {
        switch badge.style {
        case .time:
            return AnyShapeStyle(Color(red: 0.2, green: 0.5, blue: 0.8).opacity(0.12))
        case .trust:
            return AnyShapeStyle(Color(red: 0.3, green: 0.65, blue: 0.45).opacity(0.12))
        case .value:
            return AnyShapeStyle(Color(red: 0.85, green: 0.55, blue: 0.2).opacity(0.12))
        case .action:
            return AnyShapeStyle(Color(red: 0.55, green: 0.35, blue: 0.85).opacity(0.12))
        }
    }

    private var badgeBorderColor: Color {
        badgeTextColor.opacity(0.3)
    }

    private var badgeShadowColor: Color {
        badgeTextColor.opacity(0.15)
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            title: "Ваш перший астрологічний аналіз за 2 хвилини",
            message: "Дізнайтесь, що зірки кажуть про вашу кар'єру, стосунки та фінанси.",
            symbolName: "sparkles",
            highlights: [
                "📝 Введіть дату народження — 30 сек",
                "🎯 Виберіть сферу для аналізу — 10 сек",
                "✨ Отримайте персональний звіт — 60 сек"
            ],
            badge: OnboardingPage.Badge(
                text: "Займе лише 2 хвилини",
                icon: "clock.fill",
                style: .time
            ),
            timeEstimate: "~2 хв загалом",
            accentColor: .cosmic
        )
    )
    .background(Color(.systemGroupedBackground))
}
