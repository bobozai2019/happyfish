# Codex Adapter

## CLI

```powershell
codex mcp add image-recognition -- python D:\AIprogram\myaitool\mcp-servers\image-recognition\server.py
```

## config.toml

也可以手动在 `~/.codex/config.toml` 中加入：

```toml
[mcp_servers.image-recognition]
type = "stdio"
command = "python"
args = [ "D:\\AIprogram\\myaitool\\mcp-servers\\image-recognition\\server.py" ]
enabled = true
```

## Secret Policy

不要在 `codex mcp add` 命令里使用 `--env MIMO_API_KEY=...`，也不要把 `MIMO_API_KEY` 写进 `~/.codex/config.toml`。真实密钥必须在启动 Codex 的父进程环境中存在，或由本机 secret manager 注入。
