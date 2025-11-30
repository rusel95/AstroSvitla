# Data Model: Instagram Share Templates

**Feature**: 006-instagram-share-templates  
**Date**: November 30, 2024  
**Status**: Complete

## Overview

This document defines all data entities for the Instagram share templates feature. The feature introduces new models for share-optimized content and template generation while extending the existing `GeneratedReport` model.

---

## Entity Relationship Diagram

```text
┌──────────────────┐
│  GeneratedReport │
├──────────────────┤
│ id               │
│ area             │
│ summary          │
│ keyInfluences    │
│ detailedAnalysis │
│ recommendations  │
│ knowledgeUsage   │
│ ─── NEW ───      │
│ shareContent     │◄─────────┐
└──────────────────┘          │
                              │
           ┌──────────────────┘
           │
   ┌───────▼────────┐
   │  ShareContent  │
   ├────────────────┤
   │ condensedSummary│
   │ topInfluences   │
   │ topRecommendations│
   │ analysisHighlights│
   └────────────────┘


┌──────────────────┐        ┌───────────────────┐
│ ShareTemplateType│        │ GeneratedShareImage│
├──────────────────┤        ├───────────────────┤
│ .chartOnly       │───────▶│ id                │
│ .keyInsights     │        │ templateType      │
│ .recommendations │        │ imageData         │
│ .carousel        │        │ dimensions        │
└──────────────────┘        │ fileURL           │
                            └───────────────────┘
```

---

## Entity Definitions

### 1. ShareContent

**Purpose**: AI-generated content optimized for social media sharing, with strict character limits for template layouts.

**Location**: `/AstroSvitla/Models/Domain/ShareContent.swift`

#### Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `condensedSummary` | String | Required, max 280 chars | Compelling summary for Instagram post |
| `topInfluences` | [String] | Required, 3 items, each max 40 chars | Top 3 planetary influences |
| `topRecommendations` | [String] | Required, 3 items, each max 60 chars | Top 3 actionable recommendations |
| `analysisHighlights` | [String] | Required, 3-4 items, each max 50 chars | Key analysis bullet points |

#### Swift Definition

```swift
import Foundation

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
    
    var isValid: Bool {
        condensedSummary.count <= 280 &&
        topInfluences.count == 3 &&
        topInfluences.allSatisfy { $0.count <= 40 } &&
        topRecommendations.count == 3 &&
        topRecommendations.allSatisfy { $0.count <= 60 } &&
        (3...4).contains(analysisHighlights.count) &&
        analysisHighlights.allSatisfy { $0.count <= 50 }
    }
}
```

#### Validation Rules

- `condensedSummary`: Must not be empty, maximum 280 characters (Twitter-like limit)
- `topInfluences`: Exactly 3 items, each ≤40 characters
- `topRecommendations`: Exactly 3 items, each ≤60 characters
- `analysisHighlights`: 3-4 items, each ≤50 characters
- **All strings**: Must be non-empty

#### Example

```swift
ShareContent(
    condensedSummary: "Your chart reveals powerful leadership energy with Sun in Aries. Deep emotional intelligence from Moon in Cancer balances your bold initiative. Perfect time for new beginnings.",
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
        "Creative problem-solving skills",
        "Deep loyalty in relationships"
    ]
)
```

---

### 2. ShareTemplateType

**Purpose**: Enumeration of available Instagram template formats.

**Location**: `/AstroSvitla/Models/Domain/ShareContent.swift` (same file)

#### Enumeration

```swift
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
            return NSLocalizedString("share_template_chart_only", comment: "Chart Only")
        case .keyInsights:
            return NSLocalizedString("share_template_key_insights", comment: "Key Insights")
        case .recommendations:
            return NSLocalizedString("share_template_recommendations", comment: "Recommendations")
        case .carousel:
            return NSLocalizedString("share_template_carousel", comment: "Full Carousel")
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
            return NSLocalizedString("share_desc_chart_only", comment: "")
        case .keyInsights:
            return NSLocalizedString("share_desc_key_insights", comment: "")
        case .recommendations:
            return NSLocalizedString("share_desc_recommendations", comment: "")
        case .carousel:
            return NSLocalizedString("share_desc_carousel", comment: "")
        }
    }
}
```

#### Template Specifications

| Type | Dimensions | Images | Instagram Format |
|------|------------|--------|------------------|
| `chartOnly` | 1080×1920 | 1 | Story |
| `keyInsights` | 1080×1080 | 1 | Post |
| `recommendations` | 1080×1920 | 1 | Story |
| `carousel` | 1080×1080 | 5 | Carousel Post |

---

### 3. GeneratedShareImage

**Purpose**: Represents a rendered template image ready for sharing.

**Location**: `/AstroSvitla/Models/Domain/ShareContent.swift` (same file)

#### Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | UUID | Required, unique | Primary key |
| `templateType` | ShareTemplateType | Required | Which template was rendered |
| `slideIndex` | Int? | Optional, 0-4 for carousel | Index for carousel slides |
| `image` | UIImage | Required | Rendered image |
| `fileURL` | URL? | Optional | Temp file if exported |

#### Swift Definition

```swift
import UIKit

struct GeneratedShareImage: Identifiable, Sendable {
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
            guard let index = slideIndex else { return "carousel.png" }
            return "zorya-carousel-\(index + 1).png"
        default:
            return "zorya-\(templateType.rawValue).png"
        }
    }
}
```

#### Validation Rules

- `slideIndex`: Must be nil for non-carousel templates
- `slideIndex`: Must be 0-4 for carousel templates
- `image.size`: Should match `templateType.dimensions` (within 1px tolerance for rounding)

---

### 4. CarouselSlideType

**Purpose**: Identifies the content of each slide in a 5-slide carousel.

**Location**: `/AstroSvitla/Models/Domain/ShareContent.swift` (same file)

#### Enumeration

```swift
enum CarouselSlideType: Int, CaseIterable, Identifiable, Sendable {
    case cover = 0          // Natal chart + name
    case influences = 1     // Key planetary influences
    case recommendations = 2 // Top recommendations
    case analysis = 3       // Analysis highlights
    case callToAction = 4   // App promo + QR code
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .cover:
            return NSLocalizedString("carousel_title_cover", comment: "Your Natal Chart")
        case .influences:
            return NSLocalizedString("carousel_title_influences", comment: "Key Influences")
        case .recommendations:
            return NSLocalizedString("carousel_title_recommendations", comment: "Recommendations")
        case .analysis:
            return NSLocalizedString("carousel_title_analysis", comment: "Detailed Analysis")
        case .callToAction:
            return NSLocalizedString("carousel_title_cta", comment: "Discover More")
        }
    }
}
```

---

## Modified Existing Entities

### 5. GeneratedReport (Modified)

**Location**: `/AstroSvitla/Features/ReportGeneration/Models/GeneratedReport.swift`

**Changes**: Add optional `shareContent` field.

#### New Attribute

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `shareContent` | ShareContent? | Optional | Social-optimized content |

#### Updated Schema

```swift
struct GeneratedReport: Identifiable, Sendable, Codable {
    let id: UUID
    let area: ReportArea
    let summary: String
    let keyInfluences: [KeyInfluence]
    let detailedAnalysis: DetailedAnalysis
    let recommendations: [Recommendation]
    let knowledgeUsage: KnowledgeUsage
    let metadata: ReportMetadata
    
    // NEW FIELD
    var shareContent: ShareContent?
}
```

#### Backward Compatibility

- Existing reports without `shareContent`: Field is nil
- UI displays "Share unavailable" for legacy reports
- Migration: Not required; new reports will have field populated

#### JSON Decoding

```swift
extension GeneratedReport {
    enum CodingKeys: String, CodingKey {
        case id, area, summary, keyInfluences, detailedAnalysis
        case recommendations, knowledgeUsage, metadata, shareContent
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // ... existing decoding ...
        
        // Optional shareContent for backward compatibility
        shareContent = try container.decodeIfPresent(ShareContent.self, forKey: .shareContent)
    }
}
```

---

## Supporting Data Structures

### ZoryaBranding

**Purpose**: Centralized brand constants for consistent template styling.

**Location**: `/AstroSvitla/Shared/Components/ZoryaBranding.swift`

```swift
import SwiftUI

struct ZoryaBranding {
    // MARK: - Colors
    
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#1a0a2e"), Color(hex: "#16213e")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let accentGold = Color(hex: "#d4af37")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    
    // MARK: - Typography
    
    static let appName = "Zorya"
    
    static var tagline: String {
        NSLocalizedString("zorya_tagline", comment: "Discover your cosmic path")
    }
    
    // MARK: - Social
    
    static let instagramHandle = "@zorya.astrology"
    static let websiteURL = URL(string: "https://zorya.app")!
    
    // MARK: - Dimensions
    
    static let logoHeight: CGFloat = 40
    static let cornerRadius: CGFloat = 16
    static let templatePadding: CGFloat = 32
    
    // MARK: - Fonts (for templates at 1080px width)
    
    static func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    
    static let titleFont = scaledFont(size: 48, weight: .bold)
    static let headlineFont = scaledFont(size: 36, weight: .semibold)
    static let bodyFont = scaledFont(size: 28, weight: .regular)
    static let captionFont = scaledFont(size: 22, weight: .medium)
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## State Transitions

### Share Template Rendering Lifecycle

```text
┌──────────────────┐
│     Idle         │ (ReportDetailView not yet appeared)
└────────┬─────────┘
         │ onAppear
         ▼
┌──────────────────┐
│   Rendering      │ (Background async rendering)
└────────┬─────────┘
         │ all templates complete
         ▼
┌──────────────────┐
│     Ready        │ (Templates cached in memory)
└────────┬─────────┘
         │ user taps share
         ▼
