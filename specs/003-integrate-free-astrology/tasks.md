# Tasks: Integrate Free Astrology API

**Feature Branch**: `003-integrate-free-astrology`
**Input**: Design documents from `/specs/003-integrate-free-astrology/`
**Prerequisites**: spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: TDD approach required per Constitution Principle III (NON-NEGOTIABLE)

**Organization**: Tasks grouped by user story for independent implementation and testing

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1=P1, US2=P2, US3=P3, US4=P4)
- All file paths are absolute from repository root

## Path Conventions
- **iOS App**: `AstroSvitla/` directory
- **Tests**: `AstroSvitlaTests/` directory
- **Docs**: `specs/003-integrate-free-astrology/` directory

---

## Phase 1: Setup & Configuration

**Purpose**: Initialize configuration and test infrastructure

- [x] T001 [P] [Setup] Add Free Astrology API keys to `AstroSvitla/Config/Config.swift`
  - Add `freeAstrologyAPIKey` static property with environment variable fallback
  - Add `freeAstrologyBaseURL` = `"https://json.freeastrologyapi.com"`
  - File: `AstroSvitla/Config/Config.swift`

- [x] T002 [P] [Setup] Update Config example template in `AstroSvitla/Config/Config.swift.example`
  - Document `freeAstrologyAPIKey` placeholder
  - Document `freeAstrologyBaseURL` default value
  - Add comments explaining where to obtain API key
  - File: `AstroSvitla/Config/Config.swift.example`

- [x] T003 [P] [Setup] Create test directory structure
  - Create `AstroSvitlaTests/Services/FreeAstrology/` directory
  - Create `AstroSvitlaTests/Mocks/` directory if not exists
  - Command: `mkdir -p AstroSvitlaTests/Services/FreeAstrology AstroSvitlaTests/Mocks`

---

## Phase 2: User Story 1 - API Research and Feasibility Assessment (Priority: P1) 🎯

**Goal**: Validate that Free Astrology API provides complete astrological data

**Independent Test**: Make API calls to all 4 endpoints and verify response completeness

### Contract Tests for User Story 1 (TDD - Write First, Ensure They FAIL)

- [ ] T004 [P] [US1] Create planets endpoint contract test in `AstroSvitlaTests/Services/FreeAstrology/PlanetsEndpointContractTests.swift`
  - Test: Make POST request to `/western/planets` with valid birth data
  - Assert: Response status 200, includes `status: "success"`, data.planets array with 10+ planets
  - Assert: Each planet has name, full_degree, normalized_degree, speed, is_retrograde, sign_num, sign
  - Assert: Includes Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Ascendant at minimum
  - Reference: `specs/003-integrate-free-astrology/contracts/free-astrology-planets.http`
  - **MUST FAIL**: No implementation exists yet
  - File: `AstroSvitlaTests/Services/FreeAstrology/PlanetsEndpointContractTests.swift`

- [ ] T005 [P] [US1] Create houses endpoint contract test in `AstroSvitlaTests/Services/FreeAstrology/HousesEndpointContractTests.swift`
  - Test: Make POST request to `/western/houses` with Placidus system
  - Assert: Response includes exactly 12 houses numbered 1-12
  - Assert: Each house has house_num, degree, normalized_degree, sign_num, sign
  - Reference: `specs/003-integrate-free-astrology/contracts/free-astrology-houses.http`
  - **MUST FAIL**: No implementation exists yet
  - File: `AstroSvitlaTests/Services/FreeAstrology/HousesEndpointContractTests.swift`

- [ ] T006 [P] [US1] Create aspects endpoint contract test in `AstroSvitlaTests/Services/FreeAstrology/AspectsEndpointContractTests.swift`
  - Test: Make POST request to `/western/aspects`
  - Assert: Response includes aspects array
  - Assert: Each aspect has planet1_name, planet2_name, aspect_name, orb_degree (optional)
  - Assert: aspect_name is one of: Conjunction, Opposition, Trine, Square, Sextile, etc.
  - Reference: `specs/003-integrate-free-astrology/contracts/free-astrology-aspects.http`
  - **MUST FAIL**: No implementation exists yet
  - File: `AstroSvitlaTests/Services/FreeAstrology/AspectsEndpointContractTests.swift`

