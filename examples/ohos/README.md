# HarmonyOS logging example

A MoonOHOS-generated ArkTS host calling the runtimebinding HiLog adapter. The page writes eight BitLogger records on appearance and when **Write logs again** is pressed.

## Build from WSL

Use MoonBit `1.0.0-rc1+3c0520448`, Python 3, Linux CMake and Ninja, PowerShell 7, and Windows DevEco Studio with API 26 native SDK, Node, OHPM and Hvigor. The MoonOHOS 0.9.0 CLI declares `moonbitlang/async@0.21.0`, which fails to compile with RC1. Build the published source with `0.22.10` in a temporary directory. [MoonOHOS 0.9.0 on Mooncakes](https://mooncakes.io/docs/shop1111/moonohos@0.9.0)

```bash
moonohos_stage="$(mktemp -d)"
(
  set -e
  cd "$moonohos_stage"
  moon fetch shop1111/moonohos@0.9.0
  cd .repos/shop1111/moonohos/0.9.0
  moon add --upgrade moonbitlang/async@0.22.10
  moon install ./cmd/moonohos --bin "$moonohos_stage/bin"
)
export PATH="$moonohos_stage/bin:$PATH"
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

The smoke command installs the HAP and starts the application twice, validating HiLog priorities, Unicode, structured fields, targets, and filtering. Both launches passed on the API 26 x86_64 simulator with the RC1 build. Device distribution requires an appropriate signing configuration.

The page displays **Logging example completed**. Read output with `hdc -t TARGET shell hilog -x -t app -T RuntimeBinding`. A HAR consumer imports `native` from `@nanaloveyuki/runtimebinding` and calls `native.run_logging()`.

The example constructs records with BitLogger's `core` package, which supplies the record types and severity threshold check. The root `src` package also brings in file I/O C stubs that require a MoonOHOS native dependency descriptor.
