# Feature Specification: Apple Timer Parity

**Feature Branch**: `[001-apple-timer-parity]`

**Created**: 2026-08-22

**Status**: Implemented; automated Xcode and simulator verification complete; physical-device
matrix and distribution pending

**Input**: User description: "Build the Vipassana Timer for Mac and iOS and replicate all
functionality exactly."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete a Standard Meditation Session (Priority: P1)

A meditator chooses a preset or custom duration, settles during a short preparation
countdown, hears the start gong, follows an analog and digital countdown, receives the
applicable warning gong, and hears three gongs when the session completes.

**Independent Test**: Start a short test session, observe every state transition and gong,
and verify that completion occurs once with the planned duration recorded.

**Acceptance Scenarios**:

1. **Given** the home screen is idle, **When** the user selects 15, 30, 45, 60, or 120
   minutes, **Then** an eight-second preparation countdown begins immediately.
2. **Given** the custom-duration dialog is open, **When** the user enters a whole number from
   1 through 240 and confirms, **Then** the same preparation flow begins for that duration.
3. **Given** preparation reaches zero, **When** meditation begins, **Then** the start gong plays
   once and both analog and digital countdowns represent the full selected duration.
4. **Given** a planned duration longer than 30 minutes, **When** five minutes or less remain for
   the first time, **Then** the warning gong plays once.
5. **Given** a planned duration of 30 minutes or less, **When** five minutes remain, **Then** no
   warning gong plays.
6. **Given** the countdown reaches zero, **When** the session completes, **Then** the full
   duration is credited once, three end gongs play, and a completion screen shows the duration.
7. **Given** the completion screen is visible, **When** the user selects Done, **Then** the app
   returns to the idle home screen.

---

### User Story 2 - Trust the Timer While the App Is Not Visible (Priority: P1)

A meditator can lock the device, background the application, or close its window without
losing the session or corrupting the remaining time.

**Independent Test**: Start a session, make the app non-visible through each supported
lifecycle path, wait past scheduled transitions, and verify correct alerting and reconstructed
state on return.

**Acceptance Scenarios**:

1. **Given** an active session, **When** the device locks or the app moves to the background,
   **Then** the authoritative session continues without requiring per-second UI execution.
2. **Given** an active session whose app is relaunched before completion, **When** its state is
   restored, **Then** the displayed remaining time differs from the authoritative remaining
   time by no more than one second.
3. **Given** a session completes while the app is not visible, **When** completion is reached,
   **Then** the user hears the completion gong as app audio and the session is credited exactly
   once, whether or not the app is foregrounded.
4. **Given** a completed background session, **When** the app next opens, **Then** it shows the
   completion state or an equivalent completed-session acknowledgement without replaying or
   re-logging the session.
5. **Given** the audio session cannot be activated (for example, another app holds exclusive
   audio and does not yield), **When** a user attempts to begin a session, **Then** the app
   explains the failure and does not start a session it cannot signal.
6. **Given** a Mac session is active, **When** the app window closes but the app remains running,
   **Then** the session continues; ordinary idle sleep prevention keeps the session correct
   without forcing the display to remain awake.

---

### User Story 3 - End a Session Early (Priority: P1)

A meditator may end a standard session at any time and have only actual meditation time
credited.

**Independent Test**: End one session during preparation and another after meditation starts,
then inspect active state, alerts, completion presentation, and history.

**Acceptance Scenarios**:

1. **Given** preparation is active, **When** the user ends the session, **Then** preparation
   stops, no gong remains scheduled, no completion screen appears, and no time is credited.
2. **Given** meditation is active, **When** the user ends the session, **Then** all pending
   session alerts are cancelled and elapsed meditation time is credited once.
3. **Given** a session was manually ended, **When** a stale timer, notification, or lifecycle
   event later arrives, **Then** it cannot play a session gong, show completion, or add history.

---

