import ApplicationServices
import CoreGraphics
import Foundation

enum ListenerStatus: String {
    case running = "Running"
    case paused = "Paused"
    case blocked = "Blocked"
}

final class EventTapManager: ObservableObject {
    @Published private(set) var status: ListenerStatus = .paused
    @Published private(set) var lastGestureDescription: String?

    private struct ButtonPressState {
        let startLocation: CGPoint
        let startedAt: Date
        var didRunGesture = false
    }

    private let store: MappingStore
    private let buttonManager: MouseButtonManager
    private let permissionManager: PermissionManager
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var activePresses = [Int: ButtonPressState]()

    private let gestureThreshold: CGFloat = 80

    init(store: MappingStore, buttonManager: MouseButtonManager, permissionManager: PermissionManager) {
        self.store = store
        self.buttonManager = buttonManager
        self.permissionManager = permissionManager
        status = store.listenerPaused ? .paused : .running
    }

    func startIfNeeded() {
        if store.listenerPaused {
            status = .paused
            permissionManager.refresh(inputMonitoringLikelyGranted: false)
            return
        }
        start()
    }

    func start() {
        store.listenerPaused = false

        guard AXIsProcessTrusted() else {
            status = .blocked
            permissionManager.refresh(inputMonitoringLikelyGranted: false)
            return
        }

        if eventTap == nil {
            installEventTap()
        }

        guard let eventTap else {
            status = .blocked
            permissionManager.refresh(inputMonitoringLikelyGranted: false)
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
        status = .running
        permissionManager.refresh(inputMonitoringLikelyGranted: true)
    }

    func pause() {
        store.listenerPaused = true
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        status = .paused
        permissionManager.refresh(inputMonitoringLikelyGranted: eventTap != nil)
    }

    func resume() {
        start()
    }

    func stop() {
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        eventTap = nil
        runLoopSource = nil
        status = .paused
        permissionManager.refresh(inputMonitoringLikelyGranted: false)
    }

    private func installEventTap() {
        let mask = [
            CGEventType.leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .otherMouseDown,
            .otherMouseUp,
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged
        ].reduce(CGEventMask(0)) { partialResult, eventType in
            partialResult | CGEventMask(1 << eventType.rawValue)
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()
            manager.receive(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: selfPointer
        ) else {
            eventTap = nil
            runLoopSource = nil
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
    }

    private func receive(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return
        }

        let button = Int(event.getIntegerValueField(.mouseEventButtonNumber))
        let isDown = type == .leftMouseDown || type == .rightMouseDown || type == .otherMouseDown
        let isUp = type == .leftMouseUp || type == .rightMouseUp || type == .otherMouseUp
        let isMovement = type == .mouseMoved
            || type == .leftMouseDragged
            || type == .rightMouseDragged
            || type == .otherMouseDragged
        let location = event.location

        DispatchQueue.main.async { [weak self] in
            self?.handle(button: button, isDown: isDown, isUp: isUp, isMovement: isMovement, location: location)
        }
    }

    private func handle(button: Int, isDown: Bool, isUp: Bool, isMovement: Bool, location: CGPoint) {
        if isMovement {
            handleMovement(location: location)
            return
        }

        buttonManager.handle(button: button, isDown: isDown)

        guard button >= 2 else {
            return
        }

        if isDown {
            activePresses[button] = ButtonPressState(startLocation: location, startedAt: Date())
            return
        }

        guard isUp else {
            return
        }

        let pressState = activePresses.removeValue(forKey: button)

        guard status == .running, permissionManager.accessibilityGranted else {
            return
        }

        if let pressState {
            if pressState.didRunGesture {
                activePresses.removeValue(forKey: button)
                return
            }

            if runGestureIfAvailable(for: button, state: pressState, currentLocation: location) {
                activePresses.removeValue(forKey: button)
                return
            }
        }

        ActionRunner.run(store.action(for: button))
    }

    private func handleMovement(location: CGPoint) {
        guard status == .running, permissionManager.accessibilityGranted else {
            return
        }

        let buttons = activePresses
            .filter { !$0.value.didRunGesture }
            .sorted { $0.value.startedAt > $1.value.startedAt }

        for item in buttons {
            if runGestureIfAvailable(for: item.key, state: item.value, currentLocation: location) {
                break
            }
        }
    }

    @discardableResult
    private func runGestureIfAvailable(
        for button: Int,
        state: ButtonPressState,
        currentLocation: CGPoint
    ) -> Bool {
        guard let direction = gestureDirection(from: state.startLocation, to: currentLocation) else {
            return false
        }

        let action = store.gestureAction(for: button, direction: direction)
        guard action != .none else {
            return false
        }

        ActionRunner.run(action)

        var updatedState = state
        updatedState.didRunGesture = true
        activePresses[button] = updatedState
        lastGestureDescription = "Button \(button) + \(direction.shortTitle)"
        return true
    }

    private func gestureDirection(from start: CGPoint, to current: CGPoint) -> GestureDirection? {
        let deltaX = current.x - start.x
        let deltaY = current.y - start.y

        if abs(deltaX) >= abs(deltaY), abs(deltaX) >= gestureThreshold {
            return deltaX < 0 ? .left : .right
        }

        if abs(deltaY) >= gestureThreshold {
            return deltaY < 0 ? .up : .down
        }

        return nil
    }
}
