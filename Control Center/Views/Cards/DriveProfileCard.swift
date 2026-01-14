import SwiftUI

struct DriveProfileCard: View {
    @ObservedObject var state: AppState

    var body: some View {
        CardView(title: "Drive Profile") {
            VStack(alignment: .leading, spacing: 6) {
                Picker("Profile", selection: profileSelection) {
                    ForEach(state.driveProfiles) { profile in
                        Text(profile.name).tag(profile.name)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.mini)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    LabeledSlider(title: "Linear Scale", value: bindingForValue(\.linearScale), range: 0.1...1.2, step: 0.01)
                    LabeledSlider(title: "Angular Scale", value: bindingForValue(\.angularScale), range: 0.1...1.2, step: 0.01)
                    LabeledSlider(title: "Expo Curve", value: bindingForValue(\.expo), range: 0...1, step: 0.01)
                    LabeledSlider(title: "Traction", value: bindingForValue(\.traction), range: 0...1, step: 0.01)
                    LabeledSlider(title: "Torque", value: bindingForValue(\.torque), range: 0...1, step: 0.01)
                }

                Text("Profile scales apply to controller + on-screen commands.")
                    .font(.dashboardBody(10))
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
        }
    }

    private var profileSelection: Binding<String> {
        Binding(
            get: { state.selectedDriveProfile.name },
            set: { name in
                if let profile = state.driveProfiles.first(where: { $0.name == name }) {
                    state.updateDriveProfile(profile)
                }
            }
        )
    }

    private func bindingForValue(_ keyPath: WritableKeyPath<DriveProfile, Double>) -> Binding<Double> {
        Binding(
            get: {
                state.selectedDriveProfile[keyPath: keyPath]
            },
            set: { value in
                state.updateSelectedProfileValue(keyPath: keyPath, value: value)
            }
        )
    }
}
