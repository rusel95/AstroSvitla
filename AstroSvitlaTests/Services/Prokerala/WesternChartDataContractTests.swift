//
//  WesternChartDataContractTests.swift
//  AstroSvitlaTests
//
//  Contract tests for Prokerala western_chart_data API endpoint
//  Validates real API responses match expected structure and data types
//
//  NOTE: These tests require valid API credentials in environment variables:
//  - TEST_ASTROLOGY_API_USER_ID
//  - TEST_ASTROLOGY_API_KEY
//

import Testing
import Foundation
@testable import AstroSvitla

@Suite("Western Chart Data Contract Tests", .tags(.contract))
struct WesternChartDataContractTests {

    let apiService: ProkralaAPIService

    init() throws {
        // Load test credentials from environment variables
        guard let userID = ProcessInfo.processInfo.environment["TEST_ASTROLOGY_API_USER_ID"],
              let apiKey = ProcessInfo.processInfo.environment["TEST_ASTROLOGY_API_KEY"],
              !userID.isEmpty, !apiKey.isEmpty else {
            throw TestError.missingCredentials("Set TEST_ASTROLOGY_API_USER_ID and TEST_ASTROLOGY_API_KEY")
        }

        apiService = ProkralaAPIService(userID: userID, apiKey: apiKey)
    }

    enum TestError: Error {
        case missingCredentials(String)
    }

    // MARK: - Happy Path Tests

    @Test("API returns valid natal chart data with correct structure")
    func testValidChartDataStructure() async throws {
        // Arrange - Test birth data (March 15, 1990, 14:30, New York)
        let birthDetails = BirthDetails(
            name: "Test Person",
            birthDate: createDate(year: 1990, month: 3, day: 15),
            birthTime: createTime(hour: 14, minute: 30),
            birthPlace: "New York, USA",
            timeZone: TimeZone(identifier: "America/New_York")!,
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        )

        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)

