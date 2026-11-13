# HarmonyOS logging example

A MoonOHOS-generated ArkTS host calling the runtimebinding HiLog adapter. The page writes eight BitLogger records on appearance and when **Write logs again** is pressed.

## Build from WSL

Requirements: MoonBit `0.10.20+65efd5b93`, Python 3, Linux CMake/Ninja on PATH, PowerShell 7, and Windows DevEco Studio with API 26 native SDK, Node, OHPM and Hvigor installed. Install the published CLI:

```bash
moon install shop1111/moonohos/cmd/moonohos
```

From the repository root, substitute your mounted Windows paths:

```bash
python3 scripts/build-ohos-wsl.py \
  --deveco '/mnt/e/Apps/DevEco Studio' \
  --windows-temp /mnt/e/tmp \
  --powershell '/mnt/c/Program Files/PowerShell/7/pwsh.exe'
```

The command builds only `x86_64`, using the SDK's Windows compiler. It writes `runtimebinding.har` and `entry-default-unsigned.hap` under `examples/ohos/_build/artifacts/`; temporary host tools and Hvigor staging are removed automatically. Upstream compatibility constraints are recorded in [ADR 0005](../../docs/adr/0005-harmonyos-logging-and-build.md).

## Run on the simulator

```bash
python3 scripts/run-ohos-smoke.py \
  --hdc '/mnt/e/Apps/DevEco Studio/sdk/default/openharmony/toolchains/hdc.exe' \
  --target 127.0.0.1:5555
```

The smoke command installs the HAP and starts the application twice, validating real HiLog priorities, Unicode, structured fields and targets. Unsigned debug installation was accepted by the HOS 7.0 / API 26 x86_64 simulator; ordinary device distribution requires an appropriate signing configuration.

The page displays **Logging example completed**. Read output with `hdc -t TARGET shell hilog -x -t app -T RuntimeBinding`. A HAR consumer imports `native` from `@nanaloveyuki/runtimebinding` and calls `native.run_logging()`.

The example submits records through BitLogger's pure packages. Full root-package `Logger` integration and its filtering are not claimed: that package currently introduces host async native dependencies rejected by MoonOHOS.
