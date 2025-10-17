import Testing
import Foundation
import CoreLocation
@testable import AstroSvitla

/// Tests for aspect sorting and coverage requirements.
/// Verifies that natal charts include at least 20 aspects sorted by orb tightness.
@MainActor
struct AspectSortingTests {

    // MARK: - Test Helpers

    /// Load the canonical natal chart fixture for testing
    private func loadFixture() throws -> AstrologyAPINatalChartResponse {
        let fixtureURL = URL(fileURLWithPath: "/Users/Ruslan_Popesku/Desktop/AstroSvitla/specs/005-enhance-astrological-report/contracts/fixtures/natal-chart-sample.json")
        let data = try Data(contentsOf: fixtureURL)
        return try JSONDecoder().decode(AstrologyAPINatalChartResponse.self, from: data)
    }

    // MARK: - Aspect Coverage Tests

    @Test("Natal chart includes at least 20 aspects")
    func testMinimumAspectCount() throws {
        // Load fixture and create birth details
        let fixtureResponse = try loadFixture()
        let birthDetails = BirthDetails(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 315532800), // 1980-01-01
            birthTime: Date(timeIntervalSince1970: 315532800),
            location: "Test City",
            timeZone: TimeZone.current,
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 30.0)
        )

        // Map to domain model
        let natalChart = try AstrologyAPIDTOMapper.toDomain(
            response: fixtureResponse,
            birthDetails: birthDetails
        )

        // Verify at least 20 aspects are included
        #expect(
            natalChart.aspects.count >= 20,
            "Chart should include at least 20 aspects, got \(natalChart.aspects.count)"
        )
    }

    @Test("Top 20 aspects are sorted by orb tightness")
    func testTopTwentyAspectsSortedByOrb() throws {
        // Load fixture and create birth details
        let fixtureResponse = try loadFixture()
        let birthDetails = BirthDetails(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 315532800),
            birthTime: Date(timeIntervalSince1970: 315532800),
            location: "Test City",
            timeZone: TimeZone.current,
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 30.0)
        )

        // Map to domain model
        let natalChart = try AstrologyAPIDTOMapper.toDomain(
            response: fixtureResponse,
            birthDetails: birthDetails
        )

        // Get top 20 aspects (or all if fewer)
        let topAspects = Array(natalChart.aspects.prefix(20))

        // Verify they are sorted by orb (ascending)
        for i in 0..<(topAspects.count - 1) {
            let currentOrb = topAspects[i].orb
            let nextOrb = topAspects[i + 1].orb
            #expect(
                currentOrb <= nextOrb,
                "Aspect at index \(i) has orb \(currentOrb) which is greater than aspect at \(i+1) with orb \(nextOrb)"
            )
        }
    }

    @Test("All aspects in natal chart are sorted by orb")
    func testAllAspectsSortedByOrb() throws {
        // Load fixture and create birth details
        let fixtureResponse = try loadFixture()
        let birthDetails = BirthDetails(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 315532800),
            birthTime: Date(timeIntervalSince1970: 315532800),
            location: "Test City",
            timeZone: TimeZone.current,
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 30.0)
        )

        // Map to domain model
        let natalChart = try AstrologyAPIDTOMapper.toDomain(
            response: fixtureResponse,
            birthDetails: birthDetails
        )

        // Verify all aspects are sorted by orb (ascending - tightest first)
        for i in 0..<(natalChart.aspects.count - 1) {
            let currentOrb = natalChart.aspects[i].orb
            let nextOrb = natalChart.aspects[i + 1].orb
            #expect(
                currentOrb <= nextOrb,
                "Aspect \(i): \(natalChart.aspects[i].planet1)-\(natalChart.aspects[i].planet2) orb \(currentOrb)° should be <= aspect \(i+1): \(natalChart.aspects[i+1].planet1)-\(natalChart.aspects[i+1].planet2) orb \(nextOrb)°"
            )
        }
    }

    @Test("Aspects include explicit orb values")
    func testAspectsHaveExplicitOrbValues() throws {
        // Load fixture and create birth details
        let fixtureResponse = try loadFixture()
        let birthDetails = BirthDetails(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 315532800),
            birthTime: Date(timeIntervalSince1970: 315532800),
            location: "Test City",
            timeZone: TimeZone.current,
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 30.0)
        )

        // Map to domain model
        let natalChart = try AstrologyAPIDTOMapper.toDomain(
            response: fixtureResponse,
            birthDetails: birthDetails
        )

        // Verify all aspects have valid orb values (>= 0)
        for aspect in natalChart.aspects {
            #expect(
                aspect.orb >= 0,
                "Aspect \(aspect.planet1)-\(aspect.planet2) should have non-negative orb, got \(aspect.orb)"
            )

            // Verify orb is within the max orb for the aspect type
            #expect(
                aspect.orb <= aspect.type.maxOrb,
                "Aspect \(aspect.planet1)-\(aspect.planet2) orb \(aspect.orb) exceeds max \(aspect.type.maxOrb) for \(aspect.type)"
            )
        }
    }

    @Test("Fixture data contains at least 20 aspects")
    func testFixtureDataCompleteness() throws {
        // This test validates the fixture itself to ensure it has sufficient test data
        let fixtureResponse = try loadFixture()

        guard let aspectsData = fixtureResponse.chartData.aspects else {
            Issue.record("Fixture is missing aspects data")
            return
        }

        #expect(
            aspectsData.count >= 20,
            "Fixture should contain at least 20 aspects for comprehensive testing, got \(aspectsData.count)"
        )
    }

    @Test("Tightest aspect comes first in sorted list")
    func testTightestAspectFirst() throws {
        // Load fixture and create birth details
        let fixtureResponse = try loadFixture()
        let birthDetails = BirthDetails(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 315532800),
            birthTime: Date(timeIntervalSince1970: 315532800),
            location: "Test City",
            timeZone: TimeZone.current,
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 30.0)
        )

        // Map to domain model
        let natalChart = try AstrologyAPIDTOMapper.toDomain(
            response: fixtureResponse,
            birthDetails: birthDetails
        )

        guard let firstAspect = natalChart.aspects.first else {
            Issue.record("Chart has no aspects")
            return
        }

        // Verify first aspect has the smallest orb
        let allOrbs = natalChart.aspects.map { $0.orb }
        let minOrb = allOrbs.min() ?? 0

        #expect(
            firstAspect.orb == minOrb,
            "First aspect should have the tightest orb (\(minOrb)), got \(firstAspect.orb)"
        )
    }
}
