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
    var streamType: String = "RTSP"
    var username: String = ""
    var password: String = ""
    var latencyMs: Double = 200

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case isEnabled
        case streamType
        case username
        case password
        case latencyMs
    }

    init(id: UUID = UUID(),
         name: String,
         url: String,
         isEnabled: Bool,
         streamType: String = "RTSP",
         username: String = "",
         password: String = "",
         latencyMs: Double = 200) {
        self.id = id
        self.name = name
        self.url = url
        self.isEnabled = isEnabled
        self.streamType = streamType
        self.username = username
        self.password = password
        self.latencyMs = latencyMs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Camera"
        url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        streamType = try container.decodeIfPresent(String.self, forKey: .streamType) ?? "RTSP"
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        latencyMs = try container.decodeIfPresent(Double.self, forKey: .latencyMs) ?? 200
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(streamType, forKey: .streamType)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(latencyMs, forKey: .latencyMs)
    }
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
