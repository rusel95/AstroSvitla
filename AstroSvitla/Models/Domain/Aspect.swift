import Foundation

enum AspectType: String, Codable, Sendable {
    case conjunction = "Conjunction"
    case opposition = "Opposition"
    case trine = "Trine"
    case square = "Square"
    case sextile = "Sextile"

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .opposition: return 180
        case .trine: return 120
        case .square: return 90
        case .sextile: return 60
        }
    }

    var maxOrb: Double {
        switch self {
        case .conjunction, .opposition: return 8.0
        case .trine, .square: return 7.0
        case .sextile: return 6.0
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
