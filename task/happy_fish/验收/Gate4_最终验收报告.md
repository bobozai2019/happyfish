# Gate 4 最终验收报告

文档角色：`verification_evidence`

状态：[已完成]

日期：2026-08-08

范围：T08、全部 P0 需求

## 结论

- 自动测试、资源、正式版引擎 10 分钟双人 soak、性能、Windows/Web 构建及 Chrome/Edge 回归全部通过，Gate 4 签字完成。
- Chrome 使用 Playwright 1.62.1 直接启动本机 Google Chrome，无需浏览器扩展；聚合回归 `2 passed (40.4s)`，覆盖两种分辨率、双人并发键位、暂停、零滚动、音频解锁及零页面/控制台错误。
- 浏览器验收期间修复了 Web 中文字体缺失、错误的线程模板和非玩法 GodotIQ autoload。最终构建使用官方 Godot `4.7.1.stable.official.a13da4feb` 及真正的 Web non-threaded 模板（无 PThread/SharedArrayBuffer），并内嵌 Noto Sans SC（SIL OFL 1.1）。

## 自动验收

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| Headless 启动 | 退出码 0，无解析/启动错误 | `godot --headless --path . --quit-after 1` | pass |
| 自动测试 | 全部测试退出码 0 | `tests/run_all.gd`，输出 `PASS: Gate 1-2、T05 捕获经济与 T06 HUD/暂停/结果流程校验通过` | pass |
| 资源校验 | 9 鱼、3 炮及引用完整 | `tests/test_data_resources.gd`、`resources/data/` | pass |
| Windows 导出 | 命令成功且构建可运行 | `build/windows/happy_fish.exe`；隐藏启动 8 秒仍存活 | pass |
| Web 导出 | 命令成功且文件完整 | `build/web/index.{html,js,wasm,pck}` | pass |

## E2E 验收

| 场景 | 标准 | 证据 | 结果 |
|---|---|---|---|
| 双人 10 分钟游玩 | 无卡死、串线、负金币、重复发奖 | `soak_10min.json`：599.753 秒、36000 physics frames、9 次重开、0 错误 | pass |
| 救援与结算 | 双方完整完成一局并重开 | `tests/test_capture_session.gd`、`screenshots/results_friendly.png` | pass |
| Boss | 警告、捕获/离场和冷却正确 | `tests/test_gameplay_objects.gd`、`screenshots/boss_and_rescue.png` | pass |
| Chrome | 输入、布局、音频和运行正常 | `web_browser_check.json`、`tests/e2e/*.spec.ts`、`screenshots/chrome_playwright_*.png` | pass |
| Edge | 输入、布局、音频和运行正常 | `web_browser_check.json`：两尺寸、双人键位、暂停、零滚动、零控制台错误 | pass |
| 性能 | 接近 60 FPS，无持续低于 55 FPS | `performance_probe.json`：平均 59.9565 FPS，最低一秒均值 59.1056 | pass |

## 构建清单

| 产物 | 字节数 | SHA-256 |
|---|---:|---|
| `build/windows/happy_fish.exe` | 117741168 | `6417faa95aa2e34be67942af7c9d3b9b4ff8ec45ad5b5785e1093c73e1d88a2b` |
| `build/web/index.html` | 5442 | `295eff00e066d0ce1633aba88aa55645631e1c503d2b8cb6bca8ddc414a7d67e` |
| `build/web/index.js` | 315645 | `ffc3898b59fba6f5af0c02f76e5ee526cc061e65c7d2d6f4f98186876cea15c4` |
| `build/web/index.wasm` | 37900721 | `f33199ca285b7a135e9133684d23439eee156cae2a3ee599386e9169f47ff8f3` |
| `build/web/index.pck` | 14718052 | `8b070114d5e5405fd11b20df81fbe1b71f084a0f6d4b3cec7dd9a0200a31245b` |

## 命令与结果

```powershell
godot --headless --path . --quit-after 1
godot --headless --path . --script res://tests/run_all.gd
godot --path . --script res://tests/performance_probe.gd
godot --headless --path . --script res://tests/soak_10min.gd
godot --headless --path . --export-debug "Windows Desktop" build/windows/happy_fish.exe
godot --headless --path . --export-debug "Web" build/web/index.html
python tools/serve_web.py --port 8060
npm run test:e2e:chrome
```

## 需求覆盖

- [x] `../需求映射.md` 中所有 P0 需求已通过。
- [x] 所有 vNext 与 out_of_scope 内容未意外进入 MVP。
- [x] `build/` 已被 `.gitignore` 排除；本目录不是 Git checkout，无法用 Git index 二次验证。
- [x] 最终交付清单包含启动方法和已知限制。

## 启动方法与已知限制

- Windows：运行 `build/windows/happy_fish.exe`。
- Web：运行 `python tools/serve_web.py --port 8060`，打开 `http://127.0.0.1:8060/index.html`。最终产物为单线程 Web 导出。
- 浏览器首次与画布交互后解锁音频，这是桌面浏览器自动播放策略所要求的行为。
- Chrome 自动回归可运行 `npm install` 后执行 `npm run test:e2e:chrome`，不依赖 GPT/ChatGPT 浏览器扩展。

## 问题与返工

| 问题 | 严重度 | 负责人 | 返工任务 | 状态 |
|---|---|---|---|---|
| 初始受控浏览器方案依赖未安装的 ChatGPT Chrome Extension | P0 Gate blocker | 工具方案 | 改用 Playwright 直接驱动本机 Chrome，2 个用例通过 | resolved |
| 本机旧 `web_nothreads` 模板实际包含 PThread/共享内存 | P0 Web | 导出环境 | 安装官方 4.7.1 stable non-threaded 模板并重新导出 | resolved |
| GodotIQ runtime autoload 在排除 addon 后产生 Web 加载错误 | P0 Web | 工具集成 | 停用不兼容插件并移除非玩法 autoload | resolved |
