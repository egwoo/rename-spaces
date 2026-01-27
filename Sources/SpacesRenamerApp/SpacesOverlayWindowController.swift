import AppKit

final class SpacesOverlayWindowController {
    private let overlayView = SpacesOverlayView(frame: .zero)
    private var window: NSWindow?
    private var level: OverlayWindowLevel = .assistiveTechHigh

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
