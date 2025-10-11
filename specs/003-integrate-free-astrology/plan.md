# Implementation Plan: Integrate Free Astrology API

**Branch**: `003-integrate-free-astrology` | **Date**: 2025-10-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-integrate-free-astrology/spec.md`

**Note**: This template is filled in by the `/plan` command. See templates/plan-template.md for execution workflow.

## Summary

Integrate Free Astrology API as a test alternative to the existing Swiss Ephemeris and Prokerala API implementations. Create a standalone API client (`FreeAstrologyAPIService`) that can coexist with current implementations without disrupting them. Comment out (not delete) existing Swiss Ephemeris and Prokerala services to allow isolated testing of the new API. The new implementation will call four endpoints (planets, houses, aspects, natal-wheel-chart) and map responses to existing domain models. This is an experimental integration to evaluate API feasibility, data completeness, and accuracy before potentially replacing current implementations.

## Technical Context

**Language/Version**: Swift 5.9+ (iOS 17+ SDK)
**Primary Dependencies**:
- SwiftUI (UI framework)
- SwiftData (local persistence - reusing existing chart caching)
- Foundation URLSession (HTTP client for Free Astrology API)
- Existing: Commented out SwissEphemerisService and ProkralaAPIService

**Storage**:
- SwiftData ModelContainer for cached natal chart data (reusing existing ChartCacheService)
- FileManager for cached SVG chart images from Free Astrology API
- Existing caching infrastructure unchanged

**Testing**:
- XCTest framework with `#expect` assertions
- Unit tests in `AstroSvitlaTests/Services/FreeAstrology/`
- Contract tests for Free Astrology API integration
- Existing tests preserved (marked as skipped where dependent on commented implementations)

**Target Platform**: iOS 17.0+, iPhone and iPad

**Project Type**: Mobile (iOS) - Single Xcode project with modular MVVM architecture

**Performance Goals**:
- Chart generation response within 3 seconds per API endpoint
- All 4 endpoints callable in parallel for full chart generation (target <5 seconds total)
- 95% success rate for API requests
- API rate limit compliance (50 requests/day on free tier)

**Constraints**:
- Must preserve existing caching and offline functionality
- API credentials stored in Config.swift (gitignored)
- Must NOT modify existing domain models (NatalChart, Planet, House, Aspect)
- Commented code must remain compilable (use conditional compilation if needed)
- Must support rollback to previous implementations by uncommenting code

**Scale/Scope**:
- Testing scope: Generate 10-20 test charts to validate data completeness and accuracy
- Comparison: Side-by-side validation against Prokerala API results
- Features affected: ChartCalculation service layer only, no UI changes
- ~5 new files (service, models, mapper, tests, config)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Spec-Driven Delivery ✅

- Feature initiated via `/specify` with approved `specs/003-integrate-free-astrology/spec.md`
- This plan.md synchronized with feature branch `003-integrate-free-astrology`
- Generated artifacts: research.md, data-model.md, contracts/, quickstart.md
- **Status**: PASS

### Principle II: SwiftUI Modular Architecture ✅

- Current structure follows MVVM:
  - Models: `AstroSvitla/Models/API/` (will add FreeAstrologyModels.swift)
  - Services: `AstroSvitla/Services/FreeAstrology/` (new FreeAstrologyAPIService)
  - Features: Existing `Features/ChartCalculation/` unchanged (service layer swap only)
  - ViewModels: No changes required
  - Views: No changes required
- One primary type per file maintained
- Config.swift for API keys (gitignored)
- **Status**: PASS - adding new service alongside existing ones

### Principle III: Test-First Reliability (NON-NEGOTIABLE) ✅

- **Current state**: TDD approach documented and ready for implementation
- **Plan**:
  - Contract tests for all 4 Free Astrology API endpoints (TDD)
  - Unit tests for FreeAstrologyAPIService (TDD)
  - Unit tests for response parsing and DTO mapping (TDD)
  - Integration tests for end-to-end chart generation (TDD)
  - Existing tests preserved (marked as skipped where dependent on commented code)
- **Commitment**: All new API client and mapper logic will follow strict TDD
- Tests must pass via `xcodebuild test -scheme AstroSvitla` before merge
- **Status**: PASS - TDD commitment documented with clear test structure

### Principle IV: Secure Configuration & Secrets Hygiene ✅

- Free Astrology API credentials will be stored in `Config.swift` (gitignored)
- `Config.swift.example` updated with required keys:
  - `freeAstrologyAPIKey`
  - `freeAstrologyBaseURL` (default: `https://json.freeastrologyapi.com`)
- No secrets in version control
- **Status**: PASS

