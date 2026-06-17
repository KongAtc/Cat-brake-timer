import AppKit
import CatBreakTimerCore
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@main
struct CatBreakTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = TimerController()
    private let overlay = OverlayWindowController()

    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller, overlay: overlay)
                .frame(width: 420, height: 430)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .frame(width: 320)
                .padding()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}

struct ContentView: View {
    @ObservedObject var controller: TimerController
    let overlay: OverlayWindowController

    @AppStorage("workSeconds") private var workSeconds = 1500
    @AppStorage("breakSeconds") private var breakSeconds = 300
    @AppStorage("autoRestartWork") private var autoRestartWork = false
    @AppStorage("customGIFPath") private var customGIFPath = ""
    @State private var isPickingGIF = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 18) {
            Text("Cat Break Timer")
                .font(.largeTitle.bold())

            Text(status)
                .foregroundStyle(.secondary)

            Text(format(controller.remainingSeconds))
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .monospacedDigit()

            VStack(alignment: .leading, spacing: 10) {
                DurationFields(title: "Work", totalSeconds: $workSeconds, range: 1...28800)
                DurationFields(title: "Break", totalSeconds: $breakSeconds, range: 1...3600)
            }

            Toggle("Auto restart work", isOn: $autoRestartWork)

            HStack {
                Button("Start") { startWork() }
                    .keyboardShortcut(.defaultAction)

                Button(isPaused ? "Resume" : "Pause") { togglePause() }
                    .disabled(controller.phase == .idle)

                Button("Reset") { reset() }
            }

            Button("Change GIF") {
                isPickingGIF = true
            }
        }
        .padding(28)
        .onAppear(perform: syncSettings)
        .onChange(of: workSeconds) { _, _ in syncSettings() }
        .onChange(of: breakSeconds) { _, _ in syncSettings() }
        .onChange(of: autoRestartWork) { _, _ in syncSettings() }
        .onReceive(ticker) { _ in
            controller.tick()
            updateOverlay()
        }
        .fileImporter(
            isPresented: $isPickingGIF,
            allowedContentTypes: [.gif, .image],
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result, let url = urls.first {
                importGIF(from: url)
            }
        }
    }

    private var isPaused: Bool {
        if case .paused = controller.phase { return true }
        return false
    }

    private var status: String {
        switch controller.phase {
        case .idle:
            return "Ready when you are."
        case .working:
            return "Work time."
        case .breakActive:
            return "Cat says break."
        case .paused:
            return "Paused."
        }
    }

    private func startWork() {
        syncSettings()
        controller.startWork()
        overlay.close()
    }

    private func addExtraWorkTime() {
        controller.addExtraWorkTime(seconds: 300)
        overlay.close()
    }

    private func togglePause() {
        isPaused ? controller.resume() : controller.pause()
    }

    private func reset() {
        controller.reset()
        overlay.close()
    }

    private func syncSettings() {
        let settings = TimerSettings(
            workSeconds: workSeconds,
            breakSeconds: breakSeconds,
            autoRestartWork: autoRestartWork
        )
        workSeconds = settings.workSeconds
        breakSeconds = settings.breakSeconds
        controller.updateSettings(settings)
    }

    private func updateOverlay() {
        if controller.phase == .breakActive {
            overlay.show(seconds: controller.remainingSeconds, gifURL: customGIFURL) {
                controller.dismissBreak()
            } onAddExtraTime: {
                addExtraWorkTime()
            }
        } else {
            overlay.close()
        }
    }

    private var customGIFURL: URL? {
        customGIFPath.isEmpty ? nil : URL(fileURLWithPath: customGIFPath)
    }

    private func importGIF(from source: URL) {
        let didAccess = source.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                source.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let supportURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("CatBreakTimer", isDirectory: true)
            try FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)

            let destination = supportURL.appendingPathComponent("custom.gif")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            customGIFPath = destination.path
        } catch {
            print("Could not import GIF: \(error)")
        }
    }

    private func format(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

struct SettingsView: View {
    @AppStorage("workSeconds") private var workSeconds = 1500
    @AppStorage("breakSeconds") private var breakSeconds = 300
    @AppStorage("autoRestartWork") private var autoRestartWork = false

    var body: some View {
        Form {
            DurationFields(title: "Work", totalSeconds: $workSeconds, range: 1...28800)
            DurationFields(title: "Break", totalSeconds: $breakSeconds, range: 1...3600)
            Toggle("Auto restart work", isOn: $autoRestartWork)
        }
    }
}

private struct DurationFields: View {
    let title: String
    @Binding var totalSeconds: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .frame(width: 44, alignment: .leading)
            TextField("min", value: minutes, format: .number)
                .frame(width: 56)
                .multilineTextAlignment(.trailing)
            Text("min")
            TextField("sec", value: seconds, format: .number)
                .frame(width: 44)
                .multilineTextAlignment(.trailing)
            Text("sec")
        }
        .textFieldStyle(.roundedBorder)
    }

    private var minutes: Binding<Int> {
        Binding {
            totalSeconds / 60
        } set: { newValue in
            totalSeconds = TimerSettings.durationSeconds(
                minutes: newValue,
                seconds: totalSeconds % 60,
                range: range
            )
        }
    }

    private var seconds: Binding<Int> {
        Binding {
            totalSeconds % 60
        } set: { newValue in
            totalSeconds = TimerSettings.durationSeconds(
                minutes: totalSeconds / 60,
                seconds: newValue,
                range: range
            )
        }
    }
}
