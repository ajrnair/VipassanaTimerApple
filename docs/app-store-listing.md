# App Store listing copy

Ready to paste into App Store Connect. Character counts are Apple's limits and have been
validated. Voice: simplicity and trust — say what it does, say what it doesn't do, don't sell.

The app name is still subject to the open brand decision in [`roadmap.md`](roadmap.md); everything
else below works with either outcome.

## Name — 15/30

```
Vipassana Timer
```

## Subtitle — 24/30

```
A quiet meditation timer
```

## Keywords — 93/100

Comma-separated, no spaces. Deliberately excludes "vipassana" and "timer" — Apple already indexes
the name and subtitle, so repeating them wastes the field.

```
meditation,mindfulness,gong,bell,silent,offline,private,zazen,breath,sitting,anapana,quiet
```

## Promotional text — 155/170

Editable any time without a new build, so this is the field to change if messaging shifts.

```
No account, no tracking, no streaks. Just a gong, the time you chose, and quiet. Works offline. Free and open source, so the privacy claims can be checked.
```

## Description

```
A quiet timer for sitting practice.

Choose a length. A gong to begin, three to close. Nothing in between.

WHAT IT DOES

Sittings of 15, 30, 45, 60, or 120 minutes. Eight quiet seconds to settle before the first gong. A
gentle warning five minutes from the end of longer sittings. Three gongs to close.

A simple log of what you have sat. Edit it, add a private note, or delete it. Ending early records
only the time you actually sat.

Gongs play as ordinary audio, so they arrive whether the screen is locked or dark, through
headphones or the speaker, and are not silenced by the Silent switch or by a Focus.

Optionally record completed sittings to Apple Health as Mindful Minutes. Off by default.

ON YOUR WRIST

A standalone Apple Watch app that runs without your iPhone. Presets, any length up to four hours by
turning the Digital Crown, its own log, gongs and haptics. Your log moves
between iPhone and Watch directly, with no server in the middle.

WHAT IT DOESN'T DO

No account. No sign-in. No advertising. No analytics. No tracking. No cloud. No streaks, scores,
badges, or reminders to come back.

The timer works with no network connection at all. Your practice history, your notes, and your
settings stay in storage owned by the app on your own devices. They are never sent to the
developer, because there is nowhere for them to be sent.

WHY YOU CAN BELIEVE THAT

The entire source code is public under the MIT License. Anyone can read exactly what the app does
with your practice, and check that these claims are true rather than take them on trust.

INDEPENDENT

Vipassana Timer is an independent tool. It has no affiliation with any meditation school, teacher,
lineage, or teaching organization, and it is not a substitute for instruction.
```

## What's New — first release

```
The first release.

A quiet timer for sitting practice, on iPhone and Apple Watch. No account, no
tracking, and no network required. Open source, so the privacy claims can be checked.
```

## URLs

| Field | Value |
|---|---|
| Privacy Policy URL | Required. GitHub Pages at `docs/privacy.html`, or the `PRIVACY.md` fallback in [`app-store-privacy.md`](app-store-privacy.md). Needs the repository public. |
| Support URL | Required. The public repository's issues page. |
| Marketing URL | Optional. Leave blank. |

## App Review Notes

Paste this. It answers the two questions this app predictably raises before they are asked.

```
No account is needed. There is no sign-in, no server, and no test credentials to provide. Every
feature is reachable immediately on launch.

BACKGROUND AUDIO

The app declares the audio background mode because its entire purpose is to sound a bell at times
the user chose, while the screen is off and the device is in a pocket. A meditation timer whose
bell does not arrive has failed at the one thing it does.

The audio session is started only when the user explicitly begins a sitting or an interval
practice, and it is ended as soon as that practice completes or the user stops it. It is never
started or held outside an active, user-initiated practice. Between bells the session stays open so
the bell timeline stays accurate; the audible content is the bells the user asked for.

To verify: start a 15-minute sitting, lock the device, and the closing bells arrive on time. Stop
the sitting and the audio session ends with it.

PRIVACY

The app collects no data. There is no analytics, tracking, advertising, or third-party SDK, and no
network code at all. Apple Health access is optional, off by default, and write-only — completed
sittings recorded as Mindful Minutes. The app never requests permission to read Health data.

The full source is public at github.com/ajrnair/VipassanaTimerApple, so every claim above can be
verified directly in the code.
```

## Screenshots

Because the app is declared iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), Apple requires just two
sets: **iPhone 6.9" (1320x2868)** and **Apple Watch**. No iPad or Mac sets are needed.

The iPhone set is captured, in this upload order — the first three are what most people actually
see, so they carry what it is, what it feels like, and why it can be trusted:

| # | File | Screen |
|---|---|---|
| 1 | `1-a-place-to-sit.png` | Home, Dawn — "A place to sit", the five lengths |
| 2 | `2-in-silence-night.png` | Running, Night — "In silence", 44:08 remaining |
| 3 | `3-private-by-design.png` | About — "Private by design", the privacy claims |
| 4 | `4-meditation-log.png` | The log, with sittings |
| 5 | `5-in-silence-dawn.png` | Running, Dawn |
| 6 | `6-a-place-to-sit-night.png` | Home, Night |

Captured on iPhone 17 Pro Max at native resolution, so no scaling or padding is needed. The log
screenshot uses seeded sample sittings, not real practice data.

The Awareness screenshot was dropped when Awareness moved to 1.1 — do not ship a screenshot of a
feature the build does not contain; Apple treats that as a metadata rejection.

Apple accepts up to 10 per set and shows the first 3 in search results. Uploading fewer is fine;
dropping 5 and 6 keeps the set tighter if the repeated screens feel redundant.

**Apple Watch set: still needed.** Blocked on the Watch app work in progress. Required before
submission, since the release includes a watchOS app.

## Category and ratings

- Primary category: **Health & Fitness**, matching `LSApplicationCategoryType` in `Info.plist`.
- Secondary category: **Lifestyle**, or leave unset.
- Age rating: complete the questionnaire; nothing in the app is objectionable.
- Content rights: does not contain, show, or access third-party content.
