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

// Workaround: file_picker 11.0.2's own android/build.gradle skips applying
// the classic `kotlin-android` plugin (and setting its Kotlin compile
// tasks' jvmTarget) whenever AGP is major version 9+, assuming AGP's new
// Built-in Kotlin support will compile its .kt sources instead. This
// project has that feature explicitly disabled
// (`android.builtInKotlin=false` in gradle.properties), so nothing ends up
// compiling FilePickerPlugin.kt at all, and :app fails with "cannot find
// symbol FilePickerPlugin" in the Flutter-generated plugin registrant.
// See agp9_file_picker_workaround.gradle for the jvmTarget half of the fix
// (a plain Groovy script, not Kotlin DSL, so it can configure
// file_picker's `kotlinOptions {}` dynamically without a static Kotlin
// Gradle Plugin dependency here) — remove both once file_picker ships a
// real Built-in-Kotlin-aware fix.
subprojects {
    if (project.name == "file_picker") {
        pluginManager.apply("org.jetbrains.kotlin.android")
        // file_picker's own build.gradle (which creates the `android {}`
        // extension the workaround script configures) hasn't run yet at
        // this point in evaluation order, so defer until it has.
        afterEvaluate {
            apply(from = "$rootDir/agp9_file_picker_workaround.gradle")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
