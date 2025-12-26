import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var selectedProfile: UserProfile?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showDeleteConfirmation = false
    @Published var profileToDelete: UserProfile?

    private let service: UserProfileService
    private let repositoryContext: RepositoryContext

    init(service: UserProfileService, repositoryContext: RepositoryContext) {
        self.service = service
        self.repositoryContext = repositoryContext
    }

    // MARK: - Load Profiles

    func loadProfiles() {
        profiles = service.getAllProfiles()
        selectedProfile = repositoryContext.activeProfile
    }

    // MARK: - Select Profile

    func selectProfile(_ profile: UserProfile) {
        selectedProfile = profile
        repositoryContext.setActiveProfile(profile)
    }

    // MARK: - Validate Name

    func validateProfileName(_ name: String, excluding profileId: UUID? = nil) -> Bool {
        guard !name.isEmpty && name.count <= 50 else {
            errorMessage = "Profile name must be 1-50 characters"
            return false
        }

        guard service.isProfileNameUnique(name, excluding: profileId) else {
            errorMessage = "A profile with this name already exists"
            return false
        }

        errorMessage = nil
        return true
    }

    // MARK: - Create Profile

    func createProfile(
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String,
        natalChart: NatalChart
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let trimmedName = validatedName(
            name,
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude
        ) else {
            return false
        }

        do {
            let profile = try await service.createProfile(
                name: trimmedName,
                birthDate: birthDate,
                birthTime: birthTime,
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
                timezone: timezone,
                natalChart: natalChart
            )

            // Reload and set as active
            loadProfiles()
            selectProfile(profile)

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Creates a profile without natal chart (for offline/error scenarios)
    /// The chart can be fetched later when network is available
    func createProfileWithoutChart(
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String
    ) -> UserProfile? {
        guard let trimmedName = validatedName(
            name,
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude
        ) else {
            return nil
        }

        do {
            let profile = try service.createProfileWithoutChart(
                name: trimmedName,
                birthDate: birthDate,
                birthTime: birthTime,
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
                timezone: timezone
            )

            // Reload and set as active
            loadProfiles()
            selectProfile(profile)

            return profile
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Attaches a natal chart to an existing profile
    func attachChart(to profile: UserProfile, natalChart: NatalChart) -> Bool {
        do {
            try service.attachChart(to: profile, natalChart: natalChart)
            loadProfiles()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
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
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        guard let trimmedName = validatedName(
            name,
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude,
            excluding: profile.id
        ) else {
            return false
        }

        do {
            try service.updateProfile(
                profile,
                name: trimmedName,
                birthDate: birthDate,
                birthTime: birthTime,
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
                timezone: timezone,
                natalChart: natalChart
            )

            loadProfiles()
            if let refreshed = profiles.first(where: { $0.id == profile.id }) {
                selectProfile(refreshed)
            } else {
                selectProfile(profile)
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Delete Profile

    func requestDeleteProfile(_ profile: UserProfile) {
        profileToDelete = profile
        showDeleteConfirmation = true
    }

    func confirmDeleteProfile() async -> Bool {
        guard let profile = profileToDelete else { return false }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
            showDeleteConfirmation = false
            profileToDelete = nil
        }

        do {
            // If deleting active profile, switch to another
            if selectedProfile?.id == profile.id {
                let otherProfile = profiles.first { $0.id != profile.id }
                if let other = otherProfile {
                    selectProfile(other)
                } else {
                    selectedProfile = nil
                    repositoryContext.activeProfile = nil
                }
            }

            try service.deleteProfile(profile)
            loadProfiles()

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func cancelDelete() {
        showDeleteConfirmation = false
        profileToDelete = nil
    }

    // MARK: - Helper Methods

    private func validatedName(
        _ name: String,
        birthDate: Date,
        latitude: Double,
        longitude: Double,
        excluding profileId: UUID? = nil
    ) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard validateProfileName(trimmedName, excluding: profileId) else {
            return nil
        }

        guard service.validateProfileData(
            name: trimmedName,
            birthDate: birthDate,
            latitude: latitude,
            longitude: longitude
        ) else {
            errorMessage = "Invalid profile data"
            return nil
        }

        return trimmedName
    }

    func getReportCount(for profile: UserProfile) -> Int {
        return service.getReportCount(for: profile)
    }

    func hasReports(_ profile: UserProfile) -> Bool {
        return service.hasReports(profile)
    }

    func deleteConfirmationMessage(for profile: UserProfile) -> String {
        let reportCount = getReportCount(for: profile)
        let hasChart = profile.chart != nil

        var message = "This will delete:\n"
        message += "• Profile: \(profile.name)\n"
        if hasChart {
            message += "• Birth Chart\n"
        }
        if reportCount > 0 {
            message += "• \(reportCount) report\(reportCount == 1 ? "" : "s")\n"
        }
        message += "\nThis action cannot be undone."

        return message
    }
}
