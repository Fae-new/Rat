import Foundation

final class MappingStore: ObservableObject {
    @Published private(set) var detectedButtons: Set<Int> {
        didSet { saveDetectedButtons() }
    }

    @Published private var mappings: [Int: MouseAction] {
        didSet { saveMappings() }
    }

    @Published private var gestureMappings: [String: MouseAction] {
        didSet { saveGestureMappings() }
    }

    @Published var launchAtLoginEnabled: Bool {
        didSet { defaults.set(launchAtLoginEnabled, forKey: Keys.launchAtLoginEnabled) }
    }

    @Published var listenerPaused: Bool {
        didSet { defaults.set(listenerPaused, forKey: Keys.listenerPaused) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let detectedButtons = "detectedButtons"
        static let mappings = "buttonMappings"
        static let gestureMappings = "gestureMappings"
        static let removedButton2GestureDefaults = "removedButton2GestureDefaults"
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let listenerPaused = "listenerPaused"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedButtons = defaults.array(forKey: Keys.detectedButtons) as? [Int] ?? []
        detectedButtons = Set(savedButtons)

        let savedMappings = defaults.dictionary(forKey: Keys.mappings) as? [String: String] ?? [:]
        mappings = savedMappings.reduce(into: [Int: MouseAction]()) { partialResult, item in
            guard let button = Int(item.key), let action = MouseAction(rawValue: item.value) else { return }
            partialResult[button] = action
        }

        let savedGestureMappings = defaults.dictionary(forKey: Keys.gestureMappings) as? [String: String] ?? [:]
        gestureMappings = savedGestureMappings.reduce(into: [String: MouseAction]()) { partialResult, item in
            guard let action = MouseAction(rawValue: item.value) else { return }
            partialResult[item.key] = action
        }

        launchAtLoginEnabled = defaults.bool(forKey: Keys.launchAtLoginEnabled)
        listenerPaused = defaults.bool(forKey: Keys.listenerPaused)

        removeInjectedButton2GestureDefaultsIfNeeded()
    }

    var displayedButtons: [MouseButton] {
        let baseButtons = Set(0...8)
        return baseButtons.union(detectedButtons)
            .sorted()
            .map { MouseButton(number: $0, isDetected: detectedButtons.contains($0)) }
    }

    var detectedButtonNumbers: [Int] {
        detectedButtons.sorted()
    }

    func markDetected(button: Int) {
        detectedButtons.insert(button)
        if mappings[button] == nil {
            mappings[button] = MouseAction.none
        }
    }

    func action(for button: Int) -> MouseAction {
        mappings[button] ?? .none
    }

    func setAction(_ action: MouseAction, for button: Int) {
        mappings[button] = action
        markDetected(button: button)
    }

    func gestureAction(for button: Int, direction: GestureDirection) -> MouseAction {
        gestureMappings[gestureKey(button: button, direction: direction)] ?? .none
    }

    func setGestureAction(_ action: MouseAction, for button: Int, direction: GestureDirection) {
        gestureMappings[gestureKey(button: button, direction: direction)] = action
        markDetected(button: button)
    }

    private func saveDetectedButtons() {
        defaults.set(detectedButtons.sorted(), forKey: Keys.detectedButtons)
    }

    private func saveMappings() {
        let persisted = mappings.reduce(into: [String: String]()) { partialResult, item in
            partialResult[String(item.key)] = item.value.rawValue
        }
        defaults.set(persisted, forKey: Keys.mappings)
    }

    private func saveGestureMappings() {
        let persisted = gestureMappings.reduce(into: [String: String]()) { partialResult, item in
            partialResult[item.key] = item.value.rawValue
        }
        defaults.set(persisted, forKey: Keys.gestureMappings)
    }

    private func gestureKey(button: Int, direction: GestureDirection) -> String {
        "\(button).\(direction.rawValue)"
    }

    private func removeInjectedButton2GestureDefaultsIfNeeded() {
        guard !defaults.bool(forKey: Keys.removedButton2GestureDefaults) else {
            return
        }

        let leftKey = gestureKey(button: 2, direction: .left)
        let rightKey = gestureKey(button: 2, direction: .right)

        if gestureMappings[leftKey] == .previousDesktop {
            gestureMappings[leftKey] = nil
        }

        if gestureMappings[rightKey] == .nextDesktop {
            gestureMappings[rightKey] = nil
        }

        defaults.set(true, forKey: Keys.removedButton2GestureDefaults)
    }
}
