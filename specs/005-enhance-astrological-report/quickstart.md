# Enhanced Astrological Report – Developer Quickstart (Astrology API Only)# Enhanced Astrological Report - Developer Quickstart



## Overview## Overview



Follow this guide to bring the feature branch back to a green state while migrating entirely to `api.astrology-api.io`. The focus is:This guide helps developers set up, test, and troubleshoot the enhanced astrological report feature that adds:

- Restoring natal chart generation with True Node, South Node (computed), Lilith, and full house ruler coverage.- **Nodes & Lilith**: North Node, South Node, Black Moon Lilith calculations

- Keeping offline caching, SVG downloads, and rate limiting intact.- **House Rulers**: Complete analysis of all 12 house rulers using traditional rulerships

- Preserving knowledge transparency structures with a temporary stub provider until vector store work resumes.- **Expanded Aspects**: 20+ aspects (up from 8) sorted by orb tightness

- **Source Transparency**: Full attribution via OpenAI Vector Store integration

---

---

## Prerequisites

## Prerequisites

- macOS 14+, Xcode 15.0+, Swift 5.9 toolchain

- Astrology API key from https://api.astrology-api.io/rapidoc#servers- Xcode 15.0+

- (Optional) OpenAI API key for future knowledge integration – not required for this phase- Swift 5.9+

- OpenAI API account with Vector Store access

_No FreeAstrology or Prokerala credentials should remain in the repo or runtime config._- Free Astrology API key (or Astrology API key from api.astrology-api.io)



------



## Setup Checklist## Setup Instructions



1. **Config placeholders** – update `AstroSvitla/Config/Config.swift`:### 1. Configure API Keys

   ```swift

   enum Config {Edit `AstroSvitla/Config/Config.swift`:

       static let astrologyAPIBaseURL = "https://api.astrology-api.io/api/v3"

       static let astrologyAPIKey = "YOUR_ASTROLOGY_API_KEY_HERE"```swift

       static let astrologyAPIRateLimitRequests = 10struct Config {

       static let astrologyAPIRateLimitTimeWindow: TimeInterval = 60    // Existing keys

       static let astrologyAPIRequestTimeout: TimeInterval = 30    static let freeAstrologyAPIKey = "YOUR_FREE_ASTROLOGY_KEY"

   }    

   ```    // NEW: Add OpenAI Vector Store configuration

   - Ensure `.example` mirrors these keys and clearly marks placeholders.    static let openAIAPIKey = "YOUR_OPENAI_API_KEY"

   - Remove references to `freeAstrologyAPIKey`, `prokeralaClientID`, etc. from both live and example configs.    static let openAIVectorStoreID = "vs_abc123"  // From vector store setup

}

2. **Swift Package refresh** – clean build artifacts to avoid stale caches:```

   ```bash

   cd /Users/Ruslan_Popesku/Desktop/AstroSvitla⚠️ **Never commit real keys**. Use `Config.swift.example` for templates.

   xcodebuild -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15' clean build

   ```### 2. Verify API Configuration



3. **Documentation sync** – confirm `plan.md`, `research.md`, `data-model.md`, `contracts/` now describe the single-provider flow (already updated in this run).Check that nodes and Lilith are **NOT excluded** from API requests:



---**File**: `AstroSvitla/Models/API/FreeAstrologyModels.swift` (line 51-52)



## Test-First Workflow (must run in order)**Before** (WRONG - causes missing data):

```swift

1. **Contract fixtures** *(Phase 1 output)*excludePlanets: ["Lilith", "Chiron", "Ceres", "Vesta", "Juno", "Pallas", 

   - File: `contracts/astrology-api-natal-success.json` (generate via API or saved fixture).                 "True Node", "Mean Node", "IC", "Descendant"]

   - Used by: `AstroSvitlaTests/Features/ChartCalculation/AstrologyAPIContractTests.swift`.```

   - Expected asserts: nodes present, Lilith present, 12 house cusps, ≥20 aspects.

**After** (CORRECT):

