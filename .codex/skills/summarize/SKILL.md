---
name: summarize
description: "Extract verified bugs, lessons, techniques, decisions, successful patterns, tool practices, constraints, and counterintuitive facts from the conversation, then deduplicate and save them into the project or shared knowledge base. Use when the user invokes /summarize or explicitly asks to record, save, capture, persist, or distill conversation learnings into the knowledge base. Do not trigger for ordinary summaries that have no persistence intent."
---

# Summarize Knowledge

提炼当前对话中经过验证、可独立理解、值得复用的知识，并写入统一的双层 `knowledge` 体系。

## Resolve paths

1. 从本技能 `SKILL.md` 的规范路径向上定位 hub 根目录（`skills/summarize/` 的上两级）。读取其 `config/onboarding.json`；若配置存在，以其中的 `hubRoot` 为准。不要从当前工作目录猜测 hub 路径。
2. 将 `<hubRoot>/knowledge/` 作为跨项目知识库。
3. 用 `git rev-parse --show-toplevel` 确定项目根目录；不可用时才使用当前工作目录。将 `<projectRoot>/.shared/knowledge/` 作为项目知识库。
4. 两层知识库都使用 `INDEX.md`。不要创建或写入 `MEMORY.md`、`~/.claude/memory/` 或新的 `bug_history/`。

## Select the conversation window

- 默认分析本线程中上一次 `/summarize` 调用之后的全部对话。
- 本线程没有更早的 `/summarize` 时，分析整个可用对话。
- 不支持用参数缩小或替代对话范围。除 `-auto` 外的附加文字只能作为用户意图提示，不能成为唯一信息源。

## Select the interaction mode

- `/summarize`：先生成候选清单，等待用户一次性选择。
- `/summarize -auto`：使用与默认模式完全相同的提取、验证、路由、查重和冲突判断，然后执行用户对默认清单回答 `all` 时会执行的结果。
- `-auto` 不授予额外的覆盖、冲突解决、降级质量标准或敏感信息写入权限。

## Extract only durable knowledge

提取以下类型：

- bug、踩坑、失败教训和反模式；
- 可复用技巧、调试方法和架构决策；
- 成功模式、验证过的工具用法、重要限制和反直觉事实。

每个候选只表达一个核心结论。跳过普通代码改动、一次性运行状态、显而易见的事实、单纯复述文档且没有新增应用价值的内容，以及已有知识的无实质重复。

只保存已验证结论。以下任一证据可视为验证：相关测试或命令成功、可靠日志或源码证据、权威文档，或用户明确确认。推理上看似可信但未验证的假设一律不入库；在结果中报告为“未保存：待验证”。宁缺毋滥。

## Route by scope and domain

先判断作用域，再选择领域文件：

- 项目文件、类、函数、业务逻辑、具体配置值和完整排查过程写入 `<projectRoot>/.shared/knowledge/`。
- 跨项目可复用且已彻底去项目化的规律写入 `<hubRoot>/knowledge/`。
- 同一个项目 bug 同时产生项目事实和通用规律时，生成两条独立候选：完整记录写项目库；去除项目名、业务名、私有路径和非必要实现细节后的规律写 hub。
- 密钥、令牌、账号、个人信息和私有绝对路径绝不入库。代码与日志只保留支撑结论所需的最小脱敏片段。

按稳定领域和主题组织文件，例如 `unity/yaml-assets.md`、`web/vite-proxy.md`。先读取目标库的 `INDEX.md` 并优先使用已有文件；没有合适文件时可以创建稳定的“领域/主题”文件并更新索引。禁止为单条知识创建过细文件。

项目库若存在旧 `MEMORY.md`、扁平知识文件或 `bug_history/`，保留原位并在新 `INDEX.md` 中索引；不要自动迁移或重写旧内容。搜索和查重时仍包含这些旧文件。

## Check duplicates and conflicts

在写入前递归搜索目标库的 Markdown 文件，并检查标题、标签、关键术语和结论：

1. 精确重复：跳过。
2. 高度相似且结论一致：归类为“补充”。保留原条目，在末尾追加带当前日期的 `补充/更新` 段落；不得删除、改写或静默纠正已有事实。
3. 结论不一致、适用条件不明确或疑似过时：归类为“冲突”。默认模式和 `-auto` 都只报告，不写入、不解决。
4. 无重复：归类为“新建”。

## Present and write

默认模式展示一次候选清单，每条包含：

```text
1. [新建|补充|冲突｜项目|Hub｜relative/path.md] 标题
   摘要：可独立理解的一句话结论
   证据：验证依据
```

允许用户用 `all`、编号列表、作用域过滤或自然语言一次性选择，也允许临时修改非冲突候选的目标路径和作用域。冲突项只供查看，不能被 `all` 选中；若用户要解决冲突，停止本次写入并建议单独审查相关知识。

收到选择后再次检查目标内容未变化，再执行写入。`-auto` 直接执行所有可写的默认候选，等价于用户回答 `all`。

## Write flexible entries

条目结构由内容决定，但至少满足：

```markdown
## YYYY-MM-DD: 标题

- **标签**: #lowercase-tag #hyphenated-tag
```

其余字段自由选择，确保条目脱离原对话仍能理解，并包含适用条件和可执行结论。bug 记录应在有证据时保留症状、排查、根因、修复和教训；不要为了填模板编造字段。

新建文件时添加简短的一级标题。新增文件或索引尚未包含的旧文件时更新对应 `INDEX.md`；不要在技能内维护第二份固定目录树。

## Report results

写入后始终报告：

- 新建、补充和双写的条目及路径；
- 精确重复、未验证和冲突而跳过的候选；
- 新建或更新的索引。

`-auto` 只跳过确认，不得静默完成。
