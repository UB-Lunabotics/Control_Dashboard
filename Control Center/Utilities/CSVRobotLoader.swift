import Foundation
import SceneKit

struct CSVLinkVisual {
    var link: String
    var meshPath: String
    var origin: URDFTransform
    var color: NSColor?
}

struct CSVJoint {
    var parent: String
    var child: String
    var origin: URDFTransform
}

final class CSVRobotLoader {
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

    static func loadScene(from url: URL) -> SCNScene {
        lastParseError = nil
        lastVisualCount = 0
        lastJointCount = 0
        lastMissingMeshes = []
        lastResolvedMeshes = []

        let scene = SCNScene()
        let modelRoot = SCNNode()
        modelRoot.name = "URDFModelRoot"
        modelRoot.transform = makeRootTransform()
        scene.rootNode.addChildNode(modelRoot)

        guard let csv = try? String(contentsOf: url, encoding: .utf8) else {
            lastParseError = "Failed to read CSV at \(url.path)"
            return scene
        }

        let normalized = csv.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let rows = parseCSV(normalized)
        guard rows.count >= 2 else {
            lastParseError = "CSV missing header or rows"
            return scene
        }

        let header = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var index: [String: Int] = [:]
        for (i, name) in header.enumerated() {
            index[name] = i
        }

        var links = Set<String>()
        var visuals: [CSVLinkVisual] = []
        var joints: [CSVJoint] = []

        for row in rows.dropFirst() {
            let linkName = value(in: row, index: index, key: "Link Name")
            guard let linkName, !linkName.isEmpty else { continue }
            links.insert(linkName)

            if let meshPath = value(in: row, index: index, key: "Mesh Filename"), !meshPath.isEmpty {
                let origin = parseOrigin(
                    row: row,
                    index: index,
                    xKey: "Visual X",
                    yKey: "Visual Y",
                    zKey: "Visual Z",
                    rollKey: "Visual Roll",
                    pitchKey: "Visual Pitch",
                    yawKey: "Visual Yaw"
                )
                let color = parseColor(row: row, index: index)
                visuals.append(CSVLinkVisual(link: linkName, meshPath: meshPath, origin: origin, color: color))
            }

            if let parent = value(in: row, index: index, key: "Parent"), !parent.isEmpty {
                let jointOrigin = parseOrigin(
                    row: row,
                    index: index,
                    xKey: "Joint Origin X",
                    yKey: "Joint Origin Y",
                    zKey: "Joint Origin Z",
                    rollKey: "Joint Origin Roll",
                    pitchKey: "Joint Origin Pitch",
                    yawKey: "Joint Origin Yaw"
                )
                joints.append(CSVJoint(parent: parent, child: linkName, origin: jointOrigin))
            }
        }

        lastVisualCount = visuals.count
        lastJointCount = joints.count

        let baseURL = url.deletingLastPathComponent()
        let linkNodes = buildLinkNodes(links: links, joints: joints)
        applyJointHierarchy(linkNodes: linkNodes, joints: joints)

        let roots = rootLinks(links: links, joints: joints)
        for root in roots {
            if let node = linkNodes[root] {
                modelRoot.addChildNode(node)
            }
        }

        for visual in visuals {
            let meshURL = resolveMeshURL(meshPath: visual.meshPath, baseURL: baseURL)
            guard let meshNode = loadMeshNode(from: meshURL, baseURL: baseURL) else { continue }
            meshNode.transform = transformMatrix(visual.origin)
            if let override = meshOverrides[meshURL.lastPathComponent] {
                meshNode.transform = SCNMatrix4Mult(meshNode.transform, meshOverrideTransform(override))
            }
            if highlightedMeshName == meshURL.lastPathComponent {
                applyHighlightMaterial(to: meshNode)
            } else {
                applyDefaultMaterial(to: meshNode, color: visual.color)
            }
            if let linkNode = linkNodes[visual.link] {
                linkNode.addChildNode(meshNode)
            } else {
                modelRoot.addChildNode(meshNode)
            }
        }

        return scene
    }

    private static func parseCSV(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false

        for char in csv {
            if char == "\"" {
                inQuotes.toggle()
                continue
            }
            if char == "," && !inQuotes {
                currentRow.append(currentField)
                currentField = ""
                continue
            }
            if char == "\n" && !inQuotes {
                currentRow.append(currentField)
                if !currentRow.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    rows.append(currentRow)
                }
                currentRow = []
                currentField = ""
                continue
            }
            currentField.append(char)
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }

