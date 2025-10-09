import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class RepositoryContext: ObservableObject {
    @Published var activeProfile: UserProfile?

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func setActiveProfile(_ profile: UserProfile) {
        // Update User.activeProfileId
        if let user = fetchDeviceOwner() {
            user.setActiveProfile(profile)
            try? context.save()
        }

        // Update published property
        self.activeProfile = profile
    }

    func loadActiveProfile() {
        guard let user = fetchDeviceOwner(),
              let activeId = user.activeProfileId else {
            return
        }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == activeId }
        )
        self.activeProfile = try? context.fetch(descriptor).first
    }

    func fetchDeviceOwner() -> User? {
        let descriptor = FetchDescriptor<User>()
        return try? context.fetch(descriptor).first
    }

    func createDefaultUserIfNeeded() {
        guard fetchDeviceOwner() == nil else { return }

        let newUser = User()
        context.insert(newUser)
        try? context.save()
    }
}
