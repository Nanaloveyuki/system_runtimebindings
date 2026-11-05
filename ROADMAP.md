# Runtime Bindings Roadmap

Internal delivery plan for `system_runtimebindings`. The README remains user-facing; this file tracks sequencing, ownership, and acceptance. Platform plans beyond the Android MVP are conditional, not delivery commitments.

## Current Snapshot

- The BitLogger integration passes the Android install/launch/logcat smoke on API 37 x86_64 across two cold launches: Context identity, priorities, Unicode, targets, fields, filtering, and pre-initialization rejection.
- The current package exposes `AndroidSink`, `AndroidLogError`, and `device_info.sdk_level()`. BitLogger owns the logger, levels, filtering, and records; the standalone runtimebinding `Logger` and `Level` APIs have been removed.
- Sink construction and writes raise `AndroidLogError`, retaining the original AJNI failure. BitLogger's `Logger::log_with` accepts a local closure that converts that failure into `Result`. Records use BitLogger JSON formatting; warning suppression is unnecessary.
- AJNI resolves to published 0.3.6 and BitLogger to published 0.10.0, including `Logger::log_with`. Neither requires a local dependency checkout. The Android example exercises `android.application_context()` against the real host and calls `Context.getPackageName()` before closing the independently owned handle.
- Published-dependency migration verified: native/JS strict checks and unsupported-target tests pass, Android logging passes two install/launch/logcat runs, and Orbit Memo's React WebView SDK-value instrumentation passes on API 37 x86_64. Orbit's build helper no longer includes a local BitLogger checkout; its temporary workspace is removed on exit.
- Native checking and Android install/launch/logcat smoke remain the Android verification gates. HarmonyOS structured logging now passes API 26 x86_64 simulator verification; scope and upstream constraints are recorded in Stage 3.

## Stage 1: Android MVP

Goal: deliver a usable Android logging backend for the existing BitLogger library with a reproducible real-platform path.

1. Complete AJNI host-helper packaging upstream; update this repository to the compatible AJNI release and remove the executable-package dependency from the demo.
2. Keep Android write failures observable: `AndroidSink::write` raises `AndroidLogError`, and the caller converts errors to `Result` inside the `Logger::log_with` writer closure. The non-raising BitLogger `Sink` trait remains unchanged.
3. Preserve structured record semantics: map BitLogger Trace to Android Verbose and retain target, message, fields, and optional timestamp in the JSON record. Keep AJNI session and owner-thread constraints explicit.
4. Keep the example and README aligned with the selected BitLogger integration. The standalone runtimebinding logger has been removed.
5. Run workspace checks and the Android install/launch/logcat smoke against updated dependencies. The smoke checks priorities, Unicode, targets, fields, filtering, and pre-initialization rejection across two launches.
6. Review public module/package layout and generated interfaces. Publish only independently useful, stable modules; do not create or publish a shared facade solely to satisfy a planned module count.

Exit gate: the logging integration has an explicit, observable write-failure contract; it builds against published AJNI and BitLogger releases without depending on an AJNI executable package; host contract checks and real Android smoke pass; a consumer can configure BitLogger to emit to Android logcat; license and release metadata are ready.

## Stage 2: Android capability selection

The validated logging path is sufficient to begin binding preparation. Required AJNI and BitLogger APIs are published; dependency migrations must pass the Android verification gates. Keep platform work Android-first and select one capability at a time.

### Reference and compatibility preparation

For Android version changes, consult [platform versions](docs/agents/android-platform-versions.md). For API signatures, permissions, and capability-specific constraints, consult [capability references](docs/agents/android-capability-reference.md). These notes index official sources and record review dates; refresh the affected section when selecting or changing an API rather than mirroring the full Android documentation tree.

Keep the demo's current `minSdk=28`, `compileSdk=36`, and `targetSdk=36` during preparation. These are engineering inputs, not proof of API 28–36 compatibility. For every bound symbol, record its Java/JNI signature, introduction/deprecation version, permission requirements, device-API guard, target-dependent behavior, thread/session requirements, ownership/close behavior, and observable error. Consult reference documentation and behavior-change pages together; SDK `api-versions.xml` verifies symbol availability only.

For each selected binding, keep a small source record in its capability note: canonical Android URL, review date, SDK platform/revision used for signature checks, and any AOSP release tag used to resolve ambiguity. Prefer public SDK references; use tagged AOSP source only where a documented contract is insufficient. Refresh only the affected entries after an SDK/target upgrade. Keep copied platform documentation and generated SDK metadata in the local SDK/cache rather than committing them here.

Validate on the baseline API, the target API, and any capability-specific behavior thresholds before advertising that range. Keep the existing API 37 smoke as forward-runtime evidence for logging only. Record the device's build/preview identity when testing newer systems; installed SDK/emulator metadata alone does not establish release status.

