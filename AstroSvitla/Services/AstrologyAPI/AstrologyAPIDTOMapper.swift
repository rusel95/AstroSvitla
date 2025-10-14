//
//  AstrologyAPIDTOMapper.swift
//  AstroSvitla
//
//  Created by AstrologyAPI Integration
//  Maps AstrologyAPI DTOs to domain models
//

import Foundation

// MARK: - Main Mapper

enum AstrologyAPIDTOMapper {
    
    /// Convert birth details to API request format
    static func toAPIRequest(
        birthDetails: BirthDetails
    ) -> AstrologyAPINatalChartRequest {
        let calendar = Calendar.current
        let birthComponents = calendar.dateComponents([.year, .month, .day], from: birthDetails.birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: birthDetails.birthTime)
        
        let birthData = AstrologyAPIBirthData(
            year: birthComponents.year ?? 1990,
            month: birthComponents.month ?? 1,
            day: birthComponents.day ?? 1,
            hour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            second: 0,
            city: birthDetails.location,
            countryCode: extractCountryCode(from: birthDetails.location)
        )
        
        let subject = AstrologyAPISubject(name: birthDetails.name, birthData: birthData)
        
        return AstrologyAPINatalChartRequest(
            subject: subject,
            options: .default
        )
    }
    
    /// Convert birth details to SVG API request format
    static func toSVGRequest(
        birthDetails: BirthDetails,
        theme: String = "classic",
        language: String = "en"
    ) -> AstrologyAPISVGRequest {
        let natalRequest = toAPIRequest(birthDetails: birthDetails)
        let svgOptions = AstrologyAPISVGOptions(theme: theme, language: language)
        
        return AstrologyAPISVGRequest(
            subject: natalRequest.subject,
            options: natalRequest.options,
            svgOptions: svgOptions
        )
    }
    
    /// Convert API response to domain model
    static func toDomain(
        response: AstrologyAPINatalChartResponse,
        birthDetails: BirthDetails
    ) throws -> NatalChart {
        
        // Map planets from chart_data.planetary_positions (has speed data)
        let planets = try mapPlanets(response.chartData.planetaryPositions)
        
        // Map houses from chart_data
        let houses = try mapHouses(response.chartData.houseCusps ?? [])
        
        // Map aspects from chart_data
        let aspects = try mapAspects(response.chartData.aspects ?? [])
        
        // Extract angles from subject_data
        let angles = extractAnglesFromSubjectData(response.subjectData)
        
        // Generate unique image file ID for SVG chart
        let imageFileID = UUID().uuidString
        
        return NatalChart(
            birthDate: birthDetails.birthDate,
            birthTime: birthDetails.birthTime,
            latitude: response.subjectData.lat,
            longitude: response.subjectData.lng,
            locationName: response.subjectData.city,
            planets: planets,
            houses: houses,
            aspects: aspects,
            ascendant: angles.ascendant,
            midheaven: angles.midheaven,
            calculatedAt: Date(),
            imageFileID: imageFileID,
            imageFormat: "svg"
        )
    }
    
    // MARK: - Private Mapping Methods
    
    private static func mapPlanetsFromSubjectData(
        _ subjectData: AstrologyAPISubjectData
    ) throws -> [Planet] {
        var planets: [Planet] = []
        
        // Map each planet from subject_data
        let celestialBodies: [(AstrologyAPICelestialBody?, PlanetType)] = [
            (subjectData.sun, .sun),
            (subjectData.moon, .moon),
            (subjectData.mercury, .mercury),
            (subjectData.venus, .venus),
            (subjectData.mars, .mars),
            (subjectData.jupiter, .jupiter),
            (subjectData.saturn, .saturn),
            (subjectData.uranus, .uranus),
            (subjectData.neptune, .neptune),
            (subjectData.pluto, .pluto)
        ]
        
        for (body, planetType) in celestialBodies {
            guard let body = body else { continue }
            
            planets.append(Planet(
                name: planetType,
                longitude: body.absPos,
                latitude: 0, // Astrology API doesn't provide latitude for planets
                sign: ZodiacSign.from(apiName: body.sign),
                house: extractHouseNumber(from: body.house),
                isRetrograde: body.retrograde,
                speed: 0 // Speed not available in subject_data
            ))
        }
        
        return planets
    }
    
