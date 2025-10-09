import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique)
    var id: UUID

    // User-facing info
    var name: String // "Me", "Partner", "Mom", etc. - MUST be unique per device

    // Birth data
    var birthDate: Date
    var birthTime: Date
    var locationName: String // "Kyiv, Ukraine"
    var latitude: Double
    var longitude: Double
    var timezone: String // "Europe/Kyiv"

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(inverse: \User.profiles)
    var user: User?

    @Relationship(deleteRule: .cascade)
    var chart: BirthChart? // 1:1 relationship

    @Relationship(deleteRule: .cascade)
    var reports: [ReportPurchase]

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
        self.createdAt = Date()
        self.updatedAt = Date()
        self.reports = []
    }

    // Computed properties
    var birthDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: birthDate) + " " + formatter.string(from: birthTime)
    }
}
