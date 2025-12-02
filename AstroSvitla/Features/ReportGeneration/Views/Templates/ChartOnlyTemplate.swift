// Feature: 006-instagram-share-templates
// Description: Chart Only template for Instagram Stories (1080x1920)

import SwiftUI
import UIKit

// MARK: - ChartOnlyTemplate

/// Instagram Stories template showing the natal chart with birth details
/// Dimensions: 1080 x 1920 pixels (9:16 aspect ratio)
struct ChartOnlyTemplate: View {
    let birthDetails: BirthDetails
    let chartImage: UIImage?
    
    var body: some View {
        ZStack {
            // Background gradient
            ZoryaBranding.primaryGradient
                .ignoresSafeArea()
            
            // Content overlay
            VStack(spacing: 0) {
                // Top section with user info
                topSection
                    .padding(.top, ZoryaBranding.templatePadding)
                    .padding(.horizontal, ZoryaBranding.templatePadding)
                
                Spacer()
                
                // Chart section
                chartSection
                    .padding(.horizontal, ZoryaBranding.templatePadding)
                
                Spacer()
                
                // Bottom section with branding
                bottomSection
                    .padding(.bottom, ZoryaBranding.templatePadding)
                    .padding(.horizontal, ZoryaBranding.templatePadding)
            }
        }
        .frame(width: 1080, height: 1920)
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
                        .frame(width: 780, height: 780)
                        .blur(radius: 30)
                    
                    // Chart image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 720, height: 720)
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
                // Placeholder when no chart image
                placeholderChart
            }
        }
    }
    
    private var placeholderChart: some View {
        ZStack {
            Circle()
                .fill(ZoryaBranding.cardBackground)
                .frame(width: 720, height: 720)
            
            VStack(spacing: 16) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(ZoryaBranding.accentGold.opacity(0.5))
                
                Text("Your Natal Chart", comment: "Placeholder text")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(ZoryaBranding.textSecondary)
            }
        }
        .overlay(
            Circle()
                .strokeBorder(ZoryaBranding.borderColor, lineWidth: 2)
                .frame(width: 720, height: 720)
        )
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 24) {
            // Decorative line
            Rectangle()
                .fill(ZoryaBranding.accentGold.opacity(0.3))
                .frame(width: 200, height: 2)
            
            // Branding footer
            ZoryaBranding.footer()
            
            // Website CTA
            ZoryaBranding.websiteCTA()
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
        chartImage: nil
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
        chartImage: nil
    )
    .frame(width: 1080, height: 1920)
    .scaleEffect(0.3)
}
