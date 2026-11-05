# BitLogger 异步拆分交接（已完成）

> 状态：迁移完成并已验证。本文件保留为收尾记录，可删除。

## 目标（已达成）

`../BitLogger` 的异步文件能力已完全移出根 `src` 闭包：

- 根 `src.file_sink(...) -> FileSink`：同步，且不含 `moonbitlang/async` 依赖。
- `src-async.file_sink_async(...) -> AsyncFileSink`：异步文件写入、刷新、轮转。
- 配置构建的异步 logger 返回 `AsyncLogger[AsyncRuntimeSink]`，文件路径走异步文件操作。

## 最终结构

- `src-async/async_file_writer.mbt`：异步写入/轮转/刷新循环。`ensure_async_handle_internal` 在首次写入时执行 deferred 打开；打开失败增加 `open_failures` 并清除不可用 handle，该记录同时计入 `write_failures`。
- `src-async/async_file_sink.mbt`：`AsyncFileSink` 包装共享 `@file_runtime.FileSink` 状态，构造时异步打开；`reopen*` 保持同步控制语义（安装 deferred handle，由下一次异步写入完成打开）。
- `src-async/async_runtime_sink.mbt`：`AsyncRuntimeSink` 包装配置生成的 `RuntimeSink`，`File`/`QueuedFile` 走异步 writer，其余变体复用同步路径。
- `src-async/file_backend_native.mbt` / `file_backend_stub.mbt`：native 与 unavailable-backend 两套异步文件原语，无 ops 表间接层。
- `src/file_runtime/file_sink.mbt`：只保留同步实现，导出中性内部 seam（`handle_internal`、`set_handle_internal`、`rotation_internal`、`auto_flush_internal`、`format_line_internal`、`record_*_failure_internal`、`rotation_limit_bytes_internal`、`rotated_file_path`）。此前的 `async_*_internal` 命名与 `new_file_sink_from_handle_internal` 已删除。
- `src/utils/file_handle_internal.mbt`：`FileHandle` 访问器收敛到单一共享文件，backend 不再重复定义 `new_file_handle_internal`。

## 验证（已执行）

- `moon fmt --check`、`moon info`、严格 `moon check --target TARGET --deny-warn`：native / wasm / wasm-gc / js 全部通过。`llvm` 无法在本地检查（仅 nightly 工具链提供 LLVM backend）。
- 严格 `moon test --target TARGET --deny-warn`：native 319、wasm 312、wasm-gc 230、js 312。
- `src-async` 各目标：native 115、wasm 108、wasm-gc 26、js 108 通过。
- 依赖闭包核验：`src`、`src/file_runtime`、`src/utils`、`src/runtime` 闭包内无任何 `moonbitlang/async*`；只有 `src-async` 引入。
- `src-async/async_file_sink_test.mbt` 覆盖（native）：异步写入/轮转字节、deferred 打开失败计数、配置构建 logger 经异步后端落盘、`reopen` deferred 语义。
- `src-async/async_file_sink_unavailable_test.mbt` 覆盖非 native 目标的单次 open failure 计数。
- 独立消费模块（workspace 链接本地 BitLogger）在 native 上完成写入、轮转、关闭。
- 下游 `Nanaloveyuki/android_runtimebinding` 以本地 workspace 链接后 `moon check` / `moon test` 通过。
- Android 模拟器 smoke（`emulator-5554`）两次启动通过，APK 已用本地 workspace 重新构建：Context、优先级、Unicode、fields、target 覆盖、过滤、init 前拒绝均正确。
- HarmonyOS 模拟器 smoke（`127.0.0.1:5557`）两次启动通过，HAP 已用本地 workspace 重新构建：HiLog 优先级、Unicode、fields、target、过滤、ArkTS→MoonBit 调用均正确。
- `moon package --list` 归档不含 `logs/` 与 `.db*`。

## 发布状态

- `0.11.0` 已发布，但 CI 暴露两处回归：macOS 同步文件写入全部失败、Windows `Int32::to_uint` 弃用检查失败。
- `0.11.1` 已发布并修复上述问题，CI 七个 job 全绿（含 macOS、Windows）：
  - POSIX `open` flags 改由 C stub 按平台 `fcntl.h` 计算；
  - `open` 改为在 C 中调用，修复 Apple ARM64 上 variadic 参数走栈导致的 `mode` 传递错误；
  - 路径 bytes 显式 NUL 终止；
  - Windows `_write` 长度改用 `Int32::reinterpret_as_uint`。
- 注册表无 yank 命令，`0.11.0` 仍在，使用 `0.11.1` 或更高版本。

## 未执行

- `llvm` 目标检查。编译器提示 LLVM backend 仅 nightly 支持，固定 stable 工具链不包含 LLVM 的 `prelude.mi`；CI 也未覆盖 `llvm`。

## 设备验证备注

- WSL 内 `adb` 看不到设备；需用 Windows 的 `adb.exe`（`--adb` 参数已支持 `.exe` 路径），本次用 `emulator-5554`。
- `hdc.exe` 位于 `~/AppData/Local/OpenHarmony/Sdk/26.0.0/toolchains/hdc.exe`，目标 `127.0.0.1:5557`。
- OHOS 构建需 Linux `ninja`；本机没有，临时把 `/opt/android-sdk/cmake/3.22.1/bin` 加到 `PATH`。
- 本地 BitLogger 需以相对路径加入 `examples/ohos/moon.work`（moonohos 拒绝绝对路径成员），构建后已还原。

## 版本

已通过 `scripts/update-version.ps1 0.11.0 -ReleaseVersion 1.5.0` 更新 `moon.mod`、安装片段与 `docs/changes`，生成说明见 `../BitLogger/docs/changes/1.5.0(0.11.0).md`。
