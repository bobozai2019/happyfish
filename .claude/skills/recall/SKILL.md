---
name: recall
description: "搜索统一知识库中的相关洞察。搜索范围包括 hub 的跨项目 knowledge 和当前项目的 .shared/knowledge；支持概览、关键词、分类、问题、反模式及近期知识查询。"
---

# Recall — Knowledge Search

搜索由 `summarize` 维护的双层知识库。

## Resolve paths

1. 从本技能的 hub 规范路径定位 hub 根目录，并读取 `config/onboarding.json` 的 `hubRoot`。
2. 用 `git rev-parse --show-toplevel` 确定当前项目根目录，不可用时才使用当前工作目录。
3. 搜索以下两个位置：

```text
<hubRoot>/knowledge/                    — 跨项目知识
<projectRoot>/.shared/knowledge/        — 项目知识
```

不要搜索或创建 `~/.claude/memory/`。项目库中的旧 `MEMORY.md`、扁平文件和 `bug_history/` 仍作为兼容内容递归搜索。

## Search

### 无参数

递归读取两个知识目录的 Markdown 文件，按位置、相对路径和条目数（`## ` 标题）给出概览。

### 关键词

不区分大小写递归搜索所有 Markdown 文件，返回完整匹配条目，而不只是命中行。每条标明 hub/项目、相对路径、日期和标题。无匹配时建议相邻关键词或分类。

### 分类

先读取两层知识库各自的 `INDEX.md`。参数匹配索引中的分类、文件名、标签或说明时，读取对应文件或目录。特殊范围关键词：

- `项目` / `local`：只搜索项目库。
- `hub` / `通用` / `shared`：只搜索 hub。

### 特殊查询

- `problems` / `issues` / `fixes`：匹配症状、根因、修复、陷阱等字段。
- `recent` / `latest`：返回最近 7 天条目并按日期分组。
- `anti-pattern` / `陷阱`：匹配反模式和失败教训。

## Output

```text
找到 N 条相关知识：

1. [hub | web/vite-proxy.md | 日期] 标题
   经验：...

2. [项目 | unity/yaml-assets.md | 日期] 标题
   经验：...
```

路径以各自 `INDEX.md` 为导航，但索引不完整时仍递归搜索实际文件。不要在技能内维护固定的知识目录树。
