# Feature Specification: Guided Practice v2

**Feature Branch**: `[002-guided-practice]`

**Created**: 2026-08-22

**Status**: Guided implemented and shipping. Light guidance specified but not built.

**Input**: User description: "Add a simple, optional voice guide with three modes — Silent
(the existing timer and gongs), Light guidance (opening orientation and closing reflection),
and Guided (full breath and body-awareness sequence) — without weakening the faithful silent
timer."

## What this changes

The v1 timer is silent between gongs. Guided Practice adds an optional voice, and nothing else.

- Silent stays the default. A user who never opens the guide setting gets the v1 timer,
  including after updates.
- Guidance is sound only. It never changes credited time, completion, logging, recovery,
  Awareness, or gongs.
- Every asset ships in the app. No network, account, analytics, or download.
- Audio uses a `playback` session with the `audio` background mode, active only during a
  sitting the user started. (App Review 2.5.4: background modes must serve their stated
  purpose.)
- The setting, the mode names, and any errors work with VoiceOver and Dynamic Type.

## Modes

| Mode | Audience | Content | Supported sittings |
|---|---|---|---|
| Silent (default) | Everyone | None — existing timer and gongs | All durations, Awareness, Watch |
| Light guidance | Experienced meditators | Opening orientation (~12 s) + closing reflection (~48 s) | 15, 30, 45, 60-minute presets |
| Guided | New meditators | Settle, then anapana until one-third of the sitting, body scan, an equanimity reset at two-thirds (30 min and up), closing reflection | 15, 30, 45, 60-minute presets |

Any selection without a matching program — custom durations, the 120-minute preset, Awareness
mode, watchOS — runs silent. The mode picker must say so before the sitting starts, not fail
during it.

## Playback Architecture

Each mode and duration ships as one finished audio file: voice, gongs, and silence already in
place. Layouts live in [`audio/v2/cues.json`](../../audio/v2/cues.json), schema version 2.

Playback starts when the sitting starts and runs uninterrupted to the end of the closing
reflection. Every file opens with 8 seconds of silence covering the preparation, so the audio
session is live before the phone can lock. Voice and gongs sit in the same file: they share
one clock, so voice can never land on a gong.

Two designs were rejected. Sparse per-cue playback fails because nothing wakes a suspended app
to speak a cue. Mixing a playback clock with notification-delivered gongs fails because
notification delivery is not exactly timed — a late gong could land on the closing reflection.

No mode schedules a notification, ever — silent and awareness sittings already deliver their
gongs as app audio for the same reason. If playback pauses — interruption, route loss — it
simply pauses; on resume it seeks to the live offset. A voice segment or gong whose moment fell
inside the pause is skipped, never replayed late, exactly like every other session's
interruption behavior.

Two costs are accepted. Program audio, gongs included, ignores the ring/silent switch. And
force-quitting mid-program loses that sitting's remaining gongs — a narrow window, since
actively playing audio apps are kept alive. The timer and log still recover on relaunch
exactly as today.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete a Guided Sitting (Priority: P1)

A new meditator selects Guided mode and a 30-minute sitting, locks the phone after the start
gong, and receives the full instruction arc, gongs, and closing reflection without touching the
device again.

**Acceptance Scenarios**:

1. **Given** Guided mode and a 30-minute preset, **When** the sitting runs to completion with
   the device locked, **Then** settle, breath, sensations, and equanimity play at their manifest
   offsets and the closing reflection begins 2 seconds after the program's triple gong.
2. **Given** the same sitting, **When** any gong moment arrives, **Then** exactly one gong is
   heard — the program's own. No notification gong fires, and no voice overlaps a gong.
3. **Given** the same sitting, **When** it completes, **Then** the log records one 30-minute
   entry identical to a silent sitting's entry — guidance adds no fields and changes no values.
4. **Given** a 30-minute Guided sitting, **When** it runs, **Then** no five-minute warning gong
   plays; for 45 and 60-minute sittings the warning gong plays with no voice in its window.
5. **Given** the device is locked **during the eight-second preparation**, **When** the sitting
   proceeds, **Then** the full instruction arc still plays — playback began at sitting start
   with lead-in silence, so suspension during preparation cannot strand the program.

### User Story 2 - Light Guidance for an Experienced Meditator (Priority: P2)

An experienced meditator selects Light guidance for a 60-minute sitting and hears only the
opening orientation, the existing gongs, and the closing reflection.

**Acceptance Scenarios**:

1. **Given** Light guidance and any supported preset, **When** the sitting runs, **Then** voice
   plays only at 0:12 and after the completion gongs; the sitting is otherwise identical to
   silent mode, including the warning-gong rule.
