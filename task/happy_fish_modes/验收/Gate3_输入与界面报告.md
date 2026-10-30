# Gate 3 输入与界面报告

文档角色：`verification_evidence`

状态：[已完成]

日期：2026-08-08

范围：T04 单人输入路由与鼠标操作、T05 自适应 HUD/暂停/结果界面

## 结论

- 单人鼠标、单人键盘和双人固定键盘的输入与 UI 状态矩阵完整实现。
- 单人鼠标 HUD 显示 `－`、`开炮！`、`＋`；按下/松开信号接入 InputRouter，GUI 按下不会传播为战斗区开炮。
- 暂停层允许单人即时切换鼠标/键盘，双人隐藏选择；切换同步 GameFlow、Session、Router 和 HUD，并清除 held。
- 单人结果只显示个人统计；双人保持并列统计。重开保留配置，返回选择有确认层并销毁战斗。
- 1280×720 与 1920×1080 模式选择布局清晰；HUD、暂停和结果层无关键重叠。

## 自动验证

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `godot --headless --path . --script res://tests/run_input_only.gd` | 0 | 输入路由、held 清理和双人鼠标隔离通过 |
| `godot --headless --path . --script res://tests/run_all.gd` | 0 | `PASS: 旧双人回归与 Gate 3 模式/输入/UI 校验通过` |
| `godot --path . --script res://tests/capture_screenshots.gd` | 0 | 8 张模式/界面截图生成成功 |

UI 测试覆盖：P2 显隐、鼠标控件显隐、HUD 换挡/开炮信号、暂停切换、路由同步、个人结果、配置化重开、返回确认、零残留战斗实例，以及 1024×576、1280×720、1920×1080 HUD 边界。

## 截图证据

| 场景 | 路径 |
|---|---|
| 模式选择 1280×720 | `screenshots/mode_select_1280x720.png` |
| 模式选择 1920×1080 | `screenshots/mode_select_1920x1080.png` |
| 单人鼠标 | `screenshots/single_mouse_1280x720.png` |
| 单人键盘 | `screenshots/single_keyboard_1280x720.png` |
| 单人暂停与键盘选择 | `screenshots/single_pause_keyboard_1280x720.png` |
| 返回选择确认 | `screenshots/return_select_confirm_1280x720.png` |
| 双人键盘 | `screenshots/dual_keyboard_1280x720.png` |
| 单人结果 | `screenshots/single_result_1280x720.png` |

逐图检查确认：文字可读、控件均在画面内、单人无 P2 面板/结果、鼠标按钮未遮挡炮口或主鱼群区域、双人左右 HUD 与炮台保持原色彩区分。

## 契约与数值

- frozen 契约无变化。
- 单局经济、概率、Boss、炮倍资源和 Cannon 射击规则未在 T05 修改。

