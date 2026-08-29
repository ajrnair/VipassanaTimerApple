# Awareness battery measurement

Status: procedure written 27 August 2026, not yet run. This is blocker #2 in
`VipassanaTimer/Core/PracticeFeatures.swift`; Awareness does not ship until the numbers below are
filled in and judged acceptable.

## What is being measured, and why

Awareness holds one audio session open for the whole practice — up to 24 hours — with every gong
pre-scheduled onto a single player node (`PracticeGongPlayer`). Between gongs the node renders
silence. The open question is what that costs: an active audio session prevents some of the
system's deepest idle states, and nobody has measured the drain over a realistic multi-hour run
on hardware. Simulators measure nothing.

## Decide the acceptance threshold first

Write the threshold down **before** the first run, so the result is judged rather than
rationalized. Proposed: over an 8-hour locked-screen session, Awareness may cost at most
**5 percentage points more** than the same phone doing nothing for the same 8 hours (its
baseline overnight drain). If the delta is larger, the design needs work before the flag flips —
options include deactivating the audio session between distant gongs and re-arming on a timer,
which trades scheduling simplicity for idle depth.

Agreed threshold: ☐ (fill in before measuring)

## Device matrix

| Run | Device | iOS | Session | Mode |
| --- | --- | --- | --- | --- |
| 1 | Oldest supported iPhone available (iOS 17 floor) | | 8 h / 10 min fixed | baseline-vs-practice |
| 2 | Same device | | 8 h random | comparison with run 1 |
| 3 | Current primary iPhone | | 8 h / 10 min fixed | sanity on modern hardware |

## Procedure, per run

1. Charge to 100%, then unplug and wait 10 minutes (surface charge settles).
2. **Baseline night:** leave the phone locked and idle for 8 hours in the same conditions
   (same location, Wi-Fi on, cellular as usual, no alarms). Record start/end battery percentage
   from Settings → Battery.
3. **Practice night:** same starting state, start the Awareness session, lock the phone
   immediately, and leave it for the full 8 hours. Record start/end percentage.
4. Record both in the results table. The number that matters is
   `(practice drain) − (baseline drain)`.
5. **Instruments sample:** separately, run 1 hour of the session with the device attached to
   Xcode → Instruments → Energy Log, and note the energy impact band the audio session holds
   between gongs. This shows *where* the cost is, not just how big.
6. **Interruption cost:** during one run, place a phone call to the device mid-session and let
   the practice recover (`rebuild()` reschedules the remaining gongs). Confirm the recovery on
   the gong that follows, and note any visible battery step in Settings → Battery's hourly chart.
7. Confirm every expected gong was audible for at least one bounded stretch (e.g. count gongs
   across one awake hour against the schedule).

Keep conditions honest: no charger, no Low Power Mode, screen off throughout, and the same
physical location both nights — cellular signal strength moves overnight drain more than most
software does.

## Results

| Run | Baseline 8 h drain | Practice 8 h drain | Delta | Verdict |
| --- | --- | --- | --- | --- |
| 1 · 29 Aug 2026, iPhone 16 Pro, Debug build, awareness fixed | pending (baseline night not yet run) | 20 points over 6.5 h — 3.1%/h, ≈25 points per 8 h. Thermals nominal, never on power. | pending | pending |
| 2 | | | | |
| 3 | | | | |

Instruments notes:

Interruption notes:

## Watch

Not measured here. The Watch is out of the current release, and its Awareness path uses a
different keepalive (a looping silent buffer plus a tick-driven cue player), so its cost must be
measured separately when the Watch returns — an 8-hour wrist session against a baseline night on
the charger stand it would otherwise have spent.
