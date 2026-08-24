# Contributing

Thanks for looking. This is a small, deliberately narrow project, so it helps to know what will
and won't be accepted before you spend time.

## What this is

A quiet timer for sitting practice — not a journal, teacher, social product, or wellness
dashboard. [`.specify/memory/constitution.md`](.specify/memory/constitution.md) governs the
project and [`specs/`](specs/) is the behavioral contract. Reading the constitution first saves
the most time.

Some things are settled and will be declined however well built: accounts, analytics, tracking,
advertising, a backend, streaks, scores, badges, and engagement prompts.

## Before writing code

Open an issue first for anything beyond an obvious fix. Behavior changes need a specification
before an implementation — that comes from the constitution, so a pull request without one will
be asked for it anyway.

Bug reports, documentation fixes, accessibility findings, and platform-compatibility reports are
welcome without ceremony.

## What a change has to meet

- **Tested.** Every requirement gets a test where the platform allows one.
- **Absolute time.** Timer correctness must never depend on a once-a-second callback. A session
  logs at most once and never gains or loses credited time because the UI stopped refreshing.
- **Private by construction.** No new network call, SDK, or off-device transfer. The two existing
  transfers — paired-device exchange and opt-in write-only Apple Health — are the complete set.
- **Semantic colors.** Use the tokens via `VTPalette` or `WatchPalette`; a test rejects inline RGB
  in product UI. See [`docs/design-system.md`](docs/design-system.md).
- **Accessible.** Primary actions and timer states work with VoiceOver, Dynamic Type, increased
  contrast, reduced motion, and a keyboard where the platform has one.

## Checks

```bash
swift test && python3 scripts/validate_guide_manifest.py --self-test
```

CI additionally runs the Xcode tests and unsigned iOS and watchOS builds. All of it must pass.

## Audio

Don't add audio without saying where it came from. Every bundled sound is recorded in
[`ASSET_LICENSES.md`](ASSET_LICENSES.md), which also states that the recordings are not covered by
the MIT License. A voice
imitating a living or identifiable teacher, or any third-party recording without a verified
distribution license, will not be accepted.

## Licensing

Contributions are accepted under the [MIT License](LICENSE). Opening a pull request confirms you
have the right to contribute the work under those terms.
