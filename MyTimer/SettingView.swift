import SwiftUI

struct SettingView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("focus_seconds") private var focusSeconds = 25 * 60
    @AppStorage("short_break_seconds") private var shortBreakSeconds = 5 * 60
    @AppStorage("long_break_seconds") private var longBreakSeconds = 15 * 60
    @AppStorage("long_break_interval") private var longBreakInterval = 4
    @AppStorage("auto_start") private var autoStart = false

    var body: some View {
        Form {
            Section("時間") {
                Picker("集中", selection: $focusSeconds) {
                    Text("5秒（動作確認）").tag(5)
                    Text("25分").tag(25 * 60)
                    Text("50分").tag(50 * 60)
                }

                Picker("短い休憩", selection: $shortBreakSeconds) {
                    Text("3秒（動作確認）").tag(3)
                    Text("5分").tag(5 * 60)
                    Text("10分").tag(10 * 60)
                }

                Picker("長い休憩", selection: $longBreakSeconds) {
                    Text("10分").tag(10 * 60)
                    Text("15分").tag(15 * 60)
                    Text("30分").tag(30 * 60)
                }
            }

            Section("サイクル") {
                Stepper(
                    "長い休憩まで \(longBreakInterval) 回",
                    value: $longBreakInterval,
                    in: 2...8
                )
                Toggle("次のタイマーを自動で開始", isOn: $autoStart)
            }

            Section {
                Text("標準的なポモドーロは、25分集中して5分休憩します。集中を4回終えると長い休憩に入ります。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("秒数設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完了") {
                    dismiss()
                }
            }
        }
    }
}
