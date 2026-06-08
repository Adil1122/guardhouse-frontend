plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.security_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        @Suppress("DEPRECATION")
        jvmTarget = JavaVersion.VERSION_17.toString()
        freeCompilerArgs += "-Xlint:-options"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.security_app"
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

val flutterApkOutputDir = rootProject.projectDir.resolve("../build/app/outputs/flutter-apk")

tasks.register<Copy>("copyNamedDebugApkToFlutterOutput") {
    from(layout.buildDirectory.file("outputs/apk/debug/app-debug.apk"))
    into(flutterApkOutputDir)
    rename { "The Guard House-debug.apk" }
}

tasks.register<Copy>("copyNamedReleaseApkToFlutterOutput") {
    from(layout.buildDirectory.file("outputs/apk/release/app-release.apk"))
    into(flutterApkOutputDir)
    rename { "The Guard House-release.apk" }
}

tasks.configureEach {
    if (name == "assembleDebug") {
        finalizedBy("copyNamedDebugApkToFlutterOutput")
    }
    if (name == "assembleRelease") {
        finalizedBy("copyNamedReleaseApkToFlutterOutput")
    }
}

flutter {
    source = "../.."
}
