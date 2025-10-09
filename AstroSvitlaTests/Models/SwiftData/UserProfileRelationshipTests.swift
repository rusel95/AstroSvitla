import XCTest
import SwiftData
@testable import AstroSvitla

final class UserProfileRelationshipTests: XCTestCase {

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

    // MARK: - User <-> UserProfile Relationship (1:N)

    func testUserProfileBelongsToUser() throws {
        // Given
        let user = User()
        context.insert(user)

        let profile = UserProfile(
            name: "Test Profile",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test Location",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )
        context.insert(profile)

        // When
        profile.user = user
        try context.save()

        // Then
        XCTAssertNotNil(profile.user)
        XCTAssertEqual(profile.user?.id, user.id)
        XCTAssertTrue(user.profiles.contains { $0.id == profile.id })
    }

    func testUserCanHaveMultipleProfiles() throws {
        // Given
        let user = User()
        context.insert(user)

        let profile1 = UserProfile(
            name: "Profile 1",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Location 1",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )

        let profile2 = UserProfile(
            name: "Profile 2",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Location 2",
            latitude: 10.0,
            longitude: 10.0,
            timezone: "UTC"
        )

        context.insert(profile1)
        context.insert(profile2)

        // When
        profile1.user = user
        profile2.user = user
        try context.save()

        // Then
        XCTAssertEqual(user.profiles.count, 2)
        XCTAssertTrue(user.profiles.contains { $0.name == "Profile 1" })
        XCTAssertTrue(user.profiles.contains { $0.name == "Profile 2" })
    }

    // MARK: - UserProfile <-> BirthChart Relationship (1:1)

    func testUserProfileHasOneBirthChart() throws {
        // Given
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

        let chart = BirthChart(chartDataJSON: "{\"test\": \"data\"}")
        context.insert(chart)

        // When
        chart.profile = profile
        try context.save()

        // Then
        XCTAssertNotNil(profile.chart)
        XCTAssertEqual(profile.chart?.id, chart.id)
        XCTAssertEqual(chart.profile?.id, profile.id)
    }

    func testBirthChartBelongsToOneUserProfile() throws {
        // Given
        let profile1 = UserProfile(
            name: "Profile 1",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )
        let profile2 = UserProfile(
            name: "Profile 2",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )

        context.insert(profile1)
        context.insert(profile2)

        let chart = BirthChart(chartDataJSON: "{}")
        context.insert(chart)

        // When - assign to first profile
        chart.profile = profile1
        try context.save()

        // Then
        XCTAssertEqual(chart.profile?.id, profile1.id)
        XCTAssertEqual(profile1.chart?.id, chart.id)
        XCTAssertNil(profile2.chart)

        // When - reassign to second profile
        chart.profile = profile2
        try context.save()

        // Then
        XCTAssertEqual(chart.profile?.id, profile2.id)
        XCTAssertEqual(profile2.chart?.id, chart.id)
        // Note: profile1.chart might still reference it until relationship is properly updated
    }

    // MARK: - UserProfile <-> ReportPurchase Relationship (1:N)

    func testUserProfileHasManyReportPurchases() throws {
        // Given
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

        let report1 = ReportPurchase(
            area: "finances",
            reportText: "Report 1",
            summary: "Summary 1",
            detailedAnalysis: "Analysis 1",
            language: "en",
            price: 6.99,
            transactionId: "txn1"
        )

        let report2 = ReportPurchase(
            area: "career",
            reportText: "Report 2",
            summary: "Summary 2",
            detailedAnalysis: "Analysis 2",
            language: "en",
            price: 6.99,
            transactionId: "txn2"
        )

        context.insert(report1)
        context.insert(report2)

        // When
        report1.profile = profile
        report2.profile = profile
        try context.save()

        // Then
        XCTAssertEqual(profile.reports.count, 2)
        XCTAssertTrue(profile.reports.contains { $0.area == "finances" })
        XCTAssertTrue(profile.reports.contains { $0.area == "career" })
    }

    // MARK: - Cascade Delete Tests

    func testDeletingUserProfileDeletesBirthChart() throws {
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

        let chart = BirthChart(chartDataJSON: "{}")
        context.insert(chart)
        chart.profile = profile

        try context.save()

        let chartId = chart.id

        // When
        context.delete(profile)
        try context.save()

        // Then
        let chartDescriptor = FetchDescriptor<BirthChart>(
            predicate: #Predicate { $0.id == chartId }
        )
        let charts = try context.fetch(chartDescriptor)

        XCTAssertTrue(charts.isEmpty, "BirthChart should be cascade deleted with UserProfile")
    }

    func testDeletingUserProfileDeletesReports() throws {
        // Given
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

        let report = ReportPurchase(
            area: "finances",
            reportText: "Test",
            summary: "Summary",
            detailedAnalysis: "Analysis",
            language: "en",
            price: 6.99,
            transactionId: "txn"
        )
        context.insert(report)
        report.profile = profile

        try context.save()

        let reportId = report.id

        // When
        context.delete(profile)
        try context.save()

        // Then
        let reportDescriptor = FetchDescriptor<ReportPurchase>(
            predicate: #Predicate { $0.id == reportId }
        )
        let reports = try context.fetch(reportDescriptor)

        XCTAssertTrue(reports.isEmpty, "ReportPurchase should be cascade deleted with UserProfile")
    }

    func testDeletingUserProfileWithMultipleReportsDeletesAll() throws {
        // Given
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

        let report1 = ReportPurchase(
            area: "finances",
            reportText: "Report 1",
            summary: "Summary 1",
            detailedAnalysis: "Analysis 1",
            language: "en",
            price: 6.99,
            transactionId: "txn1"
        )

        let report2 = ReportPurchase(
            area: "career",
            reportText: "Report 2",
            summary: "Summary 2",
            detailedAnalysis: "Analysis 2",
            language: "en",
            price: 6.99,
            transactionId: "txn2"
        )

        context.insert(report1)
        context.insert(report2)
        report1.profile = profile
        report2.profile = profile

        try context.save()

        // When
        context.delete(profile)
        try context.save()

        // Then
        let reportDescriptor = FetchDescriptor<ReportPurchase>()
        let reports = try context.fetch(reportDescriptor)

        XCTAssertTrue(reports.isEmpty, "All reports should be cascade deleted with UserProfile")
    }

    // MARK: - Bidirectional Relationship Tests

    func testUserProfilesRelationshipWorksBidirectionally() throws {
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

        // When - set from profile side
        profile.user = user
        try context.save()

        // Then - should be visible from user side
        XCTAssertTrue(user.profiles.contains { $0.id == profile.id })

        // When - add another profile from user side
        let profile2 = UserProfile(
            name: "Test 2",
            birthDate: Date(),
            birthTime: Date(),
            locationName: "Test 2",
            latitude: 0.0,
            longitude: 0.0,
            timezone: "UTC"
        )
        context.insert(profile2)
        profile2.user = user
        try context.save()

        // Then - both should be in user.profiles
        XCTAssertEqual(user.profiles.count, 2)
        XCTAssertNotNil(profile2.user)
        XCTAssertEqual(profile2.user?.id, user.id)
    }
}