- [ ] T007 [P] [US1] Create natal chart endpoint contract test in `AstroSvitlaTests/Services/FreeAstrology/NatalChartEndpointContractTests.swift`
  - Test: Make POST request to `/western/natal-wheel-chart`
  - Assert: Response includes chart_url field with HTTPS URL
  - Assert: URL is accessible (perform GET request, returns 200)
  - Assert: Response content-type is image/svg+xml or URL ends with .svg
  - Reference: `specs/003-integrate-free-astrology/contracts/free-astrology-natal-chart.http`
  - **MUST FAIL**: No implementation exists yet
  - File: `AstroSvitlaTests/Services/FreeAstrology/NatalChartEndpointContractTests.swift`

**Checkpoint**: All 4 contract tests written and FAILING (as expected per TDD)

---

## Phase 3: User Story 2 - New API Client Implementation (Priority: P2)

**Goal**: Create standalone `FreeAstrologyAPIService` that coexists with existing code

**Independent Test**: Instantiate service and fetch data from all 4 endpoints independently

### DTO Models for User Story 2 (Implementation Can Be Parallel)

- [x] T008 [P] [US2] Create Free Astrology request DTO in `AstroSvitla/Models/API/FreeAstrologyModels.swift`
  - Define `FreeAstrologyRequest` struct with Codable
  - Properties: year, month, date, hours, minutes, seconds, latitude, longitude, timezone
  - Optional: observationPoint, ayanamsha, houseSystem, language
  - Add CodingKeys for snake_case mapping
  - Add initializer from `BirthDetails` domain model
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Base Request DTO section)
  - File: `AstroSvitla/Models/API/FreeAstrologyModels.swift` (create new file)

- [x] T009 [P] [US2] Create planets response DTOs in `AstroSvitla/Models/API/FreeAstrologyModels.swift`
  - Define `PlanetsResponse`, `PlanetsData`, `PlanetDTO` structs with Codable
  - PlanetDTO properties: name, fullDegree, normalizedDegree, speed, isRetrograde, signNum, sign
  - Add CodingKeys for snake_case mapping
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Planets Response DTO section)
  - File: `AstroSvitla/Models/API/FreeAstrologyModels.swift` (append to file)

- [x] T010 [P] [US2] Create houses response DTOs in `AstroSvitla/Models/API/FreeAstrologyModels.swift`
  - Define `HousesResponse`, `HousesData`, `HouseDTO` structs with Codable
  - HouseDTO properties: houseNum, degree, normalizedDegree, signNum, sign
  - Add CodingKeys for snake_case mapping
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Houses Response DTO section)
  - File: `AstroSvitla/Models/API/FreeAstrologyModels.swift` (append to file)

- [x] T011 [P] [US2] Create aspects response DTOs in `AstroSvitla/Models/API/FreeAstrologyModels.swift`
  - Define `AspectsResponse`, `AspectsData`, `AspectDTO` structs with Codable
  - AspectDTO properties: planet1Name, planet2Name, aspectName, orbDegree (optional)
  - Add CodingKeys for snake_case mapping
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Aspects Response DTO section)
  - File: `AstroSvitla/Models/API/FreeAstrologyModels.swift` (append to file)

- [x] T012 [P] [US2] Create natal chart response DTOs in `AstroSvitla/Models/API/FreeAstrologyModels.swift`
  - Define `NatalChartResponse`, `NatalChartData` structs with Codable
  - NatalChartData properties: chartUrl
  - Add CodingKeys for snake_case mapping
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Natal Chart Response DTO section)
  - File: `AstroSvitla/Models/API/FreeAstrologyModels.swift` (append to file)

### DTO Tests (TDD - Write Before Mapper)

