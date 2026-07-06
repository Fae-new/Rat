import SwiftUI

struct GestureMappingRow: View {
    @EnvironmentObject private var appModel: AppModel
    let button: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 10) {
                ForEach(GestureDirection.allCases) { direction in
                    GridRow {
                        Text(direction.title)
                            .font(.subheadline.weight(.medium))
                            .frame(width: 90, alignment: .leading)

                        Picker(
                            direction.title,
                            selection: Binding(
                                get: { appModel.store.gestureAction(for: button, direction: direction) },
                                set: { appModel.store.setGestureAction($0, for: button, direction: direction) }
                            )
                        ) {
                            ForEach(MouseAction.allCases) { action in
                                Text(action.title).tag(action)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 320)
                    }
                }
            }
        }
    }
}
