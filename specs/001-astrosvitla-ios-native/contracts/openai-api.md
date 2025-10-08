# OpenAI GPT-4o API Contract

**Service**: OpenAI GPT-4o Mini
**Purpose**: Generate personalized astrology reports from natal chart data
**Integration**: Official Swift SDK (`openai/openai-swift`) or REST API via `URLSession`
**Documentation**: https://platform.openai.com/docs/api-reference

---

## API Configuration

### Base Information

| Property | Value |
|----------|-------|
| Base URL | `https://api.openai.com/v1` |
| Authentication | Bearer token (`Authorization: Bearer <OPENAI_API_KEY>`) |
| Model | `gpt-4o-mini` (default) |
| SDK Package | `openai/openai-swift` |
| Swift Package URL | `https://github.com/openai/openai-swift` |

### Environment Configuration

```swift
// Configuration.swift
enum OpenAIConfig {
    static let apiKey: String = {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fatalError("OPENAI_API_KEY not set in environment")
        }
        return key
    }()

    static let model: Model = .gpt4oMini
    static let maxOutputTokens = 800 // ~500-600 words
    static let temperature: Double = 0.7 // Creative but focused
    static let topP: Double = 0.9
}
```

---

## Request Schema

### Swift SDK Integration

```swift
import OpenAI

let client = OpenAI(apiKey: OpenAIConfig.apiKey)
let prompt = buildPrompt(chart: natalChart, area: lifeArea, language: language)

let response = try await client.responses.generate(
    model: OpenAIConfig.model,
    prompt: .init(prompt)
)

guard let text = response.outputText else {
    throw ReportGenerationError.noContent
}
```

### HTTP Request (Alternative - Direct REST)

```http
POST /v1/responses
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "model": "gpt-4o-mini",
  "input": "<PROMPT_TEXT>",
  "max_output_tokens": 800,
  "temperature": 0.7,
  "top_p": 0.9
}
```

---

## Prompt Structure

### System Context (Embedded in User Prompt)

```
You are an expert astrologer with 20+ years of experience providing personalized natal chart interpretations. You combine traditional astrological wisdom with practical, actionable guidance.

Your interpretations are:
- Specific and personalized to the individual's unique chart
- Grounded in the actual planetary positions, houses, and aspects provided
- Supportive and empowering in tone
- Focused on growth and self-awareness
- Free from generic horoscope language

<LANGUAGE_INSTRUCTION>
```

### Prompt Template

```swift
func buildPrompt(
    chart: NatalChart,
    area: ReportArea,
    language: Language
) -> String {
    let languageInstruction = language == .ukrainian ?
        "CRITICAL: Your entire response MUST be in Ukrainian language (українська мова)." :
        "CRITICAL: Your entire response MUST be in English language."

    let areaFocus = getAreaFocus(area)

    return """
    You are an expert astrologer with 20+ years of experience. Generate a personalized \(area.displayName) report.

    \(languageInstruction)

    BIRTH CHART DATA:
    Birth Date: \(formatDate(chart.birthDate))
    Birth Time: \(formatTime(chart.birthTime))
    Location: \(chart.locationName)

    PLANETARY POSITIONS:
    \(formatPlanets(chart.planets))

    HOUSES:
    Ascendant: \(chart.ascendant)° \(getZodiacSign(chart.ascendant))
    Midheaven: \(chart.midheaven)° \(getZodiacSign(chart.midheaven))
    \(formatHouses(chart.houses))

    KEY ASPECTS:
    \(formatAspects(chart.aspects))

    REPORT FOCUS: \(areaFocus)

    REQUIREMENTS:
    - Length: 400-500 words
    - Structure: 3 sections
      1. Key Influences (2-3 sentences about dominant factors)
      2. Detailed Analysis (350-400 words specific to \(area.displayName))
      3. Practical Recommendations (3-4 actionable tips)
    - Be specific to THIS chart (reference actual placements)
    - Avoid generic statements that could apply to anyone
    - Supportive and empowering tone
    - Focus on growth potential and self-awareness

    Generate the report now:
    """
}
```

### Area-Specific Focus

```swift
func getAreaFocus(_ area: ReportArea) -> String {
    switch area {
    case .finances:
        return "Financial patterns, earning potential, wealth accumulation, money management style, financial opportunities and challenges based on 2nd house, 8th house, Jupiter, Saturn, Venus positions and aspects."

    case .career:
        return "Professional path, career strengths, work style, public reputation, authority relationships, career opportunities based on 10th house, 6th house, Midheaven, Saturn, Mars, Sun positions and aspects."

    case .relationships:
        return "Love style, partnership needs, relationship patterns, attraction factors, compatibility indicators based on 7th house, 5th house, Venus, Mars, Moon positions and aspects."

    case .health:
        return "Vitality patterns, health strengths and vulnerabilities, wellness approach, mind-body connection based on 6th house, 12th house, Sun, Moon, Mars, Saturn positions and aspects."

    case .general:
        return "Overall life themes, personality expression, major strengths, growth areas, life purpose, key opportunities and challenges across all life areas based on the complete chart synthesis."
    }
}
```

