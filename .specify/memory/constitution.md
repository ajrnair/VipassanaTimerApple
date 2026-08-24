<!--
Amendment log
- 2.2.0 (2026-08-24): audio provenance moves from a separate record into `ASSET_LICENSES.md`,
  and the obligation drops the checksum. The rule that nothing is bundled without saying where
  it came from is unchanged; the apparatus around it was built for a rights question that no
  longer exists.
- 2.1.0 (2026-08-23): background audio is explicitly permitted while a user-started practice
  is delivering its own gongs or guidance (awareness gongs now play as app audio); the
  prohibition narrows to keeping the app alive outside an active practice.
- 2.0.1 (2026-08-23): rewrote the whole document in the product's plain voice. No obligation
  changed.
- 2.0.0 (2026-08-23): restated the product identity in its own terms; renamed Principles I and
  VI; authorized what version 1 ships (Apple Watch, direct paired-device history exchange,
  opt-in write-only Health export); removed all references to the external reference
  implementation.
- 1.0.0 (2026-08-22): initial ratification.
-->

# Vipassana Timer for Apple Platforms Constitution

Vipassana Timer is a simple, quiet, privacy-forward meditation timer. No accounts, no
tracking, no backend: the app runs on the user's own devices, and the user keeps full control
of their data. The source is open so every privacy promise can be checked in the code.

## Core Principles

### I. A Simple, Focused Practice Instrument

The product is a quiet instrument for sitting practice — not a journal, teacher, social
product, or quantified-wellness dashboard. The approved specifications in `specs/` are the
behavioral contract: sessions, timing, cues, completion, awareness intervals, navigation,
theming, and daily totals behave as specified there. Every deliberate behavior change is
written into a feature specification and covered by an acceptance test before it ships. No
streaks, scores, badges, or prompts that reward use instead of serving practice.

### II. Reliable Absolute-Time Semantics

Timer correctness never depends on the process receiving one callback per second. An active
session survives backgrounding, window closure, suspension, relaunch, and ordinary device
events. A session logs at most once, completes at most once, and never gains or loses credited
time because the interface stopped refreshing. Countdowns may repaint about once per second;
stored truth uses authoritative start, transition, and end points.

### III. Offline and Private by Construction

The complete core experience works without an account or a network connection. Meditation
records stay on the user's own devices. Only two transfers exist: direct exchange between the
user's paired devices (iPhone and Apple Watch) with no server in between, and opt-in,
write-only export to Apple Health. No advertising, analytics, tracking, remote notifications,
profiling, or cloud backend. Any further synchronization or export starts with a constitution
amendment and its own specification.

### IV. Platform-Native, Accessible Behavior

The app follows Apple's lifecycle, permission, audio, notification, and accessibility rules as
designed. Every primary action and timer state works with VoiceOver, Dynamic Type, increased
contrast, reduced motion, and a keyboard where the platform has one. When a denied permission
or a platform limit would weaken an active session, the app says so before it can. The display
may sleep; the session stays correct.

### V. Evidence Before Release

Every requirement gets an automated test where the operating system allows one. Lifecycle,
persistence, date boundaries, duplicate events, and timer state are always tested — no
exceptions. On real hardware, test backgrounding, lock, audio interruption, denied permission,
relaunch, and completion delivery. Don't ship a requirement with no evidence behind it.

### VI. Open Source and Auditable Privacy

The source and documentation stay publishable under the MIT license, so the privacy promises
can be audited in the code. Assets with separate terms are listed in `ASSET_LICENSES.md`, and
every bundled audio asset is recorded in `ASSET_LICENSES.md` with what it is and where it came
from. Secrets, machine-local settings, and generated build outputs are never
committed.

## Product Constraints

- One product identity across iPhone, iPad, Mac, and Apple Watch.
- The core experience is local-only and works in airplane mode.
- Only one standard or awareness session runs at a time.
- Releases exclude accounts, developer-operated services, analytics, social features,
  subscriptions, and web clients.
- Apple's restrictions are represented honestly. Background audio runs only while a
  user-started practice is delivering its own gongs or guidance; the app never keeps itself
  alive outside an active practice.

## Workflow and Quality Gates

Every change starts from a specification and ends with evidence: a pull request says which
requirements it satisfies and shows its tests. Changes to timing, logging, notification, or
audio behavior need regression tests and a check on real hardware. Complexity that bends these
principles is justified in the plan before the code is written.

## Governance

This document outranks informal preference. Amendments carry a written rationale, an impact
note for active specifications, and a version bump: MAJOR changes or removes a principle,
MINOR adds or materially expands one, PATCH clarifies wording without changing obligations.
Reviews check compliance; unjustified violations block release.

**Version**: 2.2.0 | **Ratified**: 2026-08-22 | **Last Amended**: 2026-08-24
