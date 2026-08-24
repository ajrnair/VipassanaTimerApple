# Security

## Reporting

Please use
[private vulnerability reporting](https://github.com/ajrnair/VipassanaTimerApple/security/advisories/new)
rather than a public issue, and allow time for a fix before disclosing. This is a
single-maintainer project, so expect a reply in days rather than hours.

## In scope

The app has no accounts, server, network calls, or third-party SDKs, which removes most of the
usual surface. What remains:

- Unintended disclosure of practice history or private notes — including through widgets,
  complications, App Intents, Shortcuts, or the `vipassanatimer://` URL scheme.
- Flaws in the iPhone–Apple Watch history exchange over WatchConnectivity.
- Writing more to Apple Health than the documented Mindful Minutes, or reading Health data at all.
- Local data handling that contradicts [`PRIVACY.md`](PRIVACY.md).
- Any outbound network connection, which by design should not exist.

A gap between what the privacy documents claim and what the code does is worth reporting even
without a working exploit. Those claims are the product.

## Out of scope

Findings needing an already-compromised, jailbroken, or physically unlocked device; bugs in
Apple's own frameworks; and the deliberate design decision that gongs play as audio and are
therefore audible to anyone nearby.

Only the latest release is supported. See [`CHANGELOG.md`](CHANGELOG.md).
