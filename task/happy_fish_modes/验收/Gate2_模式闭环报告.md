# Gate 2 模式闭环报告

文档角色：`verification_evidence`

状态：[已完成]

日期：2026-08-08

范围：T02 应用流程与模式选择、T03 单人单局与模式化规则

## 结论

- 启动只创建应用壳和模式选择页，确认前无战斗实例、鱼群、BGM 或 Boss 计时。
- 单人只创建 P1 PlayerState，P1 炮台位于 `(640, 670)`，P2 炮台隐藏、禁用且无经济/统计状态。
- 双人继续创建 P1/P2，炮台保持 `(256, 670)` 与 `(1024, 670)`，旧双人测试全部通过。
- 单人首次 Boss 捕获阈值 10、双人 18；60 秒、2 秒预告和 90 秒冷却保持原值。
- 单人使用 120 初始金币、一次 30 金币救援；第二次耗尽且 pending 为 0 后进入 RESULTS。
- 重开保留配置并清理运行对象；返回选择销毁战斗，连续三轮无实例泄漏。

## Active players 改造位置

| 位置 | 改造 |
|---|---|
| `SessionState._ready()` | 仅连接 active cannon，配置单/双人 Boss 阈值 |
| `SessionState.start_new_session()` | 仅创建 active PlayerState 并重置 active cannon |
| `SessionState.evaluate_player_exhaustion()` | inactive id 直接拒绝 |
| `SessionState._on_fish_captured()` | 捕获总数改为 active players 求和 |
| `SessionState._evaluate_results()` | 通用 all-active-exhausted + pending=0 |
| `SessionState.transition_to()` | 只启用 active cannon，RESULTS 停止 SpawnDirector |
| `UIController.refresh_all()` | 固定节点映射只用于显隐；数据循环使用 active ids |
| `UIController._update_results()` | 只读取 active players，单人不解引用 P2 |

## 验证结果

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `godot --headless --editor --path . --quit` | 0 | Session、Spawn、UI 脚本导入成功 |
| `godot --headless --path . --script res://tests/run_all.gd` | 0 | `PASS: 旧双人回归与 Gate 2 模式闭环校验通过` |
| `godot --headless --path . --quit-after 1` | 0 | 模式选择主场景启动成功 |
| `rg` 固定双人依赖复核 | 0 | Session 逻辑循环均已 active 化；UI `[1,2]` 仅保留固定节点显隐映射 |

新增自动边界覆盖：单人/双人 active ids、inactive P2 null、炮台位置与禁用、Boss 9→10 和双人 18、单人救援与结果、配置副本、三轮 start/return 生命周期。

## 契约与数值

- frozen 契约无变化。
- `capture_service.gd`、鱼类资源、炮台资源、捕获概率和 3/5/7 保底规则未修改。