2. **Given** Light guidance and an unsupported selection (custom duration, 120 minutes,
   Awareness), **When** the user confirms it, **Then** the app states before the start that this
   sitting will be silent, and runs it silently.

### User Story 3 - Interruption, Route Loss, and Termination (Priority: P1)

Guidance degrades without ever corrupting the sitting.

**Acceptance Scenarios**:

1. **Given** a program is playing and playback pauses (interruption or route loss), **When**
   a gong or voice moment falls inside the pause, **Then** it is skipped, never played late;
   **When** playback resumes, **Then** the player seeks to the live offset and continues from
   there without replaying anything the pause covered.
2. **Given** a phone call arrives mid-program, **When** the interruption ends and the system
   permits resumption, **Then** playback resumes at the current session offset — voice that fell
   inside the interruption is skipped, never replayed late — and credited time is unaffected.
3. **Given** headphones are disconnected mid-program, **When** the route is lost, **Then**
   playback pauses; resuming is user-initiated and seeks to the current session offset first.
4. **Given** playback was paused and the system then terminates the app, **When** the app
   relaunches, **Then** the timer and log recover exactly as they do today, but playback does
   not restart mid-sitting — any gong or voice moment inside the gap is not delivered.
5. **Given** any guided or light sitting is ended early, **When** the user confirms the early
   end, **Then** playback stops immediately, the closing reflection is skipped, and early-credit
   rules apply unchanged.

### User Story 4 - Silent Mode Is Untouched (Priority: P1)

**Acceptance Scenarios**:

1. **Given** a user who has never opened the guide setting, **When** they use every existing
   feature, **Then** the app is behaviorally identical to the silent build in timing and
   logging; no guided program plays, no voice is ever heard, and the `audio` background mode
   is never exercised. (Silent sittings already run their own gong-only audio session,
   independent of this feature.)
2. **Given** any mode, **When** Awareness mode runs, **Then** it is silent apart from its
   existing gongs.

## Functional Requirements

- **FR-1** Mode selection persists per mode (standard sittings only), defaults to Silent, and is
  changeable only before a sitting starts.
- **FR-2** When the selected mode and duration have a program, the app activates a non-mixing
  `playback` audio session and starts playback at sitting start, while still foregrounded.
  Starting at meditation start is too late: iOS keeps already-playing audio alive in the
  background but never wakes an app to start playing, so a phone locked during preparation
  would strand the program. The session deactivates at program end, at early end, when the
  user dismisses the completion screen, and when any new session starts. Pressing **Done**
  during the closing reflection stops playback immediately and never affects the log, which
  was written at completion. No session may begin while a prior program is still audible. The
  iOS target gains the `audio` background mode; macOS plays the same programs without it.
- **FR-3** Program playback position is always derived from the timer core's session offset —
  after interruption, route change, or user pause, resumption seeks to the live offset first.
- **FR-4** The lock screen exposes play/pause only; seeking and skip commands are disabled.
- **FR-5** Guidance state is never persisted as session truth: recovery after relaunch restores
  the timer per existing rules and does not resume mid-sitting playback.
- **FR-6** The manifest is the contract, and CI enforces it. `scripts/validate_guide_manifest.py`
  validates `audio/v2/cues.json` against the fixed v2 matrix — guided and light × 15/30/45/60
  only; any expansion fails — along with every offset, length, identity, sequence, and overlap
  rule, and its `--self-test` runs the committed negative cases. `GuideManifestTests`, in both
  the SwiftPM and Xcode test targets, ties the manifest's timing constants and warning
  expectations to the live `TimerEngine` values, so the contract cannot drift silently. Layout
  changes must keep all of it green.
- **FR-7** Shipped assets: eight program files, mono AAC `.m4a` 48 kHz, each mixing the mono
  48 kHz 16-bit PCM voice recordings (normalised to −19 LUFS integrated, peaks ≤ −3 dBFS)
  with the gong masters (`gong_start.caf`, `gong_end_triple.caf`) at their shipped
  levels, at the exact manifest offsets. Provenance (script SHA-256, model, voice, settings,
  seed, dates, asset SHA-256) is recorded in `docs/reference.md` before release.

## Out of Scope for v2

Custom-duration programs, the 120-minute preset, Awareness-mode guidance, watchOS playback,
languages beyond English, downloadable or user-provided audio, and any change to gong assets,
logging, HealthKit export, or Watch sync.

## Delivery Gates

1. Manifest validation green in CI (already wired).
2. ElevenLabs recordings accepted per `audio/v2/README.md`.
3. Programs assembled and spot-checked against the manifest offsets on device.
4. Acceptance scenarios above verified on iPhone (locked and unlocked), iPad, and Mac,
   including the interruption and termination cases, before the mode ships enabled.
