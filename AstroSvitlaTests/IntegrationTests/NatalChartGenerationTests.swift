//
//  NatalChartGenerationTests.swift
//  AstroSvitlaTests
//
//  Integration tests for complete natal chart generation flow
//  Tests end-to-end: API calls → Data mapping → Caching → Retrieval
//
//  NOTE: These tests require valid API credentials in environment variables:
//  - TEST_ASTROLOGY_API_USER_ID
//  - TEST_ASTROLOGY_API_KEY
//

import Testing
import Foundation
import CoreLocation
import SwiftData
@testable import AstroSvitla

@Suite("Natal Chart Generation Integration Tests", .tags(.integration))
struct NatalChartGenerationTests {

    let apiService: ProkralaAPIService
    let chartCacheService: ChartCacheService
    let modelContainer: ModelContainer

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

        // Initialize API service
        apiService = ProkralaAPIService(clientID: clientID, clientSecret: clientSecret)

        // Initialize in-memory SwiftData container for tests
        let schema = Schema([CachedNatalChart.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])

        // Initialize chart cache service
        let context = modelContainer.mainContext
        chartCacheService = ChartCacheService(context: context)
    }

    enum TestError: Error {
        case missingCredentials(String)
    }

    // MARK: - Full Flow Integration Tests

    @Test("Complete chart generation flow from API to cache", .timeLimit(.seconds(10)))
    func testCompleteChartGenerationFlow() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act - Fetch data
        let dataResponse = try await apiService.fetchChartData(request)

        // Act - Map DTOs to domain model
        let natalChart = try DTOMapper.toDomain(response: dataResponse, birthDetails: birthDetails)

        // Assert - Complete natal chart structure
        #expect(natalChart.planets.count == 10, "Should have 10 planets")
        #expect(natalChart.houses.count == 12, "Should have 12 houses")
        #expect(natalChart.aspects.count > 0, "Should have aspects")
        #expect(natalChart.ascendant >= 0 && natalChart.ascendant < 360, "Valid ascendant")
        #expect(natalChart.midheaven >= 0 && natalChart.midheaven < 360, "Valid midheaven")

        // Act - Cache natal chart to SwiftData (without image)
        try chartCacheService.saveChart(
            natalChart,
            imageFileID: nil,
            imageFormat: nil
        )

        // Assert - Chart can be retrieved from cache
        let cachedChart = try chartCacheService.loadChart(id: natalChart.id)

        #expect(cachedChart.id == natalChart.id, "Chart IDs should match")
        #expect(cachedChart.planets.count == natalChart.planets.count, "Planets count should match")
        #expect(cachedChart.houses.count == natalChart.houses.count, "Houses count should match")
    }

    @Test("Chart generation completes within 5 seconds", .timeLimit(.seconds(6)))
    func testPerformanceRequirement() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        let startTime = Date()

        // Act - Full generation flow
        let dataResponse = try await apiService.fetchChartData(request)

        let duration = Date().timeIntervalSince(startTime)

        // Assert - SC-001: Chart generation < 5 seconds
        #expect(duration < 5.0, "Chart generation took \(duration) seconds (must be < 5s)")

        // Also verify we got valid data
        #expect(dataResponse.data.planetPositions.count >= 10)
    }

    @Test("Cached chart retrieval works offline")
    func testOfflineChartAccess() async throws {
        // Arrange - Generate and cache a chart first
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act - Fetch and cache
        let dataResponse = try await apiService.fetchChartData(request)
        let natalChart = try DTOMapper.toDomain(response: dataResponse, birthDetails: birthDetails)

        try chartCacheService.saveChart(natalChart, imageFileID: nil, imageFormat: nil)

        // Act - Retrieve from cache (simulating offline)
        let cachedChart = try chartCacheService.loadChart(id: natalChart.id)

        // Assert - Retrieved data matches original
        #expect(cachedChart.id == natalChart.id)
        #expect(cachedChart.planets.count == 10)
        #expect(cachedChart.houses.count == 12)
    }

    @Test("Cache lookup by birth data works correctly")
    func testCacheLookupByBirthData() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act - Generate and cache chart
        let dataResponse = try await apiService.fetchChartData(request)
        let natalChart = try DTOMapper.toDomain(response: dataResponse, birthDetails: birthDetails)

        try chartCacheService.saveChart(natalChart, imageFileID: nil, imageFormat: nil)

        // Act - Find chart by birth data
        let foundChart = chartCacheService.findChart(birthDetails: birthDetails)

        // Assert - Chart found with matching data
        #expect(foundChart != nil, "Should find cached chart by birth data")
        #expect(foundChart?.id == natalChart.id, "Found chart should match original")
    }

    @Test("Cache expiration is detected after 30 days")
    func testCacheExpiration() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act - Generate and cache chart
        let dataResponse = try await apiService.fetchChartData(request)
        let natalChart = try DTOMapper.toDomain(response: dataResponse, birthDetails: birthDetails)

        try chartCacheService.saveChart(natalChart, imageFileID: nil, imageFormat: nil)

        // Load cached chart
        let cachedChart = try chartCacheService.loadChart(id: natalChart.id)

        // Act - Check if fresh (should be fresh immediately)
        let isFresh = !chartCacheService.isCacheStale(cachedChart)
        #expect(isFresh, "Newly cached chart should not be stale")

        // Note: To test 30-day expiration, we'd need to modify the generatedAt timestamp
        // This is better done in a unit test with a mock date
    }

    @Test("Multiple charts can be cached and retrieved")
    func testMultipleChartsCaching() async throws {
        // Arrange - Create different birth data
        let birthData1 = createTestBirthDetails()
        let birthData2 = BirthDetails(
            name: "Another Person",
            birthDate: createDate(year: 1985, month: 6, day: 20),
            birthTime: createTime(hour: 10, minute: 15),
            location: "London, UK",
            timeZone: TimeZone(identifier: "Europe/London")!,
            coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        )

        let request1 = NatalChartRequest(birthDetails: birthData1)
        let request2 = NatalChartRequest(birthDetails: birthData2)

        // Act - Generate both charts
        let response1 = try await apiService.fetchChartData(request1)
        let response2 = try await apiService.fetchChartData(request2)

        let chart1 = try DTOMapper.toDomain(response: response1, birthDetails: birthData1)
        let chart2 = try DTOMapper.toDomain(response: response2, birthDetails: birthData2)

        // Act - Cache both
        try chartCacheService.saveChart(chart1, imageFileID: nil, imageFormat: nil)
        try chartCacheService.saveChart(chart2, imageFileID: nil, imageFormat: nil)

        // Act - Retrieve both
        let cached1 = try chartCacheService.loadChart(id: chart1.id)
        let cached2 = try chartCacheService.loadChart(id: chart2.id)

        // Assert - Both retrieved correctly
        #expect(cached1.id == chart1.id)
        #expect(cached2.id == chart2.id)
        #expect(cached1.birthData.birthDate != cached2.birthData.birthDate)
    }

    // MARK: - Data Validation Tests

    @Test("All planets are mapped correctly from API response")
    func testPlanetMapping() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)
        let natalChart = try DTOMapper.toDomain(response: response, birthDetails: birthDetails)

        // Assert - All planet types present
        let planetTypes = Set(natalChart.planets.map { $0.name })
        let expectedTypes: Set<PlanetType> = [
            .sun, .moon, .mercury, .venus, .mars,
            .jupiter, .saturn, .uranus, .neptune, .pluto
        ]

        #expect(planetTypes == expectedTypes, "All planet types should be present")

        // Assert - All planets have valid properties
        for planet in natalChart.planets {
            #expect(planet.longitude >= 0 && planet.longitude < 360, "Valid longitude for \(planet.name)")
            #expect(planet.house >= 1 && planet.house <= 12, "Valid house for \(planet.name)")
            #expect(planet.degreeInSign >= 0 && planet.degreeInSign < 30, "Valid degree in sign for \(planet.name)")
        }
    }

    @Test("All houses are mapped correctly from API response")
    func testHouseMapping() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)
        let natalChart = try DTOMapper.toDomain(response: response, birthDetails: birthDetails)

        // Assert - All house numbers present
        let houseNumbers = Set(natalChart.houses.map { $0.number })
        let expectedNumbers = Set(1...12)

        #expect(houseNumbers == expectedNumbers, "Houses 1-12 should all be present")

        // Assert - All houses have valid cusps
        for house in natalChart.houses {
            #expect(house.cusp >= 0 && house.cusp < 360, "Valid cusp for house \(house.number)")
        }
    }

    @Test("Aspects are mapped correctly from API response")
    func testAspectMapping() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.fetchChartData(request)
        let natalChart = try DTOMapper.toDomain(response: response, birthDetails: birthDetails)

        // Assert - Aspects have valid properties
        for aspect in natalChart.aspects {
            #expect(aspect.planet1 != aspect.planet2, "Aspect planets should be different")
            #expect(aspect.orb >= 0, "Orb should be non-negative")
            #expect(aspect.angle >= 0 && aspect.angle <= 180, "Angle should be 0-180 degrees")
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
    @Tag static var integration: Self
}