### User Story 4 - Review Daily Meditation Totals (Priority: P2)

A meditator can open the meditation log and see locally stored daily totals, newest first.

**Independent Test**: Add sessions across two local calendar dates and verify aggregation,
ordering, formatting, persistence, and the empty state.

**Acceptance Scenarios**:

1. **Given** no credited sessions exist, **When** the user opens Meditation Log, **Then** the
   message `Your first completed sitting will appear here. Sessions stay on this device.` is
   shown.
2. **Given** multiple credited sessions end on the same local date, **When** the log opens,
   **Then** their credited durations appear as one daily total.
3. **Given** sessions exist on multiple dates, **When** the log opens, **Then** dates are ordered
   newest first and formatted as abbreviated month, day, and four-digit year.
4. **Given** a daily total under one hour, **When** it is displayed, **Then** it appears as whole
   minutes; totals of at least one hour appear as hours and remaining whole minutes.
5. **Given** the app is terminated and reopened, **When** the log opens, **Then** all valid local
   totals remain available without a network connection.

---

### User Story 5 - Run an Awareness Practice (Priority: P2)

A meditator sets a whole-number duration in hours and a whole-number gong interval in minutes,
then receives a gong at each interval until the awareness period completes.

**Independent Test**: Run a shortened awareness period with multiple intervals and verify the
setup summary, each interval gong, completion behavior, cancellation, and history exclusion.

**Acceptance Scenarios**:

1. **Given** Awareness setup opens for the first time, **When** no values have been edited,
   **Then** total hours defaults to 8, the gong interval defaults to 10 minutes, and the
   programmable duration is clearly limited to 1 through 24 whole hours.
2. **Given** duration is 1 through 24 whole hours and the positive whole-minute interval yields
   no more than 63 intermediate gongs, **When** the user starts awareness, **Then** the running
   screen shows remaining time and a summary of total hours and interval.
3. **Given** awareness is active, **When** each interval boundary before the final boundary is
   reached, **Then** the start gong plays once.
4. **Given** awareness reaches its planned end, **When** completion occurs, **Then** three end
   gongs play and the completion screen identifies an awareness completion and its duration.
5. **Given** awareness is active, **When** the user ends it manually, **Then** all pending
   awareness alerts are cancelled, no completion screen appears, and no meditation time is
   added to the daily log.
6. **Given** a requested awareness schedule exceeds reliable background delivery limits,
   **When** the user attempts to start, **Then** the app identifies the unsupported combination
   and shows the minimum reliable interval for that duration rather than silently omitting gongs.

---

### User Story 6 - Use the Same Calm Product on iPhone, iPad, and Mac (Priority: P2)

A user recognizes the same visual hierarchy, wording, navigation, light/dark palette, and timer
behavior across Apple devices, with layouts adapting to screen and window size.

**Independent Test**: Compare the required screens against the approved design captures at phone, tablet,
compact Mac window, and expanded Mac window sizes in both appearance modes.

**Acceptance Scenarios**:

1. **Given** the app is idle, **When** the home screen appears, **Then** it shows `Vipassana
   Timer`, `A place to sit.`, five preset surfaces, and a custom-duration entry in the approved
   hierarchy.
2. **Given** the app is not in a running or completion state, **When** navigation opens, **Then**
   Home, Meditation Log, and Be Aware Always are available and only one is selected.
3. **Given** an active standard session, **When** preparation ends, **Then** a circular gold
   remaining-time arc with a rounded handle shrinks toward zero above a large digital timer.
4. **Given** the system switches between light and dark appearance, **When** any screen is
   shown, **Then** the fixed approved palette is used rather than an unrelated dynamic palette.
5. **Given** text size or accessibility settings increase, **When** content no longer fits its
   original dimensions, **Then** the user can still read and operate every primary control
   without clipping or overlap.
6. **Given** a hardware keyboard is present, **When** the user navigates on iPad or Mac, **Then**
   every interactive element is reachable, visibly focused, and operable.

