# Publishing from the new Apple Developer account

The account-gated half of [`roadmap.md`](roadmap.md). None of it blocks local engineering; all of
it blocks TestFlight and the App Store.

Release ships from the project's current Apple Developer team. The previous team must not be used;
its ID is the value replaced in step 3.

## 1. Account — enrolled, awaiting confirmation

Enrollment is submitted and the account is signed into Xcode. Apple's confirmation typically takes
a day or two for an individual enrollment and longer for an organization; check status at
developer.apple.com/account rather than waiting on the email. Nothing below can proceed until the
membership is active.

Two things to know rather than act on:

- The **entity type chosen at enrollment is fixed** and sets the seller name on the listing —
  your legal name for an individual, the organization's name otherwise. Changing it needs a new
  enrollment, so the brand decision in [`roadmap.md`](roadmap.md) has to work with what was chosen.
- Signing into Xcode with an Apple ID alone gives only a free Personal Team: 7-day profiles, no
  distribution. The paid membership is what makes the rest possible.

Once active, accept **Business → Agreements** in App Store Connect. A free app needs only the
Free Applications agreement; banking and tax forms matter only if it is ever paid.

## 2. Xcode — add the account, don't replace it

Xcode → Settings → Accounts → **+**. Keep the previous account signed in too; both appear as
separate teams, and older archives stay signable.

## 3. Point the project at the new team

Bundle identifiers are already migrated:

| Target | Identifier |
|---|---|
| App | `com.arn.vipassanatimer` |
| Tests | `com.arn.vipassanatimer.tests` |
| Home Screen widget | `com.arn.vipassanatimer.widgets` |
| Watch app | `com.arn.vipassanatimer.watchkitapp` |
| Watch complication | `com.arn.vipassanatimer.watchkitapp.widgets` |

Only the team ID is left. From the repository root, with the real value for `NEWTEAMID`:

```bash
sed -i '' 's/OLDTEAMID/NEWTEAMID/g' VipassanaTimer.xcodeproj/project.pbxproj
```

The old ID is whatever `grep DEVELOPMENT_TEAM VipassanaTimer.xcodeproj/project.pbxproj` currently
reports.

All eight occurrences should change and nothing else:

```bash
git diff --stat
```

Signing is Automatic everywhere, so Xcode registers the five App IDs and issues certificates on
first build. Then confirm **HealthKit** is enabled on the App ID for `com.arn.vipassanatimer` —
it is the only special capability, and automatic signing will not add it.

**Why the identifiers changed.** Bundle IDs are globally unique across the App Store and cannot be
held by two teams at once, and App Store Connect's transfer flow only moves already-published
apps. Renaming before launch is free.

**One local consequence.** A new bundle ID means a new storage container, so the renamed build
installs as a separate app with an empty log. Existing device-test history stays in the old app.

## 4. App Store Connect record

**Apps → +** under the new team: platform **iOS only** for this release — the Watch app ships
inside the iOS app and gets no record of its own, and Mac and iPad are out of scope. Bundle ID
`com.arn.vipassanatimer`, any SKU.

Then the metadata that has to be decided rather than copied:

- **Name and subtitle** — gated on the brand decision in [`roadmap.md`](roadmap.md).
- **Privacy Policy URL** — required, and must be publicly reachable at submission. An in-app page
  does not satisfy it. See [`app-store-privacy.md`](app-store-privacy.md); the repository has to be
  public first.
- **Support URL** — also required. The public repository's issues page works.
- **Screenshots** — iPhone 6.9" (1320x2868) and Apple Watch are the only required sets, now that
  the app is declared iPhone-only (`TARGETED_DEVICE_FAMILY = 1`). The iPhone set is captured; the
  Watch set is pending the Watch app work. See [`app-store-listing.md`](app-store-listing.md).
- **App privacy** — answer exactly as in [`app-store-privacy.md`](app-store-privacy.md): no data
  collected, no tracking.
- **Category** — Health & Fitness, matching `LSApplicationCategoryType`.
- **Age rating** — the questionnaire; nothing objectionable.
- **Export compliance** — `ITSAppUsesNonExemptEncryption` is already `false`, so no prompt.

## 5. Archive and upload

With "Any iOS Device (arm64)" selected: **Product → Archive**, then **Distribute App → App Store
Connect**. There is no second Mac archive for this release. Before archiving, confirm the Release
configuration carries the new team and that `VERSION`, `MARKETING_VERSION`, and
`CURRENT_PROJECT_VERSION` agree.

## 6. Known review risk: background audio

Every gong on every platform is app audio, under `UIBackgroundModes: audio` and
`WKBackgroundModes: audio`.

On iPhone this is no longer a keepalive: `PracticeGongPlayer` schedules the whole sitting's gongs
onto one `AVAudioEngine` player at exact offsets, so no silent asset exists and the session only
ever carries content the user asked for. Confirmed on device on 24 August 2026 — a locked,
pocketed iPhone sounded its closing gongs on time — so the design holds and the App Review Notes
can state plainly that the app plays only the cues the user scheduled.

`WatchAppModel` still uses a near-silent looping player. It is now the only silent keepalive left
in the product and should be brought to the same design before submission.

Inaudible audio used to stay alive in the background is a known **Guideline 2.5.4** rejection
pattern. The design is defensible — the session delivers gongs the user scheduled during a practice
they started, and constitution 2.1.0 permits exactly that — but the silent stretches are what a
reviewer would question, and since build 9 there is no notification path left to fall back on.

So: put the rationale in App Review Notes proactively, and decide the fallback before submitting
rather than during an appeal.

## 7. Don't skip

- The GitHub account is unrelated to the Apple one. The repository stays at
  `ajrnair/VipassanaTimerApple` and the in-app About links stay valid.
- Making the repository public is a prerequisite for the privacy and support URLs.
- Re-run [`release-test-plan.md`](release-test-plan.md) on device under the new team's signing.
  New provisioning changes how audio, HealthKit, and WatchConnectivity behave.
