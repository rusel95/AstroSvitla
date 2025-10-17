# Task Plan: Enhance Astrological Report Completeness & Source Transparency

**Feature Branch**: `005-enhance-astrological-report`  
**Primary References**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

---

## Phase 1 – Setup
| Task ID | Description | Deliverable |
|---------|-------------|-------------|
| [X] T001 [Setup] | Update `AstroSvitla/Config/Config.swift` and `AstroSvitla/Config/Config.swift.example` to keep only astrology-api.io placeholders (base URL, API key, rate limits) and add doc comments pointing to `quickstart.md`. | Sanitised config files with legacy providers removed. |

---

## Phase 2 – Foundational Prerequisites
| Task ID | Description | Deliverable |
|---------|-------------|-------------|
| [X] T002 [Foundational] | Capture a canonical natal chart payload from astrology-api.io and store it as `specs/005-enhance-astrological-report/contracts/fixtures/natal-chart-sample.json` for reuse in tests and docs. | JSON fixture committed under `contracts/fixtures/`. |
| [X] T003 [Foundational] | Add caching regression test in `AstroSvitlaTests/Core/Storage/ModelContainerSharedTests.swift` asserting that `ChartCacheService` returns a cached chart when offline (using mocked `NetworkMonitor`). | New XCTest covering offline cache behaviour. |
| [X] T004 [Foundational] | Introduce a `KnowledgeSourceProvider` protocol in `AstroSvitla/Features/ReportGeneration/Services/AstrologyKnowledgeProvider.swift` and update call sites for dependency injection (no functional change). | Protocol-based knowledge provider ready for stub implementation. |

---

## Phase 3 – User Story 1 (P1) – Complete Astrological Point Coverage
- **Story Goal**: Ensure Node & Lilith data flow from astrology-api.io into domain models and caching, enabling accurate interpretations.
- **Independent Test**: `AstroSvitlaTests/Features/ChartCalculation/AstrologyAPIContractTests.testNodesAndLilithMapping` validates North/South Node + Lilith positions within 1° and persisted cache entries.

| Task ID | Description | Deliverable |
|---------|-------------|-------------|
| [X] T005 [Story US1] | Create failing contract test `AstroSvitlaTests/Features/ChartCalculation/AstrologyAPIContractTests.swift` using the new fixture to assert presence of True Node, computed South Node, and Lilith. | Red XCT test covering node & Lilith expectations. |
| [X] T006 [Story US1] | Implement DTOs and mapper updates in `AstroSvitla/Models/API/AstrologyAPI/` (response models + `AstrologyAPIDTOMapper`) to populate nodes, Lilith, ascendant, and midheaven. | Green mapper translating API payload into domain models. |
| [X] T007 [Story US1] | Refactor `AstroSvitla/Services/AstrologyAPI/AstrologyAPIService.swift` and `AstroSvitla/Services/NatalChartService.swift` to call `/api/v3/charts/natal`, honour rate limiting, and persist mapped data while keeping existing cache writes intact. | Service layer using new provider with caching unchanged. |

**Checkpoint**: US1 data requests return accurate nodes/Lilith, tests pass, cache persists enriched charts.

---

## Phase 4 – User Story 2 (P1) – Complete House Ruler Analysis
- **Story Goal**: Provide traditional house rulers and their placements for all 12 houses.
- **Independent Test**: `AstroSvitlaTests/Features/ChartCalculation/HouseRulerCalculationTests.testTraditionalRulersForAllHouses` verifies rulers and locations match expectations.

| Task ID | Description | Deliverable |
|---------|-------------|-------------|
| [X] T008 [Story US2] | Add failing `HouseRulerCalculationTests` under `AstroSvitlaTests/Features/ChartCalculation/` covering 12 houses, ascendant ruler focus, and sample chart assertions. | Red XCT tests for house ruler outcomes. |
| [X] T009 [Story US2] | Finalise `TraditionalRulershipTable` in `AstroSvitla/Shared/Utilities/TraditionalRulershipTable.swift` and extend mapper logic to generate 12 `HouseRuler` entries. | Traditional rulership lookup usable by chart mapper. |
| [X] T010 [Story US2] | Update `AstroSvitla/Services/NatalChartService.swift` and `AstroSvitla/Services/ChartCacheService.swift` to persist computed house rulers and expose them via cached charts. | House rulers cached & retrievable across launches. |

**Checkpoint**: US2 exposes 12 house rulers with deterministic tests and cached persistence.

---

## Phase 5 – User Story 3 (P2) – Comprehensive Aspect Coverage
- **Story Goal**: Provide at least 20 aspects sorted by orb tightness with explicit orb values.
- **Independent Test**: `AstroSvitlaTests/Features/ChartCalculation/AspectSortingTests.testTopTwentyAspectsSortedByOrb` validates ordering and minimum count.

