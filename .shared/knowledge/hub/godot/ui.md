# UI Knowledge

## 2026-05-14: 全屏覆盖层关闭按钮统一模式

所有全屏覆盖界面（事件、商店、休息等）的关闭按钮统一放在右上角，使用一致的实现模式：

```gdscript
const Ui := preload("res://scripts/settings/settings_ui_factory.gd")

# 在 _build_ui() 中，add_child(main) 之后添加：
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

**Why:** 之前商店的退出按钮放在底部滚动区域内，用户需要滚动才能看到。事件和休息界面甚至没有关闭按钮。统一到右上角符合用户习惯。

**How to apply:** 新增任何全屏覆盖界面时，按此模式添加关闭按钮。header 叠加在 main VBox 之上，spacer 将按钮推到右侧。关闭按钮应 emit 对应的 completed signal，触发节点完成流程。

## 2026-05-16: 静态创建优先铁律

能静态创建在场景里的控件，就别动态创建；能直接在创建时设置的属性，就别用脚本动态设置。

**Why:** 静态创建的控件在编辑器中可见、可编辑、可预览，降低调试成本。动态创建和延迟赋值增加运行时复杂度，且无法在编辑器中直观检查。脚本越少，出错越少。

**How to apply:**
- 控件、布局、默认属性优先在 `.tscn` 场景编辑器中完成，而非 `_ready()` 中 `Node.new()` + `add_child()`
- 只有数据驱动的 UI（如手牌列表、敌人列表）才用动态创建，静态部分（框架、标题、按钮）走场景树
- `text`、`size`、`anchor`、`theme_override` 等属性在 Inspector 里设置，脚本只负责运行时变化的值
