# Feature Specification: Integrate Free Astrology API

**Feature Branch**: `003-integrate-free-astrology`
**Created**: 2025-10-10
**Status**: Draft
**Input**: User description: "Integrate Free Astrology API as a test alternative to existing implementations while preserving Swiss Ephemeris and Prokerala API code"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - API Research and Feasibility Assessment (Priority: P1)

As a developer evaluating the Free Astrology API, I need to verify that the API provides all necessary astrological data (planets, houses, aspects, natal wheel chart) with sufficient accuracy and detail to support the application's requirements, so I can determine if it's a viable alternative to existing implementations.

**Why this priority**: Without validating API capabilities, we cannot proceed with integration. This is the foundation that determines if the feature is viable.

**Independent Test**: Can be fully tested by making API calls to all four endpoints (planets, houses, aspects, natal-wheel-chart) with test birth data and comparing response completeness against current system requirements.

**Acceptance Scenarios**:

1. **Given** valid birth details (date, time, location), **When** calling the planets endpoint, **Then** response includes all major planets (Sun through Pluto), Ascendant, nodes, and includes position, sign, degree, retrograde status
2. **Given** valid birth details, **When** calling the houses endpoint with Placidus system, **Then** response includes all 12 house cusps with degrees and signs
3. **Given** valid birth details, **When** calling the aspects endpoint, **Then** response includes major aspects (conjunction, opposition, trine, square, sextile) between planets with degree information
4. **Given** valid birth details, **When** calling the natal-wheel-chart endpoint, **Then** response provides an SVG chart URL that is accessible and renders correctly

---

### User Story 2 - New API Client Implementation (Priority: P2)

As a developer, I need to create a separate, standalone API client for Free Astrology API that can coexist with existing implementations, so I can test the new API without disrupting or removing current functionality.

**Why this priority**: Once feasibility is confirmed, we need a clean implementation that doesn't interfere with existing code. This allows A/B testing and easy rollback if needed.

**Independent Test**: Can be tested independently by instantiating the new API client and verifying it can successfully fetch data from all four Free Astrology API endpoints without requiring any changes to existing services.

**Acceptance Scenarios**:

1. **Given** a new `FreeAstrologyAPIService` class, **When** initialized with API credentials, **Then** the service can make authenticated requests to all endpoints
2. **Given** valid birth details, **When** calling `fetchPlanets()`, **Then** service returns structured planet position data
3. **Given** valid birth details and house system preference, **When** calling `fetchHouses()`, **Then** service returns all house cusp data
4. **Given** valid birth details, **When** calling `fetchAspects()`, **Then** service returns aspect relationships between planets
5. **Given** valid birth details, **When** calling `fetchNatalWheelChart()`, **Then** service returns SVG chart URL or data

---

### User Story 3 - Comment Out Existing Implementations (Priority: P3)

As a developer testing the Free Astrology API, I need to temporarily disable Swiss Ephemeris and Prokerala API integrations through code comments (not deletion), so I can focus testing on the new API while preserving the ability to quickly restore previous implementations.

**Why this priority**: After the new API client is built, we need to isolate it for testing. Commenting (not deleting) ensures safe rollback.

**Independent Test**: Can be tested by verifying that the application compiles with commented-out code, existing tests are skipped but not removed, and the code can be uncommented to restore functionality.

**Acceptance Scenarios**:

1. **Given** SwissEphemerisService implementation, **When** code is commented with clear markers, **Then** service is not active but code remains intact for future restoration
2. **Given** ProkralaAPIService implementation, **When** code is commented with clear markers, **Then** service is not active but code remains intact
3. **Given** commented implementations, **When** building the project, **Then** build succeeds without errors related to commented code
4. **Given** commented implementations, **When** reviewing code, **Then** clear comments indicate why code is disabled and how to re-enable

---

### User Story 4 - Integration with Application Architecture (Priority: P4)

As a developer, I need to integrate the Free Astrology API client into the existing application architecture (NatalChartService orchestration layer), so users can generate natal charts using the new API through the same interface.

