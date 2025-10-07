import Foundation
import SwissEphemeris
@testable import AstroSvitla
import Testing

struct SwissEphemerisServiceTests {

    private let service = SwissEphemerisService()
    private let utc = TimeZone(secondsFromGMT: 0)!

    @Test
    func testInvalidTimeZoneThrows() {
        #expect(throws: SwissEphemerisServiceError.invalidTimeZoneIdentifier("Mars/Base")) {
            _ = try service.timeZone(from: "Mars/Base")
        }
    }

    @Test
    func testLocalDateCombinesDateAndTime() throws {
        let timeZone = try service.timeZone(from: "Europe/Kyiv")
        let birthDate = makeDate(year: 1990, month: 4, day: 15, hour: 0, minute: 0, timeZone: timeZone)
        let birthTime = makeDate(year: 1990, month: 4, day: 15, hour: 14, minute: 30, timeZone: timeZone)

        let combined = try service.localDate(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZone: timeZone
        )

        let expected = makeDate(year: 1990, month: 4, day: 15, hour: 14, minute: 30, timeZone: timeZone)
        #expect(abs(combined.timeIntervalSince(expected)) < 1)
    }

    @Test
    func testUTCConversionRespectsDSTOffset() throws {
        let timeZone = try service.timeZone(from: "America/New_York")
        let birthDate = makeDate(year: 2023, month: 7, day: 4, hour: 0, minute: 0, timeZone: timeZone)
        let birthTime = makeDate(year: 2023, month: 7, day: 4, hour: 10, minute: 15, timeZone: timeZone)

        let utcDate = try service.utcDate(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZone: timeZone
        )

        let expectedUTC = makeDate(year: 2023, month: 7, day: 4, hour: 14, minute: 15, timeZone: utc)
        #expect(abs(utcDate.timeIntervalSince(expectedUTC)) < 1)

        let offset = try service.secondsFromGMT(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: "America/New_York"
        )
        #expect(offset == -14_400)
    }

    @Test
    func testUTCConversionAcrossStandardTime() throws {
        let timeZone = try service.timeZone(from: "America/New_York")
        let birthDate = makeDate(year: 2023, month: 1, day: 15, hour: 0, minute: 0, timeZone: timeZone)
        let birthTime = makeDate(year: 2023, month: 1, day: 15, hour: 10, minute: 15, timeZone: timeZone)

        let utcDate = try service.utcDate(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZone: timeZone
        )

        let expectedUTC = makeDate(year: 2023, month: 1, day: 15, hour: 15, minute: 15, timeZone: utc)
        #expect(abs(utcDate.timeIntervalSince(expectedUTC)) < 1)

        let offset = try service.secondsFromGMT(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: "America/New_York"
        )
        #expect(offset == -18_000)
    }

    @Test
    func testCalculatePlanetMatchesReferenceCoordinate() {
        let date = makeDate(year: 2023, month: 7, day: 4, hour: 14, minute: 15, timeZone: utc)

        let planet = service.calculatePlanet(.sun, at: date)
        let reference = Coordinate(body: SwissEphemeris.Planet.sun, date: date)
        let expectedLongitude = normalize(reference.longitude)
        let expectedSign = mapToDomainSign(reference.tropical.sign)

        #expect(abs(planet.longitude - expectedLongitude) < 0.0001)
        #expect(abs(planet.latitude - reference.latitude) < 0.0001)
        #expect(planet.sign == expectedSign)
        #expect(abs(planet.speed - reference.speedLongitude) < 0.0001)
        #expect(planet.isRetrograde == (reference.speedLongitude < 0))
        #expect(planet.house == 0)
    }

    @Test
    func testCalculatePlanetsCoversAllBodies() {
        let date = makeDate(year: 2023, month: 7, day: 4, hour: 14, minute: 15, timeZone: utc)
        let planets = service.calculatePlanets(at: date)

        #expect(planets.count == PlanetType.allCases.count)
        #expect(Set(planets.map(\.name)).count == PlanetType.allCases.count)
    }

    @Test
    func testCalculateAspectsMatchesSwissEphemeris() {
        let date = makeDate(year: 2023, month: 7, day: 4, hour: 14, minute: 15, timeZone: utc)
        let planets = service.calculatePlanets(at: date)

        let aspects = service.calculateAspects(for: planets)
        #expect(!aspects.isEmpty)

        // Validate Sun/Mercury aspect using SwissEphemeris
        guard
            let sun = planets.first(where: { $0.name == .sun }),
            let mercury = planets.first(where: { $0.name == .mercury })
        else {
            Issue.record("Required planets missing from calculation output")
            return
        }

        guard let swissAspect = SwissEphemeris.Aspect(
            a: sun.longitude,
            b: mercury.longitude,
            orb: 8.0
        ) else {
            Issue.record("SwissEphemeris returned no aspect for Sun/Mercury")
            return
        }

        let expectedType: AspectType
        let expectedOrb: Double

        switch swissAspect {
        case .conjunction(let remainder):
            expectedType = .conjunction
            expectedOrb = abs(remainder)
        case .sextile(let remainder):
            expectedType = .sextile
            expectedOrb = abs(remainder)
        case .square(let remainder):
            expectedType = .square
            expectedOrb = abs(remainder)
        case .trine(let remainder):
            expectedType = .trine
            expectedOrb = abs(remainder)
        case .opposition(let remainder):
            expectedType = .opposition
            expectedOrb = abs(remainder)
        }

        guard let aspect = aspects.first(where: {
            ($0.planet1 == .sun && $0.planet2 == .mercury) ||
            ($0.planet1 == .mercury && $0.planet2 == .sun)
        }) else {
            Issue.record("Service did not produce Sun-Mercury aspect")
            return
        }

        #expect(aspect.type == expectedType)
        #expect(abs(aspect.orb - expectedOrb) < 0.01)
    }

    // TODO: Re-enable once SwissEphemeris aspect calculation no longer crashes the simulator
    // @Test
    // func testAspectOrbOverrideFiltersResults() {
    //     let date = makeDate(year: 2023, month: 7, day: 4, hour: 14, minute: 15, timeZone: utc)
    //     let planets = service.calculatePlanets(at: date)
    //
    //     let defaultAspects = service.calculateAspects(for: planets)
    //
    //     let tightOverrides: [AspectType: Double] = [
    //         .conjunction: 0.5,
    //         .sextile: 0.5,
    //         .square: 0.5,
    //         .trine: 0.5,
    //         .opposition: 0.5,
    //     ]
    //
    //     let filteredAspects = service.calculateAspects(for: planets, orbOverrides: tightOverrides)
    //
    //     #expect(filteredAspects.count <= defaultAspects.count)
    //     #expect(filteredAspects.allSatisfy { $0.orb <= 0.5 })
    // }

    @Test
    func testRetrogradeDetectionForMercury() {
        let retrogradeDate = makeDate(year: 2023, month: 9, day: 10, hour: 12, minute: 0, timeZone: utc)
        let directDate = makeDate(year: 2023, month: 7, day: 1, hour: 12, minute: 0, timeZone: utc)

        let retrogradeMercury = service.calculatePlanet(.mercury, at: retrogradeDate)
        let directMercury = service.calculatePlanet(.mercury, at: directDate)

        #expect(retrogradeMercury.isRetrograde)
        #expect(!directMercury.isRetrograde)
    }

    @Test
    func testRetrogradeDetectionForOuterPlanet() {
        let retrogradeDate = makeDate(year: 2023, month: 9, day: 10, hour: 12, minute: 0, timeZone: utc)
        let directDate = makeDate(year: 2024, month: 2, day: 1, hour: 12, minute: 0, timeZone: utc)

        let retrogradeNeptune = service.calculatePlanet(.neptune, at: retrogradeDate)
        let directNeptune = service.calculatePlanet(.neptune, at: directDate)

        #expect(retrogradeNeptune.isRetrograde)
        #expect(!directNeptune.isRetrograde)
    }

    @Test
    func testIsRetrogradeHelperUsesSwissEphemerisSpeed() {
        let retrogradeDate = makeDate(year: 2023, month: 9, day: 10, hour: 12, minute: 0, timeZone: utc)
        let directDate = makeDate(year: 2023, month: 7, day: 1, hour: 12, minute: 0, timeZone: utc)

        #expect(service.isRetrograde(.mercury, at: retrogradeDate))
        #expect(!service.isRetrograde(.mercury, at: directDate))
    }

    @Test
    func testCalculateHousesMatchesSwissEphemeris() {
        let date = makeDate(year: 2023, month: 7, day: 4, hour: 14, minute: 15, timeZone: utc)
        let latitude = 50.4501
        let longitude = 30.5234

        let result = service.calculateHouses(at: date, latitude: latitude, longitude: longitude)

        let swissCusps = HouseCusps(
            date: date,
            latitude: latitude,
            longitude: longitude,
            houseSystem: .placidus
        )

        let swissAsc = normalize(swissCusps.ascendent.tropical.value)
        let swissMC = normalize(swissCusps.midHeaven.tropical.value)

        #expect(abs(result.ascendant - swissAsc) < 0.0001)
        #expect(abs(result.midheaven - swissMC) < 0.0001)
        #expect(result.houses.count == 12)

        let swissHouses: [Cusp] = [
            swissCusps.first,
            swissCusps.second,
            swissCusps.third,
            swissCusps.fourth,
            swissCusps.fifth,
            swissCusps.sixth,
            swissCusps.seventh,
            swissCusps.eighth,
            swissCusps.ninth,
            swissCusps.tenth,
            swissCusps.eleventh,
            swissCusps.twelfth,
        ]

        for (index, house) in result.houses.enumerated() {
            let swissCusp = swissHouses[index]
            let expectedDegree = normalize(swissCusp.tropical.value)
            let expectedSign = mapToDomainSign(swissCusp.tropical.sign)

            #expect(house.number == index + 1)
            #expect(abs(house.cusp - expectedDegree) < 0.0001)
            #expect(house.sign == expectedSign)
        }
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timeZone: TimeZone
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = timeZone

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        return calendar.date(from: components)!
    }

    func normalize(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }

    func mapToDomainSign(_ sign: SwissEphemeris.Zodiac) -> ZodiacSign {
        switch sign {
        case .aries: return .aries
        case .taurus: return .taurus
        case .gemini: return .gemini
        case .cancer: return .cancer
        case .leo: return .leo
        case .virgo: return .virgo
        case .libra: return .libra
        case .scorpio: return .scorpio
        case .sagittarius: return .sagittarius
        case .capricorn: return .capricorn
        case .aquarius: return .aquarius
        case .pisces: return .pisces
        }
    }
}
