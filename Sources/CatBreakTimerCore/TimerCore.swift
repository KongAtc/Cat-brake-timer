import Combine
import Foundation

public struct TimerSettings: Equatable {
    public var workMinutes: Int
    public var breakMinutes: Int
    public var autoRestartWork: Bool

    public init(workMinutes: Int = 25, breakMinutes: Int = 5, autoRestartWork: Bool = false) {
        self.workMinutes = Self.clamp(workMinutes, 1...480)
        self.breakMinutes = Self.clamp(breakMinutes, 1...60)
        self.autoRestartWork = autoRestartWork
    }

    private static func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

public indirect enum TimerPhase: Equatable {
    case idle
    case working
    case paused(TimerPhase)
    case breakActive
}

public final class TimerController: ObservableObject {
    @Published public private(set) var phase: TimerPhase = .idle
    @Published public private(set) var remainingSeconds = 0

    public var settings: TimerSettings

    public init(settings: TimerSettings = TimerSettings()) {
        self.settings = settings
    }

    public func updateSettings(_ settings: TimerSettings) {
        self.settings = settings
        if phase == .idle {
            remainingSeconds = 0
        }
    }

    public func startWork(seconds: Int? = nil) {
        phase = .working
        remainingSeconds = seconds ?? settings.workMinutes * 60
    }

    public func startBreak(seconds: Int? = nil) {
        phase = .breakActive
        remainingSeconds = seconds ?? settings.breakMinutes * 60
    }

    public func pause() {
        switch phase {
        case .working, .breakActive:
            phase = .paused(phase)
        case .idle, .paused:
            break
        }
    }

    public func resume() {
        if case let .paused(previousPhase) = phase {
            phase = previousPhase
        }
    }

    public func reset() {
        phase = .idle
        remainingSeconds = 0
    }

    public func dismissBreak() {
        if settings.autoRestartWork {
            startWork()
        } else {
            reset()
        }
    }

    public func tick() {
        guard phase != .idle, remainingSeconds > 0 else { return }
        if case .paused = phase { return }

        remainingSeconds -= 1
        guard remainingSeconds == 0 else { return }

        switch phase {
        case .working:
            startBreak()
        case .breakActive:
            dismissBreak()
        case .idle, .paused:
            break
        }
    }
}
