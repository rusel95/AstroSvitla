import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique)
    var id: UUID

    var createdAt: Date
    var lastActiveAt: Date

    // Active user profile (for session management)
    var activeProfileId: UUID?

    @Relationship(deleteRule: .cascade)
    var profiles: [UserProfile]

    init(id: UUID = UUID(), createdAt: Date = Date(), lastActiveAt: Date = Date()) {
        self.id = id
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.activeProfileId = nil
        self.profiles = []
    }

    func updateLastActive() {
        lastActiveAt = Date()
    }

    func setActiveProfile(_ profile: UserProfile) {
        self.activeProfileId = profile.id
        updateLastActive()
    }
}
