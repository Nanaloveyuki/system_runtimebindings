# AJNI application Context requirement

Implemented and released as AJNI 0.3.6 on 2026-11-03, tag `v0.3.6` at commit `03ed9bb579a65a41f822d187da071fedbf422e15`. [GitHub Release](https://github.com/Nanaloveyuki/ajni/releases/tag/v0.3.6) and Mooncakes publication are complete; a fresh consumer downloaded `Nanaloveyuki/ajni@0.3.6` from the registry and passed the public API's desktop rejection test. Runtimebinding now pins 0.3.6 and its Android demo exercises Context acquisition on-device. The accepted API and lifecycle contract are recorded below. Platform capability references remain in [android-capability-reference.md](android-capability-reference.md).

## Outcome and ownership

The public Android-host interface is:

```moonbit nocheck
pub fn application_context() -> @runtime.JavaObject raise @runtime.RuntimeError
```

AJNI owns host initialization, Java reference ownership, owner-thread entry and session validity. Runtimebinding owns `Context.getAssets()`, asset path/read/error semantics, and later system-service adapters. Build/version static reads already work through field access and do not need this extension. Existing runtime methods, primitive arrays and UTF-16 conversion also suffice for a synchronous asset-read binding; no new JNI invocation engine is required.

## Existing facts that constrain the change

| Existing contract | Evidence in the adjacent AJNI checkout | Consequence |
| --- | --- | --- |
| Kotlin normalizes and retains `context.applicationContext` only after native initialization succeeds | `android/host/src/main/java/dev/nanaloveyuki/ajni/host/NativeBridge.kt`, `initialize` | Explicit host input; null and identity-conflicting active-host inputs are rejected. |
| The private static `applicationContextForRuntime(): Context` is called by the public checked getter | `src/android/runtime.mbt`, host consumer rules | Every acquisition promotes a Java return to an independent owned JavaObject without another C Context cache. |
| Object handles own global JNI refs; independently imported/returned objects have separate resource entries | `src/runtime/README.mbt.md`, `src/runtime/ajni_runtime.c` | Returning a normal JavaObject can reuse existing ownership and close behavior. |
| Feature shutdown preserves the generic session and callbacks | `src/android/README.mbt.md`, “Observers and stopping”; `NativeBridgeInstrumentedTest.kt` calls an existing callback after shutdown | Do not make feature shutdown close the generic session or invalidate every returned JavaObject. |
| Generic `Session.close()` invalidates derived resources and reopening advances its generation | `src/runtime/ajni_runtime.c`, `ajni_rt_host_close`, `ajni_rt_host_open` | Reuse generic session invalidation; do not add a parallel handle generation. |
| Managed execution is owner-thread-only; Android owner is the main Looper | `docs/adr/0001-general-jni.md`, `src/runtime/README.mbt.md` | Attaching a worker to the JVM does not authorize running MoonBit there. |
| `start_worker()` attaches, posts to main, and detaches | `src/android/ajni_bridge.c`, `ajni_worker_main`; Android README | This is not an asynchronous asset execution facility. |

## Accepted implementation

AJNI 0.3.6 uses a host-held application Context plus a private static Java getter through the existing checked JNI runtime:

1. In `NativeBridge`, retain the normalized application Context only after native initialization succeeds and before `initialize` returns. Reject a missing application Context explicitly. Failed initialization must not publish a new Context. Repeated initialization of the same active host must not silently replace the published Context with a different object; compare object identity and reject a conflicting host input.
2. Add a private `@JvmStatic` getter with an exact, unmangled JVM name and a `Context` return type. Require the existing main-thread rule. If the Android feature is stopped or Context has not been published, throw `IllegalStateException`; do not return null as success. Keep lookup/call names from shrinking/obfuscation using the existing host consumer rules.
3. Implement the MoonBit function using `Session::current()`, a checked lookup of the host class, and the static getter. A Java return is promoted to an ordinary owned JavaObject by the existing runtime. Close temporary class wrappers using existing patterns, preserving the primary error on cleanup. No public raw Env/ref values, new global C cache, or new runtime pointer wrapper are needed for this design.
4. On feature shutdown, clear the host's retained Context and prevent new acquisition. Already returned JavaObjects retain their normal generic-session lifetime. Preserve current subscriptions, callbacks and active-entry behavior. A subsequent successful initialization publishes a Context again.
5. A direct generic `Session.close()` makes old Context handles unusable under the existing Closed/generation checks. The Android host may still hold the application Context until feature shutdown; that host-owned strong reference is not a JNI reference leak. Reinitialize through the existing host flow before using the public acquisition interface again.
6. Non-native targets and native non-Android hosts return `UnsupportedTarget`. They must not attempt to resolve the Android host class in a desktop JVM. Use the existing platform/conditional compilation patterns to distinguish platform support from an uninitialized Android host.

This direction centralizes lifecycle state in the existing Kotlin host and reuses Java-object promotion. If implementation instead retains Context in C, it must provide the same public contract and prove rollback, duplicate-acquisition isolation, explicit reference release and thread gating; adding a second cache is not a prerequisite.

## Public semantics

| Scenario | Required outcome |
| --- | --- |
| Android call before generic host/session initialization | Existing `RuntimeError::NotInitialized`. During MoonBit package initialization the host session is not ready. |
| Android feature initialized on owner | Non-null checked JavaObject referring to the normalized application Context. |
| Two successful acquisitions | Same Java identity (`is_same`), independently owned handles. Closing one acquired handle does not close the other or disable future acquisition. Assigning an alias to one handle still shares that handle's close state. |
| Feature shutdown, generic session still live | New acquisition fails with `JavaThrown` retaining the getter's original IllegalStateException. Previously acquired handles remain valid until explicitly closed or their generic session closes. |
| Feature reinitialize with the same generic session | New acquisition succeeds. Older open handles remain valid; do not promise feature-generation invalidation. |
| Generic session closed or old-generation handle used after reopen | Existing `Closed` contract. No stale pointer access and no rebinding an old handle to the new session. |
| Java getter, lookup or normalization throws | Preserve the original Throwable via the existing JNI error path. Do not stringify or convert every Java failure into “not initialized”. |
| Unsupported platform | `UnsupportedTarget`, including a native desktop build with working JNI. |
| Foreign-thread Java/JNI managed entry | Reject in the existing native entry gate before touching MoonBit-managed values. The MoonBit function is owner-only and does not make already-running foreign-thread MoonBit safe. |

Use `RuntimeError` for this new checked-object interface. Existing Android feature functions use legacy `JniError`; keep their existing contracts unchanged rather than forcing a broad error migration into this change. The JavaThrown result after feature shutdown is intentional for the minimal checked-Java-getter design; introducing a distinct typed feature-closed result would require a separately justified native status interface.

## Implementation evidence

API37 x86_64 ART passed all 11 instrumentation tests: 3 Context tests plus 8 existing host regressions. `ApplicationContextInstrumentedTest` exercises Activity normalization and Java identity, independent ownership and alias close state, `getPackageName()` after closing a separate handle, feature shutdown/reinitialize with surviving handles/callbacks/subscriptions, original getter exception stack preservation, initialization normalization/null/conflict/native-loader rollback, explicit session close outside an active entry, reopen with stale handles rejected, and foreign-thread native rejection. A bundled executable package-initialization probe verifies `NotInitialized` before the session opens.

Linux/JDK21 checked-JNI Java/native host fixtures passed, including Android acquisition rejection with a live desktop JVM. Native and Wasm-GC rejection tests each executed and passed. NDK API24 arm64-v8a/x86_64 production, bundled acceptance and exports-disabled configurations passed the exact JNI contract gate; APK/instrumentation compilation, lint, package and release-metadata checks passed. arm64/API24 runtime and R8-minified lookup remain unverified. AJNI's Android README and ADR 0001 record the maintained contract/evidence; the test exports are optional under `AJNI_CONTEXT_TEST_EXPORTS`, so custom executable hosts need no additional wrappers.

## Blocking I/O is a separate prerequisite

The getter unlocks synchronous Android object access, not a production worker execution path. A MoonBit `InputStream.read` loop under the present Android host runs on the main owner thread. A tiny fixture can prove bytes and lifetime but cannot establish suitability for large asset reads.

Before exposing general blocking asset reads as application-ready, establish an off-main execution path. One possible direction is host Java/Kotlin I/O work that returns owned bytes/error data through native-owned completion state, then dispatches into MoonBit on its owner. Define cancellation, completion lifetime, error transfer and shutdown behavior from the actual resource use case before implementing that separate slice. Do not run MoonBit closures on the existing native worker or move JavaObject handles across threads. Activity/result delivery for permissions is another later host requirement; application Context alone does not supply it.

## Implementation slices and acceptance

| Slice | Files to inspect/change in AJNI | Completion evidence |
| --- | --- | --- |
| Host Context publication | `android/host/.../NativeBridge.kt`, `android/host/consumer-rules.pro` | Successful initialize publishes the application Context; failed/conflicting initialize preserves prior valid state; shutdown clears acquisition; getter survives shrinking. |
| Public checked getter | `src/android/runtime.mbt`, `types.mbt`/`ffi.mbt` only where platform gating requires, `src/android/moon.pkg`, generated interface | One public acquisition function, RuntimeError contract, no executable import, root package stays descriptor-only, unsupported targets fail explicitly. |
| Lifetime/host integration | Existing Android native host exports and instrumentation fixture | Identity and independently owned handles, close/reacquire, shutdown/reinitialize with surviving generic handles, explicit session close/reopen with stale handles rejected. Use the existing checked host entry, not a new foreign-thread entry. |
| Release and consumer integration | Android README, CHANGELOG, package/release checks; runtimebinding dependency and resource consumer afterward | Upstream build/smoke and targeted instrumentation pass; generic callback survival regression still passes; release version is available before replacing the downstream pin. |

Tests must exercise the public getter through a real Android host. Verify normalization by initializing with an Activity and comparing the returned object with that Activity's application Context; do not retain the Activity. After closing one independently acquired handle, call `getPackageName()` through the other, then acquire again. After feature shutdown, confirm new acquisition fails while an earlier handle still calls successfully. After reinitialize, verify acquisition works and callbacks/subscriptions retain their existing behavior. For explicit session close/reopen, close outside an active entry as required by the existing runtime, then verify stale Context handles fail Closed and new acquisition works. Before initialization and on non-Android targets, assert the documented failure rather than a fake Context or null success.

The downstream resource smoke remains runtimebinding's responsibility: exact binary bytes across several buffers, empty and Unicode-named assets, missing-asset failure, repeated reads, Java stream close and AJNI reference cleanup. Passing these does not replace the separate off-main I/O requirement or establish compatibility across untested Android versions.
