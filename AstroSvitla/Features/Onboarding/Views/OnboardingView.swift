import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onFinish: () -> Void

    @State private var animateBackground = false

    var body: some View {
        ZStack {
            // Premium animated cosmic background
            CosmicBackgroundView()

            // Additional decorative elements
            GeometryReader { geometry in
                ZStack {
                    // Floating orb 1
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.astroSecondary.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(
                            x: animateBackground ? geometry.size.width * 0.3 : geometry.size.width * 0.4,
                            y: animateBackground ? geometry.size.height * 0.15 : geometry.size.height * 0.1
                        )
                        .blur(radius: 30)

                    // Floating orb 2
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentColor.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .offset(
                            x: animateBackground ? -geometry.size.width * 0.2 : -geometry.size.width * 0.3,
                            y: animateBackground ? geometry.size.height * 0.6 : geometry.size.height * 0.5
                        )
                        .blur(radius: 40)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Glass header with progress
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Крок \(viewModel.currentIndex + 1) з \(viewModel.pages.count)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .tracking(0.3)
                                .foregroundStyle(.secondary)

                            // Premium progress bar with glow
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.accentColor.opacity(0.15))

                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * CGFloat(viewModel.currentIndex + 1) / CGFloat(viewModel.pages.count))
                                        .shadow(color: Color.accentColor.opacity(0.5), radius: 4, x: 0, y: 0)
                                }
                            }
                            .frame(height: 5)
                        }

                        Spacer()

                        // Skip button with glass effect
                        Button(action: {
                            let didFinish = viewModel.skip()
                            if didFinish {
                                onFinish()
                            }
                        }) {
                            Text("Пропустити")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                // Subtle glass divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.1), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // Main carousel
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Premium action buttons with glass container
                VStack(spacing: 14) {
                    // Primary button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            let didFinish = viewModel.advance()
                            if didFinish {
                                onFinish()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(primaryButtonTitle)

                            if viewModel.currentIndex < viewModel.pages.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .buttonStyle(.astroPrimary)

                    // Back button (appears after first page)
                    if viewModel.currentIndex > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.goBack()
                            }
                        }) {
                            Text("Назад")
                        }
                        .buttonStyle(.astroSecondary)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(
                    // Subtle glass footer
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .ignoresSafeArea()
                )
            }
        }
        .onAppear {
            if viewModel.isCompleted {
                onFinish()
            }

            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
            ) {
                animateBackground = true
            }
        }
    }

    private var primaryButtonTitle: String {
        let lastIndex = viewModel.pages.count - 1
        if viewModel.currentIndex == lastIndex {
            return "Розпочати"
        } else {
            return "Далі"
        }
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(),
        onFinish: {}
    )
}
