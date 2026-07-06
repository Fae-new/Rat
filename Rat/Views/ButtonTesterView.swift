import SwiftUI

struct ButtonTesterView: View {
    @EnvironmentObject private var appModel: AppModel

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 14)
    ]

    var body: some View {
        FormPage(title: "Button Tester", subtitle: lastDetectedText) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(appModel.store.displayedButtons) { button in
                    ButtonCard(
                        button: button,
                        isActive: appModel.buttonManager.isActive(button.number)
                    )
                }
            }
        }
    }

    private var lastDetectedText: String {
        if let button = appModel.buttonManager.lastDetectedButton {
            return "Last detected: Button \(button)"
        }
        return "Last detected: None"
    }
}
