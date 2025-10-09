import XCTest
import SwiftData
@testable import AstroSvitla

final class UserModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()

        let schema = Schema([
            User.self,
            UserProfile.self,
            BirthChart.self,
            ReportPurchase.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)
        } catch {
            fatalError("Failed to create test container: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - setActiveProfile Tests

    func testSetActiveProfileUpdatesActiveProfileId() throws {
        // Given
        let user = User()
        context.insert(user)

        let profile = UserProfile(
            name: "Test Profile",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )
        context.insert(profile)
        profile.user = user

        try context.save()

        // When
        user.setActiveProfile(profile)
        try context.save()

        // Then
        XCTAssertNotNil(user.activeProfileId)
        XCTAssertEqual(user.activeProfileId, profile.id)
    }

    func testSetActiveProfileUpdatesLastActiveAt() throws {
        // Given
        let user = User()
        context.insert(user)

        let profile = UserProfile(
            name: "Test",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )
        context.insert(profile)
        profile.user = user

        try context.save()

        let beforeUpdate = user.lastActiveAt

        // Wait a tiny bit to ensure time difference
        Thread.sleep(forTimeInterval: 0.1)

        // When
        user.setActiveProfile(profile)

        // Then
        XCTAssertGreaterThan(user.lastActiveAt, beforeUpdate)
    }

    func testActiveProfileIdPersistsAcrossContextSaves() throws {
        // Given
        let user = User()
        context.insert(user)

        let profile = UserProfile(
            name: "Test",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )
        context.insert(profile)
        profile.user = user

        user.setActiveProfile(profile)
        try context.save()

        let savedProfileId = user.activeProfileId

        // When - fetch user again in new context
        let userId = user.id
        let fetchDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userId }
        )
        let fetchedUsers = try context.fetch(fetchDescriptor)
        let fetchedUser = try XCTUnwrap(fetchedUsers.first)

        // Then
        XCTAssertEqual(fetchedUser.activeProfileId, savedProfileId)
        XCTAssertEqual(fetchedUser.activeProfileId, profile.id)
    }

    func testUserWithNoActiveProfile() throws {
        // Given
        let user = User()
        context.insert(user)
        try context.save()

        // Then
        XCTAssertNil(user.activeProfileId, "New user should have no active profile")
    }
}
