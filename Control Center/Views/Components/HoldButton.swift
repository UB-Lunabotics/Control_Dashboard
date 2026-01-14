import SwiftUI

struct HoldButton: View {
    let title: String
    let tint: Color
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        Text(title)
            .font(.dashboardBody(12))
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(tint.opacity(isPressed ? 0.8 : 0.35))
            .foregroundStyle(DashboardTheme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tint.opacity(0.8), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPress()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onRelease()
                    }
            )
    }
}
