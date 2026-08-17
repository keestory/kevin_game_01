import XCTest

@MainActor
final class AppStoreGameUITests: XCTestCase {
    func testHomePlayPauseResultAndSameSeedRetryFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-uiTestingFastFail"]
        app.launch()

        let start = app.buttons["startGameButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 4))
        attachScreenshot(named: "return-shot-home", app: app)
        start.tap()

        let game = app.otherElements["returnShotGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 4))
        let startPoint = game.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.75))
        let endPoint = game.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.75))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)

        let pause = app.buttons["pauseButton"]
        XCTAssertTrue(pause.waitForExistence(timeout: 2))
        pause.tap()

        let resume = app.buttons["resumeButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: 2))
        attachScreenshot(named: "return-shot-pause", app: app)
        resume.tap()

        let retry = app.buttons["retryButton"]
        XCTAssertTrue(retry.waitForExistence(timeout: 6))
        attachScreenshot(named: "return-shot-result", app: app)
        retry.tap()

        XCTAssertTrue(app.otherElements["returnShotGameScene"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["pauseButton"].exists)
    }

    private func attachScreenshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
