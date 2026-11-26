//
//  DeepBlueWeatherUITests.swift
//  DeepBlueWeatherUITests
//
//  Created by Karam Alnaser on 26.02.24.
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

    /// Appends "<name> <unix time>" to markers.txt so a screen recording can be trimmed to this part.
    private func mark(_ name: String) {
        guard let dir = env["SCREENSHOT_DIR"] else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("markers.txt")
        let line = "\(name) \(Date().timeIntervalSince1970)\n"
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            try? handle.close()
        } else {
            try? line.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Demo flows (used for the README GIFs)

    func testDemoConditions() throws {
        let app = makeApp()
        app.launch()
        app.tabBars.buttons["Conditions"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        if !(search.value as? String ?? "").isEmpty, app.buttons["Clear text"].exists {
            app.buttons["Clear text"].tap()
        }
        sleep(1)

        mark("conditions-start")
        search.tap()
        search.typeText("Nice, France\n")
        XCTAssertTrue(app.staticTexts["Hourly forecast"].waitForExistence(timeout: 20))
        sleep(2)
        // Drag along the 24 h curve; the sea above follows the selected hour.
        let chart = app.descendants(matching: .any).matching(identifier: "hourly-chart").firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 5))
        let hero = app.descendants(matching: .any).matching(identifier: "conditions-hero").firstMatch
        let before = hero.label
        for (from, to) in [(0.05, 0.45), (0.45, 0.85)] {
            chart.coordinate(withNormalizedOffset: CGVector(dx: from, dy: 0.6))
                .press(forDuration: 0.1, thenDragTo: chart.coordinate(withNormalizedOffset: CGVector(dx: to, dy: 0.6)),
                       withVelocity: .slow, thenHoldForDuration: 0.2)
            sleep(1)
        }
        XCTAssertNotEqual(hero.label, before, "Dragging the chart should change the selected hour")
        let best = app.buttons["best-window"]
        if best.exists { best.tap(); sleep(2) }
        scroll(to: app.staticTexts["Tide & daylight"], in: app)
        sleep(3)
        mark("conditions-end")
    }

    /// Plans a new night dive for right now, opens it, packs the smart gear, then deletes it again.
    func testDemoDive() throws {
        let app = makeApp()
        app.launch()
        app.tabBars.buttons["Dives"].tap()
        sleep(2)

        mark("dive-start")
        app.buttons["Plan a dive"].firstMatch.tap()
        let location = app.textFields["Search location"]
        XCTAssertTrue(location.waitForExistence(timeout: 5))
        location.tap()
        location.typeText("Nice, France\n")
        sleep(3) // map + conditions load
        app.swipeUp(velocity: .slow)
        let night = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'night'")).firstMatch
        XCTAssertTrue(night.waitForExistence(timeout: 5))
        night.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        sleep(1)
        app.navigationBars.buttons["Save"].tap()

        let card = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'smart gear'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        sleep(2)
        card.tap()
        XCTAssertTrue(app.staticTexts["Conditions at dive time"].waitForExistence(timeout: 10))
        sleep(3)
        scroll(to: app.staticTexts["Smart gear for this dive"], in: app)
        sleep(1)
        let rows = app.buttons.matching(identifier: "gear-row")
        let count = rows.count
        for index in 0..<count {
            rows.element(boundBy: index).tap()
            sleep(1)
        }
        sleep(2) // bubble burst when everything is packed
        mark("dive-end")

        // Clean up: delete the demo dive so the user's data stays unchanged.
        let delete = app.buttons["Delete Dive Plan"]
        scroll(to: delete, in: app)
        delete.tap()
        let confirm = app.buttons["Delete"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        sleep(2)
        XCTAssertFalse(app.staticTexts["Conditions at dive time"].exists)
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
