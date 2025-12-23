# Feature Specification: In-App Purchase System for AI Astrological Reports

**Feature Branch**: `008-implement-in-app`
**Created**: 2025-12-23
**Status**: Draft
**Input**: User description: "Implement in-app purchases for Zorya natal chart app to monetize AI-generated astrological reports. Users should be able to purchase individual report types (Personality Analysis, Career Insights, Relationship Compatibility, Wellness & Energy) at different price points, with each purchase allowing one report generation. The app supports multiple user profiles (self, family members, friends), and users should be able to buy the same report type multiple times to generate it for different profiles. Include a bundle option that provides all four report types at a discounted price. The purchase flow should present users with a paywall showing report features, benefits, AI-powered analysis explanation, and clear pricing before generation. After successful purchase, users can immediately generate their report. All data must be stored locally on device with no cloud backend - purchases should be verified through the platform's purchase system but not require server infrastructure. Target pricing: individual reports $4.99-$6.99, complete bundle $19.99. The app is initially targeting Ukrainian-speaking users with plans for international expansion, so the purchase experience should support localization. Focus on simplicity for MVP launch before New Year - users should understand the value proposition clearly and complete purchases within 2-3 taps."

## Clarifications

### Session 2025-12-23

- Q: Should the feature include bundle purchases of all four report types? → A: No - only individual report purchases (1 purchase = 1 report). No bundle offers for MVP simplicity.
- Q: What is the exact price for each report type? → A: All reports same price: $4.99 (simplest pricing model for MVP)
- Q: Are credits profile-specific or shared globally? → A: Global credit pool - credits can be used for any profile (simplest data model and UX)

## User Scenarios & Testing

### User Story 1 - Single Report Purchase for Self (Priority: P1)

A user wants to purchase and generate their first astrological report (Personality Analysis) for their own profile to understand how AI-powered astrology insights work.

**Why this priority**: This is the most common entry point for new users and represents the core monetization flow. It's the simplest path and must work flawlessly for business viability.

**Independent Test**: Can be fully tested by selecting any report type from the report list, viewing the paywall, completing purchase, and generating the report. Delivers immediate value with a complete astrological report.

**Acceptance Scenarios**:

1. **Given** user has a natal chart profile created, **When** user taps on "Personality Analysis" report, **Then** paywall displays showing report features, AI-powered analysis explanation, benefits, and price ($4.99)
2. **Given** user views paywall, **When** user taps "Purchase" button, **Then** platform purchase flow initiates
3. **Given** purchase completes successfully, **When** user returns to app, **Then** user is taken directly to report generation screen
4. **Given** user has purchased report type once, **When** user generates report, **Then** purchased report credit is consumed and report is generated immediately
5. **Given** user has generated report, **When** user views report list, **Then** generated report appears in their history

---

### User Story 2 - Repeat Purchase for Additional Profiles (Priority: P2)

A user who already purchased a report type wants to purchase the same report again to generate it for a different profile (family member, friend).

**Why this priority**: Supports the multi-profile use case and enables recurring revenue. Essential for users who want to generate reports for loved ones.

**Independent Test**: Can be fully tested by purchasing a report type, generating it for one profile, then purchasing the same report type again and generating for a different profile. Delivers value through multiple personalized reports.

**Acceptance Scenarios**:

1. **Given** user has already purchased and generated "Career Insights" for their own profile, **When** user switches to family member's profile and selects "Career Insights", **Then** paywall displays again showing purchase option
2. **Given** user purchases same report type again, **When** purchase completes, **Then** user receives new credit for that report type
3. **Given** user has credits for same report type from multiple purchases, **When** user generates report, **Then** one credit is consumed and remaining credits stay available
4. **Given** user has generated reports for multiple profiles, **When** user views report history, **Then** reports are organized by profile and show which report types are available for each profile

---

### User Story 3 - Restore Previous Purchases (Priority: P3)

A user who reinstalls the app or switches devices wants to restore their previous purchases without repaying.

**Why this priority**: Required for user retention and platform compliance, but affects fewer users than initial purchases. Critical for user trust but lower frequency.

**Independent Test**: Can be fully tested by making purchases, logging out or reinstalling app, then using restore purchases function. Delivers peace of mind and protects user investment.

**Acceptance Scenarios**:

1. **Given** user has made purchases in the past, **When** user reinstalls app or logs in on new device, **Then** "Restore Purchases" option is available in settings or purchase screen
2. **Given** user taps "Restore Purchases", **When** restoration completes successfully, **Then** all previously purchased unused credits are restored
3. **Given** purchases are restored, **When** user views available reports, **Then** user can generate reports using restored credits
4. **Given** user has already consumed credits before reinstalling, **When** purchases are restored, **Then** only unused credits are restored (consumed credits remain consumed)

---

### User Story 4 - Browse All Available Reports (Priority: P1)

A user exploring the app wants to see all available report types, understand what each offers, and review pricing before deciding which to purchase.

**Why this priority**: Essential for user education and purchase decision-making. Users need to understand value proposition before committing to purchase.

**Independent Test**: Can be fully tested by navigating to reports section and viewing all report type information without making purchases. Delivers understanding of app capabilities.

**Acceptance Scenarios**:

