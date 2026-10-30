# Gate 0 执行基线报告

文档角色：`verification_evidence`

状态：[已完成]

日期：2026-08-08

范围：T00、T01

## 结论

- T00 [已完成]：仓库、引擎、插件、命令、导出模板和忽略规则现状已复核。
- T01 [已完成]：Compatibility、InputMap、主场景骨架、测试入口与双平台导出预设均已建立。
- Gate 0 [已完成]：编辑器导入、启动烟雾测试、骨架测试及 Windows/Web 实际调试导出均通过。
- 本报告只将实际执行成功的检查记为通过；T00 时的预期失败保留为历史记录，T01 后的成功结果作为门禁结论。

## 仓库基线

| 项 | 实际现状 | 结果 |
|---|---|---|
| 工作区 | `D:\godot\project\happy-fish`；不是 Git checkout，无法验证实际跟踪状态 | warning |
| 项目内容 | T01 前仅有空主场景；现已建立 `scenes/game/main.tscn`、`tests/run_all.gd` 与资源根索引 | pass |
| 插件 | `godot_editor_logger` 启用；不兼容 Godot 4.7.1 编辑器 API 的 GodotIQ 已停用，并移除非玩法所需的运行时 autoload | pass |
| Godot | `4.7.1.stable.official.a13da4feb`，与项目声明的 4.7 一致 | pass |
| 导出模板 | 已安装官方 `4.7.1.stable` Windows x86_64 与 Web non-threaded debug/release 模板 | pass |
| Renderer | 已切换为 `GL Compatibility` | pass |
| 主场景 | `res://scenes/game/main.tscn`，包含 World、运行时对象容器与 UI 静态层级 | pass |
| 测试入口 | `res://tests/run_all.gd` 可加载主场景并校验静态层级 | pass |
| 导出预设 | `Windows Desktop` 与单线程 `Web` 均存在并完成实际 debug 导出 | pass |

## 验收项

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| 仓库现状 | 目录、规则、插件和已有文件明确 | `rg --files`、PowerShell 目录扫描、junction 属性 | pass |
| Godot 版本 | 使用兼容 Godot 4.7 构建 | 正式验收引擎返回 `4.7.1.stable.official.a13da4feb` | pass |
| Renderer | 项目切换为 Compatibility | `config/features` 与 rendering method 均为 GL Compatibility | pass |
| 主场景 | headless 启动不再报告无主场景 | `godot --headless --path . --quit-after 1` 退出码 0 | pass |
| InputMap | 12 个 MVP 输入动作存在 | 配置检查确认动作名完整 | pass |
| 导出预设 | Windows Desktop 与 Web 存在 | 实际导出生成 `build/windows/happy_fish.exe` 与 `build/web/index.html` | pass |
| 忽略规则 | `.godot/`、`build/` 和导出产物不跟踪 | `.gitignore` 包含 `.godot/` 与 `/build/`；当前无 `.git/`，实际跟踪状态不可验证 | pass（环境 warning） |
| 资源规则 | `resources/` 各层有 `index.md` 且不混放 | `resources/index.md` 已建立，当前无资源子目录 | pass |

## 命令与实际结果

| 命令 | 退出码 | 结论 |
|---|---:|---|
| `godot --version` | 0 | 可用，版本见上 |
| `rg --files -g '!.godot/**'` | 0 | 完成文件清单；ignored junction 内容不在清单中 |
| `Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --quit` | 0 | 正式版编辑器导入成功 |
| `godot --headless --path . --quit-after 1` | 0 | 空主场景可启动 |
| `godot --headless --path . --script res://tests/run_all.gd` | 1 | 预期失败：测试入口不存在 |
| `godot --headless --path . --export-debug "Windows Desktop" build/windows/happy_fish.exe` | 1 | 预期失败：没有 `export_presets.cfg` |
| `godot --headless --path . --export-debug "Web" build/web/index.html` | 1 | 预期失败：没有 `export_presets.cfg` |
| `godot --headless --path . --script res://tests/run_all.gd`（T01 后） | 0 | 主场景静态层级测试通过 |
| `godot --headless --path . --export-debug "Windows Desktop" build/windows/happy_fish.exe`（创建输出目录后） | 0 | Windows 调试导出通过 |
| `godot --headless --path . --export-debug "Web" build/web/index.html`（创建输出目录后） | 0 | Web 单线程调试导出通过 |

## 忽略与产物策略

- `.godot/` 保持忽略。
- `/build/` 已补充到 `.gitignore`；Windows 和 Web 导出产物统一位于该目录。
- `.import` 文件由 `.godot/` 承载；根目录现存 `icon.svg.import` 属于异常遗留，应在进入实现后按 Godot 4 规则处理。
- 当前没有 Git 元数据，因此以上仅验证规则文本；进入实际版本库后仍需用 `git check-ignore` 复核。

## 问题与返工

| 问题 | 严重度 | 负责人 | 返工任务 | 状态 |
|---|---|---|---|---|
| Renderer 仍为 Forward Plus | 中 | 主 agent | T01 | resolved |
| InputMap、测试入口和双平台导出预设未配置 | 中 | 主 agent | T01 | resolved |
| `.gitignore` 缺少 `/build/` | 中 | 主 agent | T01 | resolved |
| 当前工作区无 Git 元数据，无法验证实际跟踪状态 | 低 | 环境 | 无 | observed |
| GodotIQ 使用了 Godot 4.7.1 已移除的编辑器 API | 低 | 工具兼容性 | 停用非玩法所需的 GodotIQ 编辑器插件与 runtime autoload | resolved |
