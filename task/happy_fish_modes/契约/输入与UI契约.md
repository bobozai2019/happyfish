# 输入与 UI 契约

文档角色：`contract`

状态：`frozen`（T01 / Gate 1）

Owner：T01/T04/T05/T06

## 1. 操作矩阵

| 模式 | 玩家 | 瞄准 | 换挡 | 开炮 | 鼠标按钮 |
|---|---:|---|---|---|---|
| 单人鼠标 | 1 | 指针世界位置 | HUD `－`/`＋` | 左键或 HUD 开炮按钮，支持长按 | 显示 |
| 单人键盘 | 1 | `A/D` | `W/S` | `Space`，支持长按 | 隐藏 |
| 双人键盘 | 1 | `A/D` | `W/S` | `Space` | 隐藏 |
| 双人键盘 | 2 | `←/→` | `↑/↓` | `Enter` | 隐藏 |

双人模式没有操作方式选择；双人鼠标输入一律不进入 MVP。

## 2. `PlayerInputRouter` 边界

建议路径：`scripts/game/player_input_router.gd`。路由器是原始 `Input`、UI 信号和 `CannonController` 之间的唯一桥梁。

### 配置 API

| 方法 | 输入 | 规则 |
|---|---|---|
| `configure(config, cannons)` | `GameSessionConfig`, `Dictionary[int, CannonController]` | 保存 config 副本，只注册 active players |
| `set_enabled(value)` | `bool` | false 时立即释放所有 held 状态 |
| `set_single_control(control)` | `SinglePlayerControl` | 仅单人合法；先释放旧状态再切换 |
| `release_all_inputs()` | 无 | 清除鼠标/键盘/UI fire held，不修改炮倍 |

`configure()` 在 config 为空、非法、炮台缺失或炮台集合包含 inactive id 时返回 `false` 并保持 disabled；合法时返回 `true`。`set_single_control()` 在双人模式或枚举非法时返回 `false`，不得改变当前配置。

### 路由到 Cannon 的命令

| 命令 | 参数 | 说明 |
|---|---|---|
| `set_keyboard_aim_axis` | `player_id:int, axis:float` | `[-1, 1]`，Cannon 按物理帧消费；非法 id 忽略并报错 |
| `aim_at_world_position` | `player_id:int, target:Vector2` | 立即计算目标角度并限制上半圆 |
| `request_level_change` | `player_id:int, delta:int` | delta 只允许 `-1` 或 `1`，返回是否执行 |
| `set_fire_held` | `player_id:int, held:bool` | false→true 立即尝试一发并按冷却连发；false 停止后续连发 |
| `request_fire_once` | `player_id:int` | 单次尝试，不改变 held，返回是否实际发射 |

`CannonController` 不再直接读取 `Input`；它只实现上述可测试命令和既有射击/金币逻辑。

原始事件边界：键盘 action 在 `_physics_process()` 采样；未被 GUI 消费的战斗区左键按下由 `_unhandled_input()` 接收；全局左键释放和窗口失焦由 `_input()` / `NOTIFICATION_APPLICATION_FOCUS_OUT` 兜底释放。`set_enabled(false)`、暂停、结果、切换 control 和离开战斗都必须先调用 `release_all_inputs()`。

## 3. 鼠标语义

1. 单人鼠标模式下，鼠标在战斗画布内移动时，P1 炮台瞄准该世界位置。
2. 角度继续限制在 `-170°` 到 `-10°`；鼠标位于炮台下方也不得越界。
3. 战斗区域左键按下立即发射一发，并进入 held；保持按下后按炮台 `0.25s` 冷却连发。
4. 左键释放必须在任何指针位置结束 held，包括释放发生在按钮、窗口边缘或画布外时。
5. 点击 UI 控件不得触发战斗区域开炮；Button 使用 `mouse_filter = STOP`，战斗点击通过未消费事件处理。
6. 右键不绑定玩法，Web 不依赖屏蔽上下文菜单完成 MVP。
7. 窗口失焦、切换操作、暂停、进入结果或返回选择时，必须调用 `release_all_inputs()`。

## 4. HUD 操作按钮信号

仅单人鼠标模式显示以下预制按钮：

| 节点语义 | 信号 | 参数 | 行为 |
|---|---|---|---|
| `LevelDownButton` | `level_change_requested` | `player_id=1, delta=-1` | 向下循环炮倍 |
| `LevelUpButton` | `level_change_requested` | `player_id=1, delta=1` | 向上循环炮倍 |
| `FireButton.button_down` | `fire_button_changed` | `player_id=1, pressed=true` | 立即开火并开始 held |
| `FireButton.button_up` | `fire_button_changed` | `player_id=1, pressed=false` | 结束 held |

要求：