### Principle V: Release Quality Discipline ✅

- Build target: `xcodebuild -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Tests: `xcodebuild test -scheme AstroSvitla`
- PR will link to `specs/003-integrate-free-astrology/` folder
- Test chart screenshots for validation included
- Commit messages will follow convention
- **Status**: PASS

## Project Structure

### Documentation (this feature)

```
specs/003-integrate-free-astrology/
├── spec.md              # Feature specification
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (completed)
├── data-model.md        # Phase 1 output (completed)
├── quickstart.md        # Phase 1 output (completed)
├── contracts/           # Phase 1 output (completed)
│   ├── free-astrology-planets.http
│   ├── free-astrology-houses.http
│   ├── free-astrology-aspects.http
│   ├── free-astrology-natal-chart.http
│   └── response-schemas.json
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)

```
AstroSvitla/                           # iOS app target
├── App/
│   └── AstroSvitlaApp.swift           # App entry point (unchanged)
├── Config/
│   ├── Config.swift                   # Gitignored secrets (ADD: Free Astrology API key)
│   └── Config.swift.example           # Template (UPDATE: document Free Astrology config)
├── Models/                            # Domain entities
│   ├── Domain/
│   │   ├── NatalChart.swift           # Natal chart aggregate (unchanged)
│   │   ├── Planet.swift               # Planet position model (unchanged)
│   │   ├── House.swift                # House cusp model (unchanged)
│   │   └── Aspect.swift               # Aspect model (unchanged)
│   ├── API/
│   │   ├── NatalChartRequest.swift    # Birth details request (unchanged)
│   │   ├── ProkralaModels.swift       # COMMENTED: Prokerala DTOs
│   │   └── FreeAstrologyModels.swift  # NEW: Free Astrology API DTOs
│   └── SwiftData/
│       └── BirthChart.swift           # SwiftData persistence model (unchanged)
├── Services/                          # Business logic & integrations
│   ├── NatalChartService.swift        # UPDATE: Inject FreeAstrologyAPIService
│   ├── ChartCacheService.swift        # Existing cache service (unchanged)
│   ├── ImageCacheService.swift        # Existing image cache (unchanged)
│   ├── RateLimiter.swift              # Existing rate limiter (unchanged)
│   ├── NetworkMonitor.swift           # Existing network monitor (unchanged)
│   ├── Prokerala/
│   │   ├── ProkralaAPIService.swift   # COMMENTED: OAuth2 API client
│   │   └── DTOMapper.swift            # COMMENTED: Prokerala → Domain mapper
│   └── FreeAstrology/                 # NEW: Free Astrology integration
│       ├── FreeAstrologyAPIService.swift      # NEW: HTTP client for 4 endpoints
│       └── FreeAstrologyDTOMapper.swift       # NEW: Free Astrology → Domain mapper
├── Features/
│   ├── ChartCalculation/
│   │   ├── Services/
│   │   │   ├── ChartCalculator.swift          # UPDATE: Use FreeAstrologyAPIService
│   │   │   └── SwissEphemerisService.swift    # COMMENTED: Local calculation
│   │   └── Views/
│   │       ├── ChartDetailsView.swift         # Existing (unchanged)
│   │       └── NatalChartWheelView.swift      # Existing (unchanged)
│   └── [Other features unchanged]
└── Utils/                             # Shared helpers (unchanged)

AstroSvitlaTests/                      # Unit tests
├── Services/
│   ├── Prokerala/
│   │   ├── NatalWheelChartContractTests.swift # SKIP: Tests commented implementation
│   │   └── WesternChartDataContractTests.swift # SKIP: Tests commented implementation
│   ├── FreeAstrology/                 # NEW: Free Astrology tests
│   │   ├── FreeAstrologyAPIServiceTests.swift          # NEW: TDD unit tests
│   │   ├── FreeAstrologyDTOMapperTests.swift           # NEW: TDD mapper tests
│   │   ├── PlanetsEndpointContractTests.swift          # NEW: Contract test
│   │   ├── HousesEndpointContractTests.swift           # NEW: Contract test
│   │   ├── AspectsEndpointContractTests.swift          # NEW: Contract test
│   │   └── NatalChartEndpointContractTests.swift       # NEW: Contract test
│   ├── ChartCacheServiceTests.swift   # Existing (unchanged)
│   └── SwissEphemerisServiceTests.swift # SKIP: Tests commented implementation
├── Models/
│   ├── ProkralaDTOTests.swift         # SKIP: Tests commented DTOs
│   └── FreeAstrologyDTOTests.swift    # NEW: DTO parsing tests
├── IntegrationTests/
│   └── NatalChartGenerationTests.swift # UPDATE: Test with Free Astrology API
└── Mocks/
    └── MockFreeAstrologyAPIService.swift # NEW: Test double

AstroSvitlaUITests/                    # UI/E2E tests (unchanged for this feature)
```

