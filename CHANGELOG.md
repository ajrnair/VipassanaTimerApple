# Changelog

All notable changes to Vipassana Timer for Apple platforms are recorded here.
Version numbers follow `marketing.build`: the marketing version (2.0.0) is what users see,
and the build number increases with every installed build. `VERSION`, the Xcode project,
and this file always carry the same numbers.

## 2.0.0 (build 17) — 2026-08-24

- The top of every screen now behaves like the bottom: the screen's name and
  its controls stay put while the screen scrolls, and content fades out into
  the top of the field rather than sliding under a hard edge. The info button
  is reachable wherever you have scrolled to, which it was not before.
- The large title still scrolls, so the field keeps its depth and only the
  chrome is fixed.

## 2.0.0 (build 16) — 2026-08-24

- Sittings no longer play silence to stay awake. Every gong for the whole
  sitting is now scheduled onto one audio player the moment you begin, at an
  exact offset, and the quiet between gongs is simply the gaps in that content.
  Nothing audible changes; what changes is that the app is only ever playing
  the gongs you asked for, with no silent track running underneath and no
  once-a-second timer driving playback.
- Gong timing no longer depends on the app receiving a callback while your
  screen is off — the same guarantee the timer core already made.

## 2.0.0 (build 15) — 2026-08-24

- A new recording of the opening guidance, and it now begins sooner. The voice
  used to wait twelve seconds after the start gong; it now starts at eight, so
  there are about four seconds of quiet after the gong rings rather than eight.
- The new take runs 34.4 seconds against the previous 30.6, which the schedule
  absorbs without moving anything else: the opening has ninety-three seconds
  before the next guidance begins. All four Guided programs were reassembled
  and each still lands exactly on its planned length.

## 2.0.0 (build 14) — 2026-08-24

This is the build prepared for the first App Store release.

- **Awareness is not in this release.** The 1-to-24-hour interval bell is
  finished and still fully tested, but it is held back. Its Watch screen still
  redraws on an app-driven timer rather than letting watchOS tick the countdown,
  nobody has measured what a multi-hour session costs in battery, and a practice
  that can hold an audio session open for up to 24 hours is the weakest point of
  an App Store review under Guideline 2.5.4 — there is no notification fallback
  left to retreat to. A two-hour sitting is a straightforward story to defend.
  Sittings, Guided, the log, Health export, and the Watch app are unaffected;
  restoring Awareness is one flag in `PracticeFeatures`.
- **iPhone and Apple Watch only.** The app is declared iPhone-only, so the store
  listing needs no iPad screenshots. The Mac target still builds and its tests
  still run in CI; it is simply not submitted yet.
- Notifications are gone from the source, not just from the delivery path. Only
  a launch-time cleanup remains, clearing any notification left behind by a
  build from before gongs became app audio. The app requests no notification
  permission on any platform.
- The Watch app was missing a required privacy-manifest declaration for the
  preferences it stores. That is an automatic rejection at upload, now fixed.
- The privacy policy described notification-delivered gongs the app no longer
  has, and told you to revoke a permission it never asks for. Corrected.
- New production identifiers under the project's own Apple Developer team.
  Existing installs from a development build appear as a separate app with an
  empty log, because a new identifier means new storage.

## 2.0.0 (build 13) — 2026-08-24

- The Awareness screen (and every other running screen) felt laggy on the
  watch: the ticker that keeps gong cues on time runs four times a second,
  and it was marked `@Published`, so each tick forced the whole screen —
  gradient field, aperture ring, and all — to relayout and repaint, even
  though the displayed countdown only changes once a second. The ticker still
  runs at the same rate for cue precision, but the screen now only redraws
  when the displayed second actually changes.

## 2.0.0 (build 12) — 2026-08-24

- Starting Awareness from the watch left the setup screen on top of the stack
  looking untouched, while the countdown had genuinely already begun
  underneath it: the app's navigation stack didn't know the root view had
  switched to the running screen, so nothing popped the stale setup screen out
  of the way. It now clears the navigation path itself whenever a session
  starts or a completion appears.
- Every screen's bottom margin is deliberately more generous now, and a small
  scroll to reach the end control is treated as fine rather than something to
  eliminate — simulator measurements had not been predicting the real margin
  on device.

## 2.0.0 (build 11) — 2026-08-24

- The watch's Begin button was still cut off on the 40 mm, on both Sit and
  Awareness — Awareness worst of all, because its visible system title bar
  (a back chevron and "Aware") cost as much vertical room as the ring itself.
  Both screens now fit without scrolling, measured directly against the 40 mm's
  real pixels rather than judged by eye; Awareness keeps a real way back, a
  small button that costs no layout space rather than the system bar.
