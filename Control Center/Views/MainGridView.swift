import SwiftUI

struct MainGridView: View {
    @ObservedObject var state: AppState

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 16
            let rows: CGFloat = 3
            let rowHeight = (proxy.size.height - spacing * (rows - 1)) / rows

            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    URDFSimulatorCard()
                        .frame(maxHeight: .infinity)
                    CameraPanelCard(state: state)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: rowHeight)

                HStack(spacing: spacing) {
                    ControllerVisualizationCard(state: state)
                        .frame(maxHeight: .infinity)
                    DriveControlCard(state: state)
                        .frame(maxHeight: .infinity)
                }
                .frame(height: rowHeight)

                HStack(spacing: spacing) {
                    DrumControlCard(state: state)
                        .frame(maxHeight: .infinity)
                    VStack(spacing: spacing) {
                        DriveProfileCard(state: state)
                            .frame(maxHeight: .infinity)
                        DebugLoggingCard(state: state)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(height: rowHeight)
            }
        }
    }
}
