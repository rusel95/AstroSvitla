import Testing
import Foundation
import CoreLocation
@testable import AstroSvitla

/// Tests for StubKnowledgeSourceProvider that returns empty sources with transparency notice.
/// Verifies that when vector store is unavailable, the system provides honest transparency messaging.
@MainActor
struct KnowledgeProviderStubTests {

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

    /// Create a minimal natal chart for testing
    private func createSampleNatalChart() -> NatalChart {
        return NatalChart(
            birthDate: Date(timeIntervalSince1970: 315532800),
            birthTime: Date(timeIntervalSince1970: 315532800),
            latitude: 50.0,
            longitude: 30.0,
            locationName: "Test City",
            planets: [],
            houses: [],
            aspects: [],
            houseRulers: [],
            ascendant: 0,
            midheaven: 0,
            calculatedAt: Date(),
            imageFileID: "test-image",
            imageFormat: "svg"
        )
    }

    // MARK: - Stub Provider Tests

    @Test("Stub provider returns empty sources list")
    func testStubProviderReturnsEmptySources() async throws {
        let provider = StubKnowledgeSourceProvider()
        let birthDetails = createSampleBirthDetails()
        let natalChart = createSampleNatalChart()

        let usage = await provider.loadKnowledgeUsage(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart
        )

        // Verify no sources are returned
        #expect(usage.sources == nil || usage.sources?.isEmpty == true)
    }

    @Test("Stub provider indicates vector source was not used")
    func testStubProviderIndicatesNoVectorSource() async throws {
        let provider = StubKnowledgeSourceProvider()
        let birthDetails = createSampleBirthDetails()
        let natalChart = createSampleNatalChart()

        let usage = await provider.loadKnowledgeUsage(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart
        )

        // Verify vectorSourceUsed is false
        #expect(usage.vectorSourceUsed == false)
    }

    @Test("Stub provider includes explanatory transparency notice")
    func testStubProviderIncludesTransparencyNotice() async throws {
        let provider = StubKnowledgeSourceProvider()
        let birthDetails = createSampleBirthDetails()
        let natalChart = createSampleNatalChart()

        let usage = await provider.loadKnowledgeUsage(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart
        )

        // Verify notes field contains transparency message
        #expect(usage.notes != nil)
        #expect(usage.notes?.contains("Vector database") == true || usage.notes?.contains("vector store") == true)
    }

    @Test("Stub provider works across all report areas")
    func testStubProviderWorksForAllReportAreas() async throws {
        let provider = StubKnowledgeSourceProvider()
        let birthDetails = createSampleBirthDetails()
        let natalChart = createSampleNatalChart()

        let reportAreas: [ReportArea] = [.general, .career, .relationships, .health, .finances]

        for area in reportAreas {
            let usage = await provider.loadKnowledgeUsage(
                for: area,
                birthDetails: birthDetails,
                natalChart: natalChart
            )

            // Verify stub behavior is consistent across all areas
            #expect(usage.vectorSourceUsed == false, "Area \(area) should have vectorSourceUsed = false")
            #expect(usage.notes != nil, "Area \(area) should have a transparency notice")
            #expect(
                usage.sources == nil || usage.sources?.isEmpty == true,
                "Area \(area) should have no sources"
            )
        }
    }

    @Test("Stub provider notice message is user-friendly")
    func testStubProviderNoticeIsUserFriendly() async throws {
        let provider = StubKnowledgeSourceProvider()
        let birthDetails = createSampleBirthDetails()
        let natalChart = createSampleNatalChart()

        let usage = await provider.loadKnowledgeUsage(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart
        )

        guard let notice = usage.notes else {
            Issue.record("Transparency notice should not be nil")
            return
        }

        // Verify notice is informative and not too technical
        #expect(notice.count > 20, "Notice should be descriptive, got: \(notice)")

        // Verify it doesn't contain alarming language
        let lowerNotice = notice.lowercased()
        #expect(!lowerNotice.contains("error"), "Notice should not contain 'error'")
        #expect(!lowerNotice.contains("failed"), "Notice should not contain 'failed'")
        #expect(!lowerNotice.contains("unavailable"), "Notice should not contain alarming 'unavailable'")
    }

    @Test("Stub provider returns source count of zero")
    func testStubProviderZeroSourceCount() async throws {
        let provider = StubKnowledgeSourceProvider()
        let birthDetails = createSampleBirthDetails()
        let natalChart = createSampleNatalChart()

        let usage = await provider.loadKnowledgeUsage(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart
        )

        let sourceCount = usage.sources?.count ?? 0
        #expect(sourceCount == 0, "Stub provider should return 0 sources")
    }

    @Test("Stub provider does not throw errors")
    func testStubProviderDoesNotThrow() async throws {
        let provider = StubKnowledgeSourceProvider()
        let birthDetails = createSampleBirthDetails()
        let natalChart = createSampleNatalChart()

        // This test verifies that the stub provider never throws
        // If it throws, the test will fail
        _ = await provider.loadKnowledgeUsage(
            for: .general,
            birthDetails: birthDetails,
            natalChart: natalChart
        )

        // If we reach here, no error was thrown
        #expect(true)
    }
}
