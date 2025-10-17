import Foundation

/// Represents the planetary ruler of a house based on the zodiac sign on the house cusp.
/// Uses traditional rulerships (pre-modern astrology) for determining which planet governs each house.
struct HouseRuler: Codable, Identifiable, Sendable {
    let id: UUID
    let houseNumber: Int
    let rulingPlanet: PlanetType
    let rulerSign: ZodiacSign
    let rulerHouse: Int
    let rulerLongitude: Double
    
    init(
        id: UUID = UUID(),
        houseNumber: Int,
        rulingPlanet: PlanetType,
        rulerSign: ZodiacSign,
        rulerHouse: Int,
        rulerLongitude: Double
    ) {
        self.id = id
        self.houseNumber = houseNumber
        self.rulingPlanet = rulingPlanet
        self.rulerSign = rulerSign
        self.rulerHouse = rulerHouse
        self.rulerLongitude = rulerLongitude
    }
}
