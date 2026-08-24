# Guided voice recordings

These six files are the readings of the guided scripts. The app does not bundle them directly; it
bundles the continuous programs that `scripts/assemble_guided_programs.swift` builds from them.

## Where they came from

- Generated with ElevenLabs v3 on 2026-08-23.
- Generated under a paid ElevenLabs plan, as confirmed by the project owner.
- Download format: mono MP3, 44.1 kHz, 128 kb/s.
- The voice ID, settings, and seed were not captured.

These are lossy MP3s. If they are ever replaced, the replacement should be recorded as PCM rather
than an MP3 converted to WAV, which changes the label and not the quality. No single file here is
a session on its own.

## Timing review

Durations below are the unedited MP3 durations. The expected ranges are the raw-speech targets in
[`../timing-sheet.md`](../timing-sheet.md), before its specified internal pauses are inserted.

| File | Duration | Expected | Initial timing result | SHA-256 |
|------|----------|----------|-----------------------|---------|
| `guided-settle.mp3` | 34.429 s | 33–36 s | Within range | `e079ea2d0d057f72034b3dbe5b57c3d96966cf60ff87ee9aba153bd6bdb3931c` |
| `guided-breath.mp3` | 55.719 s | 35–40 s | Too long; regenerate or deliberately revise the timing specification | `57e4ae7ce0a6f074c3e2e2fa8dde9d603bc1b9aa05a96cea2a7db04ab3310905` |
| `guided-sensations.mp3` | 55.406 s | 53–59 s | Within range | `9e4fe613f5325a34f354f705f83fb4d99f6a43d5f68cc8fe062a72b1bed2913e` |
| `guided-equanimity.mp3` | 50.991 s | 27–30 s | Too long; regenerate or deliberately revise the timing specification | `3bf80103e99b3cef19859839f534418226025d1c473a68237e405ba761ee07d5` |
| `shared-metta.mp3` | 34.769 s | 33–37 s | Within range | `dcaaf7c765697815eb0d5a7a1a3c5a16a9a4f78168c5d6b0b64c9b3161c3b4fd` |
| `light-begin.mp3` | 13.166 s | 11–13 s | Marginally over; judge by ear before deciding whether to trim or regenerate | `8622d91d755c5914b196b2c84662aae38272ed420db52c801d24d784202c335b` |

Timing is the easy half. A take also has to be listened to: for clarity, pacing, pronunciation,
stray breaths, silence at the edges, and whether it sounds like the rest of the app.
