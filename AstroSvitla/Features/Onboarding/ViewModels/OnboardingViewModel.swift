import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published private(set) var pages: [OnboardingPage]
    @Published var currentIndex: Int = 0
    @Published private(set) var isCompleted: Bool
    @Published private(set) var priceText: String = "$5"

    private let storage: UserDefaults
    private let isPreviewMode: Bool
    private static let completionKey = "com.astrosvitla.onboarding.completed"
    private static let defaultPriceText = "$5"
    
    /// Page index where price badge is shown (0-indexed)
    private static let pricePageIndex = 2

    init(storage: UserDefaults = .standard, isPreviewMode: Bool = false) {
        self.storage = storage
        self.isPreviewMode = isPreviewMode
        self.pages = OnboardingViewModel.makePages(priceText: Self.defaultPriceText)
        // In preview mode, always show onboarding regardless of stored completion status
        self.isCompleted = isPreviewMode ? false : storage.bool(forKey: Self.completionKey)
    }
    
    /// Update price text from PurchaseService
    /// Call this after products are loaded to show real StoreKit price
    func updatePriceText(from purchaseService: PurchaseService) {
        let newPrice = purchaseService.getOnboardingPriceText()
        guard newPrice != priceText else { return }
        
        priceText = newPrice
        // Rebuild page 3 with new price
        updatePriceBadge(with: newPrice)
    }
    
    private func updatePriceBadge(with price: String) {
        guard pages.indices.contains(Self.pricePageIndex) else { return }
        
        let oldPage = pages[Self.pricePageIndex]
        let localizedTemplate = String(localized: "onboarding.page3.badge")
        // Replace static price (e.g., $5.99) with dynamic price from StoreKit
        let newBadgeText = localizedTemplate.replacingOccurrences(
            of: "\\$\\d+\\.?\\d*",
            with: price,
            options: .regularExpression
        )
        
        let newPage = OnboardingPage(
            title: oldPage.title,
            message: oldPage.message,
            symbolName: oldPage.symbolName,
            highlights: oldPage.highlights,
            badge: OnboardingPage.Badge(
                text: newBadgeText,
                icon: "tag.fill",
                style: .value
            ),
            timeEstimate: oldPage.timeEstimate,
            accentColor: oldPage.accentColor
        )
        
        pages[Self.pricePageIndex] = newPage
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

    private static func makePages(priceText: String) -> [OnboardingPage] {
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
                    // Use existing localization with dynamic price replacement
                    text: {
                        let template = String(localized: "onboarding.page3.badge")
                        return template.replacingOccurrences(
                            of: "\\$\\d+\\.?\\d*",
                            with: priceText,
                            options: .regularExpression
                        )
                    }(),
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
