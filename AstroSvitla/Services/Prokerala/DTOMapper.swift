//
//  DTOMapper.swift
//  AstroSvitla
//
//  Maps Prokerala API DTOs to domain models
//

import Foundation
import CoreLocation

enum MappingError: LocalizedError {
    case invalidPlanetName(String)
    case invalidSign(String)
    case invalidHouseNumber(Int)
    case invalidAspectType(String)
    case apiReturnedFailureStatus(String)

    var errorDescription: String? {
        switch self {
        case .invalidPlanetName(let name):
            return "Unknown planet name: \(name)"
        case .invalidSign(let sign):
            return "Unknown zodiac sign: \(sign)"
        case .invalidHouseNumber(let num):
            return "Invalid house number: \(num). Must be 1-12."
        case .invalidAspectType(let type):
            return "Unknown aspect type: \(type)"
        case .apiReturnedFailureStatus(let status):
            return "API returned failure status: \(status)"
        }
    }
}

enum DTOMapper {

    private static func toDomain(planetPosition: ProkralaChartDataResponse.PlanetPosition) throws -> Planet {
        guard let planetType = PlanetType(rawValue: planetPosition.name) else {
            throw MappingError.invalidPlanetName(planetPosition.name)
        }

        guard let zodiacSign = ZodiacSign(rawValue: planetPosition.zodiac.name) else {
            throw MappingError.invalidSign(planetPosition.zodiac.name)
        }

        let houseNumber = planetPosition.houseNumber ?? 1
        guard (1...12).contains(houseNumber) else {
            throw MappingError.invalidHouseNumber(houseNumber)
        }

        return Planet(
            name: planetType,
            longitude: planetPosition.longitude,
            latitude: 0,
            sign: zodiacSign,
            house: houseNumber,
            isRetrograde: planetPosition.isRetrograde,
            speed: 0
        )
    }

    private static func toDomain(house: ProkralaChartDataResponse.House) throws -> House {
        guard (1...12).contains(house.number) else {
            throw MappingError.invalidHouseNumber(house.number)
        }

        guard let zodiacSign = ZodiacSign(rawValue: house.startCusp.zodiac.name) else {
            throw MappingError.invalidSign(house.startCusp.zodiac.name)
        }

        return House(
            number: house.number,
            cusp: house.startCusp.longitude,
            sign: zodiacSign
        )
    }

    private static func toDomain(aspect: ProkralaChartDataResponse.PlanetAspect) -> Aspect? {
        guard let planet1 = PlanetType(rawValue: aspect.planetOne.name),
              let planet2 = PlanetType(rawValue: aspect.planetTwo.name) else {
            return nil
        }

        guard let aspectType = AspectType(rawValue: aspect.aspect.name) else {
            return nil
        }

        return Aspect(
            planet1: planet1,
            planet2: planet2,
            type: aspectType,
            orb: aspect.orb,
            isApplying: false
        )
    }

    private static func extractAngle(
        names: [String],
        from angles: [ProkralaChartDataResponse.PlanetPosition],
        fallback: Double
    ) -> Double {
        guard let match = angles.first(where: { angle in
            let normalized = angle.name
                .replacingOccurrences(of: " ", with: "")
                .lowercased()
            return names.contains {
                $0.replacingOccurrences(of: " ", with: "").lowercased() == normalized
            }
        }) else {
            return fallback
        }
        return match.longitude
    }

    // MARK: - Full Chart Mapping

    static func toDomain(
        response: ProkralaChartDataResponse,
        birthDetails: BirthDetails
    ) throws -> NatalChart {

        guard response.status.isSuccess else {
            throw MappingError.apiReturnedFailureStatus(response.status.description)
        }

        let payload = response.data

        let houses = try payload.houses.map { try toDomain(house: $0) }

        let planets = try payload.planetPositions.compactMap { position -> Planet? in
            guard PlanetType(rawValue: position.name) != nil else {
                return nil
            }
            return try toDomain(planetPosition: position)
        }

        let aspects = payload.aspects.compactMap { toDomain(aspect: $0) }

        let ascendantFallback = houses.first(where: { $0.number == 1 })?.cusp ?? houses.first?.cusp ?? 0
        let ascendant = extractAngle(
            names: ["Ascendant", "Asc"],
            from: payload.angles,
            fallback: ascendantFallback
        )

        let midheavenFallback = houses.first(where: { $0.number == 10 })?.cusp ?? 0
        let midheaven = extractAngle(
            names: ["Midheaven", "MC", "MediumCoeli"],
            from: payload.angles,
            fallback: midheavenFallback
        )

        // Create NatalChart
        return NatalChart(
            birthDate: birthDetails.birthDate,
            birthTime: birthDetails.birthTime,
            latitude: birthDetails.coordinate?.latitude ?? 0,
            longitude: birthDetails.coordinate?.longitude ?? 0,
            locationName: birthDetails.location,
            planets: planets,
            houses: houses,
            aspects: aspects,
            ascendant: ascendant,
            midheaven: midheaven,
            calculatedAt: Date()
        )
    }
}
