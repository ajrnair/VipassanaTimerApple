# Audio and asset terms

The MIT License in [`LICENSE`](LICENSE) applies to this project's source code and documentation
unless a file or section is expressly identified here as having separate terms.

## Bell recordings

The bundled session cues are generated from the project's bell recording:

- `audio/v2/sounds/Bell Buoy.wav` (source recording)
- `VipassanaTimer/Resources/Sounds/gong_start.caf`
- `VipassanaTimer/Resources/Sounds/gong_end_triple.caf`

They are **not** licensed for extraction, reuse, modification, or redistribution under the MIT
License. Their inclusion in this repository does not grant any separate rights in the underlying
recording.

## Generated voice recordings

The guided-voice recordings in `audio/v2/recordings/` were generated with ElevenLabs v3 on
2026-08-23 under a paid plan. The four continuous Guided programs bundled in
`VipassanaTimer/Resources/GuidedPrograms/` are assembled from them; the MP3 sources are not
bundled directly.

Neither the sources nor the assembled programs are licensed for extraction, reuse, modification,
or redistribution under this project's MIT License. They are included so the app can play them,
and for no other purpose.

## Where the bundled audio came from

Every sound in the app, and what it was made from. Nothing here is licensed for reuse; this
section says where it originated, and the licence above says what you may do with it.

**The bell.** `gong_start.caf` and `gong_end_triple.caf` are made from `audio/v2/sounds/Bell
Buoy.wav`, the project's own recording — downmixed to mono and, for the completion cue, repeated
three times. Regenerate them with:

```bash
swift scripts/make_gong_assets.swift "audio/v2/sounds/Bell Buoy.wav" VipassanaTimer/Resources/Sounds
```

**The guided voice.** The six readings in `audio/v2/recordings/` were generated with ElevenLabs v3
on 2026-08-23 under a paid plan. They are AI-generated, not a human recording, and the files carry
ElevenLabs content credentials saying so. The voice ID, settings, and seed were not kept.

**The guided programs.** The four `.m4a` files in `VipassanaTimer/Resources/GuidedPrograms/` are
assembled from those readings, the bell, and the silences in `audio/v2/cues.json`, by
`scripts/assemble_guided_programs.swift`. Running that script rewrites them, so run it when you
mean to rebuild the audio and not to check that it works.

## Names and marks

The MIT License does not grant trademark rights in the application's name, icon, or other product
identity. Vipassana Timer is an independent practice tool; no affiliation with a meditation school,
teacher, lineage, or teaching organization is implied.