- [ ] T013 [P] [US2] Create DTO parsing tests in `AstroSvitlaTests/Models/FreeAstrologyDTOTests.swift`
  - Test: Decode sample JSON for PlanetDTO
  - Test: Decode sample JSON for HouseDTO
  - Test: Decode sample JSON for AspectDTO
  - Test: Decode sample JSON for NatalChartResponse
  - Use `#expect` assertions
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Testing Strategy section)
  - **MUST FAIL**: DTOs not complete yet
  - File: `AstroSvitlaTests/Models/FreeAstrologyDTOTests.swift` (create new file)

### Mapper Tests (TDD - Write Before Mapper Implementation)

- [ ] T014 [US2] Create mapper tests in `AstroSvitlaTests/Services/FreeAstrology/FreeAstrologyDTOMapperTests.swift`
  - Test: `mapPlanets()` converts PlanetsResponse to [Planet] domain models
  - Test: `mapHouses()` converts HousesResponse to [House] domain models
  - Test: `mapAspects()` converts AspectsResponse to [Aspect] domain models
  - Test: `mapVisualization()` converts NatalChartResponse to ChartVisualization
  - Test: `toDomain()` combines all mapped data into NatalChart
  - Use mock DTO data
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Mapper Implementation section)
  - **MUST FAIL**: Mapper not implemented yet
  - File: `AstroSvitlaTests/Services/FreeAstrology/FreeAstrologyDTOMapperTests.swift` (create new file)
  - Depends on: T008-T012 (DTOs must exist)

### Mapper Implementation

- [x] T015 [US2] Implement DTO mapper in `AstroSvitla/Services/FreeAstrology/FreeAstrologyDTOMapper.swift`
  - Create `enum FreeAstrologyDTOMapper` with static methods
  - Implement `mapPlanets(_ response: PlanetsResponse) throws -> [Planet]`
  - Implement `mapHouses(_ response: HousesResponse) throws -> [House]`
  - Implement `mapAspects(_ response: AspectsResponse) throws -> [Aspect]`
  - Implement `mapVisualization(_ response: NatalChartResponse) -> ChartVisualization`
  - Implement `toDomain(planets:houses:aspects:chart:birthDetails:) throws -> NatalChart`
  - Add `MappingError` enum for error handling
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Mapper Implementation section)
  - **MUST PASS**: Mapper tests (T014) after implementation
  - File: `AstroSvitla/Services/FreeAstrology/FreeAstrologyDTOMapper.swift` (create new file and directory)
  - Depends on: T008-T012 (DTOs), T014 (tests written first)

### API Service Tests (TDD - Write Before Service Implementation)

- [ ] T016 [US2] Create API service tests in `AstroSvitlaTests/Services/FreeAstrology/FreeAstrologyAPIServiceTests.swift`
  - Test: Initialize service with API key and base URL
  - Test: `fetchPlanets()` makes POST to `/western/planets` with correct headers and body
  - Test: `fetchHouses()` makes POST to `/western/houses` with house_system parameter
  - Test: `fetchAspects()` makes POST to `/western/aspects`
  - Test: `fetchNatalWheelChart()` makes POST to `/western/natal-wheel-chart`
  - Test: Authentication header `x-api-key` is present
  - Test: Error handling for 401, 429, 500, network errors
  - Use MockURLSession or URLProtocol stubbing
  - Reference: `specs/003-integrate-free-astrology/research.md` (Error Handling Patterns section)
  - **MUST FAIL**: Service not implemented yet
  - File: `AstroSvitlaTests/Services/FreeAstrology/FreeAstrologyAPIServiceTests.swift` (create new file)
  - Depends on: T008-T012 (DTOs for request/response types)

### API Service Implementation

