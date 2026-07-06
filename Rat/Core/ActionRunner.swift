import CoreGraphics
import Foundation

enum ActionRunner {
    enum Result {
        case sent(backend: String)
        case failed(String)
        case noShortcut
    }

    private struct ModifierKey {
        let keyCode: CGKeyCode
        let flag: CGEventFlags
    }

    @discardableResult
    static func run(_ action: MouseAction) -> Result {
        guard let shortcut = action.shortcut else {
            return .noShortcut
        }

        if let errorMessage = runAppleScript(shortcut) {
            runCoreGraphics(shortcut)
            return .failed(errorMessage)
        }

        return .sent(backend: "System Events")
    }

    private static func runCoreGraphics(_ shortcut: KeyboardShortcut) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let modifiers = modifierKeys(for: shortcut.modifiers)
        var activeFlags = CGEventFlags()

        for modifier in modifiers {
            activeFlags.insert(modifier.flag)
            postKey(modifier.keyCode, keyDown: true, flags: activeFlags, source: source)
            usleep(12_000)
        }

        postKey(shortcut.keyCode, keyDown: true, flags: shortcut.modifiers, source: source)
        usleep(18_000)
        postKey(shortcut.keyCode, keyDown: false, flags: shortcut.modifiers, source: source)
        usleep(12_000)

        for modifier in modifiers.reversed() {
            activeFlags.remove(modifier.flag)
            postKey(modifier.keyCode, keyDown: false, flags: activeFlags, source: source)
            usleep(8_000)
        }
    }

    private static func runAppleScript(_ shortcut: KeyboardShortcut) -> String? {
        let modifiers = appleScriptModifiers(for: shortcut.modifiers)
        let usingClause = modifiers.isEmpty ? "" : " using {\(modifiers.joined(separator: ", "))}"
        let source = """
        tell application "System Events"
            key code \(shortcut.keyCode)\(usingClause)
        end tell
        """

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            return "Could not prepare System Events script."
        }

        script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            if let message = errorInfo[NSAppleScript.errorMessage] as? String {
                return message
            }

            return "System Events rejected the shortcut."
        }

        return nil
    }

    private static func modifierKeys(for flags: CGEventFlags) -> [ModifierKey] {
        var keys: [ModifierKey] = []

        if flags.contains(.maskShift) {
            keys.append(ModifierKey(keyCode: 56, flag: .maskShift))
        }
        if flags.contains(.maskControl) {
            keys.append(ModifierKey(keyCode: 59, flag: .maskControl))
        }
        if flags.contains(.maskAlternate) {
            keys.append(ModifierKey(keyCode: 58, flag: .maskAlternate))
        }
        if flags.contains(.maskCommand) {
            keys.append(ModifierKey(keyCode: 55, flag: .maskCommand))
        }

        return keys
    }

    private static func appleScriptModifiers(for flags: CGEventFlags) -> [String] {
        var modifiers: [String] = []

        if flags.contains(.maskShift) {
            modifiers.append("shift down")
        }
        if flags.contains(.maskControl) {
            modifiers.append("control down")
        }
        if flags.contains(.maskAlternate) {
            modifiers.append("option down")
        }
        if flags.contains(.maskCommand) {
            modifiers.append("command down")
        }

        return modifiers
    }

    private static func postKey(
        _ keyCode: CGKeyCode,
        keyDown: Bool,
        flags: CGEventFlags,
        source: CGEventSource?
    ) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else {
            return
        }

        event.flags = flags
        event.post(tap: .cghidEventTap)
        event.post(tap: .cgSessionEventTap)
        event.post(tap: .cgAnnotatedSessionEventTap)
    }
}
