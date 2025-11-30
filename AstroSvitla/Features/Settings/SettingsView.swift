import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var repositoryContext: RepositoryContext
    @Environment(\.modelContext) private var modelContext
    @State private var showingProfileManager = false
    @State private var showDevModeToast = false

    private var profileViewModel: UserProfileViewModel {
        let service = UserProfileService(context: modelContext)
        return UserProfileViewModel(service: service, repositoryContext: repositoryContext)
    }

    var body: some View {
        ZStack {
            // Premium cosmic background
            CosmicBackgroundView()
            
            ScrollView {
                VStack(spacing: 24) {
                    profileSection
                    appearanceSection
                    if preferences.isDevModeEnabled {
                        openAIModelSection
                    }
                    appInfoSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }

            // Dev mode toast
            if showDevModeToast {
                VStack {
                    Spacer()
                    devModeToast
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showDevModeToast)
            }
        }
        .navigationTitle(Text("Налаштування"))
        .sheet(isPresented: $showingProfileManager) {
            UserProfileListView(viewModel: profileViewModel)
        }
    }

    private var devModeToast: some View {
        HStack(spacing: 12) {
            Image(systemName: preferences.isDevModeEnabled ? "hammer.fill" : "hammer")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(preferences.isDevModeEnabled ? .green : .orange)

            Text(preferences.isDevModeEnabled ? "Dev Mode увімкнено" : "Dev Mode вимкнено")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    preferences.isDevModeEnabled ? Color.green.opacity(0.4) : Color.orange.opacity(0.4),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }

    // MARK: - Profile Section
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            SettingsSectionHeader(title: "Профілі", icon: "person.2.fill")
            
            // Profile management button
            Button {
                showingProfileManager = true
            } label: {
                SettingsRow(
                    icon: "person.crop.circle.badge.plus",
                    iconColor: Color(red: 0.4, green: 0.6, blue: 0.9),
                    title: "Керувати профілями",
                    subtitle: "Додати, редагувати або видалити профілі"
                )
            }
            .buttonStyle(.plain)
        }
        .glassCard(cornerRadius: 20, padding: 18, intensity: .regular)
    }

    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            SettingsSectionHeader(title: "Оформлення", icon: "paintbrush.fill")
            
            // Theme picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Тема додатку")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                
                // Custom segmented control with glass style
                HStack(spacing: 8) {
                    ForEach([
                        (AppPreferences.ThemeOption.system, "Система", "iphone"),
                        (AppPreferences.ThemeOption.light, "Світле", "sun.max.fill"),
                        (AppPreferences.ThemeOption.dark, "Темне", "moon.fill")
                    ], id: \.0) { option, title, icon in
                        ThemeOptionButton(
                            isSelected: preferences.theme == option,
                            title: title,
                            icon: icon
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                preferences.theme = option
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .glassCard(cornerRadius: 20, padding: 18, intensity: .regular)
    }

    // MARK: - OpenAI Model Section
    
    private var openAIModelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            SettingsSectionHeader(title: "Модель AI", icon: "brain.head.profile")
            
            // Model options
            VStack(spacing: 10) {
                ForEach(AppPreferences.OpenAIModel.allCases) { model in
                    ModelOptionCard(
                        model: model,
                        isSelected: preferences.selectedModel == model
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            preferences.selectedModel = model
                        }
                    }
                }
            }
            
            // Info footer
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor.opacity(0.7))
                
                Text("GPT-4o Mini рекомендовано для оптимального співвідношення ціни та якості")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .glassCard(cornerRadius: 20, padding: 18, intensity: .regular)
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with long press for dev mode
            SettingsSectionHeader(title: "Про додаток", icon: "sparkles")
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 1.5) {
                    withAnimation {
                        preferences.toggleDevMode()
                        showDevModeToast = true
                    }
                    // Hide toast after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showDevModeToast = false
                        }
                    }
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(preferences.isDevModeEnabled ? .success : .warning)
                }
            
            VStack(spacing: 12) {
                // App version
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Версія")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Text(appVersion)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()

                    // Dev mode indicator
                    if preferences.isDevModeEnabled {
                        HStack(spacing: 4) {
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 10))
                            Text("DEV")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15), in: Capsule())
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Made with love
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.pink.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.pink)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Зроблено з любов'ю")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("AstroSvitla Team 🇺🇦")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .glassCard(cornerRadius: 20, padding: 18, intensity: .regular)
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Settings Section Header

private struct SettingsSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.2), iconColor.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .frame(width: 44, height: 44)
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [iconColor.opacity(0.4), iconColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [iconColor, iconColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Theme Option Button

private struct ThemeOptionButton: View {
    let isSelected: Bool
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.15)
                    : Color.white.opacity(0.05),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? Color.accentColor.opacity(0.5)
                            : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Model Option Card

private struct ModelOptionCard: View {
    let model: AppPreferences.OpenAIModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Model info
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 12) {
                        // Cost
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle")
                                .font(.system(size: 11))
                            Text("$\(String(format: "%.4f", model.estimatedCostPer1000Tokens))/1K")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        
                        // Tokens
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.system(size: 11))
                            Text("\(model.maxTokens) токенів")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                // Recommended badge for gpt4oMini
                if model == .gpt4oMini {
                    Text("Рекомендовано")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.1)
                    : Color.white.opacity(0.03),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? Color.accentColor.opacity(0.4)
                            : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var container = try! ModelContainer(for: User.self, UserProfile.self, BirthChart.self, ReportPurchase.self)
    
    NavigationStack {
        SettingsView()
            .environmentObject(AppPreferences())
            .environmentObject(RepositoryContext(context: container.mainContext))
            .modelContainer(container)
    }
}
