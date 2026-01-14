import SwiftUI

struct ControllerVisualizationCard: View {
    @ObservedObject var state: AppState
    @ObservedObject private var gamepad: GamepadManager

    init(state: AppState) {
        self.state = state
        self.gamepad = state.gamepad
    }

    var body: some View {
        CardView(title: "Controller Visualization") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gamepad.controllerName)
                            .font(.dashboardBody(14))
                            .foregroundStyle(DashboardTheme.textPrimary)
                        Text([gamepad.vendorName, gamepad.productCategory].filter { !$0.isEmpty }.joined(separator: " / "))
                            .font(.dashboardBody(11))
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                    Spacer()
                    Toggle("Enable Controller", isOn: $state.controllerEnabled)
                        .toggleStyle(.switch)
                        .keyboardShortcut("c", modifiers: [])
                        .disabled(state.eStopActive)
                }

                HStack(spacing: 12) {
                    stickView(title: "Left Stick", x: gamepad.state.leftStickX, y: gamepad.state.leftStickY)
                    stickView(title: "Right Stick", x: gamepad.state.rightStickX, y: gamepad.state.rightStickY)
                    VStack(spacing: 10) {
                        axisBar(title: "L Trigger", value: gamepad.state.leftTrigger)
                        axisBar(title: "R Trigger", value: gamepad.state.rightTrigger)
                        StatusPill(text: gamepad.state.buttonBPressed ? "B Pressed" : "B Idle", color: gamepad.state.buttonBPressed ? DashboardTheme.danger : DashboardTheme.cardBorder)
                    }
                }

                Divider().background(DashboardTheme.cardBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bindings")
                        .font(.dashboardBody(12))
                        .foregroundStyle(DashboardTheme.textSecondary)
                    LabeledSlider(title: "Deadzone", value: bindingForBindingsValue(\.deadzone), range: 0...0.4, step: 0.01)
                    LabeledSlider(title: "Sensitivity", value: bindingForBindingsValue(\.sensitivity), range: 0.4...2.0, step: 0.01)
                    Toggle("Invert Y", isOn: bindingForBindingsBool(\.invertY))
                        .toggleStyle(.switch)
                }
            }
        }
    }

    private func stickView(title: String, x: Double, y: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.dashboardBody(11))
                .foregroundStyle(DashboardTheme.textSecondary)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DashboardTheme.background.opacity(0.7))
                Circle()
                    .fill(DashboardTheme.accent)
                    .frame(width: 10, height: 10)
                    .offset(x: CGFloat(x) * 28, y: CGFloat(-y) * 28)
            }
            .frame(width: 80, height: 80)
            Text(String(format: "x %.2f  y %.2f", x, y))
                .font(.dashboardMono(10))
                .foregroundStyle(DashboardTheme.textSecondary)
        }
    }

    private func axisBar(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.dashboardBody(11))
                .foregroundStyle(DashboardTheme.textSecondary)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DashboardTheme.background.opacity(0.7))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DashboardTheme.accent)
                        .frame(width: proxy.size.width * CGFloat(value))
                }
            }
            .frame(height: 10)
            Text(String(format: "%.2f", value))
                .font(.dashboardMono(10))
                .foregroundStyle(DashboardTheme.textSecondary)
        }
        .frame(width: 140)
    }

    private func bindingForBindingsValue(_ keyPath: WritableKeyPath<ControllerBindings, Double>) -> Binding<Double> {
        Binding(
            get: { state.controllerBindings[keyPath: keyPath] },
            set: { value in
                var updated = state.controllerBindings
                updated[keyPath: keyPath] = value
                state.updateControllerBindings(updated)
            }
        )
    }

    private func bindingForBindingsBool(_ keyPath: WritableKeyPath<ControllerBindings, Bool>) -> Binding<Bool> {
        Binding(
            get: { state.controllerBindings[keyPath: keyPath] },
            set: { value in
                var updated = state.controllerBindings
                updated[keyPath: keyPath] = value
                state.updateControllerBindings(updated)
            }
        )
    }
}
