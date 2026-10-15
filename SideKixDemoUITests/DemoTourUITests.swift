import XCTest

/// Scripted walkthroughs used to record the demo videos — no human input.
/// `tool/record_demo.sh` runs one of these while `simctl io recordVideo` is capturing.
/// They append `START` / `END` epoch timestamps to the file named by `DEMO_MARKERS`
/// (passed as `TEST_RUNNER_DEMO_MARKERS`) so the script can trim the footage to the tour.
final class DemoTourUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(element("advisor.a1").waitForExistence(timeout: 15), "advisor list never loaded")
    }

    // MARK: iPhone

    func testPhoneTour() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "iPhone only")
        mark("START")
        pause(3)

        // Filter by offer
        app.buttons["Events"].tap(); pause(1.8)
        app.buttons["Content"].tap(); pause(1.2)
        app.buttons["All"].tap(); pause(1)

        // Scroll the list under the translucent bar
        app.swipeUp(velocity: .slow); pause(1.2)
        app.swipeUp(velocity: .slow); pause(1.2)
        app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); pause(1)

        // Search
        let search = app.textFields["search.field"]
        search.tap()
        search.typeText("tom"); pause(2)
        app.buttons["Clear search"].tap(); pause(1)
        dismissKeyboard()

        // Open a profile, book, then the full-screen view
        element("advisor.a3").tap(); pause(2)
        app.swipeUp(velocity: .slow); pause(1.5)
        app.swipeDown(velocity: .slow); pause(1)
        app.buttons["profile.book"].tap(); pause(3.5)
        app.buttons["profile.fullscreen"].tap(); pause(3.5)
        app.buttons["immersive.close"].tap(); pause(1.5)

        // Back to the list, open another advisor
        app.navigationBars.buttons.element(boundBy: 0).tap(); pause(1.5)
        element("advisor.a5").tap(); pause(2.5)
        app.navigationBars.buttons.element(boundBy: 0).tap(); pause(1.5)
        mark("END")
    }

    // MARK: iPad

    func testPadTour() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad only")
        mark("START")
        pause(3)

        // Pick advisors in the sidebar
        element("advisor.a2").tap(); pause(2)
        element("advisor.a3").tap(); pause(2)

        // Filter, then search
        app.buttons["Events"].tap(); pause(1.8)
        app.buttons["All"].tap(); pause(1)
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("ama"); pause(2)
        element("advisor.a5").tap(); pause(2)
        app.buttons["Cancel"].tap(); pause(1.2)

        // Booking and full screen
        app.buttons["profile.book"].tap(); pause(3.5)
        app.buttons["profile.fullscreen"].tap(); pause(3.5)
        app.buttons["immersive.close"].tap(); pause(1.5)

        // Browse a couple more advisors in the sidebar
        element("advisor.a4").tap(); pause(2.5)
        element("advisor.a6").tap(); pause(2.5)

        mark("END")
    }

    // MARK: Helpers

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func dismissKeyboard() {
        if app.keyboards.count > 0, app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
        } else if app.keyboards.count > 0 {
            app.swipeDown()
        }
    }

    /// Simulator processes share the host filesystem, so the script can read this directly.
    private func mark(_ name: String) {
        let path = ProcessInfo.processInfo.environment["DEMO_MARKERS"] ?? "/tmp/sidekix_demo_markers.txt"
        let line = "\(name) \(Date().timeIntervalSince1970)\n"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile(); handle.write(Data(line.utf8)); try? handle.close()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    /// Real-time wait so the recording shows each state long enough to read.
    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
