# Feature Specification: Integrate New Astrology API

**Feature Branch**: `004-integrate-new-astrology`  
**Created**: October 11, 2025  
**Status**: Draft  
**Input**: User description: "Integrate new astrology API from api.astrology-api.io for natal chart generation while keeping existing API code hidden as fallback option"

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a user of AstroSvitla, I need the application to use a better astrology API for natal chart generation that provides more accurate calculations and better visual chart representations, while maintaining all existing functionality and keeping previous API implementations as hidden fallback options in case a rollback is needed.

### Acceptance Scenarios
1. **Given** a user provides birth details, **When** they generate a natal chart, **Then** the system uses the new api.astrology-api.io API and returns complete chart data with planets, houses, aspects, and SVG visualization
2. **Given** the new API is integrated, **When** a user generates multiple charts, **Then** the existing caching and offline functionality continues to work seamlessly  
3. **Given** the old API implementations exist, **When** reviewing the codebase, **Then** previous API code (Free Astrology API, Prokerala API) is commented out but preserved for potential future restoration
4. **Given** the new API integration, **When** comparing chart quality, **Then** the new API provides superior visual charts and more accurate astronomical calculations than previous implementations

### Edge Cases
- What happens when the new API is temporarily unavailable?
- How does the system handle rate limiting from the new API?
- What occurs if the new API response format changes?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST integrate api.astrology-api.io API for natal chart calculations using the `/api/v3/charts/natal` endpoint
- **FR-002**: System MUST generate SVG chart visualizations using the `/api/v3/svg/natal` endpoint
- **FR-003**: System MUST support birth data input with year, month, day, hour, minute, city, and country_code
- **FR-004**: System MUST preserve all existing domain models (NatalChart, Planet, House, Aspect) without modification
- **FR-005**: System MUST maintain existing caching infrastructure and offline support functionality
- **FR-006**: System MUST comment out (not delete) existing Free Astrology API implementation with clear restoration markers
- **FR-007**: System MUST comment out (not delete) existing Prokerala API implementation with clear restoration markers  
- **FR-008**: System MUST implement proper error handling for new API including authentication, rate limiting, and network failures
- **FR-009**: System MUST map new API response data to existing domain models through a dedicated mapper component
- **FR-010**: System MUST support Placidus house system (configurable to other systems supported by the API)
- **FR-011**: System MUST include major planets (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn) and outer planets (Uranus, Neptune, Pluto)
- **FR-012**: System MUST calculate and include major aspects (conjunction, opposition, trine, square, sextile) with proper orb tolerances
- **FR-013**: System MUST handle timezone conversion automatically through city/country_code input
- **FR-014**: System MUST implement rate limiting to respect API quotas and avoid service disruption
- **FR-015**: System MUST preserve all existing tests by commenting them out (not deleting) when they reference old API implementations

### Key Entities *(include if feature involves data)*
- **AstrologyAPIService**: New HTTP client service for communicating with api.astrology-api.io endpoints, handling authentication, request/response parsing, and error management
- **AstrologyAPIDTOModels**: Data transfer objects representing the JSON structure returned by api.astrology-api.io for natal charts and SVG generation
- **AstrologyAPIDTOMapper**: Mapping component that transforms api.astrology-api.io response data into existing domain models (NatalChart, Planet, House, Aspect, ChartVisualization)
- **AstrologyAPIConfiguration**: Configuration structure for storing API credentials, base URLs, and endpoint settings specific to the new API provider

---

## Success Criteria

- Users experience improved chart accuracy with professional-grade astronomical calculations
- Chart generation time remains under 3 seconds for complete natal chart with visualization
- SVG chart quality is visually superior to previous implementations
- 100% of existing functionality continues to work without user-facing changes
- Caching and offline features operate identically to current implementation
- Previous API code remains in codebase as commented fallback options
- Integration tests pass with new API while maintaining compatibility with existing domain models
- API rate limits are respected with no service disruptions during normal usage

## Assumptions

- The new api.astrology-api.io API provides free tier access sufficient for development and testing
- API response times are consistent with current implementation (under 2 seconds per request)
- The API supports all house systems currently used in the application
- Existing SwiftData caching models are compatible with new API response data
- No changes to user interface are required for this backend API integration
- Current error handling patterns can be adapted for the new API's error responses
