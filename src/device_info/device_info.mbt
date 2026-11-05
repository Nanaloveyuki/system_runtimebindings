///|
/// Returns the Android device API level, not the host application's target SDK.
pub fn sdk_level() -> Int32 raise @runtime.RuntimeError {
  let session = @runtime.Session::current()
  let version_class = session.find_class(
    try! @ajni.JniClass::parse("android/os/Build$VERSION"),
  )
  errdefer version_class.object().close()
  let field = version_class.static_field("SDK_INT", @ajni.JniType::int())
  let sdk_level = match field.get() {
    @runtime.Int(value) => value
    _ =>
      raise @runtime.NativeFailure("Build.VERSION.SDK_INT was not an integer")
  }
  version_class.object().close()
  sdk_level
}
