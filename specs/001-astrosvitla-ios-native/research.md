# Technical Research: Inline Profile Dropdown UX

**Feature**: Simplified Multi-Profile Management
**Research Phase**: Phase 0
**Date**: 2025-10-09

## Executive Summary

This research explores refactoring the current modal-based multi-profile UI to an inline dropdown pattern on the Home tab. The goal is to eliminate navigation overhead and provide instant profile switching with visual feedback directly in the birth data form.

**Key Finding**: SwiftUI's `Menu` component with `Picker` style provides the exact inline dropdown behavior needed, avoiding custom UI complexity while maintaining native iOS patterns.

## Current Implementation Analysis

### Existing Architecture (From Prior Implementation)

```swift
// Current modal-based flow
MainFlowView (Home Tab)
  → Toolbar button shows active profile
  → Taps button → shows .sheet(UserSelectorView)
    → UserSelectorView: List of profiles
      → Tap profile → dismiss + update RepositoryContext
      → Tap "Create New" → shows .sheet(UserProfileFormView)
        → UserProfileFormView: Full-screen form with birth data
          → Tap "Create" → saves + dismisses both modals
```

**Problems**:
1. Two levels of modal navigation (selector, then form)
2. Birth data form hidden until "Create New" tapped
3. Context switching: user loses sight of main screen
4. Extra taps to create new profile (open selector → tap create → fill form → save)

### Proposed Inline Pattern

```swift
// New inline dropdown flow
MainFlowView (Home Tab)
  ┌──────────────────────────┐
  │ [John ▼]  Profile Dropdown│
  ├──────────────────────────┤
  │ Name: [_______________]  │  ← Always visible
  │ Date: [_______________]  │
  │ Time: [_______________]  │
  │ Location: [___________]  │
  │ [Continue]               │
  └──────────────────────────┘

Tap dropdown → Shows Menu/Picker inline
  → Select "Mom" → form fields populate instantly
  → Select "Create New" → form fields clear instantly
```

**Benefits**:
1. Zero navigation - everything happens in-place
2. Birth data form always visible for context
3. Profile switching is 1 tap + instant visual feedback
4. Creating new profile: tap dropdown → "Create New" → fill → Continue (streamlined)

## SwiftUI Component Research

### Option 1: Menu with Buttons (✅ RECOMMENDED)

```swift
Menu {
    ForEach(profiles) { profile in
        Button {
            selectProfile(profile)
        } label: {
            HStack {
                Text(profile.name)
                if profile.id == activeProfile?.id {
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    Divider()

    Button {
        createNewProfile()
    } label: {
        Label("Create New Profile", systemImage: "plus.circle")
    }
} label: {
    HStack {
        Text(activeProfile?.name ?? "New Profile")
        Image(systemName: "chevron.down")
    }
}
```

**Pros**:
- Native iOS dropdown appearance
- Built-in dismiss on selection
- Supports icons, dividers, custom styling
- No custom state management needed

**Cons**:
- None for this use case

### Option 2: Picker with .menu Style (Alternative)

```swift
Picker("Profile", selection: $selectedProfileId) {
    ForEach(profiles) { profile in
        Text(profile.name).tag(profile.id)
    }
    Text("Create New Profile").tag(UUID?.none)
}
.pickerStyle(.menu)
```

**Pros**:
- Even more native (system picker)
- Automatic selection binding

