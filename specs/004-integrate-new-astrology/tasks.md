# Tasks: Integrate New Astrology API

**Input**: Design documents from `/specs/004-integrate-new-astrology/`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Summary

**Primary User Story**: As a user of AstroSvitla, I need the application to use a better astrology API (api.astrology-api.io) for natal chart generation that provides more accurate calculations and better visual chart representations, while maintaining all existing functionality and keeping previous API implementations as hidden fallback options.

**Technical Implementation**: 15 functional requirements organized into 4 implementation phases with 35 executable tasks.

## Execution Strategy

- **MVP Scope**: Complete Primary User Story (Phase 3) - delivers full API integration
- **Incremental Delivery**: Each phase can be completed independently
- **Parallel Opportunities**: 12 tasks marked [P] for parallel execution
- **Testing**: Comprehensive testing strategy included (not TDD - no explicit test requirements in spec)

## Implementation Phases

### Phase 1: Setup (Project Structure)
**Goal**: Initialize project structure and dependencies for new AstrologyAPI integration
**Dependencies**: None
**Test Criteria**: Directory structure created, Xcode project updated

- [x] **T001** Create AstrologyAPI service directory structure at `/AstroSvitla/Services/AstrologyAPI/`
- [x] **T002** Create AstrologyAPI models directory structure at `/AstroSvitla/Models/API/AstrologyAPI/`
- [x] **T003** [P] Create test directory structure at `/AstroSvitlaTests/Services/AstrologyAPI/`
- [x] **T004** [P] Update Xcode project file to include new directory groups

**Checkpoint**: ✅ Project structure ready for implementation

---

### Phase 2: Foundational (Core Infrastructure)
**Goal**: Implement foundational components required by all subsequent phases
**Dependencies**: Phase 1 complete
**Test Criteria**: Core services compile without errors, basic configuration in place

- [x] **T005** [US1] Create AstrologyAPIConfiguration struct in `/AstroSvitla/Config/Config.swift` with base URL, rate limits, and timeout settings (FR-008, FR-014)
- [x] **T006** [US1] [P] Create AstrologyAPIModels.swift with all DTO structures from data-model.md (FR-003, FR-009)
- [x] **T007** [US1] [P] Create AstrologyAPIDTOMapper.swift with domain model mapping logic (FR-004, FR-009)
- [x] **T008** [US1] Create base AstrologyAPIService.swift class with HTTP client and rate limiter integration (FR-001, FR-008, FR-014)

**Checkpoint**: ✅ Core infrastructure available for integration

---

### Phase 3: Primary Integration (Complete API Integration)
**Goal**: Implement complete api.astrology-api.io integration satisfying all functional requirements
**Dependencies**: Phase 2 complete
**Test Criteria**: Full natal chart generation works with new API, existing functionality preserved, old APIs commented out

#### 3.1: Core API Implementation
- [x] **T009** [US1] Implement natal chart generation method in AstrologyAPIService.swift using `/api/v3/charts/natal` endpoint (FR-001, FR-003)
- [x] **T010** [US1] Implement SVG chart generation method in AstrologyAPIService.swift using `/api/v3/svg/natal` endpoint (FR-002)
- [x] **T011** [US1] Add comprehensive error handling for authentication, rate limiting, and network failures in AstrologyAPIService.swift (FR-008)
- [x] **T012** [US1] [P] Implement request building with birth data, house system (Placidus), and planet selection in AstrologyAPIService.swift (FR-010, FR-011)

#### 3.2: Domain Integration
- [x] **T013** [US1] Update NatalChartService.swift to use AstrologyAPIService as primary provider (FR-001)
- [ ] **T014** [US1] [P] Update RepositoryContext.swift to inject AstrologyAPIService with proper dependencies (FR-008, FR-014)
- [x] **T015** [US1] Implement aspect calculation mapping with proper orb tolerances (conjunction, opposition, trine, square, sextile) (FR-012)
- [x] **T016** [US1] [P] Add timezone conversion handling through city/country_code input mapping (FR-013)

#### 3.3: Legacy API Preservation
- [x] **T017** [US1] Comment out Free Astrology API implementation in `/AstroSvitla/Services/FreeAstrology/` with restoration markers (FR-006)
- [x] **T018** [US1] [P] Comment out Prokerala API implementation in `/AstroSvitla/Services/Prokerala/` with restoration markers (FR-007)
- [x] **T019** [US1] [P] Comment out existing tests that reference old API implementations with preservation markers (FR-015)
- [x] **T020** [US1] Update NatalChartService.swift to remove old API calls while preserving commented code structure (FR-006, FR-007)

#### 3.4: Data Integration
- [x] **T021** [US1] Verify existing SwiftData models remain compatible with new API response mapping (FR-004, FR-005)
- [x] **T022** [US1] [P] Test existing ChartCacheService.swift with new API-generated charts to ensure caching works (FR-005)
- [x] **T023** [US1] [P] Validate offline support functionality continues working with cached charts from new API (FR-005)
- [x] **T024** [US1] Update chart generation to include all major planets and outer planets as specified (FR-011)

