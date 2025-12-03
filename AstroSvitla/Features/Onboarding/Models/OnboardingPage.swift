import Foundation

struct OnboardingPage: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let message: String
    let symbolName: String
    let highlights: [String]

    // New conversion-focused properties
    let badge: Badge?
    let timeEstimate: String?
    let accentColor: AccentStyle

    init(
        title: String,
        message: String,
        symbolName: String,
        highlights: [String] = [],
        badge: Badge? = nil,
        timeEstimate: String? = nil,
        accentColor: AccentStyle = .primary
    ) {
        self.title = title
        self.message = message
        self.symbolName = symbolName
        self.highlights = highlights
        self.badge = badge
        self.timeEstimate = timeEstimate
        self.accentColor = accentColor
    }

    struct Badge: Hashable, Sendable {
        let text: String
        let icon: String
        let style: BadgeStyle

        enum BadgeStyle: Hashable, Sendable {
            case time      // Clock icon, emphasizes speed
            case trust     // Shield icon, emphasizes security
            case value     // Star icon, emphasizes benefit
            case action    // Rocket icon, emphasizes progress
        }
    }

    enum AccentStyle: Hashable, Sendable {
        case primary
        case cosmic
        case warm
        case success
    }
}
