# PrepCivic CDX

This is the independently maintained, audited and corrected PrepCivic mobile app source. It is separate from the original repository and codebase.

Repository name: `PrepCivic-CDX`. The application name, Firebase configuration, RevenueCat product identifiers and store bundle ID remain those of PrepCivic so builds can update the existing app.

## Review and validation

Read [AUDIT.md](AUDIT.md) for the implemented fixes, remaining findings and TestFlight acceptance checks. [SOURCE_CHANGES.md](SOURCE_CHANGES.md) lists changes against the supplied original ZIP.

Local validation: 36 Flutter regression tests and 26 SQLite checks passed; static analysis had no errors or warnings; Android debug build succeeded. Native iOS builds and real Apple purchases still require Codemagic/macOS and TestFlight validation.

## Development

```sh
flutter pub get
flutter test
flutter analyze
```

## iOS build

Use the existing Codemagic signing/publishing configuration, bundle ID `com.torcdigital.prepcivique`, and a fresh build number above the latest App Store Connect build. The iOS deployment target is 15.0. Keep private keys, signing files and account credentials in Codemagic secrets, outside Git.

The app source still has version `1.0.0+10`; set a new build number in CI before upload.


## Android billing test

Use `PrepCivic_Play`, the Google Play API 35 emulator created on this workstation. Sign into its Play Store with an account listed in Play Console's license testing settings for this app. The debug app keeps the existing package ID and can be sideloaded for license testing; the old `melovibe` image cannot test billing. Mock questions now load from the bundled bank without Firestore collection permissions. Store purchases still require an online store account and a real testing transaction.
