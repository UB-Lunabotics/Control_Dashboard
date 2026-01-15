import SwiftUI

struct URDFMeshAxisControlsView: View {
    @Binding var selectedMesh: String
    let meshNames: [String]
    @Binding var flipX: Bool
    @Binding var flipY: Bool
    @Binding var flipZ: Bool
    @Binding var swapYZ: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Per-Mesh Axis Tuning")
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textSecondary)

            HStack(spacing: 8) {
                Picker("Mesh", selection: $selectedMesh) {
                    Text("Select Mesh").tag("")
                    ForEach(meshNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .labelsHidden()
                .controlSize(.mini)
                .frame(width: 180)

                Toggle("Flip X", isOn: $flipX).toggleStyle(.switch)
                Toggle("Flip Y", isOn: $flipY).toggleStyle(.switch)
                Toggle("Flip Z", isOn: $flipZ).toggleStyle(.switch)
                Toggle("Swap YZ", isOn: $swapYZ).toggleStyle(.switch)
            }
            .font(.dashboardBody(10))
        }
    }
}
