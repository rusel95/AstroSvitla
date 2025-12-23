import SwiftUI
import SwiftData

struct UserProfileListView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            Group {
                if viewModel.profiles.isEmpty {
                    emptyStateView
                } else {
                    profileListView
                }
            }
            .navigationTitle(String(localized: "profile.manage.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.done")) {
                        dismiss()
                    }
                }

                // NOTE: Profile creation now happens inline on Home tab
                // Remove the "Create Profile" button from Settings for simplified UX
            }
            .alert(String(localized: "profile.delete.title"), isPresented: $viewModel.showDeleteConfirmation) {
                Button(String(localized: "action.cancel"), role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button(String(localized: "action.delete"), role: .destructive) {
                    Task {
                        await viewModel.confirmDeleteProfile()
                    }
                }
            } message: {
                if let profile = viewModel.profileToDelete {
                    Text(viewModel.deleteConfirmationMessage(for: profile))
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .onAppear {
                viewModel.loadProfiles()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text(String(localized: "profile.empty.none"))
                .font(.title2)
                .fontWeight(.semibold)

            Text(String(localized: "profile.empty.create_first"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Profile List

    private var profileListView: some View {
        List {
            ForEach(viewModel.profiles) { profile in
                ProfileRowView(
                    profile: profile,
                    isActive: viewModel.selectedProfile?.id == profile.id,
                    onSelect: {
                        viewModel.selectProfile(profile)
                    },
                    onDelete: {
                        viewModel.requestDeleteProfile(profile)
                    }
                )
            }
        }
    }
}

// MARK: - Profile Row

private struct ProfileRowView: View {
    let profile: UserProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(isActive ? .blue : .gray)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(profile.name)
                            .font(.headline)

                        if isActive {
                            Text(String(localized: "profile.badge.active"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }

                    Text(profileSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(locationText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            HStack(spacing: 16) {
                reportCountBadge

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(String(localized: "action.delete"), systemImage: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 4)
    }

    private var profileSubtitle: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: profile.birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: profile.birthTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        if let combined = calendar.date(from: components) {
            return dateFormatter.string(from: combined)
        }

        return dateFormatter.string(from: profile.birthDate)
    }

    private var locationText: String {
        profile.locationName
    }

    private var reportCountBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text.fill")
                .font(.caption2)
            Text(String(format: String(localized: "profile.reports.count %lld"), profile.reports.count))
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }
}

#Preview {
    @Previewable @State var viewModel: UserProfileViewModel = {
        let container = try! ModelContainer.astroSvitlaShared(inMemory: true)
        let context = container.mainContext

        let user = User()
        context.insert(user)

        let profile1 = UserProfile(
            name: "John Doe",
            birthDate: Date(timeIntervalSince1970: 631152000),
            birthTime: Date(timeIntervalSince1970: 631152000 + 14400),
            locationName: "New York, NY",
            latitude: 40.7128,
            longitude: -74.0060,
            timezone: "America/New_York"
        )
        profile1.user = user
        context.insert(profile1)

        let profile2 = UserProfile(
            name: "Jane Smith",
            birthDate: Date(timeIntervalSince1970: 662688000),
            birthTime: Date(timeIntervalSince1970: 662688000 + 43200),
            locationName: "Los Angeles, CA",
            latitude: 34.0522,
            longitude: -118.2437,
            timezone: "America/Los_Angeles"
        )
        profile2.user = user
        context.insert(profile2)

        try? context.save()

        let service = UserProfileService(context: context)
        let repositoryContext = RepositoryContext(context: context)
        let vm = UserProfileViewModel(service: service, repositoryContext: repositoryContext)
        vm.loadProfiles()
        vm.selectProfile(profile1)
        return vm
    }()

    return UserProfileListView(viewModel: viewModel)
}
