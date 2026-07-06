import Foundation

enum MouseAction: String, CaseIterable, Codable, Identifiable {
    case none
    case previousDesktop
    case nextDesktop
    case swipeLeftBetweenDesktops
    case swipeRightBetweenDesktops
    case missionControl
    case appExpose
    case showDesktop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return "None"
        case .previousDesktop:
            return "Previous Desktop"
        case .nextDesktop:
            return "Next Desktop"
        case .swipeLeftBetweenDesktops:
            return "Swipe Left Between Desktops"
        case .swipeRightBetweenDesktops:
            return "Swipe Right Between Desktops"
        case .missionControl:
            return "Mission Control"
        case .appExpose:
            return "App Exposé"
        case .showDesktop:
            return "Show Desktop"
        }
    }

    var shortcut: KeyboardShortcut? {
        switch self {
        case .previousDesktop, .swipeRightBetweenDesktops:
            return KeyboardShortcut(keyCode: 123, modifiers: .maskControl)
        case .nextDesktop, .swipeLeftBetweenDesktops:
            return KeyboardShortcut(keyCode: 124, modifiers: .maskControl)
        case .missionControl:
            return KeyboardShortcut(keyCode: 126, modifiers: .maskControl)
        case .appExpose:
            return KeyboardShortcut(keyCode: 125, modifiers: .maskControl)
        case .none, .showDesktop:
            return nil
        }
    }
}
