# Notes

## Break Screen Alerts

The break overlay uses `.floating` window level instead of `.screenSaver` so Slack and system call alerts can appear above it. The app does not detect Slack calls or request Accessibility/notification-monitoring permissions.

## Duration Inputs

Work and break durations are stored as total seconds in `@AppStorage` keys `workSeconds` and `breakSeconds`. The UI shows min/sec number fields.

## Extra Time Before Break

When work time reaches zero, the break overlay starts immediately. Use `+5 min` on the overlay to close it and continue working.

## Custom GIF

The Change GIF button copies the selected GIF into Application Support as `custom.gif`. If that file is missing or unreadable, the app falls back to the bundled `cat.gif`.
