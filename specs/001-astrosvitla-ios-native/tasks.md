# Tasks: Simplified Multi-Profile UX (Inline Dropdown)

**Feature**: Inline Profile Selector on Home Tab
**Branch**: `001-astrosvitla-ios-native`
**Date**: 2025-10-09
**Prerequisites**: plan.md, research.md, data-model.md, quickstart.md

---

## Execution Summary

This task breakdown implements the simplified inline dropdown UX for multi-profile management, replacing the modal-based architecture. All profile selection and creation happens directly on the Home tab using a native SwiftUI Menu component.

**Approach**: Test-Driven Development (TDD)
- Phase 3: Write ALL tests FIRST (must FAIL)
- Phase 4-6: Implement code to make tests PASS
- Phase 8: Verify all tests pass

**Total Tasks**: 34 (3 cleanup + 2 state setup + 10 tests + 13 implementation + 6 verification)

---

## Format: `[ID] [P?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- Includes exact file paths for each task
- **⚠️ TDD Gate**: Phase 3 must complete and FAIL before Phase 4 begins

---

## Phase 1: Cleanup (Delete Modal Views)

### T001 [P]: ✅ Delete UserSelectorView
**File**: `AstroSvitla/Features/UserManagement/Views/UserSelectorView.swift`
**Action**: DELETE
**Description**: Remove the modal user selector view - replaced by inline dropdown.