**Checkpoint**: ✅ Complete API integration implemented and tested

---

### Phase 4: Polish & Validation
**Goal**: Comprehensive testing, performance validation, and documentation
**Dependencies**: Phase 3 complete
**Test Criteria**: All success criteria met, performance under 3 seconds, no regressions

#### 4.1: Integration Testing
- [ ] **T025** [US1] Create integration test for complete natal chart generation flow in `/AstroSvitlaTests/IntegrationTests/AstrologyAPIIntegrationTests.swift`
- [ ] **T026** [US1] [P] Create unit tests for AstrologyAPIService in `/AstroSvitlaTests/Services/AstrologyAPI/AstrologyAPIServiceTests.swift`
- [ ] **T027** [US1] [P] Create unit tests for AstrologyAPIDTOMapper in `/AstroSvitlaTests/Services/AstrologyAPI/AstrologyAPIDTOMapperTests.swift`
- [ ] **T028** [US1] [P] Create contract tests using HTTP examples from `/contracts/astrology-api-examples.http`

#### 4.2: Performance & Quality
- [ ] **T029** [US1] Performance test: Validate chart generation completes under 3 seconds including API call and visualization
- [ ] **T030** [US1] [P] Memory usage test: Ensure chart generation stays under 100MB memory usage
- [ ] **T031** [US1] [P] Rate limiting test: Verify API quota respect and no service disruptions during normal usage
- [ ] **T032** [US1] UI regression test: Ensure all existing functionality works without user-facing changes

#### 4.3: Documentation & Cleanup
- [ ] **T033** [US1] [P] Add comprehensive inline documentation to AstrologyAPIService.swift and AstrologyAPIDTOMapper.swift
- [ ] **T034** [US1] [P] Update project README or documentation with new API integration details
- [ ] **T035** [US1] Final validation: Run complete test suite and validate all success criteria are met

**Checkpoint**: ✅ Feature complete and ready for production

---

## Dependencies & Execution Order

### Sequential Dependencies (Must Complete in Order)
```
Phase 1 (Setup) → Phase 2 (Foundational) → Phase 3 (Integration) → Phase 4 (Polish)
```

### Within Each Phase
- **Phase 1**: T001 → T002 → (T003, T004 in parallel)
- **Phase 2**: T005 → (T006, T007, T008 in parallel)
- **Phase 3.1**: T009 → T010 → T011 → T012 (can parallelize T012)
- **Phase 3.2**: (T013, T014, T015, T016 can be parallelized after T009-T011)
- **Phase 3.3**: (T017, T018, T019 in parallel) → T020
- **Phase 3.4**: (T021, T022, T023, T024 can be parallelized)
- **Phase 4**: All tasks within each subphase can be parallelized

## Parallel Execution Examples

### Maximum Parallelization Strategy
After completing foundational tasks, these can run in parallel:
- **Data Layer**: T006 (Models), T007 (Mapper), T021 (SwiftData validation)
- **Service Layer**: T008 (Base service), T026 (Service tests)
- **Legacy Cleanup**: T017 (FreeAstrology), T018 (Prokerala), T019 (Tests)
- **Documentation**: T033 (Code docs), T034 (Project docs)

### Conservative Approach (2-3 parallel tracks)
1. **Core Implementation**: T009 → T010 → T011 → T013
2. **Testing & Validation**: T025 → T026 → T027 → T028
3. **Legacy & Cleanup**: T017 → T018 → T019 → T020

## Validation Checklist

### User Story Coverage
- ✅ **Primary User Story**: Complete API integration (T009-T024)
- ✅ **Better API Quality**: New provider implementation (T009-T012)
- ✅ **Maintain Functionality**: Existing features preserved (T021-T023)
- ✅ **Preserve Fallback**: Old APIs commented, not deleted (T017-T020)

### Functional Requirements Coverage
- ✅ **FR-001 to FR-015**: All requirements mapped to specific tasks
- ✅ **Key Entities**: All 4 components implemented across phases
- ✅ **Success Criteria**: Performance, quality, and compatibility validated

### Technical Quality
- ✅ **File Paths**: All tasks include exact file locations
- ✅ **Parallel Opportunities**: 12 tasks marked [P] for efficiency
- ✅ **Dependencies**: Clear sequential requirements identified
- ✅ **Testing**: Comprehensive test coverage without TDD requirement

---

## Success Metrics

- **Total Tasks**: 35 tasks across 4 phases
- **Parallel Opportunities**: 12 tasks can run concurrently (34% parallelization)
- **MVP Delivery**: Phase 3 completion delivers full user story
- **Independent Testing**: Each phase has clear test criteria
- **File Coverage**: 15+ files created/modified with exact paths specified

**Estimated Completion**: Phase 3 represents minimum viable delivery of the complete user story with all functional requirements satisfied.