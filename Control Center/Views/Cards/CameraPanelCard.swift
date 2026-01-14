import SwiftUI

struct CameraPanelCard: View {
    @ObservedObject var state: AppState

    var body: some View {
        CardView(title: "Camera Panel") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Quad View")
                        .font(.dashboardBody(12))
                        .foregroundStyle(DashboardTheme.textSecondary)
                    Spacer()
                    Button(state.cameraFullscreen ? "Exit Fullscreen" : "Fullscreen") {
                        state.toggleCameraFullscreen()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("f", modifiers: [])
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(camera.name)
                    .font(.dashboardBody(12))
                    .foregroundStyle(DashboardTheme.textPrimary)
                Spacer()
                Toggle("", isOn: $camera.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DashboardTheme.background.opacity(0.7))
                Text(camera.isEnabled ? "Camera Preview" : "Disabled")
                    .font(.dashboardBody(11))
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
            .frame(height: 80)
            TextField("rtsp/http/mjpeg URL", text: $camera.url)
                .textFieldStyle(.roundedBorder)
                .font(.dashboardBody(11))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DashboardTheme.cardBackground.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DashboardTheme.cardBorder.opacity(0.8), lineWidth: 1)
                )
        )
    }
}
