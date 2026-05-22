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
    
    val fixNamespace = Action<Project> {
        if (plugins.hasPlugin("com.android.library")) {
            val android = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
            android.compileSdk = 34
            if (android.namespace == null || android.namespace!!.isEmpty()) {
                android.namespace = group.toString().ifEmpty { "com.g123k.deviceapps" }
            }
        }
    }

    if (project.state.executed) {
        fixNamespace.execute(project)
    } else {
        project.afterEvaluate(fixNamespace)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
