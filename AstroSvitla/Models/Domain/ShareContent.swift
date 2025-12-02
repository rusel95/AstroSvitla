// Feature: 006-instagram-share-templates
// Description: Models for Instagram share template feature

import Foundation
import UIKit
import SwiftUI

// MARK: - ShareContent

/// AI-generated content optimized for social media sharing, with strict character limits.
struct ShareContent: Codable, Sendable, Equatable {
    
    /// Compelling summary for sharing (max 280 characters)
    let condensedSummary: String
    
    /// Top 3 planetary influences (each max 40 characters)
    /// Format: "Planet in Sign: Brief insight"
    let topInfluences: [String]
    
    /// Top 3 recommendations (each max 60 characters)
    let topRecommendations: [String]
    
    /// Key analysis highlights (3-4 items, each max 50 characters)
    let analysisHighlights: [String]
    
    // MARK: - Validation
    
    /// Validates that all content meets character limits
    var isValid: Bool {
        condensedSummary.count <= 280 &&
        condensedSummary.count > 0 &&
        topInfluences.count == 3 &&
        topInfluences.allSatisfy { $0.count <= 40 && $0.count > 0 } &&
        topRecommendations.count == 3 &&
        topRecommendations.allSatisfy { $0.count <= 60 && $0.count > 0 } &&
        (3...4).contains(analysisHighlights.count) &&
        analysisHighlights.allSatisfy { $0.count <= 50 && $0.count > 0 }
    }
    
    // MARK: - Sanitization
    
    /// Returns a sanitized version with content truncated to fit limits
    func sanitized() -> ShareContent {
        ShareContent(
            condensedSummary: condensedSummary.truncatedForShare(maxLength: 280),
            topInfluences: topInfluences.map { $0.truncatedForShare(maxLength: 40) },
            topRecommendations: topRecommendations.map { $0.truncatedForShare(maxLength: 60) },
            analysisHighlights: analysisHighlights.map { $0.truncatedForShare(maxLength: 50) }
        )
    }
}

// MARK: - ShareContent Preview Fixtures

extension ShareContent {
    
    /// Sample content for SwiftUI previews
    static var preview: ShareContent {
        ShareContent(
            condensedSummary: "Your chart reveals powerful leadership energy with Sun in Aries. Deep emotional intelligence from Moon in Cancer balances your bold initiative.",
            topInfluences: [
                "☉ Sun in Aries: Bold initiative",
                "☽ Moon in Cancer: Deep intuition",
                "♀ Venus in Taurus: Loyal love"
            ],
            topRecommendations: [
                "Embrace new beginnings with confidence",
                "Trust your emotional instincts",
                "Invest in stable relationships"
            ],
            analysisHighlights: [
                "Natural leadership abilities",
                "Strong emotional intelligence",
                "Creative problem-solving skills"
            ]
        )
    }
    
    /// Ukrainian content for locale testing
    static var ukrainianPreview: ShareContent {
        ShareContent(
            condensedSummary: "Ваша карта розкриває потужну енергію лідерства з Сонцем в Овні. Глибокий емоційний інтелект Місяця в Раку врівноважує вашу сміливу ініціативу.",
            topInfluences: [
                "☉ Сонце в Овні: Смілива ініціатива",
                "☽ Місяць в Раку: Глибока інтуїція",
                "♀ Венера в Тільці: Вірне кохання"
            ],
            topRecommendations: [
                "Приймайте нові початки з впевненістю",
                "Довіряйте своїм емоційним інстинктам",
                "Інвестуйте час у стабільні стосунки"
            ],
            analysisHighlights: [
                "Природні лідерські здібності",
                "Сильний емоційний інтелект",
                "Творчий підхід до проблем"
            ]
        )
    }
    
    /// Content at maximum character limits for boundary testing
    static var maxLengthPreview: ShareContent {
        ShareContent(
            condensedSummary: String(repeating: "A", count: 280),
            topInfluences: Array(repeating: String(repeating: "B", count: 40), count: 3),
            topRecommendations: Array(repeating: String(repeating: "C", count: 60), count: 3),
            analysisHighlights: Array(repeating: String(repeating: "D", count: 50), count: 4)
        )
    }
}

// MARK: - ShareTemplateType

