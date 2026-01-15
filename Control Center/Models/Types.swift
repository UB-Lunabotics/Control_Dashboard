import Foundation

struct IMUData: Codable {
    var roll: Double
    var pitch: Double
    var yaw: Double
}

struct DriveTelemetry: Codable {
    var v: Double
    var w: Double
}

struct DrumTelemetry: Codable {
    var lift: Double
    var spin: Double
}

struct TelemetryMessage: Codable {
    var type: String
    var seq: Int
    var imu: IMUData
    var drive: DriveTelemetry
    var drum: DrumTelemetry
    var ping_ms: Double?
}

struct DriveProfile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var linearScale: Double
    var angularScale: Double
    var expo: Double
    var traction: Double
    var torque: Double
}

struct ControllerBindings: Codable, Equatable {
    var deadzone: Double
    var sensitivity: Double
    var invertY: Bool
}

struct CameraConfig: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var url: String
    var isEnabled: Bool
}

struct ConnectionMetrics: Equatable {
    var pingMs: Double
    var packetLossPercent: Double
    var reconnectCount: Int
    var lastTelemetryAt: Date?
}

enum ConnectionState: String {
    case disconnected
    case connecting
    case connected
}

enum WebSocketDirection: String {
    case outgoing
    case incoming
}

struct WebSocketActivityEntry: Identifiable, Equatable {
    let id = UUID()
    let direction: WebSocketDirection
    let text: String
    let timestamp: Date
}
