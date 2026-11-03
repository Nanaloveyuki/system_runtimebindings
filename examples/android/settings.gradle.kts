pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
}

dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
  }
}

rootProject.name = "runtimebinding-android-demo"
include(":app", ":host")
project(":host").projectDir = file("../../.mooncakes/Nanaloveyuki/ajni/android/host")