---

## Response Schema

### Success Response

```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "<GENERATED_REPORT_TEXT>"
          }
        ],
        "role": "model"
      },
      "finishReason": "STOP",
      "safetyRatings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "probability": "NEGLIGIBLE"
        }
      ]
    }
  ],
  "usageMetadata": {
    "promptTokenCount": 420,
    "candidatesTokenCount": 650,
    "totalTokenCount": 1070
  }
}
```

### Swift Model (SDK)

```swift
// Using Swift SDK - response is simplified
let response: GenerateContentResponse = try await model.generateContent(prompt)

// Access generated text
if let reportText = response.text {
    // reportText contains the generated report
    print(reportText)
}

// Access usage metadata (optional)
if let usage = response.usageMetadata {
    print("Prompt tokens: \(usage.promptTokenCount)")
    print("Response tokens: \(usage.candidatesTokenCount)")
    print("Total tokens: \(usage.totalTokenCount)")
}
```

---

## Error Handling

### Error Types

```swift
enum ReportGenerationError: Error, LocalizedError {
    case noContent
    case apiKeyMissing
    case rateLimitExceeded
    case invalidResponse
    case networkError(Error)
    case contentFiltered // Safety filters triggered
    case quotaExceeded
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .noContent:
            return "No content generated from AI service"
        case .apiKeyMissing:
            return "OpenAI API key not configured"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again in a moment."
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .contentFiltered:
            return "Content filtered by safety settings"
        case .quotaExceeded:
            return "API quota exceeded"
        case .serviceUnavailable:
            return "AI service temporarily unavailable"
        }
    }
}
```

### HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 400 | Bad Request | Check prompt format |
| 401 | Unauthorized | Verify API key |
| 403 | Forbidden | Check API permissions |
| 429 | Rate Limit | Retry with exponential backoff |
| 500 | Server Error | Retry with exponential backoff |
| 503 | Service Unavailable | Retry later |

### Retry Logic

```swift
func generateReportWithRetry(
    chart: NatalChart,
    area: ReportArea,
    language: Language,
    maxRetries: Int = 2
) async throws -> String {
    var lastError: Error?

    for attempt in 0...maxRetries {
        do {
            return try await generateReport(chart: chart, area: area, language: language)
        } catch let error as ReportGenerationError {
            lastError = error

            switch error {
            case .rateLimitExceeded, .serviceUnavailable:
                // Retry with exponential backoff
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

            case .apiKeyMissing, .contentFiltered, .invalidResponse:
                // Don't retry these errors
                throw error

            default:
                // Retry network errors
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continue
                }
            }
        }
    }

    throw lastError ?? ReportGenerationError.invalidResponse
}
```

---

## Rate Limits & Quotas

### Free Tier Limits

| Metric | Limit | Notes |
|--------|-------|-------|
| Requests per minute (RPM) | 15 | Per API key |
| Requests per day (RPD) | 1,500 | Free tier |
| Tokens per minute (TPM) | Unknown | Monitor usage |
| Tokens per day | Unknown | Monitor usage |

### Paid Tier (If Needed)

| Metric | Limit | Cost |
|--------|-------|------|
| Requests per minute | 1,000+ | Scalable |
| Tokens | Pay-per-use | ~$0.00002-0.0001 per report |

### Cost Monitoring

```swift
struct UsageTracker {
    var totalRequests: Int = 0
    var totalTokens: Int = 0
    var totalCost: Decimal = 0

    mutating func recordUsage(tokens: Int) {
        totalRequests += 1
        totalTokens += tokens

        // OpenAI GPT-4o Mini pricing (estimated)
        // Input: ~$0.000001 per token
        // Output: ~$0.000002 per token
        // Average ~800 tokens per report
        let costPerReport: Decimal = 0.0001
        totalCost += costPerReport
    }

    var averageTokensPerRequest: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(totalTokens) / Double(totalRequests)
    }
}
```

---

## Testing & Validation

### Test Prompt (Development)

