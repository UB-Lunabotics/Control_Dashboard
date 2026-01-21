import SwiftUI

struct MotionControlCard: View {
    @ObservedObject var state: AppState

    @State private var activeDriveProfile: String? = nil
    @State private var activeLeverProfile: String? = nil
    @State private var activeDrumProfile: String? = nil

    var body: some View {
        CardView(title: "Motion Control") {
            VStack(alignment: .leading, spacing: 6) {
                sectionHeader("Drive train", pills: [
                    (state.driveEnabled ? "Drive ON" : "Drive OFF", state.driveEnabled ? DashboardTheme.success : DashboardTheme.warning),
                    (state.controllerEnabled ? "Controller ON" : "Controller OFF", state.controllerEnabled ? DashboardTheme.success : DashboardTheme.warning)
                ])
                drivePad
                if let activeDriveProfile {
                    DriveProfileSettingsView(state: state, profileName: activeDriveProfile)
                }

                sectionHeader("Drum lever", pills: [
                    (state.drumEnabled ? "Lever ON" : "Lever OFF", state.drumEnabled ? DashboardTheme.success : DashboardTheme.warning),
                    (state.eStopActive ? "E-Stop" : "Safe", state.eStopActive ? DashboardTheme.danger : DashboardTheme.success)
                ])
                leverButtons

                sectionHeader("Drum Control", pills: [
                    (state.drumEnabled ? "Drum ON" : "Drum OFF", state.drumEnabled ? DashboardTheme.success : DashboardTheme.warning),
                    (state.eStopActive ? "E-Stop" : "Safe", state.eStopActive ? DashboardTheme.danger : DashboardTheme.success)
                ])
                drumButtons
            }
        }
    }

    private func sectionHeader(_ title: String, pills: [(String, Color)]) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.dashboardBody(11))
                .foregroundStyle(DashboardTheme.textSecondary)
            Spacer()
            ForEach(pills, id: \.0) { item in
                StatusPill(text: item.0, color: item.1)
                    .scaleEffect(0.85)
            }
        }
    }

    private var drivePad: some View {
        HStack(spacing: 6) {
            HoldButton(title: "Forward", tint: DashboardTheme.success) {
                state.startDriveHold(v: 0.6, w: 0)
            } onRelease: {
                state.stopDriveHold()
                state.sendDrive(v: 0, w: 0)
            }
            HoldButton(title: "Left", tint: DashboardTheme.accent) {
                state.startDriveHold(v: 0, w: 0.5)
            } onRelease: {
                state.stopDriveHold()
                state.sendDrive(v: 0, w: 0)
            }
            HoldButton(title: "Right", tint: DashboardTheme.accent) {
                state.startDriveHold(v: 0, w: -0.5)
            } onRelease: {
                state.stopDriveHold()
                state.sendDrive(v: 0, w: 0)
            }
            HoldButton(title: "Reverse", tint: DashboardTheme.danger) {
                state.startDriveHold(v: -0.6, w: 0)
            } onRelease: {
                state.stopDriveHold()
                state.sendDrive(v: 0, w: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var leverButtons: some View {
        HStack(spacing: 6) {
            HoldButton(title: "Upper", tint: DashboardTheme.success) {
                state.startDrumHold(lift: 0.6, spin: 0)
            } onRelease: {
                state.stopDrumHold()
                state.sendDrum(lift: 0, spin: 0)
            }
            HoldButton(title: "Lower", tint: DashboardTheme.warning) {
                state.startDrumHold(lift: -0.6, spin: 0)
            } onRelease: {
                state.stopDrumHold()
                state.sendDrum(lift: 0, spin: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var drumButtons: some View {
        HStack(spacing: 6) {
            HoldButton(title: "Dig (Forward)", tint: DashboardTheme.accent) {
                state.startDrumHold(lift: 0, spin: 0.6)
            } onRelease: {
                state.stopDrumHold()
                state.sendDrum(lift: 0, spin: 0)
            }
            HoldButton(title: "Dump (Reverse)", tint: DashboardTheme.warning) {
                state.startDrumHold(lift: 0, spin: -0.6)
            } onRelease: {
                state.stopDrumHold()
                state.sendDrum(lift: 0, spin: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DriveProfileSettingsView: View {
    @ObservedObject var state: AppState
    let profileName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(profileName) Settings")
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textSecondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                LabeledSlider(title: "Linear", value: bindingForValue(\.linearScale), range: 0.1...1.2, step: 0.01)
                LabeledSlider(title: "Angular", value: bindingForValue(\.angularScale), range: 0.1...1.2, step: 0.01)
                LabeledSlider(title: "Expo", value: bindingForValue(\.expo), range: 0...1, step: 0.01)
                LabeledSlider(title: "Traction", value: bindingForValue(\.traction), range: 0...1, step: 0.01)
                LabeledSlider(title: "Torque", value: bindingForValue(\.torque), range: 0...1, step: 0.01)
            }
        }
    }

    private func bindingForValue(_ keyPath: WritableKeyPath<DriveProfile, Double>) -> Binding<Double> {
        Binding(
            get: {
                guard let profile = state.driveProfiles.first(where: { $0.name == profileName }) else {
                    return state.selectedDriveProfile[keyPath: keyPath]
                }
                return profile[keyPath: keyPath]
            },
            set: { value in
                if let profile = state.driveProfiles.first(where: { $0.name == profileName }) {
                    state.updateDriveProfile(profile)
                    state.updateSelectedProfileValue(keyPath: keyPath, value: value)
                }
            }
        )
    }
}
