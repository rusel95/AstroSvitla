import Testing
import Foundation
import CoreLocation
@testable import AstroSvitla

/// Tests for report assembly and structure requirements.
/// Verifies that generated reports contain all required sections and proper data organization.
@MainActor
struct ReportAssemblerTests {

    // MARK: - Test Helpers

    /// Create a sample birth details for testing
    private func createSampleBirthDetails() -> BirthDetails {
        return BirthDetails(
            name: "Test Person",
            birthDate: Date(timeIntervalSince1970: 315532800), // 1980-01-01
            birthTime: Date(timeIntervalSince1970: 315532800),
            location: "Test City",
            timeZone: TimeZone.current,
            coordinate: CLLocationCoordinate2D(latitude: 50.0, longitude: 30.0)
        )
    }

    /// Create a comprehensive natal chart for testing
    private func createComprehensiveNatalChart() throws -> NatalChart {
        // Load fixture for comprehensive test data
        let fixtureURL = URL(fileURLWithPath: "/Users/Ruslan_Popesku/Desktop/AstroSvitla/specs/005-enhance-astrological-report/contracts/fixtures/natal-chart-sample.json")
        let data = try Data(contentsOf: fixtureURL)
        let fixtureResponse = try JSONDecoder().decode(AstrologyAPINatalChartResponse.self, from: data)

        return try AstrologyAPIDTOMapper.toDomain(
            response: fixtureResponse,
            birthDetails: createSampleBirthDetails()
        )
    }

    // MARK: - Report Structure Tests

    @Test("Generated report contains all required top-level sections")
    func testReportContainsAllSections() async throws {
        let birthDetails = createSampleBirthDetails()
        let natalChart = try createComprehensiveNatalChart()

        let generator = AIReportGenerator()

        let report = try await generator.generateReport(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart,
            languageCode: "uk",
            languageDisplayName: "Ukrainian",
            repositoryContext: "test"
        )

        // Verify report has required top-level fields
        #expect(report.summary.isEmpty == false, "Report should have a summary")
        #expect(report.keyInfluences.isEmpty == false, "Report should have key influences")
        #expect(report.detailedAnalysis.isEmpty == false, "Report should have detailed analysis")
        #expect(report.recommendations.isEmpty == false, "Report should have recommendations")
    }

    @Test("Key influences section includes all 10 planets")
    func testKeyInfluencesContainsAllPlanets() async throws {
        let birthDetails = createSampleBirthDetails()
        let natalChart = try createComprehensiveNatalChart()

        let generator = AIReportGenerator()

        let report = try await generator.generateReport(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart,
            languageCode: "uk",
            languageDisplayName: "Ukrainian",
            repositoryContext: "test"
        )

        // Verify all 10 planets are mentioned in key influences
        let expectedPlanets: [PlanetType] = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]

