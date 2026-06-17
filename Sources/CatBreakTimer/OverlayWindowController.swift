import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var window: NSWindow?
    private var dismiss: (@MainActor () -> Void)?
    private var addExtraTime: (@MainActor () -> Void)?

    func show(
        seconds: Int,
        gifURL: URL?,
        onDismiss: @escaping @MainActor () -> Void,
        onAddExtraTime: @escaping @MainActor () -> Void
    ) {
        dismiss = onDismiss
        addExtraTime = onAddExtraTime
        if let window {
            (window.contentView as? NSHostingView<OverlayView>)?.rootView = view(seconds: seconds, gifURL: gifURL)
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
        window.level = .floating
        window.backgroundColor = .black
        window.contentView = NSHostingView(rootView: view(seconds: seconds, gifURL: gifURL))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }

    private func view(seconds: Int, gifURL: URL?) -> OverlayView {
        OverlayView(seconds: seconds, gifURL: gifURL) { [weak self] in
            self?.close()
            self?.dismiss?()
        } onAddExtraTime: { [weak self] in
            self?.close()
            self?.addExtraTime?()
        }
    }
}

struct OverlayView: View {
    let seconds: Int
    let gifURL: URL?
    let onDismiss: @MainActor () -> Void
    let onAddExtraTime: @MainActor () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                AnimatedGIFView(fileURL: gifURL)
                    .frame(width: 420, height: 420)

                Text("Break time")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(format(seconds))
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    Button("Shoo", action: onDismiss)
                    Button("+5 min", action: onAddExtraTime)
                }
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
    let fileURL: URL?

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.canDrawSubviewsIntoLayer = true
        imageView.animates = true
        imageView.image = image()
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {}

    private func image() -> NSImage? {
        if let fileURL,
           FileManager.default.fileExists(atPath: fileURL.path),
           let image = NSImage(contentsOf: fileURL) {
            return image
        }

        return Bundle.module.url(forResource: "cat", withExtension: "gif")
            .flatMap(NSImage.init(contentsOf:))
    }
}
