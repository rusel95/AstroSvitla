// Feature: 006-instagram-share-templates
// Description: Key Insights template for Instagram Post (1080x1080)

import SwiftUI

// MARK: - KeyInsightsTemplate

/// Instagram Post template showing summary, top 3 planetary influences, and additional insights
/// Dimensions: 1080 x 1080 pixels (1:1 aspect ratio)
/// Compact layout with better space utilization
struct KeyInsightsTemplate: View {
    let shareContent: ShareContent
    let birthDetails: BirthDetails
    let reportArea: ReportArea

    var body: some View {
        ZStack {
            // Background gradient - unique midnight blue theme
            ZoryaBranding.keyInsightsGradient
                .ignoresSafeArea()

            // Decorative elements
            decorativeElements

            // Content
            VStack(spacing: 20) {
                // Header with area badge
                headerSection
                    .padding(.top, 32)

                // Summary
                summarySection

                // Key influences - vertical list
                influencesSection

                // Analysis highlights
                analysisHighlightsSection

                // Footer with app link
                footerSection
                    .padding(.top, 8)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, ZoryaBranding.templatePadding)
        }
        .frame(width: 1080, height: 1080)
    }
    
    // MARK: - Decorative Elements
    
    private var decorativeElements: some View {
        ZStack {
            // Top right glow
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.1))
                .frame(width: 350, height: 350)
                .blur(radius: 60)
                .offset(x: 300, y: -280)
            
            // Bottom left glow
            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -220, y: 320)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Report area badge
            HStack(spacing: 10) {
                Image(systemName: reportArea.icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(reportArea.displayName)
                    .font(.system(size: 22, weight: .bold))
            }
            .foregroundStyle(ZoryaBranding.accentGold)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(ZoryaBranding.accentGold.opacity(0.15))
            .clipShape(Capsule())
            
            // User name
            Text(birthDetails.displayName)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(ZoryaBranding.textSecondary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Text(shareContent.condensedSummary)
            .font(.system(size: 28, weight: .medium, design: .rounded))
            .foregroundStyle(ZoryaBranding.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(.horizontal, 16)
            .lineLimit(4)
    }
    
    // MARK: - Influences Section

    private var influencesSection: some View {
        VStack(spacing: 12) {
            // Section header
            Text(String(localized: "share.key_influences.title", defaultValue: "KEY INFLUENCES"))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ZoryaBranding.textTertiary)
                .textCase(.uppercase)
                .tracking(2)

            // Influence items in vertical list
            VStack(spacing: 10) {
                ForEach(Array(shareContent.topInfluences.enumerated()), id: \.offset) { index, influence in
                    influenceRow(influence, index: index)
                }
            }
        }
    }

    private func influenceRow(_ text: String, index: Int) -> some View {
        HStack(spacing: 14) {
            // Number badge
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold.opacity(0.25))
                    .frame(width: 36, height: 36)

                Text("\(index + 1)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ZoryaBranding.accentGold)
            }

            // Influence text
            Text(text)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(ZoryaBranding.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous)
                .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Analysis Highlights Section

    private var analysisHighlightsSection: some View {
        VStack(spacing: 10) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                Text(String(localized: "share.analysis_highlights.title", defaultValue: "HIGHLIGHTS"))
                    .font(.system(size: 16, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            .foregroundStyle(ZoryaBranding.textTertiary)

            // Highlights in horizontal wrap
            HStack(spacing: 8) {
                ForEach(Array(shareContent.analysisHighlights.enumerated()), id: \.offset) { _, highlight in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(ZoryaBranding.accentGold)

                        Text(highlight)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(ZoryaBranding.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(ZoryaBranding.cardBackground)
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 8) {
            // Divider
            Rectangle()
                .fill(ZoryaBranding.accentGold.opacity(0.3))
                .frame(width: 80, height: 1.5)

            // App branding and download CTA combined
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ZoryaBranding.accentGold)

                Text(ZoryaBranding.appName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ZoryaBranding.textPrimary)

                Text("•")
                    .foregroundStyle(ZoryaBranding.textTertiary)

                Text(ZoryaBranding.appStoreURL)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ZoryaBranding.accentGold)
            }
        }
    }
}

// MARK: - Preview

#Preview("Key Insights") {
    ScrollView {
        KeyInsightsTemplate(
            shareContent: .preview,
            birthDetails: BirthDetails(
                name: "Олександра",
                birthDate: Date(),
                birthTime: Date(),
                location: "Київ, Україна"
            ),
            reportArea: .career
        )
        .scaleEffect(0.35)
        .frame(width: 1080 * 0.35, height: 1080 * 0.35)
    }
}

#Preview("Key Insights - Ukrainian") {
    ScrollView {
        KeyInsightsTemplate(
            shareContent: .ukrainianPreview,
            birthDetails: BirthDetails(
                name: "Марія Іванівна",
                birthDate: Date(),
                birthTime: Date(),
                location: "Львів, Україна"
            ),
            reportArea: .finances
        )
        .scaleEffect(0.35)
        .frame(width: 1080 * 0.35, height: 1080 * 0.35)
    }
}
