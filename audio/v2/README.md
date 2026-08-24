# Voice guide

This folder holds the scripts, timings, and manifest for the app's guided mode.

The silent timer stays the default experience. The voice guide is an opt-in mode layered on
the same session core; its behavior contract is
[`specs/002-guided-practice/spec.md`](../../specs/002-guided-practice/spec.md).

**What ships:** Guided on the 15, 30, 45, and 60-minute sittings. Light guidance is specified but
not built. The four bundled programs are assembled by
[`../../scripts/assemble_guided_programs.swift`](../../scripts/assemble_guided_programs.swift)
from the recordings in `recordings/`.

## The three modes

New and experienced meditators need different things, so v2 defines three modes rather than one
compromise script. Silence is a mode in its own right, not the absence of one.

**Silent** (the default) — the existing timer exactly as shipped: preparation, gongs, warning,
and log, with no voice assets at all. Nothing in this folder changes it.

**Light guidance** (experienced meditators) — an opening orientation and a closing reflection,
nothing in between:

1. `light-begin` — one orientation line after the start gong, about ten seconds.
2. `shared-metta` — the closing reflection, shared with the guided mode.

There are no mid-sit prompts in light guidance; the existing five-minute warning gong is the
wind-down cue.

**Guided** (new meditators, first sittings) — a full instruction arc:

1. `guided-settle` — posture and arrival, just after the start gong.
2. `guided-breath` — anapana: natural breath at the nostrils, wandering is not a mistake.
3. `guided-sensations` — the transition from breath to body-wide sensation, then release into
   self-directed practice.
4. `guided-equanimity` — a short reset at two-thirds of the sitting, only for sittings of 30
   minutes or more.
5. `shared-metta` — closing and goodwill, after the completion gongs.

Guided and light modes exist only for the 15, 30, 45, and 60-minute presets. Any other
selection — shorter or custom durations, the 120-minute preset, Awareness mode — runs silent,
and the mode picker says so before the sitting starts. Awareness mode is always silent in v2.

## Program timeline

A standard session runs: 8-second preparation → 4-second start bell → sitting → five-minute
warning bell (only sittings longer than 30 minutes; a 30-minute sitting has none) → triple
completion bell (12 seconds). Program layouts are defined in [`cues.json`](cues.json), the
integration contract for the app. Offsets are measured from the start of the meditation phase.

Silent mode schedules no audio at all.

| Segment | Mode | Plays at |
|---|---|---|
| `guided-settle` | guided | 0:12 (as the start gong fades) |
| `guided-breath` | guided | 1:45 |
| `guided-sensations` | guided | one-third of the sitting (5:00 / 10:00 / 15:00 / 20:00) |
| `guided-equanimity` | guided, 30 min and up | two-thirds of the sitting (20:00 / 30:00 / 40:00) |
| `light-begin` | light | 0:12 |
| `shared-metta` | guided and light | 2 seconds after the completion gongs end |

Hard rules: no voice may overlap any gong, and an early-ended sitting stops all remaining audio
including metta. These are enforced at build time, not at runtime — see the next section.

## Playback architecture (read before building UI)

Sparse voice files cannot be delivered from a suspended app: notification sounds are capped,
cannot be sequenced, and nothing wakes an app merely to speak a cue. So guidance ships as
**fully assembled continuous programs**: one audio file per mode and supported duration,
carrying the voice segments **and the gongs** at exact offsets with digital silence between
them. Voice and gongs share one clock and cannot drift apart. A program starts at sitting
start, opens with 8 seconds of lead-in silence covering the preparation — so the audio session
is live before the device can lock — and runs through the post-gong metta. Voice offsets stay
measured from meditation start; a segment sits at (8 + offset) seconds into its file.

- Supported: guided and light modes on the 15, 30, 45, and 60-minute presets. Everything else —
  custom durations, the 120-minute preset, Awareness mode, and watchOS — is silent in v2.
- iOS requires the `audio` background mode and an `AVAudioSession` in the `playback` category,
  non-mixing, active only while a session with a program runs. The session is deactivated at
  program end, at early end, when the user dismisses the completion screen, or when a new
  session starts; audio is never used to keep the app alive idle. Program audio, gongs
  included, plays through this session and is not muted by the ring/silent switch.
- No mode schedules a notification, ever — silent and awareness sittings already deliver
  their own gongs as app audio. When playback pauses (interruption, route loss) it simply
  pauses; on resume the player seeks to the live offset. Force-quitting the app mid-program
  loses that sitting's remaining gongs (documented, accepted — actively playing audio apps are
  rarely terminated); the timer and log recover on relaunch.
- Interruptions (calls, Siri, alarms) pause playback while the timer runs on. On resume the
  player seeks to the current session offset — voice that fell inside the interruption is
  skipped, never replayed late. Pulling headphones pauses playback; resuming is user-initiated
  and also seeks to live. The lock screen offers play/pause only, with seeking disabled.
