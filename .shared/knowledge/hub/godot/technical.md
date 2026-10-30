# Godot Technical Knowledge

### MCP 工具输出截断导致静默数据丢失

- **日期**: 2026-05-23
- **标签**: #mcp #godotiq #truncation #detail-level #debugging
- **上下文**: GodotIQ MCP 工具的 `detail` 参数控制输出上限 — `brief`=2000字符, `normal`=8000字符, `full`=无限制。`output_limit.py` 用二分搜索截断列表来满足字符限制，且不报错
- **经验**: 当 `detail="normal"` 时，包含 265 个节点的场景树被截断到约 40 个节点，目标节点（如 BattleHudLayer）可能被静默丢弃。表现为"节点不存在"但实际只是被截断掉了。**排查方法**：检查返回 JSON 中的 `output_truncated` 和 `truncation_notice` 字段。**修复**：将所有 MCP 工具默认值从 `detail="normal"` 改为 `detail="full"`；对于大场景的单节点查找，使用专门的 `godotiq_find_node` 工具替代 `godotiq_game_scene_tree`
- **相关文件**: `addons/godotiq/godotiq/tools/output_limit.py`, `addons/godotiq/godotiq/tools/bridge/__init__.py`

## 2026-08-07: Godot CLI 导出预设必须精确匹配

- **标签**: #godot #cli #web-export #export-preset #build
- `--export-debug` 和 `--export-release` 后的预设参数必须与 `export_presets.cfg` 中的 `name` 完全一致。预设的平台同为 Web 并不代表名称可以互换。
- 外部构建系统应把预设名、输出目录和入口文件视为一组配置共同同步。只更新其中一项，可能导致构建状态失败，或预览继续加载旧目录中的过期产物。
- 遇到 `Invalid export preset name` 时，先枚举工程实际预设名，再核对外部注册表与命令；不要把问题误判为端口、浏览器代理或导出模板缺失。
- **验证**: 同一工程在预设名不匹配时以退出码 1 失败；对齐名称和输出路径后以退出码 0 完成导出，并通过真实 iframe 的 WebAssembly/Canvas 初始化验证。
