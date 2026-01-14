import SwiftUI

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.dashboardBody(12))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(color.opacity(0.6), lineWidth: 1)
            )
    }
}
