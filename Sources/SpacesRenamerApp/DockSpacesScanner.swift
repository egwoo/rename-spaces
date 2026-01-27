import AppKit
import ApplicationServices
import SpacesRenamerCore

struct SpaceLabelItem {
    let index: Int
    let frame: CGRect
}

final class DockSpacesScanner {
    private let dockBundleIdentifier = "com.apple.dock"
    private let childAttributes: [CFString] = [
        kAXChildrenAttribute as CFString,
        kAXWindowsAttribute as CFString,
        "AXChildrenInNavigationOrder" as CFString
    ]

    func fetchSpaceLabelItems() -> [SpaceLabelItem] {
        guard let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: dockBundleIdentifier).first else {
            return []
        }

        let appElement = AXUIElementCreateApplication(dockApp.processIdentifier)
        var queue: [AXUIElement] = [appElement]
        var results: [SpaceLabelItem] = []

        while let element = queue.first {
            queue.removeFirst()

            if let label = attributeValue(element, attribute: NSAccessibility.Attribute.title.rawValue as CFString) as String?
                ?? attributeValue(element, attribute: NSAccessibility.Attribute.description.rawValue as CFString) as String?
                ?? attributeValue(element, attribute: "AXValue" as CFString) as String? {
                if let index = SpaceLabelParser.index(from: label),
                   let frame = frameValue(for: element) {
                    let normalized = normalizeFrame(frame)
                    results.append(SpaceLabelItem(index: index, frame: normalized))
                }
            }

            let children = collectChildren(for: element)
            if !children.isEmpty {
                queue.append(contentsOf: children)
            }
        }

        return results.sorted { $0.index < $1.index }
    }

    private func attributeValue<T>(_ element: AXUIElement, attribute: CFString) -> T? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard error == .success, let unwrapped = value else {
            return nil
        }
        return unwrapped as? T
    }

    private func frameValue(for element: AXUIElement) -> CGRect? {
        guard let axValue: AXValue = attributeValue(element, attribute: "AXFrame" as CFString) else {
            return nil
        }
        var rect = CGRect.zero
        guard AXValueGetValue(axValue, .cgRect, &rect) else {
            return nil
        }
        return rect
    }

    private func collectChildren(for element: AXUIElement) -> [AXUIElement] {
        var children: [AXUIElement] = []
        for attribute in childAttributes {
            if let values = attributeValue(element, attribute: attribute) as [AXUIElement]? {
                children.append(contentsOf: values)
            }
        }
        return dedupe(children)
    }

    private func dedupe(_ elements: [AXUIElement]) -> [AXUIElement] {
        var seen = Set<CFHashCode>()
        var result: [AXUIElement] = []
        result.reserveCapacity(elements.count)
        for element in elements {
            let hash = CFHash(element)
            if seen.insert(hash).inserted {
                result.append(element)
            }
        }
        return result
    }

    func dumpTree() -> URL? {
        guard let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: dockBundleIdentifier).first else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(dockApp.processIdentifier)
        let logDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Logs/SpacesRenamer", isDirectory: true)
        if let logDir {
            try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logURL = logDir?.appendingPathComponent("ax-dump-\(timestamp).txt")

        var lines: [String] = []
        let maxLines = 6000

        func describe(_ element: AXUIElement, depth: Int) {
            guard lines.count < maxLines else { return }
            let indent = String(repeating: "  ", count: depth)

            let role: String? = attributeValue(element, attribute: kAXRoleAttribute as CFString)
            let subrole: String? = attributeValue(element, attribute: kAXSubroleAttribute as CFString)
            let title: String? = attributeValue(element, attribute: kAXTitleAttribute as CFString)
            let value: String? = attributeValue(element, attribute: "AXValue" as CFString)
            let description: String? = attributeValue(element, attribute: kAXDescriptionAttribute as CFString)
            let frame: CGRect? = frameValue(for: element)

            let line = "\(indent)role=\(role ?? "-") subrole=\(subrole ?? "-") title=\(title ?? "-") value=\(value ?? "-") desc=\(description ?? "-") frame=\(frame?.debugDescription ?? "-")"
            lines.append(line)

            let children = collectChildren(for: element)
            if !children.isEmpty {
                for child in children {
                    describe(child, depth: depth + 1)
                    if lines.count >= maxLines { break }
                }
            }
        }

        describe(appElement, depth: 0)

        guard let logURL else { return nil }
        let output = lines.joined(separator: "\n")
        try? output.write(to: logURL, atomically: true, encoding: .utf8)
        return logURL
    }

    private func normalizeFrame(_ frame: CGRect) -> CGRect {
        guard let screen = screenFor(frame: frame) else {
            return frame
        }
        let screenFrame = screen.frame

        // Heuristic: Mission Control labels should be near the top. If AX uses a top-left
        // origin, y will be small; flip into AppKit's bottom-left coordinate space.
        if frame.midY < screenFrame.midY {
            let flippedY = screenFrame.maxY - frame.maxY
            return CGRect(x: frame.origin.x, y: flippedY, width: frame.width, height: frame.height)
        }

        return frame
    }

    private func screenFor(frame: CGRect) -> NSScreen? {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return NSScreen.screens.first { $0.frame.contains(center) }
    }
}
