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
recording. See [`docs/reference.md`](docs/reference.md) for transformations and checksums.

## Generated voice recordings

Provisional guided-voice segment masters are stored in `audio/v2/recordings/`. They were generated
with ElevenLabs v3 on 2026-08-23 under a paid plan, as confirmed by the project owner. The MP3
source files are not bundled directly. Four continuous Guided programs derived from them are
bundled in `VipassanaTimer/Resources/GuidedPrograms/` for the current device trial. The source and
derived audio are not licensed for extraction, reuse, modification, or redistribution under this
project's MIT License.

Before a public release, the voice identity, generation settings, seed (when available), and
production and distribution rights must be added to the current recording and checksum record.
See `audio/v2/recordings/README.md` and `docs/reference.md` for the current provenance boundary.

## Names and marks

The MIT License does not grant trademark rights in the application's name, icon, or other product
identity. Vipassana Timer is an independent practice tool; no affiliation with a meditation school,
teacher, lineage, or teaching organization is implied.