### Edge Cases

- Custom duration is blank, nonnumeric, zero, negative, or greater than 240 minutes.
- Duration arithmetic approaches numeric or scheduling limits.
- A standard session is ended during the eight-second preparation period.
- A session is ended less than one minute after meditation starts.
- The warning threshold is crossed while the app is suspended.
- The application returns after both warning and completion times have passed.
- Multiple completion, stop, notification, or lifecycle callbacks arrive for one session.
- The user tries to start a standard session while awareness is active, or vice versa.
- The local time zone changes during a session or between session end and log display.
- The wall clock changes substantially while a timer is active.
- A session spans local midnight; credited time belongs to the local date on which it ends.
- Audio is interrupted by a call, another application, route change, or disconnected device.
- Device volume is zero, output is muted at the hardware level, or the audio route is
  unavailable.
- The device restarts, powers off, or remains asleep across a scheduled transition.
- Local log data is empty, truncated, malformed, duplicated, or from a future schema version.
- An awareness interval is greater than or equal to the total awareness duration.
- Awareness requires more pending background events than the platform can guarantee.
- Awareness duration is greater than 24 hours or the interval would require more than 63
  intermediate gongs before completion.
- The Mac window closes, the app is explicitly quit, or the system enters idle sleep.
- The display is too small for the approved two-column card grid.

## Behavior Baseline

These guarantees are part of this specification:

- Custom minutes are actually limited to the displayed 1-240 range.
- Ending during preparation credits zero time.
- Duplicate lifecycle callbacks cannot duplicate logs or completion.
- Recoverable history is preserved and partial-read failures are disclosed instead of silently
  replacing the visible log with an empty result.
- Apple permission and background restrictions are communicated rather than hidden.

## Requirements *(mandatory)*

### Functional Requirements

#### Session selection and preparation

- **FR-001**: The product MUST support iPhone, iPad, Mac, and Apple Watch with the same timer model
  and behavioral rules, while allowing platform-appropriate presentation and device-local storage.
- **FR-002**: The home screen MUST offer 15, 30, 45, 60, and 120-minute preset sessions.
- **FR-003**: The home screen MUST offer a custom-duration entry accepting only whole minutes
  from 1 through 240 inclusive.
- **FR-004**: Invalid custom input MUST remain unconfirmed and MUST produce an understandable
  correction cue without beginning a session.
- **FR-005**: Starting a standard session MUST begin an eight-second preparation state before
  any meditation time is credited.
- **FR-006**: Only one standard or awareness session MAY be active at a time.
- **FR-007**: The preparation state MUST display `Starting in...`, the remaining preparation
  time, and an End Session control.

#### Standard session timing and audio

- **FR-008**: Transition from preparation to meditation MUST play the start gong once.
- **FR-009**: An active standard session MUST display remaining time as `MM:SS`, allowing total
  minutes to exceed 59 for multi-hour sessions.
- **FR-010**: An active standard session MUST display a circular remaining-time indicator that
  begins full and shrinks continuously toward empty.
- **FR-011**: A standard session longer than 30 minutes MUST play one warning gong when it first
  reaches five minutes remaining.
- **FR-012**: A session of exactly 30 minutes or less MUST NOT play the five-minute warning gong.
- **FR-013**: Standard completion MUST play the end gong three times as one continuous
  perceptual sequence.
- **FR-014**: Standard completion MUST show `Session Complete` and the planned duration.
- **FR-015**: Automatic standard completion MUST credit exactly the planned meditation
  duration once.
- **FR-016**: Ending during preparation MUST credit zero time and MUST NOT show completion.
- **FR-017**: Ending after meditation starts MUST credit elapsed meditation time once and MUST
  NOT show completion. A sitting credited under one minute is not logged.
- **FR-018**: Ending or completing a session MUST cancel every no-longer-applicable alert and
  audio action for that session.
