import Foundation

enum ChartCalculatorError: LocalizedError, Equatable {
    case invalidTimeZone(String)
    case invalidHouseData

    var errorDescription: String? {
        switch self {
        case .invalidTimeZone(let identifier):
            return "Invalid timezone identifier: \(identifier)"
        case .invalidHouseData:
            return "House calculation returned invalid data."
        }
    }
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
        longitude: Double,
        locationName: String
    ) async throws -> NatalChart {

        let utcDate: Date
        do {
            utcDate = try ephemerisService.utcDate(
                birthDate: birthDate,
                birthTime: birthTime,
                timeZoneIdentifier: timeZoneIdentifier
            )
        } catch {
            throw ChartCalculatorError.invalidTimeZone(timeZoneIdentifier)
        }

        let houseResult = try ephemerisService.calculateHouses(
            at: utcDate,
            latitude: latitude,
            longitude: longitude
        )

        guard houseResult.houses.count == 12 else {
            throw ChartCalculatorError.invalidHouseData
        }

        let planets = try ephemerisService
            .calculatePlanets(at: utcDate)
            .map { assignHouse(for: $0, using: houseResult.houses) }

        let aspects = ephemerisService.calculateAspects(for: planets)

        return NatalChart(
            birthDate: birthDate,
            birthTime: birthTime,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            planets: planets,
            houses: houseResult.houses,
            aspects: aspects,
            ascendant: houseResult.ascendant,
            midheaven: houseResult.midheaven,
            calculatedAt: Date()
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
