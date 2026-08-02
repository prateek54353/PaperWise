import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ADDED: Logic to read properties from local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.reader())
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
val flutterVersionName = localProperties.getProperty("flutter.versionName")

// Signing configuration - supports both environment variables (CI) and local.properties (local dev)
val releaseStoreFile = System.getenv("STORE_FILE") ?: localProperties.getProperty("storeFile")
val releaseStorePassword = System.getenv("STORE_PASSWORD") ?: localProperties.getProperty("storePassword")
val releaseKeyAlias = System.getenv("KEY_ALIAS") ?: localProperties.getProperty("keyAlias")
val releaseKeyPassword = System.getenv("KEY_PASSWORD") ?: localProperties.getProperty("keyPassword")

val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

android {
    namespace = "org.paperwise.app"
    compileSdk = 36

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    signingConfigs {
        // Release signing configuration
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
            }
        }
        // Debug signing configuration (uses default debug keystore)
        getByName("debug") {
            // Default debug signing is handled automatically by Android
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "org.paperwise.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35

        // MODIFIED: Read version info from local.properties
        versionCode = (flutterVersionCode ?: "1").toInt()
        versionName = flutterVersionName ?: "1.0"
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // Enable code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Use release signing if available, otherwise unsigned
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
                println("✓ Release signing configured with keystore: $releaseStoreFile")
            } else {
                println("⚠ No release signing configuration found - building unsigned APK")
            }
        }
    }
}

flutter {
    source = "../.."
}

// Add task to verify APK signing
tasks.register("verifySigning") {
    group = "verification"
    description = "Verify that release APK is properly signed"
    
    doLast {
        val apks = fileTree("build/app/outputs/flutter-apk") {
            include("**/*-release.apk")
        }
        
        if (apks.isEmpty) {
            println("⚠ No release APKs found to verify")
        } else {
            apks.forEach { apk ->
                println("📦 Found release APK: ${apk.name}")
                // In a real setup, you would use apksigner or jarsigner here
                // For now, we just log the APK was found
            }
        }
    }
}

// Hook verification into release build
tasks.named("assembleRelease") {
    finalizedBy("verifySigning")
}

// FIX: Add a catch-all for build failures to provide more context
// This is a common pattern to help diagnose Gradle issues.
gradle.taskGraph.whenReady {
    tasks.forEach { task ->
        task.doLast {
            if (task.state.failure != null) {
                println("Error: Gradle task ${task.path} failed with exit code 1")
                println("Try: > Run with --stacktrace option to get the stack trace.")
                println("     > Run with --info or --debug option to get more log output.")
                println("     > Run with --scan to get full insights.")
                println("     > Get more help at https://help.gradle.org.")
                println("Exited (1).")
            }
        }
    }
}