- **FR-019**: The Done action on a completion screen MUST clear completion presentation and
  return to the idle home state.

#### Lifecycle and delivery reliability

- **FR-020**: Session truth MUST remain correct without receiving per-second execution while
  the app is backgrounded, suspended, hidden, or without an open window.
- **FR-021**: The product MUST persist enough active-session state to reconstruct preparation,
  meditation, awareness, cancellation, or completion after relaunch.
- **FR-022**: Warning, interval, and completion actions MUST be uniquely identifiable and
  idempotent.
- **FR-023**: The product MUST request only permissions needed for user-selected timer behavior
  and MUST explain the benefit immediately before the first request.
- **FR-024**: If required permission is denied, the product MUST identify which background
  guarantees are unavailable and MUST provide a settings recovery path.
- **FR-025**: When authorized, a background completion MUST use the strongest compliant system
  delivery available on that operating-system version.
- **FR-026**: The product MUST NOT claim guaranteed sound delivery when system volume,
  interruption, permission, hardware state, or platform policy prevents that guarantee.
- **FR-027**: Returning to an active session MUST show authoritative remaining time within one
  second, without visibly replaying missed countdown ticks.
- **FR-028**: Returning after a session end MUST reconcile completion and history once, even if
  an alert was already delivered.
- **FR-029**: A standard or awareness session MUST remain unaffected by a time-zone change;
  substantial wall-clock changes MUST NOT create duplicate, negative, or extended sessions.
- **FR-030**: On Mac, closing the last window MUST NOT cancel an active session; explicit user
  termination or End Session/End Awareness remains authoritative.
- **FR-031**: During an active Mac session, the product MUST prevent ordinary idle system sleep
  to the extent permitted while allowing the display to sleep normally.

#### Meditation history

- **FR-032**: Credited standard-session time MUST be stored locally without network access.
- **FR-033**: Each credited duration MUST be assigned to the user's local calendar date when
  the session ends.
- **FR-034**: Multiple credited sessions on the same date MUST be summed into one daily total.
- **FR-035**: Daily totals MUST be ordered newest first.
- **FR-036**: Dates MUST display as abbreviated month, day, and four-digit year in the user's
  locale where doing so preserves the intended meaning.
- **FR-037**: Totals under one hour MUST display whole minutes; totals at or above one hour MUST
  display hours and remaining whole minutes.
- **FR-038**: Empty history MUST display `Your first completed sitting will appear here. Sessions stay on this device.`
- **FR-039**: Corrupt or unreadable history MUST NOT crash the app; valid recoverable entries
  MUST be preserved and the user MUST be told if data could not be fully read.
- **FR-040**: The product MUST NOT create duplicate credited sessions during recovery or repeated
  completion handling.

#### Awareness practice

- **FR-041**: Awareness setup MUST default to 8 total hours and a 10-minute gong interval.
- **FR-042**: Awareness setup MUST accept 1 through 24 whole hours and positive whole-number
  interval minutes. On iPhone, iPad, and Mac the duration is chosen by turning the ring and the
  interval from the 5, 10, 15, 30, and 60-minute choices; other whole-minute intervals stay
  reachable through App Intents and the `vipassanatimer://aware` URL. Where gongs are delivered
  as notifications rather than audio — the Watch — the schedule MUST contain at most 63
  intermediate gongs so every gong and the completion fit Apple's 64 pending-notification
  ceiling.
- **FR-043**: Awareness MUST reject zero, negative, overflowing, or operationally unsupported
  values with a specific correction message. For an excessive gong count on a
  notification-delivered platform, the correction MUST identify the minimum reliable
  whole-minute interval for the chosen duration.
- **FR-044**: Starting awareness MUST show `Be Aware Always`, remaining time, total hours, gong
  interval, and an End Awareness control.
- **FR-045**: Awareness MUST play one start gong at each whole interval boundary strictly before
  the final boundary.
