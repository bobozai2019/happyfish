# image-recognition MCP Server

## 用途

识别图片内容并返回文字描述。支持远程图片 URL 和本地图片路径。

## 工具

- `image_recognize`
  - `image`：图片 URL 或本地文件路径
  - `prompt`：可选提示词，默认要求详细描述图片内容

## 依赖

- Python 3.10+
- Python 包：`mcp`
- 可访问 MiMo API 的网络环境

## 环境变量

必需：

- `MIMO_API_KEY`：MiMo API key

可选：

- `MIMO_BASE_URL`：默认 `https://token-plan-cn.xiaomimimo.com/v1`
- `MIMO_MODEL`：默认 `mimo-v2.5`

安全规则：

- 真实密钥只允许来自用户环境变量或本机 secret manager。
- 禁止把密钥写入仓库、`.claude`、`~/.codex/config.toml`、`mcp.manifest.json`、adapter 文档或 shell 命令示例。
- 不要使用 `claude mcp add -e MIMO_API_KEY=真实值` 或 `codex mcp add --env MIMO_API_KEY=真实值`，这类命令会留下 shell history。
- 如果密钥曾经进入 git history，必须轮换密钥，并清理历史记录。

## 启动

canonical command：

```powershell
python D:\AIprogram\myaitool\mcp-servers\image-recognition\server.py
```

Windows 便利脚本：

```powershell
D:\AIprogram\myaitool\mcp-servers\image-recognition\start.ps1
```

Unix/WSL 便利脚本：

```bash
D:/AIprogram/myaitool/mcp-servers/image-recognition/start.sh
```

## 分发策略

- `junction/live`：本机开发默认，项目 `.claude/mcp-servers/image-recognition` 指向 hub 路径，自动跟随最新版本。
- `copy/snapshot`：稳定项目推荐，复制当前 server 到项目并记录 hub commit。
- `submodule/subtree`：需要严格项目级版本锁定时使用。

Windows junction 示例：

```powershell
New-Item -ItemType Junction `
  -Path "D:\godot\project\slg-card-test\.claude\mcp-servers\image-recognition" `
  -Target "D:\AIprogram\myaitool\mcp-servers\image-recognition"
```

稳定项目需要在项目文档记录：

```text
image-recognition source: D:/AIprogram/myaitool
hub commit: <git-commit>
distribution: copy/snapshot
```

## Agent Adapters

- Claude：见 `adapters/claude.md`
- Codex：见 `adapters/codex.md`

新增其他 agent 时，只增加新的 adapter 文档或配置片段，不把 agent 专属配置写进 `mcp.manifest.json`。
