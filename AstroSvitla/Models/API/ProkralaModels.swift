//
//  ProkralaModels.swift
//  AstroSvitla
//
//  API Response DTOs for Prokerala Astrology API
//  These models match the API JSON response structure exactly
//

import Foundation

// MARK: - Chart Data Response

struct ProkralaChartDataResponse: Decodable, Sendable {
    let status: Status
    let message: String?
    let data: ChartData

    struct Status: Decodable, Sendable {
        let rawString: String?
        let rawBool: Bool?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let boolValue = try? container.decode(Bool.self) {
                rawBool = boolValue
                rawString = nil
            } else if let stringValue = try? container.decode(String.self) {
                rawBool = nil
                rawString = stringValue
            } else {
                rawBool = nil
                rawString = nil
            }
        }

        var isSuccess: Bool {
            if let rawBool {
                return rawBool
            }
            guard let rawString else { return false }
            let normalized = rawString.lowercased()
            return normalized == "success" || normalized == "ok" || normalized == "true"
        }

        var description: String {
            if let rawBool {
                return rawBool ? "true" : "false"
            }
            return rawString ?? "unknown"
        }
    }

    struct ChartData: Decodable, Sendable {
        let houses: [House]
        let planetPositions: [PlanetPosition]
        let angles: [PlanetPosition]
        let aspects: [PlanetAspect]
        let declinations: [Declination]?
    }

    struct House: Decodable, Sendable {
        let id: Int
        let number: Int
        let startCusp: Cusp
        let endCusp: Cusp
    }

    struct Cusp: Decodable, Sendable {
        let longitude: Double
        let degree: Double
        let zodiac: WesternZodiac
    }

    struct WesternZodiac: Decodable, Sendable {
        let id: Int?
        let name: String
    }

    struct PlanetPosition: Decodable, Sendable {
        let id: Int?
        let name: String
        let longitude: Double
        let degree: Double
        let isRetrograde: Bool
        let houseNumber: Int?
        let zodiac: WesternZodiac
    }

    struct PlanetAspect: Decodable, Sendable {
        let planetOne: WesternPlanet
        let planetTwo: WesternPlanet
        let aspect: Aspect
        let orb: Double
    }

    struct WesternPlanet: Decodable, Sendable {
        let id: Int?
        let name: String
    }

    struct Aspect: Decodable, Sendable {
        let id: Int?
        let name: String
    }

    struct Declination: Decodable, Sendable {
        let planetOne: WesternPlanet
        let planetTwo: WesternPlanet
        let aspect: Aspect
        let orb: Double
    }
}

// MARK: - Chart Image Resource

struct ProkralaChartImageResource: Sendable {
    let data: Data
    let contentType: String?

    var format: String {
        guard let contentType else {
            return "svg"
        }

        let lowercased = contentType.lowercased()
        if lowercased.contains("svg") {
            return "svg"
        }

        if lowercased.contains("png") {
            return "png"
        }

        return "svg"
    }
}
