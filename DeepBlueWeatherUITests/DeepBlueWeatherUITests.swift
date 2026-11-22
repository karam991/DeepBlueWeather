//
//  DeepBlueWeatherUITests.swift
//  DeepBlueWeatherUITests
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//
//  Walks through every main screen. Also produces the README screenshots:
//    TEST_RUNNER_SCREENSHOT_DIR=<folder>   save each screen as PNG there
//    TEST_RUNNER_SCREENSHOT_DIVE=<name>    open the dive whose card contains <name>
//  Requires a signed-in user with at least one dive plan.
//

import XCTest

final class DeepBlueWeatherUITests: XCTestCase {

    private let env = ProcessInfo.processInfo.environment

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeApp(_ extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        // Freeze endless background animations so XCUITest can detect an idle app.
        app.launchArguments = ["-pauseAmbientMotion"] + extraArguments
        return app
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = env["SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    /// Swipes up until `element` sits in the upper part of the screen.
    private func scroll(to element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) {
        var swipes = 0
        while swipes < maxSwipes && !(element.exists && element.isHittable && element.frame.minY < app.frame.height * 0.4) {
            app.swipeUp(velocity: .slow)
            swipes += 1
        }
    }

    func testLoginScreen() throws {
        let app = makeApp(["-showLogin"])
        app.launch()
        XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: 10))
        sleep(2)
        snap("login")
    }

    func testMainScreens() throws {
        let app = makeApp()
        app.launch()

        // Conditions
        app.tabBars.buttons["Conditions"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("Nice, France\n")
        XCTAssertTrue(app.staticTexts["Hourly forecast"].waitForExistence(timeout: 20))
        sleep(2)
        snap("conditions")
        scroll(to: app.staticTexts["Tide & daylight"], in: app)
        sleep(2)
        snap("tides")

        // Dives
        app.tabBars.buttons["Dives"].tap()
        sleep(2)
        snap("dives")

        let card: XCUIElement
        if let name = env["SCREENSHOT_DIVE"] {
            card = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
        } else {
            card = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'smart gear'")).firstMatch
        }
        if card.waitForExistence(timeout: 5) {
            card.tap()
            XCTAssertTrue(app.staticTexts["Conditions at dive time"].waitForExistence(timeout: 10))
            sleep(4) // forecast + tide load
            snap("dive-detail")
            scroll(to: app.staticTexts["Tide & daylight"], in: app)
            sleep(1)
            snap("dive-tide")
            scroll(to: app.staticTexts["Smart gear for this dive"], in: app)
            sleep(1)
            snap("smart-gear")
            app.buttons["Back"].tap()
        }

        // Checklist
        app.tabBars.buttons["Checklist"].tap()
        sleep(2)
        snap("checklist")

        // Settings
        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        snap("settings")
    }
}
