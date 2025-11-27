import Foundation
import SwiftData
import CoreLocation

enum UserProfileError: LocalizedError {
    case duplicateName
    case chartCalculationFailed
    case invalidData
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .duplicateName:
            return "A profile with this name already exists"
        case .chartCalculationFailed:
            return "Failed to calculate natal chart"
        case .invalidData:
            return "Invalid profile data"
        case .profileNotFound:
            return "Profile not found"
        }
    }
}

@MainActor
class UserProfileService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create Profile

    /// Creates a profile with birth data and natal chart
    func createProfile(
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String,
        natalChart: NatalChart
    ) async throws -> UserProfile {
        // Validate name uniqueness
        guard isProfileNameUnique(name) else {
            throw UserProfileError.duplicateName
        }

        // Create profile
        let profile = UserProfile(
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )

        context.insert(profile)

        // Create and link birth chart
        let chartJSON = BirthChart.encodedChartJSON(from: natalChart) ?? ""
        let birthChart = BirthChart(chartDataJSON: chartJSON)
        birthChart.profile = profile
        context.insert(birthChart)

        // Link to device owner
        if let user = fetchDeviceOwner() {
            profile.user = user
        }

        try context.save()

        return profile
    }

    /// Creates a profile with birth data only (without natal chart - for offline/error cases)
    func createProfileWithoutChart(
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String
    ) throws -> UserProfile {
        // Validate name uniqueness
        guard isProfileNameUnique(name) else {
            throw UserProfileError.duplicateName
        }

        // Create profile
        let profile = UserProfile(
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )

        context.insert(profile)

        // Link to device owner
        if let user = fetchDeviceOwner() {
            profile.user = user
        }

        try context.save()

        return profile
    }

    /// Adds or updates natal chart for an existing profile
    func attachChart(to profile: UserProfile, natalChart: NatalChart) throws {
        let chartJSON = BirthChart.encodedChartJSON(from: natalChart) ?? ""
        
        if let existingChart = profile.chart {
            existingChart.updateChartData(chartJSON)
        } else {
            let birthChart = BirthChart(chartDataJSON: chartJSON)
            birthChart.profile = profile
            context.insert(birthChart)
        }
        
        profile.updatedAt = Date()
        try context.save()
    }

    // MARK: - Update Profile

    func updateProfile(
        _ profile: UserProfile,
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String,
        natalChart: NatalChart?
    ) throws {
        // Validate name uniqueness (excluding current profile)
        if profile.name != name {
            guard isProfileNameUnique(name, excluding: profile.id) else {
                throw UserProfileError.duplicateName
            }
        }

        profile.name = name
        profile.birthDate = birthDate
        profile.birthTime = birthTime
        profile.locationName = locationName
        profile.latitude = latitude
        profile.longitude = longitude
        profile.timezone = timezone
        profile.updatedAt = Date()

        if let natalChart {
            let chartJSON = BirthChart.encodedChartJSON(from: natalChart) ?? ""
            if let existingChart = profile.chart {
                existingChart.updateChartData(chartJSON)
            } else {
                let newChart = BirthChart(chartDataJSON: chartJSON)
                newChart.profile = profile
                context.insert(newChart)
            }
        }

        try context.save()
    }

    // MARK: - Delete Profile

    func deleteProfile(_ profile: UserProfile) throws {
        context.delete(profile)
        try context.save()
    }

    // MARK: - Fetch Operations

    func getActiveProfile() -> UserProfile? {
        guard let user = fetchDeviceOwner(),
              let activeId = user.activeProfileId else {
            return nil
        }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == activeId }
        )
        return try? context.fetch(descriptor).first
    }

    func getAllProfiles() -> [UserProfile] {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getProfile(by id: UUID) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == id }
        )
        return try? context.fetch(descriptor).first
    }

    // MARK: - Validation

    func isProfileNameUnique(_ name: String, excluding profileId: UUID? = nil) -> Bool {
        let descriptor: FetchDescriptor<UserProfile>

        if let excludeId = profileId {
            descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { profile in
                    profile.name == name && profile.id != excludeId
                }
            )
        } else {
            descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { $0.name == name }
            )
        }

        let results = try? context.fetch(descriptor)
        return results?.isEmpty ?? true
    }

    func validateProfileData(
        name: String,
        birthDate: Date,
        latitude: Double,
        longitude: Double
    ) -> Bool {
        // Name validation
        guard !name.isEmpty && name.count <= 50 else { return false }

        // Date validation (1900-2100)
        let calendar = Calendar.current
        let year = calendar.component(.year, from: birthDate)
        guard year >= 1900 && year <= 2100 else { return false }

        // Coordinate validation
        guard latitude >= -90 && latitude <= 90 else { return false }
        guard longitude >= -180 && longitude <= 180 else { return false }

        return true
    }

    // MARK: - Report Statistics

    func getReportCount(for profile: UserProfile) -> Int {
        return profile.reports.count
    }

    func hasReports(_ profile: UserProfile) -> Bool {
        return !profile.reports.isEmpty
    }

    /// Checks if a specific report area has already been purchased for this profile
    func hasReport(for area: ReportArea, profile: UserProfile) -> Bool {
        return profile.reports.contains { $0.isForArea(area) }
    }

    /// Returns the existing report for a specific area if it exists
    func getExistingReport(for area: ReportArea, profile: UserProfile) -> ReportPurchase? {
        return profile.reports.first { $0.isForArea(area) }
    }

    /// Returns all purchased areas for a profile
    func purchasedAreas(for profile: UserProfile) -> Set<ReportArea> {
        Set(profile.reports.compactMap { ReportArea(rawValue: $0.area) })
    }

    // MARK: - Helper Methods

    private func fetchDeviceOwner() -> User? {
        let descriptor = FetchDescriptor<User>()
        return try? context.fetch(descriptor).first
    }
}
