// Feature: 006-instagram-share-templates
// Description: 5-slide Carousel templates for Instagram Post (1080x1080 each)

import SwiftUI
import UIKit

// MARK: - Carousel Cover Slide

/// Slide 0: Cover with natal chart, user info, and key insight
struct CarouselCoverSlide: View {
    let birthDetails: BirthDetails
    let chartImage: UIImage?
    let reportArea: ReportArea
    let shareContent: ShareContent?
    
    init(birthDetails: BirthDetails, chartImage: UIImage?, reportArea: ReportArea, shareContent: ShareContent? = nil) {
        self.birthDetails = birthDetails
        self.chartImage = chartImage
        self.reportArea = reportArea
        self.shareContent = shareContent
    }
    
    var body: some View {
        ZStack {
            ZoryaBranding.carouselGradient
                .ignoresSafeArea()
            
            // Decorative elements
            decorativeElements
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // Report area badge
                    HStack(spacing: 8) {
                        Image(systemName: reportArea.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(reportArea.displayName)
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundStyle(ZoryaBranding.accentGold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ZoryaBranding.accentGold.opacity(0.15))
                    .clipShape(Capsule())
                    
                    // User name
                    Text(birthDetails.displayName)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(ZoryaBranding.textPrimary)
                        .lineLimit(1)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Chart image
                chartView
                
                Spacer()
                
                // Key insight preview (if available)
                if let content = shareContent, let firstInfluence = content.topInfluences.first {
                    VStack(spacing: 8) {
                        Text(String(localized: "share.main_influence.title", defaultValue: "MAIN INFLUENCE"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ZoryaBranding.textTertiary)
                            .textCase(.uppercase)
                            .tracking(1.5)
                        
                        Text(firstInfluence)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(ZoryaBranding.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(ZoryaBranding.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                Spacer()
                
                // Swipe indicator
                VStack(spacing: 8) {
                    Text(String(localized: "carousel.cover.swipe_hint", defaultValue: "Swipe to see more"))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(ZoryaBranding.textSecondary)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1080)
    }
    
    private var decorativeElements: some View {
        ZStack {
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 300, y: -300)
            
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: -280, y: 300)
        }
    }
    
    @ViewBuilder
    private var chartView: some View {
        if let image = chartImage {
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold.opacity(0.1))
                    .frame(width: 420, height: 420)
                    .blur(radius: 20)
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 380, height: 380)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(ZoryaBranding.accentGold.opacity(0.4), lineWidth: 2)
                    )
            }
        } else {
            #if targetEnvironment(simulator)
            ZStack {
                Circle()
                    .fill(ZoryaBranding.cardBackground)
                    .frame(width: 380, height: 380)
                
                // Mock planetary positions
                ZStack {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(ZoryaBranding.accentGold)
                    
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.purple.opacity(0.8))
                        .offset(x: 80, y: -50)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.blue.opacity(0.6))
                        .offset(x: -70, y: 80)
                    
                    Circle()
                        .strokeBorder(ZoryaBranding.accentGold.opacity(0.3), lineWidth: 2)
                        .frame(width: 320, height: 320)
                }
            }
            .overlay(
                Circle()
                    .strokeBorder(ZoryaBranding.borderColor, lineWidth: 2)
                    .frame(width: 380, height: 380)
            )
            #else
            ZStack {
                Circle()
                    .fill(ZoryaBranding.cardBackground)
                    .frame(width: 380, height: 380)
                
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 70, weight: .light))
                    .foregroundStyle(ZoryaBranding.accentGold.opacity(0.5))
            }
            .overlay(
                Circle()
                    .strokeBorder(ZoryaBranding.borderColor, lineWidth: 2)
                    .frame(width: 380, height: 380)
            )
            #endif
        }
    }
}

// MARK: - Carousel Influences Slide

/// Slide 1: Key planetary influences with full content
struct CarouselInfluencesSlide: View {
    let shareContent: ShareContent
    
    var body: some View {
        ZStack {
            ZoryaBranding.carouselGradient
                .ignoresSafeArea()
            
            // Decorative glow
            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(x: -200, y: -180)
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                    
                    Text(String(localized: "carousel.influences.title", defaultValue: "KEY INFLUENCES"))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(ZoryaBranding.textPrimary)
                }
                .padding(.top, 40)
                
                // Summary snippet
                Text(shareContent.condensedSummary)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ZoryaBranding.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 16)
                
                Spacer()
                
