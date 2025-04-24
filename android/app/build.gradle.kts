// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Apply Flutter plugin after Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

// Apply Google Services plugin from classpath
apply(plugin = "com.google.gms.google-services")

android {
    namespace = "com.example.hacktrack"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.hacktrack"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // if needed for Firebase :contentReference[oaicite:7]{index=7}
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Use Firebase BoM for version management
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))

    // Firebase libraries (no explicit versions)
    implementation("com.google.firebase:firebase-analytics")
    // ... other Firebase dependencies
}
