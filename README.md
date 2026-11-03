# Android Runtime Binding

MoonBit bindings for selected Android runtime capabilities, built on [AJNI](https://github.com/Nanaloveyuki/ajni). The current checkout provides structured Android system logging using [BitLogger](https://github.com/Nanaloveyuki/BitLogger).

## Requirements

- Android host initialized with AJNI before calling this package.
- MoonBit native target and Android NDK configured by the host application.
- MoonBit `0.10.19+97801ee1b` (`moon` CLI `0.1.20261029`).

## Use from this checkout

The current integration requires the matching BitLogger checkout at `../BitLogger`, including `Logger::log_with`. This API is not available in the published BitLogger 0.9.2 package. The workspace uses the local module while AJNI resolves to published version 0.3.6:

```bash
moon update
moon check --target native
```

Add the package import in the consuming `moon.pkg`:

```moonbit
import {
  "Nanaloveyuki/BitLogger/src" @logger,
  "Nanaloveyuki/android_runtimebinding/log",
}
```

Create the sink after AJNI initializes, on its owner thread, from an error-raising function:

```moonbit
let logger = @logger.Logger::new(@log.AndroidSink::new(), target="Index")
match logger.log_with(
  @logger.Level::Info,
  "Index built",
  @log.AndroidSink::write,
  fields=[@logger.field("resource_count", "12")],
) {
  Ok(_) => ()
  Err(@log.Runtime(error)) => raise error
}
```

`AndroidSink::new` raises `AndroidLogError` if initialization fails. Writes return `Result[Unit, AndroidLogError]`; applications choose how to handle the retained AJNI `RuntimeError`. Reuse the sink only while its AJNI session remains open and on that session's owner thread. BitLogger owns levels, filtering, targets, and fields. Its `Trace` level maps to Android `Verbose`; the other levels map directly.

View the structured records with `adb logcat -s RuntimeBinding:V`. Each message is a BitLogger JSON record, including its target and fields.

## Run the Android example

Install Android SDK Platform 36, Build Tools 36.0.0, NDK 29.0.14206865, and CMake 3.22.1. Set `ANDROID_HOME` to the SDK and `MOON_HOME` to your MoonBit installation. Java 17 or newer is required.

From the repository root:

```bash
examples/android/gradlew -p examples/android :app:assembleDebug
python3 scripts/run-android-smoke.py --serial emulator-5554
```

The example defaults to x86_64. For an ARM64 device, build with `-PandroidAbi=arm64-v8a` and pass its ADB serial to the smoke command. Use `--adb /path/to/adb` if ADB is not on PATH; WSL can use Windows `adb.exe` with the same option.

The smoke command installs the APK and launches it twice, checking application Context acquisition through `getPackageName()`, five logging priorities, Unicode, fields, target overrides, filtering, and rejection before host initialization. The example requires no runtime permissions. Use `--adb-port 5038` if your ADB server uses that port.

## Implementation

The Android adapter sends BitLogger records to the public `android.util.Log.println` API through AJNI's checked JNI runtime. It requires a live AJNI session on its owner thread. AJNI owns host initialization and JNI primitives; runtimebinding owns Android capability adaptation. HarmonyOS integration follows Android MVP validation and will use MoonOHOS's published platform APIs.

## Suitability

Use this package from MoonBit native code embedded in an Android application that integrates AJNI. The included application demonstrates host setup and logging; application UI, permissions, and other system capabilities remain the application's responsibility.
