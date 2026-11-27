///|
pub fn run_logging() -> String raise @hilog.HilogError {
  let sink = @log.HilogSink::new(0x5254, "RuntimeBinding")
  let target = "RuntimeBindingSmoke"
  for
    (level, message) in [
      (@core.Trace, "smoke trace"),
      (@core.Debug, "smoke debug"),
      (@core.Info, "smoke info"),
      (@core.Warn, "smoke warn"),
      (@core.Error, "smoke error"),
    ] {
    sink.write(@core.Record::new(level, message, target~))
  }
  sink.write(
    @core.Record::new(@core.Info, "资源索引 ready: 月亮 🌙", target~, fields=[
      @core.field("resource_count", "1"),
    ]),
  )
  sink.write(
    @core.Record::new(@core.Info, "target override", target="ResourceIndex"),
  )
  if @core.Level::enabled(@core.Debug, @core.Warn) {
    sink.write(@core.Record::new(@core.Debug, "must be filtered", target~))
  }
  sink.write(@core.Record::new(@core.Info, "PASS ohos-log", target~))
  "Logging example completed"
}