**Why this priority**: After validating the new API works standalone, we need to wire it into the app so it can be tested in the actual user workflow.

**Independent Test**: Can be tested by configuring the app to use FreeAstrologyAPIService through NatalChartService and verifying that chart generation works end-to-end with the new API.

**Acceptance Scenarios**:

1. **Given** FreeAstrologyAPIService implementation, **When** NatalChartService is configured to use it, **Then** chart generation flows work without errors
2. **Given** birth details input, **When** generating chart via new API, **Then** domain models (NatalChart) are correctly populated with API response data
3. **Given** successful API response, **When** caching is enabled, **Then** charts are cached using existing ChartCacheService infrastructure
4. **Given** generated chart, **When** displayed to user, **Then** all chart elements (planets, houses, aspects) render correctly

---

### Edge Cases

- What happens when Free Astrology API is unavailable or returns errors? (Should gracefully handle and potentially fall back to cached data)
- How does the system handle rate limits for the Free Astrology API? (Need to implement rate limiting similar to existing implementation)
- What happens when API returns incomplete data (e.g., missing planets or aspects)? (Should validate response and provide meaningful error messages)
- How do we handle authentication failures with the Free Astrology API? (Need robust error handling and retry logic)
- What if the SVG chart URL expires or is inaccessible? (Should cache downloaded chart images similar to existing implementation)
- How do we ensure commented code doesn't cause compilation warnings or IDE issues? (Use proper comment blocks and conditional compilation if needed)
- What happens when switching between different API implementations? (Need clear configuration mechanism)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST analyze Free Astrology API documentation for planets, houses, aspects, and natal-wheel-chart endpoints to verify data completeness
- **FR-002**: System MUST create a new `FreeAstrologyAPIService` class that implements API client for all four endpoints
- **FR-003**: New API client MUST support POST requests with birth details (year, month, date, hours, minutes, seconds, latitude, longitude, timezone)
- **FR-004**: System MUST support configurable house systems (Placidus, Koch, Whole Signs, etc.) matching existing functionality
- **FR-005**: System MUST support configurable observation point (topocentric/geocentric) and ayanamsha (tropical/sayana/lahiri)
- **FR-006**: System MUST handle API authentication (API key or other required credentials)
- **FR-007**: System MUST map Free Astrology API responses to existing domain models (NatalChart, Planet, House, Aspect)
- **FR-008**: System MUST comment out (not delete) SwissEphemerisService code with clear markers for future restoration
- **FR-009**: System MUST comment out (not delete) ProkralaAPIService code with clear markers for future restoration
- **FR-010**: System MUST maintain all existing domain models and caching infrastructure without modification
- **FR-011**: System MUST integrate FreeAstrologyAPIService with existing NatalChartService orchestration layer
- **FR-012**: System MUST support chart image retrieval (SVG format) from natal-wheel-chart endpoint
- **FR-013**: System MUST handle API errors gracefully with meaningful error messages
- **FR-014**: System MUST implement rate limiting to avoid exceeding API quotas
- **FR-015**: System MUST preserve all existing tests for commented implementations (marked as skipped, not deleted)

### Key Entities

