# Feature Specification: Enhance Astrological Report Completeness & Source Transparency# Feature Specification: [FEATURE NAME]



**Feature Branch**: `005-enhance-astrological-report`  **Feature Branch**: `[###-feature-name]`  

**Created**: October 16, 2025  **Created**: [DATE]  

**Status**: Draft  **Status**: Draft  

**Input**: User description: "Enhance Astrological Report Completeness & Source Transparency"**Input**: User description: "$ARGUMENTS"



## User Scenarios & Testing *(mandatory)*## User Scenarios & Testing *(mandatory)*



### User Story 1 - Complete Astrological Point Coverage (Priority: P1)

  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.

An astrology expert generates a natal chart report for a client and expects all critical astrological points to be accurately calculated and interpreted, including Ascendant, Midheaven (MC), Karmic Nodes (North/South), Lilith, and house rulers.  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,

  you should still have a viable MVP (Minimum Viable Product) that delivers value.

**Why this priority**: This is the foundation of accurate astrological analysis. Without accurate node positions and complete point coverage, reports contain incorrect information that misleads users and damages credibility with professional astrologers.  

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.

**Independent Test**: Generate a report for a known birth chart (e.g., birth data with nodes in Taurus/Scorpio) and verify that all astrological points match expected positions within 1 degree accuracy. Report must include explicit interpretation of Ascendant, MC, both nodes with house placements, and Lilith.  Think of each story as a standalone slice of functionality that can be:

  - Developed independently

**Acceptance Scenarios**:  - Tested independently

  - Deployed independently

1. **Given** a user generates a natal chart report, **When** the report is displayed, **Then** it includes accurate positions for North Node, South Node, and Lilith matching astronomical calculations  - Demonstrated to users independently

2. **Given** a report is generated, **When** viewing the detailed analysis section, **Then** it contains explicit interpretation of Ascendant's meaning for personality and life approach

3. **Given** a report is generated, **When** viewing the detailed analysis section, **Then** it contains explicit interpretation of Midheaven's significance for career and public image

