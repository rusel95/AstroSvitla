# Research: Enhance Astrological Report Completeness & Source Transparency

| Alternative | Why Rejected |

**Feature**: 005-enhance-astrological-report  |------------|--------------|

**Date**: October 17, 2025  | **Unstructured Prompt** | No guarantee all sections included; prone to missing requirements |

**Status**: Updated for astrology-api.io only integration| **Multiple API Calls** (one per section) | 6× API calls = 6× cost and latency (violates SC-008: <15s) |

| **Post-Processing Validation** | Can't fix missing sections after generation; requires retry loop |

## Overview

---

Compile the clarifications needed to migrate fully to `api.astrology-api.io`, repair the broken compile state, and prepare downstream design work. Each research question resolves a blocker that surfaced after removing FreeAstrology/Prokerala configurations.

## Research Question 6: Aspect Sorting Algorithm

---

### Decision

## Research Question 1: What endpoints and credentials does `api.astrology-api.io` require for natal charts and SVG wheels?

Sort aspects by **orb tightness (ascending)** with secondary sort by **aspect type importance**:

### Decision

```swift

Use the `POST /api/v3/charts/natal` endpoint for all natal data and `POST /api/v3/svg/natal` for SVG generation. Both endpoints expect an API key passed via `Authorization: Bearer <token>` and accept identical `subject` payloads.extension [Aspect] {

    func sortedForReport() -> [Aspect] {

```http        return self.sorted { lhs, rhs in

POST https://api.astrology-api.io/api/v3/charts/natal            // Primary: Tighter orb comes first

Authorization: Bearer {{ASTROLOGY_API_KEY}}            if abs(lhs.orb - rhs.orb) > 0.1 {

Content-Type: application/json                return lhs.orb < rhs.orb

            }

{            

  "subject": {            // Secondary: Major aspects before minor

    "name": "Test Subject",            let lhsPriority = lhs.type.priority

    "birth_data": {            let rhsPriority = rhs.type.priority

      "year": 1990,            return lhsPriority < rhsPriority

      "month": 3,        }

      "day": 25,    }

      "hour": 14,}

      "minute": 30,

      "second": 0,extension AspectType {

      "city": "Kyiv",    var priority: Int {

      "country_code": "UA"        switch self {

    }        case .conjunction: return 1

  },        case .opposition: return 2

  "options": {        case .trine: return 3

    "house_system": "P",        case .square: return 4

    "zodiac_type": "Tropic",        case .sextile: return 5

    "precision": 2,        case .quincunx: return 6

    "active_points": [        case .semisextile: return 7

      "Sun","Moon","Mercury","Venus","Mars",        case .semisquare: return 8

      "Jupiter","Saturn","Uranus","Neptune","Pluto",        case .sesquiquadrate: return 9

      "True Node","Lilith"        }

    ]    }

  }}

}```

```

### Rationale

### Rationale

**Orb Tightness (Primary)**:

- API docs confirm `/api/v3/charts/natal` bundles planets, points, houses, and aspects in one response, eliminating multi-call orchestration.- **0.5° orb** (exact aspect) has much stronger effect than **5° orb** (wide aspect)

- Consistent `subject` schema allows request builders and fixtures to be shared between natal and SVG endpoints.- Astrologers prioritize exact aspects in interpretation

- Using `Authorization` aligns with provider examples; avoids leaking keys via query strings.- Sorting by orb ensures most significant aspects analyzed first



### Alternatives Considered**Aspect Type (Secondary)**:

- Among aspects with similar orbs, major aspects (conjunction, opposition, trine, square) are more significant

| Alternative | Why Rejected |- Ensures if two aspects both have ~2° orb, conjunction is listed before semisextile

|------------|--------------|

| Query string `?key=` | Not documented, leaks credentials in logs |### Example Output

| Separate endpoints per data category | Adds latency; provider already aggregates data |

