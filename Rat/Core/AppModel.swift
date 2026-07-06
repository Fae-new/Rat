import Combine
import Foundation

final class AppModel: ObservableObject {
    let store: MappingStore
    let permissionManager: PermissionManager
    let buttonManager: MouseButtonManager
    let eventTapManager: EventTapManager
    let launchAtLoginManager: LaunchAtLoginManager

    private var cancellables = Set<AnyCancellable>()

    init() {
        let store = MappingStore()
        let permissionManager = PermissionManager()
        let buttonManager = MouseButtonManager(store: store)

        self.store = store
        self.permissionManager = permissionManager
        self.buttonManager = buttonManager
        self.eventTapManager = EventTapManager(
            store: store,
            buttonManager: buttonManager,
            permissionManager: permissionManager
        )
        self.launchAtLoginManager = LaunchAtLoginManager(store: store)

        [
            store.objectWillChange.eraseToAnyPublisher(),
            permissionManager.objectWillChange.eraseToAnyPublisher(),
            buttonManager.objectWillChange.eraseToAnyPublisher(),
            eventTapManager.objectWillChange.eraseToAnyPublisher(),
            launchAtLoginManager.objectWillChange.eraseToAnyPublisher()
        ]
        .forEach { publisher in
            publisher.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        }
    }

    func startListenerIfNeeded() {
        eventTapManager.startIfNeeded()
    }

    func refreshPermissions() {
        permissionManager.refresh(inputMonitoringLikelyGranted: eventTapManager.status == .running)
    }

    func recheckPermissionsAndResumeIfPossible() {
        refreshPermissions()

        guard !store.listenerPaused else {
            return
        }

        if eventTapManager.status != .running {
            eventTapManager.startIfNeeded()
        }
    }

    func prepareSettingsPermissions() {
        recheckPermissionsAndResumeIfPossible()
        permissionManager.requestAutomationPermissionIfNeeded()
    }
}
