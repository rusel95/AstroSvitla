//
//  AstroSvitlaUITests.swift
//  AstroSvitlaUITests
//

import XCTest

final class AstroSvitlaUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // --uitesting skips onboarding (sets UserDefaults flag)
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Onboarding bypass

    @MainActor
    func testOnboardingIsSkippedInTestingMode() throws {
        // With --uitesting, onboarding should NOT appear
        // The main content (tabs or empty state) should be visible directly
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "TabBar should be visible — onboarding should be skipped")
    }

    // MARK: - Profile Creation Sheet — Date Picker

    @MainActor
    func testProfileCreationSheetOpens() throws {
        navigateToCreateProfile()

        // Sheet should be open — check for the Save button in toolbar
        let saveButton = app.buttons["profileSaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "ProfileCreationSheet should be open")
    }

    @MainActor
    func testProfileDatePickerOpensSheet() throws {
        navigateToCreateProfile()

        let dateRow = app.buttons["profileDatePickerRow"]
        XCTAssertTrue(dateRow.waitForExistence(timeout: 3), "Date picker row should exist in ProfileCreationSheet")
        dateRow.tap()

        let doneButton = app.buttons["profileDatePickerDoneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Date picker sheet should appear with Done button")
    }

    @MainActor
    func testProfileDatePickerSheetDismissesOnDone() throws {
        navigateToCreateProfile()

        let dateRow = app.buttons["profileDatePickerRow"]
        XCTAssertTrue(dateRow.waitForExistence(timeout: 3))
        dateRow.tap()

        let doneButton = app.buttons["profileDatePickerDoneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        doneButton.tap()

        // Sheet dismissed — date row visible again
        XCTAssertTrue(dateRow.waitForExistence(timeout: 3), "Date row should be visible after dismissing picker")
        XCTAssertFalse(doneButton.exists, "Done button should be gone after dismissing picker sheet")
    }

    @MainActor
    func testProfileTimePickerOpensSheet() throws {
        navigateToCreateProfile()

        let timeRow = app.buttons["profileTimePickerRow"]
        XCTAssertTrue(timeRow.waitForExistence(timeout: 3), "Time picker row should exist in ProfileCreationSheet")
        timeRow.tap()

        let doneButton = app.buttons["profileDatePickerDoneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Time picker sheet should appear with Done button")
    }

    @MainActor
    func testProfileTimePickerSheetDismissesOnDone() throws {
        navigateToCreateProfile()

        let timeRow = app.buttons["profileTimePickerRow"]
        XCTAssertTrue(timeRow.waitForExistence(timeout: 3))
        timeRow.tap()

        let doneButton = app.buttons["profileDatePickerDoneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        doneButton.tap()

        XCTAssertTrue(timeRow.waitForExistence(timeout: 3), "Time row should be visible after dismissing picker")
    }

    @MainActor
    func testDateAndTimePickersDoNotExpandInline() throws {
        navigateToCreateProfile()

        // Tap date row — should open a sheet, not expand inline
        let dateRow = app.buttons["profileDatePickerRow"]
        XCTAssertTrue(dateRow.waitForExistence(timeout: 3))
        dateRow.tap()

        // Done button exists = sheet opened
        let doneButton = app.buttons["profileDatePickerDoneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Picker must open in a sheet, not inline")

        // Other rows must still be accessible (inline expansion would hide them)
        XCTAssertTrue(app.buttons["profileTimePickerRow"].exists, "Time row should still be in hierarchy while date sheet is open")

        doneButton.tap()
    }

    @MainActor
    func testSaveButtonDisabledWithoutRequiredFields() throws {
        navigateToCreateProfile()

        let saveButton = app.buttons["profileSaveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled without name and location")
    }

    // MARK: - Helpers

    /// Navigate through empty state to open ProfileCreationSheet
    private func navigateToCreateProfile() {
        // After onboarding skip, empty state shows because there are no profiles
        let createButton = app.buttons["createProfileButton"]
        if createButton.waitForExistence(timeout: 5) {
            createButton.tap()
        } else {
            XCTFail("createProfileButton not found — are there existing profiles in test state?")
        }
    }
}
