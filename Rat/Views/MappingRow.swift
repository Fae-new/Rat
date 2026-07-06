import SwiftUI

struct MappingRow: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var testMessage: String?
    let button: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Button \(button)")
                        .font(.headline)

                    Text(button < 2 ? "Shown in tester only" : "Mappable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker(
                    "Action",
                    selection: Binding(
                        get: { appModel.store.action(for: button) },
                        set: {
                            appModel.store.setAction($0, for: button)
                            testMessage = nil
                        }
                    )
                ) {
                    ForEach(MouseAction.allCases) { action in
                        Text(action.title).tag(action)
                    }
                }
                .labelsHidden()
                .frame(width: 280)
                .disabled(button < 2)

                Button("Test") {
                    runTest()
                }
                .disabled(button < 2 || appModel.store.action(for: button) == .none)
            }

            if let testMessage {
                Text(testMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }

    private func runTest() {
        appModel.refreshPermissions()

        guard appModel.permissionManager.accessibilityGranted else {
            testMessage = "Accessibility is missing. Re-enable Rat in System Settings, then try again."
            return
        }

        let action = appModel.store.action(for: button)
        switch ActionRunner.run(action) {
        case .sent(let backend):
            testMessage = "Ran \(action.title) with \(backend)."
        case .failed(let message):
            testMessage = "System Events failed: \(message)"
        case .noShortcut:
            testMessage = "This action does not have a shortcut yet."
        }
    }
}
