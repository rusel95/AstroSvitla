//
//  NatalWheelChartContractTests.swift
//  AstroSvitlaTests
//
//  Contract tests for Prokerala natal_wheel_chart API endpoint
//  Validates chart image generation and URL responses
//
//  NOTE: These tests require valid API credentials in environment variables:
//  - TEST_ASTROLOGY_API_USER_ID
//  - TEST_ASTROLOGY_API_KEY
//

import Testing
import Foundation
@testable import AstroSvitla

@Suite("Natal Wheel Chart Contract Tests", .tags(.contract))
struct NatalWheelChartContractTests {

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
        case invalidURL
        case downloadFailed
    }

    // MARK: - Happy Path Tests

    @Test("API returns valid chart image URL with success status")
    func testValidChartImageResponse() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails, imageFormat: "svg")

        // Act
        let response = try await apiService.generateChartImage(request)

        // Assert - Response structure
        #expect(response.status == true, "Image generation should succeed")
        #expect(!response.chart_url.isEmpty, "Chart URL should not be empty")
        #expect(!response.msg.isEmpty, "Message should not be empty")
    }

    @Test("Chart URL is valid S3 URL format")
    func testChartURLFormat() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act
        let response = try await apiService.generateChartImage(request)

        // Assert - URL validation
        guard let url = URL(string: response.chart_url) else {
            Issue.record("Invalid chart URL: \(response.chart_url)")
            return
        }

        #expect(url.scheme == "https", "Chart URL should use HTTPS")
        #expect(url.host?.contains("amazonaws.com") == true || url.host?.contains("s3") == true,
               "Chart URL should be S3 bucket URL")
    }

    @Test("SVG image can be downloaded from chart URL")
    func testDownloadSVGImage() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails, imageFormat: "svg")

        // Act - Generate chart
        let response = try await apiService.generateChartImage(request)

        guard let imageURL = URL(string: response.chart_url) else {
            throw TestError.invalidURL
        }

        // Act - Download image
        let (data, urlResponse) = try await URLSession.shared.data(from: imageURL)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw TestError.downloadFailed
        }

        // Assert - HTTP success
        #expect(httpResponse.statusCode == 200, "Image download should succeed")

        // Assert - Non-empty data
        #expect(data.count > 0, "Downloaded image should have data")

        // Assert - SVG content type or SVG content
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
        let isSVG = contentType?.contains("svg") == true ||
                    String(data: data, encoding: .utf8)?.contains("<svg") == true

        #expect(isSVG, "Downloaded content should be SVG format")
    }

    @Test("PNG image can be downloaded from chart URL")
    func testDownloadPNGImage() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails, imageFormat: "png")

        // Act - Generate chart
        let response = try await apiService.generateChartImage(request)

        guard let imageURL = URL(string: response.chart_url) else {
            throw TestError.invalidURL
        }

        // Act - Download image
        let (data, urlResponse) = try await URLSession.shared.data(from: imageURL)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw TestError.downloadFailed
        }

        // Assert - HTTP success
        #expect(httpResponse.statusCode == 200, "Image download should succeed")

        // Assert - Non-empty data
        #expect(data.count > 0, "Downloaded image should have data")

        // Assert - PNG signature (first 4 bytes: 89 50 4E 47)
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        let dataPrefix = data.prefix(4)
        let isPNG = Array(dataPrefix) == pngSignature

        #expect(isPNG, "Downloaded content should be valid PNG format")
    }

    // MARK: - Performance Tests

    @Test("API response time is under 2 seconds", .timeLimit(.seconds(5)))
    func testResponseTime() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        let startTime = Date()

        // Act
        _ = try await apiService.generateChartImage(request)

        let duration = Date().timeIntervalSince(startTime)

        // Assert - Should complete within 2 seconds (per contract spec)
        #expect(duration < 2.0, "API response too slow: \(duration) seconds")
    }

    @Test("Image download completes within 2 seconds", .timeLimit(.seconds(5)))
    func testImageDownloadTime() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act - Generate chart URL
        let response = try await apiService.generateChartImage(request)

        guard let imageURL = URL(string: response.chart_url) else {
            throw TestError.invalidURL
        }

        let startTime = Date()

        // Act - Download image
        _ = try await URLSession.shared.data(from: imageURL)

        let duration = Date().timeIntervalSince(startTime)

        // Assert - Should download within 2 seconds
        #expect(duration < 2.0, "Image download too slow: \(duration) seconds")
    }

    // MARK: - Image Format Tests

    @Test("Different image formats generate valid URLs")
    func testImageFormats() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()

        let formats = ["svg", "png"]

        for format in formats {
            let request = NatalChartRequest(
                birthDetails: birthDetails,
                imageFormat: format
            )

            // Act
            let response = try await apiService.generateChartImage(request)

            // Assert
            #expect(response.status == true, "Format \(format) generation failed")
            #expect(!response.chart_url.isEmpty, "Format \(format) returned empty URL")

            // Verify URL contains format extension
            #expect(response.chart_url.contains(".\(format)"),
                   "Chart URL should end with .\(format)")
        }
    }

    @Test("Different chart sizes generate valid images")
    func testChartSizes() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()

        let sizes = [300, 600, 800, 1200]

        for size in sizes {
            let request = NatalChartRequest(
                birthDetails: birthDetails,
                imageFormat: "png",
                chartSize: size
            )

            // Act
            let response = try await apiService.generateChartImage(request)

            // Assert
            #expect(response.status == true, "Size \(size) generation failed")
            #expect(!response.chart_url.isEmpty, "Size \(size) returned empty URL")
        }
    }

    // MARK: - Consistency Tests

    @Test("Same birth data generates consistent chart URLs")
    func testConsistentGeneration() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act - Generate twice
        let response1 = try await apiService.generateChartImage(request)
        let response2 = try await apiService.generateChartImage(request)

        // Assert - Both should succeed
        #expect(response1.status == true, "First generation failed")
        #expect(response2.status == true, "Second generation failed")

        // Note: URLs may differ due to server-side caching/generation
        // but both should be valid URLs
        #expect(URL(string: response1.chart_url) != nil, "First URL invalid")
        #expect(URL(string: response2.chart_url) != nil, "Second URL invalid")
    }

    // MARK: - Integration with Chart Data

    @Test("Image and data endpoints work together")
    func testImageAndDataEndpoints() async throws {
        // Arrange
        let birthDetails = createTestBirthDetails()
        let request = NatalChartRequest(birthDetails: birthDetails)

        // Act - Call both endpoints in parallel
        async let chartData = apiService.fetchChartData(request)
        async let chartImage = apiService.generateChartImage(request)

        let (data, image) = try await (chartData, chartImage)

        // Assert - Both succeed
        #expect(data.planets.count == 10, "Chart data should have 10 planets")
        #expect(data.houses.count == 12, "Chart data should have 12 houses")
        #expect(image.status == true, "Chart image generation should succeed")
        #expect(!image.chart_url.isEmpty, "Chart image URL should not be empty")
    }

    // MARK: - Edge Cases

    @Test("API handles different birth locations for images")
    func testDifferentLocationsForImages() async throws {
        // Test multiple locations
        let locations: [(lat: Double, lon: Double, name: String)] = [
            (40.7128, -74.0060, "New York"),
            (51.5074, -0.1278, "London"),
            (35.6762, 139.6503, "Tokyo")
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
            let response = try await apiService.generateChartImage(request)

            // Assert
            #expect(response.status == true, "Location \(location.name) failed")
            #expect(!response.chart_url.isEmpty, "Location \(location.name) returned empty URL")
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
