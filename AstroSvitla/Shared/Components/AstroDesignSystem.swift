import SwiftUI

// MARK: - Astro Design System
// A comprehensive design system inspired by iOS 26 glass morphism with marble accents

// MARK: - Color Palette

extension Color {
    // Primary gradient colors (cosmic theme)
    static let astroGradientStart = Color(red: 0.4, green: 0.3, blue: 0.8)
    static let astroGradientMid = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let astroGradientEnd = Color(red: 0.3, green: 0.5, blue: 0.9)

    // Marble-like accent colors
    static let marbleWhite = Color(red: 0.98, green: 0.97, blue: 0.96)
    static let marbleGray = Color(red: 0.92, green: 0.91, blue: 0.90)
    static let marbleVein = Color(red: 0.85, green: 0.83, blue: 0.82)

    // Glass tints
    static let glassLight = Color.white.opacity(0.15)
    static let glassBorder = Color.white.opacity(0.3)
    static let glassHighlight = Color.white.opacity(0.5)

    // Semantic colors
    static let astroPrimary = Color.accentColor
    static let astroSecondary = Color(red: 0.5, green: 0.4, blue: 0.7)
    static let astroSuccess = Color(red: 0.3, green: 0.7, blue: 0.5)
    static let astroWarning = Color(red: 0.9, green: 0.7, blue: 0.3)
}

// MARK: - Gradient Definitions

extension LinearGradient {
    /// Main cosmic gradient for backgrounds
    static let astroBackground = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.06, blue: 0.15),
            Color(red: 0.12, green: 0.08, blue: 0.20),
            Color(red: 0.06, green: 0.10, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle gradient for light mode backgrounds
    static let astroCream = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.97, blue: 0.95),
            Color(red: 0.96, green: 0.94, blue: 0.92),
            Color(red: 0.94, green: 0.92, blue: 0.90)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Marble texture gradient
    static let marble = LinearGradient(
        colors: [
            Color.marbleWhite,
            Color.marbleGray,
            Color.marbleWhite.opacity(0.9),
            Color.marbleVein.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Accent gradient for buttons and highlights
    static let astroPrimary = LinearGradient(
        colors: [
            Color.accentColor,
            Color.accentColor.opacity(0.85),
            Color.accentColor.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Glass shine effect
    static let glassShine = LinearGradient(
        colors: [
            Color.white.opacity(0.25),
            Color.white.opacity(0.05),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glass Card Style

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20
    var intensity: GlassIntensity = .regular

    enum GlassIntensity {
        case subtle, regular, prominent

        var material: Material {
            switch self {
            case .subtle: return .ultraThinMaterial
            case .regular: return .thinMaterial
            case .prominent: return .regularMaterial
            }
        }

        var borderOpacity: Double {
            switch self {
            case .subtle: return 0.15
            case .regular: return 0.25
            case .prominent: return 0.35
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(intensity.material, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(intensity.borderOpacity),
                                Color.white.opacity(intensity.borderOpacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func glassCard(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        intensity: GlassCardModifier.GlassIntensity = .regular
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding, intensity: intensity))
    }
}

// MARK: - Premium Button Styles

struct AstroPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient.astroPrimary
                        .opacity(isEnabled ? 1 : 0.5)

                    // Shine overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(configuration.isPressed ? 0 : 0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: Color.accentColor.opacity(configuration.isPressed ? 0.2 : 0.35),
                radius: configuration.isPressed ? 8 : 16,
                x: 0,
                y: configuration.isPressed ? 4 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AstroSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AstroGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.06 : 0),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AstroPrimaryButtonStyle {
    static var astroPrimary: AstroPrimaryButtonStyle { AstroPrimaryButtonStyle() }
}

extension ButtonStyle where Self == AstroSecondaryButtonStyle {
    static var astroSecondary: AstroSecondaryButtonStyle { AstroSecondaryButtonStyle() }
}

extension ButtonStyle where Self == AstroGhostButtonStyle {
    static var astroGhost: AstroGhostButtonStyle { AstroGhostButtonStyle() }
}

// MARK: - Animated Background

struct CosmicBackgroundView: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Animated orbs
            GeometryReader { geometry in
                ZStack {
                    // Primary orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentColor.opacity(0.15),
                                    Color.accentColor.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.4
                            )
                        )
                        .frame(width: geometry.size.width * 0.8)
                        .offset(
                            x: animateGradient ? geometry.size.width * 0.1 : -geometry.size.width * 0.1,
                            y: animateGradient ? -geometry.size.height * 0.1 : geometry.size.height * 0.1
                        )

                    // Secondary orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.astroSecondary.opacity(0.12),
                                    Color.astroSecondary.opacity(0.03),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.35
                            )
                        )
                        .frame(width: geometry.size.width * 0.7)
                        .offset(
                            x: animateGradient ? -geometry.size.width * 0.15 : geometry.size.width * 0.15,
                            y: animateGradient ? geometry.size.height * 0.2 : -geometry.size.height * 0.1
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Marble Texture View

struct MarbleTextureView: View {
    var opacity: Double = 0.5

    var body: some View {
        ZStack {
            // Base marble
            LinearGradient.marble
                .opacity(opacity)

            // Subtle vein pattern
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    path.move(to: CGPoint(x: 0, y: height * 0.3))
                    path.addQuadCurve(
                        to: CGPoint(x: width, y: height * 0.5),
                        control: CGPoint(x: width * 0.5, y: height * 0.2)
                    )
                }
                .stroke(
                    Color.marbleVein.opacity(opacity * 0.5),
                    style: StrokeStyle(lineWidth: 0.5, lineCap: .round)
                )
            }
        }
    }
}

// MARK: - Icon Container

struct AstroIconContainer: View {
    let systemName: String
    var size: IconSize = .large
    var style: IconStyle = .gradient

    enum IconSize {
        case small, medium, large, hero

        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 28
            case .large: return 44
            case .hero: return 72
            }
        }

        var containerSize: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 52
            case .large: return 80
            case .hero: return 140
            }
        }
    }

    enum IconStyle {
        case gradient, glass, solid
    }

    var body: some View {
        ZStack {
            switch style {
            case .gradient:
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.2),
                                Color.accentColor.opacity(0.08),
                                Color.accentColor.opacity(0.02)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.containerSize
                        )
                    )
                    .frame(width: size.containerSize * 1.5)

                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: size.containerSize)

            case .glass:
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size.containerSize)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )

            case .solid:
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: size.containerSize)
            }

            Image(systemName: systemName)
                .font(.system(size: size.iconSize, weight: .light))
                .foregroundStyle(iconGradient)
        }
    }

    private var iconGradient: some ShapeStyle {
        if style == .solid {
            return AnyShapeStyle(Color.white)
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: -geometry.size.width * 0.25 + phase * geometry.size.width * 1.5)
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Pulsing Animation

struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulsing() -> some View {
        modifier(PulsingModifier())
    }
}

