import SwiftUI

struct ControllerVisualizationCard: View {
    @ObservedObject var state: AppState
    @ObservedObject private var gamepad: GamepadManager

    @State private var showMapping: Bool = false
    @State private var mapping: [String: String] = [
        "Drive Forward": "Y",
        "Drive Reverse": "A",
        "Turn Left": "X",
        "Turn Right": "B",
        "Drum Up": "LT",
        "Drum Down": "RT",
        "Aux +": "+",
        "Aux -": "-"
    ]

    private let mappingButtons = ["A", "B", "X", "Y", "LT", "RT", "+", "-"]

    init(state: AppState) {
        self.state = state
        self.gamepad = state.gamepad
    }

    var body: some View {
        CardView(title: "Controller Visualization") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Current controller binding")
                        .font(.dashboardBody(10))
                        .foregroundStyle(DashboardTheme.textSecondary)
                    Spacer()
                    Button(action: { showMapping.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Settings")
                        }
                        .font(.dashboardBody(10))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }

                HStack(alignment: .center, spacing: 16) {
                    ControllerButtonsView(state: gamepad.state)
                        .frame(width: 180, height: 120)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DashboardTheme.cardBorder.opacity(0.5), lineWidth: 1)
                        Text("Binding: Standard")
                            .font(.dashboardBody(10))
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                    .frame(width: 120, height: 80)
                }

                if showMapping {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Button Mapping")
                            .font(.dashboardBody(10))
                            .foregroundStyle(DashboardTheme.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(mapping.keys.sorted(), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .font(.dashboardBody(10))
                                        .foregroundStyle(DashboardTheme.textPrimary)
                                    Spacer()
                                    Picker("", selection: Binding(
                                        get: { mapping[key] ?? "A" },
                                        set: { mapping[key] = $0 }
                                    )) {
                                        ForEach(mappingButtons, id: \.self) { option in
                                            Text(option).tag(option)
                                        }
                                    }
                                    .labelsHidden()
                                    .controlSize(.mini)
                                    .frame(width: 50)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ControllerButtonsView: View {
    let state: GamepadState

    var body: some View {
        ZStack {
            stickCircle(x: state.leftStickX, y: state.leftStickY)
                .position(x: 40, y: 55)
            stickCircle(x: state.rightStickX, y: state.rightStickY)
                .position(x: 95, y: 55)

            triggerBar(label: "LT", value: state.leftTrigger)
                .position(x: 120, y: 18)
            triggerBar(label: "RT", value: state.rightTrigger)
                .position(x: 150, y: 18)

            buttonCircle("Y", isActive: state.buttonYPressed)
                .position(x: 135, y: 52)
            buttonCircle("X", isActive: state.buttonXPressed)
                .position(x: 118, y: 64)
            buttonCircle("B", isActive: state.buttonBPressed)
                .position(x: 150, y: 64)
            buttonCircle("A", isActive: state.buttonAPressed)
                .position(x: 135, y: 78)

            buttonCapsule("+", isActive: state.buttonPlusPressed)
                .position(x: 130, y: 100)
            buttonCapsule("-", isActive: state.buttonMinusPressed)
                .position(x: 150, y: 100)
        }
    }

    private func stickCircle(x: Double, y: Double) -> some View {
        ZStack {
            Circle()
                .stroke(DashboardTheme.cardBorder.opacity(0.6), lineWidth: 1)
            Circle()
                .fill(DashboardTheme.accent)
                .frame(width: 6, height: 6)
                .offset(x: CGFloat(x) * 10, y: CGFloat(-y) * 10)
        }
        .frame(width: 50, height: 50)
    }

    private func triggerBar(label: String, value: Double) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(DashboardTheme.cardBorder.opacity(0.6), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 4).fill(DashboardTheme.background.opacity(0.6)))
            RoundedRectangle(cornerRadius: 4)
                .fill(DashboardTheme.accent.opacity(0.8))
                .frame(height: CGFloat(max(0.05, value)) * 20)
        }
        .frame(width: 18, height: 22)
        .overlay(
            Text(label)
                .font(.dashboardBody(8))
                .foregroundStyle(DashboardTheme.textSecondary)
                .offset(y: 12)
        )
    }

    private func buttonCircle(_ label: String, isActive: Bool) -> some View {
        let color = isActive ? DashboardTheme.accent : DashboardTheme.cardBorder
        return ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .overlay(Circle().stroke(color.opacity(0.8), lineWidth: 1))
            Text(label)
                .font(.dashboardBody(8))
                .foregroundStyle(DashboardTheme.textPrimary)
        }
        .frame(width: 16, height: 16)
    }

    private func buttonCapsule(_ label: String, isActive: Bool) -> some View {
        let color = isActive ? DashboardTheme.accent : DashboardTheme.cardBorder
        return Text(label)
            .font(.dashboardBody(8))
            .foregroundStyle(DashboardTheme.textPrimary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(color.opacity(0.8), lineWidth: 1)
            )
    }
}
