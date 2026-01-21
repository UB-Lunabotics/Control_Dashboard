import SwiftUI

struct WebSocketActivityCard: View {
    @ObservedObject var state: AppState

    @State private var stickToBottom: Bool = true

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        CardView(title: "Network Activity") {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        // Top “sentinel” lets us detect whether user has scrolled away from bottom
                        GeometryReader { _ in
                            Color.clear
                                .onAppear { stickToBottom = true }
                                .onDisappear { stickToBottom = false }
                        }
                        .frame(height: 0)

                        ForEach(state.webSocketActivity.suffix(50)) { entry in
                            HStack(spacing: 6) {
                                Text(timeString(entry.timestamp))
                                    .font(.dashboardMono(9))
                                    .foregroundStyle(DashboardTheme.textSecondary)
                                    .frame(width: 54, alignment: .leading)
                                    .textSelection(.enabled)

                                Text(entry.text)
                                    .font(.dashboardMono(10))
                                    .foregroundStyle(entry.direction == .outgoing ? Color.blue : DashboardTheme.success)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                        }

                        // Bottom anchor
                        Color.clear
                            .frame(height: 1)
                            .id("BOTTOM")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
                }
                .background(Color.black)
                .onChange(of: state.webSocketActivity.count) { _, _ in
                    guard stickToBottom else { return }
                    DispatchQueue.main.async {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                }
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }
}
