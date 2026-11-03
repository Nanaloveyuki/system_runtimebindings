# Runtime Bindings Roadmap

Internal delivery plan for `system_runtimebindings`. The README remains user-facing; this file tracks sequencing, ownership, and acceptance. Platform plans beyond the Android MVP are conditional, not delivery commitments.

## Current Snapshot

- The earlier direct Android logger proved JNI/logcat output on API 37 x86_64; that result predates the BitLogger migration.
- The current package exposes `AndroidSink` and `AndroidLogError`. BitLogger owns the logger, levels, filtering, and records; the standalone runtimebinding `Logger` and `Level` APIs have been removed.
- Writes use BitLogger's new `Logger::log_with` callback and return `Result[Unit, AndroidLogError]`. Construction raises the same adapter error; both paths retain the original AJNI failure. Records are serialized using BitLogger JSON formatting.
- AJNI resolves to published 0.3.6. The Android example now exercises `android.application_context()` against the real host and calls `Context.getPackageName()` before closing the independently owned handle. The new BitLogger method is still supplied by the local `../BitLogger` workspace member and absent from published 0.9.2; release remains blocked on the BitLogger publication and migration off the local member.
- Native checking and Android install/launch/logcat smoke remain the verification gates. HarmonyOS adapter: not started; begin evaluation only after the Android MVP exit gate below is met.

## Stage 1: Android MVP

Goal: deliver a usable Android logging backend for the existing BitLogger library with a reproducible real-platform path.

1. Complete AJNI host-helper packaging upstream; update this repository to the compatible AJNI release and remove the executable-package dependency from the demo.
2. Keep Android write failures observable through `Logger::log_with` and `Result[Unit, AndroidLogError]`. The non-raising BitLogger `Sink` trait remains unchanged; Android output uses the fallible writer contract.
3. Preserve structured record semantics: map BitLogger Trace to Android Verbose and retain target, message, fields, and optional timestamp in the JSON record. Keep AJNI session and owner-thread constraints explicit.
4. Keep the example and README aligned with the selected BitLogger integration. The standalone runtimebinding logger has been removed.
5. Run workspace checks and the Android install/launch/logcat smoke against updated dependencies. The smoke checks priorities, Unicode, targets, fields, filtering, and pre-initialization rejection across two launches.
6. Review public module/package layout and generated interfaces. Publish only independently useful, stable modules; do not create or publish a shared facade solely to satisfy a planned module count.

Exit gate: the logging integration has an explicit, observable write-failure contract; it builds against published AJNI and BitLogger releases without depending on an AJNI executable package; host contract checks and real Android smoke pass; a consumer can configure BitLogger to emit to Android logcat; license and release metadata are ready.

## Stage 2: Android capability selection

The validated logging path is sufficient to begin binding preparation. Its BitLogger publication dependency remains a release gate, not a prerequisite for documenting the next capability. Keep platform work Android-first and select one capability at a time.

### Reference and compatibility preparation

For Android version changes, consult [platform versions](docs/agents/android-platform-versions.md). For API signatures, permissions, and capability-specific constraints, consult [capability references](docs/agents/android-capability-reference.md). These notes index official sources and record review dates; refresh the affected section when selecting or changing an API rather than mirroring the full Android documentation tree.

Keep the demo's current `minSdk=28`, `compileSdk=36`, and `targetSdk=36` during preparation. These are engineering inputs, not proof of API 28–36 compatibility. For every bound symbol, record its Java/JNI signature, introduction/deprecation version, permission requirements, device-API guard, target-dependent behavior, thread/session requirements, ownership/close behavior, and observable error. Consult reference documentation and behavior-change pages together; SDK `api-versions.xml` verifies symbol availability only.

For each selected binding, keep a small source record in its capability note: canonical Android URL, review date, SDK platform/revision used for signature checks, and any AOSP release tag used to resolve ambiguity. Prefer public SDK references; use tagged AOSP source only where a documented contract is insufficient. Refresh only the affected entries after an SDK/target upgrade. Keep copied platform documentation and generated SDK metadata in the local SDK/cache rather than committing them here.

Validate on the baseline API, the target API, and any capability-specific behavior thresholds before advertising that range. Keep the existing API 37 smoke as forward-runtime evidence for logging only. Record the device's build/preview identity when testing newer systems; installed SDK/emulator metadata alone does not establish release status.

### Next implementation slices

| Order | Slice | Prerequisite and acceptance |
|---|---|---|
| 1 | Runtime version and small non-sensitive device metadata | Use published AJNI field access for `Build.VERSION.SDK_INT` and selected `Build` fields. Verify returned values against the device; keep device runtime version distinct from host app target SDK. Add only fields actually needed by the binding or example. |
| 2 | Packaged asset binary reads | AJNI 0.3.6 provides the public application-Context contract. Next prove binary reads and stream cleanup; establish off-main host execution and owner-thread completion before exposing general blocking reads. Verify exact bytes, empty files, Unicode names, missing assets and repeated reads. Keep text decoding a caller choice. |
| Later | Vibration, network state, permission requests | Select from a concrete consumer need; use the cited API thresholds and capability-specific permission/callback/lifecycle contracts before committing an interface. |

AJNI 0.3.6 exposes `android.application_context()` for the initialized host's normalized application Context; see the [AJNI Context contract](docs/agents/ajni-application-context-requirement.md). Context ownership and JNI host mechanics remain in AJNI; asset operations remain in runtimebinding. The current native worker posts back to main and does not support worker-thread MoonBit, so off-main I/O still needs a separate execution/completion contract.

For each slice, implement the Android-specific package, migrate real consumers, and exercise the actual device path before publishing its contract. Add shared abstractions only when multiple platform implementations demonstrate the same semantics. Capability-specific handles and errors should follow the selected API rather than introducing a generic resource/cancellation framework ahead of use.

## Stage 3: HarmonyOS evaluation and adapter

Start only after Android capability contracts and their verification approach are stable enough to map. First inspect the then-current published `moonohos` and `moonohos_ohos` interfaces and select one concrete capability with a viable demo path.

The adapter may depend on MoonOHOS public APIs. Node-API bridging, ABI builds, HAR/HAP packaging, and platform packages already owned by MoonOHOS remain out of scope. Consider a local shim only for a demonstrated gap that cannot reasonably be addressed through the upstream public API; document the evidence and maintenance cost before implementation.

Stage acceptance must cover the selected capability on HarmonyOS, a runnable demo, and the relevant shared contract. Broader conformance, dual-platform examples, and release packaging are sized from the selected capability rather than assumed in advance.

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
