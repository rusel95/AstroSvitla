/* TEMPORARILY DISABLED FOR FREE ASTROLOGY API TESTING
 *
 * This file has been commented out to enable isolated testing of the Free Astrology API integration.
 *
 * To re-enable:
 * 1. Remove this comment block
 * 2. Update NatalChartService to inject SwissEphemerisService instead of FreeAstrologyAPIService
 * 3. Re-enable the skipped tests in AstroSvitlaTests/Features/ChartCalculation/SwissEphemerisServiceTests.swift
 *
 * Original implementation preserved below for easy rollback if Free Astrology API proves inadequate.
 *
 * Last modified: 2025-10-10
 */

/*
import Foundation
import SwissEphemeris

enum SwissEphemerisServiceError: LocalizedError, Equatable {
    case invalidTimeZoneIdentifier(String)
    case invalidDateComponents

    var errorDescription: String? {
        switch self {
        case .invalidTimeZoneIdentifier(let identifier):
            return "Invalid timezone identifier: \(identifier)"
        case .invalidDateComponents:
            return "Unable to construct date from provided components."
        }
    }
}

/// Wraps shared integration points with SwissEphemeris and provides helpers that
/// normalise birth data into the formats required for astronomical calculations.
final class SwissEphemerisService {

    private static var isEphemerisInitialised = false
    private static let lock = NSLock()

    private var calendar: Calendar

    init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.calendar = calendar
        Self.ensureEphemerisPathIsSet()
    }

    /// Ensures the ephemeris data path is configured exactly once for the process.
    private static func ensureEphemerisPathIsSet() {
        lock.lock()
        defer { lock.unlock() }

        guard isEphemerisInitialised == false else { return }
        JPLFileManager.setEphemerisPath()
        isEphemerisInitialised = true
    }

    /// Returns the `TimeZone` instance for a given identifier or throws.
    func timeZone(from identifier: String) throws -> TimeZone {
        guard let timeZone = TimeZone(identifier: identifier) else {
            throw SwissEphemerisServiceError.invalidTimeZoneIdentifier(identifier)
        }
        return timeZone
    }

    /// Combines the provided birth date and time into a single `Date` in the supplied timezone.
    func localDate(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String
    ) throws -> Date {
        let timeZone = try timeZone(from: timeZoneIdentifier)
        return try localDate(birthDate: birthDate, birthTime: birthTime, timeZone: timeZone)
    }

    /// Combines birth date and time in the specified timezone and returns the absolute date in UTC.
    func utcDate(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String
    ) throws -> Date {
        let timeZone = try timeZone(from: timeZoneIdentifier)
        return try utcDate(birthDate: birthDate, birthTime: birthTime, timeZone: timeZone)
    }

    /// Combines birth date and time into a single `Date` object in the given timezone.
    func localDate(
        birthDate: Date,
        birthTime: Date,
        timeZone: TimeZone
    ) throws -> Date {
        calendar.timeZone = timeZone

        var dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: birthTime)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second ?? 0

        guard let combined = calendar.date(from: dateComponents) else {
            throw SwissEphemerisServiceError.invalidDateComponents
        }

        return combined
    }

    /// Converts a local birth date into UTC, respecting the timezone offset (including DST).
    func utcDate(
        birthDate: Date,
        birthTime: Date,
        timeZone: TimeZone
    ) throws -> Date {
        let local = try localDate(birthDate: birthDate, birthTime: birthTime, timeZone: timeZone)
        return local
    }

    /// Returns the timezone offset (seconds from GMT) at the provided local date.
    func secondsFromGMT(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String
    ) throws -> Int {
        let timeZone = try timeZone(from: timeZoneIdentifier)
        let local = try localDate(birthDate: birthDate, birthTime: birthTime, timeZone: timeZone)
        return timeZone.secondsFromGMT(for: local)
    }

    // MARK: - Planet Calculations

    /// Calculates a single planet position at the provided UTC date.
    func calculatePlanet(_ planet: PlanetType, at utcDate: Date) throws -> Planet {
        let swissPlanet = mapToSwissPlanet(planet)
        let coordinate = Coordinate(body: swissPlanet, date: utcDate)

        let sign = mapToDomainSign(coordinate.tropical.sign)
        let normalizedLongitude = normalizeDegrees(coordinate.longitude)
        let retrograde = isRetrograde(planet, at: utcDate)

        return Planet(
            name: planet,
            longitude: normalizedLongitude,
            latitude: coordinate.latitude,
            sign: sign,
            house: 0,
            isRetrograde: retrograde,
            speed: coordinate.speedLongitude
        )
    }

    /// Calculates all planet positions (Sun through Pluto) at the provided UTC date.
    func calculatePlanets(at utcDate: Date) throws -> [Planet] {
        try PlanetType.allCases.map { try calculatePlanet($0, at: utcDate) }
    }

    /// Returns whether a planet is retrograde at the specified UTC date.
    func isRetrograde(_ planet: PlanetType, at utcDate: Date) -> Bool {
        let swissPlanet = mapToSwissPlanet(planet)
        let coordinate = Coordinate(body: swissPlanet, date: utcDate)
        return coordinate.speedLongitude < 0
    }

    /// Calculates major aspects (Conjunction, Sextile, Square, Trine, Opposition) between the supplied planets.
    func calculateAspects(
        for planets: [Planet],
        orbOverrides: [AspectType: Double] = [:]
    ) -> [Aspect] {
        var aspects: [Aspect] = []

        for i in 0..<planets.count {
            for j in (i + 1)..<planets.count {
                let first = planets[i]
                let second = planets[j]

                guard let aspect = aspectBetween(first, second, orbOverrides: orbOverrides) else {
                    continue
                }

                aspects.append(aspect)
            }
        }

        return aspects
    }

    /// Calculates Placidus houses, returning domain models alongside ascendent and midheaven degrees.
    func calculateHouses(
        at utcDate: Date,
        latitude: Double,
        longitude: Double,
        houseSystem: HouseSystem = .placidus
    ) throws -> (houses: [House], ascendant: Double, midheaven: Double) {

        let cusps = HouseCusps(
            date: utcDate,
            latitude: latitude,
            longitude: longitude,
            houseSystem: houseSystem
        )

        let houseCusps: [(number: Int, cusp: Cusp)] = [
            (1, cusps.first),
            (2, cusps.second),
            (3, cusps.third),
            (4, cusps.fourth),
            (5, cusps.fifth),
            (6, cusps.sixth),
            (7, cusps.seventh),
            (8, cusps.eighth),
            (9, cusps.ninth),
            (10, cusps.tenth),
            (11, cusps.eleventh),
            (12, cusps.twelfth),
        ]

        let houses = houseCusps.map { entry in
            let degree = normalizeDegrees(entry.cusp.tropical.value)
            let sign = mapToDomainSign(entry.cusp.tropical.sign)

            return House(
                number: entry.number,
                cusp: degree,
                sign: sign
            )
        }

        let ascendant = normalizeDegrees(cusps.ascendent.tropical.value)
        let midheaven = normalizeDegrees(cusps.midHeaven.tropical.value)

        return (houses, ascendant, midheaven)
    }
}

// MARK: - Private Helpers

private extension SwissEphemerisService {
    func mapToSwissPlanet(_ planet: PlanetType) -> SwissEphemeris.Planet {
        switch planet {
        case .sun: return .sun
        case .moon: return .moon
        case .mercury: return .mercury
        case .venus: return .venus
        case .mars: return .mars
        case .jupiter: return .jupiter
        case .saturn: return .saturn
        case .uranus: return .uranus
        case .neptune: return .neptune
        case .pluto: return .pluto
        }
    }

    func mapToDomainSign(_ zodiac: SwissEphemeris.Zodiac) -> ZodiacSign {
        switch zodiac {
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

    func normalizeDegrees(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }


    func aspectBetween(
        _ planetA: Planet,
        _ planetB: Planet,
        orbOverrides: [AspectType: Double]
    ) -> Aspect? {
        let difference = angularDifference(planetA.longitude, planetB.longitude)

        guard let type = AspectType.majorAspect(for: difference, orbOverrides: orbOverrides) else {
            return nil
        }

        let maxOrb = orbOverrides[type] ?? type.maxOrb
        let orb = abs(type.angle - difference)

        guard orb <= maxOrb else {
            return nil
        }

        let isApplying = isApplyingAspect(
            planetA: planetA,
            planetB: planetB,
            aspectType: type
        )
        return Aspect(
            planet1: planetA.name,
            planet2: planetB.name,
            type: type,
            orb: orb,
            isApplying: isApplying
        )
    }

    func angularDifference(_ longitudeA: Double, _ longitudeB: Double) -> Double {
        let diff = abs(longitudeA - longitudeB).truncatingRemainder(dividingBy: 360)
        return diff > 180 ? 360 - diff : diff
    }

    func isApplyingAspect(
        planetA: Planet,
        planetB: Planet,
        aspectType: AspectType,
        deltaDays: Double = 0.01
    ) -> Bool {
        let currentOrb = abs(aspectType.angle - angularDifference(planetA.longitude, planetB.longitude))

        let futureLongitudeA = normalizeDegrees(planetA.longitude + planetA.speed * deltaDays)
        let futureLongitudeB = normalizeDegrees(planetB.longitude + planetB.speed * deltaDays)
        let futureOrb = abs(aspectType.angle - angularDifference(futureLongitudeA, futureLongitudeB))

        return futureOrb < currentOrb
    }
}

private extension AspectType {
    static func majorAspect(
        for angle: Double,
        orbOverrides: [AspectType: Double]
    ) -> AspectType? {
        let thresholds: [(AspectType, Double)] = [
            (.conjunction, 0),
            (.sextile, 60),
            (.square, 90),
            (.trine, 120),
            (.opposition, 180),
        ]

        for (type, target) in thresholds {
            let maxOrb = orbOverrides[type] ?? type.maxOrb
            if abs(angle - target) <= maxOrb {
                return type
            }
        }

        return nil
    }
}
*/
