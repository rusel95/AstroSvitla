// Feature: 006-instagram-share-templates
// Description: Key Insights template for Instagram Post (1080x1080)

import SwiftUI

// MARK: - KeyInsightsTemplate

/// Instagram Post template showing summary and top 3 planetary influences
/// Dimensions: 1080 x 1080 pixels (1:1 aspect ratio)
struct KeyInsightsTemplate: View {
    let shareContent: ShareContent
    let birthDetails: BirthDetails
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
                // Header with area badge
                headerSection
                    .padding(.top, 48)
                
                Spacer()
                
                // Summary
                summarySection
                
                Spacer()
                
                // Key influences
                influencesSection
                
                Spacer()
                
                // Footer
                footerSection
                    .padding(.bottom, 48)
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
                .fill(ZoryaBranding.accentGold.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 300, y: -300)
            
            // Bottom left glow
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(x: -250, y: 350)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Report area badge
            HStack(spacing: 10) {
                Image(systemName: reportArea.icon)
                    .font(.system(size: 22, weight: .semibold))
                
                Text(reportArea.displayName)
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundStyle(ZoryaBranding.accentGold)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(ZoryaBranding.accentGold.opacity(0.15))
            .clipShape(Capsule())
            
            // User name
            Text(birthDetails.displayName)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(ZoryaBranding.textSecondary)
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        Text(shareContent.condensedSummary)
            .font(.system(size: 34, weight: .medium, design: .rounded))
            .foregroundStyle(ZoryaBranding.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(8)
            .padding(.horizontal, 24)
    }
    
    // MARK: - Influences Section
    
    private var influencesSection: some View {
        VStack(spacing: 20) {
            // Section header
            Text("Key Influences", comment: "Section header")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(ZoryaBranding.textTertiary)
                .textCase(.uppercase)
                .tracking(2)
            
            // Influence items
            VStack(spacing: 16) {
                ForEach(Array(shareContent.topInfluences.enumerated()), id: \.offset) { index, influence in
                    influenceRow(influence, index: index)
                }
            }
        }
        .padding(28)
        .background(ZoryaBranding.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous)
                .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
        )
    }
    
    private func influenceRow(_ text: String, index: Int) -> some View {
        HStack(spacing: 16) {
            // Index circle
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Text("\(index + 1)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(ZoryaBranding.accentGold)
            }
            
            // Influence text
            Text(text)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineLimit(2)
            
            Spacer()
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(ZoryaBranding.accentGold)
            
            Text(ZoryaBranding.appName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(ZoryaBranding.textPrimary)
            
            Text("•")
                .foregroundStyle(ZoryaBranding.textTertiary)
            
            Text(ZoryaBranding.websiteDisplay)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(ZoryaBranding.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview("Key Insights") {
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
    .frame(width: 1080, height: 1080)
    .scaleEffect(0.4)
}

#Preview("Key Insights - Ukrainian") {
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
    .frame(width: 1080, height: 1080)
    .scaleEffect(0.4)
}