- **FR-046**: Awareness completion MUST play the end gong three times and show `Awareness
  Complete` with the planned duration.
- **FR-047**: Awareness completion or manual termination MUST NOT add time to the meditation log.
- **FR-048**: Manual awareness termination MUST cancel all pending interval and completion
  actions and return to idle without a completion screen.
- **FR-049**: Where awareness gongs are delivered as notifications — the Watch — the app MUST
  reject, before starting, a schedule requiring more than 64 pending actions in total: no more
  than 63 interval gongs strictly before the end plus one completion action, offering the
  calculated minimum reliable interval as an adjustment. Audio-delivered platforms have no such
  ceiling and MUST NOT impose one.
- **FR-063**: On iPhone, iPad, and Mac, every session — standard sittings and awareness
  practice alike — plays its start, warning, interval, and completion gongs as app audio
  through the active output route — headphones or AirPods when connected, otherwise the
  speaker — locked or unlocked, unaffected by the Silent switch, Focus, or notification
  settings. The app schedules no notifications and requires no notification permission for any
  gong. If audio is interrupted (a call, another exclusive audio app), gongs that fall inside
  the interruption are skipped, never replayed late.

#### Navigation, appearance, and accessibility

- **FR-050**: Idle navigation MUST expose Home, Meditation Log, and Be Aware Always.
- **FR-051**: The product MUST preserve the approved wording for titles, labels, actions, and
  empty states unless an Apple accessibility convention requires a clearer accessible label.
- **FR-052**: Light appearance MUST use laterite clay `#A84A2F`, patina green `#46675D`,
  limestone background `#F3F0E7`, warm surface `#FBF8F0`, and evergreen ink `#24312D` as
  approved design anchors.
- **FR-053**: Dark appearance MUST use warm clay `#E17C5C`, pale patina `#8FB0A5`, background
  `#17201D`, deep-green surface `#232E29`, and warm light text `#EAE8E0` as approved design
  anchors.
- **FR-054**: Prominent titles and countdown accents MUST retain the approved serif/sans-serif
  hierarchy while using fonts available and legible on the target platform.
- **FR-055**: The product MUST follow system light/dark appearance and MUST NOT substitute an
  unrelated dynamic color palette.
- **FR-056**: Every primary control and state MUST expose an accessible name, value, role, focus
  order, and sufficient contrast.
- **FR-057**: All primary flows MUST remain usable with enlarged text, reduced motion, increased
  contrast, VoiceOver, and keyboard navigation where the device supports them.
- **FR-058**: Layouts MUST preserve the approved hierarchy while adapting gracefully to phone,
  tablet, compact Mac window, and expanded Mac window sizes.

#### Privacy and provenance

- **FR-059**: Core behavior MUST work in airplane mode and MUST make no network request.
- **FR-060**: The product MUST NOT include accounts, advertising, analytics, tracking, cloud
  synchronization, or remote notification services.
- **FR-061**: Bundled or reused third-party code, audio, imagery, or constants MUST be limited
  to material the product needs and recorded in `docs/reference.md`.
- **FR-062**: Meditation history and active-session state MUST remain within application-owned
  local storage. The only approved transfers are direct paired iPhone–Watch history exchange and
  optional user-authorized writes of completed sittings to Apple Health.

### Key Entities *(include if feature involves data)*

- **Active Session**: The one currently preparing, meditating, or running awareness. It includes
  a unique identifier, mode, lifecycle state, planned duration, preparation duration, authoritative
  transition points, interval when applicable, scheduled-action identifiers, and cancellation or
  completion state.
- **Meditation Session Record**: One credited standard practice. It includes a unique identifier,
  planned duration, credited duration, meditation start, session end, completion type, and local
  end-date assignment. Preparation and awareness practices do not create these records.
- **Daily Total**: A derived aggregation of credited meditation duration for one local calendar
  date. It contains no independent session timing behavior.
