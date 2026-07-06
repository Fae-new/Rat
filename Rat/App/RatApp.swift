import SwiftUI

@main
struct RatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = SharedAppState.model

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appModel)
                .frame(minWidth: 900, minHeight: 620)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    appModel.recheckPermissionsAndResumeIfPossible()
                }
        }
    }
}