**Cons**:
- Harder to customize (can't easily add "Create New" as special item)
- Less control over appearance

**Decision**: Use **Menu** for full control and clarity.

## State Management Strategy

### Form State Modes

```swift
enum ProfileFormMode {
    case viewing(UserProfile)    // Existing profile selected
    case creating                // "Create New" selected
    case empty                   // No profiles exist yet
}
```

### State Transitions

```
empty → creating (user fills first profile)
viewing(John) → viewing(Mom) (user switches profiles)
viewing(John) → creating (user taps "Create New")
creating → viewing(Partner) (user saves new profile)
creating → viewing(John) (user switches away, discards unsaved)
```

### Implementation in MainFlowView

```swift
@State private var formMode: ProfileFormMode = .empty
@State private var editedName: String = ""
@State private var editedBirthDate: Date = Date()
@State private var editedBirthTime: Date = Date()
@State private var editedLocation: String = ""
@State private var editedCoordinate: CLLocationCoordinate2D? = nil

func selectProfile(_ profile: UserProfile) {
    formMode = .viewing(profile)
    editedName = profile.name
    editedBirthDate = profile.birthDate
    editedBirthTime = profile.birthTime
    editedLocation = profile.locationName
    editedCoordinate = CLLocationCoordinate2D(
        latitude: profile.latitude,
        longitude: profile.longitude
    )
    repositoryContext.setActiveProfile(profile)
}

func createNewProfile() {
    formMode = .creating
    editedName = ""
    editedBirthDate = Date()
    editedBirthTime = Date()
    editedLocation = ""
    editedCoordinate = nil
}
```

## Performance Considerations

### Dropdown Rendering

- **Menu**: Lazy-loaded, renders only visible items
- **Expected profiles**: 5-10 typical, 50 max
- **Render time**: <16ms for 60fps even at 50 items

### Profile Switch Performance

```
Tap profile → updateState (1-2ms) → form field updates (SwiftUI binding, ~5ms)
Total: <10ms perceived as instant
```

### Form Population

- Text fields: SwiftUI bindings update synchronously
- DatePickers: Native components, no custom rendering
- Location field: String display, coordinates hidden until needed

**Verdict**: No performance concerns. All operations well under 100ms constraint.

## Edge Case Handling

### 1. Duplicate Profile Names

**Scenario**: User tries to save "John" when "John" already exists
**Solution**: Validation in UserProfileViewModel.validateProfileName()
**UI**: Show error message below Continue button, disable button

### 2. Switching While Editing

**Scenario**: User starts filling "New Profile" data, then switches to existing profile
**Solution**: Discard unsaved data immediately (no confirmation)
**Rationale**: Spec FR-065 requires this for simplicity

### 3. No Profiles Exist (First Time)

**Scenario**: User completes onboarding, lands on Home tab
**Solution**: formMode = .empty, dropdown shows "New Profile", form fields empty
**UI**: Continue button disabled until all fields filled

### 4. Deleting Active Profile

**Scenario**: User deletes currently active profile from Settings
**Solution**: UserProfileListView handles this (existing code)
**Fallback**: Switch to next available profile or .empty state

## Testing Strategy

### Unit Tests (MainFlowInlineProfileTests.swift)

```swift
// Test 1: Profile selection populates form
func testSelectingProfilePopulatesFormFields()

// Test 2: Create New clears form
func testCreateNewProfileClearsFormFields()

// Test 3: Switching discards unsaved data
func testSwitchingProfileDiscardsUnsavedData()

// Test 4: Empty state shows correct UI
func testEmptyStateShowsNewProfileLabel()

// Test 5: Continue button validation
func testContinueButtonDisabledWhenFieldsEmpty()
```

### UI Tests (ProfileSwitchingUITests.swift)

```swift
// Test 1: End-to-end profile creation
func testCreateProfileInlineFlow()

// Test 2: End-to-end profile switching
func testSwitchBetweenExistingProfiles()

// Test 3: Dropdown shows all profiles
func testDropdownDisplaysAllSavedProfiles()

// Test 4: Duplicate name validation
func testDuplicateNameShowsError()
```

## Migration Path

### Phase 1: Add Inline Dropdown (Keep Modals)

1. Add dropdown Menu to MainFlowView
2. Add form state management (@State vars)
3. Wire dropdown selections to state updates
4. Test dropdown + form interaction
5. **Keep existing modal sheets as fallback**

### Phase 2: Remove Modals

1. Remove `.sheet(UserSelectorView)` from MainFlowView
2. Remove `.sheet(UserProfileFormView)` from MainFlowView
3. Delete UserSelectorView.swift
4. Delete UserProfileFormView.swift
5. Update tests

### Rollback Plan

If inline UX causes issues:
1. Re-enable modal sheets in MainFlowView
2. Hide inline dropdown (don't delete code)
3. File bugs for inline issues
4. Fix and re-enable in next sprint

## Dependencies

### Existing Components (No Changes)

- ✅ UserProfile model
- ✅ UserProfileService
- ✅ UserProfileViewModel (minor usage changes only)
- ✅ RepositoryContext
- ✅ UserProfileListView (Settings screen)

### New Components

- ➕ Inline profile dropdown Menu in MainFlowView
- ➕ Form state management in MainFlowView
- ➕ Unit tests for inline behavior
- ➕ UI tests for end-to-end flows

### External Dependencies

- SwiftUI (iOS 17+) - Menu, Picker, bindings
- SwiftData - UserProfile queries (existing)
- Combine - ObservableObject (existing)

## Open Questions

**Q1**: Should "Create New Profile" show a special icon?
**A**: Yes, use `plus.circle` systemImage for visual distinction

**Q2**: What happens if user taps dropdown while form is invalid?
**A**: Allow it - switching profiles discards invalid data per FR-065

**Q3**: Should dropdown show birth date next to name?
**A**: Not in dropdown (too much text). Show only name. Birth data visible in form below.

**Q4**: Animate form field changes?
**A**: No - instant updates feel more responsive. SwiftUI default transitions are fine.

## Conclusion

**Recommendation**: ✅ Proceed with inline dropdown implementation using SwiftUI Menu.

**Justification**:
- Simpler UX (fewer taps, no navigation)
- Native iOS patterns (Menu component)
- Minimal code changes (modify MainFlowView, delete 2 views)
- Better user context (always see form + dropdown)
- Meets all spec requirements (FR-050 to FR-065)

**Next Steps**:
1. Generate data-model.md (no changes to models, document state management)
2. Generate quickstart.md (document new inline UX patterns)
3. Generate tasks.md with TDD approach
