plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.ai.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Application ID configured for Firebase - matches google-services.json
        applicationId = "com.ai.app"
        // Android 10 (API 29) to Android 16 (API 36) support
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex for large apps
        multiDexEnabled = true
        
        // Vector drawable support
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            // Release signing configuration
            // For production: Create a keystore and configure signingConfigs block
            // See: https://developer.android.com/studio/publish/app-signing
            signingConfig = signingConfigs.getByName("debug")
            
            // Disable minification for compatibility (can enable after thorough testing)
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Uncomment after adding proper proguard rules
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

dependencies {
    // Firebase BOM - manages all Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    
    // Firebase dependencies (versions managed by BOM)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
