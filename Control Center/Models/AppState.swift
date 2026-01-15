import Foundation
import SwiftUI

final class AppState: ObservableObject {
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    @Published var host: String {
        didSet { settings.saveHost(host) }
    }
    @Published var port: Int {
        didSet { settings.savePort(port) }
    }

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var metrics = ConnectionMetrics(pingMs: 0, packetLossPercent: 0, reconnectCount: 0, lastTelemetryAt: nil)
    @Published private(set) var lastTelemetry: TelemetryMessage?
    @Published private(set) var lastCommandSent: String = ""

    @Published var systemPowerOn: Bool = false
    @Published var autonomousOn: Bool = false
    @Published var eStopActive: Bool = false {
        didSet {
            gamepad.isEnabled = controllerEnabled && !eStopActive
        }
    }
    @Published var controllerEnabled: Bool = false {
        didSet {
            gamepad.isEnabled = controllerEnabled && !eStopActive
        }
    }
    @Published var driveEnabled: Bool = true
    @Published var drumEnabled: Bool = true

    @Published var isDarkTheme: Bool = true

    @Published var driveProfiles: [DriveProfile]
    @Published var selectedDriveProfile: DriveProfile

    @Published var controllerBindings: ControllerBindings

    @Published var cameraConfigs: [CameraConfig]
    @Published var cameraFullscreen: Bool = false
    @Published var controllerMapping: [String: String] = [
        "Drive Forward": "LS-Y",
        "Drive Reverse": "LS-Y",
        "Drive Right": "RS-X",
        "Drive Left": "RS-X",
        "Drum Up": "LT",
        "Drum Down": "RT",
        "Spin Dig": "RB",
        "Spin Dump": "LB",
        "Autonomous On": "A",
        "Autonomous Off": "B",
        "E-Stop On": "Y",
        "E-Stop Off": "X",
        "Camera 1 Control": "D-Up",
        "Camera 2 Control": "D-Down"
    ]

    @Published var loggerStatus: String = "Idle"
    @Published var connectionLog: [String] = []
    @Published var showConnectionLog: Bool = false
    @Published var webSocketActivity: [WebSocketActivityEntry] = []

    private let settings = SettingsStore.shared
    let webSocket = WebSocketManager()
    let gamepad = GamepadManager()
    let logger: Logger

    private var telemetryBuffer: [TelemetryMessage] = []
    private let telemetryBufferLimit = 200
    private var lastSeq: Int?
    private var missingSeqCount = 0
    private var receivedSeqCount = 0

    private var driveHoldTimer: Timer?
    private var drumHoldTimer: Timer?
    private var heldDriveCommand: (v: Double, w: Double) = (0, 0)
    private var heldDrumCommand: (lift: Double, spin: Double) = (0, 0)
    private var lastInputStates: [String: Bool] = [:]

