import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
        } detail: {
            Group {
                switch selection ?? .general {
                case .general:
                    GeneralView()
                case .buttonTester:
                    ButtonTesterView()
                case .mappings:
                    MappingsView()
                case .buttonGestures:
                    ButtonGesturesView()
                case .permissions:
                    PermissionsView()
                case .about:
                    AboutView()
                }
            }
            .environmentObject(appModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case buttonTester
    case mappings
    case buttonGestures
    case permissions
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .buttonTester:
            return "Button Tester"
        case .mappings:
            return "Mappings"
        case .buttonGestures:
            return "Button Gestures"
        case .permissions:
            return "Permissions"
        case .about:
            return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            return "gearshape"
        case .buttonTester:
            return "computermouse"
        case .mappings:
            return "arrow.left.arrow.right"
        case .buttonGestures:
            return "arrow.up.left.and.arrow.down.right"
        case .permissions:
            return "lock.shield"
        case .about:
            return "info.circle"
        }
    }
}