- [x] T017 [US2] Implement Free Astrology API service in `AstroSvitla/Services/FreeAstrology/FreeAstrologyAPIService.swift`
  - Create `protocol FreeAstrologyAPIServiceProtocol` with 4 endpoint methods
  - Create `final class FreeAstrologyAPIService: FreeAstrologyAPIServiceProtocol`
  - Properties: apiKey, baseURL, urlSession
  - Implement `fetchPlanets(_ request: FreeAstrologyRequest) async throws -> PlanetsResponse`
  - Implement `fetchHouses(_ request: FreeAstrologyRequest) async throws -> HousesResponse`
  - Implement `fetchAspects(_ request: FreeAstrologyRequest) async throws -> AspectsResponse`
  - Implement `fetchNatalWheelChart(_ request: FreeAstrologyRequest) async throws -> NatalChartResponse`
  - Add `x-api-key` header to all requests
  - Add error enum: `FreeAstrologyError` (authenticationFailed, rateLimitExceeded, invalidRequest, serverError, networkError, invalidResponse)
  - Reference: `specs/003-integrate-free-astrology/research.md` (API Endpoints section)
  - **MUST PASS**: API service tests (T016), contract tests (T004-T007)
  - File: `AstroSvitla/Services/FreeAstrology/FreeAstrologyAPIService.swift` (create new file)
  - Depends on: T008-T012 (DTOs), T016 (tests written first)

### Mock for Testing

- [x] T018 [P] [US2] Create mock API service in `AstroSvitlaTests/Mocks/MockFreeAstrologyAPIService.swift`
  - Implement `MockFreeAstrologyAPIService: FreeAstrologyAPIServiceProtocol`
  - Properties for injecting mock responses or errors
  - Useful for integration testing without real API calls
  - File: `AstroSvitlaTests/Mocks/MockFreeAstrologyAPIService.swift` (create new file)
  - Depends on: T017 (service protocol must exist)

**Checkpoint**: FreeAstrologyAPIService complete and all tests passing

---

## Phase 4: User Story 3 - Comment Out Existing Implementations (Priority: P3)

**Goal**: Temporarily disable Swiss Ephemeris and Prokerala services without deleting

**Independent Test**: Build succeeds with commented code, tests are skipped but not removed

### Comment Out Existing Services (Can Be Parallel)

- [x] T019 [P] [US3] Comment out Swiss Ephemeris service in `AstroSvitla/Features/ChartCalculation/Services/SwissEphemerisService.swift`
  - Add block comment: `/* TEMPORARILY DISABLED FOR FREE ASTROLOGY API TESTING */`
  - Add comment: `/* To re-enable: Remove this comment block and update NatalChartService */`
  - Wrap entire file content in comment block
  - Ensure file still compiles (empty or minimal stub if needed)
  - File: `AstroSvitla/Features/ChartCalculation/Services/SwissEphemerisService.swift`

- [x] T020 [P] [US3] Comment out Prokerala API service in `AstroSvitla/Services/Prokerala/ProkralaAPIService.swift`
  - Add block comment: `/* TEMPORARILY DISABLED FOR FREE ASTROLOGY API TESTING */`
  - Add comment: `/* To re-enable: Remove this comment block and update NatalChartService */`
  - Wrap entire file content in comment block
  - File: `AstroSvitla/Services/Prokerala/ProkralaAPIService.swift`

- [x] T021 [P] [US3] Comment out Prokerala DTO mapper in `AstroSvitla/Services/Prokerala/DTOMapper.swift`
  - Add block comment: `/* TEMPORARILY DISABLED FOR FREE ASTROLOGY API TESTING */`
  - Wrap entire file content in comment block
  - File: `AstroSvitla/Services/Prokerala/DTOMapper.swift`

- [x] T022 [P] [US3] Comment out Prokerala models in `AstroSvitla/Models/API/ProkralaModels.swift`
  - Add block comment: `/* TEMPORARILY DISABLED FOR FREE ASTROLOGY API TESTING */`
  - Wrap entire file content in comment block
  - File: `AstroSvitla/Models/API/ProkralaModels.swift`

### Skip Tests for Commented Implementations

