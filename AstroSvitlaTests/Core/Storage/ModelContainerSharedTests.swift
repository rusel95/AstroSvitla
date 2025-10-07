import Foundation
import SwiftData
@testable import AstroSvitla
import Testing

struct ModelContainerSharedTests {

    @MainActor
    @Test
    func testSharedContainerIncludesDefaultUser() throws {
        let container = try ModelContainer.astroSvitlaShared(inMemory: true)
        let context = container.mainContext

        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)

        #expect(users.count == 1)
        #expect(users.first?.charts.isEmpty == true)
        #expect(users.first?.purchases.isEmpty == true)
    }

    @MainActor
    @Test
    func testSharedContainerHasAllModels() throws {
        let container = try ModelContainer.astroSvitlaShared(inMemory: true)
        let context = container.mainContext

        let chart = BirthChart(
            name: "Sample",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Kyiv, Ukraine",
            latitude: 50.4501,
            longitude: 30.5234,
            timezone: "Europe/Kyiv"
        )

        context.insert(chart)
        try context.save()

        let descriptor = FetchDescriptor<BirthChart>()
        let charts = try context.fetch(descriptor)

        #expect(charts.count == 1)
    }
}
