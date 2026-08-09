import UIKit

@MainActor
final class HapticService {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let success = UINotificationFeedbackGenerator()
    private let warning = UINotificationFeedbackGenerator()
    private var lastImpact = Date.distantPast

    func prepare() {
        light.prepare()
        success.prepare()
    }

    func perfect(enabled: Bool) {
        guard enabled, Date.now.timeIntervalSince(lastImpact) > 0.06 else { return }
        lastImpact = .now
        light.impactOccurred(intensity: 0.72)
        light.prepare()
    }

    func match(enabled: Bool) {
        guard enabled else { return }
        success.notificationOccurred(.success)
        success.prepare()
    }

    func overflow(enabled: Bool) {
        guard enabled else { return }
        warning.notificationOccurred(.warning)
    }
}
