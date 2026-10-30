# Gate 1 契约冻结报告

文档角色：`verification_evidence`

状态：[已完成]

日期：2026-08-08

范围：T02 与 `契约/`

## 结论

- T02 [已完成]：typed 数据类型、12 个数据资源、PlayerState 与自动校验入口已实现。
- Gate 1 [已完成]：数据、状态与信号、输入与平台、UI/E2E 四份契约均冻结。
- 奖励、概率、生成权重、速度、炮台倍率和捕获规则均与总纲一致；碰撞半径与显示比例仍按冻结契约由 T07 依据原型图像边界调整。

## 验收项

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| FishDefinition | 字段、类型、校验和 9 个资源完整 | `scripts/data/fish_definition.gd`；9 个 fish `.tres` 全部加载并执行 `validate()` | pass |
| CannonDefinition | 字段与 1×/2×/5× 数值一致 | `scripts/data/cannon_definition.gd`；3 个 cannon `.tres` 固定值测试 | pass |
| PlayerState | 初值和不变量明确 | 初始 120 金币、扣费、pending 成对、捕获统计、非负约束测试 | pass |
| 状态与信号 | 转换、参数、时序和失败模式明确 | `契约/游戏状态机与信号契约.md` | pass |
| 捕获公式 | RNG、稳定排序、保底与原子归属明确 | 冻结契约第 4 节；固定 RNG 注入边界已保留给 T05 | pass |
| 输入与平台 | InputMap、画布、PC/Web 约束明确 | 12 个动作均存在默认按键；Gate 0 双平台实际导出通过 | pass |
| UI/E2E | 所有必需状态与验收步骤明确 | `契约/UI与E2E契约.md` | pass |
| 外部接口 | API、数据库、存档明确 out_of_scope | `契约/README.md` | pass |
| 资源规则 | 目录索引完整且不混放 | `resources/index.md` 与 `resources/data/**/index.md` | pass |

## 命令与结果

```powershell
godot --headless --editor --path . --quit
# exit 0；FishDefinition、CannonDefinition、PlayerState 全局类注册成功

godot --headless --path . --script res://tests/run_all.gd
# exit 0；PASS: 主场景骨架、InputMap、12 个数据资源与 PlayerState 校验通过

godot --headless --path . --quit-after 1
# exit 0；主场景启动无解析错误
```

## 契约冻结记录

| 契约 | 冻结版本/日期 | 证据 | 结果 |
|---|---|---|---|
| `游戏数据契约.md` | 2026-08-08 | 资源与字段固定值测试 | frozen |
| `游戏状态机与信号契约.md` | 2026-08-08 | 状态、信号、捕获和经济边界完整 | frozen |
| `输入与平台契约.md` | 2026-08-08 | InputMap 与 Gate 0 导出证据 | frozen |
| `UI与E2E契约.md` | 2026-08-08 | 界面矩阵与 E2E-01 至 E2E-05 | frozen |

## 问题与返工

| 问题 | 严重度 | 负责人 | 返工任务 | 状态 |
|---|---|---|---|---|
| 鱼动画当前只有可替换的空 `swim` SpriteFrames，炮弹与开炮音频为 typed 占位引用 | 低 | 主 agent | T03/T07 | planned |