```swift
let testChart = NatalChart(
    birthDate: Date(timeIntervalSince1970: 1234567890),
    birthTime: Date(timeIntervalSince1970: 1234567890),
    latitude: 50.4501,
    longitude: 30.5234,
    locationName: "Kyiv, Ukraine",
    planets: [
        Planet(name: .sun, longitude: 287.45, sign: .capricorn, house: 1, isRetrograde: false),
        Planet(name: .moon, longitude: 123.67, sign: .cancer, house: 7, isRetrograde: false)
    ],
    houses: [...],
    aspects: [...],
    ascendant: 245.67,
    midheaven: 180.32
)

let testArea = ReportArea.finances
let testLanguage = Language.english

let report = try await generateReport(
    chart: testChart,
    area: testArea,
    language: testLanguage
)

// Validate response
XCTAssertGreaterThan(report.split(separator: " ").count, 300) // At least 300 words
XCTAssertLessThan(report.split(separator: " ").count, 700) // At most 700 words
XCTAssertTrue(report.contains("Sun") || report.contains("Capricorn")) // Chart-specific
```

### Mock Response (Unit Tests)

```swift
class MockOpenAIService: ReportGenerationService {
    func generateReport(chart: NatalChart, area: ReportArea, language: Language) async throws -> String {
        return """
        ## Key Influences

        Your Sun in Capricorn in the 1st house shows a strong, disciplined personality with natural leadership abilities in financial matters.

        ## Detailed Financial Analysis

        [400 words of mock content...]

        ## Practical Recommendations

        1. Focus on long-term wealth building strategies
        2. Leverage your natural discipline for saving
        3. Consider real estate investments
        4. Build multiple income streams
        """
    }
}
```

---

## Security & Privacy

### API Key Management

```swift
// ❌ NEVER commit API keys to version control
// ❌ NEVER hardcode keys in source code

// ✅ Use environment variables (development)
let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]

// ✅ Use Xcode configuration files (.xcconfig)
// Config.xcconfig:
// OPENAI_API_KEY = your_key_here

// ✅ Or fetch from secure backend (production)
// let apiKey = try await fetchAPIKeyFromBackend()
```

### Data Privacy

**Data Sent to OpenAI**:
- Birth date, time, location coordinates
- Calculated planetary positions (numbers only)
- No user names or personal identifiers

**Data NOT Sent**:
- User device ID
- Chart name ("My Chart", "Partner's Chart")
- Previously generated reports
- Purchase history
- Any personally identifiable information

---

## Performance Optimization

### Token Optimization

```swift
// Compress chart data format
func formatPlanetsCompact(_ planets: [Planet]) -> String {
    planets.map { planet in
        "\(planet.name.rawValue): \(planet.sign.rawValue) \(planet.house)H\(planet.isRetrograde ? "R" : "")"
    }.joined(separator: ", ")
}

// Before: "Sun is in Capricorn in the 1st house. Moon is in Cancer in the 7th house..."
// After: "Sun: Capricorn 1H, Moon: Cancer 7H"
// Saves ~50% tokens on planetary data
```

### Response Caching

```swift
// Cache generated reports (optional optimization)
actor ReportCache {
    private var cache: [String: String] = [:]

    func get(chartID: UUID, area: ReportArea) -> String? {
        let key = "\(chartID.uuidString)_\(area.rawValue)"
        return cache[key]
    }

    func set(chartID: UUID, area: ReportArea, report: String) {
        let key = "\(chartID.uuidString)_\(area.rawValue)"
        cache[key] = report
    }
}
```

---

## Integration Checklist

- [ ] Add `openai/openai-swift` to SPM dependencies
- [ ] Configure OpenAI API key (environment or .xcconfig)
- [ ] Implement `ReportGenerationService` protocol
- [ ] Build prompt templates for all 5 life areas
- [ ] Implement retry logic with exponential backoff
- [ ] Add error handling for all error cases
- [ ] Test with Ukrainian and English languages
- [ ] Validate report length (400-500 words)
- [ ] Monitor token usage and costs
- [ ] Set up usage tracking/analytics (optional)

---

## Example Implementation

```swift
import OpenAI

actor OpenAIReportGenerator {
    private let client: OpenAI
    private let model: Model

    init(apiKey: String, model: Model = .gpt4oMini) {
        self.client = OpenAI(apiKey: apiKey)
        self.model = model
    }

    func generateReport(
        chart: NatalChart,
        area: ReportArea,
        language: Language
    ) async throws -> String {
        let prompt = buildPrompt(chart: chart, area: area, language: language)

        let response = try await client.responses.generate(
            model: model,
            prompt: .init(prompt),
            maxOutputTokens: OpenAIConfig.maxOutputTokens,
            temperature: OpenAIConfig.temperature,
            topP: OpenAIConfig.topP
        )

        guard let text = response.outputText else {
            throw ReportGenerationError.noContent
        }

        // Validate response
        let wordCount = text.split(separator: " ").count
        guard wordCount >= 300 && wordCount <= 700 else {
            throw ReportGenerationError.invalidResponse
        }

        return text
    }

    private func buildPrompt(...) -> String {
        // Implementation from prompt template above
    }
}
```

---

**Status**: ✅ Contract specification complete
**Next**: Implement in `AstroSvitla/Core/Services/OpenAIReportGenerator.swift`
