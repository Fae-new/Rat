import Foundation

final class MouseButtonManager: ObservableObject {
    @Published private(set) var activeButtons = Set<Int>()
    @Published private(set) var lastDetectedButton: Int?

    let store: MappingStore
    private var releaseTasks = [Int: DispatchWorkItem]()

    init(store: MappingStore) {
        self.store = store
    }

    func handle(button: Int, isDown: Bool) {
        if isDown {
            releaseTasks[button]?.cancel()
            releaseTasks[button] = nil
            activeButtons.insert(button)
            lastDetectedButton = button
            store.markDetected(button: button)
        } else {
            let task = DispatchWorkItem { [weak self] in
                self?.activeButtons.remove(button)
                self?.releaseTasks[button] = nil
            }
            releaseTasks[button] = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: task)
        }
    }

    func isActive(_ button: Int) -> Bool {
        activeButtons.contains(button)
    }
}
