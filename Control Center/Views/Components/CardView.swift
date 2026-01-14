import SwiftUI

struct CardView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.dashboardTitle(16))
                .foregroundStyle(DashboardTheme.textPrimary)
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DashboardTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DashboardTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}
