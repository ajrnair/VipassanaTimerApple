# Release test plan

## Critical paths

- Start a standard sitting, background and lock the iPhone, and verify the preparation,
  five-minute-warning, and completion cues arrive at their scheduled boundaries.
- Run the debug lock-screen test with the Watch disconnected, removed, or locked. Confirm Apple's
  default alert at five seconds and the bundled gong at ten seconds are each audible. With an
  unlocked paired Watch on-wrist, confirm both notifications use the Watch system cue instead.
- Start Awareness with a short valid schedule, lock the iPhone, and verify an interval cue and the
  final completion cue.
- Complete, edit, annotate, and delete a sitting in the meditation log; relaunch and verify every
  change persists.
- With Apple Health writing enabled, complete a sitting and verify one Mindful Minutes entry is
  created. Confirm editing the local session does not create a duplicate.
- Pair the Watch app, create and edit phone history, and verify additions, edits, and deletions
  converge after both apps reconnect.
- Launch the 60-minute sitting from the iPhone widget, Mac widget, Watch complication, and an App
  Shortcut; confirm invalid or overlapping starts are rejected.

## Edge cases

- Rapidly tap Start twice and confirm only one session is created.
- End during preparation and confirm the log credits zero minutes.
- End a running sitting early and confirm only elapsed meditation time is credited.
- Relaunch during an active session and after its scheduled completion boundary.
- Change the wall clock during a session and confirm monotonic elapsed time remains authoritative.
- Try a 24-hour Awareness schedule with an interval below the supported minimum and verify the app
  explains the valid minimum rather than silently dropping cues.
- Disable notification sounds, Lock Screen delivery, or Immediate Delivery and verify Start is
  blocked with actionable settings guidance.
- Keep the paired Watch worn and unlocked, then repeat the locked-iPhone cue test to document which
  device presents the notification.

## Platform matrix

- iPhone and iPad: Debug and Release builds; light and dark appearance; smallest supported phone.
- Mac: Debug and Release builds; narrow and wide windows.
- Apple Watch: foreground custom gong/haptic, inactive system notification cue, relaunch recovery,
  and complication launch.
- CI: SwiftPM unit tests, Xcode unit tests on macOS, executable core smoke checks, and unsigned
  iOS/watchOS app-family builds.

## Current verification state

- **Verified on device, 24 August 2026 (build 16, iPhone 16 Pro):** a sitting started, the phone
  locked and pocketed, and the closing gongs arrived on time. This is the check that qualifies the
  scheduled-audio design — an `AVAudioEngine` whose next buffer is minutes away does keep the app
  alive while the screen is off, which no simulator can demonstrate. Re-run it whenever the audio
  path changes.
- **Automated:** 36 tests pass through SwiftPM and the Xcode test target; executable smoke checks
  pass; unsigned macOS, iOS/iPadOS, watchOS, widget, complication, and App Intent targets compile.
- **Simulator:** iPhone phone layouts pass in light/dark appearance and at the largest accessibility
  text size; iPad mini and 40 mm Watch layouts pass visual review.
- **Physical:** local notification delivery is confirmed, and the custom iPhone gong has sounded
  when the phone owns delivery. Cross-device routing and inactive Watch presentation remain open.
- **Distribution:** final-team signing, App Store Connect, archive upload, and TestFlight wait for
  the ARN developer membership and must not use mHealth Ventures.
