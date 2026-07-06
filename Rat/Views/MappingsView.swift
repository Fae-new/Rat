import SwiftUI

struct MappingsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        FormPage(title: "Mappings", subtitle: "Extra mouse buttons can run desktop navigation shortcuts.") {
            SettingsCard {
                if appModel.store.detectedButtonNumbers.isEmpty {
                    Text("No detected buttons yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 0) {
                        ForEach(appModel.store.detectedButtonNumbers, id: \.self) { button in
                            MappingRow(button: button)

                            if button != appModel.store.detectedButtonNumbers.last {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
}
