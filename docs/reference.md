# Audio Provenance

This record lists every bundled audio asset, its source, its transformation, and its checksum,
so a release build's audio is fully reproducible from this repository.

## Session cues

The start, warning, awareness, and completion cues are generated from the project's bell
recording:

- Source: `audio/v2/sounds/Bell Buoy.wav` — stereo 44.1 kHz 24-bit linear PCM WAV, 4.0 seconds.
  SHA-256 `6e76acb002f74869391baff9068bd1ccc06e2fba04466b8b9d6b231c3e7e9087`.

| Source | Destination | Purpose | Transformation | Status |
|--------|-------------|---------|----------------|--------|
| `audio/v2/sounds/Bell Buoy.wav` | `VipassanaTimer/Resources/Sounds/gong_start.caf` | Start, warning, and awareness cue | Downmixed to mono 44.1 kHz 16-bit linear PCM CAF, 4.0 seconds | Included; SHA-256 `ca144ea053aac0eb487fa60a95ae6cf78c8e4108139a87e5e03f1a2fcc8b9c6c` |
| `audio/v2/sounds/Bell Buoy.wav` | `VipassanaTimer/Resources/Sounds/gong_end_triple.caf` | Completion cue | Same mono transformation concatenated three times into a 12-second CAF | Included; SHA-256 `070edef5033d6516516f066055bedf8bbc386a44f08da6ac4983711568f5402e` |

Both generated files can be reproduced with:

```bash
swift scripts/make_gong_assets.swift "audio/v2/sounds/Bell Buoy.wav" VipassanaTimer/Resources/Sounds
```

## Generated voice source takes

The following provisional segment masters were generated in ElevenLabs on 2026-08-23 under a paid
plan, as confirmed by the project owner. File metadata identifies the model as `elevenlabs-v3`.
The files are mono 44.1 kHz, 128 kb/s MP3 downloads. They supply the current Guided device trial;
they are not bundled directly. A later release-quality pass can replace them with the mono 48 kHz
16-bit PCM WAV sources specified for final production.

The ElevenLabs voice ID, generation settings, and seed were not captured with these downloads and
remain required provenance before public release. Do not transcode an MP3 here to WAV merely to
change its label; a future replacement should come from a documented PCM source.

| Recording | Script SHA-256 | Recording SHA-256 |
|-----------|----------------|-------------------|
| `audio/v2/recordings/guided-settle.mp3` | `1cddeeaa564216f75462c1f03357de5ce0db7082e4c83a5034bed81bde5f2cc2` | `e079ea2d0d057f72034b3dbe5b57c3d96966cf60ff87ee9aba153bd6bdb3931c` |
| `audio/v2/recordings/guided-breath.mp3` | `d6b323a8336ef63921eca8a8bd56c1bcd46b409e1116043d9f145094a924ab8a` | `57e4ae7ce0a6f074c3e2e2fa8dde9d603bc1b9aa05a96cea2a7db04ab3310905` |
| `audio/v2/recordings/guided-sensations.mp3` | `5efdebfc0a0c90c04a2289a1dd3a1a7b3bb78d320bded5fcd46733ba60eabcdf` | `9e4fe613f5325a34f354f705f83fb4d99f6a43d5f68cc8fe062a72b1bed2913e` |
| `audio/v2/recordings/guided-equanimity.mp3` | `db8b1e04498946db30af4cc85dc9d1368a8f3a40b1f9a6a1a77123d099a46ef5` | `3bf80103e99b3cef19859839f534418226025d1c473a68237e405ba761ee07d5` |
| `audio/v2/recordings/shared-metta.mp3` | `3a20bb3af25924901739a9aa90a27ef0fb52457ad8d778d6ee1daf3cd3050d7b` | `dcaaf7c765697815eb0d5a7a1a3c5a16a9a4f78168c5d6b0b64c9b3161c3b4fd` |
| `audio/v2/recordings/light-begin.mp3` | `fc3c77eaffad06eab23e9c84d4b47bc6e8ae1139b3ca24ba5a297eb6aa585c34` | `8622d91d755c5914b196b2c84662aae38272ed420db52c801d24d784202c335b` |

### Bundled Guided trial programs

`scripts/assemble_guided_programs.swift` combines the provisional segment masters, gong
masters, and exact manifest silence into the following mono 48 kHz AAC programs. Each file starts
at sitting start, includes the eight-second preparation lead-in, and carries its own gongs.

The embedded gongs are the project bell (4-second start, 12-second triple completion),
matching the manifest's retimed constants.

| Program | Exact duration | SHA-256 |
|---------|----------------|---------|
| `VipassanaTimer/Resources/GuidedPrograms/guide-program-guided-15-v2-en.m4a` | 975 s | `cf262eb2592ec1ba624624afd6a714a03072ee71a0603ce7956268ec323f8062` |
| `VipassanaTimer/Resources/GuidedPrograms/guide-program-guided-30-v2-en.m4a` | 1,875 s | `6e8d38b6726900500e9a127f178daaf8e3d3bc28d898ff62f43a6bde4743c74a` |
| `VipassanaTimer/Resources/GuidedPrograms/guide-program-guided-45-v2-en.m4a` | 2,775 s | `577da242fbadd870cd7bb75af3673645f3b431e326ac74123c3f4ad7a49003cd` |
| `VipassanaTimer/Resources/GuidedPrograms/guide-program-guided-60-v2-en.m4a` | 3,675 s | `48b5b595062975dd3c155195b43f69e8e9e31f9c526fb6607a0e2f9cb65d5c5e` |
