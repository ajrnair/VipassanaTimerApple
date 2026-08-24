# App Store privacy disclosure

Use these answers for the build represented by this repository. Re-audit them whenever networking, analytics, crash reporting, accounts, cloud storage, or a third-party SDK is added.

## Privacy Policy URL

The repository includes a standalone policy page at `docs/privacy.html`. After publishing the
`docs/` folder with GitHub Pages, use:

`https://ajrnair.github.io/VipassanaTimerApple/privacy.html`

Until GitHub Pages is live, use this public fallback:

`https://github.com/ajrnair/VipassanaTimerApple/blob/main/PRIVACY.md`

User Privacy Choices URL: leave blank. The policy and in-app log editor already explain the available controls; there is no developer-held account or server-side data to access or erase.

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
