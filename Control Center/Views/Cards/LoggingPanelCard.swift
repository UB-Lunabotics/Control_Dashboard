import SwiftUI

struct LoggingPanelCard: View {
    @ObservedObject var state: AppState

    var body: some View {
        CardView(title: "Logging Panel") {
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
        }
    }
}