2. **Unit tests** – run once fixtures and DTOs exist:```swift

   ```bashexcludePlanets: ["Chiron", "Ceres", "Vesta", "Juno", "Pallas", 

   xcodebuild test -scheme AstroSvitla \                 "IC", "Descendant"]

     -only-testing:AstroSvitlaTests/Features/ChartCalculation/AstrologyAPIContractTests \// Removed: "True Node", "Mean Node", "Lilith" - now included in requests

     -destination 'platform=iOS Simulator,name=iPhone 15'```



   xcodebuild test -scheme AstroSvitla \### 3. Upload Knowledge to Vector Store

     -only-testing:AstroSvitlaTests/Features/ChartCalculation/NatalChartServiceTests \

     -destination 'platform=iOS Simulator,name=iPhone 15'Run the vector store upload script:

   ```

   Targets verify: request headers, rate-limit behavior, caching fallback, South Node computation.```bash

cd scripts

3. **Integration sanity** – once build compiles:./upload-astrology-knowledge.sh

   ```bash```

   xcodebuild test -scheme AstroSvitla \

     -only-testing:AstroSvitlaTests/IntegrationTests/NatalChartGenerationTests \This uploads Ukrainian astrology knowledge from `knowledge/` directory to OpenAI Vector Store.

     -destination 'platform=iOS Simulator,name=iPhone 15'

   ```**Expected output**:

   Confirms end-to-end flow with stubbed knowledge provider still yields complete report sections.```

✅ Uploaded 15 files to Vector Store vs_abc123

4. **Manual smoke**✅ Total: 12.4 MB, Status: completed

   - Run app on iPhone 15 simulator.```

   - Generate chart for: `25 Mar 1990, 14:30, Kyiv, UA`.

   - Validate UI shows: Ascendant + MC interpretations, Nodes axis paragraph, Lilith section, 12 house rulers, at least 20 aspects, knowledge transparency note (“Vector database was not used”).If you don't have the upload script yet, manually upload via OpenAI API:

1. Convert knowledge files to JSONL format (see `contracts/openai-vector-store.http`)

---2. Upload files to OpenAI: `POST /v1/files`

3. Attach to vector store: `POST /v1/vector_stores/{id}/files`

## Developer Notes

### 4. Build the Project

- **Rate limiting**: Keep `RateLimiter` injected into `NatalChartService.init`. Set `maxRequestsPerWindow`/`windowInterval` via `Config` to align with provider terms.

