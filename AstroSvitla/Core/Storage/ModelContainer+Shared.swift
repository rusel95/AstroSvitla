import SwiftData

extension ModelContainer {
    static func astroSvitlaShared(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            User.self,
            BirthChart.self,
            ReportPurchase.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        try ensureDefaultUser(in: container.mainContext)

        return container
    }

    private static func ensureDefaultUser(in context: ModelContext) throws {
        var fetch = FetchDescriptor<User>()
        fetch.fetchLimit = 1

        if let existing = try context.fetch(fetch).first {
            existing.updateLastActive()
            try context.save()
            return
        }

        let user = User()
        context.insert(user)
        try context.save()
    }
}
