import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum AutomationPermissionStatus: String {
    case unknown = "Unknown"
    case granted = "Granted"
    case missing = "Missing"
}

final class PermissionManager: ObservableObject {
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var inputMonitoringGranted = false
    @Published private(set) var automationStatus: AutomationPermissionStatus = .unknown
    @Published private(set) var automationErrorMessage: String?

    private var didRequestAutomationThisSession = false

    init() {
        refresh(inputMonitoringLikelyGranted: false)
    }

    func refresh(inputMonitoringLikelyGranted: Bool) {
        accessibilityGranted = AXIsProcessTrusted()
        inputMonitoringGranted = inputMonitoringLikelyGranted || canCreateProbeEventTap()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(options)
    }

    func requestAutomationPermissionIfNeeded() {
        guard !didRequestAutomationThisSession else {
            return
        }

        didRequestAutomationThisSession = true
        refreshAutomationPermission()
    }

    func refreshAutomationPermission() {
        if let errorMessage = runSystemEventsProbe() {
            automationStatus = .missing
            automationErrorMessage = errorMessage
        } else {
            automationStatus = .granted
            automationErrorMessage = nil
        }
    }

    func openAccessibilitySettings() {
        openPrivacyPane("Privacy_Accessibility")
    }

    func openInputMonitoringSettings() {
        openPrivacyPane("Privacy_ListenEvent")
    }

    func openAutomationSettings() {
        openPrivacyPane("Privacy_Automation")
    }

    private func openPrivacyPane(_ anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func canCreateProbeEventTap() -> Bool {
        let mask = CGEventMask(1 << CGEventType.otherMouseDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        ) else {
            return false
        }

        CFMachPortInvalidate(tap)
        return true
    }

    private func runSystemEventsProbe() -> String? {
        let source = """
        tell application "System Events"
            count application processes
        end tell
        """

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            return "Could not prepare System Events permission check."
        }

        script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            if let message = errorInfo[NSAppleScript.errorMessage] as? String {
                return message
            }

            return "System Events permission check failed."
        }

        return nil
    }
}
