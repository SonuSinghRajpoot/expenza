# Release Build Files - Distribution Guide

## ⚠️ Why Build Files Aren't in Git

GitHub has file size limits:
- **Maximum file size**: 100 MB
- **Recommended maximum**: 50 MB

Our build files:
- **APK**: 109.6 MB (exceeds 100 MB limit)
- **AAB**: 70.2 MB (exceeds 50 MB recommendation)

Therefore, build files **cannot** be pushed directly to GitHub.

---

## 📦 Option 1: GitHub Releases (Recommended)

### Create a Release on GitHub

1. **Go to your repository**: https://github.com/SonuSinghRajpoot/expenza
2. **Click "Releases"** → **"Create a new release"**
3. **Fill in details**:
   - Tag: `v1.0.0`
   - Title: `Expenza v1.0.0`
   - Description:
     ```
     Initial release of Expenza
     
     - Trip and expense management
     - AI-powered bill scanning
     - PDF and Excel export
     ```
4. **Upload files**:
   - Drag and drop `app-release.apk` (109.6 MB)
   - Drag and drop `app-release.aab` (70.2 MB)
5. **Click "Publish release"**

### Download from Releases

Users can download directly from:
```
https://github.com/SonuSinghRajpoot/expenza/releases
```

**Benefits:**
- ✅ No file size limits
- ✅ Easy to download
- ✅ Version history
- ✅ Release notes

---

## 🔧 Option 2: Git LFS (Large File Storage)

If you really want build files in Git, use Git LFS:

### Setup Git LFS

```bash
# Install Git LFS (if not installed)
# Windows: Download from https://git-lfs.github.com/
# Mac: brew install git-lfs
# Linux: sudo apt-get install git-lfs

# Initialize Git LFS in your repository
git lfs install

# Track APK and AAB files
git lfs track "*.apk"
git lfs track "*.aab"

# Add .gitattributes (created automatically)
git add .gitattributes

# Add the files
git add build/app/outputs/flutter-apk/app-release.apk
git add build/app/outputs/bundle/release/app-release.aab

# Commit and push
git commit -m "Add release builds via Git LFS"
git push origin master
```

**Note:** Git LFS has storage limits on free GitHub accounts (1 GB).

---

## 🏗️ Option 3: Build on Each Machine (Best Practice)

The recommended approach is to **build the files on each machine**:

### On New Machine

```bash
# Clone repository
git clone https://github.com/SonuSinghRajpoot/expenza.git
cd expenza

# Install dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Build release AAB
flutter build appbundle --release
```

**Benefits:**
- ✅ No repository bloat
- ✅ Always up-to-date builds
- ✅ No file size issues
- ✅ Standard practice

---

## 📱 Option 4: Cloud Storage

Upload to cloud storage and share links:

- **Google Drive**
- **Dropbox**
- **OneDrive**
- **Firebase App Distribution**
- **Other file hosting**

---

## ✅ Recommended Approach

**For Development:**
- Keep build files out of Git
- Build on each machine as needed
- See `SETUP_NEW_MACHINE.md` for setup instructions

**For Distribution:**
- Use **GitHub Releases** for easy downloads
- Or use **Firebase App Distribution** for beta testing
- Or use **Google Play Store** for production

---

## 📍 Current Build File Locations

On your current machine:
- **APK**: `d:\Projects\Expenses\build\app\outputs\flutter-apk\app-release.apk`
- **AAB**: `d:\Projects\Expenses\build\app\outputs\bundle\release\app-release.aab`

These files are **not** in Git (by design) but can be:
1. Uploaded to GitHub Releases
2. Shared via cloud storage
3. Built fresh on any machine

---

## 🚀 Quick Actions

### Create GitHub Release

1. Go to: https://github.com/SonuSinghRajpoot/expenza/releases/new
2. Tag: `v1.0.0`
3. Upload APK and AAB files
4. Publish

### Build on New Machine

```bash
git clone https://github.com/SonuSinghRajpoot/expenza.git
cd expenza
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

---

**Summary**: Build files are too large for Git. Use GitHub Releases for distribution, or build them on each machine.
