import SwiftUI

struct URDFAxisControlsView: View {
    @Binding var rotX: Double
    @Binding var rotY: Double
    @Binding var rotZ: Double
    @Binding var flipX: Bool
    @Binding var flipY: Bool
    @Binding var flipZ: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Axis / Frame Tuning")
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textSecondary)

            HStack(spacing: 8) {
                axisButton("X -90") { rotX = -90 }
                axisButton("X +90") { rotX = 90 }
                axisButton("Y -90") { rotY = -90 }
                axisButton("Y +90") { rotY = 90 }
                axisButton("Z -90") { rotZ = -90 }
                axisButton("Z +90") { rotZ = 90 }
            }

            HStack(spacing: 8) {
                Toggle("Flip X", isOn: $flipX).toggleStyle(.switch)
                Toggle("Flip Y", isOn: $flipY).toggleStyle(.switch)
                Toggle("Flip Z", isOn: $flipZ).toggleStyle(.switch)
                axisButton("Reset", action: reset)
            }
            .font(.dashboardBody(10))
        }
    }

    private func axisButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.mini)
    }

    private func reset() {
        rotX = -90
        rotY = 0
        rotZ = 0
        flipX = false
        flipY = false
        flipZ = false
    }
}
