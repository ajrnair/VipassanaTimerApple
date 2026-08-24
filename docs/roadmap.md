# Release roadmap

Updated 23 August 2026. Guided Practice remains a separate pull request and is intentionally not
included in the release-critical path below.

## Ready in the repository

- Standard sittings and 1–24 hour Awareness practice, with gongs delivered as app audio on
  iPhone and recovery on every platform.
- Editable session history with optional notes shown only after opening a saved session.
- Optional write-only Apple Health Mindful Minutes export.
- Direct iPhone–Apple Watch history exchange, including edit and deletion convergence.
- iPhone and independent Watch apps (iPad and Mac build but are out of scope for the first
  release); Home Screen widget; Watch complications; App
  Intents, Shortcuts, and deep links.
- Privacy manifests, a public-ready privacy page, exact App Store privacy answers, and a physical
  release-test checklist.
- A compact in-app About & Privacy page, MIT source license, and separate bundled-audio terms.
- 33 deterministic core tests wired into both SwiftPM and the Xcode test target.
- CI gates for SwiftPM tests, Xcode tests, executable smoke checks, and unsigned iOS/watchOS builds.
- Simulator layout review on iPhone, iPad mini, 40 mm Watch, light/dark appearance, and the largest
  iPhone accessibility text size.

## Before the first TestFlight beta

- Run a focused accessibility safety check: confirm essential controls have useful VoiceOver names,
  larger text does not hide actions, and starting, ending, and saving remain operable. The broader
  keyboard, increased-contrast, reduced-motion, and multi-platform accessibility pass can follow
  during beta.
- Run Release builds on one supported iPhone and one Watch configuration.

## During TestFlight, before a public release candidate

- Finish the physical audio-delivery matrix on iPhone and Watch: locked, backgrounded, Silent
  Mode, a Focus, and an interruption (call, another app) mid-sitting. Separately, finish the
  Watch notification-routing matrix, since the Watch still delivers its inactive-state gong as
  a local notification: on-wrist unlocked, removed, and locked.
- Decide whether the inactive Watch path should keep Apple’s system cue or attempt the bundled
  custom gong; current APIs permit a named sound, but its physical presentation is not yet verified.
- Complete VoiceOver, hardware-keyboard, increased-contrast, and reduced-motion passes on all
  supported platforms.
- Complete the product's primary name/non-affiliation decision before public marketing.

## Waiting for the new Apple developer team

The full procedure is [`app-store-release.md`](app-store-release.md). Status:

- Done: production bundle identifiers migrated off the old team's prefix to
  `com.arn.vipassanatimer*` across all five targets, with both unsigned platform builds passing.
- Blocked on enrollment: activate the new Apple Developer Program membership, accept current
  terms, then replace `DEVELOPMENT_TEAM` (still the old team, which must not ship) and re-enable
  HealthKit on the new team's App ID.
- Decide the enrollment entity type before enrolling, not after — individual enrollment puts a
  personal legal name on the listing, and it cannot be changed without re-enrolling. This is the
  same decision as the brand question below.
- Reinstall signed builds on physical iPhone and Watch under the final team and repeat the
  physical matrix above.
- Create the App Store Connect record, publish the privacy-policy URL, archive a Release build,
  upload it, complete export-compliance/privacy metadata, and distribute through TestFlight.
- Prepare an App Review Notes rationale for the background-audio design, and decide the fallback
  if Guideline 2.5.4 is raised. Since build 9 there is no notification path left anywhere, so a
  rejection has nothing to fall back on.

## First-release scope

Decided 24 August 2026: the first App Store release ships as **2.0.0**, for **iPhone and Apple
Watch only**, and covers **sittings only** — Awareness is held for a later release.

The marketing version stays 2.0.0 rather than restarting at 1.0.0. The repository's own history
records a 1.0.0 (the timer-parity app) and the 2.0.0 redesign, so renumbering the first store
release would contradict a public changelog. Apple accepts any starting version.

