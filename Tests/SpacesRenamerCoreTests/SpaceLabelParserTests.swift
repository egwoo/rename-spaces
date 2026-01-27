import XCTest
@testable import SpacesRenamerCore

final class SpaceLabelParserTests: XCTestCase {
    func testParsesDesktopIndex() {
        XCTAssertEqual(SpaceLabelParser.index(from: "Desktop 1"), 1)
        XCTAssertEqual(SpaceLabelParser.index(from: "Desktop 12"), 12)
        XCTAssertEqual(SpaceLabelParser.index(from: "Desktop 3 "), 3)
        XCTAssertEqual(SpaceLabelParser.index(from: "Space 4"), 4)
    }

    func testRejectsNonDesktopLabels() {
        XCTAssertNil(SpaceLabelParser.index(from: "Fullscreen 1"))
        XCTAssertNil(SpaceLabelParser.index(from: "Space"))
        XCTAssertNil(SpaceLabelParser.index(from: "Desktop"))
    }
}
