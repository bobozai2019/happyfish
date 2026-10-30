# Claude Adapter

## Project Scope

在目标项目目录中运行：

```powershell
claude mcp add --scope project image-recognition -- python D:\AIprogram\myaitool\mcp-servers\image-recognition\server.py
```

如果项目已经通过 junction 暴露 server，也可以使用项目路径：

```powershell
claude mcp add --scope project image-recognition -- python .claude\mcp-servers\image-recognition\server.py
```

## Secret Policy

不要在 `claude mcp add` 命令里使用 `-e MIMO_API_KEY=...`。真实密钥必须在启动 Claude Code 的父进程环境中存在，或由本机 secret manager 注入。
