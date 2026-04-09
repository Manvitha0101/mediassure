plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mediassure"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion


compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}

kotlinOptions {
    jvmTarget = "1.8"
}

defaultConfig {
    applicationId = "com.example.mediassure"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}


}

dependencies {
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

implementation(platform("com.google.firebase:firebase-bom:34.11.0"))
implementation("com.google.firebase:firebase-analytics")


}

flutter {
source = "../.."
}
