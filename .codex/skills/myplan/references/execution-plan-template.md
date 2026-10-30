# MyPlan Executable Plan Template

Use this template to convert a product idea, HTML plan, PRD, or rough requirement into an executable implementation package.

## Recommended File Structure

```text
task/<project_slug>/
├── 总纲.md
├── 需求映射.md
├── 执行状态.md
├── 决策记录.md
├── 契约/
│   ├── README.md
│   ├── API契约.md
│   ├── 数据库契约.md
│   ├── 前端路由与E2E契约.md
│   └── 任务状态机契约.md
├── 细则/
│   ├── README.md
│   ├── T00_仓库侦察与执行基线.md
│   ├── T01_技术栈与项目骨架.md
│   └── ...
└── 验收/
    ├── Gate0_验收报告.md
    ├── Gate1_契约冻结报告.md
    └── GateN_最终验收报告.md
```

Optional files:

- `风险登记.md`: add only for long-running, compliance-heavy, or operations-heavy projects.
- `归档/`: move superseded generated task plans here.

## 总纲.md

````markdown
# [未开始] <项目名> 执行总纲

来源文档：
- `<source path or prompt summary>`

任务目标：
- <one paragraph explaining the executable outcome>

## 0. 总体进度

| 层级 | 对象 | 状态 | 进度 | 当前说明 | 证据 |
|---|---|---|---:|---|---|
| 总纲 | <项目名> | [未开始] | 0% | 尚未进入执行 | - |
| Gate | Gate 0 仓库侦察 | [未开始] | 0% | 等待启动 | - |
| Gate | Gate 1 契约冻结 | [未开始] | 0% | 依赖 Gate 0 | - |

状态枚举：

- [未开始]：任务尚未启动。
- [进行中]：正在实现或正在验收。
- [已完成]：实现和验收证据均完成。
- [阻塞]：缺输入、依赖或外部条件。
- [需返工]：验收失败，等待修复。
- [暂停]：人为暂停，不等于阻塞。
- [已跳过]：明确不纳入当前范围。

## 1. 文档角色

| 文档 | 角色 | 说明 |
|---|---|---|
| `<source>` | source_plan | 原始产品/业务计划，只读 |
| `总纲.md` | execution_plan | 主 agent 调度入口 |
| `需求映射.md` | traceability | 需求到任务/契约/验收的映射 |
| `契约/*` | contract | 冻结跨任务边界 |
| `执行状态.md` | execution_state | 进度、锁、冻结状态、决策摘要 |
| `验收/*` | verification_evidence | 实际命令、结果、截图、测试输出 |
| `<old task doc>` | archive/draft | 历史草稿，不作为当前执行依据 |

## 2. MVP 边界

### 必须完成

1. <MVP item>

### 占位但不验收

1. <placeholder item>

### vNext

1. <future item>

### 明确不做

1. <non-goal>

## 3. 范围口径表

| 项目 | 分类 | 当前结论 | 说明 |
|---|---|---|---|
| `/example` | MVP / placeholder / vNext / out_of_scope | <结论> | <原因> |
| `cancelled` 状态 | vNext | MVP 不实现取消接口 | 仅保留预留说明 |

## 4. 运行模式矩阵

| 模式 | 依赖 | 启动方式 | 验收口径 | 适用场景 |
|---|---|---|---|---|
| local_demo | SQLite / memory broker / mock service | <commands> | 功能闭环可演示 | 快速开发 |
| docker_mvp | PostgreSQL / Redis / app services | <commands> | MVP 集成验收 | 本机完整验证 |
| production | Managed DB / durable queue / observability | <commands or TBD> | 稳定性、备份、监控 | 上线 |

## 5. 执行依赖 DAG

| 任务 | 名称 | 状态 | 依赖 | 进度 | 说明 |
|---|---|---|---|---:|---|
| T00 | 仓库侦察与执行基线 | [未开始] | - | 0% | 明确项目现状 |
| T01 | 技术栈与项目骨架 | [未开始] | T00 | 0% | 建立可运行骨架 |
| T02 | 数据库契约与迁移 | [未开始] | T01 | 0% | 冻结数据边界 |
| T03 | 基础 API 与领域模型 | [未开始] | T02 | 0% | 冻结基础 API |
| T04 | 后台任务/状态机 | [未开始] | T03 | 0% | 队列、调度、重试 |
| T05 | 数据采集或核心业务实现 | [未开始] | T04 | 0% | 核心业务闭环 |
| T06 | 聚合/分析/业务 API | [未开始] | T05 | 0% | 看板/分析数据 |
| T07 | 前端信息架构与布局 | [未开始] | T03 | 0% | 可与 T04 并发 |
| T08-T10 | 业务页面/工作流 | [未开始] | T06/T07 | 0% | 用户可操作页面 |
| T11 | 集成、验收、文档 | [未开始] | T08-T10 | 0% | 最终验收 |

## 6. 谨慎并发窗口

允许并发：

