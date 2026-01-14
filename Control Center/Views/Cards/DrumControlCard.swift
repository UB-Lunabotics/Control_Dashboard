import SwiftUI

struct DrumControlCard: View {
    @ObservedObject var state: AppState

    @State private var liftSpeed: Double = 0.6
    @State private var spinSpeed: Double = 0.6

    var body: some View {
        CardView(title: "Drum Control") {
            VStack(alignment: .leading, spacing: 6) {
                Group {
                    HStack(spacing: 8) {
                        HoldButton(title: "Lift Up", tint: DashboardTheme.success) {
                            state.startDrumHold(lift: liftSpeed, spin: 0)
                        } onRelease: {
                            state.stopDrumHold()
                            state.sendDrum(lift: 0, spin: 0)
                        }
                        HoldButton(title: "Lift Down", tint: DashboardTheme.warning) {
                            state.startDrumHold(lift: -liftSpeed, spin: 0)
                        } onRelease: {
                            state.stopDrumHold()
                            state.sendDrum(lift: 0, spin: 0)
                        }
                    }

                    HStack(spacing: 8) {
                        HoldButton(title: "Spin CW", tint: DashboardTheme.accent) {
                            state.startDrumHold(lift: 0, spin: spinSpeed)
                        } onRelease: {
                            state.stopDrumHold()
                            state.sendDrum(lift: 0, spin: 0)
                        }
                        HoldButton(title: "Spin CCW", tint: DashboardTheme.accent) {
                            state.startDrumHold(lift: 0, spin: -spinSpeed)
                        } onRelease: {
                            state.stopDrumHold()
                            state.sendDrum(lift: 0, spin: 0)
                        }
                    }

                    LabeledSlider(title: "Lift Speed", value: $liftSpeed, range: 0...1, step: 0.01)
                    LabeledSlider(title: "Spin Speed", value: $spinSpeed, range: 0...1, step: 0.01)
                }
                .disabled(state.eStopActive || !state.drumEnabled)
                .opacity(state.eStopActive || !state.drumEnabled ? 0.6 : 1.0)
            }
        }
    }
}