4. **Given** a report contains karmic nodes, **When** reading the nodes analysis, **Then** it describes both the North Node (soul's purpose/where to go) and South Node (past patterns/what to leave behind) with their specific house placements### User Story 1 - [Brief Title] (Priority: P1)

5. **Given** nodes are in opposite houses (e.g., 3rd-9th axis), **When** reading the analysis, **Then** it explains the house axis journey (e.g., "from student to teacher")

6. **Given** a report is generated, **When** reviewing planetary aspects, **Then** all aspects between nodes and planets are listed and interpreted[Describe this user journey in plain language]

7. **Given** Lilith is calculated, **When** viewing the analysis, **Then** it includes Lilith's placement by sign and house with interpretation of shadow themes

**Why this priority**: [Explain the value and why it has this priority level]

---

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

### User Story 2 - Complete House Ruler Analysis (Priority: P1)

**Acceptance Scenarios**:

An astrology student wants to understand not just where planets are, but also which planet rules each house and what that ruler's placement means for that life area.

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

**Why this priority**: House rulers are fundamental to traditional astrology interpretation. Without this, users miss critical connections like "1st house in Aries ruled by Mars in 7th house = personality expresses through relationships."2. **Given** [initial state], **When** [action], **Then** [expected outcome]



**Independent Test**: Generate a report and verify that for all 12 houses, the ruling planet is identified, its house placement is noted, and the interpretation explains what this rulership means for that life area.---



**Acceptance Scenarios**:### User Story 2 - [Brief Title] (Priority: P2)



1. **Given** a natal chart with specific house cusps, **When** the report is generated, **Then** each of the 12 houses has its ruling planet identified based on the sign on the cusp[Describe this user journey in plain language]

2. **Given** house rulers are calculated, **When** reading the analysis, **Then** for each house, the report states where the ruling planet is located (house and sign)

3. **Given** the Ascendant ruler is identified, **When** viewing the analysis, **Then** it explains how the Ascendant ruler's placement influences the native's overall life approach and self-expression**Why this priority**: [Explain the value and why it has this priority level]

4. **Given** the 10th house (career) ruler is placed in another house, **When** reading career analysis, **Then** the interpretation connects the 10th house ruler's location to career expression

5. **Given** a house ruler makes aspects to other planets, **When** reading that house's interpretation, **Then** these aspects are mentioned as modifying factors**Independent Test**: [Describe how this can be tested independently]



---**Acceptance Scenarios**:



### User Story 3 - Comprehensive Aspect Coverage (Priority: P2)1. **Given** [initial state], **When** [action], **Then** [expected outcome]



A professional astrologer reviewing AI-generated reports notices that only the first few aspects are interpreted, missing important planetary relationships that appear later in the aspect list.---



**Why this priority**: Complex natal charts can have 20-40 aspects. Missing aspects means missing important planetary dynamics that explain personality traits and life events.### User Story 3 - [Brief Title] (Priority: P3)



**Independent Test**: Generate a report for a chart with 25+ aspects and verify that at least the top 20 aspects (sorted by tightness of orb) are mentioned in the detailed analysis section.[Describe this user journey in plain language]



**Acceptance Scenarios**:**Why this priority**: [Explain the value and why it has this priority level]



1. **Given** a natal chart with multiple planetary aspects, **When** the report is generated, **Then** at least 20 aspects are included in the analysis (up from current 8)**Independent Test**: [Describe how this can be tested independently]

2. **Given** aspects are presented, **When** reviewing them, **Then** they are prioritized by orb tightness (closest to exact aspects listed first)

3. **Given** an aspect is mentioned, **When** reading its description, **Then** the specific angle and orb are stated (e.g., "Mars square Saturn, orb 2.3°")**Acceptance Scenarios**:

4. **Given** minor aspects exist with tight orbs, **When** reading the analysis, **Then** these aspects are included even if they're not major aspects (conjunction, opposition, trine, square, sextile)

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

---

### User Story 4 - Complete Source Attribution and Transparency (Priority: P2)

[Add more user stories as needed, each with an assigned priority]

An astrology app owner wants to understand which knowledge sources the AI used to generate each report, including specific books, chapters, and page numbers from the vectorized knowledge base.

### Edge Cases

**Why this priority**: Transparency builds trust with users and allows quality control. If a report contains questionable interpretations, the owner needs to trace which sources were used and potentially update the knowledge base.

1. **Given** a report is generated using vector database knowledge, **When** viewing the knowledge usage section, **Then** it displays a list of all sources consulted with book titles- What happens when [boundary condition]?

2. **Given** vector sources are listed, **When** reviewing each source, **Then** metadata includes: book title, author name, chapter/section, page range, quoted snippet used, and relevance score- How does system handle [error scenario]?

3. **Given** AI uses both vector database and general training knowledge, **When** viewing sources, **Then** they are clearly distinguished (e.g., "Vector DB Source" vs "AI General Knowledge")

4. **Given** 18 sources were consulted, **When** viewing the knowledge usage section, **Then** summary statistics show: total sources consulted (18), vector DB sources (15), AI training sources (3)## Requirements *(mandatory)*

5. **Given** no vector database matches were found, **When** viewing the report, **Then** the knowledge usage section explicitly states "Vector database was not used" with brief explanation

6. **Given** vector sources have varying relevance, **When** reviewing the source list, **Then** sources are sorted by relevance score (highest first)

### User Story 5 - Enhanced Report Structure with All Components (Priority: P3)### Functional Requirements

A user purchasing a "General Overview" report expects a comprehensive analysis that covers all fundamental chart elements in a well-organized structure, not just planets but also points, rulers, and axes.- **FR-001**: System MUST [specific capability, e.g., "allow users to create accounts"]

- **FR-002**: System MUST [specific capability, e.g., "validate email addresses"]  

**Why this priority**: This provides the complete user experience by bringing together all enhanced data points into a cohesive report structure that flows logically.- **FR-003**: Users MUST be able to [key interaction, e.g., "reset their password"]

- **FR-004**: System MUST [data requirement, e.g., "persist user preferences"]

**Independent Test**: Generate a General Overview report and verify it contains dedicated sections for: Key Influences (10 planets), Ascendant & Midheaven interpretation, Karmic Nodes axis analysis, House Rulers overview, Complete Aspects analysis, and Lilith interpretation.- **FR-005**: System MUST [behavior, e.g., "log all security events"]



**Acceptance Scenarios**:*Example of marking unclear requirements:*



1. **Given** a user purchases any report area, **When** the report is generated, **Then** the Key Influences section lists all 10 planets (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto)- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]

