import Foundation
import SceneKit

final class URDFViewModel: ObservableObject {
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

    @Published var selectedMesh: String = ""
    @Published var meshFlipX: Bool = false
    @Published var meshFlipY: Bool = false
    @Published var meshFlipZ: Bool = false
    @Published var meshSwapYZ: Bool = false

    var meshOverrides: [String: URDFMeshAxisOverride] = [:]

    private let urdfURL: URL
    private var hasInitializedCamera = false

    init(urdfURL: URL) {
        self.urdfURL = urdfURL
        loadScene(preserveCamera: false)
    }

    func loadScene(preserveCamera: Bool) {
        let resolved = urdfURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: resolved.path) else {
            loadError = "URDF not found: \(resolved.lastPathComponent)"
            scene = nil
            return
        }
        URDFLoader.unitScale = 1.0
        URDFLoader.axisRotation = SCNVector3(degToRad(rotX), degToRad(rotY), degToRad(rotZ))
        URDFLoader.flipX = flipX
        URDFLoader.flipY = flipY
        URDFLoader.flipZ = flipZ
        URDFLoader.meshOverrides = meshOverrides
        URDFLoader.highlightedMeshName = selectedMesh.isEmpty ? nil : selectedMesh

        let loaded = URDFLoader.loadScene(from: resolved)
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
        if URDFLoader.lastVisualCount == 0 {
            loadError = "No meshes loaded. Check STL paths in URDF."
        } else {
            loadError = nil
        }
    }

    func reloadScene(preserveCamera: Bool = true) {
        loadScene(preserveCamera: preserveCamera)
    }

    func setCamera(_ x: Float, _ y: Float, _ z: Float) {
        cameraPosition = SCNVector3(x, y, z)
    }

    func meshNames() -> [String] {
        let names = URDFLoader.lastResolvedMeshes.map { URL(fileURLWithPath: $0).lastPathComponent }
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
        let missing = URDFLoader.lastMissingMeshes
        let resolved = URDFLoader.lastResolvedMeshes
        let missingCount = missing.count
        let resolvedCount = resolved.count
        let sample = missing.prefix(2).map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
        let resolvedSample = resolved.prefix(1).map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
        let parseError = URDFLoader.lastParseError ?? "--"
        return "Visuals: \(URDFLoader.lastVisualCount) Joints: \(URDFLoader.lastJointCount)\nResolved: \(resolvedCount) Missing: \(missingCount)\nMissing sample: \(sample)\nResolved sample: \(resolvedSample)\nParse: \(parseError)\nURDF: \(urdfURL.lastPathComponent)"
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
        let bounds = targetNode.boundingBox
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
        let bounds = targetNode.boundingBox
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

    private func degToRad(_ value: Double) -> Float {
        Float(value * Double.pi / 180)
    }
}
