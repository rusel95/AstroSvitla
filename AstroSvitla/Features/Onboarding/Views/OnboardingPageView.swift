import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: page.symbolName)
                .font(.system(size: 96))
                .foregroundStyle(Color.accentColor)
                .padding()
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(page.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if page.highlights.isEmpty == false {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(page.highlights, id: \.self) { highlight in
                            Label(highlight, systemImage: "checkmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.callout)
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            title: "Заголовок",
            message: "Опис сторінки, що пояснює ключову цінність застосунку.",
            symbolName: "sparkles",
            highlights: [
                "Перевага номер один",
                "Перевага номер два",
                "Перевага номер три"
            ]
        )
    )
    .padding()
}
