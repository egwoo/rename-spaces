import AppKit
import CoreGraphics

final class SpacesOverlayWindowController {
    private let overlayView = SpacesOverlayView(frame: .zero)
    private var window: NSWindow?
    private var level: OverlayWindowLevel = .assistiveTechHigh
    private var lastWindowOrigin: CGPoint = .zero

    func show(items: [SpaceLabelItem], nameProvider: (Int) -> String?) {
        guard !items.isEmpty else {
            hide()
            return
        }

        let windowFrame = unionFrameForAllScreens()
        let window = ensureWindow(frame: windowFrame)
        applyLevel(to: window)
        window.setFrame(windowFrame, display: false)
        overlayView.frame = CGRect(origin: .zero, size: windowFrame.size)
        overlayView.update(items: items, nameProvider: nameProvider, windowOrigin: windowFrame.origin)
        lastWindowOrigin = windowFrame.origin
        window.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func setWindowLevel(_ level: OverlayWindowLevel) {
        self.level = level
        if let window {
            applyLevel(to: window)
        }
    }

    func resetWindow() {
        if let window {
            window.orderOut(nil)
            window.contentView = nil
        }
        overlayView.removeFromSuperview()
        window = nil
    }

    func visibilityState() -> (isVisible: Bool, occlusionVisible: Bool) {
        guard let window else {
            return (false, false)
        }
        let occlusionVisible = window.occlusionState.contains(.visible)
        return (window.isVisible, occlusionVisible)
    }

    func debugInfo(sampleItems: [SpaceLabelItem]) -> String {
        guard let window else {
            return "window=nil"
        }
        let windowNumber = window.windowNumber
        let frame = window.frame
        let levelValue = window.level.rawValue
        let occlusionVisible = window.occlusionState.contains(.visible)
        let cgInfo = cgWindowInfo(for: windowNumber)
        let sample = sampleItems.prefix(3).map { item -> String in
            let adjusted = item.frame.offsetBy(dx: -lastWindowOrigin.x, dy: -lastWindowOrigin.y)
            let x = String(format: "%.1f", adjusted.minX)
            let y = String(format: "%.1f", adjusted.minY)
            let w = String(format: "%.1f", adjusted.width)
            let h = String(format: "%.1f", adjusted.height)
            return "\(item.index){x=\(x),y=\(y),w=\(w),h=\(h)}"
        }
        let sampleText = sample.isEmpty ? "sample=none" : "sample=\(sample.joined(separator: ","))"
        return "window=\(windowNumber) visible=\(window.isVisible) occluded=\(!occlusionVisible) level=\(levelValue) frame=\(rectString(frame)) \(cgInfo) \(sampleText)"
    }

    private func ensureWindow(frame: CGRect) -> NSWindow {
        if let existing = window {
            return existing
        }

        let newWindow = NSPanel(contentRect: frame,
                                styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered,
                                defer: false)
        newWindow.isReleasedWhenClosed = false
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = false
        newWindow.ignoresMouseEvents = true
        newWindow.hidesOnDeactivate = false
        newWindow.isFloatingPanel = true
        newWindow.becomesKeyOnlyIfNeeded = true
        applyLevel(to: newWindow)
        newWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        newWindow.contentView = overlayView
        window = newWindow
        return newWindow
    }

    private func applyLevel(to window: NSWindow) {
        window.level = NSWindow.Level(rawValue: level.levelValue)
    }

    private func unionFrameForAllScreens() -> CGRect {
        NSScreen.screens.reduce(.null) { partial, screen in
            partial.union(screen.frame)
        }
    }

    private func cgWindowInfo(for windowNumber: Int) -> String {
        let infoList = CGWindowListCopyWindowInfo([.optionIncludingWindow], CGWindowID(windowNumber)) as? [[String: Any]]
        guard let info = infoList?.first else {
            return "cg=missing"
        }
        let layer = (info[kCGWindowLayer as String] as? NSNumber)?.intValue
        let bounds = info[kCGWindowBounds as String] as? [String: NSNumber]
        let alpha = (info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue
        let owner = info[kCGWindowOwnerName as String] as? String
        let name = info[kCGWindowName as String] as? String
        let boundsText = bounds.map { dict -> String in
            let x = dict["X"]?.doubleValue ?? 0
            let y = dict["Y"]?.doubleValue ?? 0
            let w = dict["Width"]?.doubleValue ?? 0
            let h = dict["Height"]?.doubleValue ?? 0
            return "bounds=(\(String(format: "%.1f", x)),\(String(format: "%.1f", y)),\(String(format: "%.1f", w)),\(String(format: "%.1f", h)))"
        } ?? "bounds=unknown"
        let layerText = layer.map { "layer=\($0)" } ?? "layer=unknown"
        let alphaText = alpha.map { "alpha=\(String(format: "%.2f", $0))" } ?? "alpha=unknown"
        let ownerText = owner.map { "owner=\($0)" } ?? "owner=unknown"
        let nameText = name.map { "name=\($0)" } ?? "name=unknown"
        return "cg(\(layerText) \(boundsText) \(alphaText) \(ownerText) \(nameText))"
    }

    private func rectString(_ rect: CGRect) -> String {
        let x = String(format: "%.1f", rect.minX)
        let y = String(format: "%.1f", rect.minY)
        let w = String(format: "%.1f", rect.width)
        let h = String(format: "%.1f", rect.height)
        return "(\(x),\(y),\(w),\(h))"
    }
}

enum OverlayWindowLevel: String, CaseIterable, Identifiable {
    case assistiveTechHigh
    case screenSaver
    case maximum
    case shielding

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .assistiveTechHigh:
            return "Assistive Tech High"
        case .screenSaver:
            return "Screen Saver"
        case .maximum:
            return "Maximum"
        case .shielding:
            return "Shielding"
        }
    }

    var levelValue: Int {
        switch self {
        case .assistiveTechHigh:
            return Int(CGWindowLevelForKey(.assistiveTechHighWindow))
        case .screenSaver:
            return Int(CGWindowLevelForKey(.screenSaverWindow))
        case .maximum:
            return Int(CGWindowLevelForKey(.maximumWindow))
        case .shielding:
            return Int(CGShieldingWindowLevel())
        }
    }
}

final class SpacesOverlayView: NSView {
    private var labelViews: [Int: NSTextField] = [:]

    func update(items: [SpaceLabelItem], nameProvider: (Int) -> String?, windowOrigin: CGPoint) {
        let indices = Set(items.map { $0.index })

        for (index, label) in labelViews where !indices.contains(index) {
            label.removeFromSuperview()
            labelViews.removeValue(forKey: index)
        }

        for item in items {
            let label = labelViews[item.index] ?? makeLabel()
            labelViews[item.index] = label

            if label.superview == nil {
                addSubview(label)
            }

            let name = nameProvider(item.index)
            label.stringValue = name ?? ""
            label.isHidden = (name == nil)

            let adjustedFrame = item.frame.offsetBy(dx: -windowOrigin.x, dy: -windowOrigin.y)
            label.frame = adjustedFrame
        }
    }

    private func makeLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = NSColor.white.withAlphaComponent(0.95)

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = CGSize(width: 0, height: -1)
        label.shadow = shadow

        return label
    }
}