Awareness is complete and still fully tested, gated by `PracticeFeatures.awarenessEnabled` in
`VipassanaTimer/Core/PracticeFeatures.swift`. It is out of 1.0 because it concentrated three
risks that sittings do not carry: its Watch screen needs the redraw rework (system-ticked
`Text(timerInterval:)` rather than an app-driven ticker), its battery cost over a multi-hour
session is unmeasured on both platforms, and a practice that can hold an audio session open for
up to 24 hours is the weakest point of a Guideline 2.5.4 review now that no notification fallback
exists. A 2-hour sitting is a straightforward story to defend; a 24-hour near-silent keepalive is
not. Cutting it retired all three at once.

Restoring it later means: flip the flag, redo the Watch countdown around system-ticked
primitives, measure battery over a real multi-hour session, re-add `StartAwarenessIntent` and its
App Shortcut (removed rather than gated, because `AppShortcutsBuilder` does not take
conditionals), restore the widget's Awareness quick link, and add back an Awareness screenshot.

Guided stays in 1.0. Its voice takes carry embedded ElevenLabs C2PA content credentials, so the
provenance record must say generated rather than self-recorded; the bell is genuinely the
project's own recording. Neither is licensed for reuse under the MIT grant — see
[`../ASSET_LICENSES.md`](../ASSET_LICENSES.md) — and both ship bundled inside the app. The app targets
are declared `TARGETED_DEVICE_FAMILY = 1`, so the App Store listing is iPhone-only and no iPad
screenshots are required. macOS stays in `SUPPORTED_PLATFORMS` so the Mac app keeps building and
CI keeps running the Mac test suite; it is simply not submitted. Revisit iPad and Mac after the
first release is stable.

## The Apple Watch in this release

Decided 24 August 2026: **the Watch app is not in the first release.** The iOS target no longer
embeds it — the Embed Watch Content phase and its target dependency were removed from the app
target, and a built `.app` now contains no `Watch/` directory.

The Watch targets stay in the project and CI still builds them, so nothing is lost and restoring
is a two-line change to `project.pbxproj`. Consequences worth holding on to: no watchOS
screenshots are required, no silent keepalive ships anywhere, and the copy no longer promises
iPhone-to-Watch history exchange — that feature only exists when both apps are installed.

## The public repository

This repository begins at the first public release. The development history that preceded it —
every branch, and the working design records — stays in a separate private archive, so the public
tree contains the product and nothing else.

- Done: README repositioned as an independent privacy-first practice timer. No reference-app
  framing remains anywhere in the tree or its history.
- Done: `CONTRIBUTING.md` and `SECURITY.md` added.
- Done: [`practice-log-and-notes.md`](practice-log-and-notes.md) holds the live session-notes
  contract, records the retired notification voice so it is not revived by accident, and states
  the cue-delivery contract for audio.
- Done: working records (design reports and exploration mockups) are excluded, not merely
  untracked — they were never committed here.
- Enable GitHub private vulnerability reporting immediately **after** the repository goes public.
  The API returns 404 while it is private, so `SECURITY.md`'s advisory link stays broken until
  then.
- Done: the repository is public, private vulnerability reporting is enabled, and GitHub Pages
  serves the policy from `main` `/docs` at
  `https://ajrnair.github.io/VipassanaTimerApple/privacy.html` — the URL for App Store Connect.

## Parallel, non-blocking product decisions

- Primary brand and scope: a precise practice instrument versus a broader configurable ritual
  timer. “Vipassana” can remain descriptive, but the primary name should be distinct and the app
  should state that it is independent and not a substitute for instruction.
- Optional practices: meditation, breath awareness, body awareness, Reiki, or user-named rituals
  can share the timing mechanism, but presets and language should not imply that unlike traditions
  are interchangeable.
- Guided Practice: the specification is implementation-ready; its design history lives in the
  spec. Remaining before shipping: generate and accept the ElevenLabs masters, assemble the
  eight programs, implement playback in the app, and run the spec's on-device acceptance
  scenarios.
- Voluntary support: after the timer beta is validated, consider a passive webpage link from About.
  It must have no suggested amount, prompts, rewards, feature unlocks, or contribution tracking.

## Explicitly later

- Developer-operated accounts, cloud history, analytics, social features, streaks, subscriptions,
  and content-library expansion.
- Any guided voice that imitates a living or identifiable teacher, or any third-party recording
  without a verified distribution license.