- **Offline cache**: `chartCacheService` and `imageCacheService` stay required dependencies. `getCachedChart` should return cached entries when offline.```bash

- **Knowledge stub**: Implement `KnowledgeSourceProvider` protocol with `StubKnowledgeSourceProvider`. For transparency:cd /Users/Ruslan_Popesku/Desktop/AstroSvitla

  ```swiftxcodebuild -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15' build

  return (```

      sources: [],

      metrics: KnowledgeUsageMetrics(**Expected**: Build succeeds with no errors.

          totalSourcesConsulted: 0,

          vectorDBSourceCount: 0,---

          aiTrainingSourceCount: 0,

          averageRelevanceScore: 0.0,## Testing Instructions

          cacheHit: false

      ),### Unit Tests

      message: "Vector database was not used for this report."

  )Run tests for new components:

  ```

- **South Node**: Derive by adding 180° to True Node, wrapping via `fmod`. House placement may need `(axis + 6) mod 12` logic when provider gives only North Node house.```bash

- **Aspect ordering**: Sort ascending by orb, then by major-aspect priority. Keep first 20 entries for report feed.# Test house ruler calculations

xcodebuild test -scheme AstroSvitla \

---  -only-testing:AstroSvitlaTests/HouseRulerTests \

  -destination 'platform=iOS Simulator,name=iPhone 15'

## Troubleshooting

# Test astrological point parsing

| Symptom | Check | Fix |xcodebuild test -scheme AstroSvitla \

|---------|-------|-----|  -only-testing:AstroSvitlaTests/AstrologicalPointTests \

| `Cannot find 'Config' in scope` | Ensure `Config.swift` belongs to app target and imports Foundation | Add file to target membership; rebuild |  -destination 'platform=iOS Simulator,name=iPhone 15'

| HTTP 401 from astrology API | Bearer token missing | Confirm `Authorization` header assembled in `AstrologyAPIService` and key populated |

| Nodes missing in chart | `active_points` array | Include `"True Node"` and `"Lilith"` when building request |# Test aspect sorting

| South Node missing | Mapper logic | Implement `northNode.opposite()` helper returning `.southNode` |xcodebuild test -scheme AstroSvitla \

| SVG download fails | Timeout | Increase `Config.astrologyAPIRequestTimeout` or retry with exponential backoff |  -only-testing:AstroSvitlaTests/AspectSortingTests \

| Knowledge section empty | Stub not wired | Inject `StubKnowledgeSourceProvider` into report builder and show explanatory message |  -destination 'platform=iOS Simulator,name=iPhone 15'

```

---

**Expected outcomes**:

## Next Steps After Implementation- `testTraditionalRulership_allSigns()` - All 12 signs return correct traditional rulers

- `testNorthNodeParsing_withinOneDegree()` - North Node position matches expert chart (Taurus ~47°)

1. Re-run full test suite: `xcodebuild test -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15'`.- `testAspectSorting_byOrbTightness()` - Aspects sorted with smallest orbs first

2. Update `tasks.md` to mark planning/design tasks complete and queue implementation tickets (DTO mapper, service rebuild, stub provider).

3. Document manual validation in PR checklist (screenshots of report sections + knowledge stub note).### Integration Tests

4. Coordinate with product on vector store reintroduction once compile state is stable.

Run full report generation with expert test chart:

```bash
xcodebuild test -scheme AstroSvitla \
  -only-testing:AstroSvitlaTests/NatalChartGenerationTests/testEnhancedReportWithNodes \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**This test validates**:
- North Node in Taurus (expected: ~47°, tolerance: ±1°)
- South Node in Scorpio (expected: ~227°, tolerance: ±1°)
- Lilith present with valid position (0-360°)
- All 12 house rulers calculated
- Minimum 20 aspects included
- Minimum 12 knowledge sources with metadata
- Total generation time <15 seconds

**Expected output**:
```
✅ testEnhancedReportWithNodes - North Node: 47.2° Taurus (within 1° of expected)
✅ Aspect count: 23 (meets minimum 20)
✅ Source count: 15 (meets minimum 12)
✅ Generation time: 3.2s (under 15s limit)
```

### Manual Testing

1. **Launch the app**:
   ```bash
   open AstroSvitla.xcodeproj
   # In Xcode: Run (Cmd+R) on iPhone 15 simulator
   ```

2. **Generate test chart**:
   - Enter birth data: `April 15, 1990, 14:30, Kyiv`
   - Select "General Overview" report
   - Tap "Generate Report"

3. **Verify report includes**:
   - ✅ Ascendant interpretation (e.g., "Асцендент в Овні...")
   - ✅ Midheaven interpretation (e.g., "Середина Неба в Козерозі...")
   - ✅ North Node & South Node sections (with signs and houses)
   - ✅ House rulers section (12 entries)
   - ✅ Expanded aspects (20+ entries)
   - ✅ Lilith interpretation
   - ✅ Knowledge sources at bottom (showing book titles, authors, pages)

4. **Check knowledge metrics**:
   Scroll to bottom of report → Should show:
   ```
   Використано джерел: 15 (14 з бази знань, 1 з тренувальних даних)
   Середня релевантність: 0.82
   ```

---

## Architecture Overview

```
┌─────────────────┐
│  User Request   │
│  (Generate)     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  NatalChartService      │
│  - Calculate positions  │
│  - Include nodes/Lilith │
│  - Calculate rulers     │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  AstrologyKnowledge     │
│  Provider               │
│  - Query vector store   │
│  - Cache results        │
│  - Return 15-20 sources │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  AIPromptBuilder        │
│  - Build prompt with:   │
│    • Chart data         │
│    • Knowledge snippets │
│    • JSON schema        │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  OpenAI API             │
│  - Generate report      │
│  - Include sources      │
│  - Enforce schema       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  GeneratedReport        │
│  - All sections         │
│  - Source metadata      │
│  - Usage metrics        │
└─────────────────────────┘
```

---

## Common Issues & Solutions

### Issue 1: Nodes Missing from Report

**Symptom**: Report shows "Position unavailable" for North Node or South Node.

**Diagnosis**:
1. Check API response in Xcode console:
   ```
   [NatalChartService] API response: { "planets": [...] }
   ```
2. Search for `"True Node"` in response - if missing, nodes are excluded.

**Solution**:
- Verify `FreeAstrologyModels.swift` line 51-52 does NOT contain `"True Node"` or `"Mean Node"` in `excludePlanets` array.
- If using Astrology API, ensure `active_points` array includes `"True Node"`.
- Rebuild and re-run tests.

### Issue 2: Vector Store Query Fails

**Symptom**: Error "No such vector store: vs_abc123" or empty knowledge sources.

**Diagnosis**:
1. Check API key in `Config.swift`:
   ```swift
   print("OpenAI API Key: \(Config.openAIAPIKey.prefix(10))...")
   ```
2. Verify vector store exists:
   ```bash
   curl https://api.openai.com/v1/vector_stores/vs_abc123 \
     -H "Authorization: Bearer YOUR_API_KEY"
   ```

**Solutions**:
- **Invalid Vector Store ID**: Update `Config.openAIVectorStoreID` with correct ID from OpenAI dashboard.
- **API Key Missing/Wrong**: Verify key has Vector Store access (not just chat completion).
- **Vector Store Empty**: Run upload script: `./scripts/upload-astrology-knowledge.sh`.
- **Fallback**: If vector store unavailable, app continues with empty sources (using AI general knowledge only).

### Issue 3: Generation Takes >15 Seconds

**Symptom**: Report generation exceeds success criteria (SC-008: <15s).

**Diagnosis**:
1. Check metrics in report:
   ```
   calculationTimeMs: 450
   vectorQueryTimeMs: 8500  ← Too slow
   reportGenerationTimeMs: 6500
   ```

**Solutions**:
- **High Vector Query Time**: 
  - Check cache status: `cacheHit: false` → First query is slow, subsequent should be faster
  - Reduce `max_num_results` from 20 to 15 in vector query
  - Verify network connection (vector queries require external API call)
- **High Report Generation Time**:
  - Check token count: If >2000 tokens, AI model is overloaded
  - Verify JSON Schema constraints are enforced (prevents AI from generating too much text)
- **Cache Not Working**:
  - Verify NSCache implementation in `AstrologyKnowledgeProvider`
  - Check cache key generation: Should be deterministic for same chart+area

### Issue 4: House Rulers Incorrect

**Symptom**: Report shows wrong ruling planet for house (e.g., "Правитель 1-го дому: Венера" when Ascendant is in Aries).

**Diagnosis**:
1. Check Ascendant sign: `Ascendant: 15.7° (Овен)`
2. Check expected ruler: Aries → Mars (traditional rulership)
3. Check actual ruler in report

**Solutions**:
- Verify `TraditionalRulershipTable` in `HouseRuler.swift` contains correct mappings:
  ```swift
  static let traditionalRulerships: [ZodiacSign: String] = [
      .aries: "Марс",
      .taurus: "Венера",
      // ... all 12 signs
  ]
  ```
- Ensure house cusp calculation is correct (degrees map to correct signs).
- Add test case: `testHouseRulerCalculation_forAriesAscendant_returnsMars()`.

### Issue 5: Only 8 Aspects Instead of 20

**Symptom**: Report contains 8 aspects despite requirement for 20+.

**Diagnosis**:
1. Check aspect count in API response:
   ```
   [NatalChartService] Received 25 aspects from API
   ```
2. Check prompt builder code: `AIPromptBuilder.swift` line 137

**Solution**:
- Change `.prefix(8)` to `.prefix(20)` in `AIPromptBuilder.swift`:
  ```swift
  // Before
  let aspects = chart.aspects.prefix(8)
  
  // After
  let aspects = chart.aspects
      .sorted { $0.orb < $1.orb }  // Sort by tightness
      .prefix(20)
  ```
- Rebuild and verify with test: `testAspectCount_minimum20()`.

### Issue 6: Missing Source Attribution

**Symptom**: Report shows "Джерела: недоступно" or knowledge sources array is empty.

**Diagnosis**:
1. Check vector store query result:
   ```
   [AstrologyKnowledgeProvider] Query returned 0 snippets
   ```
2. Check for errors in console

**Solutions**:
- **Vector Store Not Queried**: Verify `AstrologyKnowledgeProvider` is not still using TODO stub.
- **Low Relevance Scores**: Lower threshold from 0.7 to 0.5 in vector query.
- **Wrong Metadata Filters**: Check that metadata in JSONL files matches query filters (e.g., `area: "general"`).
- **API Rate Limit**: If rate limited, implement retry logic with exponential backoff.

---

## Performance Targets

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Node accuracy | Within 1° of expected | `testNorthNodeParsing_withinOneDegree()` |
| Aspect count | 20+ | `assert(report.aspects.count >= 20)` |
| Source count | 12+ | `assert(report.knowledgeSources.count >= 12)` |
| Generation time | <15s | `assert(metrics.totalTimeMs < 15000)` |
| Cache hit rate | >67% | Run 100 reports, measure cache hits |
| Token usage | <1800 | Check `usage.completion_tokens` in AI response |

---

## Debugging Tips

### Enable Verbose Logging

Add to `AppDelegate` or `AstroSvitlaApp.swift`:

```swift
#if DEBUG
Config.verboseLogging = true
#endif
```

This logs:
- API requests/responses (chart calculation, vector queries)
- Cache hits/misses
- Performance metrics for each stage

### Inspect Generated Prompt

Before sending to AI, print the full prompt:

```swift
// In AIPromptBuilder.swift
let prompt = buildPrompt(chart: chart, area: area, knowledge: snippets)
#if DEBUG
print("=== GENERATED PROMPT ===")
print(prompt)
print("=== END PROMPT ===")
#endif
```

Verify prompt includes:
- All astrological points (Ascendant, MC, nodes, Lilith)
- 20 aspects
- 15-20 knowledge snippets with metadata
- JSON schema structure

### Test Vector Store Directly

Use `curl` to test vector store outside the app:

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "North Node in Taurus 3rd house"}],
    "tools": [{
      "type": "file_search",
      "file_search": {"vector_store_ids": ["vs_abc123"]}
    }]
  }'
```

Expected: Response includes `tool_calls[0].file_search.results` array with snippets.

---

## Feature Flags (Optional)

If you want to enable/disable features during development:

```swift
// In Config.swift
struct FeatureFlags {
    static let useVectorStore = true      // Toggle source attribution
    static let calculateHouseRulers = true  // Toggle house ruler analysis
    static let includeLilith = true         // Toggle Lilith interpretation
    static let expandedAspects = true       // Toggle 20 vs 8 aspects
}
```

This allows testing features independently.

---

## Next Steps

1. ✅ Complete setup (API keys, vector store upload)
2. ✅ Run unit tests (`HouseRulerTests`, `AstrologicalPointTests`)
3. ✅ Run integration test (`testEnhancedReportWithNodes`)
4. ✅ Manual test with expert chart (verify all sections present)
5. ✅ Performance test (measure cache hit rate over 100 reports)
6. 🔜 Code review and merge to `main`

---

## Additional Resources

- **API Contracts**: See `specs/005-enhance-astrological-report/contracts/`
  - `astrology-api-nodes-lilith.http` - API request formats
  - `openai-vector-store.http` - Vector Store integration
  - `enhanced-report-payload.json` - Expected report structure

- **Data Model**: See `specs/005-enhance-astrological-report/data-model.md`
  - Entity schemas (AstrologicalPoint, HouseRuler, etc.)
  - Validation rules
  - Relationships and ERD

- **Research Decisions**: See `specs/005-enhance-astrological-report/research.md`
  - Why True Node vs Mean Node
  - Cost calculations for vector store
  - Aspect sorting algorithm

---

## Support

If you encounter issues not covered here:

1. Check Xcode console for error messages
2. Review API responses in network logs
3. Verify all checklist items in `specs/005-enhance-astrological-report/checklists/requirements.md`
4. Consult team or file an issue with:
   - Error message
   - Steps to reproduce
   - Expected vs actual behavior
   - Console logs

**Feature Owner**: See `specs/005-enhance-astrological-report/spec.md` for requirements and success criteria.
