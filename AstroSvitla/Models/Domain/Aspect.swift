import Foundation

enum AspectType: String, Codable, Sendable {
    case conjunction = "Conjunction"
    case opposition = "Opposition"
    case trine = "Trine"
    case square = "Square"
    case sextile = "Sextile"
    case quincunx = "Quincunx"
    case semisextile = "Semisextile"
    case semisquare = "Semisquare"
    case sesquisquare = "Sesquisquare"
    case quintile = "Quintile"
    case biquintile = "Biquintile"

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .opposition: return 180
        case .trine: return 120
        case .square: return 90
        case .sextile: return 60
        case .quincunx: return 150
        case .semisextile: return 30
        case .semisquare: return 45
        case .sesquisquare: return 135
        case .quintile: return 72
        case .biquintile: return 144
        }
    }

    var maxOrb: Double {
        switch self {
        case .conjunction, .opposition: return 8.0
        case .trine, .square: return 7.0
        case .sextile: return 6.0
        case .quincunx, .semisextile, .semisquare, .sesquisquare: return 3.0
        case .quintile, .biquintile: return 2.0
        }
    }
}

struct Aspect: Codable, Identifiable, Sendable {
    let id: UUID
    let planet1: PlanetType
    let planet2: PlanetType
    let type: AspectType
    let orb: Double
    let isApplying: Bool

    init(
        id: UUID = UUID(),
        planet1: PlanetType,
        planet2: PlanetType,
        type: AspectType,
        orb: Double,
        isApplying: Bool
    ) {
        self.id = id
        self.planet1 = planet1
        self.planet2 = planet2
        self.type = type
        let normalizedOrb = abs(orb)
        let clampedOrb = min(max(0, normalizedOrb), type.maxOrb)
        self.orb = clampedOrb
        self.isApplying = isApplying
    }
}
