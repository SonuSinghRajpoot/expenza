# Setting Up Expenza on a New Machine

This guide will help you clone and set up the Expenza project on any new machine for development.

---

## 📥 Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/SonuSinghRajpoot/expenza.git

# Navigate to the project directory
cd expenza
```

---

## 🔧 Step 2: Prerequisites

### Required Software

1. **Flutter SDK** (3.10.7 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH
   - Verify installation: `flutter doctor`

2. **Dart SDK** (comes with Flutter)
   - Verify: `dart --version`

3. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Install Android SDK and tools
   - Set up Android emulator (optional)

4. **Git** (for version control)
   - Usually pre-installed on Linux/Mac
   - Download for Windows: https://git-scm.com/download/win

### Verify Prerequisites

```bash
# Check Flutter installation
flutter doctor

# Check Git
git --version

# Check Dart
dart --version
```

---

## 📦 Step 3: Install Dependencies

```bash
# Navigate to project directory
cd expenza

# Get Flutter dependencies
flutter pub get

# Verify dependencies are installed
flutter pub deps
```

---

## 🔐 Step 4: Set Up Android Signing (For Release Builds)

### Option A: Use Existing Keystore (If You Have It)

1. **Copy keystore file** to a secure location:
   - Original location: `C:\Users\ctlp0\OneDrive\Documents\expenza-keystore.jks`
   - Copy to your new machine (keep it secure!)

2. **Create `android/key.properties`**:
   ```bash
   # Copy the example file
   cp android/key.properties.example android/key.properties
   ```

3. **Edit `android/key.properties`** with your keystore details:
   ```properties
   storePassword=YourKeystorePassword
   keyPassword=YourKeyPassword
   keyAlias=upload
   storeFile=/absolute/path/to/expenza-keystore.jks
   ```

### Option B: Generate New Keystore (If Starting Fresh)

If you don't have the original keystore, you'll need to generate a new one:

```bash
# Generate new keystore
keytool -genkey -v -keystore ~/expenza-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**⚠️ Important**: Using a different keystore means you can't update the existing app on Play Store. Only use this if you're creating a new app listing.

---

## 🧪 Step 5: Verify Setup

### Check Project Structure

```bash
# Verify key files exist
ls -la android/key.properties.example
ls -la pubspec.yaml
ls -la lib/main.dart
```

### Run Flutter Analysis

```bash
# Check for issues
flutter analyze

# Check dependencies
flutter pub outdated
```

### Test Build (Optional)

```bash
# Build debug APK to verify setup
flutter build apk --debug

# Or run on connected device/emulator
flutter run
```

---

## 🔑 Step 6: Configure Gemini API Key (For AI Features)

The app requires a Google Gemini API key for bill scanning features:

1. **Get API Key**:
   - Visit: https://makersuite.google.com/app/apikey
   - Create a new API key

2. **Add to App**:
   - Run the app: `flutter run`
   - Navigate to: Profile → Manage Gemini Keys
   - Add your API key with a label

---

## 📱 Step 7: Development Workflow

### Daily Development

```bash
# Pull latest changes
git pull origin master

# Install/update dependencies
flutter pub get

# Run the app
flutter run

# Or build for specific platform
flutter build apk --release
flutter build appbundle --release
```

### Making Changes

```bash
# Create a new branch for features
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Commit changes
git add .
git commit -m "Description of changes"

# Push to GitHub
git push origin feature/your-feature-name

# Create pull request on GitHub (if working with team)
```

---

## 🐛 Troubleshooting

### Issue: "Flutter command not found"
- **Solution**: Add Flutter to your PATH
  - Windows: Add Flutter bin directory to System Environment Variables
  - Linux/Mac: Add to `~/.bashrc` or `~/.zshrc`:
    ```bash
    export PATH="$PATH:/path/to/flutter/bin"
    ```

### Issue: "Android SDK not found"
- **Solution**: 
  - Install Android Studio
  - Run `flutter doctor --android-licenses` to accept licenses
  - Set `ANDROID_HOME` environment variable

### Issue: "Dependencies not found"
- **Solution**:
  ```bash
  flutter clean
  flutter pub get
  ```

### Issue: "Build fails with signing errors"
- **Solution**: 
  - Ensure `android/key.properties` exists
  - Verify keystore file path is correct
  - Check keystore passwords are correct

### Issue: "Cannot find key.properties"
- **Solution**: 
  - Copy `android/key.properties.example` to `android/key.properties`
  - Fill in your keystore details
  - **Note**: `key.properties` is in `.gitignore` (not committed to Git)

---

## 📂 Important Files and Directories

### Project Structure
```
expenza/
├── lib/                    # Main Dart source code
│   ├── main.dart          # App entry point
│   ├── models/            # Data models
│   ├── screens/            # UI screens
│   ├── providers/          # State management (Riverpod)
│   ├── data/               # Repositories and database
│   └── core/               # Core utilities and services
├── android/                # Android-specific files
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/
│   └── key.properties.example  # Template for signing config
├── pubspec.yaml            # Dependencies and project config
├── .gitignore              # Git ignore rules
└── README.md               # Project documentation
```

### Files NOT in Git (Sensitive)
- `android/key.properties` - Your signing credentials
- `*.jks`, `*.keystore` - Keystore files
- `.env` files - Environment variables
- Build artifacts in `build/` directory

---

## ✅ Setup Verification Checklist

After setup, verify:

- [ ] Repository cloned successfully
- [ ] Flutter installed and working (`flutter doctor`)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] `android/key.properties` created (if needed for release builds)
- [ ] Project builds without errors (`flutter build apk --debug`)
- [ ] App runs on device/emulator (`flutter run`)
- [ ] Git remote configured (`git remote -v`)

---

## 🔄 Syncing with GitHub

### Pull Latest Changes

```bash
# Fetch and merge latest changes
git pull origin master

# Or fetch first, then merge
git fetch origin
git merge origin/master
```

### Push Your Changes

```bash
# Stage changes
git add .

# Commit changes
git commit -m "Your commit message"

# Push to GitHub
git push origin master
```

---

## 📚 Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Documentation**: https://dart.dev/guides
- **Git Documentation**: https://git-scm.com/doc
- **Project README**: See `README.md` in project root

---

## 🎯 Quick Start Commands

```bash
# Clone repository
git clone https://github.com/SonuSinghRajpoot/expenza.git
cd expenza

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build release APK
flutter build apk --release

# Build release AAB (for Play Store)
flutter build appbundle --release
```

---

**You're all set! Happy coding! 🚀**
