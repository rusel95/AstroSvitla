import Foundation

struct OnboardingPage: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let message: String
    let symbolName: String
    let highlights: [String]
}