1. API 契约冻结后，前端布局可使用 mock 并发。
2. 数据库契约冻结后，API 与非共享 UI 可并发。
3. 响应结构冻结后，图表/列表组件可并发。

禁止并发：

1. Schema 未冻结时并发改 API、Worker、前端数据模型。
2. 多个 subagent 同时修改同一文件或同一契约。
3. 任务状态机和任务中心 UI 契约同时变化。

## 7. Gate 门禁

### Gate 0：仓库侦察完成

验收：
- [ ] 明确当前仓库状态
- [ ] 明确技术栈和约束
- [ ] 明确启动、测试、格式化命令草案

### Gate 1：契约冻结完成

拆成：
- Gate 1A 数据库契约
- Gate 1B API/状态机契约
- Gate 1C 前端路由/E2E 契约

验收：
- [ ] 字段级契约完整
- [ ] API request/response/error/pagination/sort 白名单明确
- [ ] 页面、路由、空/错/加载状态明确

### Gate N：最终验收完成

验收：
- [ ] 功能验收通过
- [ ] 数据验收通过
- [ ] 体验验收通过
- [ ] 单点失败不导致整体崩溃

## 8. Subagent 上下文包模板

```text
你是本任务唯一 subagent。请只处理本任务范围，不修改其他任务文件。

项目目标：
- <goal>

当前阶段：
- <Gate and status, such as Gate 1A [进行中]>

依赖输入：
- <completed artifacts>
- <frozen contracts>

你的任务：
- <task objective>

交付物：
- <files or behavior to produce>

允许修改：
- <paths>

禁止修改：
- <paths/contracts>

影响面：
- <who consumes this work>

验收标准：
- <copy task acceptance criteria>

验收证据：
- <commands, screenshots, reports expected>

回报格式：
- 完成内容
- 修改文件
- 小目标进度更新
- 验证命令与结果
- 契约变化
- 风险与遗留
- 需要主 agent 验收的点
````

## 需求映射.md

```markdown
# <项目名> 需求映射

| ID | 来源章节/原文摘要 | 优先级 | 范围分类 | 对应任务 | 对应契约 | 验收方式 | 当前状态 |
|---|---|---|---|---|---|---|---|
| R-001 | <source section> | P0 | MVP | T03/T08 | API契约/前端契约 | curl + E2E | planned |
| R-002 | <source section> | P1 | vNext | - | - | 不纳入 MVP | deferred |

## 覆盖检查

- [ ] 所有 P0 需求都有任务编号
- [ ] 所有跨模块需求都有契约
- [ ] 所有验收标准可用命令、SQL、E2E、截图或人工步骤验证
- [ ] 所有延期项有延期原因
```

## 决策记录.md

Keep this short. Record decisions that change execution or contracts.

```markdown
# 决策记录

## ADR-001：<decision title>

