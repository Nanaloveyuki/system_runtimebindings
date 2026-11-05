# BitLogger Owns the Logging Contract

Status: accepted

`Nanaloveyuki/BitLogger` owns `Logger`, `Record`, levels, filtering, and structured formatting. Runtimebinding owns Android output through `AndroidSink`. BitLogger's non-raising `Sink::write` cannot preserve fallible AJNI calls, so Android output uses the generic `Logger::log_with` writer returning `Result[Unit, E]`. Filtering still occurs before record creation and dispatch. Android sink construction and writes raise `AndroidLogError::Runtime(original_error)`. A local writer closure converts the raised failure into `Result` at the `log_with` seam. The application decides recovery or propagation; the adapter neither swallows failures nor aborts. No warning suppression is needed.

Every logcat message under `RuntimeBinding` contains the complete BitLogger JSON record, preserving target and fields even when fields are empty. BitLogger `Trace` maps to Android `Verbose`. No independent runtimebinding logger or level enum remains.

BitLogger resolves to published 0.11.1, which includes `Logger::log_with`; no local BitLogger workspace member is required. AJNI resolves to published 0.3.6; demo host helpers are imported from `ajni/android`.