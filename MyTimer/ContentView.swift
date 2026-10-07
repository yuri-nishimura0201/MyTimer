import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    // タイマーは1本だけ使う
    @State private var timer: Timer?
    @State private var endDate: Date?
    @State private var remainingSeconds = 25 * 60
    @State private var isRunning = false

    // 今が集中・短い休憩・長い休憩のどれかを表す
    @State private var mode: PomodoroMode = .focus
    @State private var completedFocusCount = 0

    @State private var showingSettings = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // 設定画面の値を保存する
    @AppStorage("focus_seconds") private var focusSeconds = 25 * 60
    @AppStorage("short_break_seconds") private var shortBreakSeconds = 5 * 60
    @AppStorage("long_break_seconds") private var longBreakSeconds = 15 * 60
    @AppStorage("long_break_interval") private var longBreakInterval = 4
    @AppStorage("auto_start") private var autoStart = false

    private let soundPlayer = SoundPlayer()

    var body: some View {
        NavigationStack {
            ZStack {
                Image("backgroundTimer")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 26) {
                        Text(mode.title)
                            .font(.title.bold())
                            .foregroundStyle(pinkGradient)

                        timerText(
                            title: "集中残り",
                            seconds: mode == .focus ? remainingSeconds : focusSeconds,
                            isActive: mode == .focus
                        )

                        HStack {
                            Button {
                                selectAndStart(.focus)
                            } label: {
                                circleButton(
                                    icon: "heart.fill",
                                    title: "集中",
                                    colors: [.pink, .purple]
                                )
                            }
                            .disabled(isRunning && mode != .focus)

                            Button {
                                selectAndStart(.shortBreak)
                            } label: {
                                circleButton(
                                    icon: "cup.and.saucer.fill",
                                    title: "休憩",
                                    colors: [
                                        Color(red: 1.0, green: 0.75, blue: 0.85),
                                        Color(red: 0.85, green: 0.75, blue: 1.0)
                                    ]
                                )
                            }
                            .disabled(isRunning && mode == .focus)
                        }

                        timerText(
                            title: mode == .longBreak ? "長い休憩残り" : "休憩残り",
                            seconds: mode == .focus ? shortBreakSeconds : remainingSeconds,
                            isActive: mode != .focus
                        )

                        controlButtons
                        progressCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("秒数設定") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings, onDismiss: resetTimer) {
                NavigationStack {
                    SettingView()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // アプリへ戻ったとき、終了時刻から残り時間を計算し直す
                if newPhase == .active {
                    updateRemainingTime()
                }
            }
        }
        .onAppear {
            resetTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private var pinkGradient: LinearGradient {
        LinearGradient(
            colors: [.pink, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func timerText(title: String, seconds: Int, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
            Text(formatTime(seconds))
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(pinkGradient)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(isActive ? 0.82 : 0.58))
        )
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.pink.opacity(0.45), lineWidth: 2)
            }
        }
        .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private func circleButton(icon: String, title: String, colors: [Color]) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.title3.bold())
        }
        .foregroundStyle(.white)
        .frame(width: 120, height: 120)
        .background(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Circle())
        .shadow(color: .pink.opacity(0.5), radius: 10, x: 0, y: 5)
    }

    private var controlButtons: some View {
        HStack(spacing: 14) {
            Button(isRunning ? "一時停止" : "再開") {
                isRunning ? pauseTimer() : startTimer()
            }
            .disabled(!isRunning && remainingSeconds == durationForCurrentMode)
            .buttonStyle(.borderedProminent)

            Button("リセット") {
                resetTimer()
            }
            .buttonStyle(.bordered)

            Button("スキップ") {
                finishCurrentMode(playSound: false)
            }
            .buttonStyle(.bordered)
        }
        .font(.subheadline.weight(.semibold))
        .tint(.purple)
    }

    private var progressCard: some View {
        HStack {
            Label("完了した集中", systemImage: "checkmark.circle.fill")
            Spacer()
            Text("\(completedFocusCount) 回")
                .fontWeight(.bold)
        }
        .foregroundStyle(.purple)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.68))
        )
    }

    private var durationForCurrentMode: Int {
        PomodoroLogic.duration(
            for: mode,
            focus: focusSeconds,
            shortBreak: shortBreakSeconds,
            longBreak: longBreakSeconds
        )
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // 選んだモードへ切り替えて開始する
    private func selectAndStart(_ selectedMode: PomodoroMode) {
        guard !isRunning else { return }

        if mode != selectedMode {
            mode = selectedMode
            remainingSeconds = durationForCurrentMode
        }
        startTimer()
    }

    // タイマーを開始する
    private func startTimer() {
        guard !isRunning, remainingSeconds > 0 else { return }

        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                updateRemainingTime()
            }
        }
    }

    // 終了時刻との差から残り時間を求めるため、バックグラウンドでもずれにくい
    private func updateRemainingTime() {
        guard isRunning, let endDate else { return }

        remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        if remainingSeconds == 0 {
            finishCurrentMode(playSound: true)
        }
    }

    private func pauseTimer() {
        updateRemainingTime()
        stopTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false
    }

    private func resetTimer() {
        stopTimer()
        remainingSeconds = durationForCurrentMode
    }

    // 現在のモードを終えて、次のモードへ進む
    private func finishCurrentMode(playSound: Bool) {
        let finishedMode = mode
        stopTimer()

        if finishedMode == .focus {
            completedFocusCount += 1
        }

        mode = PomodoroLogic.nextMode(
            after: finishedMode,
            completedFocusCount: completedFocusCount,
            longBreakInterval: longBreakInterval
        )
        remainingSeconds = durationForCurrentMode

        if playSound {
            soundPlayer.playCompletionSound()
            alertTitle = finishedMode == .focus ? "集中終了" : "休憩終了"
            alertMessage = finishedMode == .focus
                ? "お疲れさまでした。次は休憩です。"
                : "休憩が終わりました。次は集中です。"
            showingAlert = true
        }

        if autoStart {
            startTimer()
        }
    }
}
