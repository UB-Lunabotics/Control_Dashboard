import SwiftUI

struct CameraPanelCard: View {
    @ObservedObject var state: AppState

    var body: some View {
        CardView(title: "Camera Panel") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Quad View")
                        .font(.dashboardBody(11))
                        .foregroundStyle(DashboardTheme.textSecondary)
                    Spacer()
                    Button(state.cameraFullscreen ? "Exit Fullscreen" : "Fullscreen") {
                        state.toggleCameraFullscreen()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("f", modifiers: [])
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach($state.cameraConfigs) { $camera in
                        CameraTileView(camera: $camera)
                    }
                }
            }
        }
    }
}

struct CameraTileView: View {
    @Binding var camera: CameraConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(camera.name)
                    .font(.dashboardBody(11))
                    .foregroundStyle(DashboardTheme.textPrimary)
                Spacer()
                Toggle("", isOn: $camera.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DashboardTheme.cardBorder.opacity(0.5), lineWidth: 1)
                Text(camera.isEnabled ? "Camera Preview" : "Disabled")
                    .font(.dashboardBody(10))
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
            .frame(height: 60)
            TextField("rtsp/http/mjpeg URL", text: $camera.url)
                .textFieldStyle(.roundedBorder)
                .font(.dashboardBody(10))
                .controlSize(.mini)
        }
        .padding(.vertical, 4)
        .frame(minHeight: 120)
    }
}
