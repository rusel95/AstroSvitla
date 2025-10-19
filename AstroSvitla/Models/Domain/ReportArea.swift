import Foundation

enum ReportArea: String, Codable, CaseIterable, Sendable {
    case finances
    case career
    case relationships
    case health
    case general

    var displayName: String {
        switch self {
        case .finances: return "Фінанси"
        case .career: return "Кар'єра"
        case .relationships: return "Стосунки"
        case .health: return "Здоров'я"
        case .general: return "Загальний звіт"
        }
    }

    var price: Decimal {
        switch self {
        case .general: return Decimal(string: "9.99")!
        case .finances, .career: return Decimal(string: "6.99")!
        case .relationships, .health: return Decimal(string: "5.99")!
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