- **Scheduled Action**: A uniquely identified future start, warning, awareness interval, or
  completion signal associated with exactly one active session.
- **Permission Capability**: The current ability to provide visual and audible background alerts,
  including denial and platform limitations that must be presented to the user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All six prioritized user stories pass their acceptance scenarios on at least one
  supported iPhone, one supported iPad configuration, and one supported Mac configuration.
- **SC-002**: Across 100 automated lifecycle simulations per session type, no session is logged,
  completed, warned, or cancelled more than once.
- **SC-003**: After backgrounding or relaunching an active session, displayed remaining time
  reconciles to authoritative time within one second in 100% of deterministic tests.
- **SC-004**: A 15-minute through 120-minute standard session credits exactly its selected
  duration; an early-ended session credits only meditation time elapsed after preparation.
- **SC-005**: The default eight-hour awareness practice schedules or delivers exactly 47 interval
  gongs before its final completion sequence, with no extra interval gong at the eight-hour mark.
- **SC-005A**: Awareness accepts every whole-hour value from 1 through 24 when paired with a
  reliable interval, rejects a 25-hour value, and never registers more than 64 pending actions.
- **SC-006**: Repeated app launches, window closures, and lifecycle callbacks produce zero
  duplicate daily-log entries in physical-device regression testing.
- **SC-007**: All primary screens remain operable at the largest supported accessibility text
  setting without clipped primary actions or unreachable content.
- **SC-008**: A network audit of every core flow records zero outbound requests.
- **SC-009**: A first-time user can start a preset standard session in no more than two actions
  from launch and can end any running practice with one clearly labelled action.
- **SC-010**: Reference visual comparisons preserve all specified content, fixed palette values,
  timer hierarchy, and navigation labels across light and dark appearance; any platform adaptation
  is documented and approved.
- **SC-011**: Malformed local history never crashes the application in the complete corruption
  test suite and never discards an independently recoverable valid record.
- **SC-012**: With relevant permission granted, every standard start, warning, interval, and
  completion event is registered at the intended authoritative time in integration tests; physical
  delivery limitations are reported accurately rather than represented as application success.

## Assumptions

- The bundled session cues are generated from the project's bell recording; sources,
  transformations, and checksums are recorded in `docs/reference.md`.
- The initial support baseline is iOS/iPadOS 17 or later and macOS 14 or later; stronger system
  timer capabilities may be used conditionally on newer releases without dropping the baseline.
- History is local to each installation except for direct paired iPhone–Apple Watch exchange.
  iPad and Mac do not synchronize app-owned history.
- Awareness accepts whole-number hours and interval minutes only.
- Awareness duration is capped at 24 hours. A schedule uses at most 63 intermediate gong alerts
  plus one completion alert; the minimum reliable interval is `ceil(totalMinutes / 64)`.
- If an interval is greater than or equal to total awareness duration, no intermediate gong occurs;
  the completion sequence still occurs at the planned end.
- The operating system ultimately controls physical sound delivery. The product guarantees correct
  scheduling, state, and user disclosure, not sound from muted, disconnected, denied, powered-off,
  or policy-restricted hardware.
- Sessions are not pausable or resumable; users either continue or end them.
- The project will use one shared Apple product codebase with limited platform-specific behavior,
  but the technology and module design belong in the implementation plan rather than this spec.

## Out of Scope

- Accounts, authentication, cloud synchronization, data export, social features, streaks, goals,
  analytics, advertising, subscriptions, or payments.
- Television, spatial-computing, and web applications.
- Live Activities, remote notifications, and developer-operated cross-device cloud sync.
- Pause/resume, multiple concurrent practices, guided meditation content, ambient music, or custom
  gong selection.

## Dependencies

- The committed bell recording in `audio/v2/sounds/` for regenerating the session cues.
- Apple development signing and physical test devices before release validation.
- User authorization for platform alert capabilities where background signaling requires it.
