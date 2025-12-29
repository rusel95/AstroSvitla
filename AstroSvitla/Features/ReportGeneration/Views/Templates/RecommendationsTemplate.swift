// Feature: 006-instagram-share-templates
// Description: Recommendations template for Instagram Stories (1080x1920)

import SwiftUI

// MARK: - RecommendationsTemplate

/// Instagram Stories template showing personalized recommendations with full space usage
/// Dimensions: 1080 x 1920 pixels (9:16 aspect ratio)
/// Compact layout with better space utilization
struct RecommendationsTemplate: View {
    let shareContent: ShareContent
    let reportArea: ReportArea

    var body: some View {
        ZStack {
            // Background gradient - unique cosmic purple-blue theme
            ZoryaBranding.recommendationsGradient
                .ignoresSafeArea()

            // Decorative elements
            decorativeElements

            // Content
            VStack(spacing: 24) {
                // Header
                headerSection
                    .padding(.top, 50)

                // Condensed summary
                summarySection

                // Recommendations - full width usage
                recommendationsSection

                // Analysis highlights
                analysisSection

                // CTA Section
                ctaSection

                // Footer
                footerSection
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1920)
    }
    
    // MARK: - Decorative Elements
    
    private var decorativeElements: some View {
        ZStack {
            // Top glow
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.12))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(y: -600)
            
            // Middle glow
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -300, y: 0)
            
            // Bottom glow
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 450, height: 450)
                .blur(radius: 90)
                .offset(x: 200, y: 600)
        }
    }
    
    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 14) {
            // Icon and title in one row
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ZoryaBranding.accentGold.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                }

                Text(String(localized: "share.recommendations.title", defaultValue: "RECOMMENDATIONS"))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(ZoryaBranding.textPrimary)
            }

            // Report area badge
            HStack(spacing: 8) {
                Image(systemName: reportArea.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(reportArea.displayName)
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(ZoryaBranding.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(ZoryaBranding.cardBackground)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Summary Section

    private var summarySection: some View {
        Text(shareContent.condensedSummary)
            .font(.system(size: 26, weight: .medium, design: .rounded))
            .foregroundStyle(ZoryaBranding.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .lineLimit(4)
            .padding(.horizontal, 8)
    }
    
    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(spacing: 14) {
            ForEach(Array(shareContent.topRecommendations.enumerated()), id: \.offset) { index, recommendation in
                recommendationCard(recommendation, index: index)
            }
        }
    }

    private func recommendationCard(_ text: String, index: Int) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ZoryaBranding.accentGold, ZoryaBranding.accentGold.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text("\(index + 1)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Recommendation text - using full available width
            Text(text)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(ZoryaBranding.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous)
                .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                Text(String(localized: "share.highlights.title", defaultValue: "HIGHLIGHTS"))
                    .font(.system(size: 18, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            .foregroundStyle(ZoryaBranding.textTertiary)

            // Highlights as horizontal pills
            HStack(spacing: 10) {
                ForEach(Array(shareContent.analysisHighlights.enumerated()), id: \.offset) { _, highlight in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(ZoryaBranding.accentGold)

                        Text(highlight)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(ZoryaBranding.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(ZoryaBranding.cardBackground)
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 10) {
            Text(String(localized: "share.cta.get_full_report", defaultValue: "Get your full report"))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(ZoryaBranding.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 22, weight: .medium))

                Text(ZoryaBranding.appStoreURL)
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundStyle(ZoryaBranding.accentGold)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous)
                    .strokeBorder(ZoryaBranding.accentGold.opacity(0.4), lineWidth: 2)
            )
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 8) {
            // Decorative line
            Rectangle()
                .fill(ZoryaBranding.accentGold.opacity(0.3))
                .frame(width: 80, height: 1.5)

            // Branding
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ZoryaBranding.accentGold)

                Text(ZoryaBranding.appName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ZoryaBranding.textPrimary)

                Text("•")
                    .foregroundStyle(ZoryaBranding.textTertiary)

                Text(ZoryaBranding.tagline)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ZoryaBranding.textTertiary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Recommendations") {
    ScrollView {
        RecommendationsTemplate(
            shareContent: .preview,
            reportArea: .career
        )
        .scaleEffect(0.3)
        .frame(width: 1080 * 0.3, height: 1920 * 0.3)
    }
}

#Preview("Recommendations - Ukrainian") {
    ScrollView {
        RecommendationsTemplate(
            shareContent: .ukrainianPreview,
            reportArea: .relationships
        )
        .scaleEffect(0.3)
        .frame(width: 1080 * 0.3, height: 1920 * 0.3)
    }
}
