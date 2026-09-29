# Follower Check

_Placeholder name._ A Flutter app (Android + iOS, Arabic & English) that shows
who unfollowed you by comparing two copies of your own **"Followers and
following" data export** (JSON).

- Never asks for a password, never logs in, never uses an unofficial API.
- 100% on-device: no backend, no analytics, no trackers, no `INTERNET`
  permission.
- Arabic (RTL) by default, English available. Material 3, light & dark themes.

See [PRIVACY.md](PRIVACY.md) and [STORE_NOTES.md](STORE_NOTES.md).

## Features

| Screen | What it does |
|--------|--------------|
| Onboarding (3 pages) | Explains the app, the export steps (Settings › Accounts Center › Your information and permissions › Export your information › Followers and following › JSON) and that we never ask for a password |
| Import | Pick a ZIP or JSON file(s) with the system picker; parsing runs in a background isolate; each import becomes a snapshot in SQLite |
| Results | 3 tabs – **Unfollowed you**, **Not following back**, **New followers** – with search, counters, and a button that opens `instagram.com/<username>` |
| History | Snapshots with follower/following counts and an `fl_chart` line chart; tap to see that snapshot's comparison, or delete it |
| Settings | Language (AR/EN), theme, weekly / bi-weekly local reminder, delete all data, privacy policy, export guide |
| Paywall | Premium placeholder (unlimited comparisons, full history, charts) |

### Free vs Premium

Rules live in [`UsagePolicy`](lib/features/premium/domain/usage_policy.dart):

- Free: **1 comparison (import) per 7 days** (the first import is always
  allowed), last **2** snapshots in history, no chart.
- Premium: unlimited imports, full history, charts.

Premium status comes from the
[`EntitlementService`](lib/features/premium/domain/entitlement_service.dart)
interface. The current implementation
([`InAppPurchaseEntitlementService`](lib/features/premium/data/in_app_purchase_entitlement_service.dart))
uses `in_app_purchase` with a placeholder product id
`follower_check_premium` that doesn't exist in the stores yet, so the paywall
shows "Purchases aren't available yet". To go live, create that product
(non-consumable) in App Store Connect / Play Console and add receipt
validation. In **debug builds**, Settings has a "Simulate Premium" switch.

## Architecture

```
lib/
  main.dart                 # wires real implementations into Riverpod
  app.dart                  # MaterialApp.router, themes, localization
  core/                     # router (go_router), theme, shared providers, helpers
  l10n/                     # app_en.arb, app_ar.arb (+ generated/)
  features/
    onboarding/presentation
    import/
      domain/               # ExportParser (pure Dart) + models
      data/                 # file_picker adapter
      application/          # ImportController (Riverpod Notifier)
      presentation/
    snapshots/
      domain/               # Snapshot, SnapshotRepository, SnapshotDiff
      data/                 # sqflite repository
      application/          # providers
    results/presentation
    history/presentation
    premium/                # EntitlementService, UsagePolicy, IAP placeholder, paywall
    settings/               # settings, reminders (flutter_local_notifications), privacy
test/
  fixtures/                 # sample exports: current/ and legacy/ formats, html/
  features/                 # parser, diff, policy, repository unit tests
  widget/                   # end-to-end widget flow with fakes
```

- **State**: Riverpod 3 (`Notifier`, `FutureProvider`); platform services are
  injected by overriding providers, so tests use fakes.
- **Navigation**: go_router with a `StatefulShellRoute` bottom navigation.
- **Storage**: sqflite (`snapshots`, `snapshot_users` tables);
  shared_preferences for settings.

### Parser

[`ExportParser`](lib/features/import/domain/export_parser.dart) is plain Dart
(no Flutter imports), and written defensively:

- ZIP: finds `followers.json`, `followers_1.json`, `followers_2.json`, … and
  `following.json` **at any depth**; ignores other files and `__MACOSX` junk.
- Followers: a bare list of `{"string_list_data": [{"href","value","timestamp"}]}`,
  or an object wrapping such a list (`relationships_followers`).
- Following: `{"relationships_following": [...]}` with the username in
  `title` **or** `string_list_data[0].value`; falls back to parsing `href`
  (`instagram.com/_u/<name>`).
- Usernames are trimmed, `@` removed, lowercased and validated.
- HTML exports produce a "please re-export as JSON" error; unrecognized files
  produce a friendly "nothing found" error.

## Setup

Requirements: Flutter **3.47+** (Dart 3.13), Xcode 16+ for iOS, Android SDK
36 for Android.

```bash
flutter pub get
flutter gen-l10n          # also runs automatically on build (generate: true)
flutter analyze
flutter test
```

### Run

```bash
flutter run               # on a connected device / emulator / simulator
```

Android release build (currently signed with debug keys – configure signing
in `android/app/build.gradle.kts` before publishing):

```bash
flutter build apk --release
flutter build appbundle --release
```

iOS:

```bash
flutter build ios --release   # then archive in Xcode
```

### Try it without a real export

Build a ZIP from the fixtures and push it to the device:

```bash
(cd test/fixtures/legacy && zip -r /tmp/export_week1.zip .)
(cd test/fixtures/current && zip -r /tmp/export_week2.zip .)
```

Import `export_week1.zip`, then (with "Simulate Premium" on, or a week later)
`export_week2.zip`.

## Platform notes

- **Android**: no `INTERNET` permission. `POST_NOTIFICATIONS` and
  `RECEIVE_BOOT_COMPLETED` for reminders; core library desugaring enabled
  (required by flutter_local_notifications). `<queries>` entry for https
  links (url_launcher).
- **iOS**: deployment target 15.0; `CFBundleLocalizations` = ar, en.
  Reminders use local notifications only (permission requested when the user
  turns them on).
- Reminders: neither OS supports a native "every 2 weeks" repeat, so the app
  schedules a chain of 6 one-shot notifications and refreshes it on every app
  start and import.

## Renaming the app

The name is a placeholder. Change `appTitle` in the ARB files,
`android:label` in `AndroidManifest.xml`, `CFBundleDisplayName`/`CFBundleName`
in `ios/Runner/Info.plist`, and (optionally) the application / bundle ids.
Never use "Instagram" in the name, id or icon.
