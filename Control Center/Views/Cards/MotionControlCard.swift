import SwiftUI

struct MotionControlCard: View {
    @ObservedObject var state: AppState

    @State private var activeDriveProfile: String? = nil
    @State private var activeLeverProfile: String? = nil
    @State private var activeDrumProfile: String? = nil

    private let leverProfiles = ["Lift Soft", "Lift Normal", "Lift Aggressive"]
    private let drumProfiles = ["Dig", "Dump", "Balance"]

    var body: some View {
        CardView(title: "Motion Control") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    StatusPill(text: state.driveEnabled ? "Drive ON" : "Drive OFF", color: state.driveEnabled ? DashboardTheme.success : DashboardTheme.warning)
                    StatusPill(text: state.drumEnabled ? "Drum ON" : "Drum OFF", color: state.drumEnabled ? DashboardTheme.success : DashboardTheme.warning)
                    StatusPill(text: state.controllerEnabled ? "Controller ON" : "Controller OFF", color: state.controllerEnabled ? DashboardTheme.success : DashboardTheme.warning)
                    StatusPill(text: state.eStopActive ? "E-Stop ACTIVE" : "E-Stop ARMED", color: state.eStopActive ? DashboardTheme.danger : DashboardTheme.warning)
                }

                sectionHeader("Drive train")
                HStack(spacing: 8) {
                    profileList(title: "Drive Profiles", profiles: state.driveProfiles.map { $0.name }, active: $activeDriveProfile)
                    drivePad
                }
                if let activeDriveProfile {
                    DriveProfileSettingsView(state: state, profileName: activeDriveProfile)
                }

                sectionHeader("Drum lever")
                HStack(spacing: 8) {
                    profileList(title: "Lever Profiles", profiles: leverProfiles, active: $activeLeverProfile)
                    leverButtons
                }

                sectionHeader("Drum Control")
                HStack(spacing: 8) {
                    profileList(title: "Drum Profiles", profiles: drumProfiles, active: $activeDrumProfile)
                    drumButtons
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.dashboardBody(11))
            .foregroundStyle(DashboardTheme.textSecondary)
    }

    private func profileList(title: String, profiles: [String], active: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textSecondary)
            ForEach(profiles, id: \.self) { name in
                HStack(spacing: 6) {
                    Button(name) {
                        if title == "Drive Profiles", let profile = state.driveProfiles.first(where: { $0.name == name }) {
                            state.updateDriveProfile(profile)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)

                    Button(action: {
                        active.wrappedValue = (active.wrappedValue == name) ? nil : name
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var drivePad: some View {
        VStack(spacing: 6) {
            HoldButton(title: "Forward", tint: DashboardTheme.success) {
                state.startDriveHold(v: 0.6, w: 0)
            } onRelease: {
                state.stopDriveHold()
                state.sendDrive(v: 0, w: 0)
            }
            HStack(spacing: 6) {
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
            }
            HoldButton(title: "Reverse", tint: DashboardTheme.warning) {
                state.startDriveHold(v: -0.6, w: 0)
            } onRelease: {
                state.stopDriveHold()
                state.sendDrive(v: 0, w: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var leverButtons: some View {
        VStack(spacing: 6) {
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
        VStack(spacing: 6) {
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