    private static func value(in row: [String], index: [String: Int], key: String) -> String? {
        guard let idx = index[key], idx < row.count else { return nil }
        let value = row[idx].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private static func parseDouble(_ value: String?) -> Double {
        guard let value else { return 0 }
        return Double(value) ?? 0
    }

    private static func parseOrigin(
        row: [String],
        index: [String: Int],
        xKey: String,
        yKey: String,
        zKey: String,
        rollKey: String,
        pitchKey: String,
        yawKey: String
    ) -> URDFTransform {
        let x = parseDouble(value(in: row, index: index, key: xKey))
        let y = parseDouble(value(in: row, index: index, key: yKey))
        let z = parseDouble(value(in: row, index: index, key: zKey))
        let roll = parseDouble(value(in: row, index: index, key: rollKey))
        let pitch = parseDouble(value(in: row, index: index, key: pitchKey))
        let yaw = parseDouble(value(in: row, index: index, key: yawKey))
        return URDFTransform(position: SCNVector3(x, y, z), rpy: SCNVector3(roll, pitch, yaw))
    }

    private static func parseColor(row: [String], index: [String: Int]) -> NSColor? {
        guard let rString = value(in: row, index: index, key: "Color Red"),
              let gString = value(in: row, index: index, key: "Color Green"),
              let bString = value(in: row, index: index, key: "Color Blue") else { return nil }
        let aString = value(in: row, index: index, key: "Color Alpha") ?? "1"
        let r = CGFloat(parseDouble(rString))
        let g = CGFloat(parseDouble(gString))
        let b = CGFloat(parseDouble(bString))
        let a = CGFloat(parseDouble(aString))
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
    }

    private static func buildLinkNodes(links: Set<String>, joints: [CSVJoint]) -> [String: SCNNode] {
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

    private static func applyJointHierarchy(linkNodes: [String: SCNNode], joints: [CSVJoint]) {
        for joint in joints {
            guard let parent = linkNodes[joint.parent],
                  let child = linkNodes[joint.child] else { continue }
            child.transform = transformMatrix(joint.origin)
            if child.parent == nil {
                parent.addChildNode(child)
            }
        }
    }

    private static func rootLinks(links: Set<String>, joints: [CSVJoint]) -> [String] {
        let parents = Set(joints.map { $0.parent })
        let children = Set(joints.map { $0.child })
        let roots = parents.subtracting(children)
        if !roots.isEmpty {
            return Array(roots)
        }
        return Array(links)
    }

    private static func resolveMeshURL(meshPath: String, baseURL: URL) -> URL {
        if meshPath.hasPrefix("package://") {
            let trimmed = meshPath.replacingOccurrences(of: "package://", with: "")
            let resolved = baseURL.appendingPathComponent(trimmed)
            lastResolvedMeshes.append(resolved.path)
            return resolved
        }
        let resolved = baseURL.appendingPathComponent(meshPath)
        lastResolvedMeshes.append(resolved.path)
        return resolved
    }

    private static func loadMeshNode(from url: URL, baseURL: URL) -> SCNNode? {
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
                lastMissingMeshes.append(resolved.path)
                return nil
            }
        }

        let source = SCNSceneSource(url: candidate, options: nil)
        guard let scene = source?.scene(options: nil) else { return nil }
        let container = SCNNode()
        for child in scene.rootNode.childNodes {
            container.addChildNode(child)
        }
        return container.childNodes.isEmpty ? nil : container
    }

    private static func applyDefaultMaterial(to node: SCNNode, color: NSColor?) {
        if let geometry = node.geometry {
            let material = SCNMaterial()
            material.diffuse.contents = color ?? NSColor(calibratedWhite: 0.85, alpha: 1.0)
            material.lightingModel = .physicallyBased
            geometry.materials = [material]
        }
        for child in node.childNodes {
            applyDefaultMaterial(to: child, color: color)
        }
    }

    private static func applyHighlightMaterial(to node: SCNNode) {
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

    private static func transformMatrix(_ transform: URDFTransform) -> SCNMatrix4 {
        let scale = CGFloat(unitScale)
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
        let rot = axisRotation
        let rx = SCNMatrix4MakeRotation(rot.x, 1, 0, 0)
        let ry = SCNMatrix4MakeRotation(rot.y, 0, 1, 0)
        let rz = SCNMatrix4MakeRotation(rot.z, 0, 0, 1)
        var transform = SCNMatrix4Mult(SCNMatrix4Mult(rz, ry), rx)

        let sx: CGFloat = flipX ? -1 : 1
        let sy: CGFloat = flipY ? -1 : 1
        let sz: CGFloat = flipZ ? -1 : 1
        let scale = SCNMatrix4MakeScale(sx, sy, sz)
        transform = SCNMatrix4Mult(transform, scale)
        return transform
    }

    private static func meshOverrideTransform(_ override: URDFMeshAxisOverride) -> SCNMatrix4 {
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
}
