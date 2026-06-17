import XCTest
@testable import CatBreakTimerCore

final class TimerControllerTests: XCTestCase {
    func testSettingsClampInvalidSecondValues() {
        let settings = TimerSettings(workSeconds: 0, breakSeconds: 999_999, autoRestartWork: true)

        XCTAssertEqual(settings.workSeconds, 1)
        XCTAssertEqual(settings.breakSeconds, 3600)
        XCTAssertTrue(settings.autoRestartWork)
    }

    func testDurationInputClampsSecondsFieldAndTotalRange() {
        XCTAssertEqual(TimerSettings.durationSeconds(minutes: 1, seconds: 99, range: 1...3600), 119)
        XCTAssertEqual(TimerSettings.durationSeconds(minutes: 0, seconds: 0, range: 1...3600), 1)
        XCTAssertEqual(TimerSettings.durationSeconds(minutes: 999, seconds: 0, range: 1...3600), 3600)
    }

    func testWorkTimerReachesZeroAndStartsBreak() {
        let controller = TimerController(settings: TimerSettings(workSeconds: 2, breakSeconds: 300))

        controller.startWork()
        controller.tick()
        controller.tick()

        XCTAssertEqual(controller.phase, .breakActive)
        XCTAssertEqual(controller.remainingSeconds, 300)
    }

    func testAddExtraWorkTimeDelaysActiveBreak() {
        let controller = TimerController(settings: TimerSettings(workSeconds: 2, breakSeconds: 300))

        controller.startBreak()
        controller.addExtraWorkTime(seconds: 300)

        XCTAssertEqual(controller.phase, .working)
        XCTAssertEqual(controller.remainingSeconds, 300)
    }

    func testBreakTimerEndsWithoutAutoRestart() {
        let controller = TimerController(settings: TimerSettings(workSeconds: 1500, breakSeconds: 60))

        controller.startBreak(seconds: 2)
        controller.tick()
        controller.tick()

        XCTAssertEqual(controller.phase, .idle)
        XCTAssertEqual(controller.remainingSeconds, 0)
    }

    func testBreakTimerAutoRestartsWork() {
        let controller = TimerController(settings: TimerSettings(workSeconds: 180, breakSeconds: 60, autoRestartWork: true))

        controller.startBreak(seconds: 1)
        controller.tick()

        XCTAssertEqual(controller.phase, .working)
        XCTAssertEqual(controller.remainingSeconds, 180)
    }

    func testPauseStopsCountdownAndResumeContinues() {
        let controller = TimerController(settings: TimerSettings(workSeconds: 60, breakSeconds: 60))

        controller.startWork(seconds: 3)
        controller.pause()
        controller.tick()
        XCTAssertEqual(controller.remainingSeconds, 3)

        controller.resume()
        controller.tick()
        XCTAssertEqual(controller.remainingSeconds, 2)
    }
}
