# PrepCivic audit and fixes

Prepared 7 October 2026. The original ZIP is unchanged. This folder contains the corrected source. No production Firebase, RevenueCat, or store settings/data have been changed.

## Launch status

The reported practice-review defect and several related code defects have been corrected and tested locally. Purchase loading, restoration, entitlement handling, and error recovery have been corrected in code. **Successful iOS store purchases are not yet verified**, and this is not an App Store launch approval. Windows cannot build or run the iOS target; a signed build on macOS and a real-device TestFlight test remain necessary.

## Confirmed defects corrected

| Area | Cause in supplied code | Result after changes |
|---|---|---|
| Answer review | Button only dismissed the completion sheet | Review opens at question 1 with saved selections and correct answers; answers cannot be changed or scored again |
| Paid continuation | Button dismissed sheet without fetching another set | Loads another session and resets its question index, score, and selections |
| Completion navigation | Used bottom-sheet context after dismissing the sheet | Uses separate sheet and screen contexts for navigation |
| Account safety | Shared local history; destructive deletion before reauthentication | Separate account/guest databases, archived legacy data, password reauthentication and known-data cleanup |
| Settings and layout | Language selection restarted onboarding; payment footer could overflow | Correct settings picker and fully scrollable paywall |
| Package loading | Exceptions and empty offerings were hidden; unavailable packages looked purchasable with hardcoded prices | Clear localized failure/unavailable states, retry, disabled unavailable plans and payment button, genuine store-formatted prices |
| Purchase completion | Missing expected entitlement silently did nothing | Explicit pending-access guidance; purchase cancellation is handled without an error alert |
| Restoration | Returned success without updating the access tier used by quizzes | Uses highest active entitlement and attempts a Firestore mirror; practice/mock access also reads RevenueCat |
| Guest paid access | Practice/mock access depended on having a Firebase user document | RevenueCat entitlements also grant access to anonymous purchasers |
| Account identity | RevenueCat was never connected to Firebase identity | Serialized identity synchronization before access lookup, offering retrieval, purchase, and restore; account change guards on purchase results |
| Mock gate | Home and quiz used different gates and could both decrement a bonus | Quiz owns the gate; bonus is consumed only at submission; guest free attempt tracked locally |
| Mock results | Replaced the quiz route, then restarted its disposed state | Keeps quiz alive beneath results; restart resets it, dashboard callback handles a tab versus a pushed quiz |
| Question repetition | Random selection ignored exposure count; duplicated CSV stems had distinct IDs | Selects least-seen unmastered canonical stems, excludes previous session IDs until a pass is exhausted; mastery stats count canonical stems |
| Cloud duplication | Production dashboard could upload the full question bank with random IDs repeatedly | Removed uploader and filters duplicate/invalid cloud question records when reading; no existing cloud records were deleted |
| Bilingual text | Only supported square-bracket wrappers; Bengali/Arabic/Urdu used parentheses | Supports both wrappers, nested parentheses, numeric translations and French-only suppression |
| Translation alignment | Matched translated files by row number | Matches French question/answer prefixes; missing translations fall back to French rather than attaching another question's translation |
| Pashto History | Invalid CSV quoting swallowed later records with the standard CSV parser | Normalized quoting without changing CSV field values; all 223 question blocks parse |
| Missing UI labels | Completion keys absent from every locale; other UI keys missing | Added missing labels and billing messages across all six locales and enabled fallback translations |
| Bengali picker | Bengali commented out despite bundled Bengali content | Restored in supported locales and both language pickers |
| Fonts | Quiz/results fetched their fonts at runtime when not cached | Bundled the existing font variants and licenses for offline rendering |
| SQLite initialization | Concurrent screen loads could open/seed the database concurrently | Shares one in-flight database initialization; v2 content refresh preserves question IDs, results and progress |
| Firebase Android | Dart project `prepcivic` conflicted with native Android `google-services.json`; native Android and iOS both use `prep-civic` | Android Dart options now match the supplied native app's exact Firebase configuration |
| iOS native setup | Deployment target 13 conflicted with installed Firebase pod minimum 15; CocoaPods scaffold missing | Targets iOS 15, restores Flutter's standard Podfile and xcconfig includes; still needs macOS validation |
| Android tooling | Kotlin 2.2.0 below installed Flutter's supported minimum | Updates to Kotlin 2.2.20; debug APK compiles |

Local databases are now isolated by Firebase account UID, with a separate guest database. The old shared `prep_civic_v10.db` remains untouched as an archive. Its rows have no account owner, so they are **not automatically imported** into any account. Users may initially see fresh local progress; existing account-owned cloud records are imported during HomeTab sync. Stable question hashes are retained. Test upgrade/account switching on a real device before release. Cloud sync merges results rather than erasing unsynced local scores and does not decrease local progress counters.

Free practice retains the original fixed-ten-question demo policy. Paid practice avoids previously seen questions until a pass is exhausted; later repetition of unmastered questions is intentional.

## Required purchase configuration evidence

The source expects the **current RevenueCat offering** to contain these exact package identifiers. These are RevenueCat package IDs, distinct from Apple/Google product IDs.

| RevenueCat package ID | Active entitlement required | App access tier |
|---|---|---|
| `pkg_2_4_year` | `access_basic` | `2_years` |
| `pkg_10_year` | `access_pro` | `10_years` |
| `pkg_nationality` | `access_max` | `nationality` |

