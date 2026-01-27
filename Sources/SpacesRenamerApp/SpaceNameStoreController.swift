import Foundation
import SpacesRenamerCore

@MainActor
final class SpaceNameStoreController: ObservableObject {
    static let minSpaces = 1
    static let maxSpaces = 24
    static let spaceCountKey = "SpaceCount.v2"

    @Published private(set) var store: SpaceNameStore
    @Published private(set) var orderedSpaceIDs: [String]
    @Published private(set) var fallbackSpaceCount: Int

    private let persistence: SpaceNameStorePersistence
    private let userDefaults: UserDefaults
    private var legacyNamesByIndex: [Int: String]?

    init(persistence: SpaceNameStorePersistence = SpaceNameStorePersistence(),
         userDefaults: UserDefaults = .standard) {
        self.persistence = persistence
        self.userDefaults = userDefaults

        let loadedStore = persistence.load()
        self.store = loadedStore
        self.orderedSpaceIDs = []
        self.legacyNamesByIndex = persistence.loadLegacy()?.names

        let storedCount = userDefaults.integer(forKey: Self.spaceCountKey)
        if storedCount > 0 {
            self.fallbackSpaceCount = storedCount
        } else {
            self.fallbackSpaceCount = max(4, legacyNamesByIndex?.keys.max() ?? 0)
        }

        refreshSpaceOrder()
    }

    var spaceCount: Int {
        orderedSpaceIDs.isEmpty ? fallbackSpaceCount : orderedSpaceIDs.count
    }

    var hasOrderedSpaces: Bool {
        !orderedSpaceIDs.isEmpty
    }

    func refreshSpaceOrder() {
        let newOrder = SpaceOrderReader.orderedSpaceIDs()
        guard !newOrder.isEmpty else {
            return
        }
        if newOrder != orderedSpaceIDs {
            orderedSpaceIDs = newOrder
        }
        if fallbackSpaceCount != newOrder.count {
            fallbackSpaceCount = newOrder.count
            userDefaults.set(fallbackSpaceCount, forKey: Self.spaceCountKey)
        }
        applyLegacyNamesIfNeeded()
    }

    func displayName(for index: Int) -> String {
        guard let spaceID = spaceID(for: index) else {
            return "Desktop \(index)"
        }
        return store.displayName(for: spaceID, fallbackIndex: index)
    }

    func customName(for index: Int) -> String {
        guard let spaceID = spaceID(for: index) else {
            return ""
        }
        return store.customName(for: spaceID) ?? ""
    }

    func hasCustomName(for index: Int) -> Bool {
        guard let spaceID = spaceID(for: index) else {
            return false
        }
        return store.hasCustomName(for: spaceID)
    }

    func setName(_ name: String, for index: Int) {
        guard let spaceID = spaceID(for: index) else {
            return
        }
        store.setName(name, for: spaceID)
        persistence.save(store)
    }

    func clearName(for index: Int) {
        guard let spaceID = spaceID(for: index) else {
            return
        }
        store.clearName(for: spaceID)
        persistence.save(store)
    }

    func resetAll() {
        store = SpaceNameStore()
        persistence.save(store)
    }

    func updateSpaceCount(_ newValue: Int) {
        let clamped = min(max(newValue, Self.minSpaces), Self.maxSpaces)
        guard clamped != fallbackSpaceCount else {
            return
        }
        fallbackSpaceCount = clamped
        userDefaults.set(fallbackSpaceCount, forKey: Self.spaceCountKey)
    }

    private func spaceID(for index: Int) -> String? {
        guard index > 0, index <= orderedSpaceIDs.count else {
            return nil
        }
        return orderedSpaceIDs[index - 1]
    }

    private func applyLegacyNamesIfNeeded() {
        guard let legacy = legacyNamesByIndex, !legacy.isEmpty else {
            return
        }
        guard !orderedSpaceIDs.isEmpty else {
            return
        }
        var migrated = store
        for (index, name) in legacy {
            guard let spaceID = spaceID(for: index) else {
                continue
            }
            migrated.setName(name, for: spaceID)
        }
        store = migrated
        persistence.save(store)
        legacyNamesByIndex = nil
    }
}
