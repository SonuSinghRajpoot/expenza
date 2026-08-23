# Expenza - Release Notes & Changelog (August 23, 2026)

## 🚀 Overview of Changes
This release brings major enhancements in **Expense Ordering Intelligence**, **Gemini 3.7 AI Model Customization**, **Hardware Security & Task Affinity**, and **Persistent Account Backup across App Reinstalls**.

---

## 🌟 Key Features & Improvements

### 1. 📅 Smart Chronological Expense Insertion (`FEAT-009`)
- **What Changed:** When creating a new expense, it is now automatically placed in **exact chronological order by expense date** rather than simply appending to the bottom of the list.
- **Same-Day Sub-Ordering (FIFO):** If multiple expenses exist on the same calendar day, newly added entries are slotted immediately after existing same-day entries, maintaining natural daytime sequence before subsequent trip dates.
- **Batch Database Shifting:** Subsequent expense `display_order` records are shifted by `+1` in an atomic SQLite transaction, ensuring ordered PDF and Excel exports.
- **Files Modified:**
  - `lib/data/repositories/trip_repository.dart`
  - `test/expense_insertion_order_test.dart` (New Unit Tests)

---

### 2. 🤖 Dynamic In-App Gemini Model Selection (`GEM-003`)
- **What Changed:** Removed hardcoded model versions. Users can now select and update Gemini AI models directly from the app interface without modifying code or waiting for new app releases.
- **Modern Presets & Default Upgrade:**
  - **`gemini-3.7-flash`** (Set as new Default with hybrid reasoning & multimodal precision).
  - `gemini-2.5-flash` (Fast & balanced).
  - `gemini-2.5-pro` (High reasoning for complex or low-quality invoices).
  - Removed obsolete legacy models (2.0 and lower).
- **Future-Proof Custom Model Support:** Added a "Custom / Future Model" option where users can type any new model identifier (e.g. `gemini-3.8-flash`, `gemini-4.0-flash`) and apply it immediately.
- **Reactive UI:** Tabbed Gemini Settings dialog with live active model display in the Profile screen.
- **Files Modified:**
  - `lib/services/gemini_service.dart`
  - `lib/data/repositories/gemini_repository.dart`
  - `lib/providers/gemini_provider.dart`
  - `lib/screens/profile/manage_gemini_keys_dialog.dart`
  - `lib/screens/profile/profile_screen.dart`
  - `lib/screens/expense_form/expense_form.dart`
  - `lib/screens/trip_details/trip_details_screen.dart`
  - `test/gemini_model_config_test.dart` (New Unit Tests)

---

### 3. ⚡ Test Connection for Gemini Keys & AI Models (`GEM-004`)
- **What Changed:** Added a fast (<1s) **Test Connection** button for Gemini API keys and model versions to verify credentials before saving or scanning receipts.
- **Instant Health Verification:**
  - Inline **"Test Connection"** button on the *Add New Key* form with loading spinner and green/red status badge.
  - On-demand test button on all saved API key cards.
  - **"Test Model"** button to verify custom/future model names against the active key before applying.
- **Helpful Error Diagnostics:** Automatically translates status codes into user-friendly messages (`Invalid API Key (400)`, `Model Not Found (404)`, `Quota Exceeded (429)`, `Network Error`).
- **Files Modified:**
  - `lib/services/gemini_service.dart`
  - `lib/screens/profile/manage_gemini_keys_dialog.dart`
  - `test/gemini_test_connection_test.dart` (New Unit Tests)

---

### 4. 📱 Single App Instance & Sharing Intent Optimization (`ARCH-007`)
- **What Changed:** Fixed an issue where sharing receipt files (PDF/Images) from external apps (WhatsApp, Photos, Files) while Expenza was open created duplicate app instances in the Android App Switcher (Recents).
- **Task Affinity Fix:** Configured `android:launchMode="singleTask"` and removed blank `taskAffinity` in Android Manifest.
- **Seamless Flow:** Incoming shares now bring the existing running Expenza instance to the foreground and route the file directly to the active session without duplicate windows or SQLCipher concurrency lock risks.
- **Files Modified:**
  - `android/app/src/main/AndroidManifest.xml`

---

### 5. 💾 Local Account Profile & Gemini Key Persistence Across Installs (`TEST-006`)
- **What Changed:** Solved the problem where fresh app reinstalls or data clears wiped all information under the Accounts tab.
- **Persistent Local Config:** Added `AccountBackupService` that automatically maintains an `expenza_account_config.json` in public device storage (`Documents/Expenza/` and `Download/Expenza/`), which survives app uninstalls.
- **Full Accounts Data Coverage:**
  - **User Profile:** Full Name, Nickname, Employee ID, Company, Phone, WhatsApp, Profile Picture (base64).
  - **Bank Details:** Account Name, Number, IFSC, Bank Name, Branch.
  - **UPI Details:** UPI ID, UPI Name.
  - **Gemini Settings:** All API Keys (with labels and active status) and active AI model.
