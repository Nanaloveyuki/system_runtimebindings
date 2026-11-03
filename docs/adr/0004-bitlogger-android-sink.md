# BitLogger Owns the Logging Contract

Status: accepted

`Nanaloveyuki/BitLogger` owns `Logger`, `Record`, levels, filtering, and structured formatting. Runtimebinding owns Android output through `AndroidSink`. BitLogger's non-raising `Sink::write` cannot preserve fallible AJNI calls, so Android output uses the generic `Logger::log_with` writer returning `Result[Unit, E]`. Filtering still occurs before record creation and dispatch. Android sink construction raises `AndroidLogError`; writes return `Err(AndroidLogError::Runtime(original_error))`. The application decides recovery or propagation; the adapter neither swallows failures nor aborts.

Every logcat message under `RuntimeBinding` contains the complete BitLogger JSON record, preserving target and fields even when fields are empty. BitLogger `Trace` maps to Android `Verbose`. No independent runtimebinding logger or level enum remains.

The workspace includes `../BitLogger` while `log_with` awaits an upstream release. Published BitLogger 0.9.2 does not include that method; publishing runtimebinding requires a released BitLogger version containing it, updated dependency versions, and removal of the local workspace member. AJNI resolves to published 0.3.6; demo host helpers are imported from `ajni/android`.