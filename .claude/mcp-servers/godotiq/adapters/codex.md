# Codex Adapter

## 项目配置

onboarding 会在项目 `.codex/config.toml` 中生成：

```toml
[mcp_servers.godotiq]
command = "python"
args = ["-m", "godotiq"]
cwd = "<projectRoot>"
env = { PYTHONPATH = "<projectRoot>/addons/godotiq", GODOTIQ_ADDON_PORT = "<projectPort>" }
```

`addons/godotiq` 是指向 hub `godot/addons/godotiq` 的 junction。通过
`PYTHONPATH` 优先加载项目插件内的 `godotiq` Python 包，使 MCP 与编辑器插件保持同一版本。

## 前置条件

1. Python 依赖已安装：`pip install -r D:\AIprogram\myaitool\mcp-servers\godotiq\requirements.txt`
2. 项目已通过 onboarding 安装 `addons/godotiq` junction 并启用插件
3. `project.godot` 包含 `res://addons/godotiq/plugin.cfg`
4. Godot 编辑器正在运行

## Secret Policy

不要在 config.toml 中写入 `GODOTIQ_LICENSE_KEY=...`。真实密钥必须在启动 Codex 的父进程环境中存在。
