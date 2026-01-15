import SwiftUI
import Combine

final class MJPEGStream: NSObject, ObservableObject, URLSessionDataDelegate {
    @Published var currentFrame: NSImage? = nil

    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var buffer = Data()
    private var isActive = false

    func start(url: URL?) {
        stop()
        guard let url else { return }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 0
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session?.dataTask(with: url)
        isActive = true
        task?.resume()
    }

    func stop() {
        isActive = false
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        buffer.removeAll(keepingCapacity: false)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard isActive else { return }
        buffer.append(data)
        extractFrames()
    }

    private func extractFrames() {
        while true {
            guard let start = buffer.firstIndex(of: 0xFF) else { return }
            guard start + 1 < buffer.count else { return }
            if buffer[start + 1] != 0xD8 {
                buffer.removeSubrange(0...start)
                continue
            }
            guard let end = findJPEGEnd(startIndex: start + 2) else { return }
            let frameData = buffer.subdata(in: start..<(end + 1))
            buffer.removeSubrange(0...end)
            if let image = NSImage(data: frameData) {
                DispatchQueue.main.async {
                    self.currentFrame = image
                }
            }
        }
    }

    private func findJPEGEnd(startIndex: Int) -> Int? {
        var index = startIndex
        while index + 1 < buffer.count {
            if buffer[index] == 0xFF && buffer[index + 1] == 0xD9 {
                return index + 1
            }
            index += 1
        }
        return nil
    }
}

struct MJPEGStreamView: View {
    let urlString: String
    let isEnabled: Bool

    @StateObject private var stream = MJPEGStream()

    var body: some View {
        ZStack {
            if let image = stream.currentFrame {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text(isEnabled ? "Waiting for MJPEG..." : "Camera Disabled")
                    .font(.dashboardBody(10))
                    .foregroundStyle(DashboardTheme.textSecondary)
            }
        }
        .onAppear {
            connectIfNeeded()
        }
        .onChange(of: urlString) { _, _ in
            connectIfNeeded()
        }
        .onChange(of: isEnabled) { _, _ in
            connectIfNeeded()
        }
        .onDisappear {
            stream.stop()
        }
    }

    private func connectIfNeeded() {
        guard isEnabled, let url = URL(string: urlString), !urlString.isEmpty else {
            stream.stop()
            return
        }
        stream.start(url: url)
    }
}
