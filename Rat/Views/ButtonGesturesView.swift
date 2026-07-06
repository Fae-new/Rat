import SwiftUI

struct ButtonGesturesView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selectedButton = 2

    private var mappableButtons: [Int] {
        appModel.store.displayedButtons
            .map(\.number)
            .filter { $0 >= 2 }
    }

    var body: some View {
        FormPage(title: "Button Gestures", subtitle: subtitle) {
            SettingsCard {
                if mappableButtons.isEmpty {
                    Text("No mappable buttons available.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Button")
                                    .font(.headline)

                                Text(selectedButtonStatus)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Picker(
                                "Button",
                                selection: Binding(
                                    get: { normalizedSelectedButton },
                                    set: { selectedButton = $0 }
                                )
                            ) {
                                ForEach(mappableButtons, id: \.self) { button in
                                    Text(buttonTitle(button)).tag(button)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 260)
                        }

                        Divider()

                        GestureMappingRow(button: normalizedSelectedButton)
                    }
                }
            }
        }
    }

    private var normalizedSelectedButton: Int {
        if mappableButtons.contains(selectedButton) {
            return selectedButton
        }

        return mappableButtons.first ?? 2
    }

    private var subtitle: String {
        if let lastGestureDescription = appModel.eventTapManager.lastGestureDescription {
            return "Last gesture: \(lastGestureDescription)"
        }

        return "Hold a mapped button and drag left, right, up, or down."
    }

    private var selectedButtonStatus: String {
        appModel.store.detectedButtons.contains(normalizedSelectedButton) ? "Detected" : "Not detected yet"
    }

    private func buttonTitle(_ button: Int) -> String {
        let suffix = appModel.store.detectedButtons.contains(button) ? "Detected" : "Not detected"
        return "Button \(button) · \(suffix)"
    }
}