- [x] T023 [P] [US3] Skip Swiss Ephemeris tests in `AstroSvitlaTests/Features/ChartCalculation/SwissEphemerisServiceTests.swift` - SKIPPED (no tests per user request)
  - Add `.skip()` to test suite or individual tests
  - Add comment explaining why tests are skipped
  - Do NOT delete tests
  - File: `AstroSvitlaTests/Features/ChartCalculation/SwissEphemerisServiceTests.swift`

- [x] T024 [P] [US3] Skip Prokerala contract tests in `AstroSvitlaTests/Services/Prokerala/NatalWheelChartContractTests.swift` - SKIPPED (no tests per user request)
  - Add `.skip()` to test suite
  - Add comment explaining why tests are skipped
  - File: `AstroSvitlaTests/Services/Prokerala/NatalWheelChartContractTests.swift`

- [x] T025 [P] [US3] Skip Prokerala contract tests in `AstroSvitlaTests/Services/Prokerala/WesternChartDataContractTests.swift` - SKIPPED (no tests per user request)
  - Add `.skip()` to test suite
  - Add comment explaining why tests are skipped
  - File: `AstroSvitlaTests/Services/Prokerala/WesternChartDataContractTests.swift`

- [x] T026 [P] [US3] Skip Prokerala DTO tests in `AstroSvitlaTests/Models/ProkralaDTOTests.swift` - SKIPPED (no tests per user request)
  - Add `.skip()` to test suite
  - Add comment explaining why tests are skipped
  - File: `AstroSvitlaTests/Models/ProkralaDTOTests.swift`

### Verify Build

- [x] T027 [US3] Verify project builds with commented implementations
  - Run: `xcodebuild -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 16' build`
  - Assert: Build succeeds with zero errors ✅
  - Assert: Warnings about unused imports are acceptable
  - Depends on: T019-T022 (all services commented) AND T028 (NatalChartService updated)
  - Note: Completed after T028 integration

**Checkpoint**: Code commented, tests skipped, build succeeds

---

## Phase 5: User Story 4 - Integration with Application Architecture (Priority: P4)

**Goal**: Wire FreeAstrologyAPIService into NatalChartService

**Independent Test**: End-to-end chart generation using Free Astrology API

### Integration Implementation

- [x] T028 [US4] Update NatalChartService to use Free Astrology API in `AstroSvitla/Services/NatalChartService.swift`
  - Update convenience initializer to inject `FreeAstrologyAPIService` instead of `ProkralaAPIService`
  - Change: `let apiService = FreeAstrologyAPIService(...)` instead of `ProkralaAPIService(...)`
  - Update `generateChart()` method to call 4 endpoints in parallel:
    - `let (planetsResp, housesResp, aspectsResp, chartResp) = try await (apiService.fetchPlanets(...), apiService.fetchHouses(...), apiService.fetchAspects(...), apiService.fetchNatalWheelChart(...))`
  - Map responses using `FreeAstrologyDTOMapper.toDomain()`
  - Preserve all error handling and caching logic (unchanged)
  - Reference: `specs/003-integrate-free-astrology/plan.md` (Project Structure section)
  - File: `AstroSvitla/Services/NatalChartService.swift`
  - Depends on: T015 (mapper), T017 (API service), T019-T022 (Prokerala commented out)

### Integration Tests

- [x] T029 [US4] Update integration tests in `AstroSvitlaTests/IntegrationTests/NatalChartGenerationTests.swift` - SKIPPED (no tests per user request)
  - Test: End-to-end chart generation with Free Astrology API
  - Test: Verify NatalChart has complete data (planets, houses, aspects, visualization)
  - Test: Verify chart caching works (generate twice, second is from cache)
  - Test: Verify offline mode returns cached chart
  - Use real API or mock depending on test configuration
  - Reference: `specs/003-integrate-free-astrology/data-model.md` (Testing Strategy section)
  - File: `AstroSvitlaTests/IntegrationTests/NatalChartGenerationTests.swift`
  - Depends on: T028 (integration complete)

**Checkpoint**: End-to-end chart generation working with Free Astrology API

---

## Phase 6: Polish & Validation

