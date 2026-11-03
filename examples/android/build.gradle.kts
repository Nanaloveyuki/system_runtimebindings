import com.android.build.gradle.LibraryExtension

plugins {
  id("com.android.application") version "8.10.1" apply false
  id("com.android.library") version "8.10.1" apply false
  id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

project(":host") {
  layout.buildDirectory.set(rootProject.layout.buildDirectory.dir("host"))
  afterEvaluate {
    extensions.configure<LibraryExtension> {
      compileSdk = 36
      buildToolsVersion = "36.0.0"
      defaultConfig.minSdk = 28
    }
  }
}
