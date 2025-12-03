# AI Prompt Contract: Share Content Generation

**Feature**: 006-instagram-share-templates  
**Date**: November 30, 2024  
**Version**: 1.0

## Overview

This contract defines the AI prompt extension for generating social media-optimized share content alongside the main astrological report. The `shareContent` object is generated in the same API call as the main report.

---

## Prompt Extension

Add the following to the existing report generation system prompt:

```text
## Social Share Content

Additionally, generate a "shareContent" object optimized for Instagram sharing.
This content must be in the same language as the main report.

Requirements:
- condensedSummary: A compelling, shareable summary (MAXIMUM 280 characters)
  - Hook the reader in the first line
  - Include key insight and call to curiosity
  - End with intrigue or empowerment

- topInfluences: Exactly 3 items (MAXIMUM 40 characters each)
  - Format: "[Planet emoji] Planet in Sign: Brief insight"
  - Use planetary emojis: ☉ (Sun), ☽ (Moon), ☿ (Mercury), ♀ (Venus), ♂ (Mars), ♃ (Jupiter), ♄ (Saturn), ♅ (Uranus), ♆ (Neptune), ♇ (Pluto)
  - Focus on the 3 most significant placements

- topRecommendations: Exactly 3 items (MAXIMUM 60 characters each)
  - Start with an action verb
  - Make them inspiring and actionable
  - Prioritize the most impactful advice

- analysisHighlights: 3-4 items (MAXIMUM 50 characters each)
  - Key personality traits or life themes
  - Use positive, empowering language
  - Suitable for bullet-point display
```

---

## JSON Schema

### Request (no change to existing)

The share content is generated with the existing report request. No additional parameters needed.

### Response Schema Extension

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "keyInfluences": { "type": "array" },
    "detailedAnalysis": { "type": "string" },
    "recommendations": { "type": "array" },
    "knowledgeUsage": { "type": "object" },
    "shareContent": {
      "type": "object",
      "required": ["condensedSummary", "topInfluences", "topRecommendations", "analysisHighlights"],
      "properties": {
        "condensedSummary": {
          "type": "string",
          "maxLength": 280,
          "description": "Compelling summary for Instagram (max 280 chars)"
        },
        "topInfluences": {
          "type": "array",
          "items": {
            "type": "string",
            "maxLength": 40
          },
          "minItems": 3,
          "maxItems": 3,
          "description": "Top 3 planetary influences"
        },
        "topRecommendations": {
          "type": "array",
          "items": {
            "type": "string",
            "maxLength": 60
          },
          "minItems": 3,
          "maxItems": 3,
          "description": "Top 3 recommendations"
        },
        "analysisHighlights": {
          "type": "array",
          "items": {
            "type": "string",
            "maxLength": 50
          },
          "minItems": 3,
          "maxItems": 4,
          "description": "Key analysis bullet points"
        }
      }
    }
  },
  "required": ["summary", "keyInfluences", "detailedAnalysis", "recommendations", "knowledgeUsage", "shareContent"]
}
```

---

## Example Response

### English

```json
{
  "shareContent": {
    "condensedSummary": "Your chart reveals powerful leadership energy with Sun in Aries ♈️ Deep emotional intelligence from Moon in Cancer balances your bold initiative. A time of growth and transformation awaits. ✨",
    "topInfluences": [
      "☉ Sun in Aries: Bold initiative",
      "☽ Moon in Cancer: Deep intuition",
      "♀ Venus in Taurus: Loyal love"
    ],
    "topRecommendations": [
      "Embrace new beginnings with unwavering confidence",
      "Trust your emotional instincts in decisions",
      "Invest time in stable, meaningful relationships"
    ],
    "analysisHighlights": [
      "Natural leadership abilities",
      "Strong emotional intelligence",
      "Creative problem-solving skills",
      "Deep loyalty in relationships"
    ]
  }
}
```

### Ukrainian

```json
{
  "shareContent": {
    "condensedSummary": "Ваша карта розкриває потужну енергію лідерства з Сонцем в Овні ♈️ Глибокий емоційний інтелект Місяця в Раку врівноважує вашу сміливу ініціативу. Час росту та трансформації чекає. ✨",
    "topInfluences": [
      "☉ Сонце в Овні: Смілива ініціатива",
      "☽ Місяць в Раку: Глибока інтуїція",
      "♀ Венера в Тільці: Вірне кохання"
    ],
    "topRecommendations": [
      "Приймайте нові початки з непохитною впевненістю",
      "Довіряйте своїм емоційним інстинктам",
      "Інвестуйте час у стабільні стосунки"
    ],
    "analysisHighlights": [
      "Природні лідерські здібності",
      "Сильний емоційний інтелект",
      "Творчий підхід до проблем",
      "Глибока відданість у стосунках"
    ]
  }
}
```

---

## Validation Rules

### Client-Side Validation

```swift
struct ShareContentValidator {
    static func validate(_ content: ShareContent) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if content.condensedSummary.isEmpty {
            errors.append(.emptyField("condensedSummary"))
        }
        if content.condensedSummary.count > 280 {
            errors.append(.exceedsLength("condensedSummary", max: 280, actual: content.condensedSummary.count))
        }
        
