import Foundation

/// Provides lookup utilities for traditional (pre-modern) planetary rulerships by zodiac sign.
/// These rulerships follow classical sources such as Ptolemy's *Tetrabiblos* and are used when
/// calculating which planet governs a given house cusp.
struct TraditionalRulershipTable {

    private static let rulerships: [ZodiacSign: PlanetType] = [
        .aries: .mars,
        .taurus: .venus,
        .gemini: .mercury,
        .cancer: .moon,
        .leo: .sun,
        .virgo: .mercury,
        .libra: .venus,
        .scorpio: .mars,
        .sagittarius: .jupiter,
        .capricorn: .saturn,
        .aquarius: .saturn,
        .pisces: .jupiter,
    ]

    /// Returns the traditional planetary ruler for the supplied zodiac sign.
    /// - Parameter sign: The zodiac sign occupying a house cusp.
    /// - Returns: The planet that traditionally rules the provided sign.
    static func ruler(of sign: ZodiacSign) -> PlanetType {
        guard let ruler = rulerships[sign] else {
            assertionFailure("Missing traditional rulership mapping for sign: \(sign)")
            return .sun
        }
        return ruler
    }
}
