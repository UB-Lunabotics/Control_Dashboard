import SwiftUI

struct TerminalPanelCard: View {
    var body: some View {
        CardView(title: "Terminal from Jetson") {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DashboardTheme.cardBorder.opacity(0.4), lineWidth: 1)
                Text("Terminal output placeholder")
                    .font(.dashboardBody(10))
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
        }
    }
}
