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
            OnboardingPage(
                title: "Відкрийте свою натальну карту",
                message: "Отримайте точні розрахунки планет, домів та аспектів за кілька хвилин. Розуміння стартує з даних.",
                symbolName: "sparkles",
                highlights: [
                    "Персоналізовані розрахунки на основі дати, часу та місця народження",
                    "Глибокий контекст для кожної планети й аспекту",
                    "Візуальні представлення для легкого сприйняття"
                ]
            ),
            OnboardingPage(
                title: "Оплачуйте лише потрібні сфери",
                message: "Обирайте життєві напрямки, які хочете дослідити просто зараз, та отримуйте миттєві роз’яснення.",
                symbolName: "creditcard",
                highlights: [
                    "П'ять тематичних звітів: фінанси, кар'єра, стосунки, здоров’я, загальний огляд",
                    "Єдине придбання — повний доступ до вибраної сфери",
                    "Зручна історія покупок та повторне завантаження"
                ]
            ),
            OnboardingPage(
                title: "Експерти + ШІ дають глибину",
                message: "Ми поєднуємо перевірені астрологічні правила з сучасними AI-моделями, щоб ви отримували практичні поради.",
                symbolName: "brain.head.profile",
                highlights: [
                    "Кураторський набір правил від фахових астрологів",
                    "AI створює структуровані звіти українською мовою",
                    "Готові до використання рекомендації та сценарії дій"
                ]
            ),
            OnboardingPage(
                title: "Готові розпочати",
                message: "Збережіть прогрес, додайте нові сфери у будь-який момент і повертайтесь до insights, коли потрібно.",
                symbolName: "bolt.heart",
                highlights: [
                    "Onboarding відображається лише один раз",
                    "Ваші дані безпечні завдяки локальному збереженню",
                    "Ви контролюєте, які сфери досліджувати далі"
                ]
            ),
        ]
    }

    static func resetStoredProgress(storage: UserDefaults = .standard) {
        storage.removeObject(forKey: completionKey)
    }
}
