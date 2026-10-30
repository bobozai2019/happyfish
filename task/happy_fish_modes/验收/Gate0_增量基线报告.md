# Gate 0 增量基线报告

文档角色：`verification_evidence`

状态：[已完成]

日期：2026-08-08

范围：T00 增量侦察与回归基线

## 结论

- 当前双人 Godot 启动、旧自动测试、Chrome 布局与双输入回归、Windows 现有构建 smoke 全部通过。
- Web 构建由两条 Chrome E2E 实际加载，所有入口、脚本、PCK、WASM 和音频 worklet 请求成功，未出现页面或控制台错误。
- 模式化修改面已覆盖 Session、Cannon、Spawn、UI、场景、测试和设计文档；T00 未修改产品实现。
- Gate 0 通过，可以进入 T01 契约冻结。

## 环境与入口

| 项 | 当前值 |
|---|---|
| Godot | `4.7.beta.custom_build.dff2b9bb6` |
| 主场景 | `res://scenes/game/main.tscn` |
| Renderer | GL Compatibility |
| Physics | Jolt Physics |
| Windows preset | `Windows Desktop`，runnable |
| Web preset | `Web`，runnable |
| Playwright | 1.62.1，Google Chrome channel，headless，workers=1 |
| Web URL | `http://127.0.0.1:8060/index.html` |

## 修改面清单

| 边界 | 当前硬编码/耦合 | 主要位置 | 后续任务 |
|---|---|---|---|
| 玩家集合 | 多处固定遍历 `[1, 2]` | `scripts/game/session_state.gd`、`scripts/ui/ui_controller.gd`、`tests/soak_10min.gd` | T03/T05/T06 |
| P2 节点 | Session 固定 `p2_cannon_path` 和 `P2Cannon` | `scripts/game/session_state.gd`、`scenes/game/main.tscn` | T02/T03 |
| 双人结果 | 必须两人都耗尽；结果页固定 P1/P2 标签 | `scripts/game/session_state.gd`、`scripts/ui/ui_controller.gd`、`scenes/ui/results_overlay.tscn` | T03/T05 |
| Boss 阈值 | `FIRST_BOSS_CAPTURES := 18` | `scripts/game/spawn_director.gd`、`tests/test_gameplay_objects.gd` | T03 |
| 原始输入 | Cannon 直接读取 aim/level/fire；Session 直接读取 pause/restart | `scripts/game/cannon_controller.gd`、`scripts/game/session_state.gd` | T04 |
| HUD | 固定 P1/P2 panel、PauseButton 和结果节点路径 | `scripts/ui/ui_controller.gd`、`scenes/ui/hud.tscn`、`scenes/ui/results_overlay.tscn` | T05 |
| 双人测试夹具 | 输入、soak、截图、HUD 断言均假设双人 | `tests/test_gameplay_objects.gd`、`tests/test_ui_flow.gd`、`tests/soak_10min.gd`、`tests/capture_screenshots.gd` | T03-T06 |
| 应用入口 | 启动即进入战斗，无应用壳或选择页 | `project.godot`、`scenes/game/main.tscn` | T02 |
| 设计文档 | 当前仅描述双人已实现设计 | `docs/gamedesign/` | T06 |

冻结数值核对：鱼类奖励、炮倍概率、个人保底公式、初始 120 金币、一次 30 金币救援和双人经济未在 T00 改动。

## 命令与实际结果

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `godot --version` | 0 | `4.7.beta.custom_build.dff2b9bb6` |
| `godot --headless --path . --quit-after 1` | 0 | 启动成功，无解析错误 |
| `godot --headless --path . --script res://tests/run_all.gd` | 0 | `PASS: Gate 1-2、T05 捕获经济与 T06 HUD/暂停/结果流程校验通过` |
| `npx playwright test tests/e2e/chrome_layout.spec.ts --project=chrome` | 0 | `1 passed (18.1s)` |
| `npx playwright test tests/e2e/chrome_input_audio.spec.ts --project=chrome` | 0 | `1 passed (13.3s)` |
| Windows 构建隐藏启动 8 秒 | 0 | 进程持续存活，smoke pass |
| `rg -n "\\[1, 2\\]|get_player\\(2\\)|p2_|Input\\." scripts scenes tests` | 0 | 已定位玩家、P2、直接 Input 与双人测试依赖 |

Playwright 为避免覆盖 `task/happy_fish/` 历史截图，在隔离副本 `D:\godot\project\happy-fish_modes_t00_e2e` 中串行执行；原仓库产品代码和历史验收记录未被改写。

## 当前构建清单

| 产物 | 字节数 | SHA-256 | Smoke |
|---|---:|---|---|
| `build/windows/happy_fish.exe` | 117741168 | `6417faa95aa2e34be67942af7c9d3b9b4ff8ec45ad5b5785e1093c73e1d88a2b` | pass，存活 8 秒 |
| `build/web/index.html` | 5442 | `8ed34ddb6acc5891fad035aaa7df567a3ff2956c92fa837a342ab90777e2a1ab` | pass，Chrome 加载 |
| `build/web/index.js` | 357272 | `bd4b42cf7c880b10c7d8be68c275cda74d0a03bed069cf4551e9cc3db3e73643` | pass，HTTP 200 |
| `build/web/index.wasm` | 36955439 | `2ce97d19463652eda8abaf3bd72f33fd03720b1f85713282290979f725262fc6` | pass，HTTP 200 |
| `build/web/index.pck` | 14718052 | `4bb202966da7ab84caed6e36a09dc83ee731d23b8ba3e4fb5c8249bddf882528` | pass，HTTP 200 |

## 风险与后续约束

1. 当前命令行 Godot 是 4.7 beta custom build，而旧 Gate 4 记录使用 `4.7.1.stable.official.a13da4feb`。增量开发可继续，但 T06 正式构建必须改用兼容的 4.7 stable 并重新执行完整验证。
2. Windows 构建哈希与旧 Gate 4 一致；当前 Web 构建哈希与旧报告不同。当前 Web 产物已通过 Chrome 基线，但 T06 不得复用旧哈希结论，必须重新导出并记录新产物。
3. 本目录不是 Git checkout，无法用 Git index 证明零实现改动；T00 只写入本任务的执行状态与验收报告，所有产品检查均为只读。

