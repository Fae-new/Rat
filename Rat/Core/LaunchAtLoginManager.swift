import Foundation
import ServiceManagement

final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published var errorMessage: String?

    private let store: MappingStore

    init(store: MappingStore) {
        self.store = store
        refresh()
    }

    func refresh() {
        if #available(macOS 13.0, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
            store.launchAtLoginEnabled = isEnabled
        } else {
            isEnabled = store.launchAtLoginEnabled
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else {
            isEnabled = false
            store.launchAtLoginEnabled = false
            errorMessage = "Launch at Login requires macOS 13 or later."
            return
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        refresh()
    }
}
