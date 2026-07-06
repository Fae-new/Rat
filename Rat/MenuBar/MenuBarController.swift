import AppKit
import Combine

final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let appModel: AppModel
    private var cancellables = Set<AnyCancellable>()

    init(appModel: AppModel) {
        self.appModel = appModel
        super.init()
        configureStatusItem()
        rebuildMenu()

        appModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        statusItem.length = 26
        if let image = NSImage(named: "RatMenuBarIcon") {
            image.isTemplate = false
            image.size = NSSize(width: 20, height: 20)
            button.image = image
        } else {
            button.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "Rat")
        }
        button.imagePosition = .imageOnly
        button.title = ""
        button.toolTip = "Rat"
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        menu.addItem(makeItem("Open Settings", action: #selector(openSettings)))
        menu.addItem(NSMenuItem.separator())

        let pauseItem = makeItem("Pause Listener", action: #selector(pauseListener))
        pauseItem.isEnabled = appModel.eventTapManager.status == .running
        menu.addItem(pauseItem)

        let resumeItem = makeItem("Resume Listener", action: #selector(resumeListener))
        resumeItem.isEnabled = appModel.eventTapManager.status != .running
        menu.addItem(resumeItem)

        let launchItem = makeItem("Launch at Login", action: #selector(toggleLaunchAtLogin))
        launchItem.state = appModel.launchAtLoginManager.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeItem("Quit", action: #selector(quit)))

        statusItem.menu = menu
    }

    private func makeItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show(appModel: appModel)
    }

    @objc private func pauseListener() {
        appModel.eventTapManager.pause()
    }

    @objc private func resumeListener() {
        appModel.eventTapManager.resume()
    }

    @objc private func toggleLaunchAtLogin() {
        appModel.launchAtLoginManager.setEnabled(!appModel.launchAtLoginManager.isEnabled)
    }

    @objc private func quit() {
        appModel.eventTapManager.stop()
        NSApp.terminate(nil)
    }
}
