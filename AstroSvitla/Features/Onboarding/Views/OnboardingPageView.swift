import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    @State private var animateIcon = false
    @State private var animateRing = false

    var body: some View {
        VStack(spacing: 0) {
            // Premium icon area with layered effects
            ZStack {
                // Outer animated marble ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.marbleWhite.opacity(0.3),
                                Color.marbleVein.opacity(0.15),
                                Color.marbleWhite.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(animateRing ? 360 : 0))

                // Decorative circles with gradient fill
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.12),
                                Color.accentColor.opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(animateIcon ? 1.05 : 1.0)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Glass inner circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.accentColor.opacity(0.15), radius: 16, x: 0, y: 8)

                // Main icon with gradient
                Image(systemName: page.symbolName)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    .scaleEffect(animateIcon ? 1.03 : 1.0)
            }
            .frame(height: 260)
            .padding(.bottom, 20)

            // Content area with improved typography
            VStack(spacing: 20) {
                // Title with better styling
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(0.2)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                // Description
                Text(page.message)
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                // Highlights/Features with glass cards
                if page.highlights.isEmpty == false {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(page.highlights, id: \.self) { highlight in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.12))
                                        .frame(width: 26, height: 26)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color.accentColor)
                                }

                                Text(highlight)
                                    .font(.system(size: 14, weight: .regular))
                                    .lineSpacing(2)
                                    .foregroundStyle(.primary)

                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                animateIcon = true
            }
            withAnimation(
                .linear(duration: 20)
                .repeatForever(autoreverses: false)
            ) {
                animateRing = true
            }
        }
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
