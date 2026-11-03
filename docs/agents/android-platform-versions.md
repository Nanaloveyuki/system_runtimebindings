# Android platform versions

Use this reference when choosing Android API guards, reviewing behavior changes, or planning runtime verification for formal bindings. Fetched **2026-11-03** (environment date); linked pages can contain older or inconsistent content. Update the affected rows and source dates when a binding, SDK, or target changes; keep links and decision-relevant facts here rather than mirroring Android documentation. This note adds no supported-version guarantee.

## SDK settings and runtime checks

The [demo build](../../examples/android/app/build.gradle.kts) currently declares `minSdk=28`, `compileSdk=36`, and `targetSdk=36`. These settings answer different questions:

| Setting/check | Meaning and binding consequence | Official source |
| --- | --- | --- |
| `minSdk` | Installation floor. A newer API still needs a runtime guard when the app also runs below its introduction level. A manifest declaration alone does not verify those branches. | [SDK settings](https://developer.android.com/build#android_sdk_settings), [`uses-sdk`](https://developer.android.com/guide/topics/manifest/uses-sdk-element#min) |
| `compileSdk` | APIs available to the compiler. Raising it makes newer symbols available for compilation; the running device must still supply the API. The build documentation also describes compiling against a specific minor API level. | [SDK settings](https://developer.android.com/build#android_sdk_settings) |
| `targetSdk` | Selects target-dependent compatibility behavior on the running platform. It does not raise the installation floor or supply missing APIs. Android calls this an attestation of testing; this repository must report actual verification separately. | [SDK settings](https://developer.android.com/build#android_sdk_settings), [`targetSdkVersion`](https://developer.android.com/guide/topics/manifest/uses-sdk-element#target) |
| `Build.VERSION.SDK_INT` | Device's running major API level; compare with the required `VERSION_CODES` threshold before resolving/calling a newer JNI member. `RELEASE` is an opaque display string and cannot be ordered. | [`SDK_INT`](https://developer.android.com/reference/android/os/Build.VERSION#SDK_INT), [`RELEASE`](https://developer.android.com/reference/android/os/Build.VERSION#RELEASE) |
| `SDK_INT_FULL` | Added in API 36; includes major and minor versions. Minor releases may add APIs while leaving `SDK_INT` unchanged, and have stricter compatibility guarantees, including no `targetSdkVersion`-gated changes. Guard access to this field itself with `SDK_INT >= 36`, then compare against `VERSION_CODES_FULL` for minor-specific APIs. Use named constants; their numeric encoding is an implementation detail. | [`SDK_INT_FULL`](https://developer.android.com/reference/android/os/Build.VERSION#SDK_INT_FULL), [`VERSION_CODES_FULL`](https://developer.android.com/reference/android/os/Build.VERSION_CODES_FULL) |
| Preview identity | `PREVIEW_SDK_INT` is zero on production builds. For an API still under development, check equality with the exact preview revision compiled against; a later preview can remove or change it. Record `CODENAME`, preview revision, SDK, and image/build identity when reporting a run. | [`PREVIEW_SDK_INT`](https://developer.android.com/reference/android/os/Build.VERSION#PREVIEW_SDK_INT), [`CODENAME`](https://developer.android.com/reference/android/os/Build.VERSION#CODENAME), [APIs under development](https://developer.android.com/guide/topics/manifest/uses-sdk-element#apis-under-development) |

The manifest cannot express a minimum or target **minor** SDK version ([`uses-sdk`](https://developer.android.com/guide/topics/manifest/uses-sdk-element)). Consult the current API reference for minor-level availability: the older [Android 16 feature overview](https://developer.android.com/about/versions/16/features#using-new-apis) still contains preview-era wording that the full-version APIs were not finalized, whereas their current reference marks them added in API 36.

## Major versions and behavior entry points

Version/API mappings below come from the official [`uses-sdk` API-level table](https://developer.android.com/guide/topics/manifest/uses-sdk-element#ApiLevels). Read both behavior columns when a runtime or target changes. Each individual change can have additional permission, state, device, or target conditions; the column label is an entry point, not a replacement for those conditions. API 32 is Android **12L**, the Android 12 feature drop ([12L overview](https://developer.android.com/about/versions/12/12L/summary)).

| Runtime API | Android version | All-app behavior entry | Target-dependent behavior entry |
| --- | --- | --- | --- |
| 28 | 9 / Pie | [All apps](https://developer.android.com/about/versions/pie/android-9.0-changes-all) | [Target 28+](https://developer.android.com/about/versions/pie/android-9.0-changes-28) |
| 29 | 10 | [All apps](https://developer.android.com/about/versions/10/behavior-changes-all) | [Target 29+](https://developer.android.com/about/versions/10/behavior-changes-10) |
| 30 | 11 | [All apps](https://developer.android.com/about/versions/11/behavior-changes-all) | [Target 30+](https://developer.android.com/about/versions/11/behavior-changes-11) |
| 31 | 12 | [All apps](https://developer.android.com/about/versions/12/behavior-changes-all) | [Target 31+](https://developer.android.com/about/versions/12/behavior-changes-12) |
| 32 | 12L | [12L changes and verification guidance](https://developer.android.com/about/versions/12/12L/summary), plus Android 12 above | Android 12 target entry above; review 12L-specific conditions in the overview |
| 33 | 13 | [All apps](https://developer.android.com/about/versions/13/behavior-changes-all) | [Target 33+](https://developer.android.com/about/versions/13/behavior-changes-13) |
| 34 | 14 | [All apps](https://developer.android.com/about/versions/14/behavior-changes-all) | [Target 34+](https://developer.android.com/about/versions/14/behavior-changes-14) |
| 35 | 15 | [All apps](https://developer.android.com/about/versions/15/behavior-changes-all) | [Target 35+](https://developer.android.com/about/versions/15/behavior-changes-15) |
| 36 | 16 | [All apps](https://developer.android.com/about/versions/16/behavior-changes-all) | [Target 36+](https://developer.android.com/about/versions/16/behavior-changes-16) |
| 37 | 17; forward runtime relative to this demo's target | [All apps](https://developer.android.com/about/versions/17/behavior-changes-all) | [Target 37+](https://developer.android.com/about/versions/17/behavior-changes-17) |

**API 37 status:** the official [Android 17 release announcement](https://android-developers.googleblog.com/2026/06/Android-17.html), reached through the [Android 17 home page](https://developer.android.com/about/versions/17), is dated **2026-06-16** and explicitly announces the release and availability on supported Pixel devices. This is public release evidence independent of the installed emulator. Sources are unevenly maintained: the [version index](https://developer.android.com/about/versions) retrieved with a 2025-06-10 update date stops at Android 16; the [17 release-notes page](https://developer.android.com/about/versions/17/release-notes) still ends with Beta 4.1 dated 2026-06-01; the [17 SDK setup](https://developer.android.com/about/versions/17/setup-sdk) uses `compileSdk=37` but still says “Cinnamon Bun Preview.” Preserve those source limits rather than calling every API 37 image a preview or treating every preview label as current release status. Availability/release status of later minor releases was not established by this research.

For formal bindings, keep Build metadata read-only: on Android 17+ with target 37+, changing a `static final` field through JNI causes a crash ([target-37 behavior](https://developer.android.com/about/versions/17/behavior-changes-17)). That page also documents target-37 local-network permission enforcement; review it if communication with LAN devices is added. Network-state observation and LAN communication are separate capabilities.

## Proposed verification matrix

These are **planned checks, not executed results or support promises**. Keep the shipped demo target at 36 for the compatibility runs; an eventual target upgrade needs its own behavior review and runs.

| Runtime selection | Purpose |
| --- | --- |
| API 28 baseline | Exercise the installation floor, startup/JNI initialization, available API branches, and behavior when newer capabilities are unavailable. |
| Each changed capability threshold, and the preceding supported API | Exercise both branches of each guard. Example: [`VibratorManager` starts at 31](https://developer.android.com/reference/android/os/VibratorManager), so check the older path below 31 and the manager path at 31. Choose further rows from the actual class/member availability metadata, not one arbitrary device per Android name. |
| API 36, target 36 | Exercise current target-dependent behavior and metadata reads, including guarded `SDK_INT_FULL` access. Add the exact minor runtime only when consuming a minor-specific API. |
| Available API 37 runtime, target 36 | Exercise forward compatibility and all-app changes without assuming target-37 behavior is enabled. Record the precise image/build and preview indicators; consult the release evidence above for public status. |
| Available preview runtime, when relevant | Keep separate from released-runtime evidence; record the exact preview revision and test only APIs matching that revision. No specific newer preview availability was established here. |

The preparation pass inspected the existing emulator through ADB: SDK `37`, release `17`, codename `REL`, preview revision `0`, fingerprint `google/sdk_gphone64_x86_64/emu64xa:17/CE2A.260420.019/15611780:user/release-keys`. These properties identify the image; the prior logging smoke does not complete this matrix or verify unimplemented bindings.

Local signature/availability checks used Android SDK Platform 16 / API 36, package revision 2 (`source.properties`). Its `data/api-versions.xml` SHA-256 was `923f7e6367759e127679b6b5a4156ee801100e3cc07dc1d99cb811e791e45435`. No binding code or build configuration changed during this preparation pass.

## Reference and metadata policy

Use the canonical [Android API reference](https://developer.android.com/reference) for class/member contracts, “Added in”/deprecation levels, permissions, threading, and documented failures; use the release entries above for changed behavior. Follow a specific reference link only when implementing or reviewing the corresponding capability.

For bulk availability lookup, prefer the installed SDK's `platforms/android-<level>/data/api-versions.xml` and package metadata (`source.properties`/`package.xml`), plus the corresponding SDK sources or pinned AOSP source. AOSP publishes the [SDK public metadata directory](https://android.googlesource.com/platform/prebuilts/sdk/+/refs/heads/main/current/public/data/?format=HTML), including [api-versions.xml](https://android.googlesource.com/platform/prebuilts/sdk/+/refs/heads/main/current/public/data/api-versions.xml?format=HTML). Pin a revision or record the SDK package revision and file checksum for reproducible findings; `main` and live docs move. Resolve the exact overload and inherited class availability rather than assuming that a missing member-level `since` means “unknown.”

This metadata is an availability index, not proof that permissions were granted, hardware exists, a service is enabled, or target-dependent behavior was exercised. Confirm semantics in the official member documentation and results on the selected runtime. Downloading full documentation separately for every Android version adds stale copies without replacing that work; retain narrow citations and reproducible metadata provenance instead.
