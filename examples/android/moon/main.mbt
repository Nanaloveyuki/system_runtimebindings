///|
let pre_init_rejected : Ref[Bool] = Ref(false)

///|
fn init {
  try {
    ignore(@log.AndroidSink::new())
    abort(
      "FAIL android-log: AndroidSink::new succeeded before host initialization",
    )
  } catch {
    @log.Runtime(@runtime.NotInitialized) => pre_init_rejected.val = true
    _ => abort("FAIL android-log: unexpected initialization error")
  }
}

///|
fn check_write(result : Result[Unit, @log.AndroidLogError]) -> Unit {
  match result {
    Ok(_) => ()
    Err(_) => abort("FAIL android-log: record write failed")
  }
}

///|
fn verify_application_context() -> Unit raise @runtime.RuntimeError {
  let session = @runtime.Session::current()
  let context = @android.application_context()
  errdefer context.close()
  let context_class = session.find_class(
    try! @ajni.JniClass::parse("android/content/Context"),
  )
  errdefer context_class.object().close()
  let string_class = try! @ajni.JniClass::parse("java/lang/String")
  let package_name = context_class.instance_method(
    "getPackageName",
    try! @ajni.JniMethod::new(
      [],
      return_type=@ajni.JniType::object(string_class),
    ),
  )
  let package_name_object = match package_name.call([], receiver=context) {
    @runtime.Object(Some(value)) => value
    _ => raise @runtime.NativeFailure("Context.getPackageName returned null")
  }
  errdefer package_name_object.close()
  let package_name = package_name_object.to_string_value()
  if package_name != "dev.nanaloveyuki.runtimebinding.demo" {
    raise @runtime.NativeFailure("Application Context has the wrong package name")
  }
  package_name_object.close()
  context_class.object().close()
  context.close()
}

///|
fn smoke() -> Unit raise @log.AndroidLogError {
  verify_application_context() catch {
    error => raise @log.Runtime(error)
  }
  let logger = @logger.Logger::new(
    @log.AndroidSink::new(),
    min_level=@logger.Level::Trace,
    target="RuntimeBindingSmoke",
  )
  for
    (level, message) in [
      (@logger.Level::Trace, "smoke trace"),
      (@logger.Level::Debug, "smoke debug"),
      (@logger.Level::Info, "smoke info"),
      (@logger.Level::Warn, "smoke warn"),
      (@logger.Level::Error, "smoke error"),
    ] {
    check_write(logger.log_with(level, message, @log.AndroidSink::write))
  }
  check_write(
    logger.log_with(
      @logger.Level::Info,
      "资源索引 ready: 月亮 🌙",
      @log.AndroidSink::write,
      fields=[@logger.field("resource_count", "1")],
    ),
  )
  check_write(
    logger.log_with(
      @logger.Level::Info,
      "target override",
      @log.AndroidSink::write,
      target="ResourceIndex",
    ),
  )
  let filtered = logger.with_min_level(@logger.Level::Error)
  check_write(
    filtered.log_with(
      @logger.Level::Debug,
      "must be filtered",
      @log.AndroidSink::write,
    ),
  )
  if !pre_init_rejected.val {
    abort("FAIL android-log: pre-init rejection was not observed")
  }
  check_write(
    logger.log_with(
      @logger.Level::Info,
      "pre-init rejected: NotInitialized",
      @log.AndroidSink::write,
    ),
  )
  check_write(
    logger.log_with(
      @logger.Level::Info,
      "PASS android-context",
      @log.AndroidSink::write,
    ),
  )
  check_write(
    logger.log_with(
      @logger.Level::Info,
      "PASS android-log",
      @log.AndroidSink::write,
    ),
  )
}

///|
pub fn dispatch(kind : Int32, first : Int32, second : Int32) -> Unit {
  @android.dispatch_from_android(kind, first, second)
  if kind == 1 {
    smoke() catch {
      _ => abort("FAIL android-log: sink construction failed")
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
