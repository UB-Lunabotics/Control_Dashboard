import Foundation

struct SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let host = "ws.host"
        static let port = "ws.port"
        static let controllerBindings = "controller.bindings"
        static let driveProfiles = "drive.profiles"
        static let selectedProfileName = "drive.selected_profile"
        static let cameraConfigs = "camera.configs"
        static let saveLocationBookmark = "logger.save_location_bookmark"
    }

    func loadHost() -> String {
        defaults.string(forKey: Keys.host) ?? "192.168.1.10"
    }

    func saveHost(_ value: String) {
        defaults.set(value, forKey: Keys.host)
    }

    func loadPort() -> Int {
        let value = defaults.integer(forKey: Keys.port)
        return value == 0 ? 81 : value
    }

    func savePort(_ value: Int) {
        defaults.set(value, forKey: Keys.port)
    }

    func loadControllerBindings() -> ControllerBindings {
        guard let data = defaults.data(forKey: Keys.controllerBindings),
              let decoded = try? JSONDecoder().decode(ControllerBindings.self, from: data) else {
            return ControllerBindings(deadzone: 0.12, sensitivity: 1.0, invertY: false)
        }
        return decoded
    }

    func saveControllerBindings(_ value: ControllerBindings) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: Keys.controllerBindings)
        }
    }

    func defaultDriveProfiles() -> [DriveProfile] {
        [
            DriveProfile(name: "Drive Slow", linearScale: 0.4, angularScale: 0.4, expo: 0.2, traction: 0.6, torque: 0.6),
            DriveProfile(name: "Drive Normal", linearScale: 0.7, angularScale: 0.7, expo: 0.4, traction: 0.8, torque: 0.8),
            DriveProfile(name: "Drive Aggressive", linearScale: 1.0, angularScale: 1.0, expo: 0.6, traction: 1.0, torque: 1.0)
        ]
    }

    func loadDriveProfiles() -> [DriveProfile] {
        guard let data = defaults.data(forKey: Keys.driveProfiles),
              let decoded = try? JSONDecoder().decode([DriveProfile].self, from: data),
              !decoded.isEmpty else {
            return defaultDriveProfiles()
        }
        return decoded
    }

    func saveDriveProfiles(_ value: [DriveProfile]) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: Keys.driveProfiles)
        }
    }

    func loadSelectedProfileName() -> String? {
        defaults.string(forKey: Keys.selectedProfileName)
    }

    func saveSelectedProfileName(_ value: String) {
        defaults.set(value, forKey: Keys.selectedProfileName)
    }

    func loadCameraConfigs() -> [CameraConfig] {
        guard let data = defaults.data(forKey: Keys.cameraConfigs),
              let decoded = try? JSONDecoder().decode([CameraConfig].self, from: data),
              decoded.count == 4 else {
            return [
                CameraConfig(name: "Cam A", url: "", isEnabled: true),
                CameraConfig(name: "Cam B", url: "", isEnabled: true),
                CameraConfig(name: "Cam C", url: "", isEnabled: false),
                CameraConfig(name: "Cam D", url: "", isEnabled: false)
            ]
        }
        return decoded
    }

    func saveCameraConfigs(_ value: [CameraConfig]) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: Keys.cameraConfigs)
        }
    }

    func loadSaveLocationBookmark() -> Data? {
        defaults.data(forKey: Keys.saveLocationBookmark)
    }

    func saveSaveLocationBookmark(_ value: Data?) {
        defaults.set(value, forKey: Keys.saveLocationBookmark)
    }
}
