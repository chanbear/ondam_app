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

// camera_android_camerax pins androidx.camera:camera-core:1.6.1, whose
// SurfaceRequest class carries a jspecify @NonNull type annotation on
// CallbackToFutureAdapter — but camera-core's own POM doesn't declare that
// class as a compile dependency, so consumers must add it themselves or
// :camera_android_camerax:compileDebugJavaWithJavac fails with "class file
// for androidx.concurrent.futures.CallbackToFutureAdapter not found".
gradle.projectsEvaluated {
    project(":camera_android_camerax").dependencies.add(
        "implementation",
        "androidx.concurrent:concurrent-futures:1.2.0",
    )
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
