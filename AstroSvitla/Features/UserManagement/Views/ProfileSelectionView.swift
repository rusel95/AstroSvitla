import SwiftUI

struct ProfileSelectionView: View {
    var profiles: [UserProfile]
    var selectedProfile: UserProfile?
    var onSelectProfile: (UserProfile) -> Void
    var onCreateNewProfile: () -> Void
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Оберіть профіль")
                        .font(.system(size: 32, weight: .bold))

                    Text("Виберіть профіль для розрахунку натальної карти або створіть новий")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                // Profile list
                VStack(spacing: 12) {
                    ForEach(profiles) { profile in
                        ProfileCard(
                            profile: profile,
                            isSelected: profile.id == selectedProfile?.id,
                            onSelect: {
                                onSelectProfile(profile)
                            }
                        )
                    }

                    // Create new profile button
                    Button(action: onCreateNewProfile) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.accentColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Створити новий профіль")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)

                                Text("Додайте дані народження для нової людини")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                .foregroundStyle(Color.accentColor.opacity(0.2))
                        )
                    }
                }

                // Continue button
                Button(action: onContinue) {
                    HStack {
                        Text("Продовжити з профілем")
                            .font(.system(size: 17, weight: .semibold))

                        if let selected = selectedProfile {
                            Text("«\(selected.name)»")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedProfile == nil)
                .opacity(selectedProfile == nil ? 0.5 : 1.0)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ProfileCard: View {
    let profile: UserProfile
    let isSelected: Bool
    let onSelect: () -> Void

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
            HStack(spacing: 14) {
                // Avatar/Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "person.circle.fill")
                        .font(.system(size: 28, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : Color.accentColor)
                }

                // Profile info
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(formattedBirthDate)
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(formattedBirthTime)
                                .font(.system(size: 13))
                        }

                        Text("•")
                            .font(.system(size: 13))

                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 11))
                            Text(profile.locationName)
                                .font(.system(size: 13))
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                isSelected ?
                Color.accentColor.opacity(0.08) :
                Color(.secondarySystemBackground)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2
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
                    name: "Олександра",
                    birthDate: Date(),
                    birthTime: Date(),
                    locationName: "Київ, Україна",
                    latitude: 50.4501,
                    longitude: 30.5234,
                    timezone: "Europe/Kyiv"
                ),
                UserProfile(
                    name: "Іван",
                    birthDate: Date(),
                    birthTime: Date(),
                    locationName: "Львів, Україна",
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
        .navigationTitle("Профілі")
    }
}