// MARK: - Progress Ring

struct AstroProgressRing: View {
    var progress: Double = 0.25
    var lineWidth: CGFloat = 4
    var size: CGFloat = 60

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.accentColor.opacity(0.15),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Glow effect
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    Color.accentColor.opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth * 2, lineCap: .round)
                )
                .blur(radius: 4)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Animated Loader

struct AstroLoader: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.accentColor.opacity(0.1),
                            Color.accentColor.opacity(0.5),
                            Color.accentColor,
                            Color.accentColor.opacity(0.1)
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotation))

            // Inner dots
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .offset(y: -12)
                    .rotationEffect(.degrees(Double(index) * 120 + rotation * 0.5))
                    .scaleEffect(scale)
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                scale = 0.6
            }
        }
    }
}

// MARK: - Section Header

struct AstroSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("Design System") {
    ScrollView {
        VStack(spacing: 32) {
            AstroSectionHeader(
                title: "Design System",
                subtitle: "iOS 26 inspired glass morphism"
            )

            // Icons
            HStack(spacing: 24) {
                AstroIconContainer(systemName: "star.fill", size: .small, style: .solid)
                AstroIconContainer(systemName: "moon.fill", size: .medium, style: .glass)
                AstroIconContainer(systemName: "sun.max.fill", size: .large, style: .gradient)
            }

            // Buttons
            VStack(spacing: 16) {
                Button("Primary Action") {}
                    .buttonStyle(.astroPrimary)

                Button("Secondary Action") {}
                    .buttonStyle(.astroSecondary)

                Button("Ghost Action") {}
                    .buttonStyle(.astroGhost)
            }

            // Glass card
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass Card Example")
                    .font(.headline)
                Text("This card uses glass morphism with subtle borders and shadows.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()

            // Loader
            HStack(spacing: 32) {
                AstroLoader()
                AstroProgressRing(progress: 0.7)
            }
        }
        .padding(24)
    }
    .background(CosmicBackgroundView())
}
