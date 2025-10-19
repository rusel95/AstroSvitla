import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.98)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Icon area with enhanced styling
                ZStack {
                    // Decorative circles in background
                    Circle()
                        .fill(Color.accentColor.opacity(0.08))
                        .frame(width: 280, height: 280)

                    Circle()
                        .fill(Color.accentColor.opacity(0.04))
                        .frame(width: 360, height: 360)

                    // Main icon
                    Image(systemName: page.symbolName)
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor,
                                    Color.accentColor.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(height: 240)
                .padding(.bottom, 16)

                // Content area
                VStack(spacing: 20) {
                    // Title - More prominent
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .tracking(0.3)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    // Description
                    Text(page.message)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .lineHeight(1.5)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    // Highlights/Features
                    if page.highlights.isEmpty == false {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(page.highlights, id: \.self) { highlight in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 24)
                                        .padding(.top, 2)

                                    Text(highlight)
                                        .font(.system(size: 14, weight: .regular, design: .default))
                                        .lineHeight(1.4)
                                        .foregroundStyle(.primary)

                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.vertical, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Helper for line height
extension Text {
    func lineHeight(_ height: CGFloat) -> Text {
        self
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            title: "Натальна карта",
            message: "Отримайте точні розрахунки планет, домів та аспектів. Розуміння стартує з даних.",
            symbolName: "sparkles",
            highlights: [
                "Персоналізовані розрахунки на основі дати, часу та місця",
                "Глибокий контекст для кожної планети й аспекту",
                "Візуальні представлення для легкого сприйняття"
            ]
        )
    )
}
