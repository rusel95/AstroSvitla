import CoreLocation
import Foundation
import SwiftData
import Testing
@testable import AstroSvitla

@MainActor
struct ChartCacheServiceTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            CachedNatalChart.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeService(using container: ModelContainer) -> ChartCacheService {
        ChartCacheService(context: container.mainContext)
    }

    private func makeChartInputs(calculatedAt: Date = Date()) -> (BirthDetails, NatalChart) {
        let birthDetails = BirthDetails(
            name: "Ada Lovelace",
            birthDate: Date(timeIntervalSince1970: 0),
            birthTime: Date(timeIntervalSince1970: 3600),
            location: "London, UK",
            timeZone: TimeZone(identifier: "Europe/London") ?? .current,
            coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        )

        let planets: [Planet] = [
            Planet(
                name: .sun,
                longitude: 120.0,
                latitude: 0,
                sign: .cancer,
                house: 10,
                isRetrograde: false,
                speed: 1.02
            ),
            Planet(
                name: .moon,
                longitude: 45.0,
                latitude: 0,
                sign: .taurus,
                house: 3,
                isRetrograde: false,
                speed: 13.2
            )
        ]

        let houses: [House] = (1...12).map { index in
            House(
                number: index,
                cusp: Double(index - 1) * 30.0,
                sign: ZodiacSign.allCases[index % ZodiacSign.allCases.count]
            )
        }

        let aspects: [Aspect] = [
            Aspect(
                planet1: .sun,
                planet2: .moon,
                type: .sextile,
                orb: 2.0,
                isApplying: true
            )
        ]

        let chart = NatalChart(
            birthDate: birthDetails.birthDate,
            birthTime: birthDetails.birthTime,
            latitude: birthDetails.coordinate?.latitude ?? 0,
            longitude: birthDetails.coordinate?.longitude ?? 0,
            locationName: birthDetails.location,
            planets: planets,
            houses: houses,
            aspects: aspects,
            ascendant: 15.0,
            midheaven: 275.0,
            calculatedAt: calculatedAt
        )

        return (birthDetails, chart)
    }

    private func fetchCachedCharts(from context: ModelContext) throws -> [CachedNatalChart] {
        let descriptor = FetchDescriptor<CachedNatalChart>()
        return try context.fetch(descriptor)
    }

    // MARK: - Tests

    @Test("Saving then loading by id returns the same natal chart data")
    func testSaveAndLoadChart() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let service = makeService(using: container)

        let (details, originalChart) = makeChartInputs()

        try service.saveChart(originalChart, birthDetails: details)

        let cached = try fetchCachedCharts(from: context)
        #expect(cached.count == 1)

        guard let cachedChart = cached.first else {
            Issue.record("Expected cached chart to exist")
            return
        }

        let loaded = try service.loadChart(id: cachedChart.id)

        #expect(loaded != nil)
        #expect(loaded?.birthDate == originalChart.birthDate)
        #expect(loaded?.birthTime == originalChart.birthTime)
        #expect(loaded?.locationName == originalChart.locationName)
        #expect(loaded?.planets.count == originalChart.planets.count)
        #expect(loaded?.houses.count == originalChart.houses.count)
        #expect(loaded?.aspects.count == originalChart.aspects.count)
        #expect(loaded?.ascendant == originalChart.ascendant)
        #expect(loaded?.midheaven == originalChart.midheaven)
    }

    @Test("findChart returns cached chart for matching birth details")
    func testFindChartByBirthDetails() throws {
        let container = try makeContainer()
        let service = makeService(using: container)
        let (details, chart) = makeChartInputs()

        try service.saveChart(chart, birthDetails: details)

        let found = try service.findChart(birthData: details)

        #expect(found != nil)
        #expect(found?.locationName == chart.locationName)
        #expect(found?.ascendant == chart.ascendant)
    }

    @Test("isCacheStale detects charts older than the retention window")
    func testIsCacheStaleDetection() throws {
        let container = try makeContainer()
        let service = makeService(using: container)
        let context = container.mainContext

        let referenceDate = Date()
        let staleGeneratedAt = referenceDate.addingTimeInterval(-31 * 24 * 60 * 60)
        let freshGeneratedAt = referenceDate.addingTimeInterval(-5 * 24 * 60 * 60)

        let stale = CachedNatalChart(
            birthDataJSON: Data(),
            planetsJSON: Data(),
            housesJSON: Data(),
            aspectsJSON: Data(),
            ascendant: 0,
            midheaven: 0,
            houseSystem: "placidus",
            generatedAt: staleGeneratedAt
        )

        let fresh = CachedNatalChart(
            birthDataJSON: Data(),
            planetsJSON: Data(),
            housesJSON: Data(),
            aspectsJSON: Data(),
            ascendant: 0,
            midheaven: 0,
            houseSystem: "placidus",
            generatedAt: freshGeneratedAt
        )

        context.insert(stale)
        context.insert(fresh)

        #expect(service.isCacheStale(stale, referenceDate: referenceDate))
        #expect(service.isCacheStale(fresh, referenceDate: referenceDate) == false)
    }

    @Test("clearOldCharts removes entries older than 30 days")
    func testClearOldChartsRemovesStaleEntries() throws {
        let container = try makeContainer()
        let service = makeService(using: container)
        let context = container.mainContext

        let now = Date()
        let staleDate = now.addingTimeInterval(-35 * 24 * 60 * 60)
        let recentDate = now.addingTimeInterval(-10 * 24 * 60 * 60)

        let stale = CachedNatalChart(
            birthDataJSON: Data(),
            planetsJSON: Data(),
            housesJSON: Data(),
            aspectsJSON: Data(),
            ascendant: 0,
            midheaven: 0,
            houseSystem: "placidus",
            generatedAt: staleDate
        )

        let recent = CachedNatalChart(
            birthDataJSON: Data(),
            planetsJSON: Data(),
            housesJSON: Data(),
            aspectsJSON: Data(),
            ascendant: 0,
            midheaven: 0,
            houseSystem: "placidus",
            generatedAt: recentDate
        )

        context.insert(stale)
        context.insert(recent)
        try context.save()

        try service.clearOldCharts()

        let remaining = try fetchCachedCharts(from: context)
        #expect(remaining.count == 1)
        #expect(remaining.first?.generatedAt == recentDate)
    }
}
