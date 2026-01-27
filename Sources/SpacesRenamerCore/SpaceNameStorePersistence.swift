import Foundation

public struct SpaceNameStorePersistence {
    public static let storageKey = "SpaceNameStore.v2"
    public static let legacyStorageKey = "SpaceNameStore.v1"

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(userDefaults: UserDefaults = .standard,
                encoder: JSONEncoder = JSONEncoder(),
                decoder: JSONDecoder = JSONDecoder()) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() -> SpaceNameStore {
        guard let data = userDefaults.data(forKey: Self.storageKey) else {
            return SpaceNameStore()
        }
        return (try? decoder.decode(SpaceNameStore.self, from: data)) ?? SpaceNameStore()
    }

    public func loadLegacy() -> SpaceNameStoreLegacy? {
        guard let data = userDefaults.data(forKey: Self.legacyStorageKey) else {
            return nil
        }
        return try? decoder.decode(SpaceNameStoreLegacy.self, from: data)
    }

    public func clearLegacy() {
        userDefaults.removeObject(forKey: Self.legacyStorageKey)
    }

    public func save(_ store: SpaceNameStore) {
        guard let data = try? encoder.encode(store) else {
            return
        }
        userDefaults.set(data, forKey: Self.storageKey)
    }
}