/// Available Instagram template formats
enum ShareTemplateType: String, CaseIterable, Identifiable, Sendable {
    case chartOnly = "chart_only"
    case keyInsights = "key_insights"
    case recommendations = "recommendations"
    case carousel = "carousel"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .chartOnly:
            return String(localized: "share_template_chart_only", defaultValue: "Chart Only")
        case .keyInsights:
            return String(localized: "share_template_key_insights", defaultValue: "Key Insights")
        case .recommendations:
            return String(localized: "share_template_recommendations", defaultValue: "Recommendations")
        case .carousel:
            return String(localized: "share_template_carousel", defaultValue: "Full Carousel")
        }
    }
    
    /// Template dimensions in pixels
    var dimensions: CGSize {
        switch self {
        case .chartOnly, .recommendations:
            return CGSize(width: 1080, height: 1920)  // 9:16 Stories
        case .keyInsights:
            return CGSize(width: 1080, height: 1080)  // 1:1 Post
        case .carousel:
            return CGSize(width: 1080, height: 1080)  // 1:1 per slide
        }
    }
    
    /// Number of images this template generates
    var imageCount: Int {
        switch self {
        case .chartOnly, .keyInsights, .recommendations:
            return 1
        case .carousel:
            return 5  // Cover, Influences, Recommendations, Analysis, CTA
        }
    }
    
    /// SF Symbol icon for template picker
    var icon: String {
        switch self {
        case .chartOnly:
            return "chart.pie"
        case .keyInsights:
            return "sparkles"
        case .recommendations:
            return "lightbulb"
        case .carousel:
            return "rectangle.stack"
        }
    }
    
    /// Brief description for template picker
    var description: String {
        switch self {
        case .chartOnly:
            return String(localized: "share_desc_chart_only", defaultValue: "Your natal chart as a story")
        case .keyInsights:
            return String(localized: "share_desc_key_insights", defaultValue: "Top 3 planetary influences")
        case .recommendations:
            return String(localized: "share_desc_recommendations", defaultValue: "Personalized recommendations")
        case .carousel:
            return String(localized: "share_desc_carousel", defaultValue: "5-slide Instagram carousel")
        }
    }
}

// MARK: - CarouselSlideType

/// Identifies the content of each slide in a 5-slide carousel
enum CarouselSlideType: Int, CaseIterable, Identifiable, Sendable {
    case cover = 0          // Natal chart + name
    case influences = 1     // Key planetary influences
    case recommendations = 2 // Top recommendations
    case analysis = 3       // Analysis highlights
    case callToAction = 4   // App promo
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .cover:
            return String(localized: "carousel_title_cover", defaultValue: "Your Natal Chart")
        case .influences:
            return String(localized: "carousel_title_influences", defaultValue: "Key Influences")
        case .recommendations:
            return String(localized: "carousel_title_recommendations", defaultValue: "Recommendations")
        case .analysis:
            return String(localized: "carousel_title_analysis", defaultValue: "Detailed Analysis")
        case .callToAction:
            return String(localized: "carousel_title_cta", defaultValue: "Discover More")
        }
    }
}

// MARK: - GeneratedShareImage

/// Represents a rendered template image ready for sharing
struct GeneratedShareImage: Identifiable, @unchecked Sendable {
    let id: UUID
    let templateType: ShareTemplateType
    let slideIndex: Int?  // Only for carousel (0-4)
    let image: UIImage
    var fileURL: URL?
    
    init(
        id: UUID = UUID(),
        templateType: ShareTemplateType,
        slideIndex: Int? = nil,
        image: UIImage,
        fileURL: URL? = nil
    ) {
        self.id = id
        self.templateType = templateType
        self.slideIndex = slideIndex
        self.image = image
        self.fileURL = fileURL
    }
    
    /// Suggested filename for export
    var suggestedFilename: String {
        switch templateType {
        case .carousel:
            guard let index = slideIndex else { return "zorya-carousel.png" }
            return "zorya-carousel-\(index + 1).png"
        default:
            return "zorya-\(templateType.rawValue).png"
        }
    }
}

// MARK: - String Truncation Extension

private extension String {
    
    /// Truncates string for social sharing, preserving word boundaries
    func truncatedForShare(maxLength: Int) -> String {
        guard count > maxLength else { return self }
        
        let truncated = prefix(maxLength - 1)
        
        // Try to break at word boundary
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "…"
        }
        
        return String(truncated) + "…"
    }
}
