# Godot Engine Knowledge

## 2026-05-14: class_name 类型不能跨文件用作类型注解

`var x: ClassName = null`（其中 ClassName 来自另一个文件的 `class_name` 声明）在 Godot 4 中会导致 "Could not find type in current scope" 解析错误。`class_name` 注册的类型在编辑器 UI 中可用，但 GDScript 文本解析器在解析阶段无法跨文件解析它们。

**Why:** Godot 的脚本解析是分阶段的。`class_name` 在注册阶段可用，但类型注解在解析阶段求值——此时其他文件的类可能尚未解析。`preload()` 在解析阶段同步执行，所以它的返回值可用作类型。

**How to apply:** 跨文件类型注解必须使用 preload 常量模式：
```gdscript
const FooScript = preload("res://scripts/foo.gd")
var x: FooScript = null
```
不要使用 `var x: Foo = null`（即使 foo.gd 有 `class_name Foo`）。同文件内的 class_name 引用（如返回类型 `-> RunManager` 在 run_manager.gd 内部）是安全的。

## 2026-05-14: `:=` 类型推断 + 算术导致 Variant 传播

`var _drag_start_x := 0.0` 看起来是 float，但 Godot 4.7 的类型推断可能将其视为 Variant。当后续代码 `var dx: float = event.global_position.x - _drag_start_x` 做算术时，Variant 参与的表达式结果仍是 Variant，导致 "Cannot infer the type" parse error。

**Why:** `:=` 依赖右侧字面量推断类型，但在某些上下文中（类成员变量、与 Variant 属性交互）推断结果不一致。

**How to apply:** 类成员变量始终使用显式类型标注 `var x: float = 0.0` 而非 `var x := 0.0`。局部变量的 `:=` 通常没问题，但遇到 "Cannot infer the type" 错误时，优先检查参与运算的变量是否都是显式类型。

## 2026-05-14: SceneTree 没有 set_exit_code()

headless 测试脚本（extends SceneTree）中调用 `set_exit_code(0)` 会报 "Static function not found"。SceneTree 的退出方法是 `quit(exit_code)`，它同时设置退出码并关闭引擎。

**Why:** `set_exit_code()` 是 `OS` 类的静态方法，不是 SceneTree 的。`quit()` 接受可选的 exit code 参数。

**How to apply:** headless 测试脚本中用 `quit(0)` 表示成功，`quit(1)` 表示失败。不要分开调用 `set_exit_code()` + `quit()`。

## 2026-05-23: GDScript 热重载服务器脚本会崩溃

`godotiq_reload_addon` 重载 `godotiq_server.gd` 会返回 error 22（脚本正在使用中），因为它是当前运行的 WS 服务器。重载失败会导致服务器崩溃，所有后续 MCP 调用返回"远程计算机拒绝网络连接"。

**How to apply:** `godotiq_runtime.gd` 可以热重载，但 `godotiq_server.gd` 不行。修改服务器脚本后不要调用 `reload_addon`，直接重启 Godot 编辑器。

## 2026-05-22: 编辑 .gd 后必须运行语法检查

每次修改 .gd 文件后，必须运行 `godotiq_check_errors` (scope=project) 检查语法错误，即使改动看起来很微小。未检测的解析错误（如方法不存在、类型推断失败）会在运行时才暴露。

**How to apply:** 在任何修改 .gd 文件的任务结束时，调用 `mcp__godotiq__godotiq_check_errors` scope=project，修复所有报告的错误后再声称任务完成。
