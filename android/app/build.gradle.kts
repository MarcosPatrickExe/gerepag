import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val requiredSigningProperties = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword",
)
val hasReleaseSigning = requiredSigningProperties.all {
    !keystoreProperties[it]?.toString().isNullOrBlank()
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.marcos.gurgel.gerepag"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.marcos.gurgel.gerepag"
        
        minSdk = 24
        // Google Play exige Android 16 (API 36) para novos envios e atualizações.
        targetSdk = 36
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties["keyAlias"]?.toString()
            val keyPasswordProp = keystoreProperties["keyPassword"]?.toString()
            val storeFileProp = keystoreProperties["storeFile"]?.toString()
            val storePasswordProp = keystoreProperties["storePassword"]?.toString()

            if (hasReleaseSigning) {
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storeFile = rootProject.file(storeFileProp!!)
                storePassword = storePasswordProp
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any {
        it.path.startsWith(":app:") && it.name.contains("Release", ignoreCase = true)
    }
    if (releaseRequested && !hasReleaseSigning) {
        throw GradleException(
            "Assinatura release ausente. Configure android/key.properties e a upload keystore.",
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

configurations.all {
    resolutionStrategy {
        force("androidx.glance:glance-appwidget:1.1.0")
        force("androidx.glance:glance:1.1.0")
    }
}