    init() {
        let initialHost = settings.loadHost()
        let initialPort = settings.loadPort()
        let initialBindings = settings.loadControllerBindings()
        let initialProfiles = settings.loadDriveProfiles()
        let selectedName = settings.loadSelectedProfileName()
        let initialSelectedProfile = initialProfiles.first { $0.name == selectedName }
            ?? initialProfiles.first
            ?? settings.defaultDriveProfiles()[0]
        let initialCameras = settings.loadCameraConfigs()
        let initialSaveURL = Self.resolveSaveLocation(from: settings)

        host = initialHost
        port = initialPort
        controllerBindings = initialBindings
        driveProfiles = initialProfiles
        selectedDriveProfile = initialSelectedProfile
        cameraConfigs = initialCameras

        logger = Logger(saveDirectory: initialSaveURL)

        webSocket.onTelemetry = { [weak self] telemetry in
            DispatchQueue.main.async {
                self?.handleTelemetry(telemetry)
            }
        }
        webSocket.onLog = { [weak self] message in
            DispatchQueue.main.async {
                self?.appendConnectionLog(message)
            }
        }
        webSocket.onPingUpdate = { [weak self] ping in
            DispatchQueue.main.async {
                self?.metrics.pingMs = ping
            }
        }
        webSocket.onReconnect = { [weak self] count in
            DispatchQueue.main.async {
                self?.metrics.reconnectCount = count
            }
        }
        webSocket.onDisconnect = { [weak self] _ in
            DispatchQueue.main.async {
                self?.connectionState = .disconnected
            }
        }
        webSocket.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.connectionState = state
            }
        }

        gamepad.onStateUpdate = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleGamepadState(state)
            }
        }
        gamepad.updateBindings(controllerBindings)
        gamepad.isEnabled = controllerEnabled && !eStopActive
    }

    func connect() {
        settings.saveHost(host)
        settings.savePort(port)
        webSocket.connect(host: host, port: port)
        connectionState = .connecting
    }

    func disconnect() {
        webSocket.disconnect()
        connectionState = .disconnected
    }

    func updateConnectionState(_ state: ConnectionState) {
        connectionState = state
    }

    func toggleTheme() {
        isDarkTheme.toggle()
    }

    func appendConnectionLog(_ message: String) {
        let timestamp = Self.timestampFormatter.string(from: Date())
        connectionLog.append("[\(timestamp)] \(message)")
        if connectionLog.count > 120 {
            connectionLog.removeFirst(connectionLog.count - 120)
        }
    }

    func activateEStop() {
        guard !eStopActive else { return }
        eStopActive = true
        controllerEnabled = false
        driveEnabled = false
        drumEnabled = false
        stopAllHeldCommands()
        sendStopAll()
    }

    func resetEStop() {
        eStopActive = false
        driveEnabled = true
        drumEnabled = true
    }

    func sendStopAll() {
        webSocket.sendJSON(["type": "stop_all"])
        appendWebSocketActivity(direction: .outgoing, text: "stop_all")
        lastCommandSent = "stop_all"
        logger.appendLine("{\"type\":\"stop_all\",\"ts\":\(Date().timeIntervalSince1970)}")
    }

    func sendDrive(v: Double, w: Double) {
        guard driveEnabled, !eStopActive else { return }
        let scaledV = v * selectedDriveProfile.linearScale
        let scaledW = w * selectedDriveProfile.angularScale
        webSocket.sendJSON(["type": "drive", "v": scaledV, "w": scaledW])
        appendWebSocketActivity(direction: .outgoing, text: String(format: "drive v=%.3f w=%.3f", scaledV, scaledW))
        lastCommandSent = "drive v=\(scaledV) w=\(scaledW)"
        logger.appendLine("{\"type\":\"drive\",\"v\":\(scaledV),\"w\":\(scaledW),\"ts\":\(Date().timeIntervalSince1970)}")
    }

    func sendDrum(lift: Double, spin: Double) {
        guard drumEnabled, !eStopActive else { return }
        webSocket.sendJSON(["type": "drum", "lift": lift, "spin": spin])
        appendWebSocketActivity(direction: .outgoing, text: String(format: "drum lift=%.3f spin=%.3f", lift, spin))
        lastCommandSent = "drum lift=\(lift) spin=\(spin)"
        logger.appendLine("{\"type\":\"drum\",\"lift\":\(lift),\"spin\":\(spin),\"ts\":\(Date().timeIntervalSince1970)}")
    }

    func setMode(systemPower: Bool, autonomous: Bool) {
        systemPowerOn = systemPower
        autonomousOn = autonomous
        webSocket.sendJSON([
            "type": "set_mode",
            "system_power": systemPower,
            "autonomous": autonomous
        ])
        appendWebSocketActivity(direction: .outgoing, text: "set_mode power=\(systemPower) auto=\(autonomous)")
        lastCommandSent = "set_mode system_power=\(systemPower) autonomous=\(autonomous)"
    }

    func updateDriveProfile(_ profile: DriveProfile) {
        selectedDriveProfile = profile
        settings.saveSelectedProfileName(profile.name)
        persistDriveProfiles()
    }

    func updateSelectedProfileValue(keyPath: WritableKeyPath<DriveProfile, Double>, value: Double) {
        var updated = selectedDriveProfile
        updated[keyPath: keyPath] = value
        selectedDriveProfile = updated
        if let index = driveProfiles.firstIndex(where: { $0.name == updated.name }) {
            driveProfiles[index] = updated
        }
        persistDriveProfiles()
    }

    func updateControllerBindings(_ bindings: ControllerBindings) {
        controllerBindings = bindings
        settings.saveControllerBindings(bindings)
        gamepad.updateBindings(bindings)
    }

    func updateCameraConfigs(_ configs: [CameraConfig]) {
        cameraConfigs = configs
        settings.saveCameraConfigs(configs)
    }

    func persistCameraConfigs() {
        settings.saveCameraConfigs(cameraConfigs)
    }

    func toggleCameraFullscreen() {
        cameraFullscreen.toggle()
    }

    func exitCameraFullscreen() {
        cameraFullscreen = false
    }

    func selectSaveLocation() {
        if let url = logger.selectSaveDirectory() {
            if let bookmark = Self.createBookmark(for: url) {
                settings.saveSaveLocationBookmark(bookmark)
            }
            logger.updateSaveDirectory(url)
            loggerStatus = "Save location set"
        }
    }

    func saveSnapshot() {
        let snapshot = AppStateSnapshot(
            capturedAt: Date(),
            connectionState: connectionState.rawValue,
            lastCommand: lastCommandSent,
            lastTelemetry: lastTelemetry,
            telemetryBuffer: telemetryBuffer,
            modes: [
                "system_power": systemPowerOn,
                "autonomous": autonomousOn,
                "e_stop": eStopActive,
                "controller_enabled": controllerEnabled,
                "drive_enabled": driveEnabled,
                "drum_enabled": drumEnabled
            ],
            controllerEnabled: controllerEnabled,
            driveEnabled: driveEnabled,
            drumEnabled: drumEnabled,
            driveProfile: selectedDriveProfile.name,
            cameraConfigs: cameraConfigs
        )
        logger.saveSnapshot(state: snapshot)
    }

    func toggleRecording() {
        if logger.isRecording {
            logger.stopRecording()
            loggerStatus = "Stopped"
        } else {
            logger.startRecording()
            loggerStatus = logger.isRecording ? "Recording" : "No Save Location"
        }
    }

    func startDriveHold(v: Double, w: Double) {
        heldDriveCommand = (v, w)
        driveHoldTimer?.invalidate()
        driveHoldTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.sendDrive(v: v, w: w)
        }
    }

    func stopDriveHold() {
        driveHoldTimer?.invalidate()
        driveHoldTimer = nil
        heldDriveCommand = (0, 0)
    }

    func startDrumHold(lift: Double, spin: Double) {
        heldDrumCommand = (lift, spin)
        drumHoldTimer?.invalidate()
        drumHoldTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.sendDrum(lift: lift, spin: spin)
        }
    }

    func stopDrumHold() {
        drumHoldTimer?.invalidate()
        drumHoldTimer = nil
        heldDrumCommand = (0, 0)
    }

    func stopAllHeldCommands() {
        stopDriveHold()
        stopDrumHold()
    }

    func handleWindowInactive() {
        stopAllHeldCommands()
    }

    private func handleTelemetry(_ telemetry: TelemetryMessage) {
        connectionState = .connected
        lastTelemetry = telemetry
        metrics.lastTelemetryAt = Date()
        appendWebSocketActivity(direction: .incoming, text: telemetrySummary(telemetry))
        if let ping = telemetry.ping_ms {
            metrics.pingMs = ping
        }

        if let lastSeq {
            if telemetry.seq > lastSeq + 1 {
                missingSeqCount += max(0, telemetry.seq - lastSeq - 1)
            }
        }
        lastSeq = telemetry.seq
        receivedSeqCount += 1
        let total = Double(missingSeqCount + receivedSeqCount)
        metrics.packetLossPercent = total == 0 ? 0 : (Double(missingSeqCount) / total) * 100

        telemetryBuffer.append(telemetry)
        if telemetryBuffer.count > telemetryBufferLimit {
            telemetryBuffer.removeFirst(telemetryBuffer.count - telemetryBufferLimit)
        }

        if logger.isRecording {
            if let data = try? JSONEncoder().encode(telemetry),
               let text = String(data: data, encoding: .utf8) {
                logger.appendLine(text)
            }
        }
    }

    private func appendWebSocketActivity(direction: WebSocketDirection, text: String) {
        webSocketActivity.append(WebSocketActivityEntry(direction: direction, text: text, timestamp: Date()))
        if webSocketActivity.count > 120 {
            webSocketActivity.removeFirst(webSocketActivity.count - 120)
        }
    }

    private func telemetrySummary(_ telemetry: TelemetryMessage) -> String {
        let ping = telemetry.ping_ms ?? 0
        return String(
            format: "telemetry seq=%d v=%.3f w=%.3f lift=%.3f spin=%.3f ping=%.0f",
            telemetry.seq,
            telemetry.drive.v,
            telemetry.drive.w,
            telemetry.drum.lift,
            telemetry.drum.spin,
            ping
        )
    }

    private func sendDriveFromController(v: Double, w: Double) {
        guard controllerEnabled, driveEnabled, !eStopActive else { return }
        sendDrive(v: v, w: w)
    }

    private func sendDrumFromController(lift: Double, spin: Double) {
        guard controllerEnabled, drumEnabled, !eStopActive else { return }
        sendDrum(lift: lift, spin: spin)
    }

    private func handleGamepadState(_ state: GamepadState) {
        guard controllerEnabled, !eStopActive else { return }
        let driveMax = 0.6
        let turnMax = 0.5
        let liftMax = 0.6
        let spinMax = 0.6

        let forward = magnitude(for: controllerMapping["Drive Forward"], state: state, polarity: .positive)
        let reverse = magnitude(for: controllerMapping["Drive Reverse"], state: state, polarity: .negative)
        let right = magnitude(for: controllerMapping["Drive Right"], state: state, polarity: .positive)
        let left = magnitude(for: controllerMapping["Drive Left"], state: state, polarity: .negative)

        let v = (forward - reverse) * driveMax
        let w = (right - left) * turnMax
        sendDriveFromController(v: v, w: w)

        let drumUp = magnitude(for: controllerMapping["Drum Up"], state: state, polarity: .positive)
        let drumDown = magnitude(for: controllerMapping["Drum Down"], state: state, polarity: .positive)
        let spinDig = magnitude(for: controllerMapping["Spin Dig"], state: state, polarity: .positive)
        let spinDump = magnitude(for: controllerMapping["Spin Dump"], state: state, polarity: .positive)
        let lift = (drumUp - drumDown) * liftMax
        let spin = (spinDig - spinDump) * spinMax
        sendDrumFromController(lift: lift, spin: spin)

        handleEdgeAction("Autonomous On", state: state) {
            setMode(systemPower: systemPowerOn, autonomous: true)
        }
        handleEdgeAction("Autonomous Off", state: state) {
            setMode(systemPower: systemPowerOn, autonomous: false)
        }
        handleEdgeAction("E-Stop On", state: state) {
            activateEStop()
        }
        handleEdgeAction("E-Stop Off", state: state) {
            resetEStop()
        }
        handleEdgeAction("Camera 1 Control", state: state) {
            toggleCamera(index: 0)
        }
        handleEdgeAction("Camera 2 Control", state: state) {
            toggleCamera(index: 1)
        }
    }

    private enum Polarity {
        case positive
        case negative
    }

    private func magnitude(for token: String?, state: GamepadState, polarity: Polarity) -> Double {
        guard let token else { return 0 }
        let value = inputValue(for: token, state: state)
        if isAxis(token) {
            switch polarity {
            case .positive:
                return max(0, value)
            case .negative:
                return max(0, -value)
            }
        }
        return value
    }

    private func handleEdgeAction(_ action: String, state: GamepadState, actionBlock: () -> Void) {
        guard let token = controllerMapping[action] else { return }
        let pressed = inputValue(for: token, state: state) > 0.5
        let wasPressed = lastInputStates[action] ?? false
        if pressed && !wasPressed {
            actionBlock()
        }
        lastInputStates[action] = pressed
    }

    private func inputValue(for token: String, state: GamepadState) -> Double {
        switch token {
        case "A": return state.buttonAPressed ? 1 : 0
        case "B": return state.buttonBPressed ? 1 : 0
        case "X": return state.buttonXPressed ? 1 : 0
        case "Y": return state.buttonYPressed ? 1 : 0
        case "LB": return state.buttonLBPressed ? 1 : 0
        case "RB": return state.buttonRBPressed ? 1 : 0
        case "+": return state.buttonPlusPressed ? 1 : 0
        case "-": return state.buttonMinusPressed ? 1 : 0
        case "D-Up": return state.dpadUpPressed ? 1 : 0
        case "D-Down": return state.dpadDownPressed ? 1 : 0
        case "D-Left": return state.dpadLeftPressed ? 1 : 0
        case "D-Right": return state.dpadRightPressed ? 1 : 0
        case "LT": return min(0.5, max(0, state.leftTrigger * 0.5))
        case "RT": return min(0.5, max(0, state.rightTrigger * 0.5))
        case "LS-X": return state.leftStickX
        case "LS-Y": return state.leftStickY
        case "RS-X": return state.rightStickX
        case "RS-Y": return state.rightStickY
        default: return 0
        }
    }

    private func isAxis(_ token: String) -> Bool {
        token == "LS-X" || token == "LS-Y" || token == "RS-X" || token == "RS-Y"
    }

    private func toggleCamera(index: Int) {
        guard cameraConfigs.indices.contains(index) else { return }
        cameraConfigs[index].isEnabled.toggle()
    }

    private static func resolveSaveLocation(from settings: SettingsStore) -> URL? {
        guard let bookmark = settings.loadSaveLocationBookmark() else { return nil }
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &isStale) {
            if isStale, let newBookmark = Self.createBookmark(for: url) {
                settings.saveSaveLocationBookmark(newBookmark)
            }
            return url
        }
        return nil
    }

    private static func createBookmark(for url: URL) -> Data? {
        try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    private func persistDriveProfiles() {
        settings.saveDriveProfiles(driveProfiles)
    }
}