**Steps**:
1. Delete file `UserSelectorView.swift`
2. Verify no compiler errors (if references exist, they'll be fixed in T003)

**Status**: ✅ COMPLETE

---

### T002 [P]: ✅ Delete UserProfileFormView
**File**: `AstroSvitla/Features/UserManagement/Views/UserProfileFormView.swift`
**Action**: DELETE
**Description**: Remove the modal profile creation form - replaced by inline form on Home tab.

**Steps**:
1. Delete file `UserProfileFormView.swift`
2. Verify no compiler errors (if references exist, they'll be fixed in T003)

**Status**: ✅ COMPLETE

---

### T003: ✅ Remove Modal Sheets from MainFlowView
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Remove `.sheet()` modifiers for UserSelectorView and UserProfileFormView.

**Steps**:
1. Find and remove `.sheet(isPresented: ...) { UserSelectorView() }`
2. Find and remove `.sheet(isPresented: ...) { UserProfileFormView() }`
3. Remove associated @State properties for sheet presentation
4. Remove toolbar buttons that opened modals
5. Verify app builds successfully
6. Run app - Main tab should show only existing content (no profile UI yet)

**Status**: ✅ COMPLETE - Build succeeded

---

## Phase 2: State Management Foundation

### T004: ✅ Add ProfileFormMode Enum
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Add ProfileFormMode enum to manage form state transitions.

**Implementation**:
```swift
enum ProfileFormMode: Equatable {
    case empty                    // No profiles exist yet
    case viewing(UserProfile)     // Existing profile selected
    case creating                 // "Create New" selected

    var isCreating: Bool {
        if case .creating = self { return true }
        return false
    }

    var currentProfile: UserProfile? {
        if case .viewing(let profile) = self { return profile }
        return nil
    }
}
```

**Location**: Add inside MainFlowView struct (before body property)

**Status**: ✅ COMPLETE

---

### T005: ✅ Add Form State Properties
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Add @State properties for form fields and mode management.

**Implementation**:
```swift
// Form mode
@State private var formMode: ProfileFormMode = .empty

// Form field state
@State private var editedName: String = ""
@State private var editedBirthDate: Date = Date()
@State private var editedBirthTime: Date = Date()
@State private var editedLocation: String = ""
@State private var editedCoordinate: CLLocationCoordinate2D? = nil
@State private var editedTimezone: String = TimeZone.current.identifier

// UI state
@State private var isCalculating: Bool = false
@State private var validationError: String? = nil
@State private var showingDeleteConfirmation: Bool = false
```

**Location**: Add at top of MainFlowView struct (after existing @State/@EnvironmentObject)

**Status**: ✅ COMPLETE

---

## Phase 3: Tests First ⚠️ TDD - MUST COMPLETE BEFORE PHASE 4

**CRITICAL**: These tests MUST be written and MUST FAIL before ANY implementation code is written.

### T006: Unit Test - ProfileFormMode State Transitions
**File**: `AstroSvitlaTests/Features/Main/MainFlowInlineProfileTests.swift` (NEW)
**Description**: Write failing test for ProfileFormMode enum and state transitions.

**Test Cases**:
```swift
@Test func testProfileFormMode_EmptyState() {
    // Test .empty case exists
    // Test isCreating returns false
    // Test currentProfile returns nil
}

@Test func testProfileFormMode_ViewingState() {
    // Test .viewing(profile) stores profile
    // Test isCreating returns false
    // Test currentProfile returns the profile
}

@Test func testProfileFormMode_CreatingState() {
    // Test .creating case exists
    // Test isCreating returns true
    // Test currentProfile returns nil
}

@Test func testProfileFormMode_Equatable() {
    // Test .empty == .empty
    // Test .viewing(profile1) != .viewing(profile2)
    // Test .creating == .creating
}
```

**Expected**: All tests FAIL (MainFlowView doesn't have ProfileFormMode yet)

---

### T007: Unit Test - Profile Selection Handler
**File**: `AstroSvitlaTests/Features/Main/MainFlowInlineProfileTests.swift`
**Description**: Write failing test for handleProfileSelection() function.

**Test Cases**:
```swift
@Test func testHandleProfileSelection_PopulatesFormFields() {
    // Given: A UserProfile with specific data
    // When: handleProfileSelection(profile) called
    // Then: editedName, editedBirthDate, etc. match profile
    // Then: formMode == .viewing(profile)
    // Then: validationError == nil
    // Then: repositoryContext.activeProfile == profile
}

@Test func testHandleProfileSelection_ClearsValidationError() {
    // Given: validationError is set to some error
    // When: handleProfileSelection(profile) called
    // Then: validationError == nil
}
```

**Expected**: All tests FAIL (handleProfileSelection doesn't exist yet)

---

### T008: Unit Test - Create New Profile Handler
**File**: `AstroSvitlaTests/Features/Main/MainFlowInlineProfileTests.swift`
**Description**: Write failing test for handleCreateNewProfile() function.

**Test Cases**:
```swift
@Test func testHandleCreateNewProfile_ClearsFormFields() {
    // Given: Form fields populated with data
    // When: handleCreateNewProfile() called
    // Then: editedName == ""
    // Then: editedBirthDate == Date()
    // Then: editedLocation == ""
    // Then: editedCoordinate == nil
    // Then: formMode == .creating
    // Then: validationError == nil
}

@Test func testHandleCreateNewProfile_FromViewingMode() {
    // Given: formMode == .viewing(someProfile)
    // When: handleCreateNewProfile() called
    // Then: formMode == .creating
    // Then: All form fields cleared
}
```

**Expected**: All tests FAIL (handleCreateNewProfile doesn't exist yet)

---

### T009: Unit Test - Form Validation Logic
**File**: `AstroSvitlaTests/Features/Main/MainFlowInlineProfileTests.swift`
**Description**: Write failing test for form validation before saving.

**Test Cases**:
```swift
@Test func testValidateForm_EmptyName() {
    // Given: editedName == ""
    // When: validateForm() called
    // Then: returns false
    // Then: validationError contains "name required"
}

@Test func testValidateForm_DuplicateName() async {
    // Given: editedName == existing profile name
    // When: validateForm() called
    // Then: returns false
    // Then: validationError contains "name already exists"
}

@Test func testValidateForm_EmptyLocation() {
    // Given: editedLocation == ""
    // When: validateForm() called
    // Then: returns false
    // Then: validationError contains "location required"
}

@Test func testValidateForm_ValidData() {
    // Given: All fields filled correctly
    // When: validateForm() called
    // Then: returns true
    // Then: validationError == nil
}
```

**Expected**: All tests FAIL (validateForm doesn't exist yet)

---

### T010: Unit Test - Continue Button Handler
**File**: `AstroSvitlaTests/Features/Main/MainFlowInlineProfileTests.swift`
**Description**: Write failing test for handleContinue() async function.

**Test Cases**:
```swift
@Test func testHandleContinue_CreatesNewProfile() async {
    // Given: formMode == .creating, all fields valid
    // When: handleContinue() called
    // Then: UserProfileService.createProfile() called
    // Then: New profile saved to SwiftData
    // Then: formMode == .viewing(newProfile)
    // Then: repositoryContext.activeProfile == newProfile
}

@Test func testHandleContinue_UpdatesExistingProfile() async {
    // Given: formMode == .viewing(profile), fields modified
    // When: handleContinue() called
    // Then: UserProfileService.updateProfile() called
    // Then: Profile updated in SwiftData
    // Then: formMode remains .viewing(updatedProfile)
}

@Test func testHandleContinue_ValidationFailure() async {
    // Given: editedName == "" (invalid)
    // When: handleContinue() called
    // Then: No profile saved
    // Then: validationError set
    // Then: isCalculating == false
}

@Test func testHandleContinue_LoadingState() async {
    // Given: Valid form data
    // When: handleContinue() called
    // Then: isCalculating == true during execution
    // Then: isCalculating == false when complete
}
```

**Expected**: All tests FAIL (handleContinue doesn't exist yet)

---

### T011: Unit Test - Switching Profiles Discards Unsaved Data
**File**: `AstroSvitlaTests/Features/Main/MainFlowInlineProfileTests.swift`
**Description**: Write failing test for FR-065 requirement (discard unsaved data).

**Test Cases**:
```swift
@Test func testSwitchingProfiles_DiscardsUnsavedData() {
    // Given: formMode == .creating, editedName == "Unsaved Name"
    // When: handleProfileSelection(existingProfile) called
    // Then: editedName == existingProfile.name (not "Unsaved Name")
    // Then: formMode == .viewing(existingProfile)
}

@Test func testCreateNew_DiscardsViewingData() {
    // Given: formMode == .viewing(profile), editedName modified
    // When: handleCreateNewProfile() called
    // Then: editedName == "" (cleared, not modified value)
    // Then: formMode == .creating
}
```

**Expected**: All tests FAIL (handlers don't enforce this behavior yet)

---

### T012: UI Test - Dropdown Menu Displays Profiles
**File**: `AstroSvitlaUITests/ProfileSwitchingUITests.swift` (NEW)
**Description**: Write failing UI test for dropdown menu rendering.

**Test Cases**:
```swift
func testDropdownMenu_DisplaysAllProfiles() {
    // Given: 3 profiles exist ("Alice", "Bob", "Charlie")
    // When: Tap profile dropdown button
    // Then: Menu appears with 3 profile items
    // Then: Menu contains "Create New Profile" item
}

func testDropdownMenu_ShowsActiveProfile() {
    // Given: Active profile is "Alice"
    // When: View Home tab
    // Then: Dropdown label shows "Alice"
    // Then: Dropdown has chevron.down icon
}

func testDropdownMenu_HighlightsActiveProfile() {
    // Given: Active profile is "Bob"
    // When: Open dropdown menu
    // Then: "Bob" item has checkmark icon
    // Then: Other items don't have checkmark
}
```

**Expected**: All tests FAIL (dropdown UI doesn't exist yet)

---

### T013: UI Test - Profile Selection Flow
**File**: `AstroSvitlaUITests/ProfileSwitchingUITests.swift`
**Description**: Write failing UI test for end-to-end profile selection.

**Test Cases**:
```swift
func testProfileSelection_UpdatesFormFields() {
    // Given: Active profile is "Alice"
    // When: Open dropdown, tap "Bob"
    // Then: Dropdown closes
    // Then: Dropdown label shows "Bob"
    // Then: Name field shows "Bob"
    // Then: Birth date field shows Bob's date
    // Then: Location field shows Bob's location
}

func testProfileSelection_UpdatesChartDisplay() {
    // Given: Active profile is "Alice"
    // When: Switch to "Bob"
    // Then: Chart widget updates to Bob's chart data
}
```

**Expected**: All tests FAIL (profile selection not wired yet)

---

### T014: UI Test - Create New Profile Flow
**File**: `AstroSvitlaUITests/ProfileSwitchingUITests.swift`
**Description**: Write failing UI test for inline profile creation.

**Test Cases**:
```swift
func testCreateNewProfile_InlineFlow() {
    // Given: 1 existing profile
    // When: Open dropdown, tap "Create New Profile"
    // Then: Dropdown label shows "New Profile"
    // Then: All form fields clear
    // When: Fill name, date, time, location
    // When: Tap "Continue" button
    // Then: Loading indicator appears
    // Then: Profile saved
    // Then: Dropdown label shows new profile name
    // Then: Chart calculated and displayed
}

func testCreateNewProfile_ValidationError() {
    // Given: Dropdown shows "Create New Profile"
    // When: Fill name with existing profile name
    // When: Tap "Continue"
    // Then: Error message appears (duplicate name)
    // Then: Continue button disabled or error shown
    // Then: Profile NOT saved
}
```

**Expected**: All tests FAIL (create flow not implemented yet)

---

### T015: UI Test - Empty State (No Profiles)
**File**: `AstroSvitlaUITests/ProfileSwitchingUITests.swift`
**Description**: Write failing UI test for first-time user experience.

**Test Cases**:
```swift
func testEmptyState_ShowsNewProfile() {
    // Given: No profiles exist (fresh install)
    // When: Land on Home tab
    // Then: Dropdown label shows "New Profile"
    // Then: All form fields are empty
    // Then: Continue button disabled until fields filled
}

func testEmptyState_FirstProfileCreation() {
    // Given: No profiles exist
    // When: Fill form fields with valid data
    // When: Tap "Continue"
    // Then: First profile created
    // Then: Dropdown label shows profile name
    // Then: Dropdown menu now has 1 item + "Create New"
}
```

**Expected**: All tests FAIL (empty state handling not implemented yet)

---

## Phase 4: Implement Dropdown Selection Logic

### T016: Implement handleProfileSelection()
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Implement function to handle profile selection from dropdown.

**Implementation**:
```swift
private func handleProfileSelection(_ profile: UserProfile) {
    formMode = .viewing(profile)
    editedName = profile.name
    editedBirthDate = profile.birthDate
    editedBirthTime = profile.birthTime
    editedLocation = profile.locationName
    editedCoordinate = CLLocationCoordinate2D(
        latitude: profile.latitude,
        longitude: profile.longitude
    )
    editedTimezone = profile.timezone
    repositoryContext.setActiveProfile(profile)
    validationError = nil
}
```

**Location**: Add as private method inside MainFlowView

**Verify**: T007 tests now PASS

---

### T017: Implement handleCreateNewProfile()
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Implement function to handle "Create New Profile" selection.

**Implementation**:
```swift
private func handleCreateNewProfile() {
    formMode = .creating
    editedName = ""
    editedBirthDate = Date()
    editedBirthTime = Date()
    editedLocation = ""
    editedCoordinate = nil
    editedTimezone = TimeZone.current.identifier
    validationError = nil
}
```

**Location**: Add as private method inside MainFlowView

**Verify**: T008 tests now PASS

---

### T018: Add Inline Profile Dropdown Menu
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Add SwiftUI Menu component for profile selection at top of Home tab.

**Implementation**:
```swift
// Add this view component at top of body
VStack(alignment: .leading, spacing: 16) {
    // Profile Dropdown
    Menu {
        // Existing profiles
        ForEach(viewModel.profiles) { profile in
            Button {
                handleProfileSelection(profile)
            } label: {
                HStack {
                    Text(profile.name)
                    if profile.id == repositoryContext.activeProfile?.id {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }

        Divider()

        // Create New option
        Button {
            handleCreateNewProfile()
        } label: {
            Label("Create New Profile", systemImage: "plus.circle")
        }
    } label: {
        HStack {
            Text(formMode.currentProfile?.name ?? "New Profile")
                .font(.headline)
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    // Rest of form fields go here...
}
```

**Location**: Replace or integrate with existing Home tab content in body

**Verify**: T012 tests now PASS (dropdown renders)

---

### T019: Initialize Form Mode on Appear
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Set initial formMode when view appears based on active profile.

**Implementation**:
```swift
.onAppear {
    if let activeProfile = repositoryContext.activeProfile {
        handleProfileSelection(activeProfile)
    } else if let firstProfile = viewModel.profiles.first {
        handleProfileSelection(firstProfile)
    } else {
        formMode = .empty
        handleCreateNewProfile()
    }
}
```

**Location**: Add .onAppear modifier to outermost VStack in body

**Verify**: T015 tests now PASS (empty state handled correctly)

---

## Phase 5: Wire Form Fields to State

### T020: Bind Form Fields to @State Properties
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Update existing form fields to bind to new @State properties.

**Changes**:
```swift
// Name field
TextField("Name", text: $editedName)

// Birth date picker
DatePicker("Birth Date", selection: $editedBirthDate, displayedComponents: .date)

// Birth time picker
DatePicker("Birth Time", selection: $editedBirthTime, displayedComponents: .hourAndMinute)

// Location field (existing LocationSearchView or TextField)
LocationSearchView(
    locationName: $editedLocation,
    coordinate: $editedCoordinate,
    timezone: $editedTimezone
)
```

**Note**: Replace any existing bindings to viewModel properties with these @State bindings

**Verify**: Manual test - changing dropdown updates form fields instantly

---

### T021: Add Continue Button
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Add Continue button at bottom of form with validation state.

**Implementation**:
```swift
// At bottom of form VStack
Button {
    Task {
        await handleContinue()
    }
} label: {
    if isCalculating {
        ProgressView()
            .progressViewStyle(.circular)
    } else {
        Text("Continue")
            .font(.headline)
    }
}
.frame(maxWidth: .infinity)
.padding()
.background(isContinueButtonEnabled ? Color.blue : Color.gray)
.foregroundColor(.white)
.cornerRadius(12)
.disabled(!isContinueButtonEnabled || isCalculating)
```

**Add computed property**:
```swift
private var isContinueButtonEnabled: Bool {
    !editedName.isEmpty &&
    !editedLocation.isEmpty &&
    editedCoordinate != nil &&
    validationError == nil
}
```

**Location**: Add button at end of form, add computed property with other properties

---

### T022: Display Validation Errors
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Show validation error messages below form fields.

**Implementation**:
```swift
// Add after form fields, before Continue button
if let error = validationError {
    Text(error)
        .font(.caption)
        .foregroundColor(.red)
        .padding(.horizontal)
}
```

**Location**: Add inside form VStack, before Continue button

---

## Phase 6: Implement Profile Creation/Update Logic

### T023: Implement Form Validation
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Add validateForm() function with duplicate name check.

**Implementation**:
```swift
private func validateForm() async -> Bool {
    // Reset error
    validationError = nil

    // Check name not empty
    guard !editedName.trimmingCharacters(in: .whitespaces).isEmpty else {
        validationError = "Profile name is required"
        return false
    }

    // Check duplicate name
    let isDuplicate = viewModel.profiles.contains { profile in
        profile.name.lowercased() == editedName.lowercased() &&
        profile.id != formMode.currentProfile?.id
    }

    if isDuplicate {
        validationError = "A profile with this name already exists"
        return false
    }

    // Check location
    guard !editedLocation.isEmpty, editedCoordinate != nil else {
        validationError = "Birth location is required"
        return false
    }

    return true
}
```

**Location**: Add as private method inside MainFlowView

**Verify**: T009 tests now PASS

---

### T024: Implement handleContinue()
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Implement async function to save profile and calculate chart.

**Implementation**:
```swift
private func handleContinue() async {
    // Validate
    guard await validateForm() else { return }

    // Show loading
    isCalculating = true
    defer { isCalculating = false }

    do {
        switch formMode {
        case .creating, .empty:
            // Create new profile
            let newProfile = try await userProfileService.createProfile(
                name: editedName,
                birthDate: editedBirthDate,
                birthTime: editedBirthTime,
                locationName: editedLocation,
                latitude: editedCoordinate!.latitude,
                longitude: editedCoordinate!.longitude,
                timezone: editedTimezone
            )

            // Switch to viewing new profile
            handleProfileSelection(newProfile)

            // Navigate to chart or next step
            // (implementation depends on your navigation structure)

        case .viewing(let profile):
            // Update existing profile
            try await userProfileService.updateProfile(
                profile,
                name: editedName,
                birthDate: editedBirthDate,
                birthTime: editedBirthTime,
                locationName: editedLocation,
                latitude: editedCoordinate!.latitude,
                longitude: editedCoordinate!.longitude,
                timezone: editedTimezone
            )

            // Refresh form with updated data
            handleProfileSelection(profile)
        }
    } catch {
        validationError = error.localizedDescription
    }
}
```

**Dependencies**: Requires UserProfileService with createProfile() and updateProfile() methods

**Location**: Add as private method inside MainFlowView

**Verify**: T010 tests now PASS

---

## Phase 7: Integration & Edge Cases

### T025: Handle Active Profile Deletion
**File**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Action**: MODIFY
**Description**: Handle case where active profile is deleted from Settings.

**Implementation**:
```swift
.onChange(of: repositoryContext.activeProfile) { oldValue, newValue in
    // If active profile becomes nil and profiles exist, select first
    if newValue == nil {
        if let firstProfile = viewModel.profiles.first {
            handleProfileSelection(firstProfile)
        } else {
            // No profiles left
            handleCreateNewProfile()
        }
    }
}
```

**Location**: Add .onChange modifier to outermost VStack in body

**Verify**: Manual test - delete active profile from Settings, verify Home tab updates

---

### T026: Update UserProfileService (if needed)
**File**: `AstroSvitla/Features/UserManagement/Services/UserProfileService.swift`
**Action**: MODIFY (if service doesn't exist, CREATE)
**Description**: Ensure UserProfileService has createProfile() and updateProfile() methods.

**Required Methods**:
```swift
func createProfile(
    name: String,
    birthDate: Date,
    birthTime: Date,
    locationName: String,
    latitude: Double,
    longitude: Double,
    timezone: String
) async throws -> UserProfile

func updateProfile(
    _ profile: UserProfile,
    name: String,
    birthDate: Date,
    birthTime: Date,
    locationName: String,
    latitude: Double,
    longitude: Double,
    timezone: String
) async throws
```

**Note**: Implementation should:
- Create/update UserProfile in SwiftData
- Calculate BirthChart via ChartCalculator
- Link chart to profile
- Save to ModelContext

**Skip if service already exists with these methods**

---

### T027: Verify Settings Profile List Still Works
**File**: `AstroSvitla/Features/UserManagement/Views/UserProfileListView.swift`
**Action**: VERIFY (no changes)
**Description**: Manual test that existing Settings profile management screen still works.

**Test Scenarios**:
1. Navigate to Settings → User Profiles
2. Verify profile list displays all profiles
3. Test delete profile from Settings
4. Verify deletion works and updates Home tab
5. Verify cascade delete (chart + reports) still works

**Expected**: All existing Settings functionality still works

**Fix if needed**: Update UserProfileListView to use new data model if broken

---

## Phase 8: Testing & Verification

### T028: Run All Unit Tests
**Command**: `xcodebuild test -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15'`
**Description**: Execute full test suite and verify all tests pass.

**Expected Results**:
- ✅ T006-T011 tests now PASS (all implementation complete)
- ✅ Existing tests still PASS (no regressions)
- ❌ If any tests fail, debug and fix before proceeding

**Verify**: Test output shows 0 failures

---

### T029: Run All UI Tests
**Command**: `xcodebuild test -scheme AstroSvitla -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:AstroSvitlaUITests/ProfileSwitchingUITests`
**Description**: Execute UI tests for profile switching flows.

**Expected Results**:
- ✅ T012-T015 tests now PASS (all UI implementation complete)
- ❌ If any tests fail, debug and fix before proceeding

**Verify**: UI test output shows 0 failures

---

### T030: Manual Testing Checklist
**Description**: Perform manual testing of complete inline profile flow.

**Test Scenarios**:

**Scenario 1: First Time User (Empty State)**
- [ ] Launch app on fresh install
- [ ] Home tab shows "New Profile" dropdown
- [ ] Form fields are empty
- [ ] Continue button disabled until all fields filled
- [ ] Fill form with valid data
- [ ] Tap Continue → loading indicator appears
- [ ] Profile saved, dropdown shows profile name
- [ ] Chart displayed

**Scenario 2: Create Second Profile**
- [ ] Open dropdown, tap "Create New Profile"
- [ ] Dropdown shows "New Profile"
- [ ] Form fields clear instantly
- [ ] Fill form with different data
- [ ] Tap Continue → new profile created
- [ ] Dropdown now has 2 items + "Create New"

**Scenario 3: Switch Between Profiles**
- [ ] Open dropdown showing "Alice"
- [ ] See "Alice" (checkmark), "Bob", "Create New"
- [ ] Tap "Bob"
- [ ] Dropdown closes, shows "Bob"
- [ ] Form fields update instantly to Bob's data
- [ ] Chart updates to Bob's chart

**Scenario 4: Duplicate Name Validation**
- [ ] Open dropdown, tap "Create New"
- [ ] Enter existing profile name
- [ ] Tap Continue
- [ ] Error appears: "A profile with this name already exists"
- [ ] Continue button disabled or error shown
- [ ] Profile NOT saved

**Scenario 5: Discard Unsaved Data (FR-065)**
- [ ] Open dropdown, tap "Create New"
- [ ] Start filling form (name "Test")
- [ ] Without tapping Continue, switch to existing profile
- [ ] Form instantly shows existing profile data
- [ ] "Test" data discarded (no confirmation dialog)

**Scenario 6: Delete Active Profile from Settings**
- [ ] Home tab shows "Alice"
- [ ] Go to Settings → User Profiles
- [ ] Delete "Alice"
- [ ] Return to Home tab
- [ ] Dropdown switches to next available profile or "New Profile"
- [ ] Form fields update accordingly

**Scenario 7: Performance**
- [ ] Create 10 profiles
- [ ] Open dropdown → menu renders instantly (<100ms)
- [ ] Switch between profiles → form updates instantly (<100ms)
- [ ] No lag or jank

**Scenario 8: Localization**
- [ ] Test in English → all strings display correctly
- [ ] Test in Ukrainian → all strings translated
- [ ] Dropdown, form labels, buttons, errors all localized

**Pass Criteria**: All scenarios work as expected

---

### T031: Performance Profiling
**Tool**: Xcode Instruments (Time Profiler)
**Description**: Verify inline dropdown meets performance goals from plan.md.

**Measurements**:
1. **Dropdown render time**: Tap dropdown button
   - Goal: <16ms (60fps)
   - Measure: Time from tap to menu fully rendered

2. **Profile switch time**: Select different profile from dropdown
   - Goal: <100ms
   - Measure: Time from selection to form fields updated

3. **Form field population**: Time to populate all form fields
   - Goal: <50ms
   - Measure: Time from handleProfileSelection() call to UI update

**Tool Usage**:
- Launch app in Xcode
- Product → Profile (Cmd+I)
- Choose Time Profiler
- Record while performing dropdown operations
- Verify all operations meet goals

**Pass Criteria**: All operations within performance goals

---

## Phase 9: Documentation & Polish

### T032: Take Screenshots for PR
**Description**: Capture screenshots showing new inline profile UX.

**Required Screenshots**:
1. Empty state ("New Profile" dropdown, empty form)
2. Dropdown menu open (multiple profiles + "Create New")
3. Form filled with profile data
4. Active profile selected (checkmark visible)
5. Validation error displayed
6. Loading state (Continue button with spinner)

**Location**: Save to `screenshots/inline-profile-ux/` for PR description

---

### T033: Update Changelog
**File**: `CHANGELOG.md` or similar
**Description**: Document changes for this feature.

**Entry**:
```markdown
## [Unreleased]

### Changed
- **BREAKING**: Replaced modal-based multi-profile UI with inline dropdown on Home tab
- Profile selector now appears directly on Home tab (no separate screens)
- Birth data form always visible with instant profile switching
- Simplified profile creation flow (no navigation required)

### Removed
- UserSelectorView.swift (replaced by inline Menu)
- UserProfileFormView.swift (form now inline on MainFlowView)

### Fixed
- Profile selection no longer requires multiple taps
- Unsaved profile data now properly discarded on profile switch (FR-065)
```

---

### T034: Add Code Comments
**Files**: `AstroSvitla/Features/Main/MainFlowView.swift`
**Description**: Add explanatory comments for ProfileFormMode and state management.

**Comments to Add**:
```swift
// MARK: - Profile Form State Management
/// Manages the three states of the inline profile form:
/// - empty: No profiles exist (first-time user)
/// - viewing: Displaying an existing profile's data
/// - creating: User selected "Create New Profile"
enum ProfileFormMode: Equatable { ... }

// MARK: - Profile Selection Handlers
/// Updates form fields when user selects a profile from dropdown.
/// Discards any unsaved changes per FR-065 (no confirmation dialog).
private func handleProfileSelection(_ profile: UserProfile) { ... }

/// Clears form fields when user selects "Create New Profile".
/// Discards any unsaved changes per FR-065 (no confirmation dialog).
private func handleCreateNewProfile() { ... }

// MARK: - Profile Persistence
/// Saves profile (create or update) after validation.
/// Shows loading indicator during chart calculation.
private func handleContinue() async { ... }
```

---

## Dependencies Summary

### Phase Dependencies
```
Phase 1 (Cleanup)
    ↓
Phase 2 (State Setup)
    ↓
Phase 3 (Tests - MUST FAIL) ⚠️ TDD GATE
    ↓
Phase 4 (Dropdown Logic)
    ↓
Phase 5 (Form Wiring)
    ↓
Phase 6 (Save Logic)
    ↓
Phase 7 (Integration)
    ↓
Phase 8 (Verification)
    ↓
Phase 9 (Documentation)
```

### Task Dependencies
- **T003** depends on T001, T002 (delete files first, then remove references)
- **T006-T015** (all tests) depend on T004, T005 (enum/state must exist to test)
- **T016-T017** depend on T004, T005 (implement handlers for state/enum)
- **T018** depends on T016, T017 (dropdown calls handlers)
- **T019** depends on T018 (initialize form after dropdown exists)
- **T020-T022** depend on T005 (bind to @State properties)
- **T023-T024** depend on T020-T022 (validation/save need form bindings)
- **T025** depends on T016, T019 (handle profile changes)
- **T028-T031** depend on ALL previous tasks (full implementation complete)
- **T032-T034** depend on T028-T031 (document working feature)

### Visual Flow
```
T001-T003 (Cleanup) → T004-T005 (State) → T006-T015 (Tests ⚠️)
                                              ↓
                            T016-T017 (Handlers) ← Must make tests pass
                                              ↓
                            T018-T019 (Dropdown UI)
                                              ↓
                            T020-T022 (Form Binding)
                                              ↓
                            T023-T024 (Save Logic)
                                              ↓
                            T025-T027 (Integration)
                                              ↓
                            T028-T031 (Verify ALL PASS ✅)
                                              ↓
                            T032-T034 (Document)
```

---

## Parallel Execution Opportunities

### Phase 1: All Parallel
```bash
# Delete both files simultaneously
Task T001: "Delete UserSelectorView.swift"
Task T002: "Delete UserProfileFormView.swift"
# Then run T003 sequentially (depends on T001, T002)
```

### Phase 3: All Parallel (Different Test Files)
```bash
# Write all test files simultaneously
Task T006: "Write ProfileFormMode tests in MainFlowInlineProfileTests.swift"
Task T007: "Write handleProfileSelection tests in MainFlowInlineProfileTests.swift"
Task T008: "Write handleCreateNewProfile tests in MainFlowInlineProfileTests.swift"
Task T009: "Write form validation tests in MainFlowInlineProfileTests.swift"
Task T010: "Write handleContinue tests in MainFlowInlineProfileTests.swift"
Task T011: "Write discarding unsaved data tests in MainFlowInlineProfileTests.swift"
Task T012: "Write dropdown menu UI tests in ProfileSwitchingUITests.swift"
Task T013: "Write profile selection UI tests in ProfileSwitchingUITests.swift"
Task T014: "Write create new profile UI tests in ProfileSwitchingUITests.swift"
Task T015: "Write empty state UI tests in ProfileSwitchingUITests.swift"
```

### Phase 4-6: Sequential (Same File)
All tasks T004-T024 modify MainFlowView.swift → MUST be sequential

### Phase 7: Mixed
- T025 (MainFlowView) → sequential with Phase 4-6
- T026 (UserProfileService) → can be parallel if separate developer
- T027 (Settings verification) → can be parallel (different file)

### Phase 8: Sequential (Build on Each Other)
T028 (unit tests) → T029 (UI tests) → T030 (manual) → T031 (profiling)

### Phase 9: All Parallel
```bash
Task T032: "Take screenshots"
Task T033: "Update changelog"
Task T034: "Add code comments to MainFlowView.swift"
```

---

## Success Criteria

**Definition of Done**: Feature complete when ALL criteria met

- [ ] **Cleanup**
  - [ ] UserSelectorView.swift deleted
  - [ ] UserProfileFormView.swift deleted
  - [ ] Modal sheet references removed from MainFlowView

- [ ] **State Management**
  - [ ] ProfileFormMode enum implemented
  - [ ] All @State properties added
  - [ ] Handlers implemented (handleProfileSelection, handleCreateNewProfile, handleContinue)

- [ ] **UI Implementation**
  - [ ] Inline dropdown Menu component visible on Home tab
  - [ ] Menu shows all profiles + "Create New"
  - [ ] Active profile has checkmark
  - [ ] Form fields bind to @State properties
  - [ ] Continue button shows loading state
  - [ ] Validation errors display inline

- [ ] **TDD**
  - [ ] All unit tests (T006-T011) PASS
  - [ ] All UI tests (T012-T015) PASS
  - [ ] No existing tests broken

- [ ] **Functionality**
  - [ ] Profile selection updates form instantly (<100ms)
  - [ ] Profile creation saves to SwiftData
  - [ ] Chart calculation triggered on save
  - [ ] Duplicate name validation works
  - [ ] Unsaved data discarded on switch (no confirmation)
  - [ ] Empty state handled (first-time user)
  - [ ] Settings profile list still works

- [ ] **Performance**
  - [ ] Dropdown renders in <16ms (60fps)
  - [ ] Profile switch completes in <100ms
  - [ ] Form field population in <50ms

- [ ] **Localization**
  - [ ] All strings localized (EN, UK)
  - [ ] No hardcoded English strings

- [ ] **Documentation**
  - [ ] Screenshots captured
  - [ ] Changelog updated
  - [ ] Code comments added
  - [ ] PR description complete

- [ ] **Build Quality**
  - [ ] `xcodebuild test` passes with 0 failures
  - [ ] No compiler warnings
  - [ ] No SwiftLint violations
  - [ ] Manual testing checklist complete

---

## Notes

### TDD Critical Path
**⚠️ DO NOT skip Phase 3 (Tests)!** Constitution Article III requires test-first development.

**Correct Order**:
1. Write T006-T015 (ALL tests)
2. Run tests → ALL FAIL ✅ Expected
3. Implement T016-T024 (code)
4. Run tests → ALL PASS ✅ Feature works

**Incorrect Order (DO NOT DO THIS)**:
1. ~~Implement T016-T024 first~~
2. ~~Then write tests~~
3. ~~Tests pass immediately~~ ← No confidence that tests work

### Commit Strategy
**Recommended commits**:
- Commit 1: T001-T003 (Cleanup)
- Commit 2: T004-T005 (State setup)
- Commit 3: T006-T015 (All tests - failing)
- Commit 4: T016-T019 (Dropdown logic)
- Commit 5: T020-T024 (Form + save logic)
- Commit 6: T025-T027 (Integration)
- Commit 7: T028-T031 (Verification passing)
- Commit 8: T032-T034 (Documentation)

### Rollback Plan
If issues arise during implementation:
1. Keep commits small (one phase per commit)
2. Git tag before each phase: `git tag phase-N-complete`
3. Rollback with: `git reset --hard phase-N-complete`
4. Re-enable old modal sheets temporarily if needed (don't delete until Phase 8 passes)

### Edge Cases to Watch
- **No profiles + no active profile**: T019 handles this with empty state
- **Active profile deleted elsewhere**: T025 handles this with onChange
- **Rapid profile switching**: SwiftUI bindings should handle this, but test in T030
- **Very long profile names**: Test UI doesn't break (consider maxWidth or lineLimit)

---

## Summary

**Total Tasks**: 34
- **Cleanup**: 3 tasks (T001-T003)
- **State Setup**: 2 tasks (T004-T005)
- **Tests (TDD)**: 10 tasks (T006-T015) ⚠️ MUST FAIL BEFORE PHASE 4
- **Implementation**: 13 tasks (T016-T027)
- **Verification**: 4 tasks (T028-T031)
- **Documentation**: 3 tasks (T032-T034)

**Parallel Opportunities**: 13 tasks can run in parallel (Phase 1: 2, Phase 3: 10, Phase 9: 3)

**Critical Path**: T003 → T004 → T005 → T006-T015 → T016 → T017 → T018 → T019 → T020 → T023 → T024 → T028 → T029 → T030

**Estimated Effort**: 2-3 days for experienced SwiftUI developer

**Complexity**: Low-Medium
- State management is straightforward (ProfileFormMode enum)
- UI changes confined to MainFlowView
- No data model changes (UserProfile already exists)
- Minimal service changes (UserProfileService may already exist)

**Risk Areas**:
- Binding form fields correctly (T020)
- Async handleContinue() with loading state (T024)
- Performance of dropdown with many profiles (T031)

**Ready to Implement**: ✅ Start with T001!

---

**Plan Status**: ✅ Tasks Generated | Ready for Implementation
**Updated**: 2025-10-09