**Structure Decision**: iOS mobile app following existing MVVM modular architecture. This feature:
1. **Adds new service layer**: `Services/FreeAstrology/` with API client and mapper
2. **Adds new models**: `Models/API/FreeAstrologyModels.swift` for DTOs
3. **Comments existing services**: SwissEphemerisService and Prokerala services remain in codebase but inactive
4. **Updates orchestration**: `NatalChartService` configured to use `FreeAstrologyAPIService`
5. **Preserves all existing domain models and caching infrastructure**

The structure maintains clean separation: new Free Astrology implementation is entirely self-contained in its own directory, making it easy to enable/disable or remove if testing proves unfavorable.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | All constitutional principles satisfied | N/A |

No violations detected. The feature adds a new service implementation following existing patterns without introducing architectural complexity.

## Phase 2: Task Planning Approach

*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
1. Load `.specify/templates/tasks-template.md` as base template
2. Generate tasks from Phase 1 artifacts:
   - From `contracts/`: 4 contract test tasks (one per endpoint)
   - From `data-model.md`: DTO model creation + mapper implementation tasks
   - From `quickstart.md`: Manual validation test scenarios
   - From spec user stories: Integration test tasks

**Task Categories**:
- **Contract Tests** [P]: Test each API endpoint independently (planets, houses, aspects, natal-chart)
- **DTO Models** [P]: Create Codable structs for API responses
- **Mapper Logic**: Transform DTOs to domain models
- **API Service**: HTTP client implementation with authentication
- **Comment Existing**: Carefully comment out Swiss Ephemeris and Prokerala code
- **Integration**: Wire FreeAstrologyAPIService into NatalChartService
- **Configuration**: Update Config.swift and example files
- **Validation**: Run quickstart scenarios and compare with existing implementations

**Ordering Strategy** (TDD + Dependency Order):
1. Contract tests first (define expected API behavior) [P]
2. DTO models (for parsing responses) [P]
3. Mapper unit tests (before mapper implementation)
4. Mapper implementation (transform DTOs to domain)
5. API service tests (before service implementation)
6. API service implementation (HTTP client)
7. Comment out existing services (preserve rollback ability)
8. Update NatalChartService (inject new service)
9. Integration tests (end-to-end validation)
10. Manual validation (quickstart scenarios)

**Parallelization** [P]:
- Contract tests can run in parallel (independent endpoints)
- DTO model files can be created in parallel (independent types)
- Existing service commenting can happen in parallel (Swiss Ephemeris + Prokerala)

**Estimated Output**: 20-25 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the `/tasks` command, NOT by `/plan`

## Phase 3+: Future Implementation

*These phases are beyond the scope of the /plan command*

**Phase 3**: Task generation (executed by `/tasks` command to create tasks.md)
**Phase 4**: Implementation (execute tasks.md following TDD and constitutional principles)
**Phase 5**: Validation (run test suite, execute quickstart.md, performance benchmarks, accuracy comparison)

## Progress Tracking

*This checklist tracks execution flow progress*

**Phase Status**:
- [x] Phase 0: Research complete (research.md created)
- [x] Phase 1: Design complete (data-model.md, contracts/, quickstart.md created)
- [x] Phase 2: Task planning approach documented (ready for /tasks command)
- [x] Phase 3: Tasks generated (tasks.md created with 33 tasks)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS (no new violations introduced)
- [x] All NEEDS CLARIFICATION resolved (via research.md)
- [x] Complexity deviations documented (N/A - no deviations)
- [x] Agent context updated (CLAUDE.md updated with Swift 5.9+ iOS 17+)

**Artifacts Generated**:
- [x] specs/003-integrate-free-astrology/spec.md
- [x] specs/003-integrate-free-astrology/plan.md (this file)
- [x] specs/003-integrate-free-astrology/research.md
- [x] specs/003-integrate-free-astrology/data-model.md
- [x] specs/003-integrate-free-astrology/quickstart.md
- [x] specs/003-integrate-free-astrology/contracts/ (4 .http files + schemas.json)
- [x] CLAUDE.md updated
- [x] specs/003-integrate-free-astrology/tasks.md (33 tasks generated)

---

**Ready for next phase**: Execute `/tasks` command to generate implementation tasks from this plan.

*Plan completed following Constitution v1.0.0 - See `.specify/memory/constitution.md`*
