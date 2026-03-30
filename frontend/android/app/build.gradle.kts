plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
<<<<<<< HEAD
    namespace = "com.example.livraison_app"
=======
    namespace = "com.example.app"
>>>>>>> 2c954af644ce501c3327eead63251d683235d428
=======
    namespace = "com.example.livraison_app"
>>>>>>> 7e0a92e041c00011f8d92c59b57c578cab4aff29
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
<<<<<<< HEAD
<<<<<<< HEAD
        applicationId = "com.example.livraison_app"
=======
        applicationId = "com.example.app"
>>>>>>> 2c954af644ce501c3327eead63251d683235d428
=======
        applicationId = "com.example.livraison_app"
>>>>>>> 7e0a92e041c00011f8d92c59b57c578cab4aff29
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
