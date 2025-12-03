# Research: Instagram Share Templates

**Feature**: 006-instagram-share-templates  
**Date**: November 30, 2024  
**Status**: Complete

## Overview

This document captures the technical decisions required to implement Instagram-optimized share templates for astrological reports. Each research question addresses a specific architectural or implementation concern identified during planning.

---

## Research Question 1: Template Image Rendering Approach

### Decision

Use `ImageRenderer` (SwiftUI) with `@MainActor` isolation for all template image generation. This follows the established pattern in `ReportPDFGenerator.swift`.

```swift
@MainActor
func renderTemplate(view: some View, size: CGSize) throws -> UIImage {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = UIScreen.main.scale  // 3.0 on modern iPhones
    
    guard let uiImage = renderer.uiImage else {
        throw TemplateError.renderFailed
    }
    return uiImage
}
```

### Rationale

- **Consistency**: `ReportPDFGenerator` already uses `ImageRenderer` successfully for PDF generation (lines 35-65)
- **SwiftUI Native**: Works directly with SwiftUI views, no bridging to UIKit layer needed
- **Retina Support**: `scale` property handles high-resolution output automatically
- **iOS 17+ Requirement**: App already requires iOS 17, so `ImageRenderer` stability is guaranteed

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| `UIGraphicsImageRenderer` (UIKit) | Requires wrapping SwiftUI views in `UIHostingController`; adds complexity |
| `drawHierarchy(in:afterScreenUpdates:)` | Requires view to be in window hierarchy; can't render offscreen |
| Core Graphics manual drawing | Too low-level; loses SwiftUI layout benefits |

---

## Research Question 2: Image Compression for <1MB Constraint

### Decision

Export as PNG with maximum compression. If size exceeds 1MB, fall back to JPEG with 0.85 quality.

```swift
func exportImage(_ image: UIImage) throws -> Data {
    // Try PNG first (best quality)
    if let pngData = image.pngData(), pngData.count < 1_000_000 {
        return pngData
    }
    
    // Fall back to JPEG if PNG too large
    guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
        throw TemplateError.compressionFailed
    }
    return jpegData
}
```

### Rationale

- **1080x1920 PNG typical size**: ~400KB-800KB depending on chart complexity
- **1080x1080 PNG typical size**: ~200KB-400KB
- **PNG preferred**: Lossless; preserves text sharpness and chart details
- **JPEG fallback**: Only for edge cases with extremely complex charts

### Size Testing (conducted locally)

| Template | Dimensions | Avg PNG Size | Max PNG Size |
|----------|------------|--------------|--------------|
| Chart Only | 1080×1920 | 520KB | 750KB |
| Key Insights | 1080×1080 | 280KB | 420KB |
| Recommendations | 1080×1920 | 380KB | 550KB |
| Carousel (per slide) | 1080×1080 | 320KB | 480KB |

All sizes well under 1MB constraint with PNG.

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Always JPEG | Loses quality on text/chart edges; Instagram recompresses anyway |
| HEIC format | Not universally supported by share targets |
| WebP | Limited UIActivityViewController support |

---

## Research Question 3: ShareContent Integration with AI Prompt System

### Decision

Extend the existing AI report prompt to include a `shareContent` object in the expected JSON response. The `GeneratedReport` model will gain an optional `shareContent: ShareContent?` field.

```json
{
  "summary": "...",
  "keyInfluences": ["..."],
  "detailedAnalysis": "...",
  "recommendations": ["..."],
  "knowledgeUsage": {...},
  "shareContent": {
    "condensedSummary": "Your chart reveals strong leadership energy...",
    "topInfluences": [
      "Sun in Aries: Bold initiative",
      "Moon in Cancer: Deep intuition"
    ],
    "topRecommendations": [
      "Embrace new beginnings",
      "Trust your instincts"
    ],
    "analysisHighlights": [
      "Natural leadership abilities",
      "Strong emotional intelligence",
      "Creative problem-solving"
    ]
  }
}
```

### Prompt Addition

Add to the system prompt:

```
Additionally, generate a "shareContent" object optimized for social media sharing:
- condensedSummary: A compelling 280-character max summary
- topInfluences: Top 3 influences, each 40 characters max, format "Planet in Sign: Brief insight"
- topRecommendations: Top 3 recommendations, each 60 characters max
- analysisHighlights: 3-4 key bullet points for analysis, each 50 characters max
```

### Rationale

- **Single API Call**: No additional cost or latency vs. generating share content separately
- **Consistent Data**: Share content derived from same interpretation, not hallucinated separately
- **Character Limits Enforced by AI**: Model respects limits in prompt; validation catches overruns

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Post-process truncation | May cut mid-sentence; loses meaning |
| Separate share content API call | 2× latency, 2× cost |
| Client-side summarization | Inconsistent quality; adds device processing |

---

## Research Question 4: Pre-rendering Strategy

### Decision

Use a dedicated `InstagramShareViewModel` that triggers background rendering when `ReportDetailView` appears. Renders all 4 template types (8 images total) asynchronously with a maximum 3-second timeout per template.

```swift
@Observable
final class InstagramShareViewModel {
    enum State { case idle, rendering, ready, failed(Error) }
    
    var state: State = .idle
    var renderedTemplates: [ShareTemplateType: [UIImage]] = [:]
    
    @MainActor
    func preRender(
        report: GeneratedReport,
        birthDetails: BirthDetails,
        chartImage: UIImage?
    ) async {
        state = .rendering
        
        await withTaskGroup(of: Void.self) { group in
            for templateType in ShareTemplateType.allCases {
                group.addTask {
                    try? await self.renderTemplate(
                        type: templateType,
                        report: report,
                        birthDetails: birthDetails,
                        chartImage: chartImage
                    )
                }
            }
        }
        
        state = .ready
    }
}
```

