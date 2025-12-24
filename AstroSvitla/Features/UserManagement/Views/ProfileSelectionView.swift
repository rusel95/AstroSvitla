import SwiftUI

struct ProfileSelectionView: View {
    var profiles: [UserProfile]
    var selectedProfile: UserProfile?
    var onSelectProfile: (UserProfile) -> Void
    var onCreateNewProfile: () -> Void
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            // Animated background
            CosmicBackgroundView()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Header with glass effect
                        AstroSectionHeader(
                            title: String(localized: "profile.select.title"),
                            subtitle: String(localized: "profile.select.subtitle")
                        )
                        .padding(.top, 8)

                        // Profile list with glass cards
                        VStack(spacing: 14) {
                            ForEach(profiles) { profile in
                                ProfileCard(
                                    profile: profile,
                                    isSelected: profile.id == selectedProfile?.id,
                                    onSelect: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            onSelectProfile(profile)
                                        }
                                    }
                                )
                            }

                            // Create new profile button with dashed border
                            CreateProfileButton(action: onCreateNewProfile)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }

                // Continue button pinned to bottom
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        if let selected = selectedProfile {
                            Text(String(format: String(localized: "profile.continue.with %@"), selected.name))
                                .opacity(0.85)
                        }

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(.astroPrimary)
                .disabled(selectedProfile == nil)
                .opacity(selectedProfile == nil ? 0.5 : 1.0)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial.opacity(0.8))
            }
        }
    }
}

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: UserProfile
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isPressed = false

    private var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: profile.birthDate)
    }

    private var formattedBirthTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: profile.birthTime)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Avatar with glass effect
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 56, height: 56)
                    }

                    Image(systemName: isSelected ? "checkmark" : "person.fill")
                        .font(.system(size: isSelected ? 22 : 24, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : Color.accentColor)
                }
                .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)

                // Profile info
                VStack(alignment: .leading, spacing: 8) {
                    Text(profile.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .medium))
                        Text(formattedBirthDate)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11, weight: .medium))
                            Text(formattedBirthTime)
                                .font(.system(size: 13))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 11, weight: .medium))
                            Text(profile.locationName)
                                .font(.system(size: 13))
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.thinMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.05),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Create Profile Button

struct CreateProfileButton: View {
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Plus icon with glass effect
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("profile.create.new", bundle: .main)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("profile.create.hint", bundle: .main)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("With Profiles") {
    NavigationStack {
        ProfileSelectionView(
            profiles: [
                UserProfile(
                    name: "Alexandra",
                    birthDate: Date(),
                    birthTime: Date(),
                    locationName: "Kyiv, Ukraine",
                    latitude: 50.4501,
                    longitude: 30.5234,
                    timezone: "Europe/Kyiv"
                ),
                UserProfile(
                    name: "Ivan",
                    birthDate: Date(),
                    birthTime: Date(),
                    locationName: "Lviv, Ukraine",
                    latitude: 49.8397,
                    longitude: 24.0297,
                    timezone: "Europe/Kyiv"
                )
            ],
            selectedProfile: nil,
            onSelectProfile: { _ in },
            onCreateNewProfile: {},
            onContinue: {}
        )
        .navigationTitle(Text("profile.navigation.title", bundle: .main))
    }
}