- **Automatic Two-Way Synchronization:**
  - **Auto-Sync:** Background sync on every profile or key edit.
  - **Auto-Restore:** Fresh installs automatically detect the backup and restore the entire Accounts tab instantly on launch.
- **UI Management:** Added **"LOCAL BACKUP & PERSISTENCE"** card in Profile screen with last sync time, **"Backup Now"**, and **"Restore Backup"** buttons.
- **Files Modified:**
  - `lib/core/services/account_backup_service.dart` (New Service)
  - `lib/data/repositories/user_repository.dart`
  - `lib/data/repositories/gemini_repository.dart`
  - `lib/screens/profile/profile_screen.dart`
  - `test/account_backup_test.dart` (New Unit Tests)

---

### 6. 📱 Modern Android Guidelines & Edge-to-Edge System Architecture (`ARCH-008`)
- **What Changed:** Aligned app behavior with official Android 14/15 OS design guidelines and system ergonomics.
- **Predictive Back Navigation:** Enabled `android:enableOnBackInvokedCallback="true"` in Android Manifest for fluid back navigation animations.
- **Immersive Edge-to-Edge Display:** Configured transparent status and navigation bar overlays with system UI mode in `main.dart` and Android `styles.xml` for an edge-to-edge look without navigation bar letterboxing.
- **Manifest Modernization:** Cleaned up legacy Android 10 storage migration attributes (`requestLegacyExternalStorage`).
- **Files Modified:**
  - `android/app/src/main/AndroidManifest.xml`
  - `lib/main.dart`
  - `android/app/src/main/res/values/styles.xml`
  - `android/app/src/main/res/values-night/styles.xml`

---

### 7. 📋 Master Enhancement Roadmap Created
- Created **`TODO_2026-08-23.md`** containing 39 categorized, prioritized enhancement tasks across 5 domain areas (`UIUX`, `GEM`, `FEAT`, `ARCH`, `TEST`) with tracking indices.

---

## 🧪 Testing & Quality Assurance Summary

| Test File | Scenarios Covered | Status |
| :--- | :--- | :--- |
| `test/expense_insertion_order_test.dart` | Empty list, earlier date, later date, intermediate date, same-day FIFO, time invariance | ✅ Passed |
| `test/gemini_model_config_test.dart` | Default model (`gemini-3.7-flash`), modern presets, custom model persistence, whitespace trimming | ✅ Passed |
| `test/gemini_test_connection_test.dart` | API key validation, empty key handling, error translation | ✅ Passed |
| `test/account_backup_test.dart` | Profile + Gemini keys JSON sync, last modified timestamp, and auto-restoration | ✅ Passed |

---

## 📂 Summary of Modified / Created Files

```
├── android/
│   ├── app/src/main/AndroidManifest.xml           # singleTask, enableOnBackInvokedCallback, storage cleanup
│   └── app/src/main/res/values*/styles.xml        # Transparent system bars for edge-to-edge
├── lib/
│   ├── core/services/
│   │   └── account_backup_service.dart            # [NEW] Persistent local account backup service
│   ├── data/repositories/
│   │   ├── trip_repository.dart                   # Smart chronological insertion & same-day FIFO
│   │   ├── user_repository.dart                   # Auto-sync & auto-restore integration
│   │   └── gemini_repository.dart                 # Dynamic model versioning & backup integration
│   ├── providers/
│   │   └── gemini_provider.dart                   # Reactive geminiModelProvider
│   ├── screens/
│   │   ├── expense_form/expense_form.dart         # Dynamic model passed to analyzeBill
│   │   ├── profile/
│   │   │   ├── manage_gemini_keys_dialog.dart     # AI Model tab & Test Connection buttons
│   │   │   └── profile_screen.dart                # Active model display & Local Backup UI
│   │   └── trip_details/trip_details_screen.dart  # Dynamic model passed to analyzeBill
│   ├── services/
│   │   └── gemini_service.dart                    # testConnection probe & dynamic model support
│   └── main.dart                                  # Edge-to-Edge SystemUI overlay configuration
├── test/
│   ├── account_backup_test.dart                   # [NEW] Unit tests for account backup & restore
│   ├── expense_insertion_order_test.dart          # [NEW] Unit tests for chronological insertion
│   ├── gemini_model_config_test.dart              # [NEW] Unit tests for model config & presets
│   └── gemini_test_connection_test.dart           # [NEW] Unit tests for testConnection probe
├── RELEASE_NOTES_2026-08-23.md                    # [NEW] Master release notes & changelog
└── TODO_2026-08-23.md                             # [NEW] Categorized enhancement roadmap
```
