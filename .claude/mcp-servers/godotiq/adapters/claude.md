# Claude Adapter

## Project Scope

onboarding 会在项目 `.mcp.json` 中生成：

```json
{
  "mcpServers": {
    "godotiq": {
      "type": "stdio",
      "command": "python",
      "args": ["-m", "godotiq"],
      "env": {
        "PYTHONPATH": "<projectRoot>/addons/godotiq",
        "GODOTIQ_PROJECT_ROOT": "<projectRoot>",
        "GODOTIQ_ADDON_PORT": "<projectPort>"
      }
    }
  }
}
```

`addons/godotiq` 是指向 hub `godot/addons/godotiq` 的 junction。通过
`PYTHONPATH` 优先加载项目插件内的 `godotiq` Python 包，使 MCP 与编辑器插件保持同一版本。
Claude Code 的项目 `.mcp.json` 不使用 `cwd` 字段；`GODOTIQ_PROJECT_ROOT`
负责显式指定项目根目录。

## 前置条件

1. Python 依赖已安装：`pip install -r D:\AIprogram\myaitool\mcp-servers\godotiq\requirements.txt`
2. 项目已通过 onboarding 安装 `addons/godotiq` junction 并启用插件
3. `project.godot` 包含 `res://addons/godotiq/plugin.cfg`
4. Godot 编辑器正在运行

## Secret Policy

不要在 `claude mcp add` 命令里使用 `-e GODOTIQ_LICENSE_KEY=...`。真实密钥必须在启动 Claude Code 的父进程环境中存在，或由本机 secret manager 注入。
