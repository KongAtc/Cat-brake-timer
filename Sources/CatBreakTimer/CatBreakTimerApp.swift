import CatBreakTimerCore
import Combine
import SwiftUI

@main
struct CatBreakTimerApp: App {
    @StateObject private var controller = TimerController()
    private let overlay = OverlayWindowController()

    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller, overlay: overlay)
                .frame(width: 420, height: 360)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .frame(width: 320)
                .padding()
        }
    }
}

struct ContentView: View {
    @ObservedObject var controller: TimerController
    let overlay: OverlayWindowController

    @AppStorage("workMinutes") private var workMinutes = 25
    @AppStorage("breakMinutes") private var breakMinutes = 5
    @AppStorage("autoRestartWork") private var autoRestartWork = false

    var body: some View {
        VStack(spacing: 18) {
            Text("Cat Break Timer")
                .font(.largeTitle.bold())

            Text(status)
                .foregroundStyle(.secondary)

            Text(format(controller.remainingSeconds))
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .monospacedDigit()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text("Work")
                    Stepper("\(workMinutes) min", value: $workMinutes, in: 1...480)
                }
                GridRow {
                    Text("Break")
                    Stepper("\(breakMinutes) min", value: $breakMinutes, in: 1...60)
                }
            }

            Toggle("Auto restart work", isOn: $autoRestartWork)

            HStack {
                Button("Start") { startWork() }
                    .keyboardShortcut(.defaultAction)

                Button(isPaused ? "Resume" : "Pause") { togglePause() }
                    .disabled(controller.phase == .idle)

                Button("Reset") { reset() }
            }
        }
        .padding(28)
        .onAppear(perform: syncSettings)
        .onChange(of: workMinutes) { _, _ in syncSettings() }
        .onChange(of: breakMinutes) { _, _ in syncSettings() }
        .onChange(of: autoRestartWork) { _, _ in syncSettings() }
        .onReceive(ticker) { _ in
            controller.tick()
            updateOverlay()
        }
    }

    private var ticker: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()
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

    private func togglePause() {
        isPaused ? controller.resume() : controller.pause()
    }

    private func reset() {
        controller.reset()
        overlay.close()
    }

    private func syncSettings() {
        let settings = TimerSettings(
            workMinutes: workMinutes,
            breakMinutes: breakMinutes,
            autoRestartWork: autoRestartWork
        )
        workMinutes = settings.workMinutes
        breakMinutes = settings.breakMinutes
        controller.updateSettings(settings)
    }

    private func updateOverlay() {
        if controller.phase == .breakActive {
            overlay.show(seconds: controller.remainingSeconds) {
                controller.dismissBreak()
            }
        } else {
            overlay.close()
        }
    }

    private func format(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

struct SettingsView: View {
    @AppStorage("workMinutes") private var workMinutes = 25
    @AppStorage("breakMinutes") private var breakMinutes = 5
    @AppStorage("autoRestartWork") private var autoRestartWork = false

    var body: some View {
        Form {
            Stepper("Work: \(workMinutes) min", value: $workMinutes, in: 1...480)
            Stepper("Break: \(breakMinutes) min", value: $breakMinutes, in: 1...60)
            Toggle("Auto restart work", isOn: $autoRestartWork)
        }
    }
}
