# Runtime Bindings Roadmap

Internal delivery plan for `system_runtimebindings`. The README remains user-facing; this file tracks sequencing, ownership, and acceptance. Platform plans beyond the Android MVP are conditional, not delivery commitments.

## Current Snapshot

- Android logcat path: exercised on an API 37 x86_64 emulator. The smoke run verified all five Android log priorities, Unicode output, and rejection before AJNI host initialization.
- Existing Android logging package: currently exposes a direct `Logger` API. Treat it as the first platform proof, not the desired long-term logging facade; BitLogger already owns structured logging and the generic `Sink` contract.
- BitLogger Android adapter: not yet implemented. The intended Android integration is a BitLogger `Sink` that sends records to Android logcat while preserving levels, target, message, and fields, subject to an explicit write-failure contract.
- HarmonyOS adapter: not started. Do not begin API mapping or implementation until the Android MVP gate below is met.
- AJNI host helper refactor: the demo now consumes AJNI `0.3.5` and imports reusable callbacks from `Nanaloveyuki/ajni/android`, without an executable-package dependency. MoonBit `0.10.19+97801ee1b` native checks and the Android APK build pass. The API 37 x86_64 emulator passed two launches covering all five log priorities, Unicode, and rejection before AJNI initialization. Runtime binding `0.1.1` retains the direct Logger API; the BitLogger adapter remains a separate planned change.

## Stage 1: Android MVP

Goal: deliver a usable Android logging backend for the existing BitLogger library with a reproducible real-platform path.

1. Complete AJNI host-helper packaging upstream; update this repository to the compatible AJNI release and remove the executable-package dependency from the demo.
2. Before choosing the adapter interface, resolve the error-contract mismatch: BitLogger's synchronous `Sink::write` is non-raising, while AJNI calls may raise `RuntimeError`. Verify supported BitLogger extension patterns and decide how Android write failures remain observable; do not silently swallow failures or abort as an undocumented fallback.
3. If the error contract supports a reliable adapter, add an Android sink implementing BitLogger's public `Sink`. Preserve structured record semantics: map levels to Android priorities and retain target, message, and fields. Keep AJNI session and owner-thread constraints explicit.
4. Migrate the Android example and user documentation to the selected BitLogger integration. Remove the standalone runtimebinding `Logger` API after all consumers move; do not retain a parallel logging facade.
5. Re-run workspace checks and the Android install/launch/logcat smoke path against updated dependencies. Host tests must exercise record-to-log mapping and the chosen failure behavior; emulator smoke must verify actual priority, tag/target, message, and structured fields.
6. Review public module/package layout and generated interfaces. Publish only independently useful, stable modules; do not create or publish a shared facade solely to satisfy a planned module count.

Exit gate: the logging integration has an explicit, observable write-failure contract; it builds against published AJNI and BitLogger releases without depending on an AJNI executable package; host contract checks and real Android smoke pass; a consumer can configure BitLogger to emit to Android logcat; license and release metadata are ready.

## Stage 2: Android capability selection

After Stage 1, choose each next capability from a concrete consumer need. For each candidate:

- Specify Android behavior, threading/lifecycle constraints, errors, and observable acceptance before defining a cross-platform contract.
- Check the currently published AJNI API. Reuse it where sufficient; otherwise propose the smallest concrete upstream primitive with a use case and tests. Do not duplicate JNI or host integration in this repository.
- Implement and verify one capability at a time. Permissions, network state, device information, vibration, resource access, cancellation, and lifecycle composition are candidates, not promised scope.
- Add shared abstractions only when multiple platform implementations establish the same semantics. A single Android adapter does not justify a cross-platform facade or generalized cancellation/resource model.

## Stage 3: HarmonyOS evaluation and adapter

Start only after Android capability contracts and their verification approach are stable enough to map. First inspect the then-current published `moonohos` and `moonohos_ohos` interfaces and select one concrete capability with a viable demo path.

The adapter may depend on MoonOHOS public APIs. Node-API bridging, ABI builds, HAR/HAP packaging, and platform packages already owned by MoonOHOS remain out of scope. Consider a local shim only for a demonstrated gap that cannot reasonably be addressed through the upstream public API; document the evidence and maintenance cost before implementation.

Stage acceptance must cover the selected capability on HarmonyOS, a runnable demo, and the relevant shared contract. Broader conformance, dual-platform examples, and release packaging are sized from the selected capability rather than assumed in advance.

## Engineering work categories

| Category | Ownership | Evidence to accept work |
|---|---|---|
| Capability contract | runtimebinding, aligned with an existing consumer library where applicable | Consumer need, stable semantics, host contract test |
| Android logging adapter | runtimebinding implements BitLogger `Sink` | Published AJNI/BitLogger APIs, record mapping test, Android device/emulator behavior |
| JNI and Android host primitives | AJNI upstream | Specific missing primitive, thread/lifecycle contract, upstream tests and release |
| HarmonyOS adapter | runtimebinding, conditional Stage 3 | Published MoonOHOS API and runnable target-device/demo path |
| Node-API bridge and HarmonyOS packaging | MoonOHOS upstream | Contribute upstream only by agreement; do not recreate here |
| Shared abstractions and conformance | runtimebinding, only with multiple real implementations | Same meaningful behavior across adapters and consumer-facing tests |
| Toolchain and platform packaging | Existing toolchains and upstream build projects | Reuse existing tools; add only project-specific reproducible integration |
| Documentation and release | runtimebinding | README for consumers; this roadmap/ADRs for internal decisions; publish stable usable modules only |
