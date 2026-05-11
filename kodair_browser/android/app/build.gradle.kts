plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = System.getenv("KODAIR_KEYSTORE_PATH")
val releaseKeystorePassword = System.getenv("KODAIR_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("KODAIR_KEY_ALIAS")
val releaseKeyPassword = System.getenv("KODAIR_KEY_PASSWORD")

android {
    namespace = "us.kodair.kodair_browser"
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
        applicationId = "us.kodair.kodair_browser"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val requiredEnv = listOf(
                releaseKeystorePath to "KODAIR_KEYSTORE_PATH",
                releaseKeystorePassword to "KODAIR_KEYSTORE_PASSWORD",
                releaseKeyAlias to "KODAIR_KEY_ALIAS",
                releaseKeyPassword to "KODAIR_KEY_PASSWORD",
            )
            requiredEnv.forEach { (value, name) ->
                check(!value.isNullOrBlank()) { "$name must be set for release signing" }
            }

            storeFile = file(checkNotNull(releaseKeystorePath))
            storePassword = checkNotNull(releaseKeystorePassword)
            keyAlias = checkNotNull(releaseKeyAlias)
            keyPassword = checkNotNull(releaseKeyPassword)
        }
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
