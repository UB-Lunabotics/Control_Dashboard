import Foundation
import SceneKit
import ModelIO

struct URDFTransform {
    var position: SCNVector3
    var rpy: SCNVector3

    static let identity = URDFTransform(position: SCNVector3Zero, rpy: SCNVector3Zero)
}

struct URDFLinkVisual {
    var link: String
    var meshPath: String
    var origin: URDFTransform
    var scale: SCNVector3
}

struct URDFJoint {
    var parent: String
    var child: String
    var origin: URDFTransform
}

struct URDFMeshAxisOverride: Equatable {
    var flipX: Bool
    var flipY: Bool
    var flipZ: Bool
    var swapYZ: Bool

    static let none = URDFMeshAxisOverride(flipX: false, flipY: false, flipZ: false, swapYZ: false)
}

final class URDFLoader: NSObject, XMLParserDelegate {
    private var visuals: [URDFLinkVisual] = []
    private var joints: [URDFJoint] = []
    private var links: Set<String> = []
    static private(set) var lastMissingMeshes: [String] = []
    static private(set) var lastResolvedMeshes: [String] = []
    static private(set) var lastVisualCount: Int = 0
    static private(set) var lastJointCount: Int = 0
    static private(set) var lastParseError: String? = nil
    static var unitScale: Float = 1.0
    static var axisRotation = SCNVector3(Float(-Double.pi / 2), 0, 0)
    static var flipX = false
    static var flipY = false
    static var flipZ = false
    static var meshOverrides: [String: URDFMeshAxisOverride] = [:]
    static var highlightedMeshName: String? = nil

    private var currentLink: String = ""
    private var currentVisualOrigin: URDFTransform = .identity
    private var currentVisualScale = SCNVector3(1, 1, 1)
    private var currentJointOrigin: URDFTransform = .identity
    private var currentJointParent: String = ""
    private var currentJointChild: String = ""

    private var inVisual = false
    private var inJoint = false

    static func loadScene(from url: URL) -> SCNScene {
        let loader = URDFLoader()
        lastParseError = nil
        lastVisualCount = 0
        lastJointCount = 0
        guard let parser = XMLParser(contentsOf: url) else {
            lastParseError = "Failed to open URDF at \(url.path)"
            return SCNScene()
        }
        parser.delegate = loader
        parser.parse()
        lastParseError = parser.parserError?.localizedDescription
        lastVisualCount = loader.visuals.count
        lastJointCount = loader.joints.count

        let baseURL = url.deletingLastPathComponent()
        lastMissingMeshes = []
        lastResolvedMeshes = []
        let scene = SCNScene()
        let modelRoot = SCNNode()
        modelRoot.name = "URDFModelRoot"
        modelRoot.transform = URDFLoader.makeRootTransform()
        scene.rootNode.addChildNode(modelRoot)

        let linkNodes = loader.buildLinkNodes()
        loader.applyJointHierarchy(linkNodes: linkNodes)

        let roots = loader.rootLinks()
        for root in roots {
            if let node = linkNodes[root] {
                modelRoot.addChildNode(node)
            }
        }

        for visual in loader.visuals {
            let meshURL = loader.resolveMeshURL(meshPath: visual.meshPath, baseURL: baseURL)
            guard let meshNode = loader.loadMeshNode(from: meshURL, baseURL: baseURL) else { continue }
            meshNode.transform = loader.transformMatrix(visual.origin)
            if let override = URDFLoader.meshOverrides[meshURL.lastPathComponent] {
                meshNode.transform = SCNMatrix4Mult(meshNode.transform, loader.meshOverrideTransform(override))
            }
            meshNode.scale = visual.scale
            if URDFLoader.highlightedMeshName == meshURL.lastPathComponent {
                loader.applyHighlightMaterial(to: meshNode)
            } else {
                loader.applyDefaultMaterial(to: meshNode)
            }
            if let linkNode = linkNodes[visual.link] {
                linkNode.addChildNode(meshNode)
            } else {
                modelRoot.addChildNode(meshNode)
            }
        }

        return scene
    }

