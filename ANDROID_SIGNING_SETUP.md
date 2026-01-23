# Android Release Signing Configuration Guide

This guide explains how to set up release signing for Android builds.

## ⚠️ IMPORTANT

**DO NOT commit your `key.properties` file or keystore files to version control!** They are already in `.gitignore`.

## Step 1: Generate a Keystore

If you don't have a keystore yet, generate one:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- Keystore password
- Key password (can be same as keystore password)
- Your name and organization details

**Important**: Save these passwords securely! You'll need them to sign release builds.

## Step 2: Create key.properties File

1. Copy the example file:
   ```bash
   cp android/key.properties.example android/key.properties
   ```

2. Edit `android/key.properties` and fill in your values:
   ```properties
   storePassword=your_actual_keystore_password
   keyPassword=your_actual_key_password
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

   **Note**: Use absolute path for `storeFile`, or relative path from project root.

## Step 3: Update build.gradle.kts

Update `android/app/build.gradle.kts` to load the signing configuration:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fieldexpensemanager.field_expense_manager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.fieldexpensemanager.field_expense_manager"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug") // Fallback for CI/CD
            }
            isMinifyEnabled = false // Set to true and add ProGuard rules for production
            isShrinkResources = false // Set to true when minifyEnabled is true
        }
    }
}

flutter {
    source = "../.."
}
```

## Step 4: Test Release Build

Build a release APK to verify signing works:

```bash
flutter build apk --release
```

The signed APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Step 5: Build App Bundle (for Play Store)

For Google Play Store, build an App Bundle instead of APK:

```bash
flutter build appbundle --release
```

The AAB file will be at: `build/app/outputs/bundle/release/app-release.aab`

## Troubleshooting

### Error: "Keystore file not found"
- Check that the path in `key.properties` is correct
- Use absolute path if relative path doesn't work

### Error: "Wrong password"
- Verify the passwords in `key.properties` match your keystore
- Make sure there are no extra spaces or quotes

### Error: "Alias not found"
- Verify the alias name matches what you used when creating the keystore
- Default alias in this guide is "upload"

## Security Best Practices

1. **Backup your keystore**: Store it in a secure location (password manager, encrypted backup)
2. **Never commit keystore files**: They're in `.gitignore` but double-check
3. **Use strong passwords**: At least 16 characters, mix of letters, numbers, symbols
4. **Limit access**: Only developers who need to sign releases should have the keystore
5. **Document location**: Keep a secure record of where the keystore is stored (but not the passwords!)

## CI/CD Integration

For automated builds, you can:
1. Store keystore as a secure file in your CI/CD system
2. Store passwords as environment variables
3. Generate `key.properties` dynamically in the build script

Example for GitHub Actions:
```yaml
- name: Create key.properties
  run: |
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=upload" >> android/key.properties
    echo "storeFile=${{ github.workspace }}/upload-keystore.jks" >> android/key.properties
```
