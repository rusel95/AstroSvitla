import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var repositoryContext: RepositoryContext
    @Environment(\.modelContext) private var modelContext
    @State private var showingProfileManager = false

    private var profileViewModel: UserProfileViewModel {
        let service = UserProfileService(context: modelContext)
        return UserProfileViewModel(service: service, repositoryContext: repositoryContext)
    }

    var body: some View {
        Form {
            profileSection
            appearanceSection
            openAIModelSection
        }
        .navigationTitle(Text("Налаштування"))
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
                    Text("Керувати профілями")
                } icon: {
                    Image(systemName: "person.2")
                }
            }
        } header: {
            Text("Профілі")
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker(selection: $preferences.theme) {
                Text("Система").tag(AppPreferences.ThemeOption.system)
                Text("Світле").tag(AppPreferences.ThemeOption.light)
                Text("Темне").tag(AppPreferences.ThemeOption.dark)
            } label: {
                Text("Тема")
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Оформлення")
        }
    }

    private var openAIModelSection: some View {
        Section {
            Picker(selection: $preferences.selectedModel) {
                ForEach(AppPreferences.OpenAIModel.allCases) { model in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.displayName)
                        Text("~$\(String(format: "%.4f", model.estimatedCostPer1000Tokens))/1K токенів")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .tag(model)
                }
            } label: {}
            .pickerStyle(.inline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Обрана модель: **\(preferences.selectedModel.displayName)**")
                    .font(.subheadline)

                HStack {
                    Label("Макс. токенів", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(preferences.selectedModel.maxTokens)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Приблизна вартість", systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.4f", preferences.selectedModel.estimatedCostPer1000Tokens))/1K")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Модель OpenAI")
        } footer: {
            Text("Обирайте більш потужні моделі для кращої якості аналізу. GPT-4o Mini рекомендовано для оптимального співвідношення ціни та якості.")
                .font(.footnote)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppPreferences())
    }
}
