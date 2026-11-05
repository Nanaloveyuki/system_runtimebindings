///|
pub struct HilogSink {
  logger : @hilog.Logger
}

///|
/// Domain and tag validation follows MoonOHOS; writes have no delivery result.
pub fn HilogSink::new(
  domain : Int32,
  tag : String,
) -> HilogSink raise @hilog.HilogError {
  { logger: @hilog.Logger::new(domain, tag), }
}

///|
/// HiLog has one level less than BitLogger, so trace collapses into debug.
fn hilog_level(level : @logger.Level) -> @hilog.Level {
  match level {
    Trace | Debug => @hilog.Level::Debug
    Info => @hilog.Level::Info
    Warn => @hilog.Level::Warn
    Error => @hilog.Level::Error
  }
}

///|
pub impl @sink_graph.Sink for HilogSink with fn write(self, record) {
  self.logger.log(hilog_level(record.level), @formatting.format_json(record))
}

///|
pub extend HilogSink with @sink_graph.Sink::{write, write_async}
