//
//  build.gradle.kts
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Swift native libraries are built into build/, never committed.
val swiftJniLibs = layout.buildDirectory.dir("swift/jniLibs")

android {
    namespace = "com.eventpush.android"
    compileSdk = 35
    // Must match the NDK used by the Swift SDK setup (scripts/build-swift.sh).
    ndkVersion = "30.0.16248370"

    defaultConfig {
        applicationId = "com.eventpush.android"
        minSdk = 28 // = ANDROID_API in scripts/build-swift.sh
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        ndk { abiFilters += listOf("arm64-v8a") } // add "x86_64" + ABIS for Intel emulators
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug") // demo only
        }
    }

    sourceSets["main"].apply {
        jniLibs.srcDir(swiftJniLibs)
        // Same fixture as the iOS app: one source of truth.
        assets.srcDir("../../Modules/Sources/Data/DataLayer/Resources/Fixtures")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
}

// Cross-compile Swift before Android merges native libraries.
val buildSwift by tasks.registering(Exec::class) {
    group = "build"
    description = "Builds SwiftCore for Android (scripts/build-swift.sh)"
    workingDir = rootDir
    commandLine("bash", "scripts/build-swift.sh", swiftJniLibs.get().asFile.absolutePath)
    inputs.dir(rootDir.resolve("SwiftCore/Sources"))
    inputs.file(rootDir.resolve("SwiftCore/Package.swift"))
    outputs.dir(swiftJniLibs)
}
tasks.named("preBuild") { dependsOn(buildSwift) }

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.08.00")
    implementation(composeBom)
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.compose.ui:ui-tooling-preview")
}
