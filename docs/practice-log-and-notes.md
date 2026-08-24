# Practice Log and Session Notes

Status: session-notes design approved 2026-08-23 and still governing. The notification-voice
section was retired on 2026-08-24, when gong delivery moved to app audio on every platform.

## Product context

This is a quiet instrument for sitting practice — not a journal, teacher, social product, or
quantified-wellness dashboard.

## Session notes

This section is a live behavioral contract. The rules below are implemented and should not be
relaxed without a specification change.

- A meditation record may contain one optional free-form note for practical context, personal
  reflection, or both.
- The feature is named **Note**. Do not call it a journal, reflection, insight, or assessment.
- A note is available only after the user opens an existing session from the meditation log.
- Do not prompt for a note after practice.
- Do not show note text or a note badge in the log list.
- Do not add moods, ratings, tags, generated prompts, reminders, analysis, or AI interpretation.
- Notes remain in the app's private history data and participate in the same phone/watch history
  synchronization as their parent meditation record.
- Notes are never written to HealthKit.
- Preserve backward compatibility with records written before the note field existed.

## Cue delivery contract

Gongs play as ordinary app audio on every platform. The app schedules no notifications and requests
no notification permission.

- The audio session is started only when the user begins a sitting or an awareness practice, and it
  ends when that practice completes or is stopped. It is never held open outside an active,
  user-initiated practice.
- Because the cue is audio rather than a notification, it is **not** subject to the Silent switch,
  a Focus, or notification settings — this is the opposite of the constraint that applied while
  cues were notifications.
- A cue can still be inaudible for ordinary audio reasons: system volume, output routing, or a
  muted or disconnected output.
- A cue must remain authoritative when the screen locks or the app is suspended.
- The timer and the local record remain correct whether or not a gong was heard.
- Do not claim that the app can override Apple system policy.

## Retired: notification voice

The app previously delivered cues as local notifications with fixed titles (`Begin.`,
`Five minutes remain.`, `Be aware.`, `Practice complete.`, `Gong test.`). That design is retired.

`NotificationScheduler` has been removed. All that remains is
`VipassanaTimer/Services/LegacyNotificationCleanup.swift`, which clears any pending or delivered
notification once at launch so an upgrading user does not receive a gong from a session that ended
before they updated. It requests nothing and prompts for nothing, and it can be deleted a release
after 2.0.0 ships.

Removed with it: the scheduling, authorization, readiness, and delegate code, the retired strings,
`AppAlert.offersSettings` (always false, so its "Open Settings" alert branch was unreachable), and
`AppModel.openNotificationSettings()`. Do not reintroduce notification delivery without a
specification change.

Note for later: if the Apple Health denied path should offer a Settings shortcut, that is a new
affordance pointing at privacy settings — not a revival of the notification one.
