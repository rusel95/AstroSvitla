//
//  NatalWheelChartContractTests.swift
//  AstroSvitlaTests
//
//  Updated contract tests for inline SVG/PNG responses from Prokerala wheel endpoint.
//

import Testing
import Foundation
import CoreLocation
@testable import AstroSvitla

@Suite("Natal Wheel Chart Contract Tests", .tags(.contract))
struct NatalWheelChartContractTests {

    let apiService: ProkralaAPIService

    init() throws {
        let environment = ProcessInfo.processInfo.environment
        let clientID = environment["TEST_PROKERALA_CLIENT_ID"] ?? environment["TEST_ASTROLOGY_API_USER_ID"]
        let clientSecret = environment["TEST_PROKERALA_CLIENT_SECRET"] ?? environment["TEST_ASTROLOGY_API_KEY"]

        guard let clientID, let clientSecret,
              clientID.isEmpty == false, clientSecret.isEmpty == false else {
            throw TestError.missingCredentials(
                """
                Set TEST_PROKERALA_CLIENT_ID and TEST_PROKERALA_CLIENT_SECRET (or legacy \
                TEST_ASTROLOGY_API_USER_ID / TEST_ASTROLOGY_API_KEY) before running contract tests.
                """
            )
        }

        apiService = ProkralaAPIService(clientID: clientID, clientSecret: clientSecret)
    }

    enum TestError: Error {
        case missingCredentials(String)
        case invalidSVGData
        case invalidPNGData
    }

    @Test("SVG wheel request returns inline SVG markup")
    func testGenerateSVGImageReturnsSVGData() async throws {
        let request = NatalChartRequest(
            birthDetails: createTestBirthDetails(),
            imageFormat: "svg"
        )

        let resource = try await apiService.generateChartImage(request)

        #expect(resource.data.isEmpty == false, "SVG response should contain data")
        #expect(resource.format == "svg", "Content type should be SVG")

        guard let svgString = String(data: resource.data, encoding: .utf8) else {
            throw TestError.invalidSVGData
        }

        #expect(svgString.contains("<svg"), "Inline SVG markup expected in response")
    }

    @Test("PNG wheel request returns PNG binary data")
    func testGeneratePNGImageReturnsPNGData() async throws {
        let request = NatalChartRequest(
            birthDetails: createTestBirthDetails(),
            imageFormat: "png"
        )

        let resource = try await apiService.generateChartImage(request)

        #expect(resource.data.isEmpty == false, "PNG response should contain data")
        #expect(resource.format == "png", "Content type should be PNG")

        let signature = Array(resource.data.prefix(4))
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]

        #expect(signature == pngSignature, "PNG signature expected")
    }

    @Test("Image and data endpoints stay under combined performance budget", .timeLimit(.seconds(5)))
    func testParallelImageAndDataRequests() async throws {
        let request = NatalChartRequest(birthDetails: createTestBirthDetails())

        let start = Date()
        async let dataResponse = apiService.fetchChartData(request)
        async let imageResource = apiService.generateChartImage(request)

        let (data, image) = try await (dataResponse, imageResource)
        let duration = Date().timeIntervalSince(start)

        #expect(data.planets.count == 10, "Planet count mismatch")
        #expect(data.houses.count == 12, "House count mismatch")
        #expect(image.data.isEmpty == false, "Wheel response missing data")
        #expect(duration < 5.0, "Combined requests exceeded 5 second budget")
    }

    @Test("Multiple locations return wheel data")
    func testDifferentLocationsReturnImages() async throws {
        for sample in locationSamples {
            let details = BirthDetails(
                name: "Test",
                birthDate: makeDate(year: 1990, month: 3, day: 15),
                birthTime: makeTime(hour: 12, minute: 0),
                location: sample.name,
                timeZone: sample.timeZone,
                coordinate: sample.coordinate
            )

            let request = NatalChartRequest(birthDetails: details, imageFormat: "svg")
            let resource = try await apiService.generateChartImage(request)

            #expect(resource.data.isEmpty == false, "Location \(sample.name) should produce SVG data")
        }
    }

    // MARK: - Helpers

    private func createTestBirthDetails() -> BirthDetails {
        BirthDetails(
            name: "Test Person",
            birthDate: makeDate(year: 1990, month: 3, day: 15),
            birthTime: makeTime(hour: 14, minute: 30),
            location: "New York, USA",
            timeZone: TimeZone(identifier: "America/New_York") ?? .gmt,
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }

    private func makeTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }

    private var locationSamples: [(name: String, coordinate: CLLocationCoordinate2D, timeZone: TimeZone)] {
        [
            (
                "New York, USA",
                CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
                TimeZone(identifier: "America/New_York") ?? .gmt
            ),
            (
                "London, UK",
                CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
                TimeZone(identifier: "Europe/London") ?? .gmt
            ),
            (
                "Tokyo, Japan",
                CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                TimeZone(identifier: "Asia/Tokyo") ?? .gmt
            )
        ]
    }
}
