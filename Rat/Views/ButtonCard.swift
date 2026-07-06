import SwiftUI

struct ButtonCard: View {
    let button: MouseButton
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(button.isDetected ? .green : .secondary)

                Spacer()

                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(isActive ? Color.accentColor : Color(nsColor: .secondaryLabelColor))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(button.title)
                    .font(.headline)

                Text(button.isDetected ? "Detected" : "Waiting")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isActive ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isActive ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .scaleEffect(isActive ? 1.045 : 1)
        .shadow(color: isActive ? Color.accentColor.opacity(0.18) : .clear, radius: 12, y: 4)
        .animation(.spring(response: 0.22, dampingFraction: 0.68), value: isActive)
        .animation(.easeOut(duration: 0.18), value: button.isDetected)
    }

    private var background: some ShapeStyle {
        if isActive {
            return AnyShapeStyle(Color.accentColor.opacity(0.18))
        }

        if button.isDetected {
            return AnyShapeStyle(Color.green.opacity(0.09))
        }

        return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
    }

    private var iconName: String {
        switch button.number {
        case 0:
            return "cursorarrow.click"
        case 1:
            return "contextualmenu.and.cursorarrow"
        case 2:
            return "scroll"
        default:
            return "button.programmable"
        }
    }
}
