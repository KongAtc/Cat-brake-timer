# Break Screen Alert + Duration Inputs + GIF Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update Cat Break Timer so alerts can appear over the break screen, durations use min/sec inputs, the break GIF is user-changeable, and users can delay a break with a `+5 min` button when work time reaches zero.

**Architecture:** Keep timer rules in `CatBreakTimerCore` and keep SwiftUI/AppKit UI thin. Add a `breakPending` timer phase so work completion can show “Break now” and “+5 min” choices before starting the break overlay. Store simple settings with `@AppStorage`; copy custom GIFs into Application Support and fall back to bundled `cat.gif`.

**Tech Stack:** Swift Package Manager, SwiftUI, AppKit `NSWindow`, `UserDefaults`/`@AppStorage`, SwiftUI `fileImporter`, XCTest.

---

## File Structure

- Modify `Sources/CatBreakTimerCore/TimerCore.swift`: settings in seconds, new `breakPending` phase, `addExtraWorkTime(seconds:)`.
- Modify `Tests/CatBreakTimerCoreTests/TimerControllerTests.swift`: update old minute tests and add break-delay tests.
- Modify `Sources/CatBreakTimer/CatBreakTimerApp.swift`: min/sec inputs, GIF picker button, break-pending controls.
- Modify `Sources/CatBreakTimer/OverlayWindowController.swift`: lower window level, accept custom GIF URL, add `+5 min` button on overlay.
- Create `NOTES.md`: short user/developer note for this change.

## Task 1: Move Timer Settings To Seconds

**Files:**
- Modify: `Sources/CatBreakTimerCore/TimerCore.swift`
- Modify: `Tests/CatBreakTimerCoreTests/TimerControllerTests.swift`

- [x] **Step 1: Write failing settings tests**

Replace the old `testSettingsClampInvalidValues` with:

```swift
func testSettingsClampInvalidSecondValues() {
    let settings = TimerSettings(workSeconds: 0, breakSeconds: 999_999, autoRestartWork: true)

    XCTAssertEqual(settings.workSeconds, 1)
    XCTAssertEqual(settings.breakSeconds, 3600)
    XCTAssertTrue(settings.autoRestartWork)
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `swift test`

Expected: FAIL because `TimerSettings` does not have `workSeconds` or `breakSeconds`.

- [x] **Step 3: Update `TimerSettings`**

Change `TimerSettings` to:

```swift
public struct TimerSettings: Equatable {
    public var workSeconds: Int
    public var breakSeconds: Int
    public var autoRestartWork: Bool

    public init(workSeconds: Int = 1500, breakSeconds: Int = 300, autoRestartWork: Bool = false) {
        self.workSeconds = Self.clamp(workSeconds, 1...28800)
        self.breakSeconds = Self.clamp(breakSeconds, 1...3600)
        self.autoRestartWork = autoRestartWork
    }

