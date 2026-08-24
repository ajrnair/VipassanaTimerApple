# Implementation Plan: Apple Timer Parity

## Technical context

- Swift 6 toolchain, with the Xcode app compiled in Swift 5 language mode for broad SDK
  compatibility.
- One SwiftUI application target supports iOS/iPadOS 17+ and macOS 14+.
- Core timing, awareness validation, persistence, formatting, and aggregation are Foundation-only
  and testable with Swift Package Manager.
- UserNotifications provides scheduled start, warning, interval, and completion delivery.
- All authoritative time calculations use a persisted wall-clock anchor plus system uptime while
  the same boot remains active. UI timers only refresh the display.
- Data remains in the application-support container as versioned JSON.

## Awareness scheduling decision

Awareness duration is programmable from 1 through 24 whole hours. Gong interval is a positive
whole number of minutes. A valid schedule contains at most 63 intermediate gong events plus one
completion event, keeping the entire practice within Apple's 64 pending local-notification limit.

For a selected duration, the minimum reliable interval is:

`ceil(total minutes / 64)`

The default 8-hour / 10-minute schedule produces 47 intermediate gongs and one completion action.

## Architecture

```text
SwiftUI views
    │
    ▼
AppModel (@MainActor)
    ├── TimerEngine (pure absolute-time state machine)
    ├── SessionStore (active/completion recovery)
    ├── HistoryStore (idempotent records + daily totals)
    ├── NotificationScheduler (platform delivery)
    └── SleepAssertionController (Mac active-session lifetime)
```

## Product presentation

- Restore the approved soft visual language: rounded session surfaces, concentric timer and gong
  forms, floating phone navigation, and a native Mac sidebar.
- Use the approved limestone, evergreen, patina, and laterite palette in light and dark modes.
- Use a platform serif for prominent time and title typography and a system sans serif elsewhere.
- Maintain keyboard, VoiceOver, Dynamic Type, reduced-motion, and high-contrast operability.

## Notification and sound plan

- Schedule all future events when a session begins; cancel them by session identifier when ended.
- Suppress foreground banners while allowing their requested sound.
- Use the transformed 4-second bell for start, warning, and interval events.
- Use a less-than-30-second three-bell CAF for completion alerts.
- Reconcile application state from absolute timestamps rather than assuming a notification was
  physically heard.

## Verification

- The Swift Package verification executable covers awareness bounds, event counts, transition
  thresholds, clock changes, reboot recovery, early termination, idempotent history, corrupt-entry
  recovery, and active-state persistence.
- Xcode builds and tests run in CI on every change alongside the Swift Package checks.
