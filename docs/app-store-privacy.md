# App Store privacy disclosure

Use these answers for the build represented by this repository. Re-audit them whenever networking, analytics, crash reporting, accounts, cloud storage, or a third-party SDK is added.

## Privacy Policy URL

Live. Paste this into App Store Connect:

`https://ajrnair.github.io/VipassanaTimerApple/privacy.html`

GitHub Pages serves it from `main` `/docs`, so editing `docs/privacy.html` and pushing republishes
it. Keep [`../PRIVACY.md`](../PRIVACY.md) in step: the two say the same thing, and the in-app About
page links to the Markdown one.

User Privacy Choices URL: leave blank. The policy and in-app log editor already explain the available controls; there is no developer-held account or server-side data to access or erase.

## The two Health strings

`Info.plist` carries both `NSHealthUpdateUsageDescription` and `NSHealthShareUsageDescription`,
which looks like a contradiction of the claim that the app never reads Health. It is not.

Apple's upload validation rejects any app that includes HealthKit without the read description,
whether or not it ever reads — the build was refused for exactly this, with error 90683. The app
requests `read: []` in `HealthKitWriter`, so no read permission is ever asked for and the string is
never shown. It says so plainly rather than inventing a reason.

The privacy answers below are unaffected: nothing is read, and nothing is collected.

## App Privacy questionnaire

1. Select **No, we do not collect data from this app**.
2. Tracking: **No**.
3. Do not select Health & Fitness or any other data type.

Why this is accurate: Apple defines collection for the App Store label as transmitting data off the device in a way that makes it available to the developer or a third party beyond servicing a real-time request. This app has no developer server, analytics, advertising, or third-party SDK. Optional session notes remain part of the private on-device log. Optional Mindful Minutes are written into the user's Apple Health store; they are not transmitted to or accessible by the developer. iPhone–Watch log exchange is device-to-device through Apple's WatchConnectivity framework.

## Privacy manifest

The app declares:

- no tracking;
- no collected data types;
- `NSPrivacyAccessedAPICategorySystemBootTime` / reason `35F9.1`, used only for accurate elapsed-time calculations and timers; and
- `NSPrivacyAccessedAPICategoryUserDefaults` / reason `CA92.1`, used for the app's own on-device
  preferences: the Apple Health setting, chosen appearance, and the last duration and interval
  selected.

The Watch app declares both of the same reasons, since it also stores its own last-chosen duration and interval. Each executable bundle that uses a required-reason API has its own `PrivacyInfo.xcprivacy`; a bundle that uses one without declaring it is rejected at upload as `ITMS-91053`.

## Verification sources

- [Apple: Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Apple: App Privacy Details and the definition of “collect”](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple: Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Apple: Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