- 日期：YYYY-MM-DD
- 状态：accepted / superseded / proposed
- 背景：<why this decision exists>
- 决策：<what is decided>
- 影响：<tasks/contracts affected>
- 后续：<follow-up if any>
```

Recommended initial ADRs:

1. Runtime modes: local demo vs docker MVP vs production.
2. Placeholder/vNext scope: routes, states, APIs, or modules not in MVP.
3. Source/archive roles for older planning documents.

## 契约/API契约.md

Contract files must describe boundaries precisely enough that independent agents can implement against them.

````markdown
# API 契约

状态：draft / frozen

## 通用约定

- Base path: `/api`
- Error shape:

```json
{
  "code": "string",
  "message": "string",
  "details": {}
}
```

- Pagination shape:

```json
{
  "items": [],
  "page": 1,
  "page_size": 20,
  "total": 0
}
```

## Endpoint Template

### `<METHOD> <PATH>`

Owner task: `Txx`

Purpose:
- <what this endpoint enables>

Request:

| Field | Type | Required | Default | Validation | Notes |
|---|---|---:|---|---|---|
| `field` | string | yes | - | non-empty | <notes> |

Query params:

| Param | Type | Required | Allowed values | Notes |
|---|---|---:|---|---|
| `sort` | string | no | `a`, `b` | Explicit whitelist |

Response `200`:

| Field | Type | Required | Notes |
|---|---|---:|---|
| `id` | integer | yes | <notes> |

Errors:

| HTTP | Code | When |
|---:|---|---|
| 400 | `invalid_request` | <condition> |
| 404 | `not_found` | <condition> |

Acceptance:

```bash
curl -f <url>
```
````

If OpenAPI is generated, link the generation command and freeze the generated schema at Gate 1B.

## 契约/数据库契约.md

````markdown
# 数据库契约

状态：draft / frozen

## Tables

### `<table_name>`

Purpose:
- <why this table exists>

Fields:

| Field | Type | Null | Default | Constraint | Notes |
|---|---|---:|---|---|---|
| `id` | bigint | no | generated | primary key | - |

Indexes:

| Name | Fields | Purpose |
|---|---|---|
| `<index>` | `(field, created_at desc)` | <query supported> |

Acceptance SQL:

```sql
-- check table, indexes, constraints, and key insert/update behavior
```
````

## 契约/前端路由与E2E契约.md

````markdown
# 前端路由与 E2E 契约

状态：draft / frozen

## Route Matrix

| Route | Classification | Page/Feature | API dependencies | Required states | E2E owner |
|---|---|---|---|---|---|
| `/` | MVP | Dashboard | `/api/...` | loading/empty/error/success | Txx |
| `/settings` | vNext | Settings | - | placeholder only or not implemented | - |

## Viewports

- Desktop: 1440x900
- Mobile: 390x844

## E2E Acceptance

1. <step>
2. <assertion>
````

## 执行状态.md

````markdown
# <项目名> 执行状态

## 状态枚举

只使用以下 bracketed 状态：

- [未开始]
- [进行中]
- [已完成]
- [阻塞]
- [需返工]
- [暂停]
- [已跳过]

## 当前 Gate

- 状态：Gate 0 / Gate 1A / ... [未开始]
- 最近验收：<date and link to 验收 report>

## 总纲进度

| 对象 | 状态 | 进度 | 当前重点 | 最近更新 | 证据 |
|---|---|---:|---|---|---|
| <项目名> | [未开始] | 0% | 等待启动 | YYYY-MM-DD | - |

## 大任务进度

| 任务 | 名称 | 状态 | 小目标 | 已完成 | 进度 | 当前说明 | 负责人 | 验收证据 |
|---|---|---|---:|---:|---:|---|---|---|
| T00 | 仓库侦察与执行基线 | [未开始] | 5 | 0 | 0% | 等待执行 | Subagent-00 | - |
| T01 | 技术栈与项目骨架 | [未开始] | 6 | 0 | 0% | 依赖 T00 | Subagent-01 | - |

## 已冻结契约

| 契约 | 文件 | 状态 | 冻结任务 | 证据 |
|---|---|---|---|---|
| API | `契约/API契约.md` | draft/frozen | T03 | `验收/Gate1_契约冻结报告.md` |

## Active Locks

| Subagent | 任务 | 允许修改 | 禁止修改 | 状态 |
|---|---|---|---|---|

## 任务完成状态

| 任务 | 名称 | 状态 | 完成时间 | 验收证据 |
|---|---|---|---|---|
| T00 | 仓库侦察与执行基线 | [未开始] | - | - |

## 小目标进度索引

| 任务 | 小目标 | 状态 | 说明 | 证据 |
|---|---|---|---|---|
| T00 | G01 扫描仓库目录 | [未开始] | - | - |
| T00 | G02 判断现有技术栈 | [未开始] | - | - |

## 决策摘要

| ADR | 决策 | 影响 |
|---|---|---|
````

## 细则/Txx Template

````markdown
# Txx <任务名称>

负责人：Subagent-xx

任务状态：[未开始]
任务进度：0%

依赖：
- <dependencies>

可并发：
- <if any>

## 目标

<one paragraph>

## 小目标进度

| ID | 小目标 | 状态 | 交付物/证据 | 备注 |
|---|---|---|---|---|
| G01 | <small goal> | [未开始] | - | - |
| G02 | <small goal> | [未开始] | - | - |

## 输入上下文

1. `<file>`

## 交付物

1. <artifact>

## 允许修改

1. `<path>`

## 禁止修改

1. `<path or contract>`

## 实施内容

1. [未开始] <implementation item>

## 验收标准

1. <verifiable criterion>

## 验收命令

```bash
<command>
```

## 回报要求

- 完成内容
- 修改文件
- 小目标进度：逐项说明 Gxx 从什么状态变为什么状态
- 验证命令与结果
- 契约变化
- 风险与遗留
- 验收证据路径
````

## 验收/Gate Report Template

````markdown
# Gate <N> 验收报告

日期：YYYY-MM-DD
范围：<Gate scope>

## 结论

- 通过 / 未通过 / 部分通过

## 验收项

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| <item> | <criterion> | <command/log/screenshot> | pass/fail |

## 命令与结果

```bash
<command>
# <important output summary>
```

## 问题与返工

| 问题 | 严重度 | 负责人 | 状态 |
|---|---|---|---|
````

## Generation Checklist

Before finalizing a plan:

- [ ] MVP, placeholder, vNext, and out-of-scope are separated.
- [ ] Every P0 requirement maps to tasks and validation.
- [ ] Overall plan status uses bracketed Chinese status labels.
- [ ] Every major task has a status, percent, owner, and evidence link.
- [ ] Every task file has a small-goal progress table.
- [ ] Contract files are boundaries, not status reports.
- [ ] API contracts include field-level request/response/error shapes.
- [ ] Runtime modes are explicit when dependencies differ.
- [ ] Verification evidence has a destination under `验收/`.
- [ ] Old generated docs are labeled as source/draft/archive.
- [ ] Task files have clear write ownership and forbidden areas.
