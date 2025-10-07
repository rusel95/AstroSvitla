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

        let planets = ephemerisService.calculatePlanets(at: utcDate)

        let houseResult = ephemerisService.calculateHouses(
            at: utcDate,
            latitude: latitude,
            longitude: longitude
        )

        let aspects = ephemerisService.calculateAspects(for: planets)

        return ChartCalculatorResult(
            planets: planets,
            houses: houseResult.houses,
            aspects: aspects,
            ascendant: houseResult.ascendant,
            midheaven: houseResult.midheaven
        )
    }
}
