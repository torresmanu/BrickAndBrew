import XCTest

/// Drives the real app and the real iOS permission sheets for a simulator recording.
final class NearbyPintRecordingUITests: XCTestCase {
    func testNearbyPintFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-ReviewRecording"]
        app.launch()

        tap("Allow", within: 12)
        tap("Allow While Using App", within: 8)
        tap("Change to Always Allow", within: 6)

        let me = app.tabBars.buttons["Me"]
        if me.waitForExistence(timeout: 6) {
            me.tap()
        }
        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 2)
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 12)
    }

    private func tap(_ title: String, within timeout: TimeInterval) {
        let app = XCUIApplication()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if tapIfPresent(app.buttons[title]) { return }
            if tapIfPresent(springboard.buttons[title]) { return }
            Thread.sleep(forTimeInterval: 0.25)
        }
    }

    private func tapIfPresent(_ button: XCUIElement) -> Bool {
        guard button.exists, button.isHittable else { return false }
        button.tap()
        return true
    }
}
