import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadKeyProperties(): Properties {
    val properties = Properties()
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) {
        properties.load(propertiesFile.inputStream())
    }
    return properties
}

// ADDED: Logic to read properties from local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.reader())
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
val flutterVersionName = localProperties.getProperty("flutter.versionName")

android {
    namespace = "org.paperwise.app"
    compileSdk = flutter.compileSdkVersion

    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }

    signingConfigs {
        create("release") {
            val keyProperties = loadKeyProperties()
            keyAlias = keyProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            keyPassword = keyProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            storeFile = file(keyProperties.getProperty("storeFile") ?: System.getenv("STORE_FILE"))
            storePassword = keyProperties.getProperty("storePassword") ?: System.getenv("STORE_PASSWORD")
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
        targetSdk = flutter.targetSdkVersion

        // MODIFIED: Read version info from local.properties
        versionCode = (flutterVersionCode ?: "1").toInt()
        versionName = flutterVersionName ?: "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
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