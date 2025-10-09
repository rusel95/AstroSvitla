import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var repositoryContext: RepositoryContext
    @Environment(\.modelContext) private var modelContext
    @State private var isResetOnboardingConfirmationPresented = false
    @State private var showingProfileManager = false

    private var profileViewModel: UserProfileViewModel {
        let service = UserProfileService(context: modelContext)
        return UserProfileViewModel(service: service, repositoryContext: repositoryContext)
    }

    var body: some View {
        Form {
            profileSection
            appearanceSection
            languageSection
            onboardingSection
        }
        .navigationTitle(Text("settings.title", tableName: "Localizable"))
        .confirmationDialog(
            String(localized: "settings.dialog.onboarding.title", table: "Localizable"),
            isPresented: $isResetOnboardingConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings.dialog.onboarding.confirm", table: "Localizable"), role: .destructive) {
                OnboardingViewModel.resetStoredProgress()
            }
            Button(String(localized: "action.cancel", table: "Localizable"), role: .cancel) { }
        }
        .sheet(isPresented: $showingProfileManager) {
            UserProfileListView(viewModel: profileViewModel)
        }
    }

    private var profileSection: some View {
        Section {
            Button {
                showingProfileManager = true
            } label: {
                Label {
                    Text("settings.action.manage_profiles", tableName: "Localizable")
                } icon: {
                    Image(systemName: "person.2")
                }
            }
        } header: {
            Text("settings.section.profiles", tableName: "Localizable")
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker(selection: $preferences.theme) {
                Text("settings.theme.system", tableName: "Localizable").tag(AppPreferences.ThemeOption.system)
                Text("settings.theme.light", tableName: "Localizable").tag(AppPreferences.ThemeOption.light)
                Text("settings.theme.dark", tableName: "Localizable").tag(AppPreferences.ThemeOption.dark)
            } label: {
                Text("settings.picker.theme", tableName: "Localizable")
            }
            .pickerStyle(.segmented)
        } header: {
            Text("settings.section.theme", tableName: "Localizable")
        }
    }

    private var languageSection: some View {
        Section {
            Picker(selection: $preferences.language) {
                Text("settings.language.system", tableName: "Localizable").tag(AppPreferences.LanguageOption.system)
                Text("settings.language.ukrainian", tableName: "Localizable").tag(AppPreferences.LanguageOption.ukrainian)
                Text("settings.language.english", tableName: "Localizable").tag(AppPreferences.LanguageOption.english)
            } label: {}
            .pickerStyle(.inline)
            Text("settings.language.note", tableName: "Localizable")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("settings.section.language", tableName: "Localizable")
        }
    }

    private var onboardingSection: some View {
        Section {
            Button {
                isResetOnboardingConfirmationPresented = true
            } label: {
                Label {
                    Text("settings.action.replay_onboarding", tableName: "Localizable")
                } icon: {
                    Image(systemName: "sparkles")
                }
            }
        } header: {
            Text("settings.section.onboarding", tableName: "Localizable")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppPreferences())
    }
}
