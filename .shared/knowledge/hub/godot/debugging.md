# Debugging Knowledge

## 2026-05-17: GodotIQ 端口占用不要写成 ERROR

**Symptom:** `logs/editor.log` 出现 `GodotIQ: Failed to start WebSocket server on port 6007 (error 22)`，但项目脚本加载、headless 验证和场景测试都能通过。

**Investigation:** 检查最新 editor session，脚本解析错误是历史/瞬时日志，当前无法复现；重新跑 `godot --headless --editor --quit` 后只剩 GodotIQ 绑定端口失败。`6007` 被已有编辑器/GodotIQ 实例占用时，新实例启动失败属于可预期状态。

**Root cause:** GodotIQ 插件把端口占用场景用 `push_error()` 上报，EditorLogger 因而写入 `[ERROR]`，污染真正需要处理的错误列表。

**Fix:** 端口不可用时改成普通 `print()` 状态信息，状态栏显示 skipped，并 `set_process(false)` 停止当前 server 节点处理。

**Failed approaches:** 将 `push_error()` 降级为 `push_warning()` 仍会被 EditorLogger 记录为 `[ERROR] type=1`，不能清理日志噪音。

**How to apply:** 看到端口绑定 error 先确认是否已有 editor/GodotIQ 实例占用端口。对插件的"可预期降级状态"用普通状态输出，不要用 `push_error()` / `push_warning()`。

## 2026-05-14: editor.log 是编译错误的权威来源

GodotIQ 调试控制台 (`godotiq_read_debug_console`) 只捕获运行时错误。所有 parse/compile 错误写入 `logs/editor.log`，且错误会重复出现（reload + check 各触发一次）。

**Why:** 编辑器日志包含 GodotIQ 控制台看不到的脚本解析错误，是排查 "为什么场景加载失败" 的第一步。

**How to apply:** 当 `check_errors` 报 0 错误但场景仍有问题时，读取 `logs/editor.log` 查找历史 parse error。注意同一个错误会因 reload/check 产生 2-4 条重复日志。

## 2026-05-14: RefCounted 动态属性赋值失败

`battle_controller.gd` 试图给 `BattleContext`(RefCounted) 赋值 `_launch_config`，但 `battle_context.gd` 没有声明该属性。Godot 4 对 RefCounted/Node 的未声明属性运行时报 `Invalid assignment of property or key`。

**Why:** RefCounted 不像 GDScript 内部类那样允许动态属性扩展，必须在类脚本中显式声明 `var`。

**How to apply:** 当 controller 给 context 赋值新字段时，确保 context 脚本中已有对应 `var` 声明。报错信息格式：`Invalid assignment of property or key 'xxx' with value of type 'yyy' on a base object of type 'RefCounted (zzz.gd)'`。

## 2026-05-14: 全屏 Control 叠层阻挡按钮点击

`map_screen.gd` 的 `_draw_connections()` 创建了一个 `PRESET_FULL_RECT` 的 Control 用于 `draw_line` 绘制路线连线，添加在按钮节点之后（同级 sibling）。默认 `mouse_filter = MOUSE_FILTER_STOP` 导致该不可见 Control 拦截了所有鼠标输入，下方按钮完全无法点击。

**Why:** Godot 4 中同级节点后添加的渲染在上层，默认 STOP 模式会消费输入事件不再向下传递。

**How to apply:** 对仅用于绘制（draw_line/draw_circle 等）的 Control 覆盖层，必须设置 `mouse_filter = Control.MOUSE_FILTER_IGNORE`。同样适用于调试绘制、连线、覆盖装饰等场景。

## 2026-06-19: GLB 内置灯光叠加导致场景过曝

- **标签**: #godot #glb #lighting #debugging
- **症状**: Godot 场景大面积爆白，调低 `WorldEnvironment.tonemap_exposure`、外部 `Light3D.light_energy` 或 glow 后仍然没有明显改善。
- **排查**: 先对比历史截图和当前截图，再逐步排除外部灯光、光斑贴片、角色 Sprite3D 等因素。最终发现导入的 GLB 实例内部还带有灯光节点。
- **根因**: Blender/GLB 场景里的内置灯光会随 PackedScene 一起实例化，并和 Godot 场景外部灯光、Glow、曝光设置叠加，导致画面看起来像单纯过曝。
- **修复**: 在使用该 GLB 的 `.tscn` 里给内部 `Light3D` 子节点添加 override，例如 `visible = false`，再微调外部灯光和 tonemap。
- **如何应用**: 遇到“怎么压曝光都白”的 3D 场景时，先检查实例化模型内部是否自带 `DirectionalLight3D`、`OmniLight3D`、`SpotLight3D`，不要只盯全局曝光和外层灯光。
