# HarmonyOS Runtime Binding

Structured HiLog output for MoonBit native modules, using BitLogger 0.11.2 records and MoonOHOS 0.9.0. The module is available on Mooncakes and from this checkout.

## Use

Add `ohos_runtimebinding` to the consuming MoonBit workspace and depend on `Nanaloveyuki/ohos_runtimebinding@0.1.1`. Import these packages in `moon.pkg`:

```moonbit
import {
  "Nanaloveyuki/BitLogger/src/core",
  "Nanaloveyuki/ohos_runtimebinding/log",
}
```

```moonbit
let sink = @log.HilogSink::new(0x5254, "MyApp")
sink.write(@core.Record::new(
  @core.Level::Info,
  "资源索引 ready: 月亮 🌙",
  target="ResourceIndex",
  fields=[@core.field("resource_count", "1")],
))
```

Construction raises MoonOHOS `HilogError` for an invalid domain or tag. Domains must be `0..0xFFFF`; tags must contain 1–31 UTF-8 bytes without NUL. Writes implement BitLogger's non-raising `Sink` contract. HiLog delivery status is not available through the current MoonOHOS interface.

Each message is a complete BitLogger JSON record. `Trace` uses HiLog `Debug` while preserving `TRACE` in JSON; the remaining levels map directly. Target, fields, and supplied timestamp remain in the record. HiLog output is public; callers must avoid logging sensitive data.

## Requirements and applicability

Use MoonBit `0.10.20+65efd5b93` with a MoonOHOS native host. The [example](../examples/ohos/README.md) was verified on HOS 7.0 / API 26 x86_64. ARM64 and signed physical-device deployment have not been verified.

Use BitLogger's pure `core`, `formatting`, and `sink_graph` packages. Its root `src` package currently includes host async native dependencies that cannot load through MoonOHOS. This adapter does not add another logger or filtering framework.

MoonOHOS owns HiLog access, Node-API bridging, native dependency discovery, and HAR packaging. This module adapts BitLogger records to its public logging interface.
