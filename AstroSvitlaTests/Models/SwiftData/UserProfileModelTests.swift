import XCTest
import SwiftData
@testable import AstroSvitla

final class UserProfileModelTests: XCTestCase {

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

    // MARK: - Basic CRUD Tests

    func testCreateUserProfileWithValidData() throws {
        // Given
        let profile = UserProfile(
            name: "Test User",
            birthDate: Date(timeIntervalSince1970: 631152000), // 1990-01-01
            birthTime: Date(timeIntervalSince1970: 631152000 + 3600 * 14), // 14:00
            locationName: "Kyiv, Ukraine",
            latitude: 50.4501,
            longitude: 30.5234,
            timezone: "Europe/Kyiv"
        )

        // When
        context.insert(profile)
        try context.save()

        // Then
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(fetchDescriptor)

        XCTAssertEqual(profiles.count, 1, "Should have exactly one profile")
        XCTAssertEqual(profiles.first?.name, "Test User")
        XCTAssertEqual(profiles.first?.locationName, "Kyiv, Ukraine")
        XCTAssertEqual(profiles.first?.latitude, 50.4501, accuracy: 0.0001)
        XCTAssertEqual(profiles.first?.longitude, 30.5234, accuracy: 0.0001)
    }

    func testUserProfileWithInvalidDatesBefor1900() throws {
        // Given - date before 1900
        let oldDate = Date(timeIntervalSince1970: -2208988800) // 1900-01-01 minus some years

        let profile = UserProfile(
            name: "Ancient Person",
            birthDate: oldDate,
            birthTime: Date(),
            locationName: "Old City",
            latitude: 40.0,
            longitude: 40.0,
            timezone: "UTC"
        )

        // When
        context.insert(profile)
        try context.save()

        // Then - This should pass data model validation
        // Business logic validation should happen in ViewModel
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(fetchDescriptor)
        XCTAssertEqual(profiles.count, 1, "Model should allow any date, validation is in ViewModel")
    }

    func testUserProfileWithInvalidDatesAfter2100() throws {
        // Given - date after 2100
        let futureDate = Date(timeIntervalSince1970: 4102444800) // 2100+

        let profile = UserProfile(
            name: "Future Person",
            birthDate: futureDate,
            birthTime: Date(),
            locationName: "Future City",
            latitude: 40.0,
            longitude: 40.0,
            timezone: "UTC"
        )

        // When
        context.insert(profile)
        try context.save()

        // Then - Model allows it, ViewModel should validate
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(fetchDescriptor)
        XCTAssertEqual(profiles.count, 1, "Model should allow any date, validation is in ViewModel")
    }

    func testUserProfileWithInvalidCoordinates() throws {
        // Given - invalid latitude/longitude
        let profile1 = UserProfile(
            name: "Invalid Lat",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Invalid",
            latitude: 95.0, // Invalid: > 90
            longitude: 0.0,
            timezone: "UTC"
        )

        let profile2 = UserProfile(
            name: "Invalid Long",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Invalid",
            latitude: 0.0,
            longitude: 200.0, // Invalid: > 180
            timezone: "UTC"
        )

        // When
        context.insert(profile1)
        context.insert(profile2)
        try context.save()

        // Then - Model allows it, ViewModel should validate
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(fetchDescriptor)
        XCTAssertEqual(profiles.count, 2, "Model should allow any coordinates, validation is in ViewModel")
    }

    func testBirthDateTimeComputedProperty() throws {
        // Given
        let birthDate = Date(timeIntervalSince1970: 631152000) // 1990-01-01
        let birthTime = Date(timeIntervalSince1970: 631152000 + 3600 * 14) // 14:00

        let profile = UserProfile(
            name: "Test",
            birthDate: birthDate,
            birthTime: birthTime,
            locationName: "Test Location",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )

        // When
        let birthDateTime = profile.birthDateTime

        // Then
        XCTAssertFalse(birthDateTime.isEmpty, "Birth date time should not be empty")
        XCTAssertTrue(birthDateTime.contains("1990") || birthDateTime.contains("90"), "Should contain year")
        // Note: Exact format depends on locale, so we just check it's not empty
    }

    func testUserProfileNameLengthValidation() throws {
        // Given - very long name (> 50 characters)
        let longName = String(repeating: "A", count: 100)

        let profile = UserProfile(
            name: longName,
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )

        // When
        context.insert(profile)
        try context.save()

        // Then - Model allows it, ViewModel should validate
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(fetchDescriptor)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.name.count, 100, "Model should store long names, ViewModel validates")
    }

    func testUserProfileNameEmptyValidation() throws {
        // Given - empty name
        let profile = UserProfile(
            name: "",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )

        // When
        context.insert(profile)
        try context.save()

        // Then - Model allows it, ViewModel should validate
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(fetchDescriptor)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertTrue(profiles.first?.name.isEmpty ?? false, "Model should allow empty names, ViewModel validates")
    }

    func testUserProfileMetadataFields() throws {
        // Given
        let beforeCreation = Date()

        let profile = UserProfile(
            name: "Test",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )

        // When
        context.insert(profile)
        try context.save()

        let afterCreation = Date()

        // Then
        XCTAssertNotNil(profile.createdAt)
        XCTAssertNotNil(profile.updatedAt)
        XCTAssertGreaterThanOrEqual(profile.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(profile.createdAt, afterCreation)
        XCTAssertEqual(profile.createdAt.timeIntervalSince1970,
                      profile.updatedAt.timeIntervalSince1970,
                      accuracy: 1.0,
                      "CreatedAt and UpdatedAt should be very close on creation")
    }
}
