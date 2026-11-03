import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "dev.nanaloveyuki.runtimebinding.demo"
  compileSdk = 36
  buildToolsVersion = "36.0.0"
  ndkVersion = "29.0.14206865"
  providers.environmentVariable("ANDROID_NDK_HOME").orNull?.let { ndkPath = it }

  defaultConfig {
    applicationId = "dev.nanaloveyuki.runtimebinding.demo"
    minSdk = 28
    targetSdk = 36
    versionCode = 1
    versionName = "0.1.1"
    ndk {
      abiFilters += providers.gradleProperty("androidAbi").getOrElse("x86_64")
    }
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  externalNativeBuild {
    cmake {
      path = file("src/main/cpp/CMakeLists.txt")
      version = "3.22.1"
    }
  }
}

kotlin {
  compilerOptions {
    jvmTarget.set(JvmTarget.JVM_17)
  }
}

dependencies {
  implementation(project(":host"))
}
