plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.recapfreenote.recap"
    compileSdk = flutter.compileSdkVersion
    // whisper_ggml needs 29.0+; everything else is fine with that (backward compatible).
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications for Java 8 APIs on older Android.
        isCoreLibraryDesugaringEnabled = true
    }

    // kotlinOptions { } was removed in Kotlin Gradle Plugin 2.x. Use the
    // compilerOptions DSL. The global subprojects {} block in
    // ../build.gradle.kts covers third-party plugins; this block covers the
    // app module.
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.recapfreenote.recap"
        // record + whisper_ggml + flutter_gemma all need >= 24.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // `sherpa_onnx` and `flutter_onnxruntime` both ship their own copies of
    // `libonnxruntime.so`. They're API-compatible at runtime; we just pick
    // whichever the build sees first and let the merger drop duplicates.
    // Identical concern for libc++_shared.so (any plugin that bundles its
    // own NDK toolchain version of it).
    packaging {
        jniLibs {
            pickFirsts.add("lib/**/libonnxruntime.so")
            pickFirsts.add("lib/**/libc++_shared.so")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// `whisper_ggml` (Android plugin) pulls `com.antonkarpenko:ffmpeg-kit-min`
// from its own FFmpegKit re-publish, AND `ffmpeg_kit_flutter_new` pulls
// `com.antonkarpenko:ffmpeg-kit-full-gpl`. Both ship `com.antonkarpenko.
// ffmpegkit.*` classes → AGP detects duplicates and refuses to build.
//
// We keep the full-gpl variant (it's a superset; transcoding needs codecs
// the -min build doesn't include) and exclude -min from whisper_ggml's
// transitive graph. whisper_ggml uses FFmpegKit only for audio resampling
// during preprocessing — the same APIs exist in full-gpl.
configurations.all {
    exclude(group = "com.antonkarpenko", module = "ffmpeg-kit-min")
}

flutter {
    source = "../.."
}
