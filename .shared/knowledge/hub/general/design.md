# Design Knowledge

## 2026-06-08: ResizeObserver + 延迟回调模式的时序陷阱 ⚠️

- **标签**: #resizeobserver #javascript #timing #pitfall
- **陷阱**: 在 `mount()` 中调用 `container.observe()` 启动 ResizeObserver，然后调用 `requestFirstFit()` 设置延迟回调标志。期望 ResizeObserver 回调触发时检查标志并执行回调。但实际上回调在 `observe()` 后可能同步触发，此时标志还未设置。
- **为什么容易犯**: 开发者通常认为 ResizeObserver 是异步的（浏览器 spec 说是异步），但在某些情况下（容器已有确定尺寸、浏览器 layout 已完成），首次回调可能在当前 microtask 中触发。
- **后果**: 延迟回调永远不执行。例如：console attach 永远不触发，工具切换后终端不重新连接。
- **正确做法**: 必须在 `observe()` 之前设置标志。即 `requestFirstFit()` 必须在 `mount()` 之前调用。如果 `mount()` 内部有 `observe()` + 回调的模式，标志必须在进入 `mount()` 前就绑定好。
- **如何提前发现**: 如果有一个"延迟到 ResizeObserver 首次触发后执行"的逻辑，检查标志设置时机是否在 `observe()` 之前。
