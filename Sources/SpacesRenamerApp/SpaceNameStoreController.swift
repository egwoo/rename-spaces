import Foundation
import SpacesRenamerCore

@MainActor
final class SpaceNameStoreController: ObservableObject {
    static let minSpaces = 1
    static let maxSpaces = 24
    static let spaceCountKey = "SpaceCount.v2"

    @Published private(set) var store: SpaceNameStore
    @Published private(set) var orderedSpaces: [SpaceDescriptor]
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
        self.orderedSpaces = []
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
        orderedSpaces.isEmpty ? fallbackSpaceCount : orderedSpaces.count
    }

    var hasOrderedSpaces: Bool {
        !orderedSpaces.isEmpty
    }

    func refreshSpaceOrder() {
        let newSpaces = SpaceOrderReader.orderedSpaces()
        guard !newSpaces.isEmpty else {
            return
        }
        if newSpaces != orderedSpaces {
            orderedSpaces = newSpaces
        }
        if fallbackSpaceCount != newSpaces.count {
            fallbackSpaceCount = newSpaces.count
            userDefaults.set(fallbackSpaceCount, forKey: Self.spaceCountKey)
        }
        applyLegacyNamesIfNeeded()
    }

    func displayName(for index: Int) -> String {
        guard let spaceIDs = spaceIDs(for: index) else {
            return "Desktop \(index)"
        }
        if let name = resolvedName(for: spaceIDs) {
            return name
        }
        return "Desktop \(index)"
    }

    func customName(for index: Int) -> String {
        guard let spaceIDs = spaceIDs(for: index) else {
            return ""
        }
        return resolvedCustomName(for: spaceIDs) ?? ""
    }

    func hasCustomName(for index: Int) -> Bool {
        guard let spaceIDs = spaceIDs(for: index) else {
            return false
        }
        return resolvedCustomName(for: spaceIDs)?.isEmpty == false
    }

    func setName(_ name: String, for index: Int) {
        guard let ids = spaceIDs(for: index),
              let primaryID = primarySpaceID(for: index) else {
            return
        }
        for id in ids {
            store.clearName(for: id)
        }
        store.setName(name, for: primaryID)
        persistence.save(store)
    }

    func clearName(for index: Int) {
        guard let ids = spaceIDs(for: index) else {
            return
        }
        for id in ids {
            store.clearName(for: id)
        }
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

    private func spaceIDs(for index: Int) -> [String]? {
        guard index > 0, index <= orderedSpaces.count else {
            return nil
        }
        return orderedSpaces[index - 1].allIDs
    }

    private func primarySpaceID(for index: Int) -> String? {
        guard index > 0, index <= orderedSpaces.count else {
            return nil
        }
        return orderedSpaces[index - 1].primaryID
    }

    private func resolvedCustomName(for ids: [String]) -> String? {
        for id in ids {
            if let name = store.customName(for: id) {
                return name
            }
        }
        return nil
    }

    private func resolvedName(for ids: [String]) -> String? {
        for id in ids {
            if let name = store.customName(for: id), !name.isEmpty {
                return name
            }
        }
        return nil
    }

    private func applyLegacyNamesIfNeeded() {
        guard let legacy = legacyNamesByIndex, !legacy.isEmpty else {
            return
        }
        guard !orderedSpaces.isEmpty else {
            return
        }
        var migrated = store
        for (index, name) in legacy {
            guard let primaryID = primarySpaceID(for: index) else {
                continue
            }
            migrated.setName(name, for: primaryID)
        }
        store = migrated
        persistence.save(store)
        persistence.clearLegacy()
        legacyNamesByIndex = nil
    }
}
