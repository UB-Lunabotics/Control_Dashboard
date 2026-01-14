import SwiftUI

struct DebugPanelCard: View {
    @ObservedObject var state: AppState

    var body: some View {
        CardView(title: "Debug Panel") {
            VStack(alignment: .leading, spacing: 6) {
                Button("Reset Everything") {
                    state.sendStopAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
    }
}
