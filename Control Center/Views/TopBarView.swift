import SwiftUI

struct TopBarView: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WebSocket Target")
                    .font(.dashboardBody(12))
                    .foregroundStyle(DashboardTheme.textSecondary)
                HStack(spacing: 8) {
                    TextField("Host", text: $state.host)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                    TextField("Port", value: $state.port, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                    Button(state.connectionState == .connected ? "Disconnect" : "Connect") {
                        if state.connectionState == .connected {
                            state.disconnect()
                        } else {
                            state.connect()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    StatusPill(text: connectionLabel, color: connectionColor)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Link Metrics")
                    .font(.dashboardBody(12))
                    .foregroundStyle(DashboardTheme.textSecondary)
                HStack(spacing: 10) {
                    metricLabel("Ping", value: "\(Int(state.metrics.pingMs)) ms")
                    metricLabel("Loss", value: String(format: "%.1f%%", state.metrics.packetLossPercent))
                    metricLabel("Reconnects", value: "\(state.metrics.reconnectCount)")
                    metricLabel("Last", value: lastTelemetryLabel)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Modes")
                    .font(.dashboardBody(12))
                    .foregroundStyle(DashboardTheme.textSecondary)
                HStack(spacing: 8) {
                    StatusPill(text: state.systemPowerOn ? "Power ON" : "Power OFF", color: state.systemPowerOn ? DashboardTheme.success : DashboardTheme.warning)
                    StatusPill(text: state.autonomousOn ? "Auto ON" : "Auto OFF", color: state.autonomousOn ? DashboardTheme.success : DashboardTheme.warning)
                    StatusPill(text: state.eStopActive ? "E-Stop ACTIVE" : "E-Stop ARMED", color: state.eStopActive ? DashboardTheme.danger : DashboardTheme.warning)
                    StatusPill(text: state.controllerEnabled ? "Controller ON" : "Controller OFF", color: state.controllerEnabled ? DashboardTheme.success : DashboardTheme.warning)
                    StatusPill(text: state.driveEnabled ? "Drive ON" : "Drive OFF", color: state.driveEnabled ? DashboardTheme.success : DashboardTheme.warning)
                    StatusPill(text: state.drumEnabled ? "Drum ON" : "Drum OFF", color: state.drumEnabled ? DashboardTheme.success : DashboardTheme.warning)
                }
                HStack(spacing: 12) {
                    Toggle("System Power", isOn: systemPowerBinding)
                        .toggleStyle(.switch)
                        .font(.dashboardBody(11))
                    Toggle("Autonomous", isOn: autonomousBinding)
                        .toggleStyle(.switch)
                        .font(.dashboardBody(11))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Button(state.eStopActive ? "Reset E-Stop" : "E-STOP") {
                    if state.eStopActive {
                        state.resetEStop()
                    } else {
                        state.activateEStop()
                    }
                }
                .buttonStyle(.bordered)
                .tint(DashboardTheme.danger)
                .font(.dashboardTitle(12))
                .frame(minWidth: 120, minHeight: 34)
                .keyboardShortcut("e", modifiers: [])

                Toggle(isOn: $state.isDarkTheme) {
                    Text(state.isDarkTheme ? "Dark" : "Light")
                        .font(.dashboardBody(12))
                        .foregroundStyle(DashboardTheme.textPrimary)
                }
                .toggleStyle(.switch)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle().fill(DashboardTheme.cardBackground)
        )
    }

    private var connectionLabel: String {
        switch state.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        }
    }

    private var connectionColor: Color {
        switch state.connectionState {
        case .connected:
            return DashboardTheme.success
        case .connecting:
            return DashboardTheme.warning
        case .disconnected:
            return DashboardTheme.danger
        }
    }

    private var lastTelemetryLabel: String {
        guard let last = state.metrics.lastTelemetryAt else { return "--" }
        let seconds = Int(Date().timeIntervalSince(last))
        return "\(seconds)s"
    }

    private func metricLabel(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textSecondary)
            Text(value)
                .font(.dashboardMono(11))
                .foregroundStyle(DashboardTheme.textPrimary)
        }
    }

    private var systemPowerBinding: Binding<Bool> {
        Binding(
            get: { state.systemPowerOn },
            set: { value in
                state.setMode(systemPower: value, autonomous: state.autonomousOn)
            }
        )
    }

    private var autonomousBinding: Binding<Bool> {
        Binding(
            get: { state.autonomousOn },
            set: { value in
                state.setMode(systemPower: state.systemPowerOn, autonomous: value)
            }
        )
    }
}
