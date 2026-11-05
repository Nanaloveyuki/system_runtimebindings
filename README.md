# System Runtime Bindings

MoonBit bindings for selected mobile runtime capabilities. Android provides structured system logging and the device API level through [AJNI](https://github.com/Nanaloveyuki/ajni). The [HarmonyOS module](ohos_runtimebinding/README.md) provides structured HiLog output through [MoonOHOS](https://github.com/shop1111/MoonOHOS). Both use [BitLogger](https://github.com/Nanaloveyuki/BitLogger) records.

## Android requirements

- Android host initialized with AJNI before calling this package.
- MoonBit native target and Android NDK configured by the host application.
- MoonBit `0.10.19+97801ee1b` (`moon` CLI `0.1.20261029`).

## Use Android from this checkout

The workspace resolves BitLogger 0.11.1 (including `Logger::log_with`) and AJNI 0.3.6 from Mooncakes. No adjacent dependency checkouts are required:

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

Create the sink after AJNI initializes, on its owner thread. `AndroidSink::new` raises `AndroidLogError` if initialization fails. `AndroidSink::write` also raises `AndroidLogError`, retaining the original AJNI failure for callers. BitLogger owns levels, filtering, targets, and fields. Its `Trace` level maps to Android `Verbose`; the other levels map directly.

```moonbit
let logger = @logger.Logger::new(@log.AndroidSink::new(), target="Index")
let result = logger.log_with(@logger.Level::Info, "Index built", (sink, record) => {
  try {
    @log.AndroidSink::write(sink, record)
    Ok(())
  } catch {
    error => Err(error)
  }
})
```

Handle `result` at the application boundary. Reuse the sink only while its AJNI session remains open and on that session's owner thread.

Import `Nanaloveyuki/android_runtimebinding/device_info` and call `@device_info.sdk_level()` from a function that raises AJNI `RuntimeError` to read the running device's major API level. This is independent of the application's target SDK, requires an initialized AJNI session on its owner thread, and requests no permissions. Unsupported platforms raise `UnsupportedTarget`; uninitialized Android hosts raise `NotInitialized`.

View the structured records with `adb logcat -s RuntimeBinding:V`. Each message is a BitLogger JSON record, including its target and fields.


## Run the Android example

Install Android SDK Platform 36, Build Tools 36.0.0, NDK 29.0.14206865, and CMake 3.22.1. Set `ANDROID_HOME` to the SDK and `MOON_HOME` to your MoonBit installation. Java 17 or newer is required.

From the repository root:

```bash
examples/android/gradlew -p examples/android :app:assembleDebug
python3 scripts/run-android-smoke.py --serial emulator-5554
```

The example defaults to x86_64. For an ARM64 device, build with `-PandroidAbi=arm64-v8a` and pass its ADB serial to the smoke command. Use `--adb /path/to/adb` if ADB is not on PATH; WSL can use Windows `adb.exe` with the same option.

The smoke command installs the APK and launches it twice, checking application Context acquisition, logging priorities, Unicode, fields, target overrides, filtering, and rejection before host initialization. The example requires no runtime permissions. Use `--adb-port 5038` if your ADB server uses that port.

## Implementation

The Android adapter sends BitLogger records to `android.util.Log.println` through AJNI's checked JNI runtime and requires a live session on its owner thread. The HarmonyOS adapter sends records through MoonOHOS's public HiLog interface; MoonOHOS supplies Node-API bridging and HAR packaging. See the [HarmonyOS example](examples/ohos/README.md) for building and running it.

## Suitability

Use this package from MoonBit native code embedded in an Android application that integrates AJNI. The included application demonstrates host setup and logging; application UI, permissions, and other system capabilities remain the application's responsibility.

## Publish the HarmonyOS module

`ohos_runtimebinding` sits inside this module's directory and is excluded from the Android package. Publish it through the staging helper, which copies it outside the parent `.moonignore` scope:

```bash
python3 scripts/publish-ohos-module.py --dry-run
python3 scripts/publish-ohos-module.py
```

Both packages are on Mooncakes: `Nanaloveyuki/android_runtimebinding` (0.2.0) and `Nanaloveyuki/ohos_runtimebinding` (0.1.0).
