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
                // Skip button at top right
                HStack {
                    Spacer()

                    Button(action: {
                        let didFinish = viewModel.skip()
                        if didFinish {
                            onFinish()
                        }
                    }) {
                        Text("onboarding.skip")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Main carousel
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Bottom action area with buttons and step indicator together
                VStack(spacing: 12) {
                    // Primary CTA button with dynamic text
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            let didFinish = viewModel.advance()
                            if didFinish {
                                onFinish()
                            }
                        }
                    }) {
                        HStack(spacing: 10) {
                            Text(primaryButtonTitle)

                            Image(systemName: primaryButtonIcon)
                                .font(.system(size: 14, weight: .semibold))
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                    .buttonStyle(.astroPrimary)

                    // Contextual hint below button on last page
                    if isLastPage {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 11, weight: .medium))
                            Text("onboarding.first_analysis_hint")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Back button (appears after first page)
                    if viewModel.currentIndex > 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.goBack()
                            }
                        }) {
                            Text("action.back")
                        }
                        .buttonStyle(.astroSecondary)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }

                    // Step counter and progress bar
                    VStack(spacing: 6) {
                        Text("onboarding.step_counter \(viewModel.currentIndex + 1) \(viewModel.pages.count)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)

                        // Progress bar with dots
                        HStack(spacing: 8) {
                            ForEach(0..<viewModel.pages.count, id: \.self) { index in
                                Circle()
                                    .fill(index <= viewModel.currentIndex ? Color.accentColor : Color.accentColor.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == viewModel.currentIndex ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3), value: viewModel.currentIndex)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    // Subtle glass footer
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .ignoresSafeArea()
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentIndex)
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

    // MARK: - Computed Properties

    private var isLastPage: Bool {
        viewModel.currentIndex == viewModel.pages.count - 1
    }

    private var primaryButtonTitle: LocalizedStringKey {
        if isLastPage {
            return "onboarding.button.create_profile"
        } else if viewModel.currentIndex == 0 {
            return "onboarding.button.start"
        } else {
            return "onboarding.button.next"
        }
    }

    private var primaryButtonIcon: String {
        if isLastPage {
            return "sparkles"
        } else {
            return "arrow.right"
        }
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(),
        onFinish: {}
    )
}
