# Gate 1 契约冻结报告

文档角色：`verification_evidence`

状态：[已完成]

日期：2026-08-08

范围：T01 模式、输入与 UI 契约冻结

## 结论

- 三份增量契约及契约索引已从 `draft` 冻结为 `frozen`。
- R-001 至 R-019 均有任务、契约入口和可执行验收；所有 P0 需求无遗漏。
- external API、数据库、账号与云存档明确为 out_of_scope，`ConfigFile` 持久化明确为 vNext。
- Gate 1 通过；后续字段、信号或跨任务语义变更必须新增 ADR。

## 冻结对象

| 契约 | 状态 | 本轮补强 |
|---|---|---|
| `契约/游戏模式与流程契约.md` | frozen | `validate()`、失败返回、battle scene、模式选择 API、稳定节点语义、pre-ready 注入 |
| `契约/单局规则契约.md` | frozen | `configure() -> bool`、inactive player、配置时机、Boss 模式阈值 API |
| `契约/输入与UI契约.md` | frozen | Router 失败行为、Cannon 命令语义、事件消费/释放、UI 对外信号、canvas E2E 可观测性 |
| `契约/README.md` | frozen | 外部接口、持久化和历史契约边界保持不变 |

## Gate 1 核对

| 条目 | 结果 | 证据 |
|---|---|---|
| `GameMode` / `SinglePlayerControl` 合法值与默认值 | pass | 游戏模式与流程契约 §1 |
| `GameSessionConfig` 字段、派生 API、复制、校验和错误行为 | pass | 游戏模式与流程契约 §1 |
| MODE_SELECT / PLAYING 转换与战斗生命周期 | pass | 游戏模式与流程契约 §2-§8 |
| active players、经济、结果、Boss 阈值 | pass | 单局规则契约 §1-§10 |
| 键盘、鼠标、HUD 和 held 清理 | pass | 输入与 UI 契约 §1-§4 |
| 页面可见性、暂停切换、返回确认和响应布局 | pass | 输入与 UI 契约 §5-§6 |
| 五条模式 E2E 用户旅程 | pass（计划完整） | 输入与 UI 契约 §7-§8 |
| API / DB / 持久化排除 | pass | 契约 README |
| R-001 至 R-019 追踪 | pass | `需求映射.md` |

“pass（计划完整）”仅表示验收边界已冻结，不代表产品实现已经通过；实际结果将在 Gate 2-Gate 4 记录。

## 验证命令与结果

```powershell
rg -n "状态：`draft`|TODO|TBD" task/happy_fish_modes/契约
# 无匹配：NO_DRAFT_TODO_TBD

rg -n "\| R-0(0[1-9]|1[0-9]) .*\| P0 \|" task/happy_fish_modes/需求映射.md
# R-001..R-016、R-018 的全部 P0 行均有任务、契约和计划验收

rg -n "HTTP API|数据库|ConfigFile|out_of_scope|vNext" task/happy_fish_modes/契约 task/happy_fish_modes/需求映射.md
# 排除项与延期项均有明确匹配
```

## ADR 变化

- 无新增产品决策；ADR-001 至 ADR-006 保持 accepted。
- 本轮补充的是已接受决策的字段级和错误行为细化，不改变 MVP 范围、数值或用户流程。

