// Feature: 006-instagram-share-templates
// Description: 5-slide Carousel templates for Instagram Post (1080x1080 each)

import SwiftUI
import UIKit

// MARK: - Carousel Cover Slide

/// Slide 0: Cover with natal chart and user info
struct CarouselCoverSlide: View {
    let birthDetails: BirthDetails
    let chartImage: UIImage?
    let reportArea: ReportArea
    
    var body: some View {
        ZStack {
            ZoryaBranding.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    // Report area badge
                    HStack(spacing: 8) {
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
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(ZoryaBranding.textPrimary)
                        .lineLimit(1)
                }
                .padding(.top, 48)
                
                Spacer()
                
                // Chart image
                chartView
                
                Spacer()
                
                // Swipe indicator
                VStack(spacing: 8) {
                    Text("Swipe for insights", comment: "Carousel hint")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(ZoryaBranding.textSecondary)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, ZoryaBranding.templatePadding)
        }
        .frame(width: 1080, height: 1080)
    }
    
    @ViewBuilder
    private var chartView: some View {
        if let image = chartImage {
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold.opacity(0.1))
                    .frame(width: 520, height: 520)
                    .blur(radius: 20)
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 480, height: 480)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(ZoryaBranding.accentGold.opacity(0.4), lineWidth: 2)
                    )
            }
        } else {
            ZStack {
                Circle()
                    .fill(ZoryaBranding.cardBackground)
                    .frame(width: 480, height: 480)
                
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(ZoryaBranding.accentGold.opacity(0.5))
            }
            .overlay(
                Circle()
                    .strokeBorder(ZoryaBranding.borderColor, lineWidth: 2)
                    .frame(width: 480, height: 480)
            )
        }
    }
}

// MARK: - Carousel Influences Slide

/// Slide 1: Key planetary influences
struct CarouselInfluencesSlide: View {
    let shareContent: ShareContent
    
    var body: some View {
        ZStack {
            ZoryaBranding.primaryGradient
                .ignoresSafeArea()
            
            // Decorative glow
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 600, height: 600)
                .blur(radius: 100)
                .offset(x: -200, y: -200)
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                    
                    Text("Key Influences", comment: "Slide title")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(ZoryaBranding.textPrimary)
                }
                .padding(.top, 48)
                
                Spacer()
                
                // Influences list
                VStack(spacing: 20) {
                    ForEach(Array(shareContent.topInfluences.enumerated()), id: \.offset) { index, influence in
                        influenceRow(influence)
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
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, ZoryaBranding.templatePadding)
        }
        .frame(width: 1080, height: 1080)
    }
    
    private func influenceRow(_ text: String) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.3))
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

// MARK: - Carousel Recommendations Slide

/// Slide 2: Top recommendations
struct CarouselRecommendationsSlide: View {
    let shareContent: ShareContent
    
    var body: some View {
        ZStack {
            ZoryaBranding.primaryGradient
                .ignoresSafeArea()
            
            // Decorative glow
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.08))
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(x: 200, y: 200)
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                    
                    Text("Recommendations", comment: "Slide title")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(ZoryaBranding.textPrimary)
                }
                .padding(.top, 48)
                
                Spacer()
                
                // Recommendations list
                VStack(spacing: 16) {
                    ForEach(Array(shareContent.topRecommendations.enumerated()), id: \.offset) { index, recommendation in
                        recommendationRow(recommendation, index: index)
                    }
                }
                
                Spacer()
                
                // Footer
                slideFooter(pageNumber: 3)
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, ZoryaBranding.templatePadding)
        }
        .frame(width: 1080, height: 1080)
    }
    
    private func recommendationRow(_ text: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(ZoryaBranding.accentGold)
                    .frame(width: 40, height: 40)
                
                Text("\(index + 1)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Text(text)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(ZoryaBranding.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ZoryaBranding.cornerRadius, style: .continuous))
    }
}

// MARK: - Carousel Analysis Slide

/// Slide 3: Detailed analysis highlights
struct CarouselAnalysisSlide: View {
    let shareContent: ShareContent
    
    var body: some View {
        ZStack {
            ZoryaBranding.primaryGradient
                .ignoresSafeArea()
            
            // Decorative glow
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 600, height: 600)
                .blur(radius: 100)
                .offset(x: -100, y: 300)
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(ZoryaBranding.accentGold)
                    
                    Text("Analysis", comment: "Slide title")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(ZoryaBranding.textPrimary)
                }
                .padding(.top, 48)
                
                Spacer()
                
                // Analysis highlights
                VStack(alignment: .leading, spacing: 24) {
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
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, ZoryaBranding.templatePadding)
        }
        .frame(width: 1080, height: 1080)
    }
    
    private func analysisRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(ZoryaBranding.accentGold)
            
            Text(text)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(ZoryaBranding.textPrimary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

// MARK: - Carousel CTA Slide

/// Slide 4: Call to action with app promo
struct CarouselCTASlide: View {
    var body: some View {
        ZStack {
            ZoryaBranding.primaryGradient
                .ignoresSafeArea()
            
            // Decorative glows
            Circle()
                .fill(ZoryaBranding.accentGold.opacity(0.15))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(y: -200)
            
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(y: 300)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Main CTA content
                VStack(spacing: 28) {
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
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    
                    // App name and tagline
                    VStack(spacing: 12) {
                        Text(ZoryaBranding.appName)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(ZoryaBranding.textPrimary)
                        
                        Text(ZoryaBranding.tagline)
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundStyle(ZoryaBranding.textSecondary)
                    }
                    
                    // CTA button
                    VStack(spacing: 16) {
                        Text("Get Your Report", comment: "CTA button text")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [ZoryaBranding.accentGold, ZoryaBranding.accentGold.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                        
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.system(size: 22, weight: .medium))
                            Text(ZoryaBranding.websiteDisplay)
                                .font(.system(size: 26, weight: .semibold))
                        }
                        .foregroundStyle(ZoryaBranding.textSecondary)
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text(ZoryaBranding.watermark)
                        .font(.system(size: 18, weight: .medium))
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
                .padding(.bottom, 48)
            }
            .padding(.horizontal, ZoryaBranding.templatePadding)
        }
        .frame(width: 1080, height: 1080)
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
        reportArea: .career
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
