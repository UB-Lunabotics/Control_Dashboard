import SwiftUI

struct URDFSimulatorCard: View {
    @StateObject private var model: URDFViewModel
    @State private var showFullscreen = false

    init() {
        _model = StateObject(wrappedValue: URDFViewModel(modelURL: Self.defaultModelURL()))
    }

    var body: some View {
        CardView(title: "Rover Sim (CSV)") {
            Group {
                if showFullscreen {
                    ZStack {
                        Color.black
                        Text("Fullscreen active")
                            .font(.dashboardBody(11))
                            .foregroundStyle(DashboardTheme.textSecondary)
                    }
                } else {
                    URDFSceneView(model: model)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DashboardTheme.cardBorder.opacity(0.4), lineWidth: 1)
            )
        }
        .overlay(alignment: .topTrailing) {
            Button("Expand") { showFullscreen = true }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .padding(.trailing, 8)
                .padding(.top, 6)
        }
        .sheet(isPresented: $showFullscreen) {
            URDFFullscreenView(model: model, isPresented: $showFullscreen)
        }
    }

    private static func defaultModelURL() -> URL {
        if let bundled = Bundle.main.url(forResource: "Assem1", withExtension: "csv", subdirectory: "urdf") {
            return bundled
        }
        return URL(fileURLWithPath: "/Users/sujalbhakare/Projects/Lunabotics/Control Center/urdf/Assem1.csv")
    }
}

private struct URDFFullscreenView: View {
    @ObservedObject var model: URDFViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            URDFSceneView(model: model)
                .padding(16)
            Button("Close") { isPresented = false }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut(.cancelAction)
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
