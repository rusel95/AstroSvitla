// Feature: 006-instagram-share-templates
// Description: Chart Only template for Instagram Stories (1080x1920)

import SwiftUI
import UIKit

// MARK: - ChartOnlyTemplate

/// Instagram Stories template showing the natal chart with birth details and key insights
/// Dimensions: 1080 x 1920 pixels (9:16 aspect ratio)
struct ChartOnlyTemplate: View {
    let birthDetails: BirthDetails
    let chartImage: UIImage?
    let shareContent: ShareContent?
    
    // Optional initializer for backward compatibility
    init(birthDetails: BirthDetails, chartImage: UIImage?, shareContent: ShareContent? = nil) {
        self.birthDetails = birthDetails
        self.chartImage = chartImage
        self.shareContent = shareContent
    }
    
    var body: some View {
        ZStack {
            // Background gradient - unique cosmic purple theme
            ZoryaBranding.chartOnlyGradient
                .ignoresSafeArea()
            
            // Decorative stars/sparkles
            decorativeElements
            
            // Content overlay
            VStack(spacing: 0) {
                // Top section with user info
                topSection
                    .padding(.top, 60)
                    .padding(.horizontal, ZoryaBranding.templatePadding)
                
                Spacer()
                
                // Chart section
                chartSection
                    .padding(.horizontal, ZoryaBranding.templatePadding)
                
                Spacer()
                
                // Key insights section (if available)
                if let content = shareContent {
                    keyInsightsSection(content: content)
                        .padding(.horizontal, ZoryaBranding.templatePadding)
                    
                    Spacer()
                }
                
                // Bottom section with branding and CTA
                bottomSection
                    .padding(.bottom, 60)
                    .padding(.horizontal, ZoryaBranding.templatePadding)
            }
        }
        .frame(width: 1080, height: 1920)
    }
    
    // MARK: - Decorative Elements
    
    private var decorativeElements: some View {
        ZStack {
            // Top right glow
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: 300, y: -500)
            
            // Bottom left glow
            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(x: -250, y: 600)
        }
    }
    
    // MARK: - Top Section
    
    private var topSection: some View {
        VStack(spacing: 16) {
            // User name
            Text(truncatedName)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineLimit(1)
            
            // Birth details
            HStack(spacing: 24) {
                // Date
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24, weight: .medium))
                    Text(birthDetails.formattedBirthDate)
                        .font(.system(size: 24, weight: .medium))
                }
                
                // Time
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 24, weight: .medium))
                    Text(birthDetails.formattedBirthTime)
                        .font(.system(size: 24, weight: .medium))
                }
            }
            .foregroundStyle(ZoryaBranding.textSecondary)
            
            // Location
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22, weight: .medium))
                Text(birthDetails.formattedLocation)
                    .font(.system(size: 22, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(ZoryaBranding.textTertiary)
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        Group {
            if let image = chartImage {
                // Chart image with decorative frame
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(ZoryaBranding.accentGold.opacity(0.15))
                        .frame(width: 620, height: 620)
                        .blur(radius: 30)
                    
                    // Chart image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 560, height: 560)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            ZoryaBranding.accentGold.opacity(0.6),
                                            ZoryaBranding.accentGold.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                }
            } else {
                #if targetEnvironment(simulator)
                // Simulator Mock Chart - improved fallback
                ZStack {
                    Circle()
                        .fill(ZoryaBranding.cardBackground)
                        .frame(width: 560, height: 560)
                    
                    // Mock planetary positions
                    ZStack {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(ZoryaBranding.accentGold)
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.purple.opacity(0.8))
                            .offset(x: 120, y: -80)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.blue.opacity(0.6))
                            .offset(x: -100, y: 120)
                        
                        Circle()
                            .strokeBorder(ZoryaBranding.accentGold.opacity(0.3), lineWidth: 2)
                            .frame(width: 480, height: 480)
                        
                        Circle()
                            .strokeBorder(ZoryaBranding.accentGold.opacity(0.2), lineWidth: 1)
                            .frame(width: 380, height: 380)
                    }
                }
                .overlay(
                    Circle()
                        .strokeBorder(ZoryaBranding.borderColor, lineWidth: 2)
                        .frame(width: 560, height: 560)
                )
                #else
                // Placeholder when no chart image
                placeholderChart
                #endif
            }
        }
    }
    
    private var placeholderChart: some View {
        ZStack {
            Circle()
                .fill(ZoryaBranding.cardBackground)
                .frame(width: 560, height: 560)
            
            VStack(spacing: 16) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(ZoryaBranding.accentGold.opacity(0.5))
                
                Text(String(localized: "share.chart.placeholder", defaultValue: "Natal Chart"))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(ZoryaBranding.textSecondary)
            }
        }
        .overlay(
            Circle()
                .strokeBorder(ZoryaBranding.borderColor, lineWidth: 2)
                .frame(width: 560, height: 560)
        )
    }
    
    // MARK: - Key Insights Section
    
    private func keyInsightsSection(content: ShareContent) -> some View {
        VStack(spacing: 20) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                Text(String(localized: "share.key_insights.title", defaultValue: "KEY INSIGHTS"))
                    .font(.system(size: 22, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            .foregroundStyle(ZoryaBranding.accentGold)
            
            // Top 3 influences
            VStack(spacing: 14) {
                ForEach(Array(content.topInfluences.prefix(3).enumerated()), id: \.offset) { _, influence in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(ZoryaBranding.accentGold.opacity(0.4))
                            .frame(width: 8, height: 8)
                        
                        Text(influence)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(ZoryaBranding.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
            .padding(24)
            .background(ZoryaBranding.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous)
                    .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Decorative line
            Rectangle()
                .fill(ZoryaBranding.accentGold.opacity(0.3))
                .frame(width: 200, height: 2)
            
            // Branding footer
            ZoryaBranding.footer()
            
            // Download CTA
            VStack(spacing: 8) {
                Text(String(localized: "share.cta.download_app", defaultValue: "Download on App Store"))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ZoryaBranding.textSecondary)
                
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 24, weight: .medium))
                    Text(ZoryaBranding.appStoreURL)
                        .font(.system(size: 22, weight: .semibold))
                }
                .foregroundStyle(ZoryaBranding.accentGold)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var truncatedName: String {
        let name = birthDetails.displayName
        if name.count > 20 {
            return String(name.prefix(20)) + "…"
        }
        return name
    }
}

// MARK: - Preview

#Preview("Chart Only - With Image") {
    ChartOnlyTemplate(
        birthDetails: BirthDetails(
            name: "Олександра",
            birthDate: Date(),
            birthTime: Date(),
            location: "Київ, Україна"
        ),
        chartImage: nil,
        shareContent: .preview
    )
    .frame(width: 1080, height: 1920)
    .scaleEffect(0.3)
}

#Preview("Chart Only - Long Name") {
    ChartOnlyTemplate(
        birthDetails: BirthDetails(
            name: "Олександра Вікторівна Петренко-Коваленко",
            birthDate: Date(),
            birthTime: Date(),
            location: "Дніпропетровськ, Україна"
        ),
        chartImage: nil,
        shareContent: .ukrainianPreview
    )
    .frame(width: 1080, height: 1920)
    .scaleEffect(0.3)
}
