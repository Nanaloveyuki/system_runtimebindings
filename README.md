# Android Runtime Binding

MoonBit bindings for selected Android runtime capabilities, built on [AJNI](https://github.com/Nanaloveyuki/ajni). Version 0.1.1 provides Android system logging through `android.util.Log` with MoonBit 0.10.19.

## Requirements

- Android host initialized with AJNI before calling this package.
- MoonBit native target and Android NDK configured by the host application.
- MoonBit `0.10.19+97801ee1b` (`moon` CLI `0.1.20261029`).

## Use from this checkout

Resolve the published AJNI dependency from the repository root:

```bash
moon update
moon check --target native
```

Add the package import in the consuming `moon.pkg`:

```moonbit
import {
  "Nanaloveyuki/android_runtimebinding/log",
}
```

Call it after the AJNI host initializes, on its owner thread, from an error-raising function:

```moonbit
let logger = @log.Logger::new("Index")
logger.log(@log.Level::Info, "Index built")
```

`Logger::new` binds a tag and the current AJNI session; reuse the logger for subsequent writes. `Logger::log` raises AJNI's `RuntimeError` if the JNI session is unavailable, belongs to another thread, or the Java call fails. Use Android logcat to view the message. Supported priorities are `Verbose`, `Debug`, `Info`, `Warn`, and `Error`.

## Run the Android example

Install Android SDK Platform 36, Build Tools 36.0.0, NDK 29.0.14206865, and CMake 3.22.1. Set `ANDROID_HOME` to the SDK and `MOON_HOME` to your MoonBit installation. Java 17 or newer is required.

From the repository root:

```bash
examples/android/gradlew -p examples/android :app:assembleDebug
python3 scripts/run-android-smoke.py --serial emulator-5554
```

The example defaults to x86_64. For an ARM64 device, build with `-PandroidAbi=arm64-v8a` and pass its ADB serial to the smoke command. Use `--adb /path/to/adb` if ADB is not on PATH; WSL can use Windows `adb.exe` with the same option.

The smoke command installs the APK and launches it twice, checking five priorities, a Unicode message, and rejection before host initialization in logcat. The example requires no runtime permissions.

## Implementation

The Android adapter calls the public `android.util.Log.println` API through AJNI's checked JNI runtime. It requires a live AJNI session on its owner thread. This package does not initialize the Android host or manage UI, permissions, or application resources.

## Suitability

Use this package from MoonBit native code embedded in an Android application that integrates AJNI. The included application demonstrates host setup and logging; application UI, permissions, and other system capabilities remain the application's responsibility.
