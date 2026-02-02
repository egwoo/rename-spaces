import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var controller: SpaceNameStoreController
    @ObservedObject var overlayController: MissionControlOverlayController
    @State private var showDiagnostics = false

    private var spaceCountBinding: Binding<Int> {
        Binding(
            get: { controller.spaceCount },
            set: { controller.updateSpaceCount($0) }
        )
    }

    private func nameBinding(for index: Int) -> Binding<String> {
        Binding(
            get: { controller.customName(for: index) },
            set: { controller.setName($0, for: index) }
        )
    }

    private var listHeight: CGFloat {
        let count = CGFloat(controller.spaceCount)
        let rowHeight: CGFloat = 30
        let rowSpacing: CGFloat = 8
        let contentHeight = count * rowHeight + max(count - 1, 0) * rowSpacing
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 900
        let reservedHeight: CGFloat = 260
        let maxHeight = max(200, screenHeight - reservedHeight)
        return min(contentHeight, maxHeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rename Spaces")
                .font(.headline)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(1...controller.spaceCount, id: \.self) { index in
                        HStack {
                            Text("Desktop \(index)")
                                .frame(width: 110, alignment: .leading)

                            TextField("Name", text: nameBinding(for: index))
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 240)

                            Button("Clear") {
                                controller.clearName(for: index)
                            }
                            .buttonStyle(.borderless)
                            .opacity(controller.hasCustomName(for: index) ? 1 : 0)
                            .disabled(!controller.hasCustomName(for: index))
                        }
                    }
                }
                .padding(.trailing, 4)
            }
            .frame(height: listHeight)

            if !AccessibilityPermission.isTrusted() {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Accessibility access is required to overlay names in Mission Control.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Enable Accessibility Access") {
                        AccessibilityPermission.requestIfNeeded()
                    }
                }
            }

            Text("Opening Mission Control refreshes the space count.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            DisclosureGroup("Debug", isExpanded: $showDiagnostics) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Stepper("Spaces: \(controller.spaceCount)", value: spaceCountBinding,
                                in: SpaceNameStoreController.minSpaces...SpaceNameStoreController.maxSpaces)
                            .disabled(controller.hasOrderedSpaces)
                        Spacer()
                        Button("Reset All") {
                            controller.resetAll()
                        }
                    }
                    Toggle("Always show overlay (debug)", isOn: $overlayController.forceOverlay)
                    Divider()
                    let bundle = Bundle.main
                    Text("Bundle ID: \(bundle.bundleIdentifier ?? "unknown")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Bundle path: \(bundle.bundlePath)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("AX trusted: \(overlayController.isTrusted ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Mission Control active: \(overlayController.isMissionControlActive ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Overlay mode: \(overlayController.overlayMode.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Overlay level: \(overlayController.overlayWindowLevel.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let indices = overlayController.lastScanIndices
                    let labelsText = indices.isEmpty
                        ? "Detected labels: none"
                        : "Detected labels: \(indices.map(String.init).joined(separator: ", "))"
                    Text(labelsText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let lastScanAt = overlayController.lastScanAt {
                        Text("Last scan: \(lastScanAt.formatted(date: .omitted, time: .standard))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Dump Dock Accessibility Tree") {
                        if let url = overlayController.dumpDockTree() {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    }
                    .font(.caption)
                    Button("Dump Window List") {
                        if let url = overlayController.dumpWindowList() {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    }
                    .font(.caption)
                    Button("Open Log File") {
                        let url = AppLogger.shared.logURL()
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .font(.caption)
                    Button("Log Overlay Detail") {
                        overlayController.logOverlayDetail(reason: "manual")
                    }
                    .font(.caption)
                    Button("Recreate Overlay Window") {
                        overlayController.recreateOverlayWindow()
                    }
                    .font(.caption)
                }
                .padding(.top, 6)
            }

            Divider()

            HStack {
                Spacer()
                Button("Quit") {
                    NSApp?.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding(12)
        .frame(width: 460)
    }
}
