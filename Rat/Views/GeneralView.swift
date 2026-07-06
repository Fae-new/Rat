import SwiftUI

struct GeneralView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        FormPage(title: "General", subtitle: "Rat keeps listening from the menu bar while this window is closed.") {
            SettingsCard {
                StatusLine(
                    title: "Listener",
                    value: appModel.eventTapManager.status.rawValue,
                    color: color(for: appModel.eventTapManager.status)
                )

                Divider()

                HStack {
                    Button("Pause Listener") {
                        appModel.eventTapManager.pause()
                    }
                    .disabled(appModel.eventTapManager.status != .running)

                    Button("Resume Listener") {
                        appModel.eventTapManager.resume()
                    }
                    .disabled(appModel.eventTapManager.status == .running)

                    Spacer()
                }
            }

            SettingsCard {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { appModel.launchAtLoginManager.isEnabled },
                        set: { appModel.launchAtLoginManager.setEnabled($0) }
                    )
                )

                if let errorMessage = appModel.launchAtLoginManager.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func color(for status: ListenerStatus) -> Color {
        switch status {
        case .running:
            return .green
        case .paused:
            return .orange
        case .blocked:
            return .red
        }
    }
}
