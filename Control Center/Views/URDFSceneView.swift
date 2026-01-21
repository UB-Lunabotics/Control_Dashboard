import SwiftUI
import SceneKit

struct URDFSceneView: View {
    @ObservedObject var model: URDFViewModel
    @State private var showAxisTuning = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let scene = model.scene {
                    URDFSCNView(scene: scene, cameraPosition: $model.cameraPosition, cameraTarget: $model.cameraTarget)
                        .background(Color.black)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 26))
                            .foregroundStyle(DashboardTheme.accent)
                        Text(model.loadError ?? "Loading URDF...")
                            .font(.dashboardBody(11))
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                Text(model.debugInfo())
                    .font(.dashboardMono(9))
                    .foregroundStyle(DashboardTheme.textSecondary)
                    .padding(6)
                    .background(DashboardTheme.cardBackground.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(6)
            }

            HStack(spacing: 8) {
                cameraButton("Front") { model.setCamera(0, 0, 1.2) }
                cameraButton("Right") { model.setCamera(1.2, 0, 0) }
                cameraButton("Left") { model.setCamera(-1.2, 0, 0) }
                cameraButton("Top") { model.setCamera(0, 1.6, 0) }
                cameraButton("Iso") { model.setCamera(0.8, 0.9, 1.2) }
                Spacer()
                Picker("Axis Preset", selection: $model.selectedPresetName) {
                    Text("Custom").tag("Custom")
                    ForEach(URDFViewModel.axisPresets) { preset in
                        Text(preset.name).tag(preset.name)
                    }
                }
                .labelsHidden()
                .controlSize(.mini)
                .frame(width: 200)
                Button(showAxisTuning ? "Hide Axis Tuning" : "Axis Tuning") {
                    showAxisTuning.toggle()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .frame(maxWidth: .infinity)
            .onChange(of: model.selectedPresetName) { _, newValue in
                model.applyPresetByName(newValue)
            }

            if showAxisTuning {
                URDFAxisControlsView(rotX: $model.rotX, rotY: $model.rotY, rotZ: $model.rotZ, flipX: $model.flipX, flipY: $model.flipY, flipZ: $model.flipZ, scale: $model.unitScale)
                    .onChange(of: model.rotX) { _, _ in model.axisDidChange(); model.reloadScene(preserveCamera: true) }
                    .onChange(of: model.rotY) { _, _ in model.axisDidChange(); model.reloadScene(preserveCamera: true) }
                    .onChange(of: model.rotZ) { _, _ in model.axisDidChange(); model.reloadScene(preserveCamera: true) }
                    .onChange(of: model.flipX) { _, _ in model.axisDidChange(); model.reloadScene(preserveCamera: true) }
                    .onChange(of: model.flipY) { _, _ in model.axisDidChange(); model.reloadScene(preserveCamera: true) }
                    .onChange(of: model.flipZ) { _, _ in model.axisDidChange(); model.reloadScene(preserveCamera: true) }
                    .onChange(of: model.unitScale) { _, _ in model.reloadScene(preserveCamera: true) }

                URDFMeshAxisControlsView(
                    selectedMesh: $model.selectedMesh,
                    meshNames: model.meshNames(),
                    flipX: $model.meshFlipX,
                    flipY: $model.meshFlipY,
                    flipZ: $model.meshFlipZ,
                    swapYZ: $model.meshSwapYZ
                )
                .onChange(of: model.selectedMesh) { _, _ in model.updateMeshSelection() }
                .onChange(of: model.meshFlipX) { _, _ in model.updateMeshOverride() }
                .onChange(of: model.meshFlipY) { _, _ in model.updateMeshOverride() }
                .onChange(of: model.meshFlipZ) { _, _ in model.updateMeshOverride() }
                .onChange(of: model.meshSwapYZ) { _, _ in model.updateMeshOverride() }
            }
        }
    }

    private func cameraButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.mini)
    }
}

private struct URDFSCNView: NSViewRepresentable {
    let scene: SCNScene
    @Binding var cameraPosition: SCNVector3
    @Binding var cameraTarget: SCNVector3

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .black
        context.coordinator.ensureCamera(in: view)
        return view
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        nsView.scene = scene
        context.coordinator.ensureCamera(in: nsView)
        let bindingPosition = cameraPosition
        let bindingTarget = cameraTarget

        if context.coordinator.needsCameraUpdate || context.coordinator.bindingDidChange(position: bindingPosition, target: bindingTarget) {
            context.coordinator.applyCamera(position: bindingPosition, target: bindingTarget)
            context.coordinator.markBinding(position: bindingPosition, target: bindingTarget)
            context.coordinator.needsCameraUpdate = false
            return
        }

        if let current = context.coordinator.currentCameraState(in: nsView),
           !context.coordinator.approxEqual(current.position, bindingPosition) ||
            !context.coordinator.approxEqual(current.target, bindingTarget) {
            DispatchQueue.main.async {
                cameraPosition = current.position
                cameraTarget = current.target
            }
            context.coordinator.markBinding(position: current.position, target: current.target)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private let cameraNode = SCNNode()
        var needsCameraUpdate = false
        private var lastBindingPosition: SCNVector3? = nil
        private var lastBindingTarget: SCNVector3? = nil
        private weak var lastScene: SCNScene? = nil

        init() {
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.zNear = 0.001
            cameraNode.camera?.zFar = 100000
        }

        func ensureCamera(in view: SCNView) {
            if view.scene !== lastScene {
                cameraNode.removeFromParentNode()
                view.scene?.rootNode.addChildNode(cameraNode)
                view.pointOfView = cameraNode
                lastScene = view.scene
                needsCameraUpdate = true
                return
            }

            if cameraNode.parent == nil {
                view.scene?.rootNode.addChildNode(cameraNode)
                view.pointOfView = cameraNode
                lastScene = view.scene
                needsCameraUpdate = true
            }
        }

        func applyCamera(position: SCNVector3, target: SCNVector3) {
            cameraNode.position = position
            cameraNode.look(at: target)
        }

        func currentCameraState(in view: SCNView) -> (position: SCNVector3, target: SCNVector3)? {
            guard let pov = view.pointOfView else { return nil }
            let position = pov.presentation.position
            let front = pov.presentation.worldFront
            let target = SCNVector3(position.x + front.x, position.y + front.y, position.z + front.z)
            return (position, target)
        }

        func markBinding(position: SCNVector3, target: SCNVector3) {
            lastBindingPosition = position
            lastBindingTarget = target
        }

        func bindingDidChange(position: SCNVector3, target: SCNVector3) -> Bool {
            guard let lastPos = lastBindingPosition, let lastTarget = lastBindingTarget else {
                return true
            }
            return !approxEqual(position, lastPos) || !approxEqual(target, lastTarget)
        }

        func approxEqual(_ lhs: SCNVector3, _ rhs: SCNVector3, epsilon: CGFloat = 0.0001) -> Bool {
            abs(lhs.x - rhs.x) < epsilon &&
            abs(lhs.y - rhs.y) < epsilon &&
            abs(lhs.z - rhs.z) < epsilon
        }

    }
}
