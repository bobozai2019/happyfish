# Technical Knowledge

## 2026-06-06: Windows spawn shell:true 导致 0xC0000142 DLL 加载失败 ⚠️

- **标签**: #windows #nodejs #spawn #python
- **症状**: `spawn('python', ['-m', 'http.server', ...], { shell: true })` 在 Node.js 服务进程中报 0xC0000142（STATUS_DLL_INIT_FAILED），但命令行直接执行 `python` 正常。
- **排查**: 命令行直接 python 正常 → node -e spawn 正常 → 仅服务进程内失败 → 去掉 `shell: true` 后修复
- **根因**: `shell: true` 让 spawn 先启动 cmd.exe，再由 cmd.exe 启动 python，双重壳层导致 DLL 搜索路径异常。直接 spawn python（`shell: false`）不经过 cmd.exe，DLL 加载正常。
- **修复**: `spawn('python', [...], { shell: false })`，确保 python 在 PATH 中可直接调用。
- **如何应用**: Windows 上 spawn 直接可执行文件（python、node）时用 `shell: false`；只有 npm 这类批处理文件才需要 `shell: true`。

---

## 2026-06-08: ConPTY 输出已含 `\r\n`，`convertEol: true` 产生 `\r\r\n` 但视觉无害

- **标签**: #xtermjs #conpty #windows #terminal
- **经验**: Windows ConPTY（node-pty 默认后端）输出的行尾已包含 `\r\n`。xterm.js 的 `convertEol: true` 会把 `\n` 转成 `\r\n`，导致 `\r\n` 变成 `\r\r\n`。但在 ANSI 终端语义中，多余的 `\r`（回到行首）在已经是行首时是空操作，视觉效果与 `\r\n` 完全相同。
- **如何应用**: 排查终端排版问题时，不要把 `convertEol: true` 当作首要嫌疑。`\r\r\n` 不会导致光标错位、排版乱或内容重复。真正的嫌疑通常是终端尺寸不匹配、转义序列处理错误、或 backlog 重放问题。

---

## 2026-06-08: xterm.js 解析器是有状态的，跨 write() 的转义序列不会断裂

- **标签**: #xtermjs #terminal #parser #ansi
- **经验**: xterm.js 的 `EscapeSequenceParser` 是 VT500 兼容的状态机，`currentState` 在 `parse()` 调用间持久化。如果 `\x1b[32m` 被分成 `\x1b[3` 和 `2m` 两次 `write()` 调用，解析器会在第一次结束时处于 `CSI_PARAM` 状态，第二次从该状态继续，最终正确执行 SGR 32（绿色）。`requestAnimationFrame` 批量写入进一步减少了分裂概率。
- **如何应用**: 不需要担心 PTY 数据 chunk 边界分裂 ANSI 转义序列。xterm.js 自动处理。排查终端渲染问题时，转义序列分裂不是根因。

---

## 2026-06-06: .bat 标签不能放在 `for /f` 或 `if` 块内部 ⚠️

- **标签**: #windows #batch #parsing
- **症状**: .bat 文件中在 `for /f` 循环内部使用 `:label` + `goto :label`，报错"'f' 不是内部或外部命令"或"系统找不到指定的批处理标签"。
- **根因**: cmd.exe 解析 .bat 文件时，标签（`:label`）必须在顶层。放在 `for /f ... do (...)` 块内部会导致括号匹配错乱，整个块的解析失败。
- **修复**: 把需要跳转的逻辑提取到标签所在的顶层作用域。可以用 `goto` 跳出 `for` 块到外部标签，但不能在 `for` 块内部定义标签。
- **如何应用**: .bat 中复杂的 JSON 解析逻辑，用临时文件 + `set /p` 读取，配合 PowerShell `-Command` 做复杂操作。避免在 `for /f` 块内嵌套标签和跳转。