        // Assert - Response structure
        #expect(response.planets.count == 10, "Must return exactly 10 planets")
        #expect(response.houses.count == 12, "Must return exactly 12 houses")
        #expect(response.aspects.count > 0, "Should return at least some aspects")
    }

    @Test("All planets have valid properties")
    func testPlanetsValidation() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)

        // Assert - Validate each planet
        let expectedPlanets = Set(["Sun", "Moon", "Mercury", "Venus", "Mars",
                                   "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"])
        let actualPlanets = Set(response.planets.map { $0.name })

        #expect(actualPlanets == expectedPlanets, "Must return all 10 standard planets")

        for planet in response.planets {
            // Validate longitude range
            #expect(planet.full_degree >= 0.0 && planet.full_degree < 360.0,
                   "Planet \(planet.name) longitude out of range: \(planet.full_degree)")

            // Validate retrograde field
            #expect(planet.is_retro == "true" || planet.is_retro == "false",
                   "Planet \(planet.name) has invalid retrograde value: \(planet.is_retro)")

            // Validate sign is not empty
            #expect(!planet.sign.isEmpty, "Planet \(planet.name) missing sign")
        }
    }

    @Test("All houses have valid properties")
    func testHousesValidation() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)

        // Assert - Validate each house
        let expectedHouseIDs = Set(1...12)
        let actualHouseIDs = Set(response.houses.map { $0.house_id })

        #expect(actualHouseIDs == expectedHouseIDs, "Must return houses 1-12")

        for house in response.houses {
            // Validate house ID range
            #expect(house.house_id >= 1 && house.house_id <= 12,
                   "House ID out of range: \(house.house_id)")

            // Validate degree ranges
            #expect(house.start_degree >= 0.0 && house.start_degree < 360.0,
                   "House \(house.house_id) start_degree out of range: \(house.start_degree)")

            #expect(house.end_degree >= 0.0 && house.end_degree < 360.0,
                   "House \(house.house_id) end_degree out of range: \(house.end_degree)")

            // Validate sign
            #expect(!house.sign.isEmpty, "House \(house.house_id) missing sign")

            // Validate planets array exists (can be empty)
            #expect(house.planets != nil, "House \(house.house_id) missing planets array")
        }
    }

    @Test("All aspects have valid properties")
    func testAspectsValidation() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)

        // Assert - Validate aspects
        let validAspectTypes = Set(["Conjunction", "Sextile", "Square", "Trine", "Opposition", "Quincunx"])

        for aspect in response.aspects {
            // Validate planets are different
            #expect(aspect.aspecting_planet != aspect.aspected_planet,
                   "Aspect between same planet: \(aspect.aspecting_planet)")

            // Validate aspect type
            #expect(validAspectTypes.contains(aspect.type),
                   "Invalid aspect type: \(aspect.type)")

            // Validate orb (should be non-negative)
            #expect(aspect.orb >= 0.0, "Aspect orb cannot be negative: \(aspect.orb)")

            // Validate diff (angular difference should be 0-180 degrees)
            #expect(aspect.diff >= 0.0 && aspect.diff <= 180.0,
                   "Aspect diff out of range: \(aspect.diff)")
        }
    }

    @Test("Ascendant and Midheaven are present and valid")
    func testAscendantMidheavenValidation() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)

        // Assert - Ascendant
        if let ascendant = response.ascendant {
            #expect(!ascendant.sign.isEmpty, "Ascendant missing sign")
            #expect(ascendant.full_degree >= 0.0 && ascendant.full_degree < 360.0,
                   "Ascendant degree out of range: \(ascendant.full_degree)")
        }

        // Assert - Midheaven
        if let midheaven = response.midheaven {
            #expect(!midheaven.sign.isEmpty, "Midheaven missing sign")
            #expect(midheaven.full_degree >= 0.0 && midheaven.full_degree < 360.0,
                   "Midheaven degree out of range: \(midheaven.full_degree)")
        }
    }

    // MARK: - Performance Tests

    @Test("API response time is under 3 seconds", .timeLimit(.seconds(5)))
    func testResponseTime() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        let startTime = Date()

        // Act
        _ = try await apiService.fetchChartData(request)

        let duration = Date().timeIntervalSince(startTime)

        // Assert - Should complete within 3 seconds (per SC-001)
        #expect(duration < 3.0, "API response too slow: \(duration) seconds")
    }

    // MARK: - Edge Cases

    @Test("API handles different house systems correctly")
    func testDifferentHouseSystems() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()

        // Test multiple house systems
        let houseSystems = ["placidus", "koch", "equal_house", "whole_sign"]

        for houseSystem in houseSystems {
            let request = NatalChartRequest(
                birthDetails: birthDetails,
                houseSystem: houseSystem
            )

            // Act
            let response = try await apiService.fetchChartData(request)

            // Assert
            #expect(response.planets.count == 10, "House system \(houseSystem) failed")
            #expect(response.houses.count == 12, "House system \(houseSystem) failed")
        }
    }

    @Test("API handles different birth locations correctly")
    func testDifferentLocations() async throws {
        // Test multiple locations around the world
        let locations: [(lat: Double, lon: Double, name: String)] = [
            (40.7128, -74.0060, "New York"),
            (51.5074, -0.1278, "London"),
            (35.6762, 139.6503, "Tokyo"),
            (-33.8688, 151.2093, "Sydney")
        ]

        for location in locations {
            // Arrange
            let birthDetails = BirthDetails(
                name: "Test Person",
                birthDate: createDate(year: 1990, month: 3, day: 15),
                birthTime: createTime(hour: 12, minute: 0),
                birthPlace: location.name,
                timeZone: TimeZone(identifier: "UTC")!,
                coordinate: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
            )

            let request = NatalChartRequest(birthDetails: birthDetails)

            // Act
            let response = try await apiService.fetchChartData(request)

            // Assert
            #expect(response.planets.count == 10, "Location \(location.name) failed")
            #expect(response.houses.count == 12, "Location \(location.name) failed")
        }
    }

    // MARK: - Helper Methods

    private func createTestBirthDetails() -> BirthDetails {
        BirthDetails(
            name: "Test Person",
            birthDate: createDate(year: 1990, month: 3, day: 15),
            birthTime: createTime(hour: 14, minute: 30),
            birthPlace: "New York, USA",
            timeZone: TimeZone(identifier: "America/New_York")!,
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        )
    }

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    private func createTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var contract: Self
}
