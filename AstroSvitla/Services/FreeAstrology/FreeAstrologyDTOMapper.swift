//
//  FreeAstrologyDTOMapper.swift
//  AstroSvitla
//
//  Created for Free Astrology API integration
//  Maps Free Astrology API DTOs to domain models
//
//  ⚠️ LEGACY API - PRESERVED FOR ROLLBACK (2025-10-11)
//  This implementation has been replaced by AstrologyAPIDTOMapper (api.astrology-api.io)
//  DO NOT DELETE - Keep for potential rollback
//  To restore: Remove AstrologyAPI integration and re-enable this mapper in NatalChartService
//

import Foundation
import CoreLocation

/// Mapping errors that can occur during DTO to domain transformation
enum MappingError: LocalizedError {
    case missingRequiredData(String)
    case invalidPlanetData(String)
    case invalidHouseData(String)
    case invalidAspectData(String)
    case invalidResponseStatus(Int)

    var errorDescription: String? {
        switch self {
        case .missingRequiredData(let field):
            return "Required data missing: \(field)"
        case .invalidPlanetData(let reason):
            return "Unable to parse planet positions: \(reason)"
        case .invalidHouseData(let reason):
            return "Unable to parse house cusps: \(reason)"
        case .invalidAspectData(let reason):
            return "Unable to parse aspects: \(reason)"
        case .invalidResponseStatus(let code):
            return "API returned error status code: \(code)"
        }
    }
}

/// Maps Free Astrology API DTOs to domain models
enum FreeAstrologyDTOMapper {

    // MARK: - Main Aggregation Method

    /// Map complete API responses to NatalChart domain model
    static func toDomain(
        planetsResponse: PlanetsResponse,
        housesResponse: HousesResponse,
        aspectsResponse: AspectsResponse,
        chartResponse: NatalChartResponse,
        birthDetails: BirthDetails
    ) throws -> NatalChart {
        // Validate response status codes
        guard planetsResponse.statusCode == 200 else {
            throw MappingError.invalidResponseStatus(planetsResponse.statusCode)
        }
        guard housesResponse.statusCode == 200 else {
            throw MappingError.invalidResponseStatus(housesResponse.statusCode)
        }
        guard aspectsResponse.statusCode == 200 else {
            throw MappingError.invalidResponseStatus(aspectsResponse.statusCode)
        }
        guard chartResponse.statusCode == 200 else {
            throw MappingError.invalidResponseStatus(chartResponse.statusCode)
        }

        // Map individual components
        let planets = try mapPlanets(planetsResponse, houses: housesResponse)
        let houses = try mapHouses(housesResponse)
        let aspects = try mapAspects(aspectsResponse)
        let chartURL = chartResponse.chartUrl

        // Extract ascendant and midheaven from planets response
        // Ascendant is house 1 cusp, midheaven is house 10 cusp
        let ascendant = houses.first(where: { $0.number == 1 })?.cusp ?? 0.0
        let midheaven = houses.first(where: { $0.number == 10 })?.cusp ?? 0.0

        // Create NatalChart
        return NatalChart(
            birthDate: birthDetails.birthDate,
            birthTime: birthDetails.birthTime,
            latitude: birthDetails.coordinate?.latitude ?? 0.0,
            longitude: birthDetails.coordinate?.longitude ?? 0.0,
            locationName: birthDetails.location,
            planets: planets,
            houses: houses,
            aspects: aspects,
            ascendant: ascendant,
            midheaven: midheaven,
            calculatedAt: Date(),
            imageFileID: UUID().uuidString,
            imageFormat: "svg"
        )
    }

    // MARK: - Individual Mapping Methods

    /// Map planets response to domain model
    /// Note: We need houses data to assign house numbers to planets
    static func mapPlanets(_ response: PlanetsResponse, houses: HousesResponse) throws -> [Planet] {
        let houseCusps = try mapHouses(houses)

        return response.output.compactMap { dto -> Planet? in
            // Map planet name to PlanetType enum
            guard let planetType = mapPlanetName(dto.name) else {
                // Skip planets that aren't in our PlanetType enum (e.g., Ascendant, MC, IC, nodes, asteroids)
                return nil
            }

            // Map sign from API sign number (1-12) to ZodiacSign
            let sign = mapSignNumber(dto.sign)

            // Calculate which house this planet is in
            let houseNumber = calculateHouse(for: dto.fullDegree, houses: houseCusps)

            // Create Planet domain model
            return Planet(
                id: UUID(),
                name: planetType,
                longitude: dto.fullDegree,
                latitude: 0.0, // API doesn't provide declination, use 0
                sign: sign,
                house: houseNumber,
                isRetrograde: dto.isRetrograde,
                speed: 0.0  // API doesn't provide speed in this response format
            )
        }
    }

