# Playwright E2E failure ledger

## 2026-08-08 - 模式选择 Canvas 坐标校准

- Scope: `tests/e2e/mode_selection.spec.ts`，E2E-M01
- Command: `npx playwright test tests/e2e/mode_selection.spec.ts --project=chrome`
- Status: failed（已解决，最终通过）
- Classification: selector
- Evidence: 首轮错误比较两个非同源空白像素区；次轮在双人选择布局收缩后仍使用单人 Start 的 y 坐标。
- Reproduction: 1280×720 打开选择页，切换双人后按旧坐标点击开始。
- Expected: 双人卡片选中、操作选择隐藏，点击开始进入双人战斗。
- Actual: 测试采样/点击未命中目标视觉区。
- Next action: 已改用稳定采样区与双人布局 Start 坐标；最终 `1 passed (10.9s)`。

## 2026-08-08 - HUD 换挡文字延迟刷新

- Scope: `tests/e2e/single_mouse.spec.ts`，单人鼠标 HUD
- Command: `npx playwright test tests/e2e/single_mouse.spec.ts --project=chrome`
- Status: failed（已解决，E2E-M02 最终通过）
- Classification: product-bug
- Evidence: 进入战斗、单人布局、音频和鼠标瞄准通过；点击 HUD `＋` 后 `current_cannon_level` 改变，但倍率画面未变化。Trace 位于 `.playwright/results/single_mouse-E2E-M02-singl-80c90-fire-HUD-controls-and-audio-chrome/`。
- Reproduction: 默认单人鼠标开始游戏，点击底部 `＋`。
- Expected: P1 HUD 立即由 `炮倍 1×` 更新为 `炮倍 2×`，且不误开炮。
- Actual: 文字需等到下一次实际发射后才刷新。
- Next action: 已修复为统一的 InputRouter `level_changed` 可观察更新路径；E2E-M02 最终 `1 passed (13.9s)`。

## 2026-08-09 - 单人键盘 W/S 倍率缺少即时反馈

- Scope: `tests/e2e/single_keyboard_switch.spec.ts`，E2E-M03
- Command: `npx playwright test tests/e2e/single_keyboard_switch.spec.ts --project=chrome`
- Status: failed（已解决，E2E-M03 最终通过）
- Classification: product-bug
- Evidence: A/D 炮台变化通过；W 跨多个帧按住后炮台内部档位改变，但倍率 HUD 仍停留在 1×。
- Reproduction: 选择单人键盘并开始，按 W，观察 P1 倍率。
- Expected: 倍率文字立即更新，S 可见恢复。
- Actual: UI 没有接收键盘改档通知。
- Next action: 已统一发射 `level_changed` 并由 UIController 刷新；E2E-M03 最终 `1 passed (16.5s)`，E2E-M02 回归 `1 passed (15.2s)`。

## 2026-08-09 - 重开后战场局部截图范围不足

- Scope: `tests/e2e/restart_return.spec.ts`，E2E-M05
- Command: `npx playwright test tests/e2e/restart_return.spec.ts --project=chrome`
- Status: failed（已解决，最终连续两次通过）
- Classification: selector/expectation
- Evidence: 初始局部截图没有覆盖离场弹体，因此无法证明重开后的战场视觉已恢复。
- Reproduction: 单人鼠标开炮后执行暂停、确认重开，再比较过窄的战场局部。
- Expected: 比较区域覆盖可变化的弹体/网视觉，并在重开后恢复到干净稳定基线。
- Actual: 测试采样区没有包含目标变化。
- Next action: 已改为比较覆盖有效战场区域的稳定局部；最终连续两次通过（12.4s、12.2s）。

## 2026-08-09 - 暂停层动态背景误作像素基线

- Scope: `tests/e2e/restart_return.spec.ts`，E2E-M05
- Command: `npx playwright test tests/e2e/restart_return.spec.ts --project=chrome`
- Status: failed（已解决，最终连续两次通过）
- Classification: timing/visual-baseline
- Evidence: 半透明暂停层会显示持续移动的鱼群背景，两次暂停截图天然不逐像素相同。
- Reproduction: 两个不同时间点打开暂停层并直接比较整块像素。
- Expected: 分别验证运行画面到暂停画面的稳定局部变化，而非跨时间比较动态背景。
- Actual: 动态鱼群导致不稳定的逐像素差异。
- Next action: 已改为每次独立断言运行态到暂停态的局部变化；最终连续两次通过。
