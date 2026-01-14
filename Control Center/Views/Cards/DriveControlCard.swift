import SwiftUI

struct DriveControlCard: View {
    @ObservedObject var state: AppState

    @State private var forwardSpeed: Double = 0.6
    @State private var reverseSpeed: Double = 0.6
    @State private var leftSpeed: Double = 0.5
    @State private var rightSpeed: Double = 0.5
    @State private var vCommand: Double = 0.0
    @State private var wCommand: Double = 0.0

    var body: some View {
        CardView(title: "Rover Drive Control") {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    HStack(spacing: 10) {
                        HoldButton(title: "Forward", tint: DashboardTheme.success) {
                            state.startDriveHold(v: forwardSpeed, w: 0)
                        } onRelease: {
                            state.stopDriveHold()
                            state.sendDrive(v: 0, w: 0)
                        }
                        HoldButton(title: "Reverse", tint: DashboardTheme.warning) {
                            state.startDriveHold(v: -reverseSpeed, w: 0)
                        } onRelease: {
                            state.stopDriveHold()
                            state.sendDrive(v: 0, w: 0)
                        }
                    }
                    HStack(spacing: 10) {
                        HoldButton(title: "Left", tint: DashboardTheme.accent) {
                            state.startDriveHold(v: 0, w: leftSpeed)
                        } onRelease: {
                            state.stopDriveHold()
                            state.sendDrive(v: 0, w: 0)
                        }
                        HoldButton(title: "Right", tint: DashboardTheme.accent) {
                            state.startDriveHold(v: 0, w: -rightSpeed)
                        } onRelease: {
                            state.stopDriveHold()
                            state.sendDrive(v: 0, w: 0)
                        }
                    }

                    LabeledSlider(title: "Forward Speed", value: $forwardSpeed, range: 0...1, step: 0.01)
                    LabeledSlider(title: "Reverse Speed", value: $reverseSpeed, range: 0...1, step: 0.01)
                    LabeledSlider(title: "Left Speed", value: $leftSpeed, range: 0...1, step: 0.01)
                    LabeledSlider(title: "Right Speed", value: $rightSpeed, range: 0...1, step: 0.01)

                    Divider().background(DashboardTheme.cardBorder)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Send v / w")
                            .font(.dashboardBody(12))
                            .foregroundStyle(DashboardTheme.textSecondary)
                        LabeledSlider(title: "Linear v", value: $vCommand, range: -1...1, step: 0.01)
                        LabeledSlider(title: "Angular w", value: $wCommand, range: -1...1, step: 0.01)
                        Button("Send Once") {
                            state.sendDrive(v: vCommand, w: wCommand)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .disabled(state.eStopActive || !state.driveEnabled)
                .opacity(state.eStopActive || !state.driveEnabled ? 0.6 : 1.0)

                Toggle("Enable Drive", isOn: $state.driveEnabled)
                    .toggleStyle(.switch)
                    .disabled(state.eStopActive)
            }
        }
    }
}
