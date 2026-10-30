---
name: onboarding
description: "Use when a project needs to connect to the configured myaitool hub. Reads onboarding config, installs thin references to hub management docs, optionally links shared skills, MCP servers, knowledge categories, and centrally managed Godot addons, and keeps project CLAUDE.md/AGENTS.md conventions as the source of truth."
---

# 项目接入（Onboarding）

将当前项目接入配置文件指定的技能/知识/MCP/Godot 插件中枢。

## Trigger

用户在项目中调用 `/onboarding`，或询问“如何安装/接入 myaitool hub”。

推荐触发方式：

```text
/onboarding
```

触发后，agent 应先解析配置，再执行安装脚本。

## Configuration

配置文件位于 hub 仓库根目录：`D:/AIprogram/myaitool/config/onboarding.json`

优先级：

1. 用户显式指定的 `-ConfigPath`
2. 环境变量 `MYAITOOL_ONBOARDING_CONFIG`
3. 上述默认路径

**重要：配置文件在 hub 仓库中，不在目标项目中。** 执行脚本时通过 `-ConfigPath` 显式传入，或确保环境变量已设置。

配置文件决定：

- `hubRoot`：全局 hub 根目录
- `docs.hubManagement`：技能/知识/MCP 总入口文档
- `docs.mcpManagement`：MCP 管理文档
- `managedBlock`：项目入口 MD 中可重复更新的引用块标记
- `defaults.tools`：默认写入哪些工具入口
- `defaults.mcpLinkRoot`：项目侧 MCP junction 根目录
- `godot.addonsRoot`：hub 内 Godot 插件根目录
- `godot.projectAddonsRoot`：Godot 项目侧插件目录，默认 `addons`
- `godot.defaultAddonPort`：GodotIQ 默认 WebSocket 端口起点，默认 `6007`
- `godot.mcpAddonDependencies`：MCP 与必须同时安装的 Godot 插件映射

重要：不要在技能正文里写死全局 hub 路径。需要路径时，读取配置文件。

## Principle

项目入口文件属于项目本身：

- `CLAUDE.md` 保留 Claude 侧项目规则。
- `AGENTS.md` 保留 Codex/agent 侧项目规则。
- hub 规则不展开进项目入口文件，只通过二级文档引用。

## Script Parameters

```powershell
powershell -ExecutionPolicy Bypass -File D:\AIprogram\myaitool\scripts\onboard-project.ps1 `
  -ConfigPath D:\AIprogram\myaitool\config\onboarding.json `
  [-Tools Claude|Codex|Both] `
  [-Skills @('skill1','skill2')] `
  [-McpServers @('mcp1','mcp2')] `
  [-KnowledgeCategories @('general','web','nodejs')] `
  [-GodotAddons @('godotiq','scene_bundle')] `
  [-ProjectPath <path>] `
  [-ConflictAction Error|Skip|Backup|Force] `
  [-Force]
```

**必须传 `-ConfigPath`**，否则脚本会在当前工作目录下找不到配置文件。

- `-Tools`：默认由配置文件的 `defaults.tools` 决定
- `-Skills`：指定安装哪些技能（空 = 不装任何技能）
- `-McpServers`：指定安装哪些 MCP（空 = 不装）
- `-KnowledgeCategories`：指定链接哪些 hub 知识分类到 `.shared/knowledge/hub/`（空 = 不链接）
- `-GodotAddons`：指定安装并启用哪些 Godot 插件 junction（空 = 不主动安装；MCP 依赖仍会自动加入）
- `-ConflictAction`：冲突处理方式（默认 `Error`）
  - `Error`：遇到冲突抛异常，停止执行（当前默认行为）
  - `Skip`：跳过冲突项，保留本地内容，继续安装其他项
  - `Backup`：将本地内容备份为 `.backup-时间戳`，用 hub 版本替换
  - `Force`：直接删除本地内容，用 hub 版本替换（不可恢复）
- `-Force`：等同于 `-ConflictAction Backup`（向后兼容）

## MCP Setup

`-McpServers image-recognition` 会为 Claude Code 和 Codex 分别创建 MCP 配置：

### Claude Code

创建项目侧 junction（按配置的 `defaults.mcpLinkRoot`）：

```text
<project>/.claude/mcp-servers/image-recognition → hub MCP
```

### Codex

创建项目级配置文件 `.codex/config.toml`，从 MCP server 的 `adapters/codex.md` 解析 TOML 配置追加：

```toml
[mcp_servers.image-recognition]
command = "python"
args = ["-m", "image_recognition"]
```

目标路径由配置中的 `hubRoot` 决定。该步骤只创建项目侧 MCP 配置，不写入真实密钥。

密钥必须来自用户环境变量或本机 secret manager。不要把 `MIMO_API_KEY` 写进项目文件、agent 配置或命令行参数。

### GodotIQ 联动

`-McpServers godotiq` 必须根据 `godot.mcpAddonDependencies` 自动安装
`addons/godotiq` junction，并将 `res://addons/godotiq/plugin.cfg` 幂等加入
`project.godot` 的 `[editor_plugins] enabled`，不能只注册 MCP 或只创建目录。

