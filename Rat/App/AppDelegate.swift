import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appModel = SharedAppState.model
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController(appModel: appModel)
        appModel.startListenerIfNeeded()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        appModel.recheckPermissionsAndResumeIfPossible()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.windows.first { $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        appModel.eventTapManager.stop()
    }
}
