// Feature: 006-instagram-share-templates
// Description: Recommendations template for Instagram Stories (1080x1920)

import SwiftUI

// MARK: - RecommendationsTemplate

/// Instagram Stories template showing personalized recommendations with full space usage
/// Dimensions: 1080 x 1920 pixels (9:16 aspect ratio)
/// Enhanced to maximize text space and show more content
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
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 60)
                
                // Condensed summary
                summarySection
                    .padding(.top, 32)
                
                Spacer()
                
                // Recommendations - full width usage
                recommendationsSection
                
                Spacer()
                
                // Analysis highlights
                analysisSection
                
                Spacer()
                
                // CTA Section
                ctaSection
                
                // Footer
                footerSection
                    .padding(.bottom, 50)
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
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(ZoryaBranding.accentGold)
            }
            
            // Title
            Text(String(localized: "share.recommendations.title", defaultValue: "RECOMMENDATIONS"))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(ZoryaBranding.textPrimary)
            
            // Report area badge
            HStack(spacing: 8) {
                Image(systemName: reportArea.icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(reportArea.displayName)
                    .font(.system(size: 22, weight: .semibold))
            }
            .foregroundStyle(ZoryaBranding.textSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(ZoryaBranding.cardBackground)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Text(shareContent.condensedSummary)
            .font(.system(size: 28, weight: .medium, design: .rounded))
            .foregroundStyle(ZoryaBranding.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .lineLimit(4)
            .padding(.horizontal, 8)
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(spacing: 20) {
            ForEach(Array(shareContent.topRecommendations.enumerated()), id: \.offset) { index, recommendation in
                recommendationCard(recommendation, index: index)
            }
        }
    }
    
    private func recommendationCard(_ text: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 20) {
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
                    .frame(width: 52, height: 52)
                
                Text("\(index + 1)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            // Recommendation text - using full available width
            Text(text)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineSpacing(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(ZoryaBranding.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous)
                .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Analysis Section
    
    private var analysisSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                Text(String(localized: "share.highlights.title", defaultValue: "HIGHLIGHTS"))
                    .font(.system(size: 20, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            .foregroundStyle(ZoryaBranding.textTertiary)
            
            // Highlights in horizontal layout - 2 per row
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(shareContent.analysisHighlights.enumerated()), id: \.offset) { _, highlight in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(ZoryaBranding.accentGold)
                        
                        Text(highlight)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(ZoryaBranding.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(ZoryaBranding.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 14) {
            Text(String(localized: "share.cta.get_full_report", defaultValue: "Get your full report"))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(ZoryaBranding.textSecondary)
            
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 26, weight: .medium))
                
                Text(ZoryaBranding.appStoreURL)
                    .font(.system(size: 28, weight: .bold))
            }
            .foregroundStyle(ZoryaBranding.accentGold)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous)
                    .strokeBorder(ZoryaBranding.accentGold.opacity(0.4), lineWidth: 2)
            )
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 10) {
            // Decorative line
            Rectangle()
                .fill(ZoryaBranding.accentGold.opacity(0.3))
                .frame(width: 100, height: 2)
            
            // Branding
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ZoryaBranding.accentGold)
                
                Text(ZoryaBranding.appName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(ZoryaBranding.textPrimary)
                
                Text("•")
                    .foregroundStyle(ZoryaBranding.textTertiary)
                
                Text(ZoryaBranding.tagline)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ZoryaBranding.textTertiary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Recommendations") {
    RecommendationsTemplate(
        shareContent: .preview,
        reportArea: .career
    )
    .frame(width: 1080, height: 1920)
    .scaleEffect(0.3)
}

#Preview("Recommendations - Ukrainian") {
    RecommendationsTemplate(
        shareContent: .ukrainianPreview,
        reportArea: .relationships
    )
    .frame(width: 1080, height: 1920)
    .scaleEffect(0.3)
}
