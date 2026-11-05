///|
pub fn run_logging() -> String raise @hilog.HilogError {
  let sink = @log.HilogSink::new(0x5254, "RuntimeBinding")
  let logger = @logger.Logger::new(
    sink,
    min_level=@logger.Level::Trace,
    target="RuntimeBindingSmoke",
  )
  for
    (level, message) in [
      (@logger.Level::Trace, "smoke trace"),
      (@logger.Level::Debug, "smoke debug"),
      (@logger.Level::Info, "smoke info"),
      (@logger.Level::Warn, "smoke warn"),
      (@logger.Level::Error, "smoke error"),
    ] {
    logger.log(level, message)
  }
  logger.info("资源索引 ready: 月亮 🌙", fields=[
    @logger.field("resource_count", "1"),
  ])
  logger.log(@logger.Level::Info, "target override", target="ResourceIndex")
  let filtered = @logger.Logger::new(sink, min_level=@logger.Level::Warn)
  filtered.debug("must be filtered")
  logger.info("PASS ohos-log")
  "Logging example completed"
}
