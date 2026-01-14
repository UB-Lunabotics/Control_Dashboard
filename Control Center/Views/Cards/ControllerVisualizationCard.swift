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
                        .frame(width: 240, height: 150)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DashboardTheme.cardBorder.opacity(0.5), lineWidth: 1)
                        Text("Binding: Standard")
                            .font(.dashboardBody(10))
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                    .frame(width: 140, height: 90)
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
                .position(x: 60, y: 70)
            stickCircle(x: state.rightStickX, y: state.rightStickY)
                .position(x: 135, y: 70)

            triggerBar(label: "LT", value: state.leftTrigger)
                .position(x: 160, y: 22)
            triggerBar(label: "RT", value: state.rightTrigger)
                .position(x: 195, y: 22)

            buttonCircle("Y", isActive: state.buttonYPressed)
                .position(x: 185, y: 68)
            buttonCircle("X", isActive: state.buttonXPressed)
                .position(x: 165, y: 86)
            buttonCircle("B", isActive: state.buttonBPressed)
                .position(x: 205, y: 86)
            buttonCircle("A", isActive: state.buttonAPressed)
                .position(x: 185, y: 104)

            buttonCapsule("+", isActive: state.buttonPlusPressed)
                .position(x: 175, y: 125)
            buttonCapsule("-", isActive: state.buttonMinusPressed)
                .position(x: 205, y: 125)
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
        .frame(width: 70, height: 70)
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
        .frame(width: 24, height: 30)
        .overlay(
            Text(label)
                .font(.dashboardBody(8))
                .foregroundStyle(DashboardTheme.textSecondary)
                .offset(y: 16)
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
        .frame(width: 20, height: 20)
    }

    private func buttonCapsule(_ label: String, isActive: Bool) -> some View {
        let color = isActive ? DashboardTheme.accent : DashboardTheme.cardBorder
        return Text(label)
            .font(.dashboardBody(8))
            .foregroundStyle(DashboardTheme.textPrimary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(color.opacity(0.8), lineWidth: 1)
            )
    }
}
