import Foundation

enum RewardedAdOutcome: Equatable {
    case rewarded(impressionID: String)
    case dismissed
    case unavailable
    case failed
}

@MainActor
protocol RewardedAdServing {
    var isReady: Bool { get }
    func showRescueAd() async -> RewardedAdOutcome
}

#if DEBUG
@MainActor
final class MockRewardedAdService: RewardedAdServing {
    var isReady: Bool { true }

    func showRescueAd() async -> RewardedAdOutcome {
        if !ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            try? await Task.sleep(for: .milliseconds(900))
        }
        return .rewarded(impressionID: UUID().uuidString)
    }
}
#endif

@MainActor
final class UnavailableRewardedAdService: RewardedAdServing {
    var isReady: Bool { false }
    func showRescueAd() async -> RewardedAdOutcome { .unavailable }
}