Claude Code 的 `.mcp.json` 和 Codex 的 `.codex/config.toml` 都必须生成：

- `command = python`
- `args = ["-m", "godotiq"]`
- `PYTHONPATH = <Godot项目根目录>/addons/godotiq`
- `GODOTIQ_ADDON_PORT = <项目配置的可用端口>`

Codex 还必须设置 `cwd = <Godot项目根目录>`。Claude Code 的 `.mcp.json`
不写 `cwd`，而是设置 `GODOTIQ_PROJECT_ROOT = <Godot项目根目录>`。

`PYTHONPATH` 指向包含 `godotiq/` Python package 的父目录，从项目插件中优先加载
MCP 实现。MCP junction 仍保留，用于 hub 文档和管理。

如果项目 `.godotiq.json` 已有 `server.addon_port`，必须保留并复用。否则从
`godot.defaultAddonPort` 起检测本机端口，选择首个可用端口并创建项目配置。
Claude Code 和 Codex 必须写入同一个 `GODOTIQ_ADDON_PORT`，保证多 Godot
编辑器同时运行时不会连接到其他项目。

## Workflow

执行 `/onboarding` 时，按 4 个阶段进行：

### Phase A — Scan（扫描）

1. 解析配置文件，读取 `hubRoot`。
2. 确认当前工作目录是目标项目根目录；如果不是，要求用户指定 `-ProjectPath`。
3. 扫描项目文件判断类型：
   - `project.godot` 存在 → Godot 项目
   - `package.json` 存在 → Web/Node.js 项目
   - 都没有 → 通用项目
4. 扫描 `<hubRoot>/skills/` 目录，读每个 `SKILL.md` 的 YAML frontmatter `description` 字段。
5. 扫描 `<hubRoot>/mcp-servers/` 目录，读每个 `MCP.md`。
6. 扫描 `<hubRoot>/knowledge/` 目录，获取子目录列表和每个子目录下的文件名（用于推荐知识分类）。
7. 如果是 Godot 项目，只扫描配置的 `godot.addonsRoot` 直接子目录；仅将根部含
   `plugin.cfg` 的目录视为插件。不要递归扫描，避免嵌套 package 被重复列出。

### Phase B — Recommend（推荐）

根据项目类型，判断哪些技能和 MCP 适用。

**通用技能（静默安装，不问用户）：**
- onboarding、summarize、recall、myplan

`experience`、`remember`、`bug-history` 仅作为已有项目的迁移期兼容入口，不再为新项目默认安装。

**按项目类型推荐的技能：**

| 信号 | 推荐技能 |
|------|----------|
| `project.godot` 存在 | godot-headless, html-to-godot-ui, generate-test |
| `package.json` 存在 | playwright-e2e-testing |
| playwright 在 devDeps | playwright-e2e-testing |
| 不确定 | 问用户 |

**交互确认：**

