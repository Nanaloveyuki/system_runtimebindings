///|
fn parse_class(name : String) -> @ajni.JniClass raise @runtime.RuntimeError {
  @ajni.JniClass::parse(name) catch {
    _ => raise @runtime.InvalidArgument("Invalid Android log class name")
  }
}

///|
/// Retains the original AJNI failure for application error handling.
pub(all) suberror AndroidLogError {
  Runtime(@runtime.RuntimeError)
}

///|
pub struct AndroidSink {
  println : @runtime.JavaMethod
  tag : @runtime.JavaObject
}

///|
pub fn AndroidSink::new() -> AndroidSink raise AndroidLogError {
  try {
    let session = @runtime.Session::current()
    let log_class = session.find_class(parse_class("android/util/Log"))
    errdefer log_class.object().close()
    let string_class = parse_class("java/lang/String")
    let descriptor = @ajni.JniMethod::new(
      [
        @ajni.JniType::int(),
        @ajni.JniType::object(string_class),
        @ajni.JniType::object(string_class),
      ],
      return_type=@ajni.JniType::int(),
    ) catch {
      _ =>
        raise @runtime.InvalidArgument("Invalid Android log method descriptor")
    }
    let println = log_class.static_method("println", descriptor)
    log_class.object().close()
    { println, tag: session.new_string("RuntimeBinding"), }
  } catch {
    error => raise Runtime(error)
  }
}

///|
/// Writes one BitLogger record and propagates AJNI failures to its caller.
pub fn AndroidSink::write(
  self : AndroidSink,
  record : @logger.Record,
) -> Unit raise AndroidLogError {
  try {
    let session = @runtime.Session::current()
    let message_object = session.new_string(@logger.format_json(record))
    errdefer message_object.close()
    ignore(
      self.println.call([
        @runtime.Int(android_priority(record.level)),
        @runtime.Object(Some(self.tag)),
        @runtime.Object(Some(message_object)),
      ]),
    )
    message_object.close()
    ()
  } catch {
    error => raise Runtime(error)
  }
}

///|
fn android_priority(level : @logger.Level) -> Int32 {
  match level {
    Trace => 2
    Debug => 3
    Info => 4
    Warn => 5
    Error => 6
  }
}
