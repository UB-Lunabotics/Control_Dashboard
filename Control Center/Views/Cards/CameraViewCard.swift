import SwiftUI

struct CameraViewCard: View {
    @ObservedObject var state: AppState
    @State private var cam1Direction: Double = 0.5
    @State private var cam2Direction: Double = 0.5

    var body: some View {
        CardView(title: "Camera View") {
            GeometryReader { proxy in
                let sectionHeight = (proxy.size.height - 10) / 2
                VStack(spacing: 10) {
                    cameraSection(title: "Camera 1", config: bindingForCamera(index: 0), direction: $cam1Direction)
                        .frame(height: sectionHeight)
                    cameraSection(title: "Camera 2", config: bindingForCamera(index: 1), direction: $cam2Direction)
                        .frame(height: sectionHeight)
                }
            }
        }
    }

    private func cameraSection(title: String, config: Binding<CameraConfig>?, direction: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.dashboardBody(11))
                .foregroundStyle(DashboardTheme.textSecondary)

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DashboardTheme.cardBorder.opacity(0.4), lineWidth: 1)
                Text("\(title) Preview")
                    .font(.dashboardBody(10))
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 8) {
                Toggle("Camera On/Off", isOn: config?.isEnabled ?? .constant(false))
                    .toggleStyle(.switch)
                    .font(.dashboardBody(10))
                LabeledSlider(title: "Direction", value: direction, range: 0...1, step: 0.01)
            }
        }
    }

    private func bindingForCamera(index: Int) -> Binding<CameraConfig>? {
        guard state.cameraConfigs.indices.contains(index) else { return nil }
        return $state.cameraConfigs[index]
    }
}
