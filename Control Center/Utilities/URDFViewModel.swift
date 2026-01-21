import Foundation
import SceneKit

final class URDFViewModel: ObservableObject {
    struct AxisPreset: Identifiable {
        let id = UUID()
        let name: String
        let rotX: Double
        let rotY: Double
        let rotZ: Double
        let flipX: Bool
        let flipY: Bool
        let flipZ: Bool
    }

    private let settings = SettingsStore.shared

    static let axisPresets: [AxisPreset] = [
        AxisPreset(name: "SceneKit Default", rotX: 0, rotY: 0, rotZ: 0, flipX: false, flipY: false, flipZ: false),
        AxisPreset(name: "ROS (Z-up) -> SceneKit", rotX: -90, rotY: 0, rotZ: 0, flipX: false, flipY: false, flipZ: false),
        AxisPreset(name: "ROS (Z-up) + Flip Z", rotX: -90, rotY: 0, rotZ: 0, flipX: false, flipY: false, flipZ: true),
        AxisPreset(name: "ROS (Z-up) + Flip Y", rotX: -90, rotY: 0, rotZ: 0, flipX: false, flipY: true, flipZ: false),
        AxisPreset(name: "ROS (Z-up) + Rotate 180Z", rotX: -90, rotY: 0, rotZ: 180, flipX: false, flipY: false, flipZ: false)
    ]

    @Published var scene: SCNScene? = nil
    @Published var loadError: String? = nil
    @Published var cameraPosition = SCNVector3(0.8, 0.9, 1.2)
    @Published var cameraTarget = SCNVector3Zero

    @Published var rotX: Double = -90
    @Published var rotY: Double = 0
    @Published var rotZ: Double = 0
    @Published var flipX: Bool = false
    @Published var flipY: Bool = false
    @Published var flipZ: Bool = false
    @Published var selectedPresetName: String = "Custom"
    @Published var unitScale: Double = 1.0

    @Published var selectedMesh: String = ""
    @Published var meshFlipX: Bool = false
    @Published var meshFlipY: Bool = false
    @Published var meshFlipZ: Bool = false
    @Published var meshSwapYZ: Bool = false

    var meshOverrides: [String: URDFMeshAxisOverride] = [:]

    private let modelURL: URL
    private var hasInitializedCamera = false

    init(modelURL: URL) {
        self.modelURL = modelURL
        let savedPreset = settings.loadURDFAxisPreset()
        if let savedPreset,
           let preset = Self.axisPresets.first(where: { $0.name == savedPreset }) {
            applyPreset(preset)
            selectedPresetName = preset.name
        } else {
            let overrides = settings.loadURDFAxisOverrides()
            rotX = overrides.rotX
            rotY = overrides.rotY
            rotZ = overrides.rotZ
            flipX = overrides.flipX
            flipY = overrides.flipY
            flipZ = overrides.flipZ
            selectedPresetName = savedPreset ?? "Custom"
        }
        loadScene(preserveCamera: false)
    }

    func loadScene(preserveCamera: Bool) {
        let resolved = modelURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: resolved.path) else {
            loadError = "Model CSV not found: \(resolved.lastPathComponent)"
            scene = nil
            return
        }
        CSVRobotLoader.unitScale = Float(unitScale)
        CSVRobotLoader.axisRotation = SCNVector3(degToRad(rotX), degToRad(rotY), degToRad(rotZ))
        CSVRobotLoader.flipX = flipX
        CSVRobotLoader.flipY = flipY
        CSVRobotLoader.flipZ = flipZ
        CSVRobotLoader.meshOverrides = meshOverrides
        CSVRobotLoader.highlightedMeshName = selectedMesh.isEmpty ? nil : selectedMesh

        let loaded = CSVRobotLoader.loadScene(from: resolved)
        loaded.background.contents = NSColor.black
        addLights(to: loaded)
        normalizeScene(loaded)
        let (center, distance) = fitCameraToScene(loaded)

