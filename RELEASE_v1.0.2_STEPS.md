# Release v1.0.2 – What You Need to Do

## Done Automatically

- Version bumped to **1.0.2+3**
- Release APK built: `build\app\outputs\flutter-apk\app-release.apk` (109.7 MB)
- All code changes committed and pushed to GitHub: https://github.com/SonuSinghRajpoot/expenza

---

## Your Next Steps

### 1. Create a GitHub Release (to distribute the APK)

1. Open: https://github.com/SonuSinghRajpoot/expenza/releases/new  
2. **Choose a tag**: `v1.0.2` (create if it doesn’t exist)  
3. **Release title**: `Expenza v1.0.2`  
4. **Description** (example):
   ```
   ## What's New in v1.0.2

   - Share + PDF: AI analysis now works when sharing PDFs to the app
   - AI: Switched to Gemini 2.5 Flash, improved receipt extraction (pax, amount, merchant logic)
   - Notes: Generated from extracted fields instead of raw receipt text
   - Duplicate expense: Fixed detection (amount, city comparisons)
   - Permissions: Camera/Gallery/Storage requested before use
   - Data: DB moved to documents; migration from old path; data storage notice in Profile
   - UI: Compact locations list when editing a trip
   ```
5. **Attach APK**:
   - Drag and drop: `d:\Projects\Expenses\build\app\outputs\flutter-apk\app-release.apk`
6. Click **Publish release**

### 2. (Optional) Build AAB for Play Store

If you plan to publish to the Play Store:

```powershell
cd d:\Projects\Expenses
flutter build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`

### 3. (Optional) Share the APK

- Users can install the APK from: https://github.com/SonuSinghRajpoot/expenza/releases  
- Or you can copy the APK from `build\app\outputs\flutter-apk\app-release.apk` and share it directly.

---

## Summary

| Action              | Status                         |
|---------------------|--------------------------------|
| Version bump        | Done (1.0.2+3)                 |
| Release APK build   | Done                           |
| Code push to GitHub | Done                           |
| GitHub Release      | **You need to create it**      |
| Upload APK to Release | **You need to upload it**   |