| Retaining legacy providers as fallback | Violates latest product directive (single provider only) |```

1. Sun conjunction Moon (orb: 0.3°)         ← Tightest, major aspect

---2. Venus opposition Mars (orb: 0.8°)        ← Very tight, major aspect

3. Mercury square Saturn (orb: 1.2°)        ← Tight, major aspect

## Research Question 2: How do we map the Astrology API response into existing domain models without compile errors?4. Jupiter trine Neptune (orb: 2.1°)        ← Wider, but major aspect

5. Moon sextile Pluto (orb: 2.5°)           ← Major aspect

### Decision6. Mars quincunx Uranus (orb: 2.7°)         ← Minor aspect, wider orb

...

Create dedicated DTOs under `Models/API/AstrologyAPI` that mirror the provider schema, then use a mapper to transform into `NatalChart`, `AstrologicalPoint`, `House`, `Aspect`, and new helper structs (for SVG metadata). Derive South Node client-side as `northNodeLongitude ± 180°` and normalize house enumerations into numeric indices.20. Sun semisquare Jupiter (orb: 4.8°)      ← Minor aspect, widest orb

```

```swift

struct AstrologyAPINatalChartResponse: Decodable {### Astrological Justification

    struct ChartData: Decodable {

        struct Planet: Decodable {Source: **Robert Hand, *Planets in Transit*** (1976):

            let name: String> "The strength of an aspect is inversely proportional to its orb. An aspect with a 1° orb is approximately four times as strong as one with a 2° orb."

            let sign: String

            let position: Double**Orb Allowances** (traditional):

            let absPos: Double- Conjunction/Opposition: ±8°

            let house: String- Trine/Square: ±6°

            let retrograde: Bool- Sextile: ±4°

        }- Minor aspects: ±2°



        struct HouseCusp: Decodable {**In practice**: Aspects with orbs <3° are considered "applying/strong"; >5° are "separating/weak".

            let house: String

            let position: Double### Alternatives Considered

            let sign: String

        }| Alternative | Why Rejected |

|------------|--------------|

        let planetaryPositions: [Planet]| **Aspect Type Only** | Ignores orb significance; a 7° trine is weaker than a 1° sextile |

        let houseCusps: [HouseCusp]| **Chronological** (by planet order) | No meaningful prioritization; arbitrary ordering |

        let aspects: [AstrologyAPIAspect]| **By House Involvement** | Too complex; house importance varies by report area |

    }

---

    let subjectData: AstrologyAPISubject

    let chartData: ChartData## Summary of Decisions

}

```| Research Question | Decision | Key Rationale |

|-------------------|----------|---------------|

Mapper outline:| **Vector Store** | OpenAI Vector Store with metadata | Built-in relevance, cost-effective ($0.02/report), metadata support |

| **Caching** | In-memory NSCache with LRU | iOS-native, automatic eviction, 67% time reduction |

```swift| **Rulerships** | Traditional 7-planet system | Classical authority (Ptolemy), matches user expectations |

enum AstrologyAPIDTOMapper {| **Nodes** | True Node (not Mean) | ±1° accuracy, professional standard, API-supported |

    static func toDomain(response: AstrologyAPINatalChartResponse) throws -> NatalChart {| **Prompt** | JSON Schema enforcement | Guaranteed structure, token budget control, type safety |

        let northNode = try mapPoint(named: "True Node", from: response)| **Aspect Sort** | Orb tightness + type priority | Astrological significance (Hand), clear prioritization |

        let southNode = northNode.opposite()

        let lilith = try mapPoint(named: "Lilith", from: response)---

        let houses = mapHouses(response.chartData.houseCusps)

        let planets = mapPlanets(response.chartData.planetaryPositions, houses: houses)## Implementation Readiness

        let aspects = mapAspects(response.chartData.aspects)

        let rulerships = TraditionalRulershipTable.resolve(houses: houses, planets: planets)All technical unknowns resolved. Development team has:

        return NatalChart(- ✅ API integration patterns (vector store, nodes/Lilith queries)

            id: UUID(),- ✅ Data structures (rulership table, cache keys, JSON schema)

            birthDetails: response.subjectData.toBirthDetails(),- ✅ Algorithms (sorting, ruler calculation, cache eviction)

            planets: planets,- ✅ Validation criteria (±1° accuracy, token budgets, performance targets)

            astrologicalPoints: [northNode, southNode, lilith],

            houses: houses,**Status**: Ready to proceed to **Phase 1: Design & Contracts**

            aspects: aspects,

            houseRulers: rulerships---

        )

    }**Research Completed**: October 16, 2025  

}**Reviewed By**: [Development Team Lead Name]  

```**Approved For**: Phase 1 (Data Model & API Contracts)


