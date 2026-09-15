import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// -----------------------------------------------------------------------------
// Flutter version information
// -----------------------------------------------------------------------------

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")

if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.reader())
}

val flutterVersionCode =
    localProperties.getProperty("flutter.versionCode")

val flutterVersionName =
    localProperties.getProperty("flutter.versionName")

// -----------------------------------------------------------------------------
// Release signing
//
// Priority:
// 1. Environment variables - useful for CI
// 2. android/key.properties - useful for local builds
// -----------------------------------------------------------------------------

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")

if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

fun signingProperty(
    environmentName: String,
    propertyName: String,
): String? {
    return System.getenv(environmentName)
        ?.takeIf { it.isNotBlank() }
        ?: keyProperties.getProperty(propertyName)
            ?.takeIf { it.isNotBlank() }
}

val releaseStoreFile =
    signingProperty("STORE_FILE", "storeFile")

val releaseStorePassword =
    signingProperty("STORE_PASSWORD", "storePassword")

val releaseKeyAlias =
    signingProperty("KEY_ALIAS", "keyAlias")

val releaseKeyPassword =
    signingProperty("KEY_PASSWORD", "keyPassword")

val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

// -----------------------------------------------------------------------------
// Android configuration
// -----------------------------------------------------------------------------

android {
    namespace = "org.paperwise.app"

    compileSdk = 35

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    // -------------------------------------------------------------------------
    // Signing configurations
    // -------------------------------------------------------------------------

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword

                storeFile = releaseStoreFile?.let {
                    file(it)
                }

                storePassword = releaseStorePassword
            }
        }

        getByName("debug") {
            // Android's default debug keystore.
        }
    }

    // -------------------------------------------------------------------------
    // Java / Kotlin
    // -------------------------------------------------------------------------

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // -------------------------------------------------------------------------
    // Default configuration
    // -------------------------------------------------------------------------

    defaultConfig {
        applicationId = "org.paperwise.app"

        minSdk = flutter.minSdkVersion
        targetSdk = 35

        versionCode =
            (flutterVersionCode ?: "1").toInt()

        versionName =
            flutterVersionName ?: "1.0"
    }

    // -------------------------------------------------------------------------
    // Build types
    // -------------------------------------------------------------------------

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"

            signingConfig =
                signingConfigs.getByName("debug")
        }

        release {
            isMinifyEnabled = true
            isShrinkResources = true

            if (hasReleaseSigning) {
                signingConfig =
                    signingConfigs.getByName("release")

                println(
                    "✓ Release signing configured"
                )

                println(
                    "✓ Keystore: $releaseStoreFile"
                )
            } else {
                println(
                    "⚠ No release signing configuration found"
                )

                println(
                    "⚠ Release APK will be unsigned"
                )
            }
        }
    }
}

// -----------------------------------------------------------------------------
// Flutter
// -----------------------------------------------------------------------------

flutter {
    source = "../.."
}

// -----------------------------------------------------------------------------
// APK signing verification
// -----------------------------------------------------------------------------

tasks.register("verifySigning") {
    group = "verification"

    description =
        "Verify that release APKs were generated."

    doLast {
        val apkDirectory =
            file("build/outputs/flutter-apk")

        val apks = fileTree(apkDirectory) {
            include("**/*-release.apk")
        }

        if (apks.isEmpty) {
            println(
                "⚠ No release APKs found to verify"
            )
        } else {
            apks.forEach { apk ->
                println(
                    "📦 Release APK: ${apk.name}"
                )
            }
        }
    }
}

// -----------------------------------------------------------------------------
// Run verification after release builds
// -----------------------------------------------------------------------------

tasks.matching {
    it.name == "assembleRelease" ||
        it.name == "bundleRelease"
}.configureEach {
    finalizedBy("verifySigning")
}