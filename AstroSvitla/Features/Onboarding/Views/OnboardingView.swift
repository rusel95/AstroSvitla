import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageIndicators

            actionButtons
        }
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .onAppear {
            if viewModel.isCompleted {
                onFinish()
            }
        }
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentIndex ? Color.accentColor : Color.accentColor.opacity(0.2))
                    .frame(width: index == viewModel.currentIndex ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentIndex)
            }
        }
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(primaryButtonTitle) {
                let didFinish = viewModel.advance()
                if didFinish {
                    onFinish()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)

            Button("Пропустити") {
                let didFinish = viewModel.skip()
                if didFinish {
                    onFinish()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
    }

    private var primaryButtonTitle: String {
        viewModel.currentIndex == viewModel.pages.count - 1 ? "Почати" : "Далі"
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(),
        onFinish: {}
    )
}
