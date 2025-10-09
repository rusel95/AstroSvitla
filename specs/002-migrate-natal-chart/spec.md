# Feature Specification: Migrate to Prokerala Astrology API for Natal Chart Calculations and Visualization

**Feature Branch**: `002-migrate-natal-chart`
**Created**: 2025-10-09
**Status**: Draft
**Input**: User description: "Migrate natal chart calculations and visualization to Prokerala Astrology API to replace current framework with a single unified API provider"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Accurate Natal Chart with Visualization (Priority: P1)

Users need to generate and view their natal chart with accurate planetary positions, houses, aspects, and a visual chart wheel, all sourced from a reliable astrological calculation service.

**Why this priority**: This is the core value proposition of the app - providing users with their natal chart data and visualization. Without this, the app has no primary function.

**Independent Test**: Can be fully tested by entering birth data (date, time, location) and verifying that the system displays both calculated astrological data (planets, houses, aspects) and a chart wheel image.

**Acceptance Scenarios**:

1. **Given** a user has entered valid birth data (date, time, location), **When** they request their natal chart, **Then** the system displays planetary positions with zodiac signs and degrees
2. **Given** a user has entered valid birth data, **When** they request their natal chart, **Then** the system displays house cusps with signs and degrees
3. **Given** a user has entered valid birth data, **When** they request their natal chart, **Then** the system displays major aspects between planets (conjunctions, oppositions, trines, squares, sextiles)
4. **Given** a user has entered valid birth data, **When** they request their natal chart, **Then** the system displays a visual chart wheel showing all calculated data
5. **Given** a user views their natal chart, **When** the chart data is displayed, **Then** retrograde planets are clearly indicated

---

### User Story 2 - Receive Chart Data Quickly (Priority: P2)

Users expect their natal chart calculations and visualization to load quickly without long wait times, ensuring a smooth experience.

**Why this priority**: User experience quality depends on response time. While not as critical as having the feature work at all, slow performance will significantly impact user satisfaction and retention.

**Independent Test**: Can be tested by measuring the time between submitting birth data and receiving both calculated data and chart visualization.

**Acceptance Scenarios**:

1. **Given** a user has submitted birth data, **When** the system processes the request, **Then** planetary positions are displayed within 3 seconds
2. **Given** a user has submitted birth data, **When** the system processes the request, **Then** the chart wheel visualization appears within 5 seconds
3. **Given** the external API is temporarily unavailable, **When** a user requests a chart, **Then** the system displays a clear error message explaining the issue

---

### User Story 3 - Access Charts Offline or During API Outages (Priority: P3)

Users who have previously generated charts should be able to view their saved chart data even when the API service is unavailable.

**Why this priority**: This enhances reliability and user trust, but is secondary to having the core feature working. Users can tolerate occasional inability to generate new charts more than they can tolerate the feature not existing.

**Independent Test**: Can be tested by generating a chart while online, then disconnecting from the API service and verifying that the previously generated chart remains viewable.

**Acceptance Scenarios**:

1. **Given** a user has previously generated a natal chart, **When** they open the app without internet connectivity, **Then** they can still view their saved chart data
2. **Given** a user has previously generated a natal chart, **When** they open the app without internet connectivity, **Then** they can still view their saved chart wheel image
3. **Given** a user attempts to generate a new chart while offline, **When** they submit birth data, **Then** the system clearly indicates that internet connectivity is required

---

### Edge Cases

- What happens when birth location is ambiguous (e.g., multiple cities with the same name)?
- How does the system handle birth times at midnight or during daylight saving time transitions?
- What happens when the API rate limit is exceeded (5 requests per minute on free tier)?
- How does the system handle very old birth dates (e.g., before 1900) or future dates?
- What happens if the chart wheel image fails to load but calculations succeed?
- How does the system handle partial API responses (e.g., calculations succeed but chart image generation fails)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST calculate planetary positions (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto) with zodiac signs and degrees for given birth data
- **FR-002**: System MUST calculate house cusps for all 12 houses with zodiac signs and degrees
- **FR-003**: System MUST calculate major aspects between planets (conjunction, opposition, trine, square, sextile) with degrees of separation
- **FR-004**: System MUST identify and indicate retrograde planets
- **FR-005**: System MUST generate a visual natal chart wheel showing planets, houses, signs, and aspects
- **FR-006**: System MUST support chart wheel visualization in both SVG and PNG formats
- **FR-007**: System MUST handle location data including city name, country, latitude, and longitude for accurate calculations
- **FR-008**: System MUST handle timezone and daylight saving time considerations for birth time accuracy
- **FR-009**: System MUST store generated chart data locally for offline access
- **FR-010**: System MUST store chart wheel images locally for offline viewing
- **FR-011**: System MUST handle API authentication and rate limiting (5,000 credits/month on free tier, 5 requests per minute)
- **FR-012**: System MUST display clear error messages when API requests fail, including network errors, authentication failures, and rate limit exceeded
- **FR-013**: System MUST validate birth data before sending API requests (valid date range, valid coordinates, valid time format)
- **FR-014**: System MUST support Placidus house system for Western astrology calculations

