# Cat Break Timer

Cat Break Timer is a small macOS Pomodoro-style app that helps you focus during work sessions and takes over the screen with a cat GIF when it is time for a break.

## Repo Notes

- See [AGENTS.md](/Users/athichart/Desktop/Research/AGENTS.md) for repo-specific instructions and project rules.

## What it does

- Lets you set work and break lengths.
- Counts down work sessions and switches to break mode automatically.
- Shows a full-screen break overlay with a cat animation.
- Can restart work automatically after a break, if you want that behavior.

## Project layout

- `Sources/CatBreakTimerCore`: timer state and core logic.
- `Sources/CatBreakTimer`: SwiftUI app and AppKit overlay window.
- `Sources/CatBreakTimer/Resources/cat.gif`: the animated cat shown during breaks.
- `Tests/CatBreakTimerCoreTests`: unit tests for the timer behavior.

## Requirements

- macOS 14 or later
- Swift 6

## Run it

```bash
swift run CatBreakTimer
```

## Test it

```bash
swift test
```

## Settings

The app remembers these values with `@AppStorage`:

- Work duration
- Break duration
- Auto restart work

## Notes

- This is a Mac-native Swift package.
- The core timer logic stays in `CatBreakTimerCore` so it is easy to test.
- The UI stays thin and just drives the timer state.
