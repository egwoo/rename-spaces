import Foundation

public struct SpaceNameStore: Codable, Equatable {
    public private(set) var names: [String: String]

    public init(names: [String: String] = [:]) {
        self.names = names
    }

    public func displayName(for spaceID: String, fallbackIndex: Int) -> String {
        if let name = names[spaceID], !name.isEmpty {
            return name
        }
        return "Desktop \(fallbackIndex)"
    }

    public func customName(for spaceID: String) -> String? {
        return names[spaceID]
    }

    public func hasCustomName(for spaceID: String) -> Bool {
        return names[spaceID]?.isEmpty == false
    }

    public mutating func setName(_ name: String, for spaceID: String) {
        let isBlank = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isBlank {
            names.removeValue(forKey: spaceID)
        } else {
            names[spaceID] = name
        }
    }

    public mutating func clearName(for spaceID: String) {
        names.removeValue(forKey: spaceID)
    }
}

public struct SpaceNameStoreLegacy: Codable, Equatable {
    public let names: [Int: String]
}
