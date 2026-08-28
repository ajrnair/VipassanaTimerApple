# Release roadmap

Updated 27 August 2026. This file records what ships and what remains for the current release.

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

Decided 24 August 2026: the first App Store release ships as **2.0.0**, for **iPhone only**, and
covers **sittings and Guided practice**.

Two things are finished in the repository and deliberately held back:

- **Awareness practice** (1–24 hour) is complete and fully tested behind
  `PracticeFeatures.awarenessEnabled` in `VipassanaTimer/Core/PracticeFeatures.swift`.
- **The Apple Watch app** builds and its tests run, but the iOS target no longer embeds it and it
  is not in the submission. App Store Connect therefore asks for no watchOS screenshots.

The marketing version stays 2.0.0 rather than restarting at 1.0.0, because the repository's own
history already records a 1.0.0 and the 2.0.0 redesign. Apple accepts any starting version.

Guided Practice is in the release. Its voice takes and bell are bundled in the app and are not
licensed for reuse under the MIT grant — see [`../ASSET_LICENSES.md`](../ASSET_LICENSES.md).

The app target is declared `TARGETED_DEVICE_FAMILY = 1`, so the listing is iPhone-only and no iPad
screenshots are required. macOS stays in `SUPPORTED_PLATFORMS` so the Mac app keeps building and
CI keeps running the Mac test suite; it is not submitted. iPad, Mac, and the Watch are revisited
after the first release is stable.

## Ready in the repository

Everything here builds and is tested. What the first release actually ships is narrower — see the
scope section above.

- Standard sittings and 1–24 hour Awareness practice, with gongs delivered as app audio on
  iPhone and recovery on every platform.
- Editable session history with optional notes shown only after opening a saved session.
- Optional write-only Apple Health Mindful Minutes export.
- Direct iPhone–Apple Watch history exchange, including edit and deletion convergence.
- iPhone and independent Watch apps; iPad and Mac build; Home Screen widget; Watch complications;
  App Intents, Shortcuts, and deep links.
- Privacy manifests, a published privacy page, exact App Store privacy answers, and a physical
  release-test checklist.
- A compact in-app About & Privacy page, MIT source license, and separate bundled-audio terms.
- 50 deterministic core tests wired into both SwiftPM and the Xcode test target.
- CI gates for SwiftPM tests, Xcode tests, executable smoke checks, and unsigned iOS/watchOS builds.
- Simulator layout review on iPhone, iPad mini, 40 mm Watch, light/dark appearance, and the largest
  iPhone accessibility text size.

## Before releasing an approved build

- Install 2.0.0 (28) through TestFlight and run a **Release** build on a physical iPhone, including
  one locked-phone sitting. This is the only material check the whole effort has never done.
- Run a focused accessibility safety check: confirm essential controls have useful VoiceOver names,
  larger text does not hide actions, and starting, ending, and saving remain operable.

## After the first release

- Finish the physical audio-delivery matrix on iPhone: locked, backgrounded, Silent Mode, a Focus,
  and an interruption (call, another app) mid-sitting.
- Complete VoiceOver, hardware-keyboard, increased-contrast, and reduced-motion passes.
- When the Watch app returns to the release: run the Watch notification-routing matrix (on-wrist
  unlocked, removed, locked), and decide whether its inactive-state path keeps Apple's system cue
  or attempts the bundled custom gong. Current APIs permit a named sound, but its physical
  presentation is unverified.
- Revisit Awareness, iPad, and Mac as shipped platforms.

## Done

- **Apple Developer team.** Enrolled and active as `D649A7DJ44`. Production identifiers are
  `com.arn.aplacetosit*` across all targets, HealthKit is enabled on the App ID, the App Store
  Connect record exists, and a Release build has been archived, uploaded, and submitted.
- **The repository is public**, with `CONTRIBUTING.md`, `SECURITY.md`, and GitHub private
  vulnerability reporting enabled.
- **The privacy policy is published** at `aplacetosit.in` via GitHub Pages, so the URL Apple has
  on file resolves. The blob-URL fallback recorded in
  [`app-store-privacy.md`](app-store-privacy.md) is no longer needed.
- **The name and non-affiliation decision.** The store name is *A Place to Sit*; the README, the
  in-app About page, and the landing page each state that this is an independent practice tool,
  affiliated with no school, teacher, lineage, or organisation, and not a substitute for
  instruction.
- `practice-log-and-notification-design.md` renamed to `practice-log-and-notes.md`; the live
  session-notes contract is kept, the notification voice is recorded as retired, and the cue
  contract describes audio delivery.
- Working records untracked and gitignored (tracked size 30.4 MB to 24.7 MB). They remain on disk
  and in git history, which a history rewrite would be needed to clear.

## Not planned

- Developer-operated accounts, cloud history, analytics, social features, streaks, subscriptions,
  and content-library expansion.
- Any guided voice that imitates a living or identifiable teacher, or any third-party recording
  without a verified distribution license.
