import AppKit
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func show(appModel: AppModel) {
        if let existingWindow = NSApp.windows.first(where: { $0.title == "Rat Settings" }) {
            NSApp.activate(ignoringOtherApps: true)
            existingWindow.deminiaturize(nil)
            existingWindow.makeMain()
            existingWindow.makeKeyAndOrderFront(nil)
            existingWindow.orderFrontRegardless()
            appModel.prepareSettingsPermissions()
            return
        }

        if window == nil {
            let view = SettingsView()
                .environmentObject(appModel)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Rat Settings"
            window.contentViewController = NSHostingController(rootView: view)
            window.backgroundColor = .windowBackgroundColor
            window.isOpaque = true
            window.hasShadow = true
            window.collectionBehavior = [.moveToActiveSpace]
            window.center()
            window.setFrameAutosaveName("RatSettingsWindow")
            window.isReleasedWhenClosed = false
            window.delegate = self
            self.window = window
        }

        NSApp.activate(ignoringOtherApps: true)
        window?.deminiaturize(nil)
        window?.makeMain()
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        appModel.prepareSettingsPermissions()
    }

    func windowWillClose(_ notification: Notification) {
        window?.orderOut(nil)
    }
}
