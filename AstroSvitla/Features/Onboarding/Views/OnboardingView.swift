import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            // Background animation with gradient
            VStack {
                Spacer()
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .offset(y: 200)
                    .blur(radius: 40)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Крок \(viewModel.currentIndex + 1) з \(viewModel.pages.count)")
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .tracking(0.5)
                                .foregroundStyle(.secondary)

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.accentColor.opacity(0.2))

                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.accentColor)
                                        .frame(width: geometry.size.width * CGFloat(viewModel.currentIndex + 1) / CGFloat(viewModel.pages.count))
                                }
                            }
                            .frame(height: 4)
                        }

                        Spacer()

                        // Skip button (always visible)
                        Button(action: {
                            let didFinish = viewModel.skip()
                            if didFinish {
                                onFinish()
                            }
                        }) {
                            Text("Пропустити")
                                .font(.system(size: 14, weight: .semibold, design: .default))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                Divider()
                    .opacity(0.2)

                // Main carousel
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Action buttons (sticky at bottom)
                VStack(spacing: 12) {
                    // Primary button
                    Button(action: {
                        let didFinish = viewModel.advance()
                        if didFinish {
                            onFinish()
                        }
                    }) {
                        HStack {
                            Text(primaryButtonTitle)
                                .font(.system(size: 16, weight: .semibold, design: .default))

                            if viewModel.currentIndex < viewModel.pages.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold, design: .default))
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)

                    // Back button (appears after first page)
                    if viewModel.currentIndex > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.goBack()
                            }
                        }) {
                            Text("Назад")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundStyle(.secondary)
                                .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .onAppear {
            if viewModel.isCompleted {
                onFinish()
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
