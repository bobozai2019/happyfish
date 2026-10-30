# Runtime Knowledge

## 2026-06-06: `tsx watch` 通过 pnpm 从服务进程 spawn 时冷启动超时 ⚠️

- **标签**: #nodejs #tsx #pnpm #timeout
- **症状**: `npm run dev`（实际执行 `tsx watch server/index.ts`）从服务进程 spawn 后，`waitForPort` 默认 5 秒超时内端口未绑定。交互式 shell 中 2 秒内即可绑定。
- **排查**: 手动 node spawn 正常 → 服务进程内 spawn 超时 → 增大超时到 15 秒后解决
- **根因**: pnpm 的 `tsx` 通过 `.pnpm/tsx@x.x.x/node_modules/tsx/dist/cli.mjs` 路径解析，在服务进程上下文中模块加载和 TypeScript 编译比交互式 shell 慢。
- **修复**: `waitForPort` 默认超时从 5000ms 增加到 15000ms。
- **如何应用**: 涉及 `tsx watch` 或 pnpm 管理的 CLI 工具的端口等待，超时应设 15 秒以上。清理旧进程时用 `taskkill /T /F /PID` 确保杀掉整个进程树。
