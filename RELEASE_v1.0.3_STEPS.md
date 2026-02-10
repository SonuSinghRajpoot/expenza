# Release v1.0.3 – What You Need to Do

## Done Automatically

- Version bumped to **1.0.3+4**
- All code changes committed and pushed to GitHub: https://github.com/SonuSinghRajpoot/expenza

---

## What's New in v1.0.3

- PDF Export: Fix evidence images from Camera/Smart Scan not appearing in generated PDF
- Evidence storage: Camera/gallery images are now persisted into app documents (`Expenza/bills`) and normalized to JPEG for better compatibility

---

## Your Next Steps

### 1. Create a GitHub Release (to distribute the APK)

1. Open: https://github.com/SonuSinghRajpoot/expenza/releases/new  
2. **Choose a tag**: `v1.0.3` (create if it doesn’t exist)  
3. **Release title**: `Expenza v1.0.3`  
4. **Description** (example):
   ```
   ## What's New in v1.0.3

   - PDF export now correctly includes evidence images scanned via camera
   - Evidence images are persisted more reliably and normalized for PDF compatibility
   ```
5. **Attach APK**:
   - Build APK locally (see below) and upload `build\app\outputs\flutter-apk\app-release.apk`
6. Click **Publish release**

### 2. Build Release APK

```powershell
cd d:\Projects\Expenses
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

### 3. (Optional) Build AAB for Play Store

```powershell
cd d:\Projects\Expenses
flutter build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`

---

## Summary

| Action              | Status                    |
|---------------------|---------------------------|
| Version bump        | Done (1.0.3+4)            |
| Code push to GitHub | Done                      |
| GitHub Release      | **You need to create it** |
| Upload APK to Release | **You need to upload it** |

