import XCTest
@testable import SpacesRenamerCore

final class SpaceNameStorePersistenceTests: XCTestCase {
    func testSaveAndLoadRoundTrip() {
        let suiteName = "SpacesRenamerTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let persistence = SpaceNameStorePersistence(userDefaults: userDefaults)
        let store = SpaceNameStore(names: ["space-1": "Work", "space-2": "Chat"])

        persistence.save(store)
        let loaded = persistence.load()

        XCTAssertEqual(loaded, store)
    }

    func testLoadReturnsEmptyWhenDataIsInvalid() {
        let suiteName = "SpacesRenamerTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.set(Data([0x00, 0x01, 0x02]), forKey: SpaceNameStorePersistence.storageKey)
        let persistence = SpaceNameStorePersistence(userDefaults: userDefaults)

        let loaded = persistence.load()

        XCTAssertEqual(loaded, SpaceNameStore(names: [:]))
    }
}
