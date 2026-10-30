# Conventions Knowledge

## 2026-05-17: UI 根脚本用局部 preload 类型

UI 页面根脚本默认不声明全局 `class_name`，但使用方仍然要尽量强类型。需要判断或持有页面类型时，在当前脚本局部声明脚本资源：

```gdscript
const MapScreenScript := preload("res://scripts/ui/map_screen.gd")

var screen: MapScreenScript = MapScreenScene.instantiate() as MapScreenScript
if current_screen is MapScreenScript:
	pass
```

**Why:** 页面级 UI 直接 `class_name MapScreen` 会污染 Godot 全局类型表，让页面脚本看起来像稳定公共 API，也增加旧 UI、新 UI、同名组件并存时的冲突风险。

**How to apply:** 页面导航、局部组件协作和测试用 `preload` 脚本类型；只有真正跨系统复用的公共 UI 组件才声明 `class_name`，并在规范中记录例外。

## 2026-05-17: 生产调试日志统一走 DevLog

生产运行路径不直接调用裸 `print()`；需要长期保留的 AI 可观测性和人工排查日志统一走 `scripts/utils/dev_log.gd`。

```gdscript
const DevLogScript := preload("res://scripts/utils/dev_log.gd")

DevLogScript.debug(&"TurnFlow", "player_action", {"turn": turn_index})
```

**Why:** 直接散落 `print()` 会在导出包和自动验证中持续产生噪音，但完全删除日志会降低排查效率。统一入口可以保留可观测性，同时集中控制 editor 开启、导出包关闭。

**How to apply:** 新增生产日志时只调用 `DevLog.debug(channel, message, fields)`；字段优先用简单标量，避免整包写入大型对象。测试脚本仍可直接 `print()` 输出 PASS 和诊断信息。

## 2026-05-14: 类型注解必须用 preload 常量，不能用 class_name

所有跨文件的类型注解必须使用 `preload()` 常量，不能直接引用 `class_name` 注册的类型名。

标准模式：
```gdscript
# 文件顶部
const BattleContextScript = preload("res://scripts/battle/battle_context.gd")

# 变量和参数
var _ctx: BattleContextScript = null
func setup(ctx: BattleContextScript) -> void:
```

**Why:** Godot 4 的文本解析器无法在解析阶段跨文件解析 class_name 类型，会抛出 74+ 个 "Could not find type in current scope" 错误和级联的 ERR_CYCLING_LINK (error 43) 失败。

**How to apply:** 新增任何跨文件类型引用时，先添加 `const XxxScript = preload(...)` 再用 `XxxScript` 作类型标注。同文件内的 class_name 引用（如返回类型）是安全的例外。

## 2026-05-14: 全屏覆盖层必须有右上角关闭按钮

所有全屏覆盖界面（事件、商店、休息等）必须在右上角放置统一的关闭按钮。

标准实现：

```gdscript
const Ui := preload("res://scripts/settings/settings_ui_factory.gd")

# _build_ui() 中，在主内容之后添加：
var close_btn := Button.new()
close_btn.text = "✕"
close_btn.custom_minimum_size = Vector2(44, 44)
close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
Ui.outline_button(close_btn)
close_btn.pressed.connect(_on_close_pressed)
var header := HBoxContainer.new()
header.add_theme_constant_override("separation", 10)
var header_spacer := Control.new()
header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
header.add_child(header_spacer)
header.add_child(close_btn)
add_child(header)
```

**Why:** 关闭按钮不能放在滚动区域内（如商店之前的做法），必须固定在视口右上角，确保用户随时可见可点击。统一位置和样式降低认知负担。

**How to apply:** 新增任何全屏覆盖界面时，按此模式添加。关闭按钮 emit 对应的 completed signal，触发节点完成流程返回地图。

## 2026-05-15: 能固化到场景里的，别用脚本

**规则：** 能在 .tscn 场景中完成的控件创建和属性设置，禁止用脚本代码做。

具体来说：
- **节点创建**：Button、Label、Container 等静态 UI 元素必须在场景树中创建，不许 `_build_ui()` 里 `Xxx.new()` + `add_child()`
- **属性设置**：text、custom_minimum_size、size_flags、theme_override 等固定属性在 Inspector 里设好，不许脚本里 `node.xxx = yyy`
- **信号连接**：静态信号连接在场景的"信号"面板完成，只有动态信号（运行时才知道目标）才在脚本里 `.connect()`
- **例外**：数据驱动的 UI 列表（手牌、商店商品、波次敌人）是合理的脚本生成场景，因为内容是运行时数据

**Why:** 脚本创建 UI 代码量大、难维护、Inspector 看不到全貌、无法在编辑器里预览布局。场景化后设计师能直接看到结构，改属性不用改代码，也不会出现"脚本创建了但忘记设置某个属性"的 bug。

**How to apply:** 写 `_build_ui()` 或类似函数前先问自己——这个节点结构是固定的还是运行时动态的？固定的就做进场景。只有"数量和内容取决于数据"的部分才留给脚本。
