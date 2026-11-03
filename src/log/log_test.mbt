///|
#cfg(not(target="native"))
test "Android sink construction reports unsupported target" {
  try {
    ignore(@log.AndroidSink::new())
    fail("Expected UnsupportedTarget")
  } catch {
    @log.Runtime(error) =>
      match error {
        @runtime.UnsupportedTarget => ()
        _ => fail("Expected UnsupportedTarget")
      }
    _ => fail("Expected AndroidLogError")
  }
}
