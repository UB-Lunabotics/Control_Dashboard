import Foundation
import GameController

struct GamepadState {
    var leftStickX: Double = 0
    var leftStickY: Double = 0
    var rightStickX: Double = 0
    var rightStickY: Double = 0
    var leftTrigger: Double = 0
    var rightTrigger: Double = 0
    var buttonAPressed: Bool = false
    var buttonBPressed: Bool = false
    var buttonXPressed: Bool = false
    var buttonYPressed: Bool = false
    var buttonPlusPressed: Bool = false
    var buttonMinusPressed: Bool = false
}

final class GamepadManager: ObservableObject {
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var controllerName: String = "No Controller"
    @Published private(set) var vendorName: String = ""
    @Published private(set) var productCategory: String = ""
    @Published private(set) var state = GamepadState()

    var bindings = ControllerBindings(deadzone: 0.12, sensitivity: 1.0, invertY: false)
    var isEnabled: Bool = false
    var onDriveCommand: ((Double, Double) -> Void)?
    var onDrumCommand: ((Double, Double) -> Void)?
    var onEStop: (() -> Void)?

    private var pollTimer: Timer?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(controllerConnected), name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDisconnected), name: .GCControllerDidDisconnect, object: nil)
        if let controller = GCController.controllers().first {
            configure(controller: controller)
        }
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    func updateBindings(_ bindings: ControllerBindings) {
        self.bindings = bindings
    }

    @objc private func controllerConnected(note: Notification) {
        guard let controller = note.object as? GCController else { return }
        configure(controller: controller)
    }

    @objc private func controllerDisconnected(note: Notification) {
        isConnected = false
        controllerName = "No Controller"
        vendorName = ""
        productCategory = ""
        state = GamepadState()
    }

    private func configure(controller: GCController) {
        isConnected = true
        controllerName = controller.vendorName ?? "Controller"
        vendorName = controller.vendorName ?? ""
        productCategory = controller.productCategory

        controller.extendedGamepad?.valueChangedHandler = { [weak self] gamepad, element in
            guard let self else { return }
            self.readState(gamepad)
        }
    }

    private func readState(_ gamepad: GCExtendedGamepad) {
        let invert: Double = bindings.invertY ? -1.0 : 1.0
        state.leftStickX = Double(gamepad.leftThumbstick.xAxis.value)
        state.leftStickY = Double(gamepad.leftThumbstick.yAxis.value) * invert
        state.rightStickX = Double(gamepad.rightThumbstick.xAxis.value)
        state.rightStickY = Double(gamepad.rightThumbstick.yAxis.value) * invert
        state.leftTrigger = Double(gamepad.leftTrigger.value)
        state.rightTrigger = Double(gamepad.rightTrigger.value)
        state.buttonAPressed = gamepad.buttonA.isPressed
        state.buttonBPressed = gamepad.buttonB.isPressed
        state.buttonXPressed = gamepad.buttonX.isPressed
        state.buttonYPressed = gamepad.buttonY.isPressed
        state.buttonPlusPressed = gamepad.buttonMenu.isPressed
        state.buttonMinusPressed = gamepad.buttonOptions?.isPressed ?? false

        if state.buttonBPressed {
            onEStop?()
        }
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.emitCommands()
        }
    }

    private func emitCommands() {
        guard isEnabled, isConnected else { return }
        let vRaw = applyDeadzone(state.leftStickY)
        let wRaw = applyDeadzone(state.rightStickX)
        let v = applySensitivity(vRaw)
        let w = applySensitivity(wRaw)
        onDriveCommand?(v, w)

        let spin = applySensitivity(state.rightTrigger) - applySensitivity(state.leftTrigger)
        if abs(spin) > 0.01 {
            onDrumCommand?(0, spin)
        }
    }

    private func applyDeadzone(_ value: Double) -> Double {
        let dz = bindings.deadzone
        if abs(value) < dz {
            return 0
        }
        return value
    }

    private func applySensitivity(_ value: Double) -> Double {
        value * bindings.sensitivity
    }
}
