import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.haptics") private var haptics = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("플레이") {
                    Toggle("햅틱", systemImage: "hand.tap.fill", isOn: $haptics)
                }
                Section("게임 정보") {
                    LabeledContent("버전", value: "0.1 MVP")
                    LabeledContent("오늘의 시드", value: String(DailySeed.current()))
                }
            }
            .navigationTitle("설정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}
