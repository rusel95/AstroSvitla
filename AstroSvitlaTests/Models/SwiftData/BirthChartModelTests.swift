import Foundation
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
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    @Test
    func testBirthChartCreationPersistsProperties() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let birthDate = ISO8601DateFormatter().date(from: "1990-04-15T00:00:00Z")!
        let birthTime = ISO8601DateFormatter().date(from: "1990-04-15T14:30:00Z")!

        let chart = BirthChart(
            name: "Primary",
            birthDate: birthDate,
            birthTime: birthTime,
            locationName: "Kyiv, Ukraine",
            latitude: 50.4501,
            longitude: 30.5234,
            timezone: "Europe/Kyiv"
        )

        context.insert(chart)
        try context.save()

        #expect(chart.name == "Primary")
        #expect(chart.latitude == 50.4501)
        #expect(chart.longitude == 30.5234)
        #expect(chart.chartDataJSON.isEmpty)
        #expect(!chart.birthDateTime.isEmpty)
    }

    @MainActor
    @Test
    func testUpdateChartDataUpdatesTimestamp() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let chart = BirthChart(
            name: "Primary",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Kyiv, Ukraine",
            latitude: 50.4501,
            longitude: 30.5234,
            timezone: "Europe/Kyiv"
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
}
