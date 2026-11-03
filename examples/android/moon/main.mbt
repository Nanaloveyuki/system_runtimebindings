///|
let pre_init_rejected : Ref[Bool] = Ref(false)

///|
fn init {
  // The host initializes MoonBit before installing its JNI session.
  try {
    ignore(@log.Logger::new("RuntimeBindingSmoke"))
    abort("FAIL android-log: Logger::new succeeded before host initialization")
  } catch {
    @runtime.NotInitialized => pre_init_rejected.val = true
    error =>
      abort(
        "FAIL android-log: unexpected pre-init error: \{runtime_error(error)}",
      )
  }
}

///|
fn runtime_error(error : @runtime.RuntimeError) -> String {
  match error {
    UnsupportedTarget => "UnsupportedTarget"
    NotInitialized => "NotInitialized"
    Closed => "Closed"
    WrongThread => "WrongThread"
    Busy => "Busy"
    InvalidArgument(message) => "InvalidArgument: \{message}"
    JavaThrown(_) => "JavaThrown"
    NativeFailure(message) => "NativeFailure: \{message}"
  }
}

///|
fn smoke() -> Unit raise @runtime.RuntimeError {
  let logger = @log.Logger::new("RuntimeBindingSmoke")
  logger.log(Verbose, "smoke verbose")
  logger.log(Debug, "smoke debug")
  logger.log(Info, "smoke info")
  logger.log(Warn, "smoke warn")
  logger.log(Error, "smoke error")
  logger.log(Info, "资源索引 ready: 月亮 🌙")
  if !pre_init_rejected.val {
    logger.log(Error, "FAIL android-log: pre-init rejection was not observed")
    abort("FAIL android-log: pre-init rejection was not observed")
  }
  logger.log(Info, "pre-init rejected: NotInitialized")
  logger.log(Info, "PASS android-log")
}

///|
pub fn dispatch(kind : Int32, first : Int32, second : Int32) -> Unit {
  @android.dispatch_from_android(kind, first, second)
  if kind == 1 {
    smoke() catch {
      error => abort("FAIL android-log: \{runtime_error(error)}")
    }
  }
}

///|
pub fn create_int_callback(env : UInt64) -> UInt64 {
  @android.create_int_callback(env)
}

///|
pub fn handled_observer_error() -> Int32 {
  @android.handled_observer_error()
}

///|
fn main {
  ()
}
