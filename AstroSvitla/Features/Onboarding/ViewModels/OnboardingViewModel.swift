import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published private(set) var pages: [OnboardingPage]
    @Published var currentIndex: Int = 0
    @Published private(set) var isCompleted: Bool

    private let storage: UserDefaults
    private let isPreviewMode: Bool
    private static let completionKey = "com.astrosvitla.onboarding.completed"

    init(storage: UserDefaults = .standard, isPreviewMode: Bool = false) {
        self.storage = storage
        self.isPreviewMode = isPreviewMode
        self.pages = OnboardingViewModel.makePages()
        // In preview mode, always show onboarding regardless of stored completion status
        self.isCompleted = isPreviewMode ? false : storage.bool(forKey: Self.completionKey)
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
        // Don't persist completion status in preview mode
        if !isPreviewMode {
            storage.set(true, forKey: Self.completionKey)
        }
    }

    private static func makePages() -> [OnboardingPage] {
        [
            // Page 1: Hero Welcome - Hook with time promise
            OnboardingPage(
                title: String(localized: "onboarding.page1.title"),
                message: String(localized: "onboarding.page1.message"),
                symbolName: "sparkles",
                highlights: [],
                badge: OnboardingPage.Badge(
                    text: String(localized: "onboarding.page1.badge"),
                    icon: "clock.fill",
                    style: .time
                ),
                timeEstimate: nil,
                accentColor: .cosmic
            ),

            // Page 2: Simple 3-Step Process with time breakdown
            OnboardingPage(
                title: String(localized: "onboarding.page2.title"),
                message: String(localized: "onboarding.page2.message"),
                symbolName: "list.number",
                highlights: [
                    String(localized: "onboarding.page2.step1"),
                    String(localized: "onboarding.page2.step2"),
                    String(localized: "onboarding.page2.step3")
                ],
                badge: OnboardingPage.Badge(
                    text: String(localized: "onboarding.page2.badge"),
                    icon: "person.badge.shield.checkmark.fill",
                    style: .trust
                ),
                timeEstimate: String(localized: "onboarding.page2.time_estimate"),
                accentColor: .primary
            ),

            // Page 3: What You Get - Value proposition
            OnboardingPage(
                title: String(localized: "onboarding.page3.title"),
                message: String(localized: "onboarding.page3.message"),
                symbolName: "chart.pie.fill",
                highlights: [
                    String(localized: "onboarding.page3.area1"),
                    String(localized: "onboarding.page3.area2"),
                    String(localized: "onboarding.page3.area3"),
                    String(localized: "onboarding.page3.area4"),
                    String(localized: "onboarding.page3.area5")
                ],
                badge: OnboardingPage.Badge(
                    text: String(localized: "onboarding.page3.badge"),
                    icon: "tag.fill",
                    style: .value
                ),
                timeEstimate: nil,
                accentColor: .warm
            ),

            // Page 4: Trust & Ready - Final CTA with free report highlight
            OnboardingPage(
                title: String(localized: "onboarding.page4.title"),
                message: String(localized: "onboarding.page4.message"),
                symbolName: "gift.fill",
                highlights: [
                    String(localized: "onboarding.page4.free_report", defaultValue: "🎁 First report is FREE"),
                    String(localized: "onboarding.page4.feature1"),
                    String(localized: "onboarding.page4.feature2"),
                    String(localized: "onboarding.page4.feature3")
                ],
                badge: OnboardingPage.Badge(
                    text: String(localized: "onboarding.page4.badge"),
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
