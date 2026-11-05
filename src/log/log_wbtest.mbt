///|
/// Android log priority constants are stable across API levels; the mapping is
/// the only part of the write path that can be checked without a live JNI
/// session.
test "android priority covers every BitLogger level" {
  inspect(android_priority(@logger.Level::Trace), content="2")
  inspect(android_priority(@logger.Level::Debug), content="3")
  inspect(android_priority(@logger.Level::Info), content="4")
  inspect(android_priority(@logger.Level::Warn), content="5")
  inspect(android_priority(@logger.Level::Error), content="6")
}

///|
/// Mapping must stay strictly increasing so BitLogger's level filter and
/// Android's own log filtering agree on ordering.
test "android priority preserves level ordering" {
  let levels : Array[@logger.Level] = [
    @logger.Level::Trace,
    @logger.Level::Debug,
    @logger.Level::Info,
    @logger.Level::Warn,
    @logger.Level::Error,
  ]
  for index = 1; index < levels.length(); {
    assert_true(
      android_priority(levels[index - 1]) < android_priority(levels[index]),
    )
    continue index + 1
  }
}

///|
/// The record payload handed to `Log.println` is BitLogger's JSON form. Check
/// the shape the Android side receives, including target and fields.
test "android sink payload keeps record structure" {
  let record = @logger.Record::new(
    @logger.Level::Warn,
    "Index rebuilt",
    target="Index",
    fields=[@logger.field("resource", "moon")],
  )
  let payload = @logger.format_json(record)
  inspect(
    payload,
    content="{\"level\":\"WARN\",\"message\":\"Index rebuilt\",\"fields\":{\"resource\":\"moon\"},\"target\":\"Index\"}",
  )
}

///|
/// A record without a target or fields still has to be valid JSON, because the
/// Android side parses the payload to recover the record.
test "android sink payload tolerates empty context" {
  let record = @logger.Record::new(@logger.Level::Info, "plain")
  let payload = @logger.format_json(record)
  inspect(
    payload,
    content="{\"level\":\"INFO\",\"message\":\"plain\",\"fields\":{}}",
  )
}

///|
/// Unicode messages must survive the MoonBit-to-JNI string conversion path
/// unchanged; the smoke test covers the device, this covers the payload.
test "android sink payload keeps unicode messages" {
  let record = @logger.Record::new(
    @logger.Level::Info,
    "资源索引 ready: 月亮 🌙",
  )
  let payload = @logger.format_json(record)
  assert_true(payload.contains("资源索引 ready: 月亮 🌙"))
}