2. **Given** the detailed analysis is displayed, **When** reading through it, **Then** it contains clearly labeled subsections for: Ascendant, Midheaven, Karmic Nodes, House Rulers, Aspects, and Lilith- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

3. **Given** subsections exist, **When** reading the Karmic Nodes section, **Then** it describes the South-to-North axis journey with specific life area implications

4. **Given** house rulers are presented, **When** reviewing that section, **Then** at minimum the Ascendant ruler, 10th house ruler, and 7th house ruler are discussed with their placements### Key Entities *(include if feature involves data)*

5. **Given** Lilith is discussed, **When** reading its section, **Then** the interpretation addresses shadow work, taboo themes, or empowerment relevant to the report's life area focus

- **[Entity 1]**: [What it represents, key attributes without implementation]

---- **[Entity 2]**: [What it represents, relationships to other entities]



### Edge Cases## Success Criteria *(mandatory)*



- **What happens when the API fails to return node positions?** System should log a warning, fall back to calculating nodes via backup method or secondary API, and flag the report as "partial data" if nodes cannot be obtained.

- **What happens when karmic nodes are exactly on a house cusp?** Report should note this significant placement and its amplification of that house's themes.

- **What happens when a house has an intercepted sign?** (two signs in one house) The ruler analysis should account for both rulers or note the complexity.### Measurable Outcomes

- **What happens when generating multiple reports for the same chart?** Vector database queries should be cached to avoid redundant API calls and improve performance.

- **SC-001**: [Measurable metric, e.g., "Users can complete account creation in under 2 minutes"]

## Requirements *(mandatory)*- **SC-002**: [Measurable metric, e.g., "System handles 1000 concurrent users without degradation"]

- **SC-003**: [User satisfaction metric, e.g., "90% of users successfully complete primary task on first attempt"]

### Functional Requirements- **SC-004**: [Business metric, e.g., "Reduce support tickets related to [X] by 50%"]


#### Astrological Point Data Capture

- **FR-001**: System MUST capture North Node position (longitude, sign, house) from astronomical calculation API
- **FR-002**: System MUST capture South Node position (longitude, sign, house), calculated as opposite point to North Node (180° from North Node)
- **FR-003**: System MUST capture Lilith (Black Moon) position (longitude, sign, house) from astronomical calculation API
- **FR-004**: System MUST store Ascendant and Midheaven positions with their corresponding zodiac signs
- **FR-005**: System MUST calculate and store the ruling planet for each of the 12 houses based on the zodiac sign on each house cusp
- **FR-006**: System MUST retrieve all planetary aspects from API without arbitrary limits (minimum 20 aspects if available in chart)

#### Report Generation Requirements

- **FR-007**: Generated reports MUST include explicit interpretation of Ascendant's meaning for personality, physical appearance, and life approach
- **FR-008**: Generated reports MUST include explicit interpretation of Midheaven's significance for career path, public reputation, and life direction
- **FR-009**: Generated reports MUST include interpretation of North Node placement (sign and house) describing the soul's evolutionary direction and life lessons to embrace
- **FR-010**: Generated reports MUST include interpretation of South Node placement (sign and house) describing past life patterns, innate talents, and tendencies to release
- **FR-011**: Generated reports MUST describe the karmic axis relationship between North and South Node houses (e.g., "3rd-9th axis: journey from student to teacher")
- **FR-012**: Generated reports MUST list and interpret all aspects between karmic nodes and natal planets
- **FR-013**: Generated reports MUST include interpretation of Lilith's placement by sign and house, addressing shadow work, taboo themes, or empowerment
- **FR-014**: Generated reports MUST analyze house rulers, identifying at minimum: Ascendant ruler, 10th house ruler, and 7th house ruler with their house placements and significance
- **FR-015**: Generated reports MUST include at least 20 planetary aspects (if chart contains that many), sorted by orb tightness, with specific angles and orbs stated
- **FR-016**: Key Influences section MUST list all 10 major planets: Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto

