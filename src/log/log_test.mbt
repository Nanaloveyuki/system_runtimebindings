///|
#cfg(not(target="native"))
test "logging cannot simulate success without native JNI" {
  try {
    ignore(@log.Logger::new("unsupported"))
    fail("Expected UnsupportedTarget")
  } catch {
    @runtime.UnsupportedTarget => ()
    _ => fail("Expected UnsupportedTarget")
  }
}