用 `AskUserQuestion` 展示推荐的非通用技能（多选），让用户确认/调整：
```
AskUserQuestion:
  questions:
    - question: "检测到以下技能可能适用于此项目，安装哪些？"
      header: "技能选择"
      multiSelect: true
      options:
        - label: "godot-headless"
          description: "Godot 无头模式场景加载和截图验证"
        - label: "html-to-godot-ui"
          description: "将 HTML/CSS 转换为 Godot Control 场景"
        - label: "全部安装"
          description: "安装所有推荐的技能"
```

如果有可用的 MCP，第二个问题：
```
AskUserQuestion:
  questions:
    - question: "是否安装以下 MCP 服务器？"
      header: "MCP 选择"
      multiSelect: true
      options:
        - label: "image-recognition"
          description: "图片识别 MCP"
        - label: "godotiq"
          description: "Godot 编辑器桥接；自动安装必需的 godotiq 插件"
```

如果是 Godot 项目，展示可用插件多选。插件名、description 和 version 从各插件
根部 `plugin.cfg` 读取。选择 `godotiq` MCP 时，界面必须明确说明
`godotiq` 插件会作为必需依赖一起安装，不再要求用户重复选择。

**知识分类推荐：**

根据项目特征推荐 hub 知识分类，AI 灵活判断。参考映射：

| 项目特征 | 推荐知识分类 |
|----------|--------------|
| Godot 项目 | godot, general |
| Web 前端/Node.js | web, nodejs, general |
| 纯 Node.js 后端 | nodejs, general |
| 通用 | general |

AI 应深入分析项目代码（依赖、import、技术栈），而非仅看顶层信号。例如：
- 项目虽有 `package.json` 但主要做 WebSocket 服务 → 推荐 `nodejs`，可选 `web`
- Godot 项目用了 GDScript 调用外部 API → 推荐 `godot`, `general`

与技能推荐合并在同一个 `AskUserQuestion` 中展示（作为第三个问题）：
```
AskUserQuestion:
  questions:
    - question: "检测到以下知识分类可能适用于此项目，链接哪些？"
      header: "知识分类"
      multiSelect: true
      options:
        - label: "general"
          description: "通用技术经验（Windows 进程、DLL、设计模式）"
        - label: "godot"
          description: "Godot 引擎经验（调试、UI、战斗逻辑）"
        - label: "全部链接"
          description: "链接所有推荐的知识分类"
```

**冲突预检：**

在执行安装前，扫描项目中以下路径，检测是否已有本地内容（非 junction）与要安装的 skills/knowledge/MCP 同名：
- `.claude/skills/<name>`
- `.codex/skills/<name>`
- `.shared/knowledge/hub/<category>`
- `.claude/mcp-servers/<name>`
- `addons/<godot-addon-name>`

如果发现冲突，用 `AskUserQuestion` 列出冲突项并让用户选择处理方式：
```
AskUserQuestion:
  questions:
    - question: "检测到以下本地资产与 hub 同名，如何处理？\n\n- .claude/skills/onboarding/ (3 files)\n- .shared/knowledge/hub/general/ (5 files)"
      header: "冲突处理"
      multiSelect: false
      options:
        - label: "保留本地（推荐）"
          description: "跳过冲突项，保留项目已有内容。其他无冲突项正常安装。"
        - label: "备份后替换"
          description: "将本地内容备份为 .backup-时间戳，用 hub 版本替换"
        - label: "全部替换"
          description: "删除本地内容，用 hub 版本替换（此操作不可恢复）"
```

如果无冲突，不弹出此问题，直接执行。

### Phase C — Execute（执行）

调用脚本，传入选中的技能和 MCP：

```powershell
powershell -ExecutionPolicy Bypass -File D:\AIprogram\myaitool\scripts\onboard-project.ps1 `
  -ConfigPath D:\AIprogram\myaitool\config\onboarding.json `
  -Tools <tools> `
  -Skills @('onboarding','summarize','recall','myplan','<user-selected>') `
  -McpServers @('<user-selected>') `
  -KnowledgeCategories @('<user-selected>') `
  -GodotAddons @('<user-selected>') `
  -ConflictAction <user-choice>
