import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var window: NSWindow?
    private var dismiss: (@MainActor () -> Void)?

    func show(seconds: Int, onDismiss: @escaping @MainActor () -> Void) {
        dismiss = onDismiss
        if let window {
            (window.contentView as? NSHostingView<OverlayView>)?.rootView = view(seconds: seconds)
            return
        }

        let screenFrame = NSScreen.main?.frame ?? .zero
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.level = .screenSaver
        window.backgroundColor = .black
        window.contentView = NSHostingView(rootView: view(seconds: seconds))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }

    private func view(seconds: Int) -> OverlayView {
        OverlayView(seconds: seconds) { [weak self] in
            self?.close()
            self?.dismiss?()
        }
    }
}

struct OverlayView: View {
    let seconds: Int
    let onDismiss: @MainActor () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                AnimatedGIFView(resource: "cat", extension: "gif")
                    .frame(width: 420, height: 420)

                Text("Break time")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(format(seconds))
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Button("Shoo", action: onDismiss)
                    .font(.title2.bold())
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(40)
        }
    }

    private func format(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

struct AnimatedGIFView: NSViewRepresentable {
    let resource: String
    let `extension`: String

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.canDrawSubviewsIntoLayer = true
        imageView.animates = true
        imageView.image = Bundle.module.url(forResource: resource, withExtension: `extension`).flatMap(NSImage.init(contentsOf:))
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {}
}
