import XCTest

final class AppStoreGameUITests: XCTestCase {
    func testFirstRunCanEnterGame() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let start = app.buttons["startGameButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 3))

        let homeScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        homeScreenshot.name = "home-v2"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)

        start.tap()

        let tutorial = app.buttons["dismissTutorialButton"]
        if tutorial.waitForExistence(timeout: 2) {
            tutorial.tap()
        }
        XCTAssertTrue(app.buttons["pauseButton"].waitForExistence(timeout: 2))

        let gameScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        gameScreenshot.name = "game-screen"
        gameScreenshot.lifetime = .keepAlways
        add(gameScreenshot)
    }
}
