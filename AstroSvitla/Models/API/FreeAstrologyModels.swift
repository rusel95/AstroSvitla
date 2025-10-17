//
//  FreeAstrologyModels.swift
//  AstroSvitla
//
//  Created for Free Astrology API integration
//  Contains all DTOs for Free Astrology API requests and responses
//

import Foundation
import CoreLocation

// MARK: - Request Model

/// Configuration options for Free Astrology API
struct FreeAstrologyConfig: Codable {
    let observationPoint: String
    let ayanamsha: String
    let language: String?
    let excludePlanets: [String]?
    let allowedAspects: [String]?

    enum CodingKeys: String, CodingKey {
        case observationPoint = "observation_point"
        case ayanamsha
        case language
        case excludePlanets = "exclude_planets"
        case allowedAspects = "allowed_aspects"
    }

    init(
        observationPoint: String = "topocentric",
        ayanamsha: String = "tropical",
        language: String? = "en",
        excludePlanets: [String]? = nil,
        allowedAspects: [String]? = nil
    ) {
        self.observationPoint = observationPoint
        self.ayanamsha = ayanamsha
        self.language = language
        self.excludePlanets = excludePlanets
        self.allowedAspects = allowedAspects
    }

    /// Default configuration with simplified chart (only major planets and aspects)
    static var simplified: FreeAstrologyConfig {
        FreeAstrologyConfig(
            observationPoint: "topocentric",
            ayanamsha: "tropical",
            language: "en",
            excludePlanets: [
                "Chiron", "Ceres", "Vesta", "Juno", "Pallas",
                "IC", "Descendant"
            ],
            allowedAspects: [
                "Conjunction", "Opposition", "Trine", "Square", "Sextile"
            ]
        )
    }
}

/// Request model for Free Astrology API endpoints
/// Maps from app's BirthDetails to API's expected format
struct FreeAstrologyRequest: Codable {
    let year: Int
    let month: Int
    let date: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    let latitude: Double
    let longitude: Double
    let timezone: Double
    let config: FreeAstrologyConfig

    // Initializer referencing BirthDetails removed; struct now only contains properties.
}

// MARK: - Planets Response Models

/// Top-level response wrapper for planets endpoint
struct PlanetsResponse: Codable {
    let statusCode: Int
    let output: [PlanetDTO]
}

/// Localized planet name
struct LocalizedName: Codable {
    let en: String
}

/// Zodiac sign information from API
struct APIZodiacSign: Codable {
    let number: Int
    let name: LocalizedName
}

/// Individual planet data transfer object
struct PlanetDTO: Codable {
    let planet: LocalizedName
    let fullDegree: Double
    let normDegree: Double
    let isRetro: String
    let zodiacSign: APIZodiacSign

    enum CodingKeys: String, CodingKey {
        case planet
        case fullDegree
        case normDegree
        case isRetro
        case zodiacSign = "zodiac_sign"
    }

    /// Convert "True" / "False" string to boolean
    var isRetrograde: Bool {
        isRetro.lowercased() == "true"
    }

    /// Get planet name in English
    var name: String {
        planet.en
    }

    /// Get zodiac sign number (1-12)
    var sign: Int {
        zodiacSign.number
    }
}

// MARK: - Houses Response Models

/// Top-level response wrapper for houses endpoint
struct HousesResponse: Codable {
    let statusCode: Int
    let output: HousesOutput
}

/// Houses data container
struct HousesOutput: Codable {
    let houses: [HouseDTO]

    enum CodingKeys: String, CodingKey {
        case houses = "Houses"
    }
}

/// Individual house data transfer object
struct HouseDTO: Codable {
    let house: Int
    let degree: Double
    let normDegree: Double
    let zodiacSign: APIZodiacSign

    enum CodingKeys: String, CodingKey {
        case house = "House"
        case degree
        case normDegree
        case zodiacSign = "zodiac_sign"
    }

    /// Get zodiac sign number (1-12)
    var sign: Int {
        zodiacSign.number
    }
}

// MARK: - Aspects Response Models

/// Top-level response wrapper for aspects endpoint
struct AspectsResponse: Codable {
    let statusCode: Int
    let output: [AspectDTO]
}

/// Individual aspect data transfer object
struct AspectDTO: Codable {
    let planet1: LocalizedName
    let planet2: LocalizedName
    let aspect: LocalizedName

    enum CodingKeys: String, CodingKey {
        case planet1 = "planet_1"
        case planet2 = "planet_2"
        case aspect
    }

    /// Get aspect type in English
    var type: String {
        aspect.en
    }

    /// Get first planet name in English
    var planet1Name: String {
        planet1.en
    }

    /// Get second planet name in English
    var planet2Name: String {
        planet2.en
    }
}

// MARK: - Natal Chart Response Models

/// Top-level response wrapper for natal-wheel-chart endpoint
/// Returns direct URL to SVG chart image
struct NatalChartResponse: Codable {
    let statusCode: Int
    let output: String  // Direct SVG URL

    /// Get chart URL
    var chartUrl: String {
        output
    }
}

