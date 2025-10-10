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
        }
    }
}

enum DTOMapper {

    // MARK: - Planet Mapping

    static func toDomain(planetDTO: PlanetDTO, house: Int) throws -> Planet {
        guard let planetType = PlanetType(rawValue: planetDTO.name) else {
            throw MappingError.invalidPlanetName(planetDTO.name)
        }

        guard let zodiacSign = ZodiacSign(rawValue: planetDTO.sign) else {
            throw MappingError.invalidSign(planetDTO.sign)
        }

        let isRetrograde = (planetDTO.is_retro.lowercased() == "true")

        return Planet(
            name: planetType,
            longitude: planetDTO.full_degree,
            latitude: 0, // API doesn't provide latitude
            sign: zodiacSign,
            house: house,
            isRetrograde: isRetrograde,
            speed: 0 // API doesn't provide speed in basic response
        )
    }

    // MARK: - House Mapping

    static func toDomain(houseDTO: HouseDTO) throws -> House {
        guard (1...12).contains(houseDTO.house_id) else {
            throw MappingError.invalidHouseNumber(houseDTO.house_id)
        }

        guard let zodiacSign = ZodiacSign(rawValue: houseDTO.sign) else {
            throw MappingError.invalidSign(houseDTO.sign)
        }

        return House(
            number: houseDTO.house_id,
            cusp: houseDTO.start_degree,
            sign: zodiacSign
        )
    }

    // MARK: - Aspect Mapping

    static func toDomain(aspectDTO: AspectDTO) throws -> Aspect {
        guard let planet1 = PlanetType(rawValue: aspectDTO.aspecting_planet) else {
            throw MappingError.invalidPlanetName(aspectDTO.aspecting_planet)
        }

        guard let planet2 = PlanetType(rawValue: aspectDTO.aspected_planet) else {
            throw MappingError.invalidPlanetName(aspectDTO.aspected_planet)
        }

        guard let aspectType = AspectType(rawValue: aspectDTO.type) else {
            throw MappingError.invalidAspectType(aspectDTO.type)
        }

        return Aspect(
            planet1: planet1,
            planet2: planet2,
            type: aspectType,
            orb: aspectDTO.orb,
            isApplying: false // API doesn't provide this; could calculate later
        )
    }

    // MARK: - Full Chart Mapping

    static func toDomain(
        response: ProkralaChartDataResponse,
        birthDetails: BirthDetails
    ) throws -> NatalChart {

        // Create house-to-planet mapping
        var housePlanetMap: [String: Int] = [:]
        for houseDTO in response.houses {
            for planetName in (houseDTO.planets ?? []) {
                housePlanetMap[planetName] = houseDTO.house_id
            }
        }

        // Map planets with house assignments
        let planets = try response.planets.map { planetDTO in
            let house = housePlanetMap[planetDTO.name] ?? 1
            return try toDomain(planetDTO: planetDTO, house: house)
        }

        // Map houses
        let houses = try response.houses.map { try toDomain(houseDTO: $0) }

        // Map aspects
        let aspects = try response.aspects.map { try toDomain(aspectDTO: $0) }

        // Extract ascendant and midheaven
        let ascendant = response.ascendant?.full_degree ?? houses.first?.cusp ?? 0
        let midheaven = response.midheaven?.full_degree ?? (houses.count >= 10 ? houses[9].cusp : 0)

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
