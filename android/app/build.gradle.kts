plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // id("com.google.gms.google-services") // Temporarily disabled for local APK build
}

android {
    namespace = "com.rxxeron.ewumate"
    compileSdk = 36 // REQUIRED: Upgraded to 36 to satisfy flutter plugins

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
        minSdk = flutter.minSdkVersion  // CRITICAL: Keeps Android 10 support active
        targetSdk = 36
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
