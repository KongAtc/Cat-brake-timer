import XCTest
@testable import CatBreakTimerCore

final class TimerControllerTests: XCTestCase {
    func testSettingsClampInvalidValues() {
        let settings = TimerSettings(workMinutes: 0, breakMinutes: 99, autoRestartWork: true)

        XCTAssertEqual(settings.workMinutes, 1)
        XCTAssertEqual(settings.breakMinutes, 60)
        XCTAssertTrue(settings.autoRestartWork)
    }

    func testWorkTimerReachesZeroAndStartsBreak() {
        let controller = TimerController(settings: TimerSettings(workMinutes: 1, breakMinutes: 5))

        controller.startWork(seconds: 2)
        controller.tick()
        controller.tick()

        XCTAssertEqual(controller.phase, .breakActive)
        XCTAssertEqual(controller.remainingSeconds, 300)
    }

    func testBreakTimerEndsWithoutAutoRestart() {
        let controller = TimerController(settings: TimerSettings(workMinutes: 25, breakMinutes: 1))

        controller.startBreak(seconds: 2)
        controller.tick()
        controller.tick()

        XCTAssertEqual(controller.phase, .idle)
        XCTAssertEqual(controller.remainingSeconds, 0)
    }

    func testBreakTimerAutoRestartsWork() {
        let controller = TimerController(settings: TimerSettings(workMinutes: 3, breakMinutes: 1, autoRestartWork: true))

        controller.startBreak(seconds: 1)
        controller.tick()

        XCTAssertEqual(controller.phase, .working)
        XCTAssertEqual(controller.remainingSeconds, 180)
    }

    func testPauseStopsCountdownAndResumeContinues() {
        let controller = TimerController(settings: TimerSettings(workMinutes: 1, breakMinutes: 1))

        controller.startWork(seconds: 3)
        controller.pause()
        controller.tick()
        XCTAssertEqual(controller.remainingSeconds, 3)

        controller.resume()
        controller.tick()
        XCTAssertEqual(controller.remainingSeconds, 2)
    }
}
