# T05 自适应 HUD、暂停与结果界面

负责人：主 agent

任务状态：[未开始]

任务进度：0%

依赖：T04 [已完成]

可并发：新增图标素材可独立准备；HUD、Pause、Results 和 UIController 必须单写者。

## 目标

完成模式选择后的所有界面差异：单人鼠标按钮、单人键盘提示、双人旧 HUD、暂停切换、个人结果、返回选择确认和响应式布局。

## 小目标进度

| ID | 小目标 | 状态 | 交付物/证据 | 备注 |
|---|---|---|---|---|
| G01 | 模式选择视觉与状态反馈 | [未开始] | 选择页截图 | 儿童友好 |
| G02 | 单/双人 HUD 自适应 | [未开始] | `hud.tscn` | P2 可见性 |
| G03 | 单人鼠标换挡/开炮按钮 | [未开始] | UI 信号接线 | 长按开炮 |
| G04 | 暂停操作切换与返回确认 | [未开始] | pause scene | 双人无切换 |
| G05 | 单人/双人结果布局 | [未开始] | results scene | 个人/并列 |
| G06 | 响应布局与 UI 流测试通过 Gate 3 | [未开始] | Gate 3 报告 | 两分辨率 |

## 输入上下文

1. `../契约/输入与UI契约.md`
2. `../契约/游戏模式与流程契约.md`
3. `scenes/ui/hud.tscn`
4. `scenes/ui/pause_overlay.tscn`
5. `scenes/ui/results_overlay.tscn`
6. `scripts/ui/ui_controller.gd`

## 交付物

1. 模式化 HUD、暂停和结果场景。
2. UIController 模式接线。
3. UI 流、按钮事件消费和布局测试。
4. Gate 3 报告与截图。

## 允许修改

1. `scenes/ui/`
2. `scripts/ui/`
3. `resources/art/ui/` 与相应 `index.md`（仅必要图标）
4. `scripts/game/player_input_router.gd` 的 UI 信号接线最小调整
5. `tests/test_ui_flow.gd` 与新增 UI 测试
6. 本任务状态和 Gate 3 证据

## 禁止修改

1. 单局经济、概率、Boss 和炮倍数值
2. Cannon 射击逻辑
3. frozen 契约
4. 通过脚本在 `_ready()` 重建可预定义的 UI 层级

## 实施内容

1. [未开始] 在 `.tscn` 中预制模式化面板和操作按钮。
2. [未开始] 依据 config 切换可见性、提示和结果文案。
3. [未开始] 接入 `－`/`＋`、Fire button_down/up 和按钮音效。
4. [未开始] 暂停层实现单人切换和返回选择确认。
5. [未开始] 验证 UI 点击不传播为战斗左键。
6. [未开始] 在 1280×720、1920×1080 验证布局。

## 验收标准

1. 单人鼠标显示操作按钮；单人键盘和双人隐藏。
2. 双人模式看不到可切换操作方式的控件。
3. 切换后控制提示和输入立即一致，无 held 残留。
4. 单人结果无 P2、伙伴或胜负文案；双人结果保持并列。
5. 所有 UI 按钮点击不误开炮，布局无重叠。

## 验收命令

```powershell
godot --headless --path . --script res://tests/run_all.gd
godot --path . --script res://tests/capture_screenshots.gd
```

## 回报要求

按标准格式回报，并附各模式/分辨率截图路径。

