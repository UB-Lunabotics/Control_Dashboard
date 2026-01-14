import SwiftUI

struct ControllerVisualizationCard: View {
    @ObservedObject var state: AppState
    @ObservedObject private var gamepad: GamepadManager

    @State private var showMapping: Bool = false
    private let mappingButtons = [
        "A", "B", "X", "Y",
        "LT", "RT", "LB", "RB",
        "+", "-",
        "D-Up", "D-Down", "D-Left", "D-Right",
        "LS-X", "LS-Y", "RS-X", "RS-Y"
    ]

    init(state: AppState) {
        self.state = state
        self.gamepad = state.gamepad
    }

    var body: some View {
        CardView(title: "Controller Visualization") {
            VStack(alignment: .leading, spacing: 8) {
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
                    .controlSize(.regular)
                }

                if !showMapping {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                stickCircle(title: "Left", x: gamepad.state.leftStickX, y: gamepad.state.leftStickY)
                                stickCircle(title: "Right", x: gamepad.state.rightStickX, y: gamepad.state.rightStickY)
                            }
                            dPadView(state: gamepad.state)
                        }
                        .frame(width: 160)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                TriggerIndicator(title: "LT (Drum Up)", value: gamepad.state.leftTrigger)
                                TriggerIndicator(title: "RT (Drum Down)", value: gamepad.state.rightTrigger)
                            }
                            HStack(spacing: 8) {
                                ButtonIndicator(title: "LB (Mode Prev)", isActive: gamepad.state.buttonLBPressed)
                                ButtonIndicator(title: "RB (Mode Next)", isActive: gamepad.state.buttonRBPressed)
                            }
                            HStack(spacing: 8) {
                                ButtonIndicator(title: "A (Start Auto)", isActive: gamepad.state.buttonAPressed)
                                ButtonIndicator(title: "X (Left)", isActive: gamepad.state.buttonXPressed)
                            }
                            HStack(spacing: 8) {
                                ButtonIndicator(title: "B (E-Stop)", isActive: gamepad.state.buttonBPressed)
                                ButtonIndicator(title: "Y (Forward)", isActive: gamepad.state.buttonYPressed)
                            }
                            HStack(spacing: 8) {
                                ButtonIndicator(title: "+ (Aux +)", isActive: gamepad.state.buttonPlusPressed)
                                ButtonIndicator(title: "- (Aux -)", isActive: gamepad.state.buttonMinusPressed)
                            }
                        }
                    }
                }

                if showMapping {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Button Mapping")
                            .font(.dashboardBody(10))
                            .foregroundStyle(DashboardTheme.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(state.controllerMapping.keys.sorted(), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .font(.dashboardBody(10))
                                        .foregroundStyle(DashboardTheme.textPrimary)
                                    Spacer()
                                    Picker("", selection: Binding(
                                        get: { state.controllerMapping[key] ?? "A" },
                                        set: { state.controllerMapping[key] = $0 }
                                    )) {
                                        ForEach(mappingButtons, id: \.self) { option in
                                            Text(option).tag(option)
                                        }
                                    }
                                    .labelsHidden()
                                    .controlSize(.mini)
                                    .frame(width: 60)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ButtonIndicator: View {
    let title: String
    let isActive: Bool

    var body: some View {
        let color = isActive ? DashboardTheme.accent : DashboardTheme.cardBorder
        return Text(title)
            .font(.dashboardBody(10))
            .foregroundStyle(DashboardTheme.textPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(isActive ? 0.25 : 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.7), lineWidth: 1)
            )
    }
}

private struct TriggerIndicator: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.dashboardBody(10))
                .foregroundStyle(DashboardTheme.textPrimary)
            GeometryReader { proxy in
                let width = max(2, proxy.size.width * CGFloat(value))
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DashboardTheme.cardBackground.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DashboardTheme.cardBorder.opacity(0.6), lineWidth: 1)
                        )
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DashboardTheme.accent.opacity(0.8))
                        .frame(width: width)
                }
            }
            .frame(height: 12)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(DashboardTheme.cardBackground.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private func stickCircle(title: String, x: Double, y: Double) -> some View {
    VStack(spacing: 6) {
        ZStack {
            Circle()
                .stroke(DashboardTheme.cardBorder.opacity(0.6), lineWidth: 1)
            Circle()
                .fill(DashboardTheme.accent)
                .frame(width: 6, height: 6)
                .offset(x: CGFloat(x) * 10, y: CGFloat(-y) * 10)
        }
        .frame(width: 70, height: 70)
        Text(title)
            .font(.dashboardBody(10))
            .foregroundStyle(DashboardTheme.textSecondary)
    }
}

private func dPadView(state: GamepadState) -> some View {
    let size: CGFloat = 50
    return ZStack {
        RoundedRectangle(cornerRadius: 4)
            .stroke(DashboardTheme.cardBorder.opacity(0.6), lineWidth: 1)
            .frame(width: size, height: size)

        dPadSegment(isActive: state.dpadUpPressed)
            .frame(width: size * 0.32, height: size * 0.5)
            .offset(y: -size * 0.25)
        dPadSegment(isActive: state.dpadDownPressed)
            .frame(width: size * 0.32, height: size * 0.5)
            .offset(y: size * 0.25)
        dPadSegment(isActive: state.dpadLeftPressed)
            .frame(width: size * 0.5, height: size * 0.32)
            .offset(x: -size * 0.25)
        dPadSegment(isActive: state.dpadRightPressed)
            .frame(width: size * 0.5, height: size * 0.32)
            .offset(x: size * 0.25)
    }
}

private func dPadSegment(isActive: Bool) -> some View {
    let color = isActive ? DashboardTheme.accent : DashboardTheme.cardBorder
    return RoundedRectangle(cornerRadius: 3)
        .fill(color.opacity(isActive ? 0.8 : 0.35))
}
