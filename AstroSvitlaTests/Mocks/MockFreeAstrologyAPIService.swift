//
//  MockFreeAstrologyAPIService.swift
//  AstroSvitlaTests
//
//  Created for Free Astrology API integration testing
//  Mock implementation for testing without real API calls
//
//  ⚠️ LEGACY TEST MOCK - PRESERVED FOR ROLLBACK (2025-10-11)
//  This mock has been replaced by tests using AstrologyAPIService
//  DO NOT DELETE - Keep for potential rollback
//

import Foundation
@testable import AstroSvitla

/// Mock implementation of FreeAstrologyAPIServiceProtocol for testing
final class MockFreeAstrologyAPIService: FreeAstrologyAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Mock Data Injection

    var planetsResponse: PlanetsResponse?
    var housesResponse: HousesResponse?
    var aspectsResponse: AspectsResponse?
    var natalChartResponse: NatalChartResponse?

    var shouldThrowError: FreeAstrologyError?

    // MARK: - Call Tracking

    var fetchPlanetsCalled = false
    var fetchHousesCalled = false
    var fetchAspectsCalled = false
    var fetchNatalWheelChartCalled = false

    var lastPlanetsRequest: FreeAstrologyRequest?
    var lastHousesRequest: FreeAstrologyRequest?
    var lastAspectsRequest: FreeAstrologyRequest?
    var lastChartRequest: FreeAstrologyRequest?

    // MARK: - Protocol Implementation

    func fetchPlanets(_ request: FreeAstrologyRequest) async throws -> PlanetsResponse {
        fetchPlanetsCalled = true
        lastPlanetsRequest = request

        if let error = shouldThrowError {
            throw error
        }

        guard let response = planetsResponse else {
            throw FreeAstrologyError.invalidResponse
        }

        return response
    }

    func fetchHouses(_ request: FreeAstrologyRequest) async throws -> HousesResponse {
        fetchHousesCalled = true
        lastHousesRequest = request

        if let error = shouldThrowError {
            throw error
        }

        guard let response = housesResponse else {
            throw FreeAstrologyError.invalidResponse
        }

        return response
    }

    func fetchAspects(_ request: FreeAstrologyRequest) async throws -> AspectsResponse {
        fetchAspectsCalled = true
        lastAspectsRequest = request

        if let error = shouldThrowError {
            throw error
        }

        guard let response = aspectsResponse else {
            throw FreeAstrologyError.invalidResponse
        }

        return response
    }

    func fetchNatalWheelChart(_ request: FreeAstrologyRequest) async throws -> NatalChartResponse {
        fetchNatalWheelChartCalled = true
        lastChartRequest = request

        if let error = shouldThrowError {
            throw error
        }

        guard let response = natalChartResponse else {
            throw FreeAstrologyError.invalidResponse
        }

        return response
    }

    // MARK: - Helper Methods for Testing

    /// Reset all tracking flags and data
    func reset() {
        fetchPlanetsCalled = false
        fetchHousesCalled = false
        fetchAspectsCalled = false
        fetchNatalWheelChartCalled = false

        lastPlanetsRequest = nil
        lastHousesRequest = nil
        lastAspectsRequest = nil
        lastChartRequest = nil

        planetsResponse = nil
        housesResponse = nil
        aspectsResponse = nil
        natalChartResponse = nil

        shouldThrowError = nil
    }

    /// Configure mock with successful responses
    func configureMockSuccessResponses() {
        // Mock planets response
        planetsResponse = PlanetsResponse(
            status: "success",
            data: PlanetsData(planets: [
                PlanetDTO(
                    id: 0,
                    name: "Sun",
                    fullDegree: 54.5,
                    normDegree: 24.5,
                    speed: 1.0,
                    isRetro: "False",
                    sign: 2,
                    signLord: 3,
                    nakshatra: nil,
                    nakshatraLord: nil,
                    house: 1
                ),
                PlanetDTO(
                    id: 1,
                    name: "Moon",
                    fullDegree: 120.3,
                    normDegree: 0.3,
                    speed: 13.0,
                    isRetro: "False",
                    sign: 5,
                    signLord: 0,
                    nakshatra: nil,
                    nakshatraLord: nil,
                    house: 4
                )
            ]),
            error: nil
        )

        // Mock houses response
        housesResponse = HousesResponse(
            status: "success",
            data: HousesData(houses: [
                HouseDTO(house: 1, sign: 1, signLord: 4, degree: 0.0),
                HouseDTO(house: 2, sign: 2, signLord: 3, degree: 30.0),
                HouseDTO(house: 3, sign: 3, signLord: 2, degree: 60.0),
                HouseDTO(house: 4, sign: 4, signLord: 1, degree: 90.0),
                HouseDTO(house: 5, sign: 5, signLord: 0, degree: 120.0),
                HouseDTO(house: 6, sign: 6, signLord: 2, degree: 150.0),
                HouseDTO(house: 7, sign: 7, signLord: 3, degree: 180.0),
                HouseDTO(house: 8, sign: 8, signLord: 4, degree: 210.0),
                HouseDTO(house: 9, sign: 9, signLord: 5, degree: 240.0),
                HouseDTO(house: 10, sign: 10, signLord: 6, degree: 270.0),
                HouseDTO(house: 11, sign: 11, signLord: 7, degree: 300.0),
                HouseDTO(house: 12, sign: 12, signLord: 8, degree: 330.0)
            ]),
            error: nil
        )

        // Mock aspects response
        aspectsResponse = AspectsResponse(
            status: "success",
            data: AspectsData(aspects: [
                AspectDTO(
                    aspectingPlanet: 0,
                    aspectedPlanet: 1,
                    aspectingPlanetName: "Sun",
                    aspectedPlanetName: "Moon",
                    type: "Trine",
                    orb: 5.2,
                    isApplying: true,
                    diff: 65.8
                )
            ]),
            error: nil
        )

        // Mock natal chart response
        natalChartResponse = NatalChartResponse(
            status: "success",
            data: NatalChartData(chartUrl: "https://example.com/chart.svg"),
            error: nil
        )
    }
}
