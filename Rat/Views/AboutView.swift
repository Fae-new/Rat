import SwiftUI

struct AboutView: View {
    var body: some View {
        FormPage(title: "About", subtitle: "Rat maps extra mouse buttons to macOS Spaces navigation.") {
            SettingsCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Rat")
                        .font(.title2.bold())

                    Text("Version 1.0")
                        .foregroundStyle(.secondary)

                    Text("Mappings work while the menu bar app is running. The settings window can stay closed.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MVP Scope")
                        .font(.headline)

                    Text("No daemon, gestures, per-app profiles, custom shortcut recorder, cloud sync, analytics, update checker, or installer.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
