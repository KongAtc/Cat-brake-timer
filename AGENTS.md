# AGENTS.md

## Project

Mac-only Cat Break Timer built as a Swift Package.

## Commands

- Build: `swift build`
- Test: `swift test`
- Run: `swift run CatBreakTimer`

SwiftPM/Xcode may need normal user cache access outside the workspace.

## Structure

- `Sources/CatBreakTimerCore`: timer state and testable logic.
- `Sources/CatBreakTimer`: SwiftUI app and AppKit overlay window.
- `Sources/CatBreakTimer/Resources/cat.gif`: bundled break-screen GIF.
- `Tests/CatBreakTimerCoreTests`: unit tests for timer behavior.

## Rules

- Keep this Mac-native. Do not add Electron, Tauri, or web tooling.
- Keep logic in `CatBreakTimerCore`; keep UI thin.
- Use `UserDefaults`/`@AppStorage` for simple settings.
- Do not add accounts, analytics, sync, auto-updaters, or packaging unless explicitly requested.
- Add one focused test for non-trivial timer behavior changes.
