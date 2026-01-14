import SwiftUI

struct URDFSimulatorCard: View {
    var body: some View {
        CardView(title: "Rover Sim (URDF)") {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DashboardTheme.background.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DashboardTheme.cardBorder, lineWidth: 1)
                    )
                VStack(spacing: 6) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 26))
                        .foregroundStyle(DashboardTheme.accent)
                    Text("URDF/SceneKit placeholder")
                        .font(.dashboardBody(12))
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