    private static func mapPlanets(
        _ apiPlanets: [AstrologyAPIPlanetaryPosition]
    ) throws -> [Planet] {
        return apiPlanets.compactMap { apiPlanet in
            guard let planetType = PlanetType.from(apiName: apiPlanet.name) else {
                return nil // Skip unrecognized planets
            }
            
            return Planet(
                name: planetType,
                longitude: apiPlanet.absoluteLongitude,
                latitude: 0, // Astrology API doesn't provide latitude for planets
                sign: ZodiacSign.from(apiName: apiPlanet.sign),
                house: apiPlanet.house,
                isRetrograde: apiPlanet.isRetrograde,
                speed: apiPlanet.speed
            )
        }
    }
    
    private static func mapHouses(
        _ apiHouses: [AstrologyAPIHouseCusp]
    ) throws -> [House] {
        return apiHouses.map { apiHouse in
            House(
                number: apiHouse.house,
                cusp: apiHouse.degree,
                sign: ZodiacSign.from(apiName: apiHouse.sign)
            )
        }
    }
    
    private static func mapAspects(
        _ apiAspects: [AstrologyAPIAspect]
    ) throws -> [Aspect] {
        return apiAspects.compactMap { apiAspect in
            guard let planet1 = PlanetType.from(apiName: apiAspect.point1),
                  let planet2 = PlanetType.from(apiName: apiAspect.point2),
                  let aspectType = AspectType.from(apiName: apiAspect.aspectType) else {
                return nil
            }
            
            return Aspect(
                planet1: planet1,
                planet2: planet2,
                type: aspectType,
                orb: apiAspect.orb,
                isApplying: false // API doesn't provide this info
            )
        }
    }
    
    private static func extractAnglesFromSubjectData(
        _ subjectData: AstrologyAPISubjectData
    ) -> (ascendant: Double, midheaven: Double) {
        let ascendant = subjectData.ascendant?.absPos ?? 0
        let midheaven = subjectData.mediumCoeli?.absPos ?? 0
        
        return (ascendant: ascendant, midheaven: midheaven)
    }
    
    private static func extractHouseNumber(from houseString: String?) -> Int {
        guard let houseString = houseString else { return 1 }
        
        // Parse house names like "Ninth_House" -> 9
        let houseMap: [String: Int] = [
            "First_House": 1, "Second_House": 2, "Third_House": 3,
            "Fourth_House": 4, "Fifth_House": 5, "Sixth_House": 6,
            "Seventh_House": 7, "Eighth_House": 8, "Ninth_House": 9,
            "Tenth_House": 10, "Eleventh_House": 11, "Twelfth_House": 12
        ]
        
        return houseMap[houseString] ?? 1
    }
    
    private static func extractCountryCode(from location: String) -> String {
        // Simple country code extraction logic
        // In production, this should use a proper location service
        // For now, return a default
        return "US"
    }
}

// MARK: - Enum Extensions for Mapping

extension PlanetType {
    static func from(apiName: String) -> PlanetType? {
        switch apiName.lowercased() {
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
}

extension ZodiacSign {
    static func from(apiName: String) -> ZodiacSign {
        switch apiName.lowercased() {
        case "ari", "aries": return .aries
        case "tau", "taurus": return .taurus
        case "gem", "gemini": return .gemini
        case "can", "cancer": return .cancer
        case "leo": return .leo
        case "vir", "virgo": return .virgo
        case "lib", "libra": return .libra
        case "sco", "scorpio": return .scorpio
        case "sag", "sagittarius": return .sagittarius
        case "cap", "capricorn": return .capricorn
        case "aqu", "aquarius": return .aquarius
        case "pis", "pisces": return .pisces
        default: return .aries // Default fallback
        }
    }
}

extension AspectType {
    static func from(apiName: String) -> AspectType? {
        switch apiName.lowercased() {
        case "conjunction": return .conjunction
        case "opposition": return .opposition
        case "trine": return .trine
        case "square": return .square
        case "sextile": return .sextile
        default: return nil
        }
    }
}

// MARK: - Mapping Errors

enum AstrologyAPIMappingError: LocalizedError {
    case invalidPlanetData(String)
    case invalidHouseData(String)  
    case invalidAspectData(String)
    case missingRequiredField(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPlanetData(let planet):
            return "Invalid planet data for: \(planet)"
        case .invalidHouseData(let house):
            return "Invalid house data for: \(house)"
        case .invalidAspectData(let aspect):
            return "Invalid aspect data for: \(aspect)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}
