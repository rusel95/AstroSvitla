import Testing
import Foundation
import CoreLocation
@testable import AstroSvitla

/// Tests for house ruler calculation logic using traditional rulerships.
/// Verifies that house rulers are correctly determined and their placements are accurate.
@MainActor
struct HouseRulerCalculationTests {
    
    // MARK: - Test Helpers
    
    /// Load the canonical natal chart fixture for testing
    private func loadFixture() throws -> AstrologyAPINatalChartResponse {
        let fixtureURL = URL(fileURLWithPath: "/Users/Ruslan_Popesku/Desktop/AstroSvitla/specs/005-enhance-astrological-report/contracts/fixtures/natal-chart-sample.json")
        let data = try Data(contentsOf: fixtureURL)
        return try JSONDecoder().decode(AstrologyAPINatalChartResponse.self, from: data)
    }
    
    // MARK: - Traditional Rulership Tests
    
    @Test("Traditional rulership table returns correct rulers for all signs")
    func testTraditionalRulershipTable() throws {
        // Test all 12 signs have correct traditional rulers
        #expect(TraditionalRulershipTable.ruler(of: .aries) == .mars)
        #expect(TraditionalRulershipTable.ruler(of: .taurus) == .venus)
        #expect(TraditionalRulershipTable.ruler(of: .gemini) == .mercury)
        #expect(TraditionalRulershipTable.ruler(of: .cancer) == .moon)
        #expect(TraditionalRulershipTable.ruler(of: .leo) == .sun)
        #expect(TraditionalRulershipTable.ruler(of: .virgo) == .mercury)
        #expect(TraditionalRulershipTable.ruler(of: .libra) == .venus)
        #expect(TraditionalRulershipTable.ruler(of: .scorpio) == .mars)
        #expect(TraditionalRulershipTable.ruler(of: .sagittarius) == .jupiter)
        #expect(TraditionalRulershipTable.ruler(of: .capricorn) == .saturn)
        #expect(TraditionalRulershipTable.ruler(of: .aquarius) == .saturn)
        #expect(TraditionalRulershipTable.ruler(of: .pisces) == .jupiter)
    }
    
    // MARK: - House Ruler Calculation Tests
    
    @Test("Natal chart contains house rulers for all 12 houses")
    func testNatalChartHasAllHouseRulers() throws {
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
        
        // Verify all 12 houses have rulers
        #expect(natalChart.houseRulers.count == 12)
        
        // Verify each house number 1-12 has exactly one ruler
        for houseNum in 1...12 {
            let rulers = natalChart.houseRulers.filter { $0.houseNumber == houseNum }
            #expect(rulers.count == 1, "House \(houseNum) should have exactly one ruler")
        }
    }
    
    @Test("Ascendant ruler is correctly calculated")
    func testAscendantRulerCalculation() throws {
        // Load fixture
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
        
        // Find 1st house (Ascendant) ruler
        guard let ascendantRuler = natalChart.houseRulers.first(where: { $0.houseNumber == 1 }) else {
            Issue.record("Ascendant ruler not found")
            return
        }
        
        // Verify ascendant ruler matches the sign on the 1st house cusp
        guard let firstHouse = natalChart.houses.first(where: { $0.number == 1 }) else {
            Issue.record("First house not found")
            return
        }
        
        let expectedRuler = TraditionalRulershipTable.ruler(of: firstHouse.sign)
        #expect(ascendantRuler.rulingPlanet == expectedRuler)
        
        // Verify ruler planet exists in chart
        let rulerPlanet = natalChart.planets.first { $0.name == ascendantRuler.rulingPlanet }
        #expect(rulerPlanet != nil, "Ruling planet \(ascendantRuler.rulingPlanet) should exist in chart")
        
        // Verify ruler's house placement matches
        if let ruler = rulerPlanet {
            #expect(ascendantRuler.rulerHouse == ruler.house)
            #expect(ascendantRuler.rulerSign == ruler.sign)
        }
    }
    
    @Test("Each house ruler points to an existing planet in the chart")
    func testHouseRulersReferenceValidPlanets() throws {
        let fixtureResponse = try loadFixture()
        let birthDetails = BirthDetails(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 315532800),
            birthTime: Date(timeIntervalSince1970: 315532800),
            location: "Test City",
            timeZone: TimeZone.current,
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 30.0)
        )
        
        let natalChart = try AstrologyAPIDTOMapper.toDomain(
            response: fixtureResponse,
            birthDetails: birthDetails
        )
        
        let planetTypes = Set(natalChart.planets.map { $0.name })
        
        for ruler in natalChart.houseRulers {
            #expect(
                planetTypes.contains(ruler.rulingPlanet),
                "House \(ruler.houseNumber) ruler \(ruler.rulingPlanet) should exist in chart planets"
            )
        }
    }
    
    @Test("House rulers are computed from house cusp signs")
    func testHouseRulersMatchCuspSigns() throws {
        let fixtureResponse = try loadFixture()
        let birthDetails = BirthDetails(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 315532800),
            birthTime: Date(timeIntervalSince1970: 315532800),
            location: "Test City",
            timeZone: TimeZone.current,
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 30.0)
        )
        
        let natalChart = try AstrologyAPIDTOMapper.toDomain(
            response: fixtureResponse,
            birthDetails: birthDetails
        )
        
        // For each house, verify its ruler matches the traditional ruler of the cusp sign
        for house in natalChart.houses {
            guard let houseRuler = natalChart.houseRulers.first(where: { $0.houseNumber == house.number }) else {
                Issue.record("No ruler found for house \(house.number)")
                continue
            }
            
            let expectedRuler = TraditionalRulershipTable.ruler(of: house.sign)
            #expect(
                houseRuler.rulingPlanet == expectedRuler,
                "House \(house.number) with \(house.sign) on cusp should be ruled by \(expectedRuler), got \(houseRuler.rulingPlanet)"
            )
        }
    }
}