```

`godot.mcpAddonDependencies` 中声明的依赖由脚本自动合并。例如选择
`-McpServers godotiq` 即使没有显式传 `-GodotAddons godotiq`，也必须创建：

```text
<project>/addons/godotiq → <hubRoot>/godot/addons/godotiq
```

随后必须保留已有 editor plugin 条目，并将插件路径加入 `project.godot`：

```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/godotiq/plugin.cfg")
```

重复执行不得产生重复插件路径。

`-ConflictAction` 根据用户在冲突预检中的选择传入：
- 选择"保留本地" → `-ConflictAction Skip`
- 选择"备份后替换" → `-ConflictAction Backup`
- 选择"全部替换" → `-ConflictAction Force`
- 无冲突时 → 不传此参数（默认 `Error`，遇到冲突报错停止）

### Phase D — Verify（验证）

1. 读取项目 `CLAUDE.md` / `AGENTS.md`，确认 managed block 存在且没有重复。
2. 确认技能 junction 创建成功：`.claude/skills/<name>/SKILL.md` 和 `.codex/skills/<name>/SKILL.md` 可读取。
3. 如果安装了 MCP：
   - Claude Code：确认 `.mcp.json` 存在且包含正确的 MCP 条目（command、args 用相对路径）
   - Claude Code：确认 `.claude/mcp-servers/<name>/MCP.md` 可读取
   - Codex：确认 `.codex/config.toml` 包含 `[mcp_servers.<name>]` 条目
4. 如果安装了知识分类：确认 `.shared/knowledge/hub/<category>` junction 可读取。
5. 如果安装了 Godot 插件：
   - 确认 `addons/<name>/plugin.cfg` 可读取且 junction 指向 hub。
   - 确认 `project.godot` 的 `[editor_plugins] enabled` 包含且只包含一次对应插件路径。
   - godotiq 还要确认 `addons/godotiq/godotiq/__main__.py` 可读取。
   - 确认 `.godotiq.json` 的 `server.addon_port` 与两个 MCP 配置一致。
   - Claude Code：确认 `.mcp.json` 的 `GODOTIQ_PROJECT_ROOT`、`PYTHONPATH` 和 `python -m godotiq`。
   - Codex：确认 `.codex/config.toml` 的 `cwd`、`PYTHONPATH` 和 `python -m godotiq`。
6. 汇总结果，包括：
   - 已安装的 skills、knowledge、MCP
   - 跳过的冲突项（skipped-local / skipped-different）
   - 备份的路径（如有），附恢复说明：
     ```
     如需恢复备份：删除 junction，然后将 .backup-时间戳 重命名回原名
     ```

## Managed Block

脚本只管理配置文件中 `managedBlock.start` 到 `managedBlock.end` 之间的块。

重复运行时替换该块，不追加重复内容。块外内容必须保持不动。

## Optional Asset Review

如果用户要求”归档项目已有技能/经验到 hub”，再执行资产审查：

- 扫描 `.claude/skills/*/SKILL.md`、`.codex/skills/*/SKILL.md`、`.claude/commands/*.md`、`.shared/knowledge/**/*.md`、`~/.claude/memory/**/*.md`。
- 区分项目特定资产和可共享资产。
- 归档前必须让用户确认。
- 项目特定资产保持在项目内，不迁入 hub。
- 可共享技能进入 `<hubRoot>/skills/`。
- 可共享知识进入 `<hubRoot>/knowledge/` 并更新 `knowledge/INDEX.md`。

## Safety Notes

- 不覆盖项目入口文件，只 upsert managed block。
- 不把 hub 规则全文复制进项目入口文件。
- 不把密钥写入任何仓库文件、agent 配置、manifest 或命令行示例。
- Godot 插件固定使用 junction（Windows 等价于 `mklink /J`），不复制插件快照；安装后自动启用。
- godotiq MCP 与 godotiq 插件是不可拆分依赖；安装 MCP 时必须先确保插件 junction 可用。
- **本地优先**：遇到本地已有同名内容时，默认停止（`-ConflictAction Error`）；只有用户明确选择后才跳过/备份/替换。
- 执行任何归档、删除、替换本地资产前，必须先展示冲突列表并获得用户确认。
- `Force` 模式使用 `Remove-Item -Recurse`，文件永久删除不可恢复，必须在 AskUserQuestion 中明确告知用户。
