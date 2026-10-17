# Expenza v1.2.2 (1.2.2+9) — Predictability fixes

Restore point for the previous version: git tag `restore/v1.2.1-before-fixes` (same commit as `v1.2.1`).

## Sharing files into the app
- **SHR-1** Database opens only once, even when several screens ask for it at startup. Fixes shares that did nothing on the first try and worked on the second.
- **SHR-2** Errors while handling a share now show a message, and loading the trip list is retried once.
- **SHR-3** The trip list no longer resets to "loading" on every change. The expense form waits for the trip, so trip cities and date limits are always applied.
- **SHR-4** Shares are handled one at a time, repeat deliveries are ignored, and the launch share is marked as consumed. Reopening the app from Recents no longer replays an old share (MainActivity).
- **SHR-5** Launch permission prompts wait until the app is unlocked and no share is in progress. They are skipped for a launch that came from a share.
- **SHR-6** PDFs are recognised by their content, not only by a `.pdf` file name ending, and are always stored with a `.pdf` extension.
- **SHR-7** The AI-Scan option shows a "Checking Gemini key…" placeholder while keys load, instead of appearing late.

## Cities
- **CTY-1** New built-in list of Indian cities with old names, spellings and airport/station codes (`lib/core/constants/indian_cities.dart`), and a resolver (`IndianCityResolver`). AI cities are mapped to a canonical city or left blank, with a hint showing what the AI read.
- **CTY-2** Only recognised trip cities are sent to Gemini as hints. Saved cities use the canonical spelling.
- **CTY-3** The prompt asks for city names only (no airport, terminal, station or area) plus `fromCode`/`toCode`.
- **CTY-4** The city field offers the full city list. Unrecognised names need a "Use anyway?" confirmation. Duplicate detection compares canonical cities.

## Remarks
- **RMK-1** Older Gemini models use temperature 0. Gemini 3 models keep their default, as Google recommends.
- **RMK-2** All pages are sent, up to 6. Pages rendered from a PDF always use Vision. The on-device OCR shortcut is used only when it returns amount, date and head.
- **RMK-3** AI output is cleaned up in one place (`GeminiService.normalizeResult`), and sub-heads must belong to the head.
- **RMK-4 / RMK-5** The remark is built from the form's final values (`RemarkBuilder`). It updates as fields change, until the user types their own notes.

## Form
- **GEN-2** Head and Sub Head validate the values on screen. An AI-filled sub-head no longer shows "Required".

## Tests
`test/indian_city_resolver_test.dart`, `test/remark_builder_test.dart`, `test/gemini_normalize_result_test.dart`

## Also in this version
- New **Subscription** head (sub-heads: Software / App, Others). City is optional for this head.
- Consistent outlined icons for every head and sub-head.
- City dropdown panel height is capped and the panel scrolls.
- **Back up before updating:** tapping Update first suggests saving the Excel and PDF reports. With active trips it lists them; with none, it lists submitted trips that have no report yet. It can generate them in one tap.
- **In-app updates from GitHub Releases:** checks on every app launch (never during or after a launch from a shared file), plus **Profile → App Updates → Check for updates**. Shows the release notes, downloads the right APK for the phone and opens the Android installer.

## How to publish an update so phones pick it up
1. Bump `version:` in `pubspec.yaml` (e.g. `1.2.3+10`).
2. Build with the **same signing key** as the installed app: `flutter build apk --release --split-per-abi` (a single universal APK also works).
3. Create a GitHub Release on `SonuSinghRajpoot/expenza` with tag `v1.2.3` (it must match the pubspec version) and attach the APK file(s). Don't mark it as a draft or pre-release.
4. The release description is shown as "What's new" in the app.