    private func resolveMeshURL(meshPath: String, baseURL: URL) -> URL {
        if meshPath.hasPrefix("package://") {
            let trimmed = meshPath.replacingOccurrences(of: "package://", with: "")
            let resolved = baseURL.appendingPathComponent(trimmed)
            print("[URDFLoader] Resolve mesh: \(meshPath) -> \(resolved.path)")
            URDFLoader.lastResolvedMeshes.append(resolved.path)
            return resolved
        }
        let resolved = baseURL.appendingPathComponent(meshPath)
        print("[URDFLoader] Resolve mesh: \(meshPath) -> \(resolved.path)")
        URDFLoader.lastResolvedMeshes.append(resolved.path)
        return resolved
    }

    private func loadMeshNode(from url: URL, baseURL: URL) -> SCNNode? {
        let resolved = url.standardizedFileURL
        var candidate = resolved
        if !FileManager.default.fileExists(atPath: candidate.path) {
            let fallbackA = baseURL.deletingLastPathComponent().appendingPathComponent("meshes").appendingPathComponent(resolved.lastPathComponent)
            let fallbackB = Bundle.main.resourceURL?.appendingPathComponent("meshes").appendingPathComponent(resolved.lastPathComponent)
            if FileManager.default.fileExists(atPath: fallbackA.path) {
                candidate = fallbackA
            } else if let fallbackB, FileManager.default.fileExists(atPath: fallbackB.path) {
                candidate = fallbackB
            } else {
                print("[URDFLoader] Missing mesh: \(resolved.path)")
                URDFLoader.lastMissingMeshes.append(resolved.path)
                return nil
            }
        }

        let source = SCNSceneSource(url: candidate, options: nil)
        guard let scene = source?.scene(options: nil) else { return nil }
        let container = SCNNode()
        for child in scene.rootNode.childNodes {
            container.addChildNode(child)
        }
        applyDefaultMaterial(to: container)
        return container.childNodes.isEmpty ? nil : container
    }

    private func applyDefaultMaterial(to node: SCNNode) {
        if let geometry = node.geometry {
            let material = SCNMaterial()
            material.diffuse.contents = NSColor(calibratedWhite: 0.85, alpha: 1.0)
            material.lightingModel = .physicallyBased
            geometry.materials = [material]
        }
        for child in node.childNodes {
            applyDefaultMaterial(to: child)
        }
    }

    private func applyHighlightMaterial(to node: SCNNode) {
        if let geometry = node.geometry {
            let material = SCNMaterial()
            material.diffuse.contents = NSColor.systemYellow
            material.emission.contents = NSColor.systemOrange
            material.lightingModel = .physicallyBased
            geometry.materials = [material]
        }
        for child in node.childNodes {
            applyHighlightMaterial(to: child)
        }
    }

    private func buildLinkNodes() -> [String: SCNNode] {
        var nodes: [String: SCNNode] = [:]
        for link in links {
            nodes[link] = SCNNode()
        }
        for joint in joints {
            if nodes[joint.parent] == nil {
                nodes[joint.parent] = SCNNode()
            }
            if nodes[joint.child] == nil {
                nodes[joint.child] = SCNNode()
            }
        }
        return nodes
    }

    private func applyJointHierarchy(linkNodes: [String: SCNNode]) {
        for joint in joints {
            guard let parent = linkNodes[joint.parent],
                  let child = linkNodes[joint.child] else { continue }
            child.transform = transformMatrix(joint.origin)
            if child.parent == nil {
                parent.addChildNode(child)
            }
        }
    }

    private func rootLinks() -> [String] {
        let parents = Set(joints.map { $0.parent })
        let children = Set(joints.map { $0.child })
        let roots = parents.subtracting(children)
        if !roots.isEmpty {
            return Array(roots)
        }
        return Array(links)
    }

    private func transformMatrix(_ transform: URDFTransform) -> SCNMatrix4 {
        let scale = CGFloat(URDFLoader.unitScale)
        let translation = SCNMatrix4MakeTranslation(
            transform.position.x * scale,
            transform.position.y * scale,
            transform.position.z * scale
        )
        let rx = SCNMatrix4MakeRotation(transform.rpy.x, 1, 0, 0)
        let ry = SCNMatrix4MakeRotation(transform.rpy.y, 0, 1, 0)
        let rz = SCNMatrix4MakeRotation(transform.rpy.z, 0, 0, 1)
        let rotation = SCNMatrix4Mult(SCNMatrix4Mult(rz, ry), rx)
        return SCNMatrix4Mult(translation, rotation)
    }

