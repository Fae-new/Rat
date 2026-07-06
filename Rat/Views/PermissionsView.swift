import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        FormPage(title: "Permissions", subtitle: "Execution is disabled until the required permissions are available.") {
            SettingsCard {
                StatusLine(
                    title: "Accessibility",
                    value: appModel.permissionManager.accessibilityGranted ? "Granted" : "Missing",
                    color: appModel.permissionManager.accessibilityGranted ? .green : .red
                )

                StatusLine(
                    title: "Input Monitoring",
                    value: appModel.permissionManager.inputMonitoringGranted ? "Granted" : "Missing",
                    color: appModel.permissionManager.inputMonitoringGranted ? .green : .red
                )

                StatusLine(
                    title: "Automation",
                    value: appModel.permissionManager.automationStatus.rawValue,
                    color: automationColor
                )

                StatusLine(
                    title: "Listener",
                    value: appModel.eventTapManager.status.rawValue,
                    color: listenerColor
                )

                if let errorMessage = appModel.permissionManager.automationErrorMessage {
                    Divider()

                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsCard {
                HStack {
                    Button("Request Accessibility") {
                        appModel.permissionManager.requestAccessibilityPermission()
                        appModel.recheckPermissionsAndResumeIfPossible()
                    }

                    Button("Open Accessibility Settings") {
                        appModel.permissionManager.openAccessibilitySettings()
                    }

                    Button("Open Input Monitoring Settings") {
                        appModel.permissionManager.openInputMonitoringSettings()
                    }

                    Spacer()
                }

                HStack {
                    Button("Request Automation") {
                        appModel.permissionManager.refreshAutomationPermission()
                    }

                    Button("Open Automation Settings") {
                        appModel.permissionManager.openAutomationSettings()
                    }

                    Spacer()
                }

                HStack {
                    Button("Refresh Status") {
                        appModel.recheckPermissionsAndResumeIfPossible()
                        appModel.permissionManager.refreshAutomationPermission()
                    }

                    Spacer()
                }
            }
        }
    }

    private var listenerColor: Color {
        switch appModel.eventTapManager.status {
        case .running:
            return .green
        case .paused:
            return .orange
        case .blocked:
            return .red
        }
    }

    private var automationColor: Color {
        switch appModel.permissionManager.automationStatus {
        case .granted:
            return .green
        case .missing:
            return .red
        case .unknown:
            return .orange
        }
    }
}
