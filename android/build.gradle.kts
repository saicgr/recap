allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// AGP 8 enforces JVM-target consistency between Java + Kotlin compile tasks
// in the same module. Older Flutter plugins (device_calendar,
// receive_sharing_intent, file_picker, …) pin Java to 1.8 in their own
// build.gradle. We hook `gradle.beforeProject` so we set defaults BEFORE
// each subproject's own build.gradle has a chance to set its own Java
// compatibility. Then we hook `gradle.afterProject` to retroactively raise
// any Java tasks that still landed on 1.8.
gradle.beforeProject {
    extensions.findByType(JavaPluginExtension::class.java)?.apply {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
gradle.afterProject {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
    // Force Android plugin's compileOptions DSL on every Android library
    // subproject. Some plugins (device_calendar, audio_session) set
    // sourceCompatibility=1.8 here, which AGP-8 then mirrors into the
    // JavaCompile task even if we set it on the task above. This block
    // catches those plugins by walking the LibraryExtension after their
    // own build.gradle has run.
    plugins.withId("com.android.library") {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            ?.compileOptions?.apply {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
