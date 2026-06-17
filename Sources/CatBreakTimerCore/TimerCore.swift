import Combine
import Foundation

public struct TimerSettings: Equatable {
    public var workSeconds: Int
    public var breakSeconds: Int
    public var autoRestartWork: Bool

    public init(workSeconds: Int = 1500, breakSeconds: Int = 300, autoRestartWork: Bool = false) {
        self.workSeconds = Self.clamp(workSeconds, 1...28800)
        self.breakSeconds = Self.clamp(breakSeconds, 1...3600)
        self.autoRestartWork = autoRestartWork
    }

    public static func durationSeconds(minutes: Int, seconds: Int, range: ClosedRange<Int>) -> Int {
        clamp(minutes * 60 + clamp(seconds, 0...59), range)
    }

    private static func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

public indirect enum TimerPhase: Equatable {
    case idle
    case working
    case paused(TimerPhase)
    case breakPending
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
        remainingSeconds = seconds ?? settings.workSeconds
    }

    public func startBreak(seconds: Int? = nil) {
        phase = .breakActive
        remainingSeconds = seconds ?? settings.breakSeconds
    }

    public func addExtraWorkTime(seconds: Int = 300) {
        phase = .working
        remainingSeconds = max(1, seconds)
    }

    public func pause() {
        switch phase {
        case .working, .breakActive:
            phase = .paused(phase)
        case .idle, .breakPending, .paused:
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
            phase = .breakPending
        case .breakActive:
            dismissBreak()
        case .idle, .breakPending, .paused:
            break
        }
    }
}
