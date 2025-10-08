import Foundation

enum ZodiacSign: String, Codable, CaseIterable, Sendable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"

    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius:
            return .fire
        case .taurus, .virgo, .capricorn:
            return .earth
        case .gemini, .libra, .aquarius:
            return .air
        case .cancer, .scorpio, .pisces:
            return .water
        }
    }

    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn:
            return .cardinal
        case .taurus, .leo, .scorpio, .aquarius:
            return .fixed
        case .gemini, .virgo, .sagittarius, .pisces:
            return .mutable
        }
    }

    var degreeRange: ClosedRange<Double> {
        guard let index = ZodiacSign.allCases.firstIndex(of: self) else {
            return 0...0
        }
        let start = Double(index) * 30.0
        return start...(start + 30.0)
    }

    /// Convert an ecliptic longitude degree (0-360) to zodiac sign
    static func from(degree: Double) -> ZodiacSign {
        let normalizedDegree = degree.truncatingRemainder(dividingBy: 360)
        let signIndex = Int(normalizedDegree / 30.0)
        return ZodiacSign.allCases[signIndex % 12]
    }
}

enum Element: String, Codable, Sendable {
    case fire = "Fire"
    case earth = "Earth"
    case air = "Air"
    case water = "Water"
}

enum Modality: String, Codable, Sendable {
    case cardinal = "Cardinal"
    case fixed = "Fixed"
    case mutable = "Mutable"
}