- **FreeAstrologyAPIService**: New service class responsible for making HTTP requests to Free Astrology API endpoints, handling authentication, and returning raw API responses
- **FreeAstrologyModels**: Data transfer objects (DTOs) representing Free Astrology API request/response structures for planets, houses, aspects, and chart images
- **FreeAstrologyDTOMapper**: Mapping layer to convert Free Astrology API responses into existing domain models (NatalChart, Planet, House, Aspect, ChartVisualization)
- **APIConfiguration**: Configuration structure to manage API credentials, base URLs, and endpoint paths for Free Astrology API
- **NatalChartService**: Existing orchestrator service that will be updated to optionally use FreeAstrologyAPIService instead of commented implementations

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developer can make successful API calls to all four Free Astrology API endpoints and receive complete response data within 3 seconds per request
- **SC-002**: FreeAstrologyAPIService successfully maps API responses to NatalChart domain model with 100% of required fields populated (planets, houses, aspects)
- **SC-003**: Application builds successfully with SwissEphemerisService and ProkralaAPIService code commented out, with zero compilation errors
- **SC-004**: Chart generation using Free Astrology API produces visually accurate natal charts that match existing chart output (visual comparison test)
- **SC-005**: All existing unit tests are preserved (marked as skipped) and can be re-enabled by uncommenting implementations
- **SC-006**: New API integration includes error handling for at least 5 common failure scenarios (network errors, authentication failures, invalid input, rate limits, incomplete responses)
- **SC-007**: Code review confirms clear separation of concerns: new FreeAstrologyAPIService exists independently without modifications to existing service interfaces
- **SC-008**: Documentation includes comparison matrix showing data completeness between Free Astrology API and existing implementations (which fields are available, format differences, accuracy considerations)

## Technical Analysis

### API Capabilities Assessment

Based on documentation review, Free Astrology API provides:

**Planets Endpoint** (`/western/planets`):
- ✅ All major planets (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto)
- ✅ Ascendant
- ✅ Nodes, Chiron, Lilith
- ✅ Asteroids (Ceres, Vesta, Juno, Pallas)
- ✅ Position data: degrees, normalized degrees, retrograde status, zodiac sign
- ✅ Configurable observation point and ayanamsha

**Houses Endpoint** (`/western/houses`):
- ✅ Multiple house systems (Placidus, Koch, Whole Signs, Equal, Regiomontanus, Porphyry, Vehlow)
- ✅ All 12 house cusps with degree and sign data
- ✅ Same configuration options as planets

**Aspects Endpoint** (`/western/aspects`):
- ✅ All major aspects (conjunction, opposition, trine, square, sextile, semi-sextile, quintile, septile, octile, novile, quincunx, sesquiquadrate)
- ✅ Configurable orb values
- ✅ Ability to exclude specific planets or aspects
- ✅ Aspect relationships between all planet pairs

**Natal Wheel Chart Endpoint** (`/western/natal-wheel-chart`):
- ✅ SVG chart generation with URL response
- ✅ Customizable colors and appearance
- ✅ Multiple language support (9+ languages)
- ✅ All configuration options from other endpoints

**Conclusion**: API appears feature-complete for basic natal chart generation. Sufficient for testing as alternative implementation.

### Implementation Strategy

1. **Phase 1 - Research**: Make test API calls to verify actual behavior matches documentation
2. **Phase 2 - Models**: Create DTOs for API request/response structures
3. **Phase 3 - Service**: Implement FreeAstrologyAPIService with all four endpoint methods
4. **Phase 4 - Mapping**: Create mapper from Free Astrology DTOs to existing domain models
5. **Phase 5 - Comment**: Carefully comment out existing implementations with restoration instructions
6. **Phase 6 - Integration**: Wire new service into NatalChartService with configuration flag
7. **Phase 7 - Testing**: Comprehensive testing of all chart generation scenarios

### Risks and Mitigations

**Risk**: Free Astrology API may have different calculation methods leading to slightly different results
**Mitigation**: Document differences and validate accuracy against known ephemeris data

**Risk**: API may have usage limits or costs that impact feasibility
**Mitigation**: Check API pricing/limits early in research phase; implement rate limiting

**Risk**: SVG chart format may be incompatible with existing image handling
**Mitigation**: Test SVG parsing and rendering early; may need conversion to PNG

**Risk**: Commenting out code may introduce subtle bugs or missing dependencies
**Mitigation**: Thorough testing after commenting; use compiler flags or protocol-based injection if needed

## Next Steps

After specification approval, proceed to `/plan` to create detailed implementation plan including:
- API endpoint testing and validation scripts
- Service architecture and class diagrams
- DTO model definitions
- Mapper implementation strategy
- Configuration management approach
- Test plan and validation criteria
