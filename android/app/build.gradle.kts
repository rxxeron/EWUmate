plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.rxxeron.ewumate"
    compileSdk = 35 // FIXED: Set to Stable Android 15 (was 36)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.rxxeron.ewumate"
        minSdk = 21  // CRITICAL: Keeps Android 10 support active
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Ensures the APK is signed with the default Android debug key
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
        }
        release {
            // We are using debug keys here too, just in case you run release by accident
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

configurations.all {
    resolutionStrategy {
        force("androidx.activity:activity:1.9.0")
    }
}
