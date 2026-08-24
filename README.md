# Vipassana Timer

**Private by design.** A quiet timer for sitting practice, for iPhone.

Free and open source, with no account, scores, streaks, advertising, analytics, or tracking. The
timer works offline and your practice stays on your own devices. The source is public under the
[MIT License](LICENSE) so the privacy claims here can be checked in the code; the bundled audio
has [separate terms](ASSET_LICENSES.md).

Vipassana Timer is an independent practice tool. No affiliation with a meditation school,
teacher, lineage, or teaching organization is implied, and it is not a substitute for
instruction.

## What it does

**Sittings.** Five lengths — 15, 30, 45, 60, and 120 minutes. Eight
quiet seconds to settle, one gong to begin, a warning gong five minutes from the end of sittings
longer than 30 minutes, and three gongs to close. Ending early credits only the time you actually
sat, never the preparation seconds. Sittings under a minute are not recorded.

**Gongs are app audio, everywhere.** On every platform, gongs play as ordinary app audio through
whatever you are listening on — headphones when connected, otherwise the speaker. They arrive
locked or unlocked and are not silenced by the Silent switch or by a Focus. The app schedules no
notifications and asks for no notification permission.

**A log you own.** An offline, editable practice log. Private notes live on each session and
appear when you open it.

**Apple Health, if you want it.** Optional, off by default, and write-only: completed sittings can
be recorded as Mindful Minutes. The app never asks to read Health data.

**No server anywhere.** There is no developer-operated server and no account anywhere in the
product. Practice data never leaves the device except through the optional Apple Health export.

**Quick starts.** A Home Screen widget, App Shortcuts, and
`vipassanatimer://` links. Shortcuts and links accept any length from 1 to 240 minutes.

Sessions survive backgrounding, relaunch, and reboot. Timing rests on absolute time rather than on
a once-a-second callback, so a session logs at most once and never gains or loses credited time
because the interface stopped refreshing.

## Design

Since 2.0.0 the app uses one design at two times of day: **Dawn** in light appearance and **Night**
in dark, sharing the same structure and hairlines with only the field inverted. Colors are semantic
tokens in a shared catalog. See [`docs/design-system.md`](docs/design-system.md). The Watch keeps
its own deliberately dark treatment.

## Privacy

The app collects nothing. Timer state, log entries, notes, and preferences stay in app-owned
storage on your devices and are never sent to the developer. No analytics, tracking, advertising,
remote notifications, or cloud backend.

[`PRIVACY.md`](PRIVACY.md) is the full policy.

## Platforms

The first release ships for **iPhone (iOS 17)** and covers sittings only. Awareness — the 1-to-24-hour interval bell — is built and tested but held for a later
release behind
`PracticeFeatures.awarenessEnabled`. The Apple Watch app is likewise built and tested but not in
the first release — the iOS target no longer embeds it. See [`docs/roadmap.md`](docs/roadmap.md).

The project also builds and is tested for macOS 14, and CI runs the Mac test suite, but Mac and
iPad are deliberately out of scope for the first release and are not submitted.

System volume, audio routing, or a muted output can still keep a gong from being heard. The timer
and the local record remain correct regardless.

## Build

Requires the full Xcode application (15 or newer).

Open [`VipassanaTimer.xcodeproj`](VipassanaTimer.xcodeproj), select the `VipassanaTimer` scheme,
choose an iPhone Simulator (or `My Mac`, which still builds), and Run. The Watch app still builds
and is still covered by CI under the `VipassanaTimerWatchApp Watch App` scheme; it is simply not
embedded in the shipping iOS app.

For a physical device, select your own team in **Signing & Capabilities** and use your own bundle
identifiers — the ones in this repository belong to the project's team.

## Tests

The timer core depends only on Foundation, so it verifies without Xcode:

```bash
swift test
```

36 tests cover awareness bounds, preparation and warning boundaries, early credit, clock changes
and reboot recovery, idempotent history, corruption recovery, persistence, and design tokens. CI
adds the Xcode tests, unsigned iOS and watchOS builds, and the guided-manifest validator on every
pull request.

## Audio

The session cues come from the project's own bell recording — a 4-second bell to start, three
bells to close. Regenerate them with:

```bash
swift scripts/make_gong_assets.swift "audio/v2/sounds/Bell Buoy.wav" VipassanaTimer/Resources/Sounds
```

[`ASSET_LICENSES.md`](ASSET_LICENSES.md) records where every bundled sound came from, and states
that the recordings are **not** covered by the MIT License.

## Optional voice guide

The app is silent between gongs. Guided is opt-in: Silent is the default and leaves the timer
exactly as described above, while Guided adds spoken instruction on the 15, 30, 45, and
60-minute sittings. A third mode, Light guidance, is specified but not built.

Specification: [`specs/002-guided-practice/spec.md`](specs/002-guided-practice/spec.md).

## Project records

- [`.specify/memory/constitution.md`](.specify/memory/constitution.md) — how the project is governed
- [`specs/`](specs/) — product and feature specifications
- [`CHANGELOG.md`](CHANGELOG.md) — what changed in every build
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — what a change has to meet
- [`SECURITY.md`](SECURITY.md) — reporting a vulnerability
- [`PRIVACY.md`](PRIVACY.md) · [`docs/app-store-privacy.md`](docs/app-store-privacy.md) — privacy policy and App Store answers
- [`docs/design-system.md`](docs/design-system.md) — color tokens and theming
- [`docs/roadmap.md`](docs/roadmap.md) · [`docs/release-test-plan.md`](docs/release-test-plan.md) · [`docs/app-store-release.md`](docs/app-store-release.md) — what remains before release

## License

MIT for source and documentation ([`LICENSE`](LICENSE)). The bundled bell and voice recordings
carry [separate terms](ASSET_LICENSES.md) and are not part of the MIT grant, which also does not
grant rights in the app's name or icon.
