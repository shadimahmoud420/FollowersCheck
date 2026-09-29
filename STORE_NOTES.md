# Store review notes (App Store & Google Play)

> Step-by-step release guide in Arabic: [docs/RELEASE_GUIDE.md](docs/RELEASE_GUIDE.md).
> Store listing texts: [docs/STORE_LISTING.md](docs/STORE_LISTING.md).

These notes help the app pass review and avoid trademark / data-policy
rejections. Copy the relevant parts into App Review notes / Play Console.

## Positioning

- **Name / icon / package id must not contain "Instagram"** (or "Insta",
  "IG", the camera-glyph logo, or Meta brand colors/gradients). Current ids:
  - Android `applicationId`: `com.followercheck.follower_check`
  - iOS bundle id: `com.followercheck.followerCheck`
  - Display name: `Follower Check` (placeholder)
- Referring to Instagram **in the description and in-app instructions** is
  nominative use and is fine, e.g. "Works with the data export you download
  from Instagram". Always add the disclaimer:

  > Follower Check is an independent app and is not affiliated with,
  > endorsed or sponsored by Instagram or Meta.

- Do not use Instagram screenshots/UI or logos in store screenshots. Use the
  app's own screens with demo usernames.

## Key facts for reviewers

- The app **never asks for a password** and **never logs in** to any service.
- It uses **no unofficial / private API**, no scraping, no WebView login.
- The user provides a file they exported themselves via
  *Settings › Accounts Center › Your information and permissions › Export your
  information* (Followers and following, JSON).
- All processing is **on-device**. No backend, no analytics, no ads, no
  tracking SDKs. Android manifest has **no `INTERNET` permission**.

### Suggested App Review note (Apple)

> Follower Check compares two data-export files that the user downloads from
> their own Instagram account (Settings › Accounts Center › Export your
> information, JSON format). The app never requests credentials and makes no
> network requests; everything is processed locally. To test, use the sample
> files attached / in the demo ZIP: import `export_week1.zip`, then
> `export_week2.zip`, and open the Results tab. (In the free tier only one
> comparison per week is allowed – please use the Premium sandbox purchase or
> a debug build to import twice.)

Prepare a demo ZIP pair from `test/fixtures` (e.g. `legacy/` then `current/`)
and attach it, or host it and put the link in the review notes.

## Apple App Store

- **Guideline 5.2.1/5.2.2 (IP)**: no Meta marks in name, subtitle, icon,
  keywords field. Keywords like "followers, unfollow, tracker" are fine.
- **Guideline 5.1.1 (Data collection)**: App Privacy "nutrition label" →
  **Data Not Collected** (data never leaves the device).
- **Guideline 4.2 (minimum functionality)**: emphasize history, charts,
  bilingual UI and reminders.
- **Guideline 3.1.1**: premium must be purchased via StoreKit (already
  planned via `in_app_purchase`). Provide a *Restore purchases* button (done).
- File import uses the system document picker – no special entitlements
  needed. Local notifications need no push entitlement.
- Privacy manifest (`PrivacyInfo.xcprivacy`): declare `NSPrivacyTracking =
  false`, no tracking domains, and the required-reason APIs used by plugins
  (e.g. `UserDefaults` – `CA92.1`). Most plugins ship their own manifests;
  re-check the Xcode privacy report before submitting.

## Google Play

- **Data safety form**: "No data collected", "No data shared". Data is
  processed ephemerally on device.
- **Impersonation / IP policy**: no Instagram logo, name or look-alike icon;
  include the disclaimer in the full description.
- **Permissions**: `POST_NOTIFICATIONS` (reminders),
  `RECEIVE_BOOT_COMPLETED` (restore scheduled reminders after reboot). No
  exact-alarm permission is used (inexact scheduling).
- **Billing**: `in_app_purchase` adds `com.android.vending.BILLING`
  automatically; create the product `follower_check_premium` before enabling.
- Target the latest required API level; provide a privacy policy URL (host
  `PRIVACY.md`).

## Before publishing checklist

- [ ] Replace placeholder name/icon.
- [ ] Enable GitHub Pages on `/docs` and add the privacy policy URL
      (`docs/privacy-policy.html`) and support URL (`docs/index.html`) to both stores.
- [ ] Create IAP product `follower_check_premium` (non-consumable) and test
      with sandbox / license testers; add receipt verification.
- [ ] Create the upload keystore and `android/key.properties` (see
      `android/key.properties.example`), or configure it in Codemagic.
- [ ] Set `APP_STORE_APPLE_ID` in `codemagic.yaml`.
- [ ] Screenshots in Arabic and English, light & dark.
