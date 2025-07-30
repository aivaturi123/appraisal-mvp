// ✅ Force Java version for Gradle (before evaluation)
gradle.settingsEvaluated {
    println("Overriding java.home to: C:\\Users\\nancy\\Downloads\\Android\\Android Studio1\\jbr")
    System.setProperty("java.home", "C:\\Users\\nancy\\Downloads\\Android\\Android Studio1\\jbr")
}

// ✅ Repositories used in all modules
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Optional: shared build directory setup
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// ✅ Make
