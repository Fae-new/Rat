import Foundation

enum GestureDirection: String, CaseIterable, Codable, Identifiable {
    case left
    case right
    case up
    case down

    var id: String { rawValue }

    var title: String {
        switch self {
        case .left:
            return "Drag Left"
        case .right:
            return "Drag Right"
        case .up:
            return "Drag Up"
        case .down:
            return "Drag Down"
        }
    }

    var shortTitle: String {
        switch self {
        case .left:
            return "Left"
        case .right:
            return "Right"
        case .up:
            return "Up"
        case .down:
            return "Down"
        }
    }
}
