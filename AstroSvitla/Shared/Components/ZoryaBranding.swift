// Feature: 006-instagram-share-templates
// Description: Centralized brand constants for Instagram share templates

import SwiftUI

// MARK: - ZoryaBranding

/// Centralized brand constants for consistent template styling
struct ZoryaBranding {
    
    // MARK: - Colors
    
    /// Primary gradient for template backgrounds (deep purple/navy)
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#1a0a2e"), Color(hex: "#16213e")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Chart Only template gradient - deep cosmic purple with starfield feel
    static let chartOnlyGradient = LinearGradient(
        colors: [Color(hex: "#0f0c29"), Color(hex: "#302b63"), Color(hex: "#24243e")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Key Insights template gradient - rich midnight blue with gold undertones
    static let keyInsightsGradient = LinearGradient(
        colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e"), Color(hex: "#0f3460")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Recommendations template gradient - cosmic purple-blue with mystical feel
    static let recommendationsGradient = LinearGradient(
        colors: [Color(hex: "#2c1654"), Color(hex: "#1e3a5f"), Color(hex: "#0d1b2a")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Carousel template gradient - aurora-inspired with dynamic colors
    static let carouselGradient = LinearGradient(
        colors: [Color(hex: "#1f1c2c"), Color(hex: "#1a2a6c"), Color(hex: "#2c1654")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Secondary gradient for overlay effects
    static let overlayGradient = LinearGradient(
        colors: [
            Color.black.opacity(0.3),
            Color.clear,
            Color.black.opacity(0.4)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Accent gold color for highlights
    static let accentGold = Color(hex: "#d4af37")
    
    /// Primary text color (white)
    static let textPrimary = Color.white
    
    /// Secondary text color (white with opacity)
    static let textSecondary = Color.white.opacity(0.8)
    
    /// Tertiary text color for less emphasis
    static let textTertiary = Color.white.opacity(0.6)
    
    /// Card background color
    static let cardBackground = Color.white.opacity(0.12)
    
    /// Border color for cards
    static let borderColor = Color.white.opacity(0.2)
    
    // MARK: - Typography (for templates at 1080px width)
    // Note: Using .system() fonts ensures proper Cyrillic character support (і, ї, є, ґ)
    // Do not replace with custom fonts unless they include full Ukrainian glyph coverage
    
    /// Title font (48pt bold)
    static let titleFont = Font.system(size: 48, weight: .bold, design: .rounded)
    
    /// Headline font (36pt semibold)
    static let headlineFont = Font.system(size: 36, weight: .semibold, design: .rounded)
    
    /// Body font (28pt regular)
    static let bodyFont = Font.system(size: 28, weight: .regular, design: .rounded)
    
    /// Caption font (22pt medium)
    static let captionFont = Font.system(size: 22, weight: .medium, design: .rounded)
    
    /// Small caption font (18pt medium)
    static let smallCaptionFont = Font.system(size: 18, weight: .medium, design: .rounded)
    
    /// Creates a scaled font for templates
    static func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    
    // MARK: - Brand Identity
    
    /// App name
    static let appName = "Zorya"
    
    /// Localized tagline
    static var tagline: String {
        String(localized: "zorya_tagline", defaultValue: "Discover your cosmic path")
    }
    
    /// Instagram handle
    static let instagramHandle = "@zorya.astrology"
    
    /// Website URL
    static let websiteURL = URL(string: "https://zorya.app")!
    
    /// Website display string
    static let websiteDisplay = "zorya.app"
    
    /// App Store URL for download CTA
    static let appStoreURL = "apps.apple.com/app/zorya"
    
    /// Localized watermark text
    static var watermark: String {
        String(localized: "zorya_watermark", defaultValue: "Generated with Zorya")
    }
    
    // MARK: - Dimensions
    
    /// Logo height in template
    static let logoHeight: CGFloat = 40
    
    /// Standard corner radius for cards
    static let cornerRadius: CGFloat = 16
    
    /// Large corner radius
    static let largeCornerRadius: CGFloat = 24
    
    /// Template padding (edge insets)
    static let templatePadding: CGFloat = 48
    
    /// Card padding
    static let cardPadding: CGFloat = 24
    
    /// Spacing between elements
    static let elementSpacing: CGFloat = 20
    
    /// Large spacing between sections
    static let sectionSpacing: CGFloat = 32
}

// MARK: - Branding View Components

extension ZoryaBranding {
    
    /// Standard footer view for all templates
    @ViewBuilder
    static func footer(showInstagram: Bool = false) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accentGold)
                
                Text(appName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(textPrimary)
            }
            
            Text(tagline)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(textSecondary)
            
            if showInstagram {
                Text(instagramHandle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(textTertiary)
            }
        }
    }
    
    /// Website CTA view
    @ViewBuilder
    static func websiteCTA() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: 20, weight: .medium))
            
            Text(websiteDisplay)
                .font(.system(size: 22, weight: .semibold))
        }
        .foregroundStyle(accentGold)
    }
}

// MARK: - Color Hex Extension

extension Color {
    
    /// Initialize Color from hex string (e.g., "#FF5733" or "FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (no alpha)
            (a, r, g, b) = (255, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews

#Preview("Branding Footer") {
    ZStack {
        ZoryaBranding.primaryGradient
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            ZoryaBranding.footer()
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            ZoryaBranding.footer(showInstagram: true)
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            ZoryaBranding.websiteCTA()
        }
        .padding()
    }
}
