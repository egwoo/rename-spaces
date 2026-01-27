import Foundation

struct SpaceOrderReader {
    static func orderedSpaceIDs() -> [String] {
        guard let domain = UserDefaults.standard.persistentDomain(forName: "com.apple.spaces"),
              let displayConfig = domain["SpacesDisplayConfiguration"] as? [String: Any],
              let management = displayConfig["Management Data"] as? [String: Any],
              let monitors = management["Monitors"] as? [[String: Any]],
              let monitor = selectPrimaryMonitor(from: monitors),
              let spaces = monitor["Spaces"] as? [[String: Any]] else {
            return []
        }

        var result: [String] = []
        for space in spaces {
            let type = intValue(space["type"] ?? space["Type"]) ?? -1
            guard type == 0 else {
                continue
            }
            let idValue = intValue(space["id64"]) ?? intValue(space["ManagedSpaceID"])
            guard let idValue else {
                continue
            }
            let id = String(idValue)
            if result.contains(id) {
                continue
            }
            result.append(id)
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
