import XCTest
@testable import SpacesRenamerCore

final class SpaceNameStoreTests: XCTestCase {
    func testDisplayNameFallsBackToDesktopIndex() {
        let store = SpaceNameStore(names: [:])

        XCTAssertEqual(store.displayName(for: "space-1", fallbackIndex: 1), "Desktop 1")
        XCTAssertEqual(store.displayName(for: "space-4", fallbackIndex: 4), "Desktop 4")
    }

    func testSetNamePreservesWhitespace() {
        var store = SpaceNameStore(names: [:])

        store.setName("  Focus  ", for: "space-2")

        XCTAssertEqual(store.displayName(for: "space-2", fallbackIndex: 2), "  Focus  ")
    }

    func testSetNameClearsWhenBlank() {
        var store = SpaceNameStore(names: ["space-1": "Work"])

        store.setName("   ", for: "space-1")

        XCTAssertEqual(store.displayName(for: "space-1", fallbackIndex: 1), "Desktop 1")
        XCTAssertFalse(store.hasCustomName(for: "space-1"))
    }

    func testClearNameRemovesEntry() {
        var store = SpaceNameStore(names: ["space-3": "Docs"])

        store.clearName(for: "space-3")

        XCTAssertEqual(store.displayName(for: "space-3", fallbackIndex: 3), "Desktop 3")
        XCTAssertFalse(store.hasCustomName(for: "space-3"))
    }
}