    private static func makeRootTransform() -> SCNMatrix4 {
        let rot = URDFLoader.axisRotation
        let rx = SCNMatrix4MakeRotation(rot.x, 1, 0, 0)
        let ry = SCNMatrix4MakeRotation(rot.y, 0, 1, 0)
        let rz = SCNMatrix4MakeRotation(rot.z, 0, 0, 1)
        var transform = SCNMatrix4Mult(SCNMatrix4Mult(rz, ry), rx)

        let sx: CGFloat = URDFLoader.flipX ? -1 : 1
        let sy: CGFloat = URDFLoader.flipY ? -1 : 1
        let sz: CGFloat = URDFLoader.flipZ ? -1 : 1
        let scale = SCNMatrix4MakeScale(sx, sy, sz)
        transform = SCNMatrix4Mult(transform, scale)
        return transform
    }

    private func meshOverrideTransform(_ override: URDFMeshAxisOverride) -> SCNMatrix4 {
        var transform = SCNMatrix4Identity
        if override.swapYZ {
        let rotateX = SCNMatrix4MakeRotation(CGFloat(Float(Double.pi / 2)), 1, 0, 0)
            transform = SCNMatrix4Mult(transform, rotateX)
        }

        let sx: CGFloat = override.flipX ? -1 : 1
        let sy: CGFloat = override.flipY ? -1 : 1
        let sz: CGFloat = override.flipZ ? -1 : 1
        let scale = SCNMatrix4MakeScale(sx, sy, sz)
        transform = SCNMatrix4Mult(transform, scale)
        return transform
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        switch elementName {
        case "link":
            currentLink = attributeDict["name"] ?? currentLink
            links.insert(currentLink)
        case "visual":
            inVisual = true
            currentVisualOrigin = .identity
            currentVisualScale = SCNVector3(1, 1, 1)
        case "joint":
            inJoint = true
            currentJointOrigin = .identity
            currentJointParent = ""
            currentJointChild = ""
        case "origin":
            let origin = parseOrigin(attributes: attributeDict)
            if inVisual {
                currentVisualOrigin = origin
            } else if inJoint {
                currentJointOrigin = origin
            }
        case "mesh":
            if inVisual, let filename = attributeDict["filename"] {
                let scale = parseScale(attributeDict["scale"])
                visuals.append(URDFLinkVisual(link: currentLink, meshPath: filename, origin: currentVisualOrigin, scale: scale))
            }
        case "parent":
            if inJoint {
                currentJointParent = attributeDict["link"] ?? currentJointParent
            }
        case "child":
            if inJoint {
                currentJointChild = attributeDict["link"] ?? currentJointChild
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "visual":
            inVisual = false
        case "joint":
            inJoint = false
            if !currentJointParent.isEmpty, !currentJointChild.isEmpty {
                joints.append(URDFJoint(parent: currentJointParent, child: currentJointChild, origin: currentJointOrigin))
            }
        default:
            break
        }
    }

    private func parseOrigin(attributes: [String: String]) -> URDFTransform {
        let xyz = parseVector(attributes["xyz"])
        let rpy = parseVector(attributes["rpy"])
        return URDFTransform(position: xyz, rpy: rpy)
    }

    private func parseScale(_ value: String?) -> SCNVector3 {
        guard let value else { return SCNVector3(1, 1, 1) }
        let parts = value.split(separator: " ").map { Double($0) ?? 1 }
        if parts.count == 3 {
            return SCNVector3(parts[0], parts[1], parts[2])
        }
        return SCNVector3(1, 1, 1)
    }

    private func parseVector(_ value: String?) -> SCNVector3 {
        guard let value else { return SCNVector3Zero }
        let parts = value.split(separator: " ").map { Double($0) ?? 0 }
        if parts.count == 3 {
            return SCNVector3(parts[0], parts[1], parts[2])
        }
        return SCNVector3Zero
    }
}
