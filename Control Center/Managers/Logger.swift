import Foundation
import AppKit

final class Logger: ObservableObject {
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var saveDirectory: URL?

    private var fileHandle: FileHandle?
    private var logURL: URL?
    private var isAccessingScopedResource = false

    init(saveDirectory: URL?) {
        self.saveDirectory = saveDirectory
    }

    func updateSaveDirectory(_ url: URL?) {
        saveDirectory = url
    }

    func selectSaveDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            return panel.url
        }
        return nil
    }

    func saveSnapshot(state: AppStateSnapshot) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.saveSnapshot(state: state)
            }
            return
        }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "dashboard_snapshot_\(timestampString()).json"
        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? JSONEncoder().encode(state) {
                try? data.write(to: url)
            }
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        guard let directory = saveDirectory else { return }
        if directory.startAccessingSecurityScopedResource() {
            isAccessingScopedResource = true
        }
        let url = directory.appendingPathComponent("dashboard_log_\(timestampString()).jsonl")
        logURL = url
        FileManager.default.createFile(atPath: url.path, contents: nil)
        fileHandle = try? FileHandle(forWritingTo: url)
        isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }
        try? fileHandle?.close()
        fileHandle = nil
        isRecording = false
        if isAccessingScopedResource {
            saveDirectory?.stopAccessingSecurityScopedResource()
            isAccessingScopedResource = false
        }
    }

    func appendLine(_ line: String) {
        guard isRecording else { return }
        guard let data = (line + "\n").data(using: .utf8) else { return }
        fileHandle?.write(data)
    }

    private func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

struct AppStateSnapshot: Codable {
    var capturedAt: Date
    var connectionState: String
    var lastCommand: String
    var lastTelemetry: TelemetryMessage?
    var telemetryBuffer: [TelemetryMessage]
    var modes: [String: Bool]
    var controllerEnabled: Bool
    var driveEnabled: Bool
    var drumEnabled: Bool
    var driveProfile: String
    var cameraConfigs: [CameraConfig]
}