        if content.topInfluences.count != 3 {
            errors.append(.invalidCount("topInfluences", expected: 3, actual: content.topInfluences.count))
        }
        for (index, influence) in content.topInfluences.enumerated() {
            if influence.count > 40 {
                errors.append(.exceedsLength("topInfluences[\(index)]", max: 40, actual: influence.count))
            }
        }
        
        if content.topRecommendations.count != 3 {
            errors.append(.invalidCount("topRecommendations", expected: 3, actual: content.topRecommendations.count))
        }
        for (index, rec) in content.topRecommendations.enumerated() {
            if rec.count > 60 {
                errors.append(.exceedsLength("topRecommendations[\(index)]", max: 60, actual: rec.count))
            }
        }
        
        if content.analysisHighlights.count < 3 || content.analysisHighlights.count > 4 {
            errors.append(.invalidCount("analysisHighlights", expected: "3-4", actual: content.analysisHighlights.count))
        }
        for (index, highlight) in content.analysisHighlights.enumerated() {
            if highlight.count > 50 {
                errors.append(.exceedsLength("analysisHighlights[\(index)]", max: 50, actual: highlight.count))
            }
        }
        
        return errors
    }
}
```

### Error Handling

If validation fails after API response:
1. Log validation error to Sentry with field details
2. Attempt truncation for length violations
3. If structural issues (missing fields, wrong count), set `shareContent = nil`
4. UI shows "Share unavailable" gracefully

---

## Truncation Fallback

For minor length violations, apply smart truncation:

```swift
extension String {
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

extension ShareContent {
    func sanitized() -> ShareContent {
        ShareContent(
            condensedSummary: condensedSummary.truncatedForShare(maxLength: 280),
            topInfluences: topInfluences.map { $0.truncatedForShare(maxLength: 40) },
            topRecommendations: topRecommendations.map { $0.truncatedForShare(maxLength: 60) },
            analysisHighlights: analysisHighlights.map { $0.truncatedForShare(maxLength: 50) }
        )
    }
}
```

---

## Testing Contract

### Unit Test Cases

```swift
@Test func testShareContentDecoding() async throws {
    let json = """
    {
      "condensedSummary": "Test summary",
      "topInfluences": ["☉ Sun: Test", "☽ Moon: Test", "♀ Venus: Test"],
      "topRecommendations": ["Rec 1", "Rec 2", "Rec 3"],
      "analysisHighlights": ["Point 1", "Point 2", "Point 3"]
    }
    """
    
    let content = try JSONDecoder().decode(ShareContent.self, from: json.data(using: .utf8)!)
    #expect(content.topInfluences.count == 3)
    #expect(content.topRecommendations.count == 3)
    #expect(content.analysisHighlights.count == 3)
}

@Test func testShareContentValidation() {
    let validContent = ShareContent.preview
    let errors = ShareContentValidator.validate(validContent)
    #expect(errors.isEmpty)
}

@Test func testShareContentTruncation() {
    let longSummary = String(repeating: "A", count: 300)
    let truncated = longSummary.truncatedForShare(maxLength: 280)
    #expect(truncated.count == 280)
    #expect(truncated.hasSuffix("…"))
}
```

---

## Integration Notes

### Prompt Injection Location

The share content prompt extension should be added at the end of the existing system prompt, before any JSON schema definition.

### Token Budget

Estimated additional tokens:
- Prompt extension: ~150 tokens
- Response shareContent: ~200 tokens
- Total overhead: ~350 tokens (within acceptable budget)

### Backward Compatibility

Reports generated before this feature:
- Will have `shareContent: null` in response
- Decode as `shareContent = nil` on client
- Share feature shows "unavailable" state

---

**Contract Status**: ✅ **COMPLETE**

**Integration Point**: Report generation AI prompt in `ReportGenerationService`
