import Foundation

final class WebSocketManager: ObservableObject {
    @Published private(set) var state: ConnectionState = .disconnected

    private var session: URLSession = URLSession(configuration: .default)
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTimer: Timer?
    private var pingTimer: Timer?
    private var reconnectAttempt = 0
    private var currentURL: URL?

    var onTelemetry: ((TelemetryMessage) -> Void)?
    var onPingUpdate: ((Double) -> Void)?
    var onReconnect: ((Int) -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onStateChange: ((ConnectionState) -> Void)?

    func connect(host: String, port: Int) {
        let urlString = "ws://\(host):\(port)"
        guard let url = URL(string: urlString) else { return }
        currentURL = url
        state = .connecting
        onStateChange?(.connecting)
        reconnectAttempt = 0
        startTask(url: url)
    }

    func disconnect() {
        state = .disconnected
        onStateChange?(.disconnected)
        stopTimers()
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    func sendJSON(_ payload: [String: Any]) {
        guard let task, state == .connected else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return }
        let message = URLSessionWebSocketTask.Message.data(data)
        task.send(message) { _ in }
    }

    private func startTask(url: URL) {
        stopTimers()
        receiveTask?.cancel()
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        state = .connecting
        onStateChange?(.connecting)
        startReceiveLoop()
        startPingLoop()
    }

    private func startReceiveLoop() {
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    guard let task = self.task else { return }
                    let message = try await task.receive()
                    await MainActor.run {
                        self.state = .connected
                        self.onStateChange?(.connected)
                    }
                    self.handleMessage(message)
                } catch {
                    await MainActor.run {
                        self.state = .disconnected
                        self.onStateChange?(.disconnected)
                    }
                    self.scheduleReconnect(error: error)
                    break
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        let data: Data?
        switch message {
        case .data(let value):
            data = value
        case .string(let value):
            data = value.data(using: .utf8)
        @unknown default:
            data = nil
        }
        guard let data else { return }
        if let telemetry = try? JSONDecoder().decode(TelemetryMessage.self, from: data), telemetry.type == "telemetry" {
            onTelemetry?(telemetry)
        }
    }

    private func scheduleReconnect(error: Error?) {
        onDisconnect?(error)
        reconnectAttempt += 1
        onReconnect?(reconnectAttempt)
        stopTimers()
        guard let url = currentURL else { return }
        let delay = min(10.0, pow(1.6, Double(reconnectAttempt)))
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.startTask(url: url)
        }
    }

    private func startPingLoop() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func sendPing() {
        guard let task, state == .connected else { return }
        let started = Date()
        task.sendPing { [weak self] error in
            guard error == nil else { return }
            let elapsed = Date().timeIntervalSince(started) * 1000.0
            DispatchQueue.main.async {
                self?.onPingUpdate?(elapsed)
            }
        }
    }

    private func stopTimers() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        pingTimer?.invalidate()
        pingTimer = nil
    }
}
