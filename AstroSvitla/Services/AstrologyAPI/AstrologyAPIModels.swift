//
//  AstrologyAPIModels.swift
//  AstroSvitla
//
//  Created by AstrologyAPI Integration
//  Data Transfer Objects for api.astrology-api.io
//

import Foundation

// MARK: - Request DTOs

/// Birth data for natal chart calculation
struct AstrologyAPIBirthData: Codable, Sendable {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let second: Int
    let city: String
    let countryCode: String
    
    private enum CodingKeys: String, CodingKey {
        case year, month, day, hour, minute, second, city
        case countryCode = "country_code"
    }
}

/// Subject information for API requests
struct AstrologyAPISubject: Codable, Sendable {
    let name: String
    let birthData: AstrologyAPIBirthData
    
    private enum CodingKeys: String, CodingKey {
        case name
        case birthData = "birth_data"
    }
}

/// Chart calculation options
struct AstrologyAPIOptions: Codable, Sendable {
    let houseSystem: String
    let zodiacType: String
    let activePoints: [String]
    let precision: Int
    
    private enum CodingKeys: String, CodingKey {
        case houseSystem = "house_system"
        case zodiacType = "zodiac_type"
        case activePoints = "active_points"
        case precision
    }
    
    static let `default` = AstrologyAPIOptions(
        houseSystem: "P", // Placidus
        zodiacType: "Tropic", // Tropical/Western
        activePoints: ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"],
        precision: 2
    )
}

/// Complete natal chart request
struct AstrologyAPINatalChartRequest: Codable, Sendable {
    let subject: AstrologyAPISubject
    let options: AstrologyAPIOptions
}

/// SVG chart generation options
struct AstrologyAPISVGOptions: Codable, Sendable {
    let theme: String
    let language: String
    
    static let `default` = AstrologyAPISVGOptions(
        theme: "classic",
        language: "en"
    )
}

/// SVG chart generation request  
struct AstrologyAPISVGRequest: Codable, Sendable {
    let subject: AstrologyAPISubject
    let options: AstrologyAPIOptions
    let svgOptions: AstrologyAPISVGOptions?
    
    private enum CodingKeys: String, CodingKey {
        case subject, options
        case svgOptions = "svg_options"
    }
}

// MARK: - Response DTOs

/// Individual celestial body data in subject_data
struct AstrologyAPICelestialBody: Codable, Sendable {
    let name: String
    let quality: String?
    let element: String?
    let sign: String
    let signNum: Int?
    let position: Double
    let absPos: Double
    let emoji: String?
    let pointType: String?
    let house: String?
    let retrograde: Bool
    
    private enum CodingKeys: String, CodingKey {
        case name, quality, element, sign, position, emoji, house, retrograde
        case signNum = "sign_num"
        case absPos = "abs_pos"
        case pointType = "point_type"
    }
}

/// Subject metadata in API response
struct AstrologyAPISubjectData: Codable, Sendable {
    let name: String
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let city: String
    let nation: String
    let lng: Double
    let lat: Double
    let tzStr: String
    let sun: AstrologyAPICelestialBody?
    let moon: AstrologyAPICelestialBody?
    let mercury: AstrologyAPICelestialBody?
    let venus: AstrologyAPICelestialBody?
    let mars: AstrologyAPICelestialBody?
    let jupiter: AstrologyAPICelestialBody?
    let saturn: AstrologyAPICelestialBody?
    let uranus: AstrologyAPICelestialBody?
    let neptune: AstrologyAPICelestialBody?
    let pluto: AstrologyAPICelestialBody?
    let ascendant: AstrologyAPICelestialBody?
    let descendant: AstrologyAPICelestialBody?
    let mediumCoeli: AstrologyAPICelestialBody?
    let imumCoeli: AstrologyAPICelestialBody?
    
    private enum CodingKeys: String, CodingKey {
        case name, year, month, day, hour, minute, city, nation, lng, lat
        case tzStr = "tz_str"
        case sun, moon, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto
        case ascendant, descendant
        case mediumCoeli = "medium_coeli"
        case imumCoeli = "imum_coeli"
    }
}

/// Individual planetary position
struct AstrologyAPIPlanetaryPosition: Codable, Sendable {
    let name: String
    let sign: String
    let degree: Double
    let absoluteLongitude: Double
    let house: Int
    let isRetrograde: Bool
    let speed: Double
    
    private enum CodingKeys: String, CodingKey {
        case name, sign, degree, house, speed
        case absoluteLongitude = "absolute_longitude"
        case isRetrograde = "is_retrograde"
    }
}

/// House cusp information
struct AstrologyAPIHouseCusp: Codable, Sendable {
    let house: Int
    let sign: String
    let degree: Double
    let absoluteLongitude: Double
    let retrograde: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case house, sign, degree, retrograde
        case absoluteLongitude = "absolute_longitude"
    }
}

/// Aspect between planets
struct AstrologyAPIAspect: Codable, Sendable {
    let point1: String
    let point2: String
    let aspectType: String
    let orb: Double
    
    private enum CodingKeys: String, CodingKey {
        case point1, point2, orb
        case aspectType = "aspect_type"
    }
}

/// Chart calculation data
struct AstrologyAPIChartData: Codable, Sendable {
    let planetaryPositions: [AstrologyAPIPlanetaryPosition]
    let houseCusps: [AstrologyAPIHouseCusp]?
    let aspects: [AstrologyAPIAspect]?
    
    private enum CodingKeys: String, CodingKey {
        case planetaryPositions = "planetary_positions"
        case houseCusps = "house_cusps"
        case aspects
    }
}

/// Complete natal chart response
struct AstrologyAPINatalChartResponse: Codable, Sendable {
    let subjectData: AstrologyAPISubjectData
    let chartData: AstrologyAPIChartData
    
    private enum CodingKeys: String, CodingKey {
        case subjectData = "subject_data"
        case chartData = "chart_data"
    }
}

/// SVG chart response
struct AstrologyAPISVGResponse: Codable, Sendable {
    let svgContent: String
    
    private enum CodingKeys: String, CodingKey {
        case svgContent = "svg"
    }
}

// MARK: - Error Response

/// Error response from API
struct AstrologyAPIErrorResponse: Codable, Sendable {
    let error: String
    let message: String?
    let code: Int?
}
