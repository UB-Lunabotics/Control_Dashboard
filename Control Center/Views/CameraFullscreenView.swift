import SwiftUI

struct CameraFullscreenView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ZStack {
            DashboardTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    StatusPill(text: state.connectionState == .connected ? "Connected" : "Offline", color: state.connectionState == .connected ? DashboardTheme.success : DashboardTheme.danger)
                    StatusPill(text: "Ping \(Int(state.metrics.pingMs)) ms", color: DashboardTheme.accent)
                    StatusPill(text: state.eStopActive ? "E-Stop ACTIVE" : "E-Stop ARMED", color: state.eStopActive ? DashboardTheme.danger : DashboardTheme.warning)
                    StatusPill(text: state.systemPowerOn ? "Power ON" : "Power OFF", color: state.systemPowerOn ? DashboardTheme.success : DashboardTheme.warning)
                    StatusPill(text: state.autonomousOn ? "Auto ON" : "Auto OFF", color: state.autonomousOn ? DashboardTheme.success : DashboardTheme.warning)
                    Spacer()
                    Button("Exit Fullscreen") {
                        state.exitCameraFullscreen()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 20)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(state.cameraConfigs) { camera in
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DashboardTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(DashboardTheme.cardBorder, lineWidth: 1)
                                )
                            VStack(alignment: .leading, spacing: 8) {
                                Text(camera.name)
                                    .font(.dashboardTitle(14))
                                    .foregroundStyle(DashboardTheme.textPrimary)
                                Text(camera.isEnabled ? "Streaming" : "Disabled")
                                    .font(.dashboardBody(11))
                                    .foregroundStyle(DashboardTheme.textSecondary)
                                Spacer()
                                Text("FPS: --")
                                    .font(.dashboardMono(11))
                                    .foregroundStyle(DashboardTheme.textSecondary)
                            }
                            .padding(12)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .overlay(
            KeyEventMonitor { event in
                if event.keyCode == 53 { // Escape
                    state.exitCameraFullscreen()
                }
                if event.charactersIgnoringModifiers?.lowercased() == "f" {
                    state.toggleCameraFullscreen()
                }
            }
            .frame(width: 0, height: 0)
        )
    }
}