- The End control on every sitting screen was a filled grey shape that read as
  inert. It is a hairline capsule now, at rest, and fills in only when pressed
  — the tap itself confirms the touch landed, instead of the button looking
  "pressed" the whole time.

## 2.0.0 (build 10) — 2026-08-24

- The watch's session screens — preparation, sitting, awareness, completion —
  sat outside the app's navigation stack, so they had none of the safe-area
  margin watchOS gives everything else: the eyebrow ran under the system clock
  and the end control was cut off by the bottom edge. All four now share one
  navigation stack and fit within it, on both the 40 mm and 49 mm.

## 2.0.0 (build 9) — 2026-08-24

- Watch gongs are app audio now, as they already are on iPhone, iPad and Mac.
  They sound through whatever the watch is playing to and are no longer silenced
  by the Silent switch or by a Focus. The live audio session also keeps the app
  running once the wrist drops, which is what had let watch gongs fail to arrive
  at all. The watch asks for no notification permission.
- Watch text no longer truncates. "Time observed." had been squeezed to "Time…"
  on the 40 mm because it was compressed rather than allowed a second line;
  completion now scrolls, and every fixed-size string can wrap or shrink.
- Watch controls look like controls: ending a sitting and finishing a session are
  real buttons rather than bare tappable text.
- The marketing version is 2.0.0; this note is what `VERSION` and the project
  carry too.

## 2.0.0 (build 8) — 2026-08-24

- Turning the Awareness ring now shows an arc and a knob that follow your finger,
  so it is clear the ring is the control and where it currently sits. One and two
  minute gong intervals join the choices.
- The Sit and Awareness screens remember the duration and interval you chose last.
- Log rows carry only the weekday and day; the month heading above them already
  says which month and year. Sittings under a minute never appear, even if an
  earlier build stored them.
- Content fades out further above the bottom navigation, so rows no longer collide
  with the labels as they scroll past.
- The add and info buttons are the same hairline circle at the same size, rather
  than a circle beside a much smaller glyph.
- The appearance choice moves to the top of the info page, which no longer carries
  a title above a page that already names itself.

## 2.0.0 (build 7) — 2026-08-23

Brings the build back in line with the Ganzfeld design boards, which it had
drifted from in geometry and type.

- The aperture was twice its specified size on every screen, because it scaled
  from the long edge of the display rather than the short one. A glow wider than
  the screen reads as an even wash, not an aperture, so its growth across a
  sitting was invisible. It is now the size the boards specify.
- The vignette was a circle where the boards use an ellipse, so it never reached
  the left and right edges and the field read flat. It now darkens the surround
  as intended, which is also what lets the aperture read as luminous.
- Ring numerals were a single shared text style at less than half their specified
  size, leaving the numeral floating inside a ring drawn to frame it. Sit and
  Awareness now use 78 point, preparation 72, and a running sitting 62, all still
  scaling with Dynamic Type.
- The bottom navigation had grown a line and a filled bar across it. It floats in
  the field again, resting on a scrim that fades up from the foot of the screen.
- Awareness adopts its board: the duration is chosen by turning the ring and the
  interval from 5, 10, 15, 30, or 60 minutes, replacing two typed fields and
  their steppers. Other intervals remain available through Shortcuts and the URL
  scheme. Because gongs no longer arrive as notifications on iPhone, iPad, or
  Mac, the 64-gong ceiling no longer applies there; the Watch keeps it.
- The Sit screen drops the two trailing lines of copy the boards do not have, and
  marks the selected duration by weight alone — the underline belongs to the
  practice-style row.
- The log gets its board's circular add button, hairline switch, and month
  headings, and editing a session no longer rewrites its recorded duration and
  start time.

## 2.0.0 (build 6) — 2026-08-23

- Standard sittings now play their start, warning, and completion gongs as app audio, the
  same delivery Awareness gained in build 4: through headphones or AirPods when connected,
  otherwise the speaker; locked or unlocked; unaffected by the Silent switch, Focus, or
  notification settings. The app schedules no notifications anywhere and no longer asks for
  notification permission; the locked-screen-gongs readiness card is gone.

## 2.0.0 (build 5) — 2026-08-23

A new visual language, after James Turrell's Light and Space work. The screen is
a field of graded light with a warm aperture rather than a page of cards.

- The aperture is the clock. It grows from barely-there during the eight
  preparation seconds to full bloom at completion, so a glance reads roughly how
  far along a sitting is without reading a number — and the session ends in
  light, which is what the three closing gongs already do in sound.
