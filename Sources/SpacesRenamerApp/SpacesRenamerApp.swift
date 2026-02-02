import SwiftUI

@main
struct SpacesRenamerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller: SpaceNameStoreController
    @StateObject private var overlayController: MissionControlOverlayController

    init() {
        let controller = SpaceNameStoreController()
        let overlayController = MissionControlOverlayController(
            nameProvider: { index in
                controller.hasCustomName(for: index) ? controller.displayName(for: index) : nil
            },
            spaceCountProvider: {
                controller.spaceCount
            },
            spaceCountUpdater: { count in
                controller.updateSpaceCount(count)
            },
            spaceOrderUpdater: {
                controller.refreshSpaceOrder()
            },
            debugInfoProvider: { indices in
                controller.debugInfo(for: indices)
            }
        )
        _controller = StateObject(wrappedValue: controller)
        _overlayController = StateObject(wrappedValue: overlayController)
        appDelegate.configure(overlayController: overlayController)
    }

    var body: some Scene {
        MenuBarExtra("Rename Spaces", systemImage: "rectangle.3.group") {
            MenuContentView(controller: controller, overlayController: overlayController)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayController: MissionControlOverlayController?

    func configure(overlayController: MissionControlOverlayController) {
        self.overlayController = overlayController
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp?.setActivationPolicy(.accessory)
        overlayController?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlayController?.stop()
    }
}
