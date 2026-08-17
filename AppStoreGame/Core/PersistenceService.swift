import Foundation

@MainActor
final class PersistenceService {
    static let shared = PersistenceService()

    private let defaults: UserDefaults
    private let profileKey = "returnShot.playerProfile.v1"
    private let recoveryKey = "returnShot.playerProfile.recovery"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PlayerProfile {
        guard let data = defaults.data(forKey: profileKey) else {
            return PlayerProfile()
        }
        do {
            return try JSONDecoder().decode(PlayerProfile.self, from: data)
        } catch {
            if defaults.data(forKey: recoveryKey) == nil {
                defaults.set(data, forKey: recoveryKey)
            }
            return PlayerProfile()
        }
    }

    func save(_ profile: PlayerProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }
}
