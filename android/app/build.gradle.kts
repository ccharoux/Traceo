
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "com.ccharoux.traceo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    val keyPropertiesFile = rootProject.file("key.properties")
    val keyProperties = Properties() 
    if (keyPropertiesFile.exists()) {
        keyProperties.load(FileInputStream(keyPropertiesFile)) 
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ccharoux.traceo"
        // Force le support d'Android 7.0 (API 24) au minimum
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        
        // On récupère les valeurs depuis pubspec.yaml via l'objet flutter
        versionCode = flutter.versionCode

        versionName = "${flutter.versionName}(${flutter.versionCode})"

        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "x86_64")) // On retire armeabi-v7a et x86 (32 bits) si on veut être sûr
        }
        // Transmet la clé API de local.properties au Manifest
        manifestPlaceholders["MAPS_API_KEY"] = localProperties.getProperty("MAPS_API_KEY") ?: ""
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
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
