///|
/// Domain and tag validation is pure; the level mapping is the other testable
/// part of the sink. Delivery itself needs the HarmonyOS runtime.
test "hilog sink rejects an out-of-range domain" {
  try {
    ignore(HilogSink::new(-1, "RuntimeBinding"))
    fail("Expected InvalidDomain")
  } catch {
    @hilog.InvalidDomain(domain) => inspect(domain, content="-1")
    _ => fail("Expected InvalidDomain")
  }
  try {
    ignore(HilogSink::new(0x10000, "RuntimeBinding"))
    fail("Expected InvalidDomain")
  } catch {
    @hilog.InvalidDomain(domain) => inspect(domain, content="65536")
    _ => fail("Expected InvalidDomain")
  }
}

///|
/// HiLog tags are limited to 1-31 bytes, which constrains the tag the sink
/// passes through.
test "hilog sink rejects an invalid tag" {
  try {
    ignore(HilogSink::new(0x5254, ""))
    fail("Expected InvalidTag")
  } catch {
    @hilog.InvalidTag(_) => ()
    _ => fail("Expected InvalidTag")
  }
  try {
    ignore(HilogSink::new(0x5254, "0123456789012345678901234567890123"))
    fail("Expected InvalidTag")
  } catch {
    @hilog.InvalidTag(_) => ()
    _ => fail("Expected InvalidTag")
  }
}

///|
/// A valid domain and tag construct without raising, so callers can build the
/// sink on a live HarmonyOS runtime.
test "hilog sink accepts a valid domain and tag" {
  let sink = HilogSink::new(0x5254, "RuntimeBinding")
  inspect(ignore(sink), content="()")
}

///|
/// `hilog.Level` has no `Show` implementation, so the mapping is checked by
/// pattern matching instead of by rendering it.
fn hilog_level_name(level : @hilog.Level) -> String {
  match level {
    @hilog.Level::Debug => "Debug"
    @hilog.Level::Info => "Info"
    @hilog.Level::Warn => "Warn"
    @hilog.Level::Error => "Error"
    @hilog.Level::Fatal => "Fatal"
  }
}

///|
/// BitLogger's five levels collapse onto HiLog's four levels. The mapping is
/// what the HiLog output shows, so check it directly.
test "hilog level mapping collapses trace into debug" {
  inspect(hilog_level_name(hilog_level(@logger.Level::Trace)), content="Debug")
  inspect(hilog_level_name(hilog_level(@logger.Level::Debug)), content="Debug")
  inspect(hilog_level_name(hilog_level(@logger.Level::Info)), content="Info")
  inspect(hilog_level_name(hilog_level(@logger.Level::Warn)), content="Warn")
  inspect(hilog_level_name(hilog_level(@logger.Level::Error)), content="Error")
}
