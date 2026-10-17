import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.fieldexpensemanager.field_expense_manager"
    // Android 17 is published as SDK platform "android-37.0" (minor API level 0).
    compileSdk {
        version = release(37) {
            minorApiLevel = 0
        }
    }
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    defaultConfig {
        applicationId = "com.fieldexpensemanager.field_expense_manager"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Expenza"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val storeFilePath = keystoreProperties["storeFile"] as? String
                if (storeFilePath != null && file(storeFilePath).exists()) {
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                    storeFile = file(storeFilePath)
                    storePassword = keystoreProperties["storePassword"] as String
                }
            }
        }
    }

    buildTypes {
        // Debug builds install next to the real app instead of replacing it,
        // so testing never touches real expense data.
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "Expenza Debug"
        }
        release {
            val releaseConfig = signingConfigs.findByName("release")
            val hasReleaseKey = releaseConfig?.storeFile?.exists() == true
            // Never ship a release APK signed with a debug key: Android refuses
            // to install it as an update over a properly signed app (this is how
            // v1.2.0 ended up debug-signed). Fail release builds instead.
            val buildingRelease = gradle.startParameter.taskNames.any {
                it.contains("Release", ignoreCase = true)
            }
            if (buildingRelease && !hasReleaseKey) {
                throw GradleException(
                    "Release signing key not found. Set storeFile in android/key.properties " +
                        "to your expenza-keystore.jks before building a release."
                )
            }
            signingConfig = if (hasReleaseKey) {
                releaseConfig
            } else {
                signingConfigs.getByName("debug") // only reached for non-release tasks
            }
            isMinifyEnabled = false // Set to true after adding ProGuard rules
            isShrinkResources = false // Set to true when minifyEnabled is true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
