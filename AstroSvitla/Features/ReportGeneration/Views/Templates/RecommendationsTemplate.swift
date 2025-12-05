// Feature: 006-instagram-share-templates
// Description: Recommendations template for Instagram Stories (1080x1920)

import SwiftUI

// MARK: - RecommendationsTemplate

/// Instagram Stories template showing personalized recommendations
/// Dimensions: 1080 x 1920 pixels (9:16 aspect ratio)
struct RecommendationsTemplate: View {
    let shareContent: ShareContent
    let reportArea: ReportArea
    
    var body: some View {
        ZStack {
            // Background gradient
            ZoryaBranding.primaryGradient
                .ignoresSafeArea()
            
            // Decorative elements
            decorativeElements
            
            // Content
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 80)
                
                Spacer()
                
                // Recommendations
                recommendationsSection
                
                Spacer()
                
                // CTA Section
                ctaSection
                
                Spacer()
                
                // Footer
                footerSection
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, ZoryaBranding.templatePadding)
        }
        .frame(width: 1080, height: 1920)
    }
    
    // MARK: - Decorative Elements
    
    private var decorativeElements: some View {
        ZStack {
            // Top glow
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.1))
                .frame(width: 600, height: 600)
                .blur(radius: 100)
                .offset(y: -600)
            
            // Bottom glow
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(y: 600)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(ZoryaBranding.accentGold)
            }
            
            // Title
            Text("share.recommendations.title")
                .font(.system(size: 48, weight: .bold, design: .rounded))
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
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(spacing: 24) {
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
                    .frame(width: 56, height: 56)
                
                Text("\(index + 1)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            // Recommendation text
            Text(text)
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(28)
        .background(ZoryaBranding.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous)
                .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 16) {
            Text("share.cta.get_full_report")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(ZoryaBranding.textSecondary)
            
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                
                Text(ZoryaBranding.websiteDisplay)
                    .font(.system(size: 32, weight: .bold))
            }
            .foregroundStyle(ZoryaBranding.accentGold)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous)
                .strokeBorder(ZoryaBranding.accentGold.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            // Decorative line
            Rectangle()
                .fill(ZoryaBranding.accentGold.opacity(0.3))
                .frame(width: 120, height: 2)
            
            // Branding
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ZoryaBranding.accentGold)
                
                Text(ZoryaBranding.appName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(ZoryaBranding.textPrimary)
            }
            
            Text(ZoryaBranding.tagline)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(ZoryaBranding.textTertiary)
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