1. **Given** user is on reports screen, **When** user views report list, **Then** all four report types are displayed with titles, brief descriptions, and "locked" or "available" status
2. **Given** user taps on locked report, **When** paywall opens, **Then** user sees detailed description of report content, AI analysis features, benefits, example insights, and clear pricing

---

### Edge Cases

- What happens when user initiates purchase but cancels before completing platform payment?
- How does system handle purchase validation failure from platform?
- What happens if user attempts to generate report while platform purchase verification is still in progress?
- How does system handle network unavailability during purchase verification?
- What happens when user has insufficient credits for a report type but credits exist for other types?
- How does system handle rapid repeated purchase attempts for the same report type?
- What happens if user's platform account region doesn't match app localization (e.g., non-Ukrainian App Store account)?
- How does system handle price changes after user has seen paywall but before completing purchase?
- What happens when user tries to restore purchases but platform returns error?

## Requirements

### Functional Requirements

- **FR-001**: System MUST display four distinct report types: Personality Analysis, Career Insights, Relationship Compatibility, and Wellness & Energy
- **FR-002**: System MUST present a paywall before report generation showing report features, AI-powered analysis explanation, benefits, and pricing
- **FR-003**: System MUST support individual report purchases at $4.99 per report (uniform pricing across all report types)
- **FR-004**: Users MUST be able to complete purchase flow within 2-3 taps from viewing paywall to confirming purchase
- **FR-005**: System MUST allow users to purchase the same report type multiple times for different profiles
- **FR-006**: System MUST track purchase credits locally on device for each report type
- **FR-007**: System MUST consume one credit per report generation for the corresponding report type
- **FR-008**: System MUST verify purchases through platform purchase system (App Store/Play Store) without requiring server infrastructure
- **FR-009**: System MUST immediately enable report generation after successful purchase completion
- **FR-010**: System MUST support localization for purchase flow, starting with Ukrainian language
- **FR-011**: System MUST provide "Restore Purchases" functionality to recover unused credits
- **FR-012**: System MUST store all purchase records and credit balances locally on device
- **FR-013**: System MUST prevent report generation when user has zero credits for that report type
- **FR-014**: System MUST display current credit balance for each report type in user interface
- **FR-015**: System MUST handle purchase cancellation gracefully without consuming credits
- **FR-016**: System MUST display appropriate error messages when purchase verification fails
- **FR-017**: System MUST track which user profile each generated report was created for (credits are global, but generation history is profile-specific)

### Key Entities

- **Report Type**: Represents one of four available report categories (Personality Analysis, Career Insights, Relationship Compatibility, Wellness & Energy) with attributes including display name, description, benefits, price, and unique identifier for purchase system
- **Purchase Credit**: Represents a single-use entitlement to generate one specific report type, with attributes including report type, acquisition date, consumption status, and optionally the user profile it was consumed for (credits exist in global pool until consumed)
- **Purchase Record**: Represents a completed transaction with attributes including purchase date, report type identifier, transaction ID from platform, price paid, and restoration status

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can complete purchase flow from viewing report to payment confirmation within 2-3 taps
- **SC-002**: Paywall clearly communicates value proposition such that users understand what they're purchasing before payment (measured by purchase completion rate vs. paywall abandonment)
- **SC-003**: Purchase restoration completes successfully for 95% of users who have made previous purchases
- **SC-004**: Zero purchase verification errors result in lost credits or double-charging (100% transaction integrity)
- **SC-005**: Users can switch between profiles and make purchases without confusion (measured by support requests related to purchase confusion)
- **SC-006**: Localized purchase experience displays correctly for Ukrainian language users with accurate pricing formatting
- **SC-007**: Users can generate report within 5 seconds of purchase completion
- **SC-008**: Purchase credit tracking maintains 100% accuracy across app sessions, reinstalls, and device restarts
- **SC-009**: First-time purchasers successfully generate their first report within 2 minutes of purchase (95% success rate)

## Assumptions

- Platform purchase verification (App Store/Play Store) provides reliable transaction validation without requiring custom backend
- Users understand the concept of consumable in-app purchases (one purchase = one report generation)
- Uniform pricing of $4.99 per report is competitive and acceptable to target Ukrainian market
- Platform handles currency conversion and regional pricing automatically
- Local device storage is sufficient and reliable for purchase record persistence
- Users primarily interact with one device and restore purchases is secondary use case
- Ukrainian localization is sufficient for MVP launch before international expansion
- Platform purchase system handles payment method validation, security, and compliance
- Network connectivity is available during purchase verification but not required afterwards
- Users create profiles before attempting to generate reports (profile creation is prerequisite)

## Dependencies

- Platform In-App Purchase SDK (App Store/Google Play) for transaction processing
- Existing user profile management system for associating purchases with profiles
- Existing report generation system for AI-powered astrological report creation
- Localization system for Ukrainian language support in purchase UI

## Out of Scope

- Server-side purchase verification or receipt validation
- Subscription-based pricing models (focus on consumable purchases only)
- Family sharing of purchases across multiple platform accounts
- Gift purchases or transferring credits between users
- Promotional codes or discount coupons
- Purchase analytics dashboard or admin panel
- Refund processing (handled by platform policies)
- Cross-platform purchase synchronization (iOS to Android)
- Purchase history export or reporting
- Integration with external payment systems beyond platform stores
