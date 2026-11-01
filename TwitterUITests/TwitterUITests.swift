import XCTest

/// Drives the column stack's gestures on whichever display the app is on, with mock data, so they can be recorded and
/// checked by eye: Simulator's own pointer only reaches iPhone Duo's outer display. Runs against the installed app
/// (install it first), since the test bundle isn't hosted by it.
final class ColumnGestureUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRetroComposerAndDrafts() throws {
        let app = launch("--tab", "home", "--compose")
        let editor = app.descendants(matching: .any).matching(identifier: "Tweet text").firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("Hello retro")
        XCTAssertTrue(app.staticTexts["269 characters remaining"].exists)
        capture(app, "Classic composer")

        app.buttons["Cancel"].firstMatch.tap()
        app.buttons["Save Draft"].tap()
        XCTAssertTrue(app.buttons["New Tweet"].waitForExistence(timeout: 5))
        app.buttons["New Tweet"].tap()
        app.buttons["Drafts"].tap()
        XCTAssertTrue(app.staticTexts["Hello retro"].waitForExistence(timeout: 5))
        capture(app, "Classic drafts")
        app.staticTexts["Hello retro"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertTrue((editor.value as? String)?.contains("Hello retro") == true)
        // Mock posting also removes this test's saved draft.
        app.buttons["Tweet"].tap()
        XCTAssertTrue(app.buttons["New Tweet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testComposerThreadEditing() throws {
        let app = launch("--tab", "home", "--compose")
        let first = app.descendants(matching: .any).matching(identifier: "Tweet text").firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        first.typeText("First Tweet")
        app.buttons["Add another Tweet"].tap()
        let next = app.descendants(matching: .any).matching(identifier: "Next Tweet in thread").firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()
        next.typeText("Second Tweet")
        XCTAssertTrue(app.buttons["Tweet"].isEnabled)
        capture(app, "Thread composer")
        app.buttons["Remove Tweet from Thread"].tap()
        XCTAssertFalse(next.exists)
        app.buttons["Tweet"].tap()
        XCTAssertTrue(app.buttons["New Tweet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSwipeTrayFavoritesBookmarksAndQuote() throws {
        let app = launch("--tab", "home")
        let post = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "The Composable Architecture 1.26")
        ).firstMatch
        XCTAssertTrue(post.waitForExistence(timeout: 5))
        let start = post.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        start.press(
            forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: -180, dy: 0)), withVelocity: 400,
            thenHoldForDuration: 0)
        let tray = app.otherElements["tweet-action-tray"]
        XCTAssertTrue(tray.waitForExistence(timeout: 5))
        capture(app, "Swipe action tray")
        tray.buttons["Favorite"].tap()
        XCTAssertTrue(tray.buttons["Remove Favorite"].waitForExistence(timeout: 3))
        tray.buttons["Remove Favorite"].tap()
        tray.buttons["Bookmark"].tap()
        XCTAssertTrue(tray.buttons["Remove Bookmark"].waitForExistence(timeout: 3))
        tray.buttons["Remove Bookmark"].tap()
        let closeStart = post.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.5))
        closeStart.press(
            forDuration: 0.05, thenDragTo: closeStart.withOffset(CGVector(dx: 180, dy: 0)), withVelocity: 400,
            thenHoldForDuration: 0)
        XCTAssertTrue(tray.waitForNonExistence(timeout: 3))
        start.press(
            forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: -180, dy: 0)), withVelocity: 400,
            thenHoldForDuration: 0)
        XCTAssertTrue(tray.waitForExistence(timeout: 3))

        tray.buttons["Retweet"].tap()
        XCTAssertTrue(app.buttons["Quote Tweet"].waitForExistence(timeout: 5))
        capture(app, "Classic retweet sheet")
        app.buttons["Quote Tweet"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "Tweet text").firstMatch.waitForExistence(timeout: 5))
        capture(app, "Quote composer")
    }

    @MainActor
    func testClassicBackButtonAndNativeEdgeSwipe() throws {
        let app = launch("--tab", "home", "--open-thread")
        let back = app.buttons["Back"].firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        capture(app, "Classic back bezel")
        // A short, held edge pull must cancel without discarding the thread or its navigation state.
        point(in: app, x: 5, y: 400).press(
            forDuration: 0.05, thenDragTo: point(in: app, x: 65, y: 400), withVelocity: 100, thenHoldForDuration: 1)
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        point(in: app, x: 5, y: 400).press(
            forDuration: 0.05, thenDragTo: point(in: app, x: 350, y: 400), withVelocity: 500, thenHoldForDuration: 0)
        XCTAssertTrue(app.buttons["New Tweet"].waitForExistence(timeout: 5))
        XCTAssertFalse(back.exists)

        let post = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "The Composable Architecture 1.26")
        ).firstMatch
        // Tap prose rather than the link at the end of the same text element.
        post.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        sleep(1)
        point(in: app, x: 5, y: 400).press(
            forDuration: 0.05, thenDragTo: point(in: app, x: 350, y: 400), withVelocity: 500, thenHoldForDuration: 0)
        XCTAssertTrue(app.buttons["New Tweet"].waitForExistence(timeout: 5))
        XCTAssertFalse(back.exists)

        post.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(app.buttons["New Tweet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testClassicListsRefresh() throws {
        let app = launch("--tab", "home", "--open-lists")
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        start.press(
            forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 300)), withVelocity: 150,
            thenHoldForDuration: 1)
        XCTAssertTrue(scroll.exists)
        capture(app, "Classic Lists")
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Hold below the catch, then past it, for checking the classic arrow and loading header in a recording.
    @MainActor
    func testPullToRefresh() throws {
        let app = launch()
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        start.press(
            forDuration: 0.05,
            thenDragTo: start.withOffset(CGVector(dx: 0, dy: 90)),
            withVelocity: 150, thenHoldForDuration: 2)
        sleep(1)
        start.press(
            forDuration: 0.05,
            thenDragTo: start.withOffset(CGVector(dx: 0, dy: 300)),
            withVelocity: 150, thenHoldForDuration: 2)
        sleep(2)
        XCTAssertTrue(scroll.exists)
    }

    /// Opens a thread as a column, then pulls it down by its bar until it closes.
    @MainActor
    func testPullColumnDown() throws {
        let app = launch("--open-thread")
        let frame = app.windows.firstMatch.frame
        // In the newest column's bar: the trailing card, just below its top edge.
        let start = point(in: app, x: frame.width * 0.6, y: 60)
        start.press(
            forDuration: 0.05, thenDragTo: point(in: app, x: frame.width * 0.6, y: 460), withVelocity: 900,
            thenHoldForDuration: 0)
        sleep(2)
    }

    /// Opens a thread, then pulls the strip past its start and lets go, throwing the column away.
    @MainActor
    func testThrowColumnsAway() throws {
        let app = launch("--open-thread")
        let frame = app.windows.firstMatch.frame
        let start = point(in: app, x: frame.width * 0.3, y: frame.height * 0.5)
        start.press(
            forDuration: 0.05, thenDragTo: point(in: app, x: frame.width * 0.3 + 320, y: frame.height * 0.5),
            withVelocity: 600, thenHoldForDuration: 0.1)
        sleep(2)
    }

    /// Slides the strip back to show the column under the newest one, and forward again.
    @MainActor
    func testSlideColumns() throws {
        let app = launch("--open-thread", "--open-profile")
        let frame = app.windows.firstMatch.frame
        let y = frame.height * 0.5
        point(in: app, x: frame.width * 0.3, y: y)
            .press(
                forDuration: 0.05, thenDragTo: point(in: app, x: frame.width * 0.3 + 260, y: y),
                withVelocity: 1200, thenHoldForDuration: 0)
        sleep(1)
        point(in: app, x: frame.width * 0.6, y: y)
            .press(
                forDuration: 0.05, thenDragTo: point(in: app, x: frame.width * 0.6 - 260, y: y),
                withVelocity: 1200, thenHoldForDuration: 0)
        sleep(1)
    }

    /// Opens a reply's thread and scrolls up to the conversation above it.
    @MainActor
    func testScrollThreadUpToContext() throws {
        let app = launch("--open-reply")
        let frame = app.windows.firstMatch.frame
        let x = frame.width * 0.5
        point(in: app, x: x, y: frame.height * 0.3)
            .press(
                forDuration: 0.05, thenDragTo: point(in: app, x: x, y: frame.height * 0.8), withVelocity: 800,
                thenHoldForDuration: 0.5)
        sleep(6)
    }

    /// Turns the device to the orientation named in the `UITEST_ORIENTATION` environment variable (portrait,
    /// portraitUpsideDown, landscapeLeft, landscapeRight) and launches with the arguments in `UITEST_ARGS`, then waits
    /// for a screenshot to be taken from outside.
    @MainActor
    func testPose() throws {
        let environment = ProcessInfo.processInfo.environment
        let orientations: [String: UIDeviceOrientation] = [
            "portrait": .portrait, "portraitUpsideDown": .portraitUpsideDown,
            "landscapeLeft": .landscapeLeft, "landscapeRight": .landscapeRight
        ]
        if let name = environment["UITEST_ORIENTATION"], let orientation = orientations[name] {
            XCUIDevice.shared.orientation = orientation
        }
        let arguments = (environment["UITEST_ARGS"] ?? "").split(separator: " ").map(String.init)
        let app = XCUIApplication(bundleIdentifier: "gold.samhenri.Twitter")
        app.launchArguments = ["--mock-twitter"] + arguments
        app.launch()
        sleep(8)
    }

    private func launch(_ arguments: String...) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "gold.samhenri.Twitter")
        app.launchArguments = ["--mock-twitter"] + arguments
        app.launch()
        sleep(3)
        return app
    }

    private func point(in app: XCUIApplication, x: CGFloat, y: CGFloat) -> XCUICoordinate {
        app.windows.firstMatch.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y))
    }
}
