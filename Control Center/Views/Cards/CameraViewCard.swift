import SwiftUI

struct CameraViewCard: View {
    @ObservedObject var state: AppState
    @State private var cam1Direction: Double = 0.5
    @State private var cam2Direction: Double = 0.5
    @State private var cam1SettingsExpanded = false
    @State private var cam2SettingsExpanded = false

    var body: some View {
        CardView(title: "Camera View") {
            GeometryReader { proxy in
                let sectionHeight = (proxy.size.height - 10) / 2
                VStack(spacing: 10) {
                    cameraSection(
                        title: "Camera 1",
                        config: bindingForCamera(index: 0),
                        direction: $cam1Direction,
                        showSettings: $cam1SettingsExpanded
                    )
                        .frame(height: sectionHeight)
                    cameraSection(
                        title: "Camera 2",
                        config: bindingForCamera(index: 1),
                        direction: $cam2Direction,
                        showSettings: $cam2SettingsExpanded
                    )
                        .frame(height: sectionHeight)
                }
            }
        }
    }

    private func cameraSection(title: String, config: Binding<CameraConfig>?, direction: Binding<Double>, showSettings: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.dashboardBody(11))
                    .foregroundStyle(DashboardTheme.textSecondary)
                Spacer()
                Button(showSettings.wrappedValue ? "Hide Settings" : "Stream Settings") {
                    showSettings.wrappedValue.toggle()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DashboardTheme.cardBorder.opacity(0.4), lineWidth: 1)
                MJPEGStreamView(
                    urlString: config?.wrappedValue.url ?? "",
                    isEnabled: config?.wrappedValue.isEnabled ?? false
                )
            }
            .frame(maxHeight: .infinity)

            if showSettings.wrappedValue {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("Stream URL", text: Binding(
                            get: { config?.wrappedValue.url ?? "" },
                            set: { config?.wrappedValue.url = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)

                        Button((config?.wrappedValue.isEnabled ?? false) ? "Stop" : "Stream") {
                            if config != nil {
                                config?.wrappedValue.isEnabled.toggle()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    HStack(spacing: 8) {
                        Text("Only MJPEG supported for now")
                            .font(.dashboardBody(9))
                            .foregroundStyle(DashboardTheme.textSecondary)

                    TextField("User", text: Binding(
                        get: { config?.wrappedValue.username ?? "" },
                        set: { config?.wrappedValue.username = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)

                    SecureField("Password", text: Binding(
                        get: { config?.wrappedValue.password ?? "" },
                        set: { config?.wrappedValue.password = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                }

                    LabeledSlider(title: "Latency", value: Binding(
                        get: { config?.wrappedValue.latencyMs ?? 200 },
                        set: { newValue in config?.wrappedValue.latencyMs = newValue }
                    ), range: 50...1000, step: 10)
                }
            }

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
