import Foundation
import CoreLocation
import SwiftData
@testable import AstroSvitla
import Testing

struct BirthChartModelTests {

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            BirthChart.self,
            ReportPurchase.self,
            UserProfile.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    @Test
    func testBirthChartInitializationDefaults() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let chart = BirthChart()

        context.insert(chart)
        try context.save()

        #expect(chart.chartDataJSON.isEmpty)
        #expect(chart.createdAt <= chart.updatedAt)
        #expect(chart.profile == nil)
    }

    @MainActor
    @Test
    func testUpdateChartDataUpdatesTimestamp() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let chart = BirthChart(
            chartDataJSON: ""
        )

        context.insert(chart)
        try context.save()

        let originalUpdatedAt = chart.updatedAt
        usleep(1_000)

        chart.updateChartData("{\"planets\":[]}")
        try context.save()

        #expect(chart.chartDataJSON == "{\"planets\":[]}")
        #expect(chart.updatedAt >= originalUpdatedAt)
    }

    @MainActor
    @Test
    func testMakeBirthDetailsUsesLinkedProfile() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let profile = UserProfile(
            name: "Sample",
            birthDate: Date(timeIntervalSince1970: 631152000),
            birthTime: Date(timeIntervalSince1970: 631152000 + 3600),
            locationName: "Kyiv, Ukraine",
            latitude: 50.4501,
            longitude: 30.5234,
            timezone: "Europe/Kyiv"
        )

        let chart = BirthChart()
        chart.profile = profile

        context.insert(profile)
        context.insert(chart)
        try context.save()

        let details = chart.makeBirthDetails()

        #expect(details?.name == "Sample")
        #expect(details?.location == "Kyiv, Ukraine")
        #expect(details?.coordinate?.latitude == 50.4501)
        #expect(details?.coordinate?.longitude == 30.5234)
    }
}
