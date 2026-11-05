///|
test "device SDK level rejects unsupported targets" {
  try {
    ignore(@device_info.sdk_level())
    fail("Expected UnsupportedTarget")
  } catch {
    @runtime.UnsupportedTarget => ()
    _ => fail("Expected UnsupportedTarget")
  }
}
