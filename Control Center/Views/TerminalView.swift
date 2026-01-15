import SwiftUI
import SwiftTerm

struct SwiftTermContainerView: NSViewRepresentable {
    let initialCommand: String
    let knownHostsPath: String?

    func makeNSView(context: Context) -> SwiftTermNativeView {
        let view = SwiftTermNativeView(frame: .zero)
        view.configure(initialCommand: initialCommand, knownHostsPath: knownHostsPath)
        return view
    }

    func updateNSView(_ nsView: SwiftTermNativeView, context: Context) {
    }
}

final class SwiftTermNativeView: NSView, LocalProcessTerminalViewDelegate {
    private let term = LocalProcessTerminalView(frame: .zero)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        term.processDelegate = self
        term.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        addSubview(term)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        term.frame = bounds
    }

    func configure(initialCommand: String, knownHostsPath: String?) {
        term.startProcess(executable: "/bin/zsh", args: ["-l", "-i"])
        var bootstrap = ""
        if let knownHostsPath, !knownHostsPath.isEmpty {
            let escaped = knownHostsPath.replacingOccurrences(of: "\"", with: "\\\"")
            bootstrap += "function ssh() { command /usr/bin/ssh -o UserKnownHostsFile=\"\(escaped)\" -o StrictHostKeyChecking=accept-new \"$@\"; }\n"
        }
        if !initialCommand.isEmpty {
            bootstrap += initialCommand + "\n"
        }
        if !bootstrap.isEmpty {
            let bytes = Array(bootstrap.utf8)
            term.send(data: bytes[...])
        }
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
    }
}
