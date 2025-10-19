import SwiftUI

struct ProfileEmptyStateView: View {
    var onCreateProfile: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(Color.accentColor.opacity(0.04))
                    .frame(width: 220, height: 220)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 16)

            // Text content
            VStack(spacing: 12) {
                Text("Створіть свій перший профіль")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text("Введіть дані про народження, щоб розрахувати вашу натальну карту та отримати персоналізовані астрологічні прогнози")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }

            // Action button
            Button(action: onCreateProfile) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Створити профіль")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.white)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            // Help text
            Text("Це займе всього 30 секунд")
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        ProfileEmptyStateView(onCreateProfile: {})
            .navigationTitle("Початок")
    }
}
