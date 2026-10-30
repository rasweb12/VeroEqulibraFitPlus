import java.io.FileInputStream
import java.util.Properties

val releaseKeyPropertiesFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties()
val hasReleaseSigning = releaseKeyPropertiesFile.isFile

if (hasReleaseSigning) {
    FileInputStream(releaseKeyPropertiesFile).use(releaseKeyProperties::load)
    val required = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    require(required.all { !releaseKeyProperties.getProperty(it).isNullOrBlank() }) {
        "android/key.properties deve conter storeFile, storePassword, keyAlias e keyPassword."
    }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.com.vero_equilibrafit.vero_equilibrafit_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.com.vero_equilibrafit.vero_equilibrafit_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(releaseKeyProperties.getProperty("storeFile"))
                storePassword = releaseKeyProperties.getProperty("storePassword")
                keyAlias = releaseKeyProperties.getProperty("keyAlias")
                keyPassword = releaseKeyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val requiresReleaseSigning = allTasks.any { task ->
        task.name.contains("Release", ignoreCase = true)
    }
    if (requiresReleaseSigning && !hasReleaseSigning) {
        throw GradleException(
            "A assinatura de release não foi configurada. Crie android/key.properties a partir de key.properties.example.",
        )
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
