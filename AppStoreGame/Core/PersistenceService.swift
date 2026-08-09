import Foundation

@MainActor
final class PersistenceService {
    static let shared = PersistenceService()

    private let defaults: UserDefaults
    private let profileKey = "oneMoreCar.playerProfile.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PlayerProfile {
        guard let data = defaults.data(forKey: profileKey),
              let profile = try? JSONDecoder().decode(PlayerProfile.self, from: data),
              profile.version <= 2 else {
            return PlayerProfile()
        }
        return profile
    }

    func save(_ profile: PlayerProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }
}
