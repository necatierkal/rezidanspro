import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val localKeyPropertiesFile = project.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else if (localKeyPropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(localKeyPropertiesFile))
}

android {
    namespace = "com.rezidanspro.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.rezidanspro.app"
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val keyFile = project.file("rezidanspro-release-key.jks")
            if (keyFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: "rezidanspro"
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: "300516"
                storeFile = keyFile
                storePassword = keystoreProperties.getProperty("storePassword") ?: "300516"
            }
        }
    }

    buildTypes {
        release {
            val keyFile = project.file("rezidanspro-release-key.jks")
            if (keyFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
