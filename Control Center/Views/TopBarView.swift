import SwiftUI
import AppKit

struct TopBarView: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                Group {
//                    if NSImage(named: "UBLogo") != nil {
                        Image("UBLogo")
                            .resizable()
                            .scaledToFit()
//                    } else {
//                        Image(systemName: "shield.lefthalf.filled")
//                            .resizable()
//                            .scaledToFit()
//                            .foregroundStyle(DashboardTheme.accent)
//                    }
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("UB Lunabotics")
                        .font(.dashboardTitle(18))
                        .foregroundStyle(DashboardTheme.textPrimary)
                    Text("Rover Control Dashboard")
                        .font(.dashboardBody(11))
                        .foregroundStyle(DashboardTheme.textSecondary)
                }
            }

            Spacer(minLength: 8)

            topBarSection(title: "IP Settings") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        TextField("Host", text: $state.host)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.small)
                            .frame(width: 140)
                        TextField("Port", value: $state.port, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.small)
                            .frame(width: 60)
                        Button(state.connectionState == .connected ? "Disconnect" : "Connect") {
                            if state.connectionState == .connected {
                                state.disconnect()
                            } else {
                                state.connect()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    Button(state.showConnectionLog ? "Hide Log" : "Show Log") {
                        state.showConnectionLog.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                topBarSection(title: "Indicators") {
                    HStack(spacing: 6) {
                        StatusPill(text: state.systemPowerOn ? "Power ON" : "Power OFF", color: state.systemPowerOn ? DashboardTheme.success : DashboardTheme.warning)
                        StatusPill(text: state.autonomousOn ? "Auto ON" : "Auto OFF", color: state.autonomousOn ? DashboardTheme.success : DashboardTheme.warning)
                        StatusPill(text: state.eStopActive ? "E-Stop ACTIVE" : "E-Stop ARMED", color: state.eStopActive ? DashboardTheme.danger : DashboardTheme.warning)
                        StatusPill(text: state.controllerEnabled ? "Controller ON" : "Controller OFF", color: state.controllerEnabled ? DashboardTheme.success : DashboardTheme.warning)
                        StatusPill(text: state.driveEnabled ? "Drive ON" : "Drive OFF", color: state.driveEnabled ? DashboardTheme.success : DashboardTheme.warning)
                        StatusPill(text: state.drumEnabled ? "Drum ON" : "Drum OFF", color: state.drumEnabled ? DashboardTheme.success : DashboardTheme.warning)
                    }
                }

                topBarSection(title: "Metrics") {
                    HStack(spacing: 8) {
                        StatusPill(text: connectionLabel, color: connectionColor)
                        metricLabel("Ping", value: "\(Int(state.metrics.pingMs)) ms")
                        metricLabel("Loss", value: String(format: "%.1f%%", state.metrics.packetLossPercent))
                        metricLabel("Last", value: lastTelemetryLabel)
                    }
                    .frame(width: 240, alignment: .leading)
                }

                topBarSection(title: "System / E-Stop / Auto") {
                    HStack(spacing: 8) {
                        Toggle("Power", isOn: systemPowerBinding)
                            .toggleStyle(.switch)
                        Toggle("Auto", isOn: autonomousBinding)
                            .toggleStyle(.switch)
                        Button(state.eStopActive ? "E-STOP ACTIVE" : "E-STOP") {
                            if state.eStopActive {
                                state.resetEStop()
                            } else {
                                state.activateEStop()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DashboardTheme.danger)
                        .controlSize(.regular)          // normal macOS size

                        Button("Reset") {
                            state.sendStopAll()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .font(.dashboardBody(10))
                    .foregroundStyle(DashboardTheme.textPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private func topBarSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textSecondary)
            content()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DashboardTheme.cardBackground.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DashboardTheme.cardBorder.opacity(0.3), lineWidth: 1)
                )
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
                .font(.dashboardBody(9))
                .foregroundStyle(DashboardTheme.textSecondary)
            Text(value)
                .font(.dashboardMono(10))
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
