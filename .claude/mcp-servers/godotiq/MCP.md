# GodotIQ MCP Server

## 用途

桥接 AI 助手到 Godot 编辑器和运行中的游戏。通过 WebSocket 与 Godot 插件通信，提供场景操作、GDScript 编辑、运行时检查、截图等功能。

## 架构

```
Python MCP server (stdio) ←→ WebSocket ←→ GDScript addon (Godot editor)
```

- MCP server 通过 stdio 与 AI agent 通信
- 通过 WebSocket（默认端口 6107）与 Godot 编辑器中的 godotiq 插件通信
- Godot 编辑器需启用 godotiq 插件

## 前置条件

1. Python 依赖已安装：`pip install -r requirements.txt`
2. Godot 编辑器中已启用 godotiq 插件（`addons/godotiq/`）
3. Godot 编辑器正在运行

## 工具（Community）

| 工具 | 说明 |
|------|------|
| `godotiq_ping` | 健康检查 |
| `godotiq_screenshot` | 视口截图（游戏/编辑器） |
| `godotiq_run` | 启动/停止游戏 |
| `godotiq_perf_snapshot` | FPS、draw calls、内存 |
| `godotiq_editor_context` | 编辑器状态 |
| `godotiq_scene_tree` | 实时场景树 |
| `godotiq_node_ops` | 节点批量操作 |
| `godotiq_script_ops` | GDScript 读写 |
| `godotiq_file_ops` | 文件系统操作 |
| `godotiq_input` | 玩家输入模拟 |
| `godotiq_exec` | 执行 GDScript |
| `godotiq_state_inspect` | 运行时属性查询 |
| `godotiq_nav_query` | 寻路查询 |
| `godotiq_watch` | 属性监控 |
| `godotiq_undo_history` | 撤销/重做 |
| `godotiq_save_scene` | 保存场景 |
| `godotiq_camera` | 3D 相机控制 |
| `godotiq_ui_map` | UI 元素映射 |
| `godotiq_build_scene` | 批量创建节点 |
| `godotiq_check_errors` | GDScript 编译检查 |
| `godotiq_read_debug_console` | 读取调试控制台 |
| `godotiq_verify_project_runs` | 运行验证 |
| `godotiq_verify_motion` | 运动验证 |
| `godotiq_game_scene_tree` | 运行时场景树 |
| `godotiq_press_button` | 触发按钮信号 |
| `godotiq_find_node` | 查找节点 |
| `godotiq_reload_addon` | 热重载插件 |

## Pro 工具

需要 `GODOTIQ_LICENSE_KEY`：

`godotiq_project_summary`, `godotiq_file_context`, `godotiq_dependency_graph`, `godotiq_signal_map`, `godotiq_impact_check`, `godotiq_validate`, `godotiq_trace_flow`, `godotiq_animation_audit`, `godotiq_asset_registry`, `godotiq_scene_map`, `godotiq_spatial_audit`, `godotiq_placement`, `godotiq_suggest_scale`, `godotiq_explore`

## 环境变量

| 变量 | 必需 | 默认值 | 说明 |
|------|------|--------|------|
| `GODOTIQ_PROJECT_ROOT` | 否 | 自动发现 | Godot 项目根目录 |
| `GODOTIQ_ADDON_PORT` | 否 | 6107 | WebSocket 端口；避开 Godot 默认远程调试端口 6007 |
| `GODOTIQ_LICENSE_KEY` | 否 | - | Pro 许可证密钥 |
| `GODOTIQ_DEV_KEY` | 否 | - | 开发密钥（Pro bypass） |

## 分发策略

**junction/live**（固定）：选择 godotiq MCP 时，onboarding 同步创建：

```text
<project>/addons/godotiq → <hubRoot>/godot/addons/godotiq
<project>/.claude/mcp-servers/godotiq → <hubRoot>/mcp-servers/godotiq
```

同时将 `res://addons/godotiq/plugin.cfg` 幂等加入 `project.godot` 的
`[editor_plugins] enabled`，使编辑器下次启动时直接加载桥接插件。

Claude Code 和 Codex 均使用 `python -m godotiq`，并把
`<project>/addons/godotiq` 写入 `PYTHONPATH`，优先加载插件随附的 Python 包。
Codex 使用项目根作为 `cwd`；Claude Code 通过 `GODOTIQ_PROJECT_ROOT` 显式传入项目根。
两端还会收到同一个 `GODOTIQ_ADDON_PORT`。项目未配置端口时，onboarding 从
`6107` 起选择首个可用端口并写入 `.godotiq.json`，避开 Godot 默认远程调试端口 6007。
因此编辑器插件和 MCP Python 实现始终来自同一个受 hub 管控的 addon 版本。

## 接入方式

Claude 接入见：`adapters/claude.md`

Codex 接入见：`adapters/codex.md`