### Key Entities

- **Birth Data**: Represents the input required for natal chart calculation - includes date (year, month, day), time (hour, minute), and location (city, country, latitude, longitude, timezone)
- **Natal Chart**: Represents the complete astrological chart - includes planetary positions, house cusps, aspects, retrograde indicators, and metadata (calculation timestamp, house system used)
- **Planet Position**: Represents a celestial body's position - includes planet name, zodiac sign, degree, minute, house placement, retrograde status, and speed
- **House Cusp**: Represents the starting point of an astrological house - includes house number (1-12), zodiac sign, and degree
- **Aspect**: Represents an angular relationship between two planets - includes planet pair, aspect type (conjunction, opposition, etc.), exact angle, orb (deviation from exact), and applying/separating status
- **Chart Visualization**: Represents the visual chart wheel - includes image format (SVG/PNG), image data, dimensions, and generation timestamp

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can generate a complete natal chart (calculations + visualization) in under 5 seconds under normal network conditions
- **SC-002**: 95% of chart generation requests complete successfully without errors
- **SC-003**: Previously generated charts remain accessible and viewable when the device is offline
- **SC-004**: Users can view chart wheel visualizations that clearly display all planets, houses, and major aspects
- **SC-005**: System handles API rate limiting gracefully without crashing or losing user data
- **SC-006**: Chart calculations are accurate to within standard astrological precision (within 1 degree of expected values)
- **SC-007**: Users receive clear, actionable error messages for all failure scenarios (network issues, invalid data, API errors)
- **SC-008**: System supports the monthly API credit limit (5,000 requests) without degradation or unexpected costs

## Assumptions

- Prokerala Astrology API provides sufficient accuracy for Western tropical astrology calculations
- The free tier's 5,000 credits/month limit is sufficient for the application's user base and usage patterns
- Chart wheel images provided by the API are of sufficient quality for display on iOS devices
- The API's 5 requests/minute rate limit can be managed through appropriate request throttling and caching
- Users primarily need Western tropical astrology calculations (as opposed to Vedic/sidereal)
- Placidus house system is the standard choice for Western astrology and provides accurate latitude-based house calculations
- Birth data validation can be performed client-side before API requests to reduce unnecessary API calls
- Local storage capacity on iOS devices is sufficient for caching multiple natal charts and their visualizations
- Network connectivity is required only for generating new charts, not for viewing previously generated charts

## Dependencies

- Prokerala Astrology API availability and reliability
- API authentication credentials (API key/token)
- Device internet connectivity for new chart generation
- Device local storage for chart caching
- Accurate timezone and location data for birth information

## Onboarding Considerations

- Highlight use of Placidus house system as an advantage during user onboarding
- Emphasize professional-grade accuracy from industry-standard calculations
- Communicate that the app uses the same calculation methods as professional astrologers

## Out of Scope

- Support for astrological systems other than Western tropical astrology (Vedic, Chinese, etc.)
- Advanced chart types (progressions, transits, synastry, composite charts)
- Astrological interpretations or readings (focusing only on calculations and visualization)
- Custom chart styling or theming options for the wheel visualization
- Manual coordinate entry (assuming location search/selection handles this)
- Historical ephemeris data validation or correction
- Support for hypothetical points (Lilith, Part of Fortune, etc.) beyond major planets
- Chart comparison or compatibility features
- Migration of existing chart data from the current framework (will start fresh)
- Support for multiple house systems (Placidus only for this feature)