- Session truth is unchanged: credited time, completion, and the log come from the timer core.
  A paused, killed, or silent program never alters them.

The exact program layouts, lengths, and policies are machine-readable in [`cues.json`](cues.json)
and enforced by [`../../scripts/validate_guide_manifest.py`](../../scripts/validate_guide_manifest.py),
which CI runs for every supported duration. The complete product behavior and acceptance
criteria live in
[`../../specs/002-guided-practice/spec.md`](../../specs/002-guided-practice/spec.md).

## Recording setup (ElevenLabs)

1. Open **Text to Speech** and choose **Eleven Multilingual v2**. It is steadier than the more
   expressive v3 for calm narration.
2. Choose a natural adult voice with an unforced accent. A calm Indian-English voice is welcome.
3. Settings: Stability **65**, Similarity **75**, Style exaggeration **0**, Speaker Boost **On**,
   Speed **0.90**. If a result is theatrical, raise Stability slightly; if flat, lower it. Keep
   Style at zero.
4. Set a **seed** and record it with each generation. Treat it as best-effort consistency, not
   determinism — the API does not guarantee identical output for an identical seed, so judge
   retake consistency by ear against the kept takes.
5. Paste one `.txt` file from [`scripts/`](scripts/) at a time. The files contain no stage
   directions. Do not type pause labels into the text box; exact silences are inserted in
   assembly per [`timing-sheet.md`](timing-sheet.md).
6. Generate two takes per file when convenient and keep the one that sounds like a clear human
   teacher, not a meditation advertisement.

## Performance direction

- Grounded, clear, warm, and matter-of-fact.
- Calm without becoming breathy, sleepy, whispered, devotional, or ASMR-like.
- Do not imitate a guru, announcer, therapist, or luxury-wellness advertisement.
- Natural speaking voice, clean consonants, restrained melody. Let sentences land without
  exaggerated emphasis on words such as "observe," "sensations," or "moment."
- Quality check on the output, not a second instruction to the reader: finished speech should
  land near 85–95 words per minute. The timing sheet's per-file ranges assume that pace.
- Voice only. No music, bowls, ambience, reverb, or processing.

## Deliverables

| Script file | Master to return | Optional second take |
|---|---|---|
| `scripts/guided-settle.txt` | `guide-guided-settle-v2-en.wav` | `…-take2.wav` |
| `scripts/guided-breath.txt` | `guide-guided-breath-v2-en.wav` | `…-take2.wav` |
| `scripts/guided-sensations.txt` | `guide-guided-sensations-v2-en.wav` | `…-take2.wav` |
| `scripts/guided-equanimity.txt` | `guide-guided-equanimity-v2-en.wav` | `…-take2.wav` |
| `scripts/shared-metta.txt` | `guide-shared-metta-v2-en.wav` | `…-take2.wav` |
| `scripts/light-begin.txt` | `guide-light-begin-v2-en.wav` | `…-take2.wav` |

Masters: mono WAV, 48 kHz, **16-bit PCM** — ElevenLabs' documented PCM output is 16-bit
(S16LE), and repackaging it in a 24-bit container adds no quality. Deliver 24-bit only if the
downloaded source is genuinely 24-bit. This also matches the shipped gong assets, which are
mono 48 kHz 16-bit linear PCM. Peaks no higher than −3 dBFS; beyond that ceiling, leave
loudness untouched — do not convert, denoise, or normalize.

## Post-production and app assets

- Trim each recording and normalize to approximately **−19 LUFS integrated (mono)** with
  peaks ≤ −3 dBFS, so the voice sits consistently against the existing gong levels.
- Assemble the **eight program files** defined in [`cues.json`](cues.json) — guided and light at
  15, 30, 45, and 60 minutes — by placing each voice segment at its manifest offset and mixing
  in the gong masters (`gong_start.caf`, `gong_end_triple.caf` from
  `VipassanaTimer/Resources/Sounds`, at their shipped levels, untouched) at the manifest's
  `gongLayout` offsets, with digital silence elsewhere, out to the manifest's exact program
  length. Run `python3 scripts/validate_guide_manifest.py --self-test` before and after any
  layout change.
- App delivery format: mono AAC in `.m4a`, 48 kHz, 96 kb/s. Program files are named per the
  manifest (for example `guide-program-guided-30-v2-en.m4a`); recordings keep their own
  names for provenance and future re-assembly.
- File names carry version and language (`-v2-en`); any re-record or new language bumps or
  extends the suffix rather than overwriting.

## Where the audio comes from

Record every bundled sound in [`../../ASSET_LICENSES.md`](../../ASSET_LICENSES.md): what it is,
and what it was made from. All script text in this folder is original writing for this project;
it paraphrases no recorded course material.
