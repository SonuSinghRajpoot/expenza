# Expenza - Release Notes v1.2.0 (Build 7)
**Release Date:** August 23, 2026  
**Version:** `1.2.0+7`

---

## 🚀 Overview of Release v1.2.0
Version 1.2.0 delivers major milestones across **Theme-Adaptive Visual Branding**, **Hardware Biometric Security**, **Smart Hybrid OCR Intelligence**, **Adaptive Image Compression**, **Multi-Page Folio Extraction**, **UI Polish with Shimmer Skeletons**, **Database Pagination**, and **Architectural Cleanliness**.

---

## 🌟 Key Features & Improvements

### 1. 🎨 Theme-Adaptive Rupee (`₹`) App Icon (`ICON-001`)
- **Adaptive OS Launcher Icon:** Full-bleed background with a centered circular Indian Rupee (`₹`) badge and 20% safe-area padding to prevent clipping across all OEM launcher masks (Samsung OneUI squircle, Pixel circle, OnePlus rounded rect).
- **Android 13+ Material You Monochromatic Vector:** Added `ic_launcher_monochrome.xml` supporting automatic dynamic color tinting when switching between Light Mode, Dark Mode, or system wallpaper palettes.
- **In-App Dynamic Vector `<AppLogo />`:** Automatically detects light/dark theme to display high-contrast gradient strokes.

### 2. 🔐 Hardware Biometric / PIN App Lock (`TEST-004`)
- **Native Android Security:** Migrated native host activity to `FlutterFragmentActivity` and integrated `local_auth` for Fingerprint, Face Unlock, and Device PIN authentication.
- **Instant Launch Protection:** Pre-loaded lock state on frame 1 to prevent unlock flickers.
- **Background Resume Locking:** Re-locks when app is sent to background and resumed.
- **Biometric Share Queue:** If a receipt or PDF is shared while the app is locked, `SharingListener` safely queues the intent and immediately opens the expense options dialog upon successful fingerprint authentication.
- **Settings Toggle:** Dedicated security toggle under the Profile tab.

### 3. 🧠 Smart Hybrid OCR Pipeline (`GEM-001`)
- **Fast Local Extraction:** Runs fast on-device Google ML Kit OCR on single receipt captures.
- **Lightweight Text Prompting:** If receipt text is clear ($\ge 80$ characters with digits/currency), sends a lightweight text prompt to Gemini (cutting scan time to ~1s and saving 90% tokens).
- **Vision Fallback:** Automatically falls back to full multimodal Vision if text is insufficient or skewed.

### 4. 📄 Multi-Page Document Stitching & Folio Extraction (`GEM-006`)
- Removed the previous 2-page limit, expanding Gemini document analysis to up to 6 pages for hotel folios, airline tickets, and multi-page tax invoices.

### 5. 📸 Adaptive Receipt Image Compression (`FEAT-007`)
- Downsamples camera photos exceeding 1800px on the longest dimension at 85% JPEG quality.
- Shrinks 4–8 MB camera captures down to ~200–350 KB while preserving 100% legibility of fine print, timestamps, and line items.

### 6. ✨ Shimmer Skeleton Loaders & Micro-Interactions (`UIUX-005`)
- Replaced plain circular progress spinners with modern `TripCardSkeleton`, `ExpenseCardSkeleton`, and `SummaryCardSkeleton` shimmer animations.

### 7. ⚡ Database Pagination & Lazy Loading (`ARCH-004`)
- Added optional `limit` and `offset` pagination to `TripRepository.getExpenses()` for high performance on large trips.

### 8. 🏗️ Architectural Modularization (`ARCH-001`, `ARCH-002`, `ARCH-003`)
- Decomposed monolithic screen files into reusable widgets:
  - `lib/screens/trip_details/widgets/trip_list_items.dart`
  - `lib/screens/expense_form/widgets/image_viewer_dialog.dart`
  - `lib/core/services/export/export_directory_helper.dart`

### 9. 🤖 Dynamic Gemini 3.7 Selection & Key Connection Tester (`GEM-003`, `GEM-004`)
- Added in-app Gemini model selector (`gemini-3.7-flash`, `gemini-2.5-flash`, `gemini-2.5-pro`, custom models) and on-demand **Test Connection** button for API keys.

### 10. 💾 Persistent Local Account Backup (`TEST-006`)
- Auto-syncs and restores profile information, bank/UPI details, and Gemini keys across app reinstalls via public storage.

### 11. 🔑 Unified App-Level Master Encryption Key (`ARCH-009`)
- **Persistent Decryption Across Reinstalls:** Replaced per-install random key generation with a deterministic unified master encryption key (`_kAppMasterPassKey`), ensuring that database backups and old `.db` files can always be decrypted and read across fresh reinstalls and device migrations.
- **Auto-Rekey Migration:** Seamlessly detects databases encrypted with older random keys or raw unencrypted databases and automatically re-encrypts them using `PRAGMA rekey`.

---

## 📦 Build Artifacts
- **Universal Release APK:** `build/app/outputs/flutter-apk/app-release.apk`
- **Split Per ABI APKs:**
  - `app-arm64-v8a-release.apk`
  - `app-armeabi-v7a-release.apk`
  - `app-x86_64-release.apk`
