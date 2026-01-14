import SwiftUI

struct DebugLoggingCard: View {
    @ObservedObject var state: AppState

    var body: some View {
        CardView(title: "Debug + Logging") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Button("Add Marker") {
                        let marker = "{\"type\":\"marker\",\"ts\":\(Date().timeIntervalSince1970)}"
                        state.logger.appendLine(marker)
                    }
                    Button("Save Snapshot") {
                        state.saveSnapshot()
                    }
                    Button("Select Save Location") {
                        state.selectSaveLocation()
                    }
                }
                .buttonStyle(.bordered)

                Toggle(isOn: Binding(
                    get: { state.logger.isRecording },
                    set: { newValue in
                        if newValue != state.logger.isRecording {
                            state.toggleRecording()
                        }
                    }
                )) {
                    Text(state.logger.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.dashboardBody(12))
                        .foregroundStyle(DashboardTheme.textPrimary)
                }
                .toggleStyle(.switch)
                .keyboardShortcut("r", modifiers: [])

                Text("Status: \(state.loggerStatus)")
                    .font(.dashboardBody(11))
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
        }
    }
}
