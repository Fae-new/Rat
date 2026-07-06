import Foundation

struct MouseButton: Identifiable, Hashable {
    let number: Int
    let isDetected: Bool

    var id: Int { number }
    var title: String { "Button \(number)" }
}
