import Foundation

enum PlanetType: String, Codable, CaseIterable, Sendable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"
}

struct Planet: Codable, Identifiable, Sendable {
    let id: UUID
    let name: PlanetType
    let longitude: Double
    let latitude: Double
    let sign: ZodiacSign
    let house: Int
    let isRetrograde: Bool
    let speed: Double

    init(
        id: UUID = UUID(),
        name: PlanetType,
        longitude: Double,
        latitude: Double,
        sign: ZodiacSign,
        house: Int,
        isRetrograde: Bool,
        speed: Double
    ) {
        self.id = id
        self.name = name
        self.longitude = longitude
        self.latitude = latitude
        self.sign = sign
        self.house = house
        self.isRetrograde = isRetrograde
        self.speed = speed
    }
}
