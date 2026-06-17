# Break Screen Alert + Duration Inputs + GIF Picker Plan

## Summary

Update the Mac-only SwiftUI app so break screen overlays stop blocking Slack/system call popups, timer durations use minute/second number inputs, and the user can choose a different `.gif` for the break screen. Also add a short project note documenting the change.

## Key Changes

- Change the break overlay window from `.screenSaver` level to a lower always-on-top level, likely `.floating`, so Slack/system call popups can appear above it.
- Keep the existing `Shoo` button as the manual way to stop the break screen; do not add Slack-specific detection or Accessibility/notification permissions.
- Replace current minute-only steppers with number `TextField`s for:
  - Work: `min` + `sec`
  - Break: `min` + `sec`
- Store durations as total seconds in `@AppStorage`:
  - `workSeconds`, default `1500`
  - `breakSeconds`, default `300`
  - Clamp work to `1...28800`
  - Clamp break to `1...3600`
- Update `TimerSettings` public interface from minute-based fields to:
  - `workSeconds: Int`
  - `breakSeconds: Int`
  - `autoRestartWork: Bool`
- Add a "Change GIF" button using SwiftUI `fileImporter` with GIF/image content types.
- When a GIF is selected, copy it into the app support folder, store that copied file path in `@AppStorage`, and display it in `OverlayView`.
- Keep bundled `cat.gif` as fallback if the custom GIF is missing or unreadable.
- Create a note file, `NOTES.md`, describing:
  - why overlay level was lowered
  - how duration inputs work
  - where custom GIFs are stored
  - that Slack call detection is intentionally skipped for v1

## Test Plan

- Update unit tests for `TimerSettings`:
  - invalid `workSeconds` clamps to `1`
  - oversized `breakSeconds` clamps to `3600`
- Update timer behavior tests:
  - work timer transitions to break using seconds
  - break timer ends and returns idle
  - auto-restart starts work using `workSeconds`
  - pause still stops countdown
- Build checks:
  - `swift test`
  - `swift build`
- Manual checks:
  - enter work/break values using min/sec fields
  - start a short timer and confirm overlay appears
  - confirm Slack/system alerts can appear over the break overlay
  - choose a new `.gif` and confirm the next break screen uses it
  - delete/move the chosen GIF source and confirm copied app-support GIF still works

## Assumptions

- "Alert popup from Slack" means it should be visible above the break screen, not automatically detected.
- "Can stop the break screen" is covered by the existing `Shoo` button, kept visible on the overlay.
- Custom GIF selection should persist across app launches.
- No new macOS permissions, Slack integration, notification scraping, or Accessibility monitoring for this version.
