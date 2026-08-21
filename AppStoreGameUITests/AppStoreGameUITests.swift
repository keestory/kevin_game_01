import XCTest

@MainActor
final class AppStoreGameUITests: XCTestCase {
    func testHomePlayPauseResultAndSameSeedRetryFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-uiTestingFastFail", "-skipTutorial"]
        app.launch()

        let start = app.buttons["startGameButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 4))
        attachScreenshot(named: "return-shot-action-design-home", app: app)
        start.tap()

        let game = app.otherElements["returnShotGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 4))
        let startPoint = game.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.75))
        let endPoint = game.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.75))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        let progression = app.descendants(matching: .any)["progressionHUD"]
        XCTAssertTrue(progression.waitForExistence(timeout: 2))
        let skillRail = app.descendants(matching: .any)["skillCoreHUD"]
        XCTAssertTrue(skillRail.waitForExistence(timeout: 2))
        attachScreenshot(named: "return-shot-action-design-game", app: app)

        let pause = app.buttons["pauseButton"]
        XCTAssertTrue(pause.waitForExistence(timeout: 2))
        pause.tap()

        let resume = app.buttons["resumeButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: 2))
        attachScreenshot(named: "return-shot-action-design-pause", app: app)
        resume.tap()

        let retry = app.buttons["retryButton"]
        XCTAssertTrue(retry.waitForExistence(timeout: 6))
        attachScreenshot(named: "return-shot-action-design-result", app: app)
        retry.tap()

        XCTAssertTrue(app.otherElements["returnShotGameScene"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["pauseButton"].exists)
    }

    func testNativeDesignSystemGalleryLaunchAndAccessibilityControls() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-designGallery"]
        app.launch()

        let gallery = app.otherElements["designSystemGallery"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 4))
        XCTAssertTrue(app.switches["galleryReduceMotion"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.switches["galleryPhotosensitivity"].exists)
        XCTAssertTrue(app.switches["galleryColorAssist"].exists)
        XCTAssertFalse(app.buttons["startGameButton"].exists)
        attachScreenshot(named: "native-design-system-gallery", app: app)

        let flame = app.buttons["galleryEffect-화염"]
        for _ in 0..<7 where !flame.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(flame.waitForExistence(timeout: 2))
        XCTAssertTrue(flame.isHittable)
        flame.tap()
        let effectStage = app.descendants(matching: .any)["galleryEffectStage"]
        XCTAssertTrue(effectStage.waitForExistence(timeout: 2))
        attachScreenshot(named: "native-design-system-effect-preview", app: app)
    }

    func testDescentHomePlayPauseResultAndRetryFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-skipTutorial", "-uiTestingDescentFastFinish"]
        app.launch()

        let start = app.buttons["startDescentButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        attachScreenshot(named: "descent-breaker-home", app: app)
        start.tap()

        XCTAssertTrue(app.descendants(matching: .any)["descentShipSelection"].waitForExistence(timeout: 4))
        attachScreenshot(named: "descent-breaker-ship-selection", app: app)
        let hammer = app.buttons["descentShipOptionHammer"]
        XCTAssertTrue(hammer.waitForExistence(timeout: 2))
        hammer.tap()
        XCTAssertEqual(app.buttons["descentShipOptionHammer"].value as? String, "선택됨")
        attachScreenshot(named: "descent-breaker-ship-selection-hammer", app: app)
        let confirmShip = app.buttons["descentShipConfirmButton"]
        XCTAssertTrue(confirmShip.waitForExistence(timeout: 2))
        confirmShip.tap()

        let game = app.otherElements["descentGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 4))
        XCTAssertTrue((game.value as? String)?.contains("해머") == true)
        let left = game.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.72))
        let right = game.coordinate(withNormalizedOffset: CGVector(dx: 0.82, dy: 0.72))
        left.press(forDuration: 0.12, thenDragTo: right)
        XCTAssertTrue(app.descendants(matching: .any)["descentSkillHUD"].waitForExistence(timeout: 2))
        attachScreenshot(named: "descent-breaker-game", app: app)

        let pause = app.buttons["descentPauseButton"]
        XCTAssertTrue(pause.waitForExistence(timeout: 2))
        pause.tap()
        let resume = app.buttons["descentResumeButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: 2))
        attachScreenshot(named: "descent-breaker-pause", app: app)
        resume.tap()

        XCTAssertTrue(app.otherElements["descentResultOverlay"].waitForExistence(timeout: 12))
        Thread.sleep(forTimeInterval: 0.45)
        attachScreenshot(named: "descent-breaker-result", app: app)
        let retry = app.buttons["descentRetryButton"]
        XCTAssertTrue(retry.exists)
        retry.tap()
        XCTAssertTrue(app.otherElements["descentGameScene"].waitForExistence(timeout: 4))
    }

    func testRankedEndlessPreflightSeparatesAssistedAndCrossesLevelBoundary() {
        let preflightApp = XCUIApplication()
        preflightApp.launchArguments = ["-uiTesting", "-skipTutorial"]
        preflightApp.launch()

        let start = preflightApp.buttons["startDescentButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        XCTAssertTrue(preflightApp.descendants(matching: .any)["descentShipSelection"].waitForExistence(timeout: 4))
        XCTAssertTrue(preflightApp.buttons["descentShipOptionSwift"].label.contains("빠른 이동·연사"))
        XCTAssertTrue(preflightApp.buttons["descentShipOptionHammer"].label.contains("이동이 가장 느리고 한 레인만"))
        XCTAssertTrue(preflightApp.buttons["descentShipOptionTrident"].label.contains("원소 효과는 중앙탄만"))
        let electric = preflightApp.buttons["descentBoosterElectricButton"]
        XCTAssertTrue(electric.waitForExistence(timeout: 2))
        electric.tap()
        preflightApp.buttons["descentShipConfirmButton"].tap()

        let assistedBadge = preflightApp.staticTexts.matching(
            NSPredicate(format: "identifier == %@ AND label == %@", "descentRankedClassBadge", "ASSISTED")
        ).firstMatch
        XCTAssertTrue(assistedBadge.waitForExistence(timeout: 5))
        XCTAssertEqual(assistedBadge.label, "ASSISTED")
        XCTAssertFalse(preflightApp.otherElements["descentChoiceArena"].exists)
        preflightApp.terminate()

        let levelApp = XCUIApplication()
        levelApp.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-autoStartRankedEndless",
            "-uiTestingEndlessLevelBoundary"
        ]
        levelApp.launch()
        let game = levelApp.otherElements["descentGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 5))
        let reachedLevelTwo = NSPredicate(format: "value CONTAINS %@", "레벨 2")
        expectation(for: reachedLevelTwo, evaluatedWith: game)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(levelApp.descendants(matching: .any)["descentLevelHUD"].exists)
        XCTAssertTrue(levelApp.staticTexts.matching(
            NSPredicate(format: "identifier == %@ AND label == %@", "descentRankedClassBadge", "CLEAN")
        ).firstMatch.exists)
        XCTAssertFalse(levelApp.otherElements["descentResultOverlay"].exists)
        attachScreenshot(named: "descent-ranked-endless-level-2", app: levelApp)
    }

    func testRankedEndlessCombatV2ExposesThreatAndHostileAttack() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-autoStartRankedEndless",
            "-uiTestingEndlessCombatShowcase"
        ]
        app.launch()

        let game = app.otherElements["descentGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["descentThreatTierBadge"].waitForExistence(timeout: 2))

        let visibleThreat = NSPredicate(format: "value CONTAINS %@", "위협 레벨 3")
        expectation(for: visibleThreat, evaluatedWith: game)
        waitForExpectations(timeout: 3)

        let hostileProjectile = NSPredicate(format: "value CONTAINS %@", "적 공격체 1")
        expectation(for: hostileProjectile, evaluatedWith: game)
        waitForExpectations(timeout: 4)
        XCTAssertTrue((game.value as? String)?.contains("전기 레벨 3") == true)
        XCTAssertTrue((game.value as? String)?.contains("바람 레벨 3") == true)
        attachScreenshot(named: "descent-ranked-endless-combat-v2", app: app)
    }

    func testDescentChoiceArenaRedlineFlow() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-autoStartDescent",
            "-uiTestingChoiceArena",
            "-uiTestingDescentFastFinish"
        ]
        app.launch()

        let game = app.otherElements["descentGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 5))

        let arena = app.descendants(matching: .any)["descentChoiceArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["descentChoiceHeading"].exists)
        XCTAssertTrue(app.staticTexts["descentChoicePaceText"].exists)
        let steady = app.buttons["descentChoiceSafeButton"]
        let redline = app.buttons["descentChoiceRedlineButton"]
        XCTAssertTrue(steady.exists)
        XCTAssertTrue(redline.exists)
        attachScreenshot(named: "descent-choice-arena", app: app)

        Thread.sleep(forTimeInterval: 0.45)
        redline.tap()
        XCTAssertFalse(arena.waitForExistence(timeout: 1))
        XCTAssertTrue((game.value as? String)?.contains("레드라인 선택") == true)
        attachScreenshot(named: "descent-choice-redline-resumed", app: app)

        XCTAssertTrue(app.otherElements["descentResultOverlay"].waitForExistence(timeout: 12))
        let summary = app.staticTexts["descentChoiceResultSummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 2))
        XCTAssertTrue((summary.label).contains("레드라인"))
        attachScreenshot(named: "descent-choice-result", app: app)
    }

    func testDescentChoiceArenaSurvivesBackgroundAndRequiresExplicitChoice() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-autoStartDescent",
            "-uiTestingChoiceArena",
            "-descentResearch"
        ]
        app.launch()

        let arena = app.descendants(matching: .any)["descentChoiceArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 6))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(arena.waitForExistence(timeout: 4))

        let steady = app.buttons["descentChoiceSafeButton"]
        XCTAssertTrue(steady.waitForExistence(timeout: 2))
        Thread.sleep(forTimeInterval: 0.45)
        steady.tap()
        XCTAssertFalse(arena.waitForExistence(timeout: 1))
        let game = app.otherElements["descentGameScene"]
        XCTAssertTrue((game.value as? String)?.contains("안정 비행 선택") == true)
    }

    func testDescentCarriedTouchCannotSelectArenaCard() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-autoStartDescent",
            "-uiTestingChoiceArena"
        ]
        app.launch()

        let game = app.otherElements["descentGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 5))
        let left = game.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.72))
        let right = game.coordinate(withNormalizedOffset: CGVector(dx: 0.82, dy: 0.72))
        left.press(forDuration: 3.0, thenDragTo: right)

        let arena = app.descendants(matching: .any)["descentChoiceArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["descentChoiceSafeButton"].exists)
        XCTAssertTrue(app.buttons["descentChoiceRedlineButton"].exists)
        Thread.sleep(forTimeInterval: 0.45)
        app.buttons["descentChoiceSafeButton"].tap()
        XCTAssertFalse(arena.waitForExistence(timeout: 1))
    }

    func testDescentNoArenaResearchVariantNeverShowsChoiceUI() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-autoStartDescent",
            "-uiTestingChoiceArena",
            "-descentResearch",
            "-descentVariantNoArena"
        ]
        app.launch()

        let game = app.otherElements["descentGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 3.5)
        XCTAssertFalse(app.descendants(matching: .any)["descentChoiceArena"].exists)
        XCTAssertTrue((game.value as? String)?.contains("Choice Arena 전") == true)
        XCTAssertFalse(app.otherElements["descentResultOverlay"].exists)
    }

    /// Manual evidence utility. It is skipped in normal CI and only runs while producing
    /// an owner-requested gameplay recording with `RUN_DESCENT_VIDEO_DEMO=1`.
    func testDescentThirtySecondRecordingDemo() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["RUN_DESCENT_VIDEO_DEMO"] == "1",
            "Manual 30-second recording utility"
        )

        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-autoStartDescent",
            "-uiTestingDescentRecordingDemo"
        ]
        app.launch()

        let game = app.otherElements["descentGameScene"]
        XCTAssertTrue(game.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["descentSkillHUD"].waitForExistence(timeout: 2))

        let left = game.coordinate(withNormalizedOffset: CGVector(dx: 0.14, dy: 0.72))
        let right = game.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.72))
        let deadline = Date().addingTimeInterval(36)
        var movesRight = true

        while Date() < deadline {
            let origin = movesRight ? left : right
            let destination = movesRight ? right : left
            origin.press(forDuration: 0.08, thenDragTo: destination)
            movesRight.toggle()
            Thread.sleep(forTimeInterval: 0.18)

            XCTAssertTrue(game.exists, "Descent run ended before the recording completed")
            XCTAssertFalse(app.otherElements["descentResultOverlay"].exists)
        }

    }

    func testRasterLightningArtShowcaseLoadsInGameScene() {
        assertRasterAttackShowcase(kind: "lightning")
    }

    func testRasterFlameArtShowcaseLoadsInGameScene() {
        assertRasterAttackShowcase(kind: "flame")
    }

    func testRasterWindArtShowcaseLoadsInGameScene() {
        assertRasterAttackShowcase(kind: "wind")
    }

    func testRasterPierceArtShowcaseLoadsInGameScene() {
        assertRasterAttackShowcase(kind: "pierce")
    }

    func testMaxOverdriveVisualShowcaseLoadsInGameScene() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-captureHold",
            "-uiTestingArtShowcase",
            "lightning",
            "-uiTestingOverdriveShowcase"
        ]
        app.launch()

        let start = app.buttons["startGameButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 4))
        start.tap()

        XCTAssertTrue(app.otherElements["returnShotGameScene"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.images["artShowcase-lightning-overdrive"].waitForExistence(timeout: 3))
        attachScreenshot(named: "return-shot-max-overdrive", app: app)
    }

    func testDescentResearchConsoleShowsDQPrimaryAndParticipants() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-descentResearchConsole",
            "-uiTestingResearchConsoleSample"
        ]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["researchConsole"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["researchDQBanner"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["researchNextAssignmentCard"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["researchPrimaryRetryKPI"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["researchPrimaryScoreKPI"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["researchPrimaryTouchKPI"].exists)
        attachScreenshot(named: "descent-research-console-summary", app: app)

        let lastParticipant = app.staticTexts["P10"]
        for _ in 0..<12 where !lastParticipant.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(lastParticipant.waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["researchExportButton"].waitForExistence(timeout: 2))
        let deleteButton = app.buttons["researchDeleteButton"]
        XCTAssertTrue(deleteButton.exists)
        XCTAssertFalse(deleteButton.isEnabled, "Sample data must never be deletable")
        attachScreenshot(named: "descent-research-console-participants", app: app)
    }

    func testInvalidDescentResearchAssignmentFailsClosed() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-descentResearch",
            "-descentParticipant", "P01",
            "-descentOrderIndex", "1"
        ]
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["researchAssignmentError"].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.buttons["startDescentButton"].exists)
        XCTAssertFalse(app.otherElements["descentGameScene"].exists)
        attachScreenshot(named: "descent-research-assignment-blocked", app: app)
    }

    private func assertRasterAttackShowcase(kind: String) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-skipTutorial",
            "-captureHold",
            "-uiTestingArtShowcase",
            kind
        ]
        app.launch()

        let start = app.buttons["startGameButton"]
        XCTAssertTrue(start.waitForExistence(timeout: 4), "Missing start button for \(kind)")
        start.tap()

        XCTAssertTrue(
            app.otherElements["returnShotGameScene"].waitForExistence(timeout: 4),
            "Missing GameScene for \(kind)"
        )
        XCTAssertTrue(
            app.images["artShowcase-\(kind)"].waitForExistence(timeout: 3),
            "Missing raster showcase marker for \(kind)"
        )
        attachScreenshot(named: "return-shot-raster-vfx-\(kind)", app: app)
    }

    private func attachScreenshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
