import SwiftUI

struct MainGridView: View {
    @ObservedObject var state: AppState

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 12
            let leftWidth = proxy.size.width * 0.32
            let midWidth = proxy.size.width * 0.36
            let rightWidth = proxy.size.width - leftWidth - midWidth - spacing * 2

            HStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    ControllerVisualizationCard(state: state)
                        .frame(height: proxy.size.height * 0.32)
                    TerminalPanelCard()
                        .frame(maxHeight: .infinity)
                }
                .frame(width: leftWidth)

                VStack(spacing: spacing) {
                    URDFSimulatorCard()
                        .frame(height: proxy.size.height * 0.34)

                    LoggingPanelCard(state: state)
                        .frame(height: proxy.size.height * 0.14)

                    MotionControlCard(state: state)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: midWidth)

                VStack(spacing: spacing) {
                    CameraViewCard(state: state)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: rightWidth)
            }
        }
    }
}
