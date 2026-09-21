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
subprojects {
    if (project.name != "app") {
        project.afterEvaluate {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(androidExt, 36)
                } catch (e: Exception) {
                    try { androidExt.javaClass.getMethod("setCompileSdk", Int::class.java).invoke(androidExt, 36) } catch (e2: Exception) {}
                }
                try {
                    val compileOptions = androidExt.javaClass.getMethod("getCompileOptions").invoke(androidExt)
                    compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
                    compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
                } catch (e: Exception) {}
            }
            tasks.withType<JavaCompile>().configureEach {
                sourceCompatibility = "17"
                targetCompatibility = "17"
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                try {
                    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                } catch (e: Exception) {}
            }
        }
    }
    configurations.all {
        resolutionStrategy {
            force("androidx.compose.remote:remote-creation-android:1.0.0-alpha06")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
