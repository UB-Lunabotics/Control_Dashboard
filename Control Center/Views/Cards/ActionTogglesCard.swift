import SwiftUI

struct ActionTogglesCard: View {
    @ObservedObject var state: AppState

    var body: some View {
        CardView(title: "Action Toggles") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("System Power", isOn: systemPowerBinding)
                    .toggleStyle(.switch)
                Toggle("Autonomous", isOn: autonomousBinding)
                    .toggleStyle(.switch)
                Toggle("Controller Enabled", isOn: controllerBinding)
                    .toggleStyle(.switch)
                    .disabled(state.eStopActive)
                Toggle("Drive Enabled", isOn: $state.driveEnabled)
                    .toggleStyle(.switch)
                    .disabled(state.eStopActive)
                Toggle("Drum Enabled", isOn: $state.drumEnabled)
                    .toggleStyle(.switch)
                    .disabled(state.eStopActive)
            }
            .font(.dashboardBody(11))
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

    private var controllerBinding: Binding<Bool> {
        Binding(
            get: { state.controllerEnabled },
            set: { value in
                state.controllerEnabled = value
            }
        )
    }
}