- 按钮 `focus_mode = NONE`，避免抢走键盘操作焦点。
- 最小点击区域 `56×56 px`，开炮按钮建议至少 `88×64 px`。
- 按钮按下有缩放/亮度和按钮音效反馈。
- 按钮不可支付时不伪造射击反馈；倍率按钮仍允许切换，实际发射继续自动降档。

## 5. 页面/界面状态矩阵

| 界面 | 分类 | 单人鼠标 | 单人键盘 | 双人键盘 |
|---|---|---|---|---|
| 模式选择 | MVP | 显示鼠标已选 | 显示键盘已选 | 只显示双键盘说明 |
| 战斗 HUD | MVP | P1 + 操作按钮 | P1 + 键盘提示 | P1/P2 + 双键盘提示 |
| 暂停层操作选择 | MVP | 可切为键盘 | 可切为鼠标 | 隐藏/只读“双键盘” |
| 结果层 | MVP | 单人统计 | 单人统计 | 双人并列统计 |
| 返回模式选择确认 | MVP | 可用 | 可用 | 可用 |

所有界面继续使用简体中文、Noto Sans SC 和现有美漫卡通主题。禁止加入商店、账号或付费入口。

### UIController 对外信号

| 信号 | 参数 | 消费者 |
|---|---|---|
| `restart_requested` | 无 | `GameFlowController.restart_current_game()` |
| `return_to_mode_select_requested` | 无 | 确认层通过后由 GameFlow 销毁战斗 |
| `single_control_change_requested` | `control:int` | GameFlow 校验并更新路由/UI |
| `level_change_requested` | `player_id:int, delta:int` | PlayerInputRouter |
| `fire_button_changed` | `player_id:int, pressed:bool` | PlayerInputRouter |

UIController 只发请求，不直接改应用配置；GameFlow 成功处理 control 后调用 `UIController.apply_single_control(control)` 刷新暂停层、提示和按钮可见性。

## 6. 布局规则

- 模式选择卡片在 `1280×720` 与 `1920×1080` 居中，无横向滚动。
- 单人炮台位于底部中央 `x≈50%`；P2 HUD 和炮台不可见且不可交互。
- 单人 HUD 保持金币、炮倍、提示和状态清晰；鼠标按钮不得遮挡炮口或中央鱼群主区域。
- 双人布局、P1 暖色和 P2 冷色标识保持当前验收外观。
- Web 页面在方向键、Space、Enter、鼠标开火期间保持 `scrollX=0, scrollY=0`。

## 7. E2E 契约

### E2E-M01 模式选择

1. 启动后只显示模式选择。
2. 单人默认鼠标；切到双人后不显示操作选择。
3. 未点击开始时没有战斗鱼群或 BGM。

### E2E-M02 单人鼠标

1. 单人鼠标开始，只见一座中央炮台和 P1 HUD。
2. 移动鼠标改变炮台朝向，角度不越界。
3. 左键点按发射一发，长按产生多发。
4. 点击 `＋`/`－` 改变倍率且不误开炮；长按 HUD 开炮按钮正常。
5. 首次交互后 Web AudioContext 为 `running`，页面零滚动、零错误。

### E2E-M03 单人键盘与切换

1. 选择单人键盘后使用 P1 旧按键完成瞄准、换挡和开炮。
2. 暂停切换到鼠标，继续后立即使用鼠标且没有残留键盘 held。
3. 再切回键盘，鼠标点击战斗区域不再开炮。

### E2E-M04 双人回归

1. 选择双人，只显示双键盘说明和双 HUD/双炮台。
2. 并发保持 P1 `A+Space` 与 P2 `→+Enter`，双方独立响应。
3. 鼠标点击战斗区域不控制任一炮台或开炮。

### E2E-M05 重开与返回

1. 重开后保留模式和单人操作选择，局内数据归零。
2. 返回模式选择后战斗实例消失。
3. 再次开始不继承鱼、金币、pending、保底、Boss 时间或暂停状态。

### 画布可观测性

Godot Web UI 位于单一 canvas 内，不引入伪 DOM 控件。E2E 通过稳定画面区域差异、输入前后截图、零错误监听和 Godot 自动/集成测试共同闭环；节点数量、金币、pending 和枚举状态由 GDScript 测试断言，不以脆弱像素 OCR 代替。

## 8. 浏览器和错误规则

- 验收桌面 Chrome 与 Edge，尺寸 `1280×720`、`1920×1080`。
- Playwright Chrome 用例必须监听 `pageerror` 与 console error，二者均为空。
- 鼠标/键盘/UI 输入不得造成页面滚动、文字选中或浏览器快捷行为干扰。
- UI 消费失败、held 未释放或双人被鼠标控制均为 P0 失败。
