import CoreLocation
import Foundation
import SwiftData
@testable import AstroSvitla
import Testing

private final class MockNetworkMonitor {
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }
}

private struct OfflineCacheResolver {
    let networkMonitor: MockNetworkMonitor
    let cacheService: ChartCacheService

    func cachedChart(for birthDetails: BirthDetails) throws -> NatalChart? {
        guard networkMonitor.isConnected == false else {
            return nil
        }

        return try cacheService.findChart(birthData: birthDetails)
    }
}

struct ModelContainerSharedTests {

    @MainActor
    @Test
    func testSharedContainerIncludesDefaultUser() throws {
        let container = try ModelContainer.astroSvitlaShared(inMemory: true)
        let context = container.mainContext

        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)

        #expect(users.count == 1)
        #expect(users.first?.profiles.isEmpty == true)
    }

    @MainActor
    @Test
    func testSharedContainerHasAllModels() throws {
        let container = try ModelContainer.astroSvitlaShared(inMemory: true)
        let context = container.mainContext

        let profile = UserProfile(
            name: "Sample",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Kyiv, Ukraine",
            latitude: 50.4501,
            longitude: 30.5234,
            timezone: "Europe/Kyiv"
        )

        let chart = BirthChart(chartDataJSON: "{}")
        chart.profile = profile

        context.insert(profile)
        context.insert(chart)
        try context.save()

        let descriptor = FetchDescriptor<BirthChart>()
        let charts = try context.fetch(descriptor)

        #expect(charts.count == 1)
    }

    @MainActor
    @Test("Chart cache service serves cached data when offline")
    func testChartCacheServiceReturnsCachedChartWhenOffline() throws {
        let container = try ModelContainer.astroSvitlaShared(inMemory: true)
        let cacheService = ChartCacheService(context: container.mainContext)

        let birthDetails = BirthDetails(
            name: "Offline Tester",
            birthDate: Date(timeIntervalSince1970: 1_700_000_000),
            birthTime: Date(timeIntervalSince1970: 1_700_003_600),
            location: "Kyiv, Ukraine",
            timeZone: TimeZone(identifier: "Europe/Kyiv") ?? .current,
            coordinate: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
        )

        let generatedAt = Date(timeIntervalSince1970: 1_700_086_400)
        let planets: [Planet] = [
            Planet(
                name: .sun,
                longitude: 120,
                latitude: 0,
                sign: .cancer,
                house: 10,
                isRetrograde: false,
                speed: 1.0
            ),
            Planet(
                name: .moon,
                longitude: 45,
                latitude: 0,
                sign: .taurus,
                house: 2,
                isRetrograde: false,
                speed: 13.0
            )
        ]

        let houses: [House] = (1...12).map { index in
            House(
                number: index,
                cusp: Double(index - 1) * 30,
                sign: ZodiacSign.allCases[(index - 1) % ZodiacSign.allCases.count]
            )
        }

        let aspects: [Aspect] = [
            Aspect(
                planet1: .sun,
                planet2: .moon,
                type: .trine,
                orb: 3.0,
                isApplying: true
            )
        ]

        var natalChart = NatalChart(
            birthDate: birthDetails.birthDate,
            birthTime: birthDetails.birthTime,
            latitude: birthDetails.coordinate?.latitude ?? 0,
            longitude: birthDetails.coordinate?.longitude ?? 0,
            locationName: birthDetails.location,
            planets: planets,
            houses: houses,
            aspects: aspects,
            houseRulers: [],
            ascendant: 18.0,
            midheaven: 212.0,
            calculatedAt: generatedAt
        )
        natalChart.imageFileID = "cached-image"
        natalChart.imageFormat = "svg"

        try cacheService.saveChart(natalChart, birthDetails: birthDetails, imageFileID: natalChart.imageFileID, imageFormat: natalChart.imageFormat)

        let offlineMonitor = MockNetworkMonitor(isConnected: false)
        let offlineResolver = OfflineCacheResolver(networkMonitor: offlineMonitor, cacheService: cacheService)
        let cachedChart = try offlineResolver.cachedChart(for: birthDetails)

        #expect(offlineMonitor.isConnected == false)
        #expect(cachedChart != nil)
        #expect(cachedChart?.ascendant == natalChart.ascendant)
        #expect(cachedChart?.planets.count == natalChart.planets.count)
        #expect(cachedChart?.calculatedAt == generatedAt)
        #expect(cachedChart?.imageFileID == natalChart.imageFileID)
        #expect(cachedChart?.imageFormat == natalChart.imageFormat)

        let onlineMonitor = MockNetworkMonitor(isConnected: true)
        let onlineResolver = OfflineCacheResolver(networkMonitor: onlineMonitor, cacheService: cacheService)
        let onlineChart = try onlineResolver.cachedChart(for: birthDetails)

        #expect(onlineChart == nil)
    }
}
