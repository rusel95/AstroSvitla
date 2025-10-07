import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique)
    var id: UUID

    var createdAt: Date
    var lastActiveAt: Date

    @Relationship(deleteRule: .cascade)
    var charts: [BirthChart]

    @Relationship(deleteRule: .cascade)
    var purchases: [ReportPurchase]

    init(id: UUID = UUID(), createdAt: Date = Date(), lastActiveAt: Date = Date()) {
        self.id = id
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.charts = []
        self.purchases = []
    }

    func updateLastActive() {
        lastActiveAt = Date()
    }
}