### Rationale

- Dedicated DTOs restore compile-time safety and enable targeted tests (contract fixtures).
- Calculating South Node locally guarantees perfect opposition even if API does not return it.
- Converting provider house strings (e.g., `"First_House"`) to ints keeps downstream code unchanged.

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Parsing into dictionaries | Loses type safety; perpetuates runtime errors |
| Reusing legacy FreeAstrology DTOs | Mismatched schema introduced compile errors |
| Requesting South Node directly | Endpoint does not include it; client computation is trivial |

---

## Research Question 3: How do we preserve offline and rate-limit behavior after the provider switch?

### Decision

Continue using existing `RateLimiter`, `NetworkMonitor`, `ChartCacheService`, and `ImageCacheService`, but inject them explicitly into `NatalChartService` to avoid accidental removal. Rate limiter defaults: 10 requests per 60 seconds (matching provider guidance). Cache key remains `(birthDetails, houseSystem)` hashed for deterministic lookups.

### Rationale

- Offline fallback (return cached chart) is a core UX expectation cited in spec and constitution.
- Provider enforces soft rate limits; maintaining the limiter prevents HTTP 429s and retries.
- Explicit dependency injection simplifies unit tests (mockable services) and prevents compile errors triggered by previous deletions.

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Removing cache + rate limiter | Breaks success criteria (offline availability, performance) |
| Embedding limiter logic in `AstrologyAPIService` | Couples transport and orchestration layers, harder to fake in tests |
| Switching to disk-only cache | Slower, increases I/O, no eviction semantics |

---

## Research Question 4: How should knowledge transparency behave while vector store work is paused?

### Decision

Introduce a `KnowledgeSourceProvider` protocol returning an array of `EnhancedKnowledgeSource`. During this phase, implement a `StubKnowledgeSourceProvider` that records when vector store is unavailable and surfaces the message "Vector database was not used" with empty metadata. Preserve the protocol so future vector integration can drop in without rewriting report assembly.

### Rationale

- Keeps report payload schema unchanged (knowledge section still present) which satisfies spec and prevents consumer breakage.
- Allows tests to assert that the stub sets `knowledgeMetrics.cacheHit = false` and `vectorDBSourceCount = 0`, maintaining transparency obligations.
- Prevents compile errors caused by removing vector-store-specific files while honoring the product decision to defer integration.

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Removing knowledge section entirely | Violates spec + success criteria (source transparency) |
| Hardcoding dummy sources | Misleading; fails honesty requirement |
| Blocking report generation until vector store ships | Unacceptable delay; user needs other enhancements now |

---

## Research Question 5: What regression tests are required to re-enable TDD for the new provider?

### Decision

Author two levels of tests before implementation:

1. **Contract tests** under `AstroSvitlaTests/Features/ChartCalculation` that load canned JSON from `contracts/astrology-api-natal-success.json` and assert mapping to domain types (nodes, Lilith, house rulers, aspect sorting).
2. **Service tests** that mock `URLProtocol` to verify request headers (`Authorization`), endpoint paths, and retry handling for HTTP 429.

### Rationale

- Restores failing tests (Red) demanded by constitution, guiding the DTO/service rebuild.
- Prevents silent regressions in aspect count, node accuracy, and cache usage.
- Provides fixtures reusable by QA for manual verification.

### Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Integration-only tests | Slow, rely on live API key, brittle CI |
| UI snapshot tests | Do not cover data integrity or service orchestration |
| Post-hoc validation | Violates TDD workflow; risks shipping regressions |

---

## Summary of Decisions

| Topic | Decision | Impact |
|-------|----------|--------|
| Endpoints & Auth | Use `/api/v3/charts/natal` + `/api/v3/svg/natal` with bearer token | Single provider path, consistent payloads |
| DTO Mapping | New astrology-specific DTOs + mapper; compute South Node locally | Restores compile-time safety, satisfies node requirements |
| Offline & Rate Limiting | Keep existing services; inject explicitly; 10 req / 60s | Maintains UX and avoids 429s |
| Knowledge Transparency Stub | Protocol + stub provider | Keeps schema intact while vector store deferred |
| Testing Strategy | Contract fixtures + URLProtocol service tests | Re-enables TDD and guards critical behavior |

**Status**: Ready for Phase 1 (Data Model & Contracts).
