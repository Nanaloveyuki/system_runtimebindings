///|
/// Android log priority, ordered from least to most severe.
/// Values match android.util.Log priorities.
pub(all) enum Level {
  Verbose
  Debug
  Info
  Warn
  Error
}

///|
fn parse_class(name : String) -> @ajni.JniClass raise @runtime.RuntimeError {
  @ajni.JniClass::parse(name) catch {
    _ => raise @runtime.InvalidArgument("Invalid Android log class name")
  }
}

///|
pub fn Level::priority(self : Level) -> Int32 {
  match self {
    Verbose => 2
    Debug => 3
    Info => 4
    Warn => 5
    Error => 6
  }
}

///|
/// A logger bound to the AJNI session that was current at construction.
pub struct Logger {
  println : @runtime.JavaMethod
  tag : @runtime.JavaObject
}

///|
/// Creates a logger for an Android log tag. Create it after AJNI host initialization.
pub fn Logger::new(tag : String) -> Logger raise @runtime.RuntimeError {
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
    _ => raise @runtime.InvalidArgument("Invalid Android log method descriptor")
  }
  let println = log_class.static_method("println", descriptor)
  ignore(log_class.object().close())
  { println, tag: session.new_string(tag), }
}

///|
/// Writes one message to Android's system log. The logger is valid only while
/// its AJNI session remains open and on that session's owner thread.
pub fn Logger::log(
  self : Logger,
  level : Level,
  message : String,
) -> Unit raise @runtime.RuntimeError {
  let session = @runtime.Session::current()
  let message_object = session.new_string(message)
  errdefer message_object.close()
  ignore(
    self.println.call([
      @runtime.Int(level.priority()),
      @runtime.Object(Some(self.tag)),
      @runtime.Object(Some(message_object)),
    ]),
  )
  message_object.close()
}