The iOS bundle ID is `com.torcdigital.prepcivique`. The source contains an Apple public SDK key, but the ZIP cannot prove it belongs to the intended RevenueCat iOS app or that Apple returns its products.

The supplied screenshots already confirm the bundle ID, matching product IDs (`prep_2_4_year`, `prep_10_year`, `prep_nationality`), the three offering packages with iOS/Android products, and entitlement identifiers. Apple lists all three as **Non-Consumable**, **Prepare for Submission**. The Paid Apps agreement, bank and tax records show Active. These products are lifetime one-time purchases. RevenueCat's earlier Missing Metadata display and Apple's draft status alone do not establish why a TestFlight device returns no products; sandbox testing does not require App Review approval. See [Apple sandbox troubleshooting](https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox).

A live TestFlight test and device log from the updated code are still needed to establish any remaining remote configuration cause. The masked Apple SDK key cannot be compared with the source. The screenshot of offering details does not prove which offering is current, and the validated App Store Connect import key does not independently verify the in-app purchase key. No more dashboards are needed to continue code work.

Do not guess package assignments from prices or array order. If the dashboard IDs differ, correct the exact mapping using that evidence. Empty offerings can come from RevenueCat/store configuration, so this code patch alone cannot establish the remote root cause. See [RevenueCat's official troubleshooting guide](https://www.revenuecat.com/docs/offerings/troubleshooting-offerings) and [customer identity documentation](https://www.revenuecat.com/docs/customers/user-ids).

## Remaining audit findings requiring follow-up

- **Translation-content gaps:** Pashto Values contains 112 questions versus 125 French questions and largely uses a different bank: 114 French stems and 345 option cells have no exact Pashto match. The app now omits those translations safely. Some other language cells also have mismatched prefixes. `TRANSLATION_MATCH_AUDIT.json` lists them. Correct translated content or a reviewed stable-ID mapping is needed; translations have not been invented.
- **Account deletion:** now reauthenticates with the password before deleting anything, deletes the three known user subcollections in batches, removes that account’s local database, then removes profile/Auth identity. Wrong passwords cannot delete data. Network failures may leave partial cleanup and should be retried. A trusted backend is still needed for guaranteed complete deletion, unknown collections, queued writes, legacy unattributed data, and any RevenueCat customer records; none was supplied. Deleting the app account does not refund a lifetime purchase.
- **Local history upgrade:** account isolation is fixed; attribution of old shared history remains unknown. The archived database is preserved rather than guessing an owner.
- **Backend access control:** client code writes `subscription_tier`, bonus counters, and progress. Firestore rules and any RevenueCat webhooks/functions were not included, so server enforcement cannot be audited. Paid access should be verified server-side for protected server resources; the client now grants access only from RevenueCat (with a per-account in-memory cache of previously returned entitlements during an outage); Firestore mirrors cannot grant paid access.
- **Curriculum distinctions:** all three active paid tiers currently use the same practice selection and mock pool. The onboarding profile is separate from paid access. Confirm the intended differences before adding tier-specific content filters.
- **Curriculum wording:** Apple confirms the lifetime non-consumable model. The third plan is Nationalité (naturalization), while the spoken request mentioned permanent residency. Its content distinction needs owner confirmation.
- **Secondary UX:** some legacy screens contain French-only strings; the settings FAQ has no content/route. These should be reviewed before claiming complete language and UX coverage.
- **Release operations:** store dashboards, production rules, signing, receipt validation/restore-transfer settings, refund/revocation behavior, purchase accessibility on every device, and iOS database migration still need live validation. No release was uploaded.

## Validation

- 18 Flutter regression tests pass, including full ten-question review and continuation, empty/unknown offerings, retry, real store price display, cancellation, missing entitlement, restoration, CSV parsing, duplicate filtering, local account naming/isolation, deletion ordering and small-screen enlarged-text payment controls. Purchases are simulated through an injected billing client; these are not Apple transactions.
- 26 checks execute the app's selection SQL in SQLite against all six supplied French categories (854 source questions). They verify within-session uniqueness, previous-session exclusion, least-seen priority and mastered-question exclusion, and preservation of local progress against stale cloud snapshots.
- Static analysis: no errors or warnings; informational lint/deprecation suggestions remain. See `ANALYSIS.txt`.
- Android debug build succeeds. See `BUILD_RESULTS.txt`.
- `ASSET_AUDIT.json` reports 33 repeated French stems within their categories (821 distinct stems), no malformed French answer blocks, and no missing UI keys under the audit script's literal-key scan.
- Native iOS build and live purchase validation are **not performed**.

Run the checks from this project folder:

```text
flutter pub get
flutter test
dart analyze
python tools/verify_selection_sql.py
python tools/audit_assets.py
dart run tools/audit_translation_matching.dart
flutter build apk --debug
```

On macOS, use the same project, run `flutter pub get`, install the iOS pods if required, open `ios/Runner.xcworkspace`, use your existing signing configuration, and build a new TestFlight build with an unused build number. Do not reuse the original ZIP's build number `+6` for an upload already accepted by App Store Connect. Existing store releases are unchanged.

TestFlight acceptance checks: complete ten free practice questions, review forward/back without score changes; buy each plan with a sandbox tester; confirm the expected entitlement and paid practice/mock access; restart the app; restore after reinstall; test cancellation and network failures; test login/logout and a second account; check all six languages including RTL layouts and missing-translation fallbacks.