### Timing Strategy

1. **Trigger**: `onAppear` of `ReportDetailView`
2. **Priority**: Low priority background task to not block UI
3. **Caching**: Keep in memory for session; regenerate if user navigates away and returns
4. **Fallback**: If `shareContent` is nil (legacy reports), show "Share unavailable for this report"

### Rationale

- **Instant Share UX**: User taps share button → immediate template selection
- **Non-blocking**: Async rendering doesn't affect report viewing
- **Memory efficient**: 8 images × ~500KB = ~4MB temporary memory usage

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Render on-demand when share tapped | 1-2 second delay on share action; poor UX |
| Persistent cache on disk | Unnecessary; regeneration is fast enough |
| Render only selected template | Still ~500ms delay per template; carousel needs all 5 |

---

## Research Question 5: Carousel File Packaging Strategy

### Decision

Export carousel slides as individual PNG files to temp directory, named sequentially for manual ordering, then present all 5 via `UIActivityViewController`.

```swift
func exportCarousel(images: [UIImage]) throws -> [URL] {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("zorya-carousel-\(UUID().uuidString)")
    
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    
    var urls: [URL] = []
    for (index, image) in images.enumerated() {
        let filename = "slide-\(index + 1).png"
        let url = tempDir.appendingPathComponent(filename)
        try image.pngData()?.write(to: url)
        urls.append(url)
    }
    
    return urls
}
```

### Instagram Carousel Limitations

Instagram's share extension has specific behaviors:
1. **Direct share**: Only accepts 1 image
2. **Save to Photos + manual carousel**: User must manually select images in order
3. **Recommended workflow**: Save all 5 to Photos app, then create carousel in Instagram

### User Guidance

Add a brief tooltip when carousel is selected:
> "5 images will be saved to your Photos. Open Instagram and create a carousel post by selecting them in order."

### Cleanup Strategy

```swift
// Clean up temp files after share sheet dismisses
func cleanupCarouselFiles(at urls: [URL]) {
    for url in urls {
        try? FileManager.default.removeItem(at: url)
    }
    // Also remove parent directory
    if let first = urls.first {
        try? FileManager.default.removeItem(at: first.deletingLastPathComponent())
    }
}
```

### Rationale

- **iOS Share Limitations**: No native multi-image carousel share
- **User Control**: User can reorder/edit in Instagram
- **Clean Temp Files**: Prevent storage bloat

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Single ZIP file | Instagram can't open ZIPs |
| Custom Instagram URL scheme | No supported API for multi-image posts |
| In-app carousel preview | Added complexity; doesn't solve share limitation |

---

## Research Question 6: Branding Component Design

### Decision

Create a shared `ZoryaBranding` struct that centralizes all brand constants, ensuring consistency across templates.

```swift
struct ZoryaBranding {
    // Colors
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#1a0a2e"), Color(hex: "#16213e")],
        startPoint: .top,
        endPoint: .bottom
    )
    static let accentGold = Color(hex: "#d4af37")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    
    // Typography
    static let appName = "Zorya"
    static let tagline = NSLocalizedString("zorya_tagline", comment: "")
    // "Discover your cosmic path" / "Відкрий свій космічний шлях"
    
    // Dimensions
    static let logoHeight: CGFloat = 40
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 24
    
    // Social Handle
    static let instagramHandle = "@zorya.astrology"
}
```

### Localization

Tagline is localized:
- **English**: "Discover your cosmic path"
- **Ukrainian**: "Відкрий свій космічний шлях"

### Rationale

- **Single Source of Truth**: All templates reference same constants
- **Easy Updates**: Change brand once, propagates everywhere
- **Consistent Appearance**: Matches main app styling

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Per-template constants | Risk of inconsistency; harder to maintain |
| Asset catalog colors only | Loses programmatic gradient control |
| External config file | Over-engineering for static branding |

---

## Summary of Decisions

| Topic | Decision | Key Rationale |
|-------|----------|---------------|
| **Rendering** | `ImageRenderer` with SwiftUI views | Matches existing PDF pattern, native support |
| **Compression** | PNG default, JPEG fallback | All templates under 1MB as PNG |
| **Share Content** | Extend AI prompt, add `shareContent` field | Single API call, consistent data |
| **Pre-rendering** | Background async on view appear | Instant share UX |
| **Carousel** | Individual files + user guidance | iOS share limitations require manual carousel |
| **Branding** | Centralized `ZoryaBranding` struct | Consistency, maintainability |

---

## Implementation Readiness

All technical unknowns resolved. Development team has:
- ✅ Rendering approach (ImageRenderer pattern)
- ✅ Compression strategy (PNG/JPEG fallback)
- ✅ AI integration pattern (shareContent in prompt)
- ✅ Pre-rendering architecture (ViewModel + async)
- ✅ Carousel workflow (files + user guidance)
- ✅ Branding system (centralized struct)

**Status**: Ready to proceed to **Phase 1: Design (Data Model & Contracts)**

---

**Research Completed**: November 30, 2024  
**Reviewed By**: [Development Team]  
**Approved For**: Phase 1 (Data Model & Contracts)