    /// Map houses response to domain model
    static func mapHouses(_ response: HousesResponse) throws -> [House] {
        let houses = response.output.houses

        guard houses.count == 12 else {
            throw MappingError.invalidHouseData("Expected 12 houses, got \(houses.count)")
        }

        return houses.map { dto -> House in
            // Map sign from API sign number
            let sign = mapSignNumber(dto.sign)

            return House(
                id: UUID(),
                number: dto.house,
                cusp: dto.degree,
                sign: sign
            )
        }
    }

    /// Map aspects response to domain model
    static func mapAspects(_ response: AspectsResponse) throws -> [Aspect] {
        return response.output.compactMap { dto -> Aspect? in
            // Map planet names to PlanetType
            guard let planet1Type = mapPlanetName(dto.planet1Name),
                  let planet2Type = mapPlanetName(dto.planet2Name) else {
                // Skip aspects involving planets not in our enum
                return nil
            }

            // Map aspect type
            guard let aspectType = mapAspectType(dto.type) else {
                // Skip aspects not in our AspectType enum
                return nil
            }

            return Aspect(
                id: UUID(),
                planet1: planet1Type,
                planet2: planet2Type,
                type: aspectType,
                orb: 0.0,  // API doesn't provide orb in this format
                isApplying: false  // API doesn't provide is_applying in this format
            )
        }
    }

    // MARK: - Helper Mapping Functions

    /// Calculate which house a planet is in based on its longitude
    private static func calculateHouse(for longitude: Double, houses: [House]) -> Int {
        // Normalize longitude to 0-360
        let normalizedLongitude = longitude.truncatingRemainder(dividingBy: 360)
        let positiveLongitude = normalizedLongitude < 0 ? normalizedLongitude + 360 : normalizedLongitude

        // Find which house the planet falls in
        for i in 0..<houses.count {
            let currentHouse = houses[i]
            let nextHouse = houses[(i + 1) % houses.count]

            let currentCusp = currentHouse.cusp.truncatingRemainder(dividingBy: 360)
            let nextCusp = nextHouse.cusp.truncatingRemainder(dividingBy: 360)

            // Handle wrap-around at 0/360 degrees
            if currentCusp < nextCusp {
                if positiveLongitude >= currentCusp && positiveLongitude < nextCusp {
                    return currentHouse.number
                }
            } else {
                // Wraps around 0
                if positiveLongitude >= currentCusp || positiveLongitude < nextCusp {
                    return currentHouse.number
                }
            }
        }

        // Fallback: return first house
        return 1
    }

    /// Map planet name string to PlanetType enum
    private static func mapPlanetName(_ name: String) -> PlanetType? {
        switch name.lowercased() {
        case "sun": return .sun
        case "moon": return .moon
        case "mercury": return .mercury
        case "venus": return .venus
        case "mars": return .mars
        case "jupiter": return .jupiter
        case "saturn": return .saturn
        case "uranus": return .uranus
        case "neptune": return .neptune
        case "pluto": return .pluto
        default: return nil
        }
    }

    /// Map aspect type string to AspectType enum
    private static func mapAspectType(_ type: String) -> AspectType? {
        switch type.lowercased() {
        case "conjunction": return .conjunction
        case "opposition": return .opposition
        case "trine": return .trine
        case "square": return .square
        case "sextile": return .sextile
        default: return nil
        }
    }

    /// Map sign number (1-12) to ZodiacSign enum
    /// API uses: 1=Aries, 2=Taurus, ..., 12=Pisces
    private static func mapSignNumber(_ signNum: Int) -> ZodiacSign {
        switch signNum {
        case 1: return .aries
        case 2: return .taurus
        case 3: return .gemini
        case 4: return .cancer
        case 5: return .leo
        case 6: return .virgo
        case 7: return .libra
        case 8: return .scorpio
        case 9: return .sagittarius
        case 10: return .capricorn
        case 11: return .aquarius
        case 12: return .pisces
        default:
            // Fallback to calculating from degree if number is out of range
            let degree = Double((signNum - 1) * 30)
            return ZodiacSign.from(degree: degree)
        }
    }
}
