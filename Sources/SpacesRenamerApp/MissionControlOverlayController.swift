import AppKit
import Foundation

@MainActor
final class MissionControlOverlayController: ObservableObject {
    private let scanner = DockSpacesScanner()
    private let overlay = SpacesOverlayWindowController()
    private let detector = MissionControlDetector()
    private let logger = AppLogger.shared
    private let nameProvider: (Int) -> String?
    private let spaceCountUpdater: (Int) -> Void
    private let spaceCountProvider: () -> Int
    private let spaceOrderUpdater: () -> Void
    private let userDefaults: UserDefaults
    private var timer: Timer?
    private var lastLogAt: Date?
    private var lastOverlayMode: OverlayMode = .none
    private var lastMissionControlActive: Bool = false
    private static let forceOverlayKey = "SpacesRenamer.ForceOverlay.v1"

    @Published private(set) var lastScanIndices: [Int] = []
    @Published private(set) var lastScanAt: Date?
    @Published private(set) var isTrusted: Bool = false
    @Published private(set) var isMissionControlActive: Bool = false
    @Published private(set) var overlayMode: OverlayMode = .none
    @Published var forceOverlay: Bool {
        didSet {
            userDefaults.set(forceOverlay, forKey: Self.forceOverlayKey)
            logger.log("forceOverlay=\(forceOverlay)")
        }
    }
    @Published var overlayWindowLevel: OverlayWindowLevel {
        didSet {
            overlay.setWindowLevel(overlayWindowLevel)
            logger.log("overlayLevel=\(overlayWindowLevel.displayName)")
        }
    }

    init(nameProvider: @escaping (Int) -> String?,
         spaceCountProvider: @escaping () -> Int,
         spaceCountUpdater: @escaping (Int) -> Void = { _ in },
         spaceOrderUpdater: @escaping () -> Void = {},
         userDefaults: UserDefaults = .standard) {
        self.nameProvider = nameProvider
        self.spaceCountProvider = spaceCountProvider
        self.spaceCountUpdater = spaceCountUpdater
        self.spaceOrderUpdater = spaceOrderUpdater
        self.userDefaults = userDefaults
        self.forceOverlay = userDefaults.bool(forKey: Self.forceOverlayKey)
        self.overlayWindowLevel = .assistiveTechHigh
        overlay.setWindowLevel(self.overlayWindowLevel)
    }

    func dumpDockTree() -> URL? {
        scanner.dumpTree()
    }

    func dumpWindowList() -> URL? {
        detector.dumpWindows()
    }

    func start() {
        AccessibilityPermission.requestIfNeeded()
        if timer != nil {
            return
        }
        timer = Timer.scheduledTimer(timeInterval: 0.2,
                                     target: self,
                                     selector: #selector(handleTimer),
                                     userInfo: nil,
                                     repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        overlay.hide()
    }

    private func tick() {
        let trusted = AccessibilityPermission.isTrusted()
        isTrusted = trusted
        lastScanAt = Date()
        spaceOrderUpdater()

        let screen = primaryScreen()
        let items = trusted ? scanner.fetchSpaceLabelItems() : []
        let filteredItems = filterMissionControlItems(items, on: screen)
        let mcActive = detector.isActive(on: screen) || !filteredItems.isEmpty

        isMissionControlActive = mcActive
        lastScanIndices = filteredItems.map(\.index).sorted()

        if forceOverlay, let screen {
            overlayMode = .forced
            let count = max(spaceCountProvider(), 1)
            let heuristicItems = HeuristicSpaceLayout.items(spaceCount: count, screen: screen)
            lastScanIndices = heuristicItems.map { $0.index }
            overlay.show(items: heuristicItems, nameProvider: nameProvider)
            logState(itemsCount: heuristicItems.count, note: "Forced heuristic")
        } else if !filteredItems.isEmpty, mcActive {
            overlayMode = .accessibility
            if let maxIndex = filteredItems.map(\.index).max() {
                spaceCountUpdater(maxIndex)
            }
            let deduped = dedupe(items: filteredItems)
            overlay.show(items: deduped, nameProvider: nameProvider)
            let note = filteredItems.count == items.count
                ? "Using AX labels"
                : "Using AX labels (filtered \(items.count)->\(filteredItems.count))"
            logState(itemsCount: filteredItems.count, note: note)
        } else if mcActive, let screen {
            overlayMode = .heuristic
            let count = max(spaceCountProvider(), 1)
            let heuristicItems = HeuristicSpaceLayout.items(spaceCount: count, screen: screen)
            lastScanIndices = heuristicItems.map { $0.index }
            overlay.show(items: heuristicItems, nameProvider: nameProvider)
            logState(itemsCount: heuristicItems.count, note: "Using heuristic layout")
        } else {
            overlayMode = .none
            overlay.hide()
            let note: String
            if !items.isEmpty {
                note = "AX labels ignored (not in Mission Control)"
            } else {
                note = trusted ? "Mission Control inactive" : "AX not trusted"
            }
            logState(itemsCount: 0, note: note)
        }
    }

    @objc private func handleTimer() {
        tick()
    }

    private func logState(itemsCount: Int, note: String) {
        let now = Date()
        let shouldLog = lastLogAt.map { now.timeIntervalSince($0) >= 1.0 } ?? true
        let modeChanged = overlayMode != lastOverlayMode
        let mcChanged = isMissionControlActive != lastMissionControlActive

        if shouldLog || modeChanged || mcChanged {
            lastLogAt = now
            lastOverlayMode = overlayMode
            lastMissionControlActive = isMissionControlActive

            let evidence = detector.lastEvidence.map { " evidence=\($0)" } ?? ""
            let message = """
                trusted=\(isTrusted) mcActive=\(isMissionControlActive) mode=\(overlayMode.rawValue) level=\(overlayWindowLevel.displayName) items=\(itemsCount) indices=\(lastScanIndices) note=\(note)\(evidence)
                """
            logger.log(message)
        }
    }

    private func primaryScreen() -> NSScreen? {
        if let screen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) {
            return screen
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    private func filterMissionControlItems(_ items: [SpaceLabelItem], on screen: NSScreen?) -> [SpaceLabelItem] {
        guard let screen else {
            return items
        }
        let screenFrame = screen.frame
        let topBandHeight = max(160, screenFrame.height * 0.25)
        let minY = screenFrame.maxY - topBandHeight
        return items.filter { $0.frame.midY >= minY }
    }

    private func dedupe(items: [SpaceLabelItem]) -> [SpaceLabelItem] {
        var seen = Set<Int>()
        var result: [SpaceLabelItem] = []
        for item in items.sorted(by: { $0.index < $1.index }) {
            if seen.insert(item.index).inserted {
                result.append(item)
            }
        }
        return result
    }
}

enum OverlayMode: String {
    case none = "None"
    case accessibility = "Accessibility"
    case heuristic = "Heuristic"
    case forced = "Forced"
}