                // Influences list - full width
                VStack(spacing: 16) {
                    ForEach(Array(shareContent.topInfluences.enumerated()), id: \.offset) { index, influence in
                        influenceRow(influence, index: index)
                    }
                }
                .padding(24)
                .background(ZoryaBranding.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous)
                        .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
                )
                
                Spacer()
                
                // Footer
                slideFooter(pageNumber: 2)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1080)
    }
    
    private func influenceRow(_ text: String, index: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Text("\(index + 1)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ZoryaBranding.accentGold)
            }
            
            Text(text)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

// MARK: - Carousel Recommendations Slide

/// Slide 2: Top recommendations with full space usage
struct CarouselRecommendationsSlide: View {
    let shareContent: ShareContent
    
    var body: some View {
        ZStack {
            ZoryaBranding.carouselGradient
                .ignoresSafeArea()
            
            // Decorative glow
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.1))
                .frame(width: 450, height: 450)
                .blur(radius: 80)
                .offset(x: 200, y: 200)
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                    
                    Text(String(localized: "carousel.recommendations.title", defaultValue: "RECOMMENDATIONS"))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(ZoryaBranding.textPrimary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Recommendations list - full width usage
                VStack(spacing: 16) {
                    ForEach(Array(shareContent.topRecommendations.enumerated()), id: \.offset) { index, recommendation in
                        recommendationRow(recommendation, index: index)
                    }
                }
                
                Spacer()
                
                // Footer
                slideFooter(pageNumber: 3)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1080)
    }
    
    private func recommendationRow(_ text: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold)
                    .frame(width: 44, height: 44)
                
                Text("\(index + 1)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Text(text)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(ZoryaBranding.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous)
                .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Carousel Analysis Slide

/// Slide 3: Detailed analysis highlights with more content
struct CarouselAnalysisSlide: View {
    let shareContent: ShareContent
    
    var body: some View {
        ZStack {
            ZoryaBranding.carouselGradient
                .ignoresSafeArea()
            
            // Decorative glow
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(x: -100, y: 250)
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                    
                    Text(String(localized: "carousel.analysis.title", defaultValue: "ANALYSIS"))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(ZoryaBranding.textPrimary)
                }
                .padding(.top, 40)
                
                // Summary section
                Text(shareContent.condensedSummary)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ZoryaBranding.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 16)
                
                Spacer()
                
                // Analysis highlights - full display
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(shareContent.analysisHighlights.enumerated()), id: \.offset) { _, highlight in
                        analysisRow(highlight)
                    }
                }
                .padding(28)
                .background(ZoryaBranding.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: ZoryaBranding.largeCornerRadius, style: .continuous)
                        .strokeBorder(ZoryaBranding.borderColor, lineWidth: 1)
                )
                
                Spacer()
                
                // Footer
                slideFooter(pageNumber: 4)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1080)
    }
    
    private func analysisRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(ZoryaBranding.accentGold)
            
            Text(text)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

// MARK: - Carousel CTA Slide

/// Slide 4: Call to action with app promo and download link
struct CarouselCTASlide: View {
    var body: some View {
        ZStack {
            ZoryaBranding.carouselGradient
                .ignoresSafeArea()
            
            // Decorative glows
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.15))
                .frame(width: 450, height: 450)
                .blur(radius: 100)
                .offset(y: -180)
            
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(y: 280)
            
            VStack(spacing: 28) {
                Spacer()
                
                // Main CTA content
                VStack(spacing: 24) {
                    // Logo/Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ZoryaBranding.accentGold, ZoryaBranding.accentGold.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 52, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    
                    // App name and tagline
                    VStack(spacing: 10) {
                        Text(ZoryaBranding.appName)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(ZoryaBranding.textPrimary)
                        
                        Text(ZoryaBranding.tagline)
                            .font(.system(size: 26, weight: .medium, design: .rounded))
                            .foregroundStyle(ZoryaBranding.textSecondary)
                    }
                    
                    // Feature highlights
                    VStack(spacing: 12) {
                        featureRow(icon: "chart.pie.fill", text: String(localized: "share.cta.feature_charts", defaultValue: "Natal Charts"))
                        featureRow(icon: "lightbulb.fill", text: String(localized: "share.cta.feature_insights", defaultValue: "Deep Insights"))
                        featureRow(icon: "person.fill", text: String(localized: "share.cta.feature_personalized", defaultValue: "Personalized"))
                    }
                    .padding(.vertical, 16)
                    
                    // CTA button
                    VStack(spacing: 14) {
                        Text(String(localized: "carousel.cta.button", defaultValue: "Download on App Store"))
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [ZoryaBranding.accentGold, ZoryaBranding.accentGold.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.app.fill")
                                .font(.system(size: 20, weight: .medium))
                            Text(ZoryaBranding.appStoreURL)
                                .font(.system(size: 24, weight: .semibold))
                        }
                        .foregroundStyle(ZoryaBranding.textSecondary)
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text(ZoryaBranding.watermark)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ZoryaBranding.textTertiary)
                    
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index == 4 ? ZoryaBranding.accentGold : ZoryaBranding.textTertiary.opacity(0.5))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 1080, height: 1080)
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(ZoryaBranding.accentGold)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Shared Footer

private func slideFooter(pageNumber: Int) -> some View {
    VStack(spacing: 8) {
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
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(ZoryaBranding.textSecondary)
        }
        
        // Page indicator
        HStack(spacing: 6) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index == pageNumber - 1 ? ZoryaBranding.accentGold : ZoryaBranding.textTertiary.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Previews

#Preview("Carousel - Cover") {
    CarouselCoverSlide(
        birthDetails: BirthDetails(
            name: "Олександра",
            birthDate: Date(),
            birthTime: Date(),
            location: "Київ, Україна"
        ),
        chartImage: nil,
        reportArea: .career,
        shareContent: .preview
    )
    .frame(width: 1080, height: 1080)
    .scaleEffect(0.4)
}

#Preview("Carousel - Influences") {
    CarouselInfluencesSlide(shareContent: .preview)
        .frame(width: 1080, height: 1080)
        .scaleEffect(0.4)
}

#Preview("Carousel - Recommendations") {
    CarouselRecommendationsSlide(shareContent: .preview)
        .frame(width: 1080, height: 1080)
        .scaleEffect(0.4)
}

#Preview("Carousel - Analysis") {
    CarouselAnalysisSlide(shareContent: .preview)
        .frame(width: 1080, height: 1080)
        .scaleEffect(0.4)
}

#Preview("Carousel - CTA") {
    CarouselCTASlide()
        .frame(width: 1080, height: 1080)
        .scaleEffect(0.4)
}