┌──────────────────┐
│   Presenting     │ (Share sheet visible)
└────────┬─────────┘
         │ share complete/cancel
         ▼
┌──────────────────┐
│     Ready        │ (Return to ready state)
└──────────────────┘
```

### Error States

```text
┌──────────────────┐
│   Rendering      │
└────────┬─────────┘
         │ timeout / error
         ▼
┌──────────────────┐
│     Failed       │ (Show error message, offer retry)
└──────────────────┘
```

---

## Localization Keys

New strings to add to `Localizable.xcstrings`:

```json
{
  "zorya_tagline": {
    "en": "Discover your cosmic path",
    "uk": "Відкрий свій космічний шлях"
  },
  "share_template_chart_only": {
    "en": "Chart Only",
    "uk": "Тільки карта"
  },
  "share_template_key_insights": {
    "en": "Key Insights",
    "uk": "Ключові інсайти"
  },
  "share_template_recommendations": {
    "en": "Recommendations",
    "uk": "Рекомендації"
  },
  "share_template_carousel": {
    "en": "Full Carousel",
    "uk": "Повна карусель"
  },
  "share_desc_chart_only": {
    "en": "Your natal chart as a story",
    "uk": "Ваша натальна карта для сторіс"
  },
  "share_desc_key_insights": {
    "en": "Top 3 planetary influences",
    "uk": "Топ-3 планетарних впливів"
  },
  "share_desc_recommendations": {
    "en": "Personalized recommendations",
    "uk": "Персоналізовані рекомендації"
  },
  "share_desc_carousel": {
    "en": "5-slide Instagram carousel",
    "uk": "5-слайдова карусель Instagram"
  },
  "carousel_title_cover": {
    "en": "Your Natal Chart",
    "uk": "Ваша натальна карта"
  },
  "carousel_title_influences": {
    "en": "Key Influences",
    "uk": "Ключові впливи"
  },
  "carousel_title_recommendations": {
    "en": "Recommendations",
    "uk": "Рекомендації"
  },
  "carousel_title_analysis": {
    "en": "Detailed Analysis",
    "uk": "Детальний аналіз"
  },
  "carousel_title_cta": {
    "en": "Discover More",
    "uk": "Дізнатись більше"
  },
  "share_unavailable": {
    "en": "Share not available for this report",
    "uk": "Поділитися недоступно для цього звіту"
  },
  "share_button_title": {
    "en": "Share to Instagram",
    "uk": "Поділитися в Instagram"
  }
}
```

---

## Testing Fixtures

### Sample ShareContent

```swift
extension ShareContent {
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
    
    static var maxLengthPreview: ShareContent {
        ShareContent(
            condensedSummary: String(repeating: "A", count: 280),
            topInfluences: Array(repeating: String(repeating: "B", count: 40), count: 3),
            topRecommendations: Array(repeating: String(repeating: "C", count: 60), count: 3),
            analysisHighlights: Array(repeating: String(repeating: "D", count: 50), count: 4)
        )
    }
}
```

### Validation Tests

```swift
@Test func testShareContentValidation() {
    let validContent = ShareContent.preview
    #expect(validContent.isValid)
    
    let maxContent = ShareContent.maxLengthPreview
    #expect(maxContent.isValid)
    
    let invalidContent = ShareContent(
        condensedSummary: String(repeating: "X", count: 300),  // Over 280
        topInfluences: ["Too short"],  // Only 1
        topRecommendations: [],  // Empty
        analysisHighlights: []  // Empty
    )
    #expect(!invalidContent.isValid)
}

@Test func testShareTemplateTypeDimensions() {
    #expect(ShareTemplateType.chartOnly.dimensions == CGSize(width: 1080, height: 1920))
    #expect(ShareTemplateType.keyInsights.dimensions == CGSize(width: 1080, height: 1080))
    #expect(ShareTemplateType.carousel.imageCount == 5)
}
```

---

## Data Model Summary

| Entity | Purpose | Location | Key Attributes |
|--------|---------|----------|----------------|
| **ShareContent** | AI-generated share content | Models/Domain/ | condensedSummary, topInfluences, topRecommendations, analysisHighlights |
| **ShareTemplateType** | Template format enum | Models/Domain/ | chartOnly, keyInsights, recommendations, carousel |
| **GeneratedShareImage** | Rendered template image | Models/Domain/ | templateType, image, fileURL |
| **CarouselSlideType** | Carousel slide enum | Models/Domain/ | cover, influences, recommendations, analysis, callToAction |
| **ZoryaBranding** | Brand constants | Shared/Components/ | colors, fonts, dimensions |
| **GeneratedReport** (modified) | Add shareContent field | Features/ReportGeneration/Models/ | +shareContent: ShareContent? |

---

**Data Model Status**: ✅ **COMPLETE** - Ready for contract definition

**Next Step**: Create `contracts/share-content-prompt.md`