**Purpose**: Final validation, documentation, and cleanup

- [ ] T030 [P] [Polish] Run quickstart manual test scenarios
  - Execute all 6 scenarios from `specs/003-integrate-free-astrology/quickstart.md`
  - Scenario 1: Generate complete natal chart
  - Scenario 2: Offline behavior with cached chart
  - Scenario 3: Rate limit handling (run sparingly)
  - Scenario 4: Invalid input handling
  - Scenario 5: Chart image display
  - Scenario 6: Different house systems
  - Document results in quickstart.md or create test report
  - Reference: `specs/003-integrate-free-astrology/quickstart.md`
  - Depends on: T028 (integration complete)

- [ ] T031 [P] [Polish] Verify all automated tests pass
  - Run: `xcodebuild test -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15'`
  - Assert: Contract tests pass (T004-T007)
  - Assert: DTO tests pass (T013)
  - Assert: Mapper tests pass (T014)
  - Assert: API service tests pass (T016)
  - Assert: Integration tests pass (T029)
  - Assert: Skipped tests remain skipped (T023-T026)
  - Depends on: All implementation tasks complete

- [ ] T032 [Polish] Create comparison documentation between APIs
  - Compare: Free Astrology API vs Prokerala API data completeness
  - Compare: Response times, accuracy, limitations
  - Document: Which fields differ, format differences
  - Add findings to `specs/003-integrate-free-astrology/comparison.md` (new file)
  - Reference: Success Criteria SC-008 from spec.md
  - Depends on: T030 (manual testing complete)

- [ ] T033 [Polish] Code review and cleanup
  - Review: All new code follows Swift conventions
  - Review: TDD followed (tests written first, implementation second)
  - Review: Clear separation of concerns (service, mapper, DTOs)
  - Review: Comments are clear about commented-out code
  - Review: No secrets in version control
  - Cleanup: Remove any debug print statements
  - Cleanup: Format code consistently

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Phase 1 (Setup)**: T001-T003 - No dependencies, can start immediately
2. **Phase 2 (US1 - Research)**: T004-T007 - Can start after T001 (API key configured)
3. **Phase 3 (US2 - API Client)**: T008-T018 - Can start after Phase 1 complete
4. **Phase 4 (US3 - Comment)**: T019-T027 - Can start after Phase 1 complete (parallel with US2)
5. **Phase 5 (US4 - Integration)**: T028-T029 - Depends on US2 and US3 complete
6. **Phase 6 (Polish)**: T030-T033 - Depends on US4 complete

### User Story Dependencies

- **US1 (Research/Contract Tests)**: Independent, can run after setup
- **US2 (API Client)**: Independent, can run after setup
- **US3 (Comment Out)**: Independent, can run after setup (parallel with US1 and US2)
- **US4 (Integration)**: Depends on US2 (API client ready) and US3 (old code disabled)

### Task Dependencies Within Phases

**Phase 2 (US1)**:
- T004-T007 are fully parallel [P]

**Phase 3 (US2)**:
- T008-T012 are parallel [P] (DTO models)
- T013 is parallel with T008-T012 [P] (DTO tests)
- T014 depends on T008-T012 (needs DTOs)
- T015 depends on T014 (tests first)
- T016 depends on T008-T012 (needs DTOs for service types)
- T017 depends on T016 (tests first)
- T018 depends on T017 [P] (needs protocol)

**Phase 4 (US3)**:
- T019-T022 are fully parallel [P] (commenting different files)
- T023-T026 are fully parallel [P] (skipping different test files)
- T027 depends on T019-T022 (verify after commenting)

**Phase 5 (US4)**:
- T028 depends on T015, T017, T019-T022
- T029 depends on T028

**Phase 6 (Polish)**:
- T030-T033 all depend on T028-T029, but T030-T031 are parallel [P]

---

## Parallel Execution Examples

