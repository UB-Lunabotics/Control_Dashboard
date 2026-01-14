import SwiftUI

struct LoggingPanelCard: View {
    @ObservedObject var state: AppState

    var body: some View {
        CardView(title: "Logging Panel") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Button("Add Marker") {
                                let marker = "{\"type\":\"marker\",\"ts\":\(Date().timeIntervalSince1970)}"
                                state.logger.appendLine(marker)
                            }
                            Button("Save Snapshot") {
                                state.saveSnapshot()
                            }
                            Button("Save Location") {
                                state.selectSaveLocation()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Toggle(isOn: Binding(
                            get: { state.logger.isRecording },
                            set: { newValue in
                                if newValue != state.logger.isRecording {
                                    state.toggleRecording()
                                }
                            }
                        )) {
                            Text("Start Recording")
                                .font(.dashboardBody(10))
                                .foregroundStyle(DashboardTheme.textPrimary)
                        }
                        .toggleStyle(.switch)

                        Text("Status: \(state.loggerStatus)")
                            .font(.dashboardBody(10))
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Metrics")
                            .font(.dashboardBody(10))
                            .foregroundStyle(DashboardTheme.textSecondary)
                        metricRow("Packets", value: "\(state.metrics.reconnectCount)")
                        metricRow("Last Cmd", value: state.lastCommandSent.isEmpty ? "--" : state.lastCommandSent)
                        metricRow("Telemetry", value: state.metrics.lastTelemetryAt == nil ? "--" : "Live")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricRow(_ title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textSecondary)
            Text(value)
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textPrimary)
                .lineLimit(1)
        }
    }
}
