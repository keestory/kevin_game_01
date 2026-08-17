import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.haptics") private var haptics = true
    @AppStorage("settings.sound") private var sound = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("플레이") {
                    Toggle("사운드", systemImage: "speaker.wave.2.fill", isOn: $sound)
                    Toggle("햅틱", systemImage: "hand.tap.fill", isOn: $haptics)
                }
                Section("게임 정보") {
                    LabeledContent("버전", value: "0.3 리턴 샷 체인 프로토타입")
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
