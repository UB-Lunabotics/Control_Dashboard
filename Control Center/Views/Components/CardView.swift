import SwiftUI

struct CardView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.dashboardTitle(14))
                .foregroundStyle(DashboardTheme.textPrimary)
            Divider().background(DashboardTheme.cardBorder.opacity(0.4))
            content
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DashboardTheme.cardBackground.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DashboardTheme.cardBorder.opacity(0.35), lineWidth: 1)
                )
        )
    }
}
