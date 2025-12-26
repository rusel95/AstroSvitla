import Foundation

enum ReportArea: String, Codable, CaseIterable, Sendable {
    case finances
    case career
    case relationships
    case health
    case general

    var displayName: String {
        switch self {
        case .finances: return String(localized: "area.finances")
        case .career: return String(localized: "area.career")
        case .relationships: return String(localized: "area.relationships")
        case .health: return String(localized: "area.health")
        case .general: return String(localized: "area.general")
        }
    }

    var icon: String {
        switch self {
        case .finances: return "dollarsign.circle.fill"
        case .career: return "briefcase.fill"
        case .relationships: return "heart.fill"
        case .health: return "heart.text.square.fill"
        case .general: return "star.circle.fill"
        }
    }

}
