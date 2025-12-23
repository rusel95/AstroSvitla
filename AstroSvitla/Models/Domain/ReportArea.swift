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

    /// Uniform pricing for all report types per spec 008-implement-in-app
    /// All reports are $4.99 USD (Tier 5)
    var price: Decimal {
        return Decimal(string: "4.99")!
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

    var productIdentifier: String {
        switch self {
        case .general: return Config.ProductID.generalReport
        case .finances: return Config.ProductID.financesReport
        case .career: return Config.ProductID.careerReport
        case .relationships: return Config.ProductID.relationshipsReport
        case .health: return Config.ProductID.healthReport
        }
    }
}