- One rule keeps the language coherent: the aperture is brightest where there is
  least content. It blooms on the session screens and recedes behind the log.
- Two fields, one language. Night and Dawn are the same design at two times of
  day, not two designs: identical hairlines, aperture and structure, with only
  the field inverted. Appearance follows the system by default and can be set
  explicitly under the info button.
- Cards, filled pills and the tab bar's surface are gone. Selection is an
  underline, buttons are outlines, and rows are separated by hairlines.
- The Sit screen's custom-minutes field is gone; the five presets remain, and
  arbitrary durations are still available through Shortcuts and the URL scheme.
  Awareness keeps free entry for both hours and interval, because intervals are
  idiosyncratic and the default of ten minutes is not a preset.
- Every colour was measured against the field's real falloff so text, hairlines
  and the accent clear WCAG AA at the brightest point of each screen. A light
  field needs heavier hairlines than a dark one, so Dawn's are 58% ink where
  Night's are 48% white.

## 1.0.0 (build 4) — 2026-08-23

- Awareness gongs now play as app audio: through headphones or AirPods when connected,
  otherwise the speaker; locked or unlocked; unaffected by the Silent switch, Focus, or
  notification settings. Awareness no longer sends notifications or asks for notification
  permission.
- The hold-to-end button fills visibly while held, and screen copy and spacing are tightened
  across the app.

## 1.0.0 (build 3) — 2026-08-23

- The session cues are now the app's own bell recording: a 4-second start bell and a
  12-second triple completion bell.
- Guided practice device trial: 15, 30, 45, and 60-minute sittings can play a full voice
  instruction arc; Silent stays the default.
- The tab bar now fades away during practice; nothing else competes for attention.
- Ending a sitting now takes press-and-hold instead of one accidental tap.
- The Awareness screen now shows when the next gong will sound.
- Editing a log note no longer rewrites the session's recorded details, and sittings under
  one minute are no longer logged.
- The idle screens no longer refresh four times a second; the timer ticks only while a
  session runs.
- The Add session control is now a quiet + in the log header, the empty log explains that
  sessions stay on this device, the light-mode accent meets the AA contrast bar, and the
  sitting screen no longer truncates at the largest accessibility sizes.

## 1.0.0 (build 2) — 2026-08-23

- Sittings now resist double starts, stale callbacks, duplicate completion, and cancellation races.
- The meditation log can now be edited, carry discreet private notes, and keep additions, edits,
  and deletions aligned between iPhone and Apple Watch.
- Completed sittings can optionally be written to Apple Health as Mindful Minutes without duplicate
  exports.
- iPhone and Mac widgets, Watch complications, App Shortcuts, and deep links now provide quick starts.
- Locked-screen gong diagnostics now check Immediate Delivery and use quieter notification language.
- Gong assets now use broadly compatible linear PCM audio; locked-iPhone playback was verified on
  physical hardware when the phone owned notification delivery.
- Health export completion preserves later note and duration edits, and cannot recreate a deleted log.
- Pending Health exports resume after relaunch, while denied or revoked write access leaves the
  in-app Health switch accurately disabled.
- Repeated or malformed deep-link parameters are handled safely instead of terminating the app.
- Privacy disclosures now precisely cover local notes, Watch exchange, Health writing, and Apple’s
  required-reason APIs.
- The release pipeline now runs 29 behavioral tests through SwiftPM, Xcode, and CI, and
  compiles unsigned iOS and watchOS builds on every change.
- iPad now declares full rotation support, while compact-phone layouts, typography, and spacing are
  more polished.
- The persistent phone navigation now reserves its measured height and stays compact at the largest
  accessibility text sizes without limiting the practice screens themselves.
- A standalone, public-ready privacy page now mirrors the repository policy and exact App Store
  privacy answers.
- A discreet in-app About & Privacy page now makes the local-data promise, optional write-only
  Health behavior, public source, MIT license, separate audio terms, and independent status easy
  to inspect before the first TestFlight beta.

## 1.0.0 (build 1) — 2026-08-22

- Added native SwiftUI apps for iPhone, iPad, Mac, and Apple Watch.
- Built the sitting flow, preparation period, warning gong, completion gongs, and meditation log.
- Added programmable Awareness sessions from 1 to 24 hours with validated reminder intervals.
- Added local notification delivery, session recovery, and offline persistence.
- Added the limestone, evergreen, patina, and laterite visual system, including light and dark appearances.
- Added repeatable core checks, product specifications, design-audit evidence, and ElevenLabs voice-production scripts.
