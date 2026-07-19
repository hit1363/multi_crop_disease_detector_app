import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
    // Only redirect build directory for projects within the same drive/root to avoid "different roots" errors
    // for plugins located in the Pub cache on a different drive.
    if (project.projectDir.path.startsWith(rootProject.projectDir.path)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(
                if (project.name == "tflite_flutter") {
                    JvmTarget.JVM_11
                } else {
                    JvmTarget.JVM_17
                },
            )
        }
    }
}

/*
allprojects {
    plugins.withId("com.android.application") {
        extensions.getByType<com.android.build.gradle.BaseExtension>().externalNativeBuild {
            cmake {
                version = "3.22.1"
            }
        }
    }
    plugins.withId("com.android.library") {
        extensions.getByType<com.android.build.gradle.BaseExtension>().externalNativeBuild {
            cmake {
                version = "3.22.1"
            }
        }
    }
}
*/

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
