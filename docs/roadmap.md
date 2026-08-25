# Release roadmap

Updated 24 August 2026. This file records what ships and what remains for the current release.
Guided Practice remains a separate pull request and is intentionally not included in the
release-critical path below.
## Submitted

**2.0.0 (28), submitted 25 August 2026, Waiting for Review.**
Submission ID `dce608f6-e109-4574-b799-a4e5f0561a3b`, app `6804852110`, team `D649A7DJ44`,
bundle `com.arn.aplacetosit`. Listed as **A Place to Sit**; the app on a device still says
Vipassana Timer, which is deliberate.

Two upload rejections on the way, both worth remembering:

- The screenshots were the wrong size for the slot. 6.9-inch is 1320x2868; the 6.5-inch slot
  wants 1284x2778. Apple scales down from 6.9, so one set is enough.
- `NSHealthShareUsageDescription` is required of any app that *includes* HealthKit, whether or
  not it reads. Error 90683. The app requests `read: []` and still had to carry the string.

**Not yet verified: a Release build on hardware.** Every device test through this whole effort
used a development build, and Release compiles differently. Version release is manual, so there
is a window between approval and going live — use it. Install 2.0.0 (28) through TestFlight and
sit one locked-phone sitting before releasing.

**The open review risk is Guideline 2.5.4.** The App Review Notes argue the case: the audio
session exists to sound gongs the user scheduled, starts only on an explicit start, and ends with
the practice. If it is raised anyway, the fallback is in `app-store-release.md`.

## First-release scope

Decided 24 August 2026: the first App Store release ships as **2.0.0**, for **iPhone and Apple
Watch only**, and covers **sittings only**. Awareness practice is held for a later release; it is
complete and fully tested behind `PracticeFeatures.awarenessEnabled` in
`VipassanaTimer/Core/PracticeFeatures.swift`.

The marketing version stays 2.0.0 rather than restarting at 1.0.0, because the repository's own
history already records a 1.0.0 and the 2.0.0 redesign. Apple accepts any starting version.

Guided Practice stays in the 1.0 scope. Its voice takes and bell are bundled in the app and are
not licensed for reuse under the MIT grant — see [`../ASSET_LICENSES.md`](../ASSET_LICENSES.md).

The app targets are declared `TARGETED_DEVICE_FAMILY = 1`, so the App Store listing is iPhone-only
and no iPad screenshots are required. macOS stays in `SUPPORTED_PLATFORMS` so the Mac app keeps
building and CI keeps running the Mac test suite; it is not submitted. iPad and Mac are revisited
after the first release is stable.

## Ready in the repository

- Standard sittings and 1–24 hour Awareness practice, with gongs delivered as app audio on
  iPhone and recovery on every platform.
- Editable session history with optional notes shown only after opening a saved session.
- Optional write-only Apple Health Mindful Minutes export.
- Direct iPhone–Apple Watch history exchange, including edit and deletion convergence.
- iPhone and independent Watch apps (iPad and Mac build but are out of scope for the first
  release); Home Screen widget; Watch complications; App Intents, Shortcuts, and deep links.
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
- Decide whether the inactive Watch path should keep Apple's system cue or attempt the bundled
  custom gong; current APIs permit a named sound, but its physical presentation is not yet verified.
- Complete VoiceOver, hardware-keyboard, increased-contrast, and reduced-motion passes on all
  supported platforms.
- Complete the product's primary name and non-affiliation decision before public marketing.

## Waiting for the new Apple developer team

The full procedure is [`app-store-release.md`](app-store-release.md). Status:

- Done: production bundle identifiers migrated to `com.arn.vipassanatimer*` across all five
  targets, with both unsigned platform builds passing.
- Blocked on enrollment: activate the new Apple Developer Program membership, accept current
  terms, then replace `DEVELOPMENT_TEAM` and re-enable HealthKit on the new team's App ID.
- Decide the enrollment entity type before enrolling; it cannot be changed without re-enrolling.
- Reinstall signed builds on physical iPhone and Watch under the final team and repeat the
  physical matrix above.
- Create the App Store Connect record, publish the privacy-policy URL, archive a Release build,
  upload it, complete export-compliance/privacy metadata, and distribute through TestFlight.
- Prepare App Review Notes covering the background-audio design.

## Before making the repository public

- Done: README repositioned as an independent privacy-first practice timer.
- Done: `CONTRIBUTING.md` and `SECURITY.md` added, with private vulnerability reporting.
- Publish `docs/` with GitHub Pages, or accept the `PRIVACY.md` blob-URL fallback recorded in
  [`app-store-privacy.md`](app-store-privacy.md). A reachable privacy URL is required at
  submission either way.
- Done: `practice-log-and-notification-design.md` renamed to `practice-log-and-notes.md`; the live
  session-notes contract is kept, the notification voice is recorded as retired, and the cue
  contract now describes audio delivery.
- Done: working records untracked and gitignored (tracked size 30.4 MB to 24.7 MB). They remain on
  disk and in git history, which a history rewrite would be needed to clear.
- Enable GitHub private vulnerability reporting immediately **after** the repository goes public —
  the API returns 404 while it is private, so `SECURITY.md`'s advisory link stays broken until then.

## Not planned

- Developer-operated accounts, cloud history, analytics, social features, streaks, subscriptions,
  and content-library expansion.
- Any guided voice that imitates a living or identifiable teacher, or any third-party recording
  without a verified distribution license.
