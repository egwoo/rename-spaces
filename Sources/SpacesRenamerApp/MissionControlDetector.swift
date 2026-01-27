import AppKit
import CoreGraphics

final class MissionControlDetector {
    private let logger = AppLogger.shared
    private(set) var lastEvidence: String?

    func isActive(on screen: NSScreen?) -> Bool {
        guard screen != nil else {
            lastEvidence = nil
            return false
        }

        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] ?? []

        for window in windows {
            guard let owner = window[kCGWindowOwnerName as String] as? String, owner == "Dock" else {
                continue
            }

            if let name = window[kCGWindowName as String] as? String,
               (name.localizedCaseInsensitiveContains("Mission Control")
                || name.localizedCaseInsensitiveContains("Spaces Bar")) {
                lastEvidence = "Dock window named \(name)"
                return true
            }
        }

        lastEvidence = nil
        return false
    }

    func dumpWindows() -> URL? {
        let logDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Logs/SpacesRenamer", isDirectory: true)
        if let logDir {
            try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logURL = logDir?.appendingPathComponent("window-dump-\(timestamp).txt")

        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] ?? []

        var lines: [String] = []
        for window in windows {
            let owner = window[kCGWindowOwnerName as String] as? String ?? "-"
            let name = window[kCGWindowName as String] as? String ?? "-"
            let layer = window[kCGWindowLayer as String] as? Int ?? 0
            let boundsDict = window[kCGWindowBounds as String] as? [String: Any]
            let bounds = boundsDict.flatMap { CGRect(dictionaryRepresentation: $0 as CFDictionary) }
            let line = "owner=\(owner) name=\(name) layer=\(layer) bounds=\(bounds?.debugDescription ?? "-")"
            lines.append(line)
        }

        guard let logURL else {
            return nil
        }

        let output = lines.joined(separator: "\n")
        try? output.write(to: logURL, atomically: true, encoding: .utf8)
        logger.log("Window dump written: \(logURL.path)")
        return logURL
    }
}