    private static func clamp(_ value: Int, _ range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
```

Update `startWork` and `startBreak` defaults:

```swift
remainingSeconds = seconds ?? settings.workSeconds
remainingSeconds = seconds ?? settings.breakSeconds
```

- [x] **Step 4: Update existing tests to seconds**

Use `TimerSettings(workSeconds: 60, breakSeconds: 300)` for a 1-minute work and 5-minute break setup. Update auto-restart expectation to `180` by using `TimerSettings(workSeconds: 180, breakSeconds: 60, autoRestartWork: true)`.

- [x] **Step 5: Run tests**

Run: `swift test`

Expected: PASS.

## Task 2: Add Break Delay State And Button Behavior

**Files:**
- Modify: `Sources/CatBreakTimerCore/TimerCore.swift`
- Modify: `Tests/CatBreakTimerCoreTests/TimerControllerTests.swift`

- [x] **Step 1: Write failing break-delay tests**

Add:

```swift
func testWorkTimerReachesZeroAndWaitsForBreakChoice() {
    let controller = TimerController(settings: TimerSettings(workSeconds: 2, breakSeconds: 300))

    controller.startWork()
    controller.tick()
    controller.tick()

    XCTAssertEqual(controller.phase, .breakPending)
    XCTAssertEqual(controller.remainingSeconds, 0)
}

func testAddExtraWorkTimeDelaysBreak() {
    let controller = TimerController(settings: TimerSettings(workSeconds: 2, breakSeconds: 300))

    controller.startWork()
    controller.tick()
    controller.tick()
    controller.addExtraWorkTime(seconds: 300)

    XCTAssertEqual(controller.phase, .working)
    XCTAssertEqual(controller.remainingSeconds, 300)
}

func testStartBreakFromPendingStartsBreakTimer() {
    let controller = TimerController(settings: TimerSettings(workSeconds: 1, breakSeconds: 120))

    controller.startWork()
    controller.tick()
    controller.startBreak()

    XCTAssertEqual(controller.phase, .breakActive)
    XCTAssertEqual(controller.remainingSeconds, 120)
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `swift test`

Expected: FAIL because `.breakPending` and `addExtraWorkTime(seconds:)` do not exist.

- [x] **Step 3: Implement break pending**

Add `case breakPending` to `TimerPhase`.

Change work completion in `tick()`:

```swift
case .working:
    phase = .breakPending
```

Add:

```swift
public func addExtraWorkTime(seconds: Int = 300) {
    phase = .working
    remainingSeconds = max(1, seconds)
}
```

Keep `startBreak()` as the way to move from pending to actual break.

- [x] **Step 4: Update old transition test**

Rename `testWorkTimerReachesZeroAndStartsBreak` to `testWorkTimerReachesZeroAndWaitsForBreakChoice`; it should expect `.breakPending`, not `.breakActive`.

- [x] **Step 5: Run tests**

Run: `swift test`

Expected: PASS.

## Task 3: Update Main Window Inputs And Break Pending Controls

**Files:**
- Modify: `Sources/CatBreakTimer/CatBreakTimerApp.swift`

- [x] **Step 1: Replace minute storage**

Replace:

```swift
@AppStorage("workMinutes") private var workMinutes = 25
@AppStorage("breakMinutes") private var breakMinutes = 5
```

with:

```swift
@AppStorage("workSeconds") private var workSeconds = 1500
@AppStorage("breakSeconds") private var breakSeconds = 300
```

- [x] **Step 2: Add min/sec bindings**

Add private bindings or helper methods in `ContentView` so the UI edits `workSeconds` and `breakSeconds` through minute and second fields. Clamp seconds field to `0...59`; clamp total work to `1...28800`; clamp total break to `1...3600`.

Use SwiftUI `TextField(value:format:)` number inputs, following Apple’s current `TextField("Label", value: $value, format: .number)` API.

- [x] **Step 3: Replace steppers with number fields**

Show:

```text
Work: [min] min [sec] sec
Break: [min] min [sec] sec
```

Use compact numeric text fields; no custom picker library.

- [x] **Step 4: Add break-pending controls**

When `controller.phase == .breakPending`, show:

```swift
Button("Start Break") { controller.startBreak() }
Button("+5 min") { controller.addExtraWorkTime(seconds: 300) }
```

The `+5 min` button is the required “add extra time before break” behavior.

- [x] **Step 5: Update settings sync**

Build `TimerSettings(workSeconds: workSeconds, breakSeconds: breakSeconds, autoRestartWork: autoRestartWork)` and write clamped values back to `@AppStorage`.

- [x] **Step 6: Build**

Run: `swift build`

Expected: PASS.

## Task 4: Let Alerts Show Above Overlay And Add Overlay Delay Button

**Files:**
- Modify: `Sources/CatBreakTimer/OverlayWindowController.swift`
- Modify: `Sources/CatBreakTimer/CatBreakTimerApp.swift`

- [x] **Step 1: Lower overlay window level**

Change:

```swift
window.level = .screenSaver
```

to:

```swift
window.level = .floating
```

This keeps the break screen above normal windows but lets system/Slack call alerts appear above it.

- [x] **Step 2: Add extra-time callback**

Change overlay show API to accept:

```swift
func show(
    seconds: Int,
    gifURL: URL?,
    onDismiss: @escaping @MainActor () -> Void,
    onAddExtraTime: @escaping @MainActor () -> Void
)
```

- [x] **Step 3: Add overlay `+5 min` button**

In `OverlayView`, add a second button next to `Shoo`:

```swift
Button("+5 min", action: onAddExtraTime)
```

The callback should close the overlay and call `controller.addExtraWorkTime(seconds: 300)`.

- [x] **Step 4: Keep manual stop behavior**

Keep `Shoo` wired to dismiss the break as today. No Slack detection, no Accessibility permissions, no notification scraping.

- [x] **Step 5: Build**

Run: `swift build`

Expected: PASS.

## Task 5: Add GIF Picker And Persistence

**Files:**
- Modify: `Sources/CatBreakTimer/CatBreakTimerApp.swift`
- Modify: `Sources/CatBreakTimer/OverlayWindowController.swift`

- [x] **Step 1: Add GIF path storage**

Add:

```swift
@AppStorage("customGIFPath") private var customGIFPath = ""
@State private var isPickingGIF = false
```

- [x] **Step 2: Add Change GIF button**

Add:

```swift
Button("Change GIF") {
    isPickingGIF = true
}
```

Attach `.fileImporter(isPresented:allowedContentTypes:allowsMultipleSelection:onCompletion:)` with GIF/image content types. Use `UTType.gif` and `.image`; import `UniformTypeIdentifiers`.

- [x] **Step 3: Copy selected GIF**

On successful selection, copy the chosen file to:

```text
Application Support/CatBreakTimer/custom.gif
```

Create the directory if missing. Replace the old `custom.gif` if present.

- [x] **Step 4: Store copied path**

Set `customGIFPath` to the copied file path. Never store the original selected path as the runtime source.

- [x] **Step 5: Display selected GIF**

Change `AnimatedGIFView` to support either:

```swift
let fileURL: URL?
```

If `fileURL` exists and loads, display it. Otherwise load bundled `cat.gif` from `Bundle.module`.

- [x] **Step 6: Build**

Run: `swift build`

Expected: PASS.

## Task 6: Notes And Final Verification

**Files:**
- Create: `NOTES.md`

- [x] **Step 1: Add notes**

Create:

```markdown
# Notes

## Break Screen Alerts

The break overlay uses `.floating` window level instead of `.screenSaver` so Slack and system call alerts can appear above it. The app does not detect Slack calls or request Accessibility/notification-monitoring permissions.

## Duration Inputs

Work and break durations are stored as total seconds in `@AppStorage` keys `workSeconds` and `breakSeconds`. The UI shows min/sec number fields.

## Extra Time Before Break

When work time reaches zero, the timer enters a pending-break state. Use `Start Break` to begin the break or `+5 min` to delay it and continue working.

## Custom GIF

The Change GIF button copies the selected GIF into Application Support as `custom.gif`. If that file is missing or unreadable, the app falls back to the bundled `cat.gif`.
```

- [x] **Step 2: Run tests**

Run: `swift test`

Expected: PASS.

- [x] **Step 3: Run build**

Run: `swift build`

Expected: PASS.

- [ ] **Step 4: Manual checks**

Run: `swift run CatBreakTimer`.

Check:

- min/sec inputs accept values and clamp correctly
- work timer reaches zero and shows break-pending controls
- `+5 min` starts another 5 minutes of work
- `Start Break` opens the break overlay
- overlay `+5 min` closes the overlay and resumes work
- Slack/system alerts can appear above the break overlay
- Change GIF persists after relaunch

## Assumptions

- Extra time is fixed at `+5 min` for v1; make it configurable only after using it.
- Slack/call support means alerts are visible above the overlay, not auto-detected.
- Existing `Shoo` remains the manual way to stop the break screen.
- No new dependencies, no app packaging, and no macOS permissions are added.
