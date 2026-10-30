# 单人模式与操作选择验收证据索引

文档角色：`verification_evidence_index`

本目录保存已执行的 Gate 报告、截图与机器可读证据。

| Gate | 当前状态 | 计划报告 | 通过条件 |
|---|---|---|---|
| Gate 0 增量基线 | [已完成] | `Gate0_增量基线报告.md` | 旧双人自动/E2E 绿色，修改面完整 |
| Gate 1 契约冻结 | [已完成] | `Gate1_契约冻结报告.md` | 三份契约 frozen，P0 覆盖完整 |
| Gate 2 模式闭环 | [已完成] | `Gate2_模式闭环报告.md` | 模式选择、单人/双人单局和生命周期通过 |
| Gate 3 输入与界面 | [已完成] | `Gate3_输入与界面报告.md` | 三种操作路径、HUD、暂停、结果和布局通过 |
| Gate 4 最终验收 | [已完成] | `Gate4_最终验收报告.md` | 全量测试、E2E、soak、性能、双构建和文档通过 |

## 计划附属证据

```text
验收/
├── screenshots/
│   ├── mode_select_1280x720.png
│   ├── single_mouse_1280x720.png
│   ├── single_keyboard_1280x720.png
│   ├── dual_keyboard_1280x720.png
│   └── single_result_1280x720.png
├── playwright_modes.json
├── soak_single_10min.json
├── soak_dual_10min.json
└── performance_probe.json
```

## 记录规则

1. 报告必须写明日期、精确命令、退出码、重要输出和证据相对路径。
2. 模板、计划或预期结果不算实际证据。
3. 失败项必须记录严重度、Owner、返工任务和状态，不得删除失败历史。
4. 浏览器用例必须保留 `pageerror` 和 console error 严格断言，不得以过滤产品错误通过。
5. 只有全部必选项通过且无未解决 P0 blocker 时，Gate 才能标记 `[已完成]`。
