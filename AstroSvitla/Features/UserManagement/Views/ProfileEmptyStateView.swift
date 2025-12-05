import SwiftUI

struct ProfileEmptyStateView: View {
    var onCreateProfile: () -> Void

    @State private var animateOrbs = false
    @State private var animateIcon = false

    var body: some View {
        ZStack {
            // Animated cosmic background
            CosmicBackgroundView()

            VStack(spacing: 36) {
                Spacer()

                // Premium illustration with animated elements
                ZStack {
                    // Outer animated glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentColor.opacity(0.12),
                                    Color.accentColor.opacity(0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .scaleEffect(animateOrbs ? 1.1 : 1.0)

                    // Marble-textured ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.marbleWhite.opacity(0.4),
                                    Color.marbleVein.opacity(0.2),
                                    Color.marbleWhite.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(animateOrbs ? 360 : 0))

                    // Inner glass circle
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.accentColor.opacity(0.2), radius: 20, x: 0, y: 10)

                    // Animated icon
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.accentColor,
                                    Color.accentColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 8)

                // Glass content card
                VStack(spacing: 16) {
                    Text("profile.empty.title", bundle: .main)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    Text("profile.empty.description", bundle: .main)
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 8)

                // Premium action button
                VStack(spacing: 16) {
                    Button(action: onCreateProfile) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("profile.action.create", bundle: .main)
                        }
                    }
                    .buttonStyle(.astroPrimary)
                    .padding(.horizontal, 32)

                    // Subtle help text with icon
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))
                        Text("profile.hint.time", bundle: .main)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.tertiary)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                animateOrbs = true
            }
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                animateIcon = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileEmptyStateView(onCreateProfile: {})
            .navigationTitle(Text("navigation.start", bundle: .main))
    }
}
