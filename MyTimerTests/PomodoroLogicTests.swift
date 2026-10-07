import XCTest
@testable import MyTimer

final class PomodoroLogicTests: XCTestCase {
    func testFocusIsFollowedByShortBreak() {
        let next = PomodoroLogic.nextMode(
            after: .focus,
            completedFocusCount: 1,
            longBreakInterval: 4
        )
        XCTAssertEqual(next, .shortBreak)
    }

    func testFourthFocusIsFollowedByLongBreak() {
        let next = PomodoroLogic.nextMode(
            after: .focus,
            completedFocusCount: 4,
            longBreakInterval: 4
        )
        XCTAssertEqual(next, .longBreak)
    }

    func testBreakIsFollowedByFocus() {
        XCTAssertEqual(
            PomodoroLogic.nextMode(
                after: .longBreak,
                completedFocusCount: 4,
                longBreakInterval: 4
            ),
            .focus
        )
    }

    func testDurationMatchesMode() {
        XCTAssertEqual(
            PomodoroLogic.duration(
                for: .shortBreak,
                focus: 1500,
                shortBreak: 300,
                longBreak: 900
            ),
            300
        )
    }
}