        if !preserveCamera || !hasInitializedCamera {
            cameraTarget = center
            let distanceY = distance * Float(0.6)
            let cx = Float(center.x) + distance
            let cy = Float(center.y) + distanceY
            let cz = Float(center.z) + distance
            cameraPosition = SCNVector3(cx, cy, cz)
            hasInitializedCamera = true
        }

        if loaded.rootNode.childNodes.isEmpty {
            let fallback = SCNBox(width: 0.4, height: 0.2, length: 0.6, chamferRadius: 0.02)
            fallback.firstMaterial?.diffuse.contents = NSColor.systemRed
            let fallbackNode = SCNNode(geometry: fallback)
            loaded.rootNode.addChildNode(fallbackNode)
        }

        scene = loaded
        if CSVRobotLoader.lastVisualCount == 0 {
            loadError = "No meshes loaded. Check STL paths in CSV."
        } else {
            loadError = nil
        }
    }

    func reloadScene(preserveCamera: Bool = true) {
        loadScene(preserveCamera: preserveCamera)
    }

    func applyPresetByName(_ name: String) {
        if name == "Custom" {
            selectedPresetName = "Custom"
            saveAxisOverrides()
            reloadScene(preserveCamera: true)
            return
        }
        guard let preset = Self.axisPresets.first(where: { $0.name == name }) else { return }
        applyPreset(preset)
        selectedPresetName = preset.name
        settings.saveURDFAxisPreset(preset.name)
        saveAxisOverrides()
        reloadScene(preserveCamera: true)
    }

    func axisDidChange() {
        if selectedPresetName != "Custom" {
            selectedPresetName = "Custom"
            settings.saveURDFAxisPreset("Custom")
        }
        saveAxisOverrides()
    }

    func setCamera(_ x: Float, _ y: Float, _ z: Float) {
        cameraPosition = SCNVector3(x, y, z)
    }

    func meshNames() -> [String] {
        let names = CSVRobotLoader.lastResolvedMeshes.map { URL(fileURLWithPath: $0).lastPathComponent }
        return Array(Set(names)).sorted()
    }

    func updateMeshSelection() {
        guard !selectedMesh.isEmpty else { return }
        let override = meshOverrides[selectedMesh] ?? .none
        meshFlipX = override.flipX
        meshFlipY = override.flipY
        meshFlipZ = override.flipZ
        meshSwapYZ = override.swapYZ
        reloadScene(preserveCamera: true)
    }

    func updateMeshOverride() {
        guard !selectedMesh.isEmpty else { return }
        meshOverrides[selectedMesh] = URDFMeshAxisOverride(
            flipX: meshFlipX,
            flipY: meshFlipY,
            flipZ: meshFlipZ,
            swapYZ: meshSwapYZ
        )
        reloadScene(preserveCamera: true)
    }

    func debugInfo() -> String {
        let missing = CSVRobotLoader.lastMissingMeshes
        let resolved = CSVRobotLoader.lastResolvedMeshes
        let missingCount = missing.count
        let resolvedCount = resolved.count
        let sample = missing.prefix(2).map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
        let resolvedSample = resolved.prefix(1).map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
        let parseError = CSVRobotLoader.lastParseError ?? "--"
        return "Visuals: \(CSVRobotLoader.lastVisualCount) Joints: \(CSVRobotLoader.lastJointCount)\nResolved: \(resolvedCount) Missing: \(missingCount)\nMissing sample: \(sample)\nResolved sample: \(resolvedSample)\nParse: \(parseError)\nCSV: \(modelURL.lastPathComponent)"
    }

    private func addLights(to scene: SCNScene) {
        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(2, 3, 4)
        scene.rootNode.addChildNode(lightNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 500
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
    }

    private func fitCameraToScene(_ scene: SCNScene) -> (SCNVector3, Float) {
        let targetNode = scene.rootNode.childNode(withName: "URDFModelRoot", recursively: false) ?? scene.rootNode
        let bounds = computeBounds(in: targetNode) ?? targetNode.boundingBox
        let minVec = bounds.min
        let maxVec = bounds.max
        let minX = Float(minVec.x)
        let minY = Float(minVec.y)
        let minZ = Float(minVec.z)
        let maxX = Float(maxVec.x)
        let maxY = Float(maxVec.y)
        let maxZ = Float(maxVec.z)
        let center = SCNVector3((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
        let sizeX = maxX - minX
        let sizeY = maxY - minY
        let sizeZ = maxZ - minZ
        let radius = max(sizeX, max(sizeY, sizeZ))
        let distance = max(Float(1.0), radius * Float(2.5))
        return (center, distance)
    }

    private func normalizeScene(_ scene: SCNScene) {
        let targetNode = scene.rootNode.childNode(withName: "URDFModelRoot", recursively: false) ?? scene.rootNode
        let bounds = computeBounds(in: targetNode) ?? targetNode.boundingBox
        let minVec = bounds.min
        let maxVec = bounds.max
        let minX = Float(minVec.x)
        let minY = Float(minVec.y)
        let minZ = Float(minVec.z)
        let maxX = Float(maxVec.x)
        let maxY = Float(maxVec.y)
        let maxZ = Float(maxVec.z)
        let sizeX = maxX - minX
        let sizeY = maxY - minY
        let sizeZ = maxZ - minZ
        let maxDim = max(sizeX, max(sizeY, sizeZ))
        guard maxDim > 0.0001 else { return }

        let center = SCNVector3((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
        let scale = Float(1.0) / maxDim
        targetNode.scale = SCNVector3(scale, scale, scale)
//        targetNode.position = SCNVector3(-Float(center.x) * CGFloat(scale), -Float(center.y) * CGFloat(scale), -Float(center.z) * CGFloat(scale))
        let s = Float(scale)

        let x = -Float(center.x) * s
        let y = -Float(center.y) * s
        let z = -Float(center.z) * s

        targetNode.position = SCNVector3(x, y, z)

    }

    private func computeBounds(in root: SCNNode) -> (min: SCNVector3, max: SCNVector3)? {
        var minV = SCNVector3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var maxV = SCNVector3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
        var found = false

        root.enumerateChildNodes { node, _ in
            guard node.geometry != nil else { return }
            let bounds = node.boundingBox
            let corners = [
                SCNVector3(bounds.min.x, bounds.min.y, bounds.min.z),
                SCNVector3(bounds.min.x, bounds.min.y, bounds.max.z),
                SCNVector3(bounds.min.x, bounds.max.y, bounds.min.z),
                SCNVector3(bounds.min.x, bounds.max.y, bounds.max.z),
                SCNVector3(bounds.max.x, bounds.min.y, bounds.min.z),
                SCNVector3(bounds.max.x, bounds.min.y, bounds.max.z),
                SCNVector3(bounds.max.x, bounds.max.y, bounds.min.z),
                SCNVector3(bounds.max.x, bounds.max.y, bounds.max.z)
            ]
            for corner in corners {
                let local = node.convertPosition(corner, to: root)
                minV = SCNVector3(min(minV.x, local.x), min(minV.y, local.y), min(minV.z, local.z))
                maxV = SCNVector3(max(maxV.x, local.x), max(maxV.y, local.y), max(maxV.z, local.z))
            }
            found = true
        }

        return found ? (minV, maxV) : nil
    }

    private func degToRad(_ value: Double) -> Float {
        Float(value * Double.pi / 180)
    }

    private func applyPreset(_ preset: AxisPreset) {
        rotX = preset.rotX
        rotY = preset.rotY
        rotZ = preset.rotZ
        flipX = preset.flipX
        flipY = preset.flipY
        flipZ = preset.flipZ
    }

    private func saveAxisOverrides() {
        settings.saveURDFAxisOverrides(
            rotX: rotX,
            rotY: rotY,
            rotZ: rotZ,
            flipX: flipX,
            flipY: flipY,
            flipZ: flipZ
        )
    }
}