        for planet in expectedPlanets {
            let planetMentioned = report.keyInfluences.contains { influence in
                influence.lowercased().contains(planet.rawValue.lowercased())
            }
            #expect(
                planetMentioned,
                "Key influences should mention \(planet.rawValue)"
            )
        }
    }

    @Test("Detailed analysis mentions Ascendant and Midheaven")
    func testDetailedAnalysisMentionsAngles() async throws {
        let birthDetails = createSampleBirthDetails()
        let natalChart = try createComprehensiveNatalChart()

        let generator = AIReportGenerator()

        let report = try await generator.generateReport(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart,
            languageCode: "uk",
            languageDisplayName: "Ukrainian",
            repositoryContext: "test"
        )

        let analysis = report.detailedAnalysis.lowercased()

        // Check for Ascendant mentions (various possible terms)
        let ascendantMentioned = analysis.contains("ascendant") ||
                                 analysis.contains("асцендент") ||
                                 analysis.contains("rising sign")

        #expect(ascendantMentioned, "Detailed analysis should mention Ascendant")

        // Check for Midheaven mentions (various possible terms)
        let midheavenMentioned = analysis.contains("midheaven") ||
                                 analysis.contains("середина неба") ||
                                 analysis.contains("mc") ||
                                 analysis.contains("medium coeli")

        #expect(midheavenMentioned, "Detailed analysis should mention Midheaven")
    }

    @Test("Detailed analysis includes karmic nodes discussion")
    func testDetailedAnalysisIncludesNodes() async throws {
        let birthDetails = createSampleBirthDetails()
        let natalChart = try createComprehensiveNatalChart()

        let generator = AIReportGenerator()

        let report = try await generator.generateReport(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart,
            languageCode: "uk",
            languageDisplayName: "Ukrainian",
            repositoryContext: "test"
        )

        let analysis = report.detailedAnalysis.lowercased()

        // Check for North Node mentions
        let northNodeMentioned = analysis.contains("north node") ||
                                 analysis.contains("північний вузол") ||
                                 analysis.contains("true node")

        // Check for South Node mentions
        let southNodeMentioned = analysis.contains("south node") ||
                                 analysis.contains("південний вузол")

        #expect(
            northNodeMentioned || southNodeMentioned,
            "Detailed analysis should mention karmic nodes"
        )
    }

    @Test("Detailed analysis mentions house rulers")
    func testDetailedAnalysisMentionsHouseRulers() async throws {
        let birthDetails = createSampleBirthDetails()
        let natalChart = try createComprehensiveNatalChart()

        let generator = AIReportGenerator()

        let report = try await generator.generateReport(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart,
            languageCode: "uk",
            languageDisplayName: "Ukrainian",
            repositoryContext: "test"
        )

        let analysis = report.detailedAnalysis.lowercased()

        // Check for house ruler mentions
        let houseRulerMentioned = analysis.contains("house ruler") ||
                                  analysis.contains("правитель дому") ||
                                  analysis.contains("ruler of")

        #expect(houseRulerMentioned, "Detailed analysis should mention house rulers")
    }

    @Test("Detailed analysis mentions multiple aspects")
    func testDetailedAnalysisMentionsAspects() async throws {
        let birthDetails = createSampleBirthDetails()
        let natalChart = try createComprehensiveNatalChart()

        let generator = AIReportGenerator()

        let report = try await generator.generateReport(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart,
            languageCode: "uk",
            languageDisplayName: "Ukrainian",
            repositoryContext: "test"
        )

        let analysis = report.detailedAnalysis.lowercased()

        // Count aspect type mentions
        let aspectTypes = ["conjunction", "opposition", "trine", "square", "sextile",
                          "кон'юнкція", "опозиція", "тригон", "квадрат", "секстиль"]

        var aspectMentionCount = 0
        for aspectType in aspectTypes {
            if analysis.contains(aspectType) {
                aspectMentionCount += 1
            }
        }

        #expect(
            aspectMentionCount >= 3,
            "Detailed analysis should mention at least 3 different aspect types"
        )
    }

    @Test("Report includes knowledge usage transparency information")
    func testReportIncludesKnowledgeUsage() async throws {
        let birthDetails = createSampleBirthDetails()
        let natalChart = try createComprehensiveNatalChart()

        let generator = AIReportGenerator()

        let report = try await generator.generateReport(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart,
            languageCode: "uk",
            languageDisplayName: "Ukrainian",
            repositoryContext: "test"
        )

        // Verify knowledge usage section exists
        #expect(report.knowledgeUsage.notes != nil || report.knowledgeUsage.sources != nil,
                "Report should include knowledge usage information")
    }

    @Test("Report structure is valid JSON serializable")
    func testReportIsJSONSerializable() async throws {
        let birthDetails = createSampleBirthDetails()
        let natalChart = try createComprehensiveNatalChart()

        let generator = AIReportGenerator()

        let report = try await generator.generateReport(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart,
            languageCode: "uk",
            languageDisplayName: "Ukrainian",
            repositoryContext: "test"
        )

        // Attempt to encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let jsonData = try encoder.encode(report)

        // Verify we got valid JSON data
        #expect(jsonData.count > 0, "Report should encode to valid JSON")

        // Verify we can decode it back
        let decoder = JSONDecoder()
        let decodedReport = try decoder.decode(GeneratedReport.self, from: jsonData)

        #expect(decodedReport.area == report.area)
        #expect(decodedReport.summary == report.summary)
    }
}