#### Vector Database and Source Attribution

- **FR-017**: System MUST query vector database for relevant astrological knowledge based on chart configuration and report area
- **FR-018**: System MUST retrieve top 15-20 most relevant knowledge snippets from vector database (if available)
- **FR-019**: System MUST capture and store complete metadata for each knowledge source: book title, author, chapter/section, page range, snippet text, relevance score
- **FR-020**: System MUST distinguish between knowledge from vector database and knowledge from AI's general training data
- **FR-021**: Generated reports MUST include a Knowledge Usage section that lists all sources consulted during generation
- **FR-022**: Knowledge Usage section MUST display: total sources consulted, count of vector database sources, count of AI training sources
- **FR-023**: Each listed source MUST include: book title, author (if available), chapter/section (if available), page range (if available), quoted snippet used, relevance score
- **FR-024**: Sources in Knowledge Usage section MUST be sorted by relevance score (highest first)
- **FR-025**: If no vector database matches found, Knowledge Usage section MUST explicitly state "Vector database was not used" with brief explanation
- **FR-026**: System MUST cache vector database query results for identical chart configurations to improve performance on subsequent report generations

### Key Entities

#### AstrologicalPoint
- **Represents**: Calculated points in a natal chart that aren't planets (nodes, Lilith, angles)
- **Types**: North Node, South Node, Lilith (Black Moon), Ascendant, Midheaven, potentially Chiron
- **Attributes**: longitude (degree position), zodiac sign, house placement, point type
- **Relationships**: Associated with one NatalChart; can form aspects with planets

#### HouseRuler
- **Represents**: The planetary ruler of a house based on the zodiac sign on the house cusp
- **Attributes**: house number (1-12), ruling planet, ruler's sign, ruler's house placement, aspects to ruler
- **Relationships**: Each house has one primary ruler; ruler is one of the natal planets
- **Business Rules**: Rulership determined by traditional planetary rulerships (Mars rules Aries, Venus rules Taurus/Libra, etc.)

#### EnhancedKnowledgeSource
- **Represents**: A specific source of astrological knowledge consulted during report generation
- **Attributes**: book title, author name, chapter/section, page range, snippet text (quote used), relevance score (0.0-1.0), source type (vector database or AI training)
- **Relationships**: Multiple sources associated with one GeneratedReport
- **Business Rules**: Relevance scores assigned by vector database similarity search; sources must be traceable to specific books in knowledge base

#### KnowledgeUsageMetrics
- **Represents**: Summary statistics about knowledge sources used in report generation
- **Attributes**: total sources consulted, vector database source count, AI training source count, average relevance score, cache hit (boolean - whether cached results were used)
- **Relationships**: One per GeneratedReport
- **Business Rules**: Metrics calculated after all sources are retrieved; cache hit set to true if vector query results came from cache

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Generated reports achieve 100% accuracy for karmic node positions compared to professional ephemeris data (within 1 degree)
- **SC-002**: Generated reports include all 6 critical astrological points (Ascendant interpretation, MC interpretation, North Node, South Node, Lilith, house rulers) in 100% of cases
- **SC-003**: Professional astrologers reviewing reports rate completeness as 8/10 or higher (up from current estimated 5/10)
- **SC-004**: Reports include 2.5x more aspects than current implementation (20 aspects vs current 8)
- **SC-005**: Knowledge Usage sections display an average of 12+ distinct sources with complete metadata per report
- **SC-006**: Users can trace the origin of any specific astrological interpretation to a named book and page range in 90%+ of cases
- **SC-007**: Vector database cache reduces query time by 70% for repeat chart configurations
- **SC-008**: Report generation time remains under 15 seconds despite 3x increase in content depth
- **SC-009**: Reports generated with enhanced data receive 40% fewer "missing information" support inquiries from professional astrologer users
- **SC-010**: User satisfaction ratings for "report completeness" increase from current baseline to 85%+ positive ratings

