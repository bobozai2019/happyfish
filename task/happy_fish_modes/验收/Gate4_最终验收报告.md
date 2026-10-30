# Gate 4 最终验收报告

文档角色：`verification_evidence`

日期：2026-08-09

范围：T06 集成验收、稳定性、性能、Windows/Web 构建、设计文档与逐需求审计

结论：Gate 4 `[已完成]`。R-001 至 R-019 均有实现和实际验收证据；无未解决 P0 blocker。

## 1. 固定环境

- 引擎：Godot `4.7.1.stable.official.a13da4feb`
- Windows：桌面 release 导出，`build/windows/happy_fish.exe`
- Web：non-threaded release 导出，Chrome/Edge 桌面浏览器
- Playwright：`1.62.1`，单 worker 串行

## 2. 自动测试与启动

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `godot --headless --editor --path . --quit` | 0 | 编辑器导入完成 |
| `godot --headless --path . --quit-after 1` | 0 | 应用入口无启动/解析错误 |
| `godot --headless --path . --script res://tests/run_all.gd` | 0 | `PASS: 旧双人回归与 Gate 3 模式/输入/UI 校验通过` |

覆盖配置、选择页、生命周期、active players、单/双人经济与结果、10/18 Boss 阈值、输入路由、held 清理、UI 可见性和响应布局。

## 3. 浏览器 E2E

最终导出后执行 `npm run test:e2e`，退出码 0，12/12 通过（84.6 秒）：Chrome 6/6、Edge 6/6。

实际覆盖模式选择、单人鼠标、单人键盘和暂停切换、双人双键盘与鼠标隔离、重开/返回选择、响应布局、首次交互音频、零页面滚动、零 `pageerror`、零 console error。机器可读结果见 `playwright_modes.json`；调试失败历史见 `../../../docs/testing/playwright-e2e-failures.md`，均已解决。

## 4. 稳定性与性能

| 证据 | 结果 | 关键数据 |
|---|---|---|
| `soak_single_10min.json` | pass | 36,000 物理帧；599.988 秒；0 错误；鱼峰值 20；7 次重开 |
| `soak_dual_10min.json` | pass | 36,000 物理帧；599.936 秒；0 错误；鱼峰值 20；10 次重开 |
| `performance_probe.json` | pass | 平均 60.022 FPS；最低一秒 59.847 FPS；无连续低于 55 FPS |

两组 soak 持续检查 active players 的金币非负、pending 非负、普通鱼不超上限；结束时主动结算全部弹体并验证 pending 为 0。

## 5. 构建与 smoke

| 产物 | 字节 | SHA-256 | 结果 |
|---|---:|---|---|
| `build/windows/happy_fish.exe` | 123858328 | `7beba097455c676148ba2b24c9d44fd481809bed492cb898989afbffbaf00704` | release 导出；存活 smoke 8 秒 |
| `build/web/index.html` | 5442 | `8781ccb27d73e2366245cda3043e76b60f9e71dc25a3027fffcc34c1d68c58c8` | release 导出；双浏览器通过 |
| `build/web/index.js` | 279815 | `68586d6daafc93c6e697b3fb258976874aa7459b8931165ebb1dc3c9614cc42c` | pass |
| `build/web/index.wasm` | 39513091 | `35116f68540ac41acf7d71ea457added91b5e960a9cca3e2acc72918eaf01277` | pass |
| `build/web/index.pck` | 14745996 | `4c40b55d14dda9f2e53dbaed1f2df3ba5973bc99e49475d2bd51eaa9a4846e1e` | pass |

Web preset 明确为 `variant/thread_support=false`。Windows smoke 只终止本次启动的精确 PID。

## 6. 视觉与文档

`screenshots/` 含模式选择 1280×720/1920×1080、单人鼠标、单人键盘、暂停切换、返回确认、双人键盘和单人结果共 8 张实机截图；逐图检查无关键重叠、越界或错误 P2 残留。

`docs/gamedesign/游戏设计总览.md` 与 `docs/gamedesign/内容与表现.md` 已同步 as-built 单人/双人流程、操作、HUD、结果、Boss 阈值、桌面 Web 音频和启动入口。

## 7. 验收中修复

1. HUD 倍率在鼠标 `＋/－` 与键盘 `W/S` 改档后未即时刷新：增加统一 `level_changed` 通知并由 UIController 更新。
2. Playwright 模式选择坐标和动态背景截图基线：校准为稳定区域，不放宽产品错误、滚动或输入隔离断言。
3. 增加 Edge 项目并按实际浏览器 UA 校验；Chrome 与 Edge 使用同一套功能用例。

## 8. 已知边界

- 手柄、触控、按键重映射、持久化上次选择和双人鼠标仍属于 vNext/out_of_scope。
- 本轮验证桌面 Windows、Chrome 与 Edge；不包含移动浏览器、Firefox、Safari 或线上托管。

签署：Gate 4 通过，T06 可关闭。
