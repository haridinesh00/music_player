allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// ─── CONSOLIDATED SUBPROJECTS BLOCK ──────────────────────────
// ─── CONSOLIDATED SUBPROJECTS BLOCK ──────────────────────────
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        if (hasProperty("android")) {
            val androidExt = extensions.getByName("android")
            if (androidExt is com.android.build.gradle.BaseExtension) {
                // 1. The Namespace Fix
                if (androidExt.namespace == null) {
                    androidExt.namespace = group.toString()
                }
                
                // 2. Force Java to Version 17 across all plugins
                androidExt.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }

    // 3. Force Kotlin to Version 17 across all plugins
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions.jvmTarget = "17"
    }

    // 4. Evaluate the app (Must be the very LAST line in this block)
    project.evaluationDependsOn(":app")
}
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}