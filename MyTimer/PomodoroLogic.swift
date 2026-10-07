import Foundation

// タイマーの3つの状態
enum PomodoroMode: String {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus: "集中タイム"
        case .shortBreak: "休憩タイム"
        case .longBreak: "長い休憩"
        }
    }
}

// 画面と分けることで、切り替え処理だけをテストできる
struct PomodoroLogic {
    static func duration(
        for mode: PomodoroMode,
        focus: Int,
        shortBreak: Int,
        longBreak: Int
    ) -> Int {
        switch mode {
        case .focus: focus
        case .shortBreak: shortBreak
        case .longBreak: longBreak
        }
    }

    static func nextMode(
        after mode: PomodoroMode,
        completedFocusCount: Int,
        longBreakInterval: Int
    ) -> PomodoroMode {
        if mode != .focus {
            return .focus
        }

        let shouldTakeLongBreak = completedFocusCount > 0
            && completedFocusCount % longBreakInterval == 0
        return shouldTakeLongBreak ? .longBreak : .shortBreak
    }
}