## Constraints & Assumptions *(mandatory)*

### Constraints

- Must maintain compatibility with existing natal chart calculation API endpoints
- Cannot exceed 15-second maximum report generation time to maintain acceptable user experience
- Vector database query costs must remain within $0.10 per report budget
- Must preserve existing report structure and JSON format for backward compatibility
- Cache storage for vector query results limited to 1000 most recent chart configurations
- AI token limits restrict maximum report length to approximately 1800 tokens output

### Assumptions

- Astronomical calculation API provides accurate positions for nodes and Lilith when requested (not filtered out)
- Vector database has been populated with at least 20 quality astrology books chunked and embedded
- Traditional planetary rulership system is used (not modern rulers like Uranus for Aquarius)
- Users understand basic astrological terminology or reports include brief definitions
- Professional astrologer feedback represents typical user needs for report completeness
- Vector database embeddings have been optimized for astrological query patterns
- Most users generate reports for unique birth charts (cache hit rate estimated at 15-20%)
- Source attribution increases user trust even if users don't read every source listed

### Dependencies

- Astronomical calculation API must support querying North Node, South Node, and Lilith positions
- Vector database service (OpenAI Vector Store or similar) must be configured and operational
- Knowledge base must be curated with quality astrological texts, properly chunked and embedded
- AI model must have sufficient context window to process 15-20 knowledge snippets plus chart data
- House rulership calculation logic must be implemented using traditional planetary dignity tables
- Report generation service must have access to caching layer (Redis or in-memory cache)

## Out of Scope

- Modern planetary rulers (e.g., Uranus for Aquarius instead of Saturn) - using traditional rulerships only
- Additional asteroids beyond Lilith (Chiron, Ceres, Vesta, etc.) - may be future enhancement
- Progressions, transits, or predictive techniques - this feature focuses on natal chart interpretation only
- Arabic Parts or Lots (Part of Fortune, etc.) - not included in this enhancement
- Harmonic charts or other derived chart types - natal chart only
- User-selectable house systems - continues using existing house system (Placidus)
- Custom knowledge base upload by users - using curated professional knowledge base only
- Real-time editing of AI-generated interpretations - reports remain static after generation
- Comparison reports (synastry, composite charts) - single natal chart focus only
- PDF formatting enhancements for source citations - existing PDF export remains unchanged

---

## Appendix: Current vs. Enhanced Coverage

### Current State Analysis

| **Element** | **Current Status** | **Enhanced Status** |
|-------------|-------------------|---------------------|
| Ascendant | Calculated, displayed in chart, not interpreted | ✅ Calculated + interpreted meaning |
| Midheaven | Calculated, displayed in chart, not interpreted | ✅ Calculated + interpreted meaning |
| North Node | ❌ Excluded from API, not available | ✅ Calculated + sign + house + interpreted |
| South Node | ❌ Excluded from API, not available | ✅ Calculated + sign + house + interpreted |
| Karmic Axis | ❌ Not available | ✅ House axis journey explained |
| Lilith | ❌ Excluded from API, not available | ✅ Calculated + sign + house + interpreted |
| House Rulers | ❌ Not calculated | ✅ Calculated for all 12 houses + key rulers interpreted |
| Aspects Covered | 8 aspects maximum | ✅ 20+ aspects, sorted by orb |
| Planets in Key Influences | All 10 planets | ✅ All 10 planets (maintained) |
| Vector Sources | 1 hardcoded snippet | ✅ 15-20 dynamic sources with full metadata |
| Source Attribution | None | ✅ Book, author, chapter, pages, snippet, relevance score |
| Cache | None | ✅ Vector query caching for performance |

### Quality Impact

**Before Enhancement**: Expert astrologer feedback shows critical gaps - wrong node positions, missing interpretations, no source transparency.

**After Enhancement**: Reports will meet professional astrology standards with complete point coverage, accurate calculations, comprehensive aspect analysis, and full source attribution for quality control and trust building.
