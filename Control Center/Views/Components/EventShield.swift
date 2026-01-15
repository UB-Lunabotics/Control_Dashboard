#if os(macOS)
import SwiftUI
import AppKit

struct EventShield: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ShieldView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class ShieldView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { self }

        override func mouseDown(with event: NSEvent) {}
        override func mouseUp(with event: NSEvent) {}
        override func rightMouseDown(with event: NSEvent) {}
        override func otherMouseDown(with event: NSEvent) {}
        override func mouseDragged(with event: NSEvent) {}
        override func rightMouseDragged(with event: NSEvent) {}
        override func otherMouseDragged(with event: NSEvent) {}
        override func scrollWheel(with event: NSEvent) {}
    }
}
#else
struct EventShield: View {
    var body: some View { Color.clear }
}
#endif