### Next implementation slices

| Order | Slice | Prerequisite and acceptance |
|---|---|---|
| 1 | Device runtime version | Implemented as `device_info.sdk_level()` using published AJNI static-field access. Orbit Memo's Android `memo.runtime` consumes the result; its frontend accepts desktop responses without `sdkLevel` and validates a supplied value as a positive integer. Native/JS unsupported-target tests pass. API 37 x86_64 instrumentation passes: the mounted React app completes an IPC round trip and returns the same SDK integer as Kotlin's `Build.VERSION.SDK_INT`. |
| 2 | Packaged asset binary reads | AJNI 0.3.6 provides the public application-Context contract. Next prove binary reads and stream cleanup; establish off-main host execution and owner-thread completion before exposing general blocking reads. Verify exact bytes, empty files, Unicode names, missing assets and repeated reads. Keep text decoding a caller choice. |
| Later | Vibration, network state, permission requests | Select from a concrete consumer need; use the cited API thresholds and capability-specific permission/callback/lifecycle contracts before committing an interface. |

AJNI 0.3.6 exposes `android.application_context()` for the initialized host's normalized application Context; see the [AJNI Context contract](docs/agents/ajni-application-context-requirement.md). Context ownership and JNI host mechanics remain in AJNI; asset operations remain in runtimebinding. The current native worker posts back to main and does not support worker-thread MoonBit, so off-main I/O still needs a separate execution/completion contract.

For each slice, implement the Android-specific package, migrate real consumers, and exercise the actual device path before publishing its contract. Add shared abstractions only when multiple platform implementations demonstrate the same semantics. Capability-specific handles and errors should follow the selected API rather than introducing a generic resource/cancellation framework ahead of use.

## Stage 3: HarmonyOS evaluation and adapter

Android prerequisites passed before starting this stage. The selected HarmonyOS capability is structured logging through published `moonohos` and `moonohos_ohos` 0.6.0 with BitLogger 0.10.0. The independently built `ohos_runtimebinding` module avoids AJNI dependencies.

The adapter may depend on MoonOHOS public APIs. Node-API bridging, ABI builds, HAR/HAP packaging, and platform packages already owned by MoonOHOS remain out of scope. Consider a local shim only for a demonstrated gap that cannot reasonably be addressed through the upstream public API; document the evidence and maintenance cost before implementation.

Stage acceptance must cover the selected capability on HarmonyOS, a runnable demo, and the relevant shared contract. Broader conformance, dual-platform examples, and release packaging are sized from the selected capability rather than assumed in advance.

- HOS 7.0 / API 26 x86_64: HAR and HAP build, unsigned debug HAP installation, ArkTS-to-MoonBit invocation, visible completion state, and real HiLog records passed. Two force-stop/start runs verify Trace-to-Debug mapping, remaining priorities, Unicode, fields, and targets.
- The adapter uses BitLogger's pure `core`, `formatting`, and `sink_graph` packages. The root `Logger` package pulls host async native stubs that MoonOHOS rejects; no full root-logger or cross-platform filtering claim is made for the device example.
- The WSL build command invokes the official Windows SDK compiler through temporary path wrappers and restores `-all-pkgs` metadata stripped by MoonOHOS 0.6.0. It does not modify upstream installations. Remove the metadata compatibility bridge once an upstream release supports the current compiler; see ADR 0005.
- ARM64, ordinary signed-device deployment, additional capabilities, and publication of the new module remain unverified.


## Engineering work categories

| Category | Ownership | Evidence to accept work |
|---|---|---|
| Capability contract | runtimebinding, aligned with an existing consumer library where applicable | Consumer need, stable semantics, host contract test |
| Android logging adapter | runtimebinding provides a fallible BitLogger record writer | Published AJNI/BitLogger APIs, error and record contract checks, Android device/emulator behavior |
| JNI and Android host primitives | AJNI upstream | Specific missing primitive, thread/lifecycle contract, upstream tests and release |
| HarmonyOS adapter | runtimebinding, conditional Stage 3 | Published MoonOHOS API and runnable target-device/demo path |
| Node-API bridge and HarmonyOS packaging | MoonOHOS upstream | Contribute upstream only by agreement; do not recreate here |
| Shared abstractions and conformance | runtimebinding, only with multiple real implementations | Same meaningful behavior across adapters and consumer-facing tests |
| Toolchain and platform packaging | Existing toolchains and upstream build projects | Reuse existing tools; add only project-specific reproducible integration |
| Documentation and release | runtimebinding | README for consumers; this roadmap/ADRs for internal decisions; publish stable usable modules only |
