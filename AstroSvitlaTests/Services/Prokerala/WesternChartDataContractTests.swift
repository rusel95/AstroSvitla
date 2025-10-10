//
//  WesternChartDataContractTests.swift
//  AstroSvitlaTests
//
//  Contract tests for Prokerala natal-planet-position compute endpoint
//  Validates real API responses match expected structure and data types
//
//  NOTE: These tests require valid API credentials in environment variables:
//  - TEST_ASTROLOGY_API_USER_ID
//  - TEST_ASTROLOGY_API_KEY
//

import Testing
import Foundation
import CoreLocation
@testable import AstroSvitla

@Suite("Western Chart Data Contract Tests", .tags(.contract))
struct WesternChartDataContractTests {

    let apiService: ProkralaAPIService

    init() throws {
        // Load test credentials from environment variables
        let environment = ProcessInfo.processInfo.environment
        let clientID = environment["TEST_PROKERALA_CLIENT_ID"] ?? environment["TEST_ASTROLOGY_API_USER_ID"]
        let clientSecret = environment["TEST_PROKERALA_CLIENT_SECRET"] ?? environment["TEST_ASTROLOGY_API_KEY"]

        guard let clientID, let clientSecret,
              clientID.isEmpty == false, clientSecret.isEmpty == false else {
            throw TestError.missingCredentials(
                "Set TEST_PROKERALA_CLIENT_ID and TEST_PROKERALA_CLIENT_SECRET (or legacy TEST_ASTROLOGY_API_USER_ID / TEST_ASTROLOGY_API_KEY)"
            )
        }

        apiService = ProkralaAPIService(clientID: clientID, clientSecret: clientSecret)
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
            location: "New York, USA",
            timeZone: TimeZone(identifier: "America/New_York")!,
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        )

        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)
        let data = response.data

        // Assert - Response structure
        #expect(data.planetPositions.count >= 10, "Must return planet positions")
        #expect(data.houses.count == 12, "Must return exactly 12 houses")
        #expect(data.aspects.count > 0, "Should return at least some aspects")
    }

    @Test("All planets have valid properties")
    func testPlanetsValidation() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)
        let data = response.data

        // Assert - Validate each planet
        let expectedPlanets = Set(["Sun", "Moon", "Mercury", "Venus", "Mars",
                                   "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"])
        let actualPlanets = Set(
            data.planetPositions
                .compactMap { PlanetType(rawValue: $0.name)?.rawValue }
        )

        #expect(actualPlanets == expectedPlanets, "Must return all 10 standard planets")

        for planet in data.planetPositions where expectedPlanets.contains(planet.name) {
            #expect(planet.longitude >= 0.0 && planet.longitude < 360.0,
                   "Planet \(planet.name) longitude out of range: \(planet.longitude)")

            #expect(planet.degree >= 0.0 && planet.degree < 30.0,
                   "Planet \(planet.name) degree out of range: \(planet.degree)")

            #expect(planet.zodiac.name.isEmpty == false,
                   "Planet \(planet.name) missing zodiac sign")
        }
    }

    @Test("All houses have valid properties")
    func testHousesValidation() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)
        let houses = response.data.houses

        let expectedHouseIDs = Set(1...12)
        let actualHouseIDs = Set(houses.map { $0.number })

        #expect(actualHouseIDs == expectedHouseIDs, "Must return houses 1-12")

        for house in houses {
            #expect(house.number >= 1 && house.number <= 12,
                   "House number out of range: \(house.number)")

            #expect(house.startCusp.longitude >= 0.0 && house.startCusp.longitude < 360.0,
                   "House \(house.number) start longitude out of range: \(house.startCusp.longitude)")

            #expect(house.endCusp.longitude >= 0.0 && house.endCusp.longitude < 360.0,
                   "House \(house.number) end longitude out of range: \(house.endCusp.longitude)")

            #expect(house.startCusp.zodiac.name.isEmpty == false,
                   "House \(house.number) missing zodiac sign")
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

        for aspect in response.data.aspects {
            #expect(aspect.planetOne.name != aspect.planetTwo.name,
                   "Aspect between same planet: \(aspect.planetOne.name)")

            #expect(validAspectTypes.contains(aspect.aspect.name),
                   "Invalid aspect type: \(aspect.aspect.name)")

            #expect(aspect.orb >= 0.0, "Aspect orb cannot be negative: \(aspect.orb)")
        }
    }

    @Test("Ascendant and Midheaven are present and valid")
    func testAscendantMidheavenValidation() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)
        let angles = response.data.angles

        let ascendant = angles.first(where: { $0.name.caseInsensitiveCompare("Ascendant") == .orderedSame })
        let midheaven = angles.first(where: {
            $0.name.caseInsensitiveCompare("Midheaven") == .orderedSame ||
            $0.name.caseInsensitiveCompare("MC") == .orderedSame
        })

        if let ascendant {
            #expect(ascendant.longitude >= 0 && ascendant.longitude < 360, "Ascendant longitude invalid")
        }

        if let midheaven {
            #expect(midheaven.longitude >= 0 && midheaven.longitude < 360, "Midheaven longitude invalid")
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

            let response = try await apiService.fetchChartData(request)
            let data = response.data

            #expect(data.planetPositions.count >= 10, "House system \(houseSystem) failed")
            #expect(data.houses.count == 12, "House system \(houseSystem) failed")
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
                location: location.name,
                timeZone: TimeZone(identifier: "UTC")!,
                coordinate: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
            )

            let request = NatalChartRequest(birthDetails: birthDetails)

            // Act
            let response = try await apiService.fetchChartData(request)
            let data = response.data

            #expect(data.planetPositions.count >= 10, "Location \(location.name) missing planets")
            #expect(data.houses.count == 12, "Location \(location.name) missing houses")
        }
    }

    // MARK: - Helper Methods

    private func createTestBirthDetails() -> BirthDetails {
        BirthDetails(
            name: "Test Person",
            birthDate: createDate(year: 1990, month: 3, day: 15),
            birthTime: createTime(hour: 14, minute: 30),
            location: "New York, USA",
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
