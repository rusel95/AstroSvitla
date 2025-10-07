import Foundation

struct ChartCalculatorResult {
    let planets: [Planet]
    let houses: [House]
    let aspects: [Aspect]
    let ascendant: Double
    let midheaven: Double
}

final class ChartCalculator {

    private let ephemerisService: SwissEphemerisService

    init(ephemerisService: SwissEphemerisService = SwissEphemerisService()) {
        self.ephemerisService = ephemerisService
    }

    func calculate(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String,
        latitude: Double,
        longitude: Double
    ) throws -> ChartCalculatorResult {

        let utcDate = try ephemerisService.utcDate(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: timeZoneIdentifier
        )

        let houseResult = ephemerisService.calculateHouses(
            at: utcDate,
            latitude: latitude,
            longitude: longitude
        )

        let planets = ephemerisService
            .calculatePlanets(at: utcDate)
            .map { assignHouse(for: $0, using: houseResult.houses) }

        let aspects = ephemerisService.calculateAspects(for: planets)

        return ChartCalculatorResult(
            planets: planets,
            houses: houseResult.houses,
            aspects: aspects,
            ascendant: houseResult.ascendant,
            midheaven: houseResult.midheaven
        )
    }

    private func assignHouse(for planet: Planet, using houses: [House]) -> Planet {
        guard let house = houseContaining(planetLongitude: planet.longitude, houses: houses) else {
            return planet
        }

        return Planet(
            id: planet.id,
            name: planet.name,
            longitude: planet.longitude,
            latitude: planet.latitude,
            sign: planet.sign,
            house: house.number,
            isRetrograde: planet.isRetrograde,
            speed: planet.speed
        )
    }

    private func houseContaining(planetLongitude: Double, houses: [House]) -> House? {
        guard houses.count == 12 else { return nil }

        let ordered = houses.sorted { $0.number < $1.number }

        for index in 0..<ordered.count {
            let current = ordered[index]
            let next = ordered[(index + 1) % ordered.count]

            if isLongitude(planetLongitude, between: current.cusp, and: next.cusp) {
                return current
            }
        }

        return ordered.first
    }

    private func isLongitude(_ value: Double, between start: Double, and end: Double) -> Bool {
        let normalizedValue = normalize(value)
        let normalizedStart = normalize(start)
        let normalizedEnd = normalize(end)

        if normalizedStart < normalizedEnd {
            return (normalizedStart...normalizedEnd).contains(normalizedValue)
        } else {
            return normalizedValue >= normalizedStart || normalizedValue <= normalizedEnd
        }
    }

    private func normalize(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }
}
