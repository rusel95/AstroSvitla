import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published private(set) var pages: [OnboardingPage]
    @Published var currentIndex: Int = 0
    @Published private(set) var isCompleted: Bool

    private let storage: UserDefaults
    private static let completionKey = "com.astrosvitla.onboarding.completed"

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        self.pages = OnboardingViewModel.makePages()
        self.isCompleted = storage.bool(forKey: Self.completionKey)
    }

    func advance() -> Bool {
        guard currentIndex < pages.count - 1 else {
            completeOnboarding()
            return true
        }

        currentIndex += 1
        return false
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func skip() -> Bool {
        completeOnboarding()
        return true
    }

    func resetForTesting() {
        isCompleted = false
        currentIndex = 0
        storage.removeObject(forKey: Self.completionKey)
    }

    private func completeOnboarding() {
        guard isCompleted == false else { return }
        isCompleted = true
        storage.set(true, forKey: Self.completionKey)
    }

    private static func makePages() -> [OnboardingPage] {
        [
            // Page 1: Hero Welcome - Hook with time promise
            OnboardingPage(
                title: "Ваш перший астрологічний аналіз за 2 хвилини",
                message: "Дізнайтесь, що зірки кажуть про вашу кар'єру, стосунки та фінанси — без реєстрації, без підписок.",
                symbolName: "sparkles",
                highlights: [],
                badge: OnboardingPage.Badge(
                    text: "Займе лише 2 хвилини",
                    icon: "clock.fill",
                    style: .time
                ),
                timeEstimate: nil,
                accentColor: .cosmic
            ),

            // Page 2: Simple 3-Step Process with time breakdown
            OnboardingPage(
                title: "Три простих кроки до інсайтів",
                message: "Ми зробили процес максимально швидким і зрозумілим.",
                symbolName: "list.number",
                highlights: [
                    "📝 Введіть дату народження — 30 сек",
                    "🎯 Виберіть сферу для аналізу — 10 сек",
                    "✨ Отримайте персональний звіт — 60 сек"
                ],
                badge: OnboardingPage.Badge(
                    text: "Без реєстрації",
                    icon: "person.badge.shield.checkmark.fill",
                    style: .trust
                ),
                timeEstimate: "~2 хв загалом",
                accentColor: .primary
            ),

            // Page 3: What You Get - Value proposition
            OnboardingPage(
                title: "5 сфер вашого життя під контролем",
                message: "Кожен звіт — це глибокий AI-аналіз вашої натальної карти з практичними порадами.",
                symbolName: "chart.pie.fill",
                highlights: [
                    "💰 Фінанси та матеріальний потенціал",
                    "💼 Кар'єра та професійний розвиток",
                    "❤️ Стосунки та партнерство",
                    "🏥 Здоров'я та енергія",
                    "⭐️ Загальний портрет особистості"
                ],
                badge: OnboardingPage.Badge(
                    text: "від $5.99 за звіт",
                    icon: "tag.fill",
                    style: .value
                ),
                timeEstimate: nil,
                accentColor: .warm
            ),

            // Page 4: Trust & Ready - Final CTA
            OnboardingPage(
                title: "Готові побачити свою карту?",
                message: "Ваші дані зберігаються лише на вашому пристрої. Почніть прямо зараз — перший профіль безкоштовний.",
                symbolName: "rocket.fill",
                highlights: [
                    "🔒 100% приватність — дані не покидають пристрій",
                    "⚡️ Миттєвий розрахунок натальної карти",
                    "📚 Аналіз на основі класичної астрології"
                ],
                badge: OnboardingPage.Badge(
                    text: "Почніть безкоштовно",
                    icon: "gift.fill",
                    style: .action
                ),
                timeEstimate: nil,
                accentColor: .success
            )
        ]
    }

    static func resetStoredProgress(storage: UserDefaults = .standard) {
        storage.removeObject(forKey: completionKey)
    }
}
