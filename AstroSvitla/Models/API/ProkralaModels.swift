//
//  ProkralaModels.swift
//  AstroSvitla
//
//  API Response DTOs for Prokerala Astrology API
//  These models match the API JSON response structure exactly
//

import Foundation

// MARK: - Planet DTO

struct PlanetDTO: Codable {
    let name: String
    let sign: String
    let full_degree: Double
    let is_retro: String  // API returns "true" or "false" as string

    enum CodingKeys: String, CodingKey {
        case name
        case sign
        case full_degree
        case is_retro
    }
}

// MARK: - House DTO

struct HouseDTO: Codable {
    let house_id: Int
    let sign: String
    let start_degree: Double
    let end_degree: Double
    let planets: [String]?

    enum CodingKeys: String, CodingKey {
        case house_id
        case sign
        case start_degree
        case end_degree
        case planets
    }
}

// MARK: - Aspect DTO

struct AspectDTO: Codable {
    let aspecting_planet: String
    let aspected_planet: String
    let type: String
    let orb: Double
    let diff: Double

    enum CodingKeys: String, CodingKey {
        case aspecting_planet
        case aspected_planet
        case type
        case orb
        case diff
    }
}

// MARK: - Ascendant/Midheaven DTOs

struct AscendantDTO: Codable {
    let sign: String
    let full_degree: Double
}

struct MidheavenDTO: Codable {
    let sign: String
    let full_degree: Double
}

// MARK: - Chart Data Response

struct ProkralaChartDataResponse: Codable {
    let planets: [PlanetDTO]
    let houses: [HouseDTO]
    let aspects: [AspectDTO]
    let ascendant: AscendantDTO?
    let midheaven: MidheavenDTO?
}

// MARK: - Chart Image Response

struct ProkralaChartImageResponse: Codable {
    let status: Bool
    let chart_url: String
    let msg: String
}