### Launch All Contract Tests Together (Phase 2):
```bash
# All 4 contract tests can run in parallel
Task: "Create planets endpoint contract test in AstroSvitlaTests/Services/FreeAstrology/PlanetsEndpointContractTests.swift"
Task: "Create houses endpoint contract test in AstroSvitlaTests/Services/FreeAstrology/HousesEndpointContractTests.swift"
Task: "Create aspects endpoint contract test in AstroSvitlaTests/Services/FreeAstrology/AspectsEndpointContractTests.swift"
Task: "Create natal chart endpoint contract test in AstroSvitlaTests/Services/FreeAstrology/NatalChartEndpointContractTests.swift"
```

### Launch All DTO Models Together (Phase 3):
```bash
# All DTO model tasks can run in parallel (appending to same file handled carefully)
Task: "Create Free Astrology request DTO in AstroSvitla/Models/API/FreeAstrologyModels.swift"
Task: "Create planets response DTOs in AstroSvitla/Models/API/FreeAstrologyModels.swift"
Task: "Create houses response DTOs in AstroSvitla/Models/API/FreeAstrologyModels.swift"
Task: "Create aspects response DTOs in AstroSvitla/Models/API/FreeAstrologyModels.swift"
Task: "Create natal chart response DTOs in AstroSvitla/Models/API/FreeAstrologyModels.swift"
```

### Launch All Comment Tasks Together (Phase 4):
```bash
# All commenting tasks can run in parallel
Task: "Comment out Swiss Ephemeris service in AstroSvitla/Features/ChartCalculation/Services/SwissEphemerisService.swift"
Task: "Comment out Prokerala API service in AstroSvitla/Services/Prokerala/ProkralaAPIService.swift"
Task: "Comment out Prokerala DTO mapper in AstroSvitla/Services/Prokerala/DTOMapper.swift"
Task: "Comment out Prokerala models in AstroSvitla/Models/API/ProkralaModels.swift"
```

---

## Implementation Strategy

### TDD First (Constitutional Requirement)

1. **Tests Before Code**: Always write tests FIRST, verify they FAIL, then implement
2. **Red → Green → Refactor**: Standard TDD workflow
3. **Contract Tests Define Behavior**: T004-T007 define what API should return
4. **Unit Tests Guide Implementation**: T013, T014, T016 guide mapper and service design

### MVP Approach

**Minimal Working Integration**:
1. Complete Phase 1 (Setup): T001-T003
2. Complete Phase 2 (Contract Tests): T004-T007 → Validate API works
3. Complete Phase 3 (US2 up to T017): Basic API client working
4. **STOP and VALIDATE**: Can make API calls and get responses
5. Continue with mapping, commenting, integration

### Incremental Delivery

1. **Milestone 1**: Contract tests passing (API validated)
2. **Milestone 2**: API client working (can fetch data)
3. **Milestone 3**: Mapper working (DTOs → Domain models)
4. **Milestone 4**: Old code commented (isolated testing environment)
5. **Milestone 5**: Integration complete (end-to-end working)
6. **Milestone 6**: Manual validation (production-ready)

### Rollback Strategy

If Free Astrology API proves inadequate:
1. Uncomment Swiss Ephemeris/Prokerala code (T019-T022)
2. Re-enable skipped tests (T023-T026)
3. Revert NatalChartService changes (T028)
4. Remove Free Astrology implementation (optional, or keep for future reference)

---

## Notes

- **TDD Non-Negotiable**: Per Constitution Principle III, tests must be written first
- **[P] = Parallel**: Different files, no shared state, safe to run concurrently
- **Absolute Paths**: All file paths are from repository root for clarity
- **Comment vs Delete**: Existing code is commented (never deleted) for easy rollback
- **Independent Stories**: Each user story should be independently testable at its checkpoint
- **Build Must Pass**: After commenting existing code (T027), build must succeed
- **API Key Security**: Never commit real API keys, use Config.swift (gitignored)

---

**Total Tasks**: 33
**Estimated Completion**: 20-25 hours (with TDD, contract tests, integration testing)
**Risk Mitigation**: Rollback strategy documented if Free Astrology API unsuitable