| Task ID | Description | Deliverable |
|---------|-------------|-------------|
| [X] T011 [Story US3] | Author failing `AspectSortingTests` in `AstroSvitlaTests/Features/ChartCalculation/` using fixture data to demand ≥20 aspects sorted by orb. | Red XCT enforcing aspect requirements. |
| [X] T012 [Story US3] | Enhance `AstrologyAPIDTOMapper` aspect mapping and related domain helpers to sort by orb and trim/extend to top 20 entries. | Mapper producing sorted aspect arrays satisfying tests. |

**Checkpoint**: US3 ensures reports list ≥20 aspects in tightness order with passing tests.

---

## Phase 6 – User Story 4 (P2) – Source Attribution & Transparency
- **Story Goal**: Maintain transparent knowledge usage reporting while vector store integration is paused (stub response communicated to users).
- **Independent Test**: `AstroSvitlaTests/Features/ReportGeneration/KnowledgeProviderStubTests.testStubProviderReportsVectorStoreUnavailable` confirms stub output and metrics.

| Task ID | Description | Deliverable |
|---------|-------------|-------------|
| [X] T013 [Story US4] | Add failing stub tests in `AstroSvitlaTests/Features/ReportGeneration/KnowledgeProviderStubTests.swift` to assert empty sources, zero counts, and explanatory notice. | Red XCT capturing transparency expectations. |
| [X] T014 [Story US4] | Implement `StubKnowledgeSourceProvider` in `AstroSvitla/Features/ReportGeneration/Services/` and wire it through `AstrologyKnowledgeProvider` plus report assembly to surface the "Vector database was not used" notice. | Stubbed transparency path with passing tests. |

**Checkpoint**: US4 surfaces honest transparency messaging when vector store is unavailable.

---

## Phase 7 – User Story 5 (P3) – Enhanced Report Structure
- **Story Goal**: Deliver cohesive report sections covering planets, nodes, house rulers, aspects, Lilith, and transparency notice.
- **Independent Test**: `AstroSvitlaTests/Features/ReportGeneration/ReportAssemblerTests.testReportContainsAllSections` verifies JSON sections and SwiftUI rendering order.

| Task ID | Description | Deliverable |
|---------|-------------|-------------|
| [X] T015 [Story US5] | Add failing tests in `AstroSvitlaTests/Features/ReportGeneration/ReportAssemblerTests.swift` to demand all required sections and knowledge notice. | Red XCT validating report structure. |
| [X] T016 [Story US5] | Update `AstroSvitla/Features/ReportGeneration/Services/AIPromptBuilder.swift` and `ReportAssembler.swift` to emit mandated sections and data payloads. | Prompt + assembler emitting full report schema. |
| [X] T017 [Story US5] | Extend `AstroSvitla/Features/ReportGeneration/Views/ReportDetailView.swift` (and related SwiftUI views) to render new sections and transparency notice. | Updated UI showing complete structured report. |

**Checkpoint**: US5 delivers enriched report structure in data and UI, tests pass.

---

## Phase 8 – Polish & Cross-Cutting
| Task ID | Description | Deliverable |
|---------|-------------|-------------|
| [X] T018 [Polish] | Add integration test `AstroSvitlaTests/IntegrationTests/NatalChartGenerationTests.testReturnsCachedChartWhenOffline` validating cache-first behaviour after API switch. | Integration test proving caching regression-free. |
| [X] T019 [Polish] | Update `quickstart.md` and `plan.md` with final manual QA steps (`xcodebuild test`, offline cache verification checklist) and record dependency notes. | Documentation refreshed with final QA instructions. |

---

## Dependencies
1. Phase 1 (Setup) → Phase 2 (Foundational) → US1 (P1) → US2 (P1) → US3 (P2) → US4 (P2) → US5 (P3) → Polish.
2. Caching regression coverage (T003, T018) must remain intact before and after service refactors.

## Parallel Execution Opportunities
- Foundational tasks T002 and T004 can run in parallel with T003 once fixture format is agreed.  
- Within US5, UI work in T017 can proceed alongside T016 once the assembler interface is finalised.

## Implementation Strategy
1. Deliver MVP by completing US1 (accurate nodes/Lilith with caching) – unlocks basic chart integrity.  
2. Layer US2 (house rulers) to stabilise core interpretations.  
3. Add US3 (aspects) for deeper analysis, then US4 (transparency stub) to keep trust signals.  
4. Finish with US5 (UI/report polish) and cross-cutting integration checks.

## Summary
- **Total Tasks**: 19  
- **Tasks per User Story**: US1 – 3, US2 – 3, US3 – 2, US4 – 2, US5 – 3  
- **Parallel Opportunities**: Noted for Foundational (T002 vs T004) and US5 (T016 vs T017) once dependencies satisfied.  
- **Independent Test Criteria**: US1 (`AstrologyAPIContractTests`), US2 (`HouseRulerCalculationTests`), US3 (`AspectSortingTests`), US4 (`KnowledgeProviderStubTests`), US5 (`ReportAssemblerTests`).  
- **Suggested MVP Scope**: Complete up through US1 to restore accurate point coverage with caching before layering additional analysis features.
