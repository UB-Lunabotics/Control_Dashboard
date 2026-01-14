import SwiftUI

struct TerminalPanelCard: View {
    var body: some View {
        CardView(title: "Terminal from Jetson") {
            SwiftTermContainerView(initialCommand: "")
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(DashboardTheme.cardBorder.opacity(0.4), lineWidth: 1)
                )
        }
    }
}
