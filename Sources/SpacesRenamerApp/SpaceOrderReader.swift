import Foundation

struct SpaceDescriptor: Equatable {
    let id64: Int
    let uuid: String?

    var primaryID: String {
        uuidString ?? id64String
    }

    var id64String: String {
        String(id64)
    }

    var uuidString: String? {
        guard let uuid, !uuid.isEmpty else {
            return nil
        }
        return uuid
    }

    var allIDs: [String] {
        if let uuidString {
            return [uuidString, id64String]
        }
        return [id64String]
    }
}

struct SpaceOrderReader {
    static func orderedSpaces() -> [SpaceDescriptor] {
        guard let domain = UserDefaults.standard.persistentDomain(forName: "com.apple.spaces"),
              let displayConfig = domain["SpacesDisplayConfiguration"] as? [String: Any],
              let management = displayConfig["Management Data"] as? [String: Any],
              let monitors = management["Monitors"] as? [[String: Any]],
              let monitor = selectPrimaryMonitor(from: monitors),
              let spaces = monitor["Spaces"] as? [[String: Any]] else {
            return []
        }

        var result: [SpaceDescriptor] = []
        var seen = Set<String>()
        for space in spaces {
            let type = intValue(space["type"] ?? space["Type"]) ?? -1
            guard type == 0 else {
                continue
            }
            guard let id64 = intValue(space["id64"]) ?? intValue(space["ManagedSpaceID"]) else {
                continue
            }
            let uuid = space["uuid"] as? String
            let descriptor = SpaceDescriptor(id64: id64, uuid: uuid)
            if seen.insert(descriptor.id64String).inserted {
                result.append(descriptor)
            }
        }
        return result
    }

    private static func selectPrimaryMonitor(from monitors: [[String: Any]]) -> [String: Any]? {
        if let main = monitors.first(where: { ($0["Display Identifier"] as? String) == "Main" }) {
            return main
        }
        return monitors.first
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int {
            return int
        }
        if let int64 = value as? Int64 {
            return Int(int64)
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        return nil
    }
}
