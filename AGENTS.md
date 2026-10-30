# Repository Guidelines
这是一个的捕鱼达人游戏

## Project Structure & Module Organization

This is an early-stage Godot project. `project.godot` is the source of project and engine settings, while `icon.svg` is the current shared asset. Godot-generated metadata lives in `.godot/` and must remain untracked.

As the game grows, keep scenes in `scenes/`, GDScript in `scripts/`, reusable art/audio/fonts in `assets/`, and automated checks in `tests/`. Group feature-specific files together when practical—for example, `scenes/fish/`, `scripts/fish/`, and `assets/fish/`. Use `res://` paths in Godot resources; do not depend on machine-specific absolute paths.

## Build, Test, and Development Commands

- `godot --editor --path .` opens the project in the Godot editor.
- `godot --path .` runs the configured main scene once one exists.
- `godot --headless --path . --quit-after 1` imports resources and catches startup or parse errors in CI.
- `godot --headless --editor --path . --quit` performs a non-interactive editor import after asset changes.

The project declares Godot 4.7 with Forward Plus rendering and Jolt Physics. Use a compatible Godot 4.7 build; avoid committing incidental setting changes produced by another engine version.

## Coding Style & Naming Conventions

Use UTF-8 and LF line endings as configured by `.editorconfig` and `.gitattributes`. Follow standard GDScript style: tabs for indentation, `snake_case` for files, variables, and functions, `PascalCase` for named classes and node types, and `SCREAMING_SNAKE_CASE` for constants. Name scenes by their primary node or purpose, such as `fish_tank.tscn` and `FishController`.

Keep scripts focused, prefer typed GDScript for public APIs, and use signals rather than tightly coupling unrelated nodes. Edit `project.godot` through the editor unless a reviewed change specifically requires hand editing.

## Testing Guidelines

No test framework or coverage target is currently configured. Place future tests under `tests/`, mirror the source layout, and name test scripts `test_<feature>.gd`. Every gameplay change should include either an automated test or documented manual verification. Always run the headless startup check before opening a pull request.

## Commit & Pull Request Guidelines

Git history is not present in this checkout, so no repository-specific convention can be inferred. Use short, imperative commits with an optional scope, such as `feat(fish): add feeding behavior` or `fix(ui): preserve tank aspect ratio`.

Pull requests should explain the player-visible effect, list verification steps, link related issues, and include screenshots or short recordings for visual changes. Keep generated `.godot/` and platform export directories out of commits.

<!-- myaitool-hub-start -->
## Shared myaitool hub

Shared skills, knowledge, MCP, and Godot addon management docs:
`D:/AIprogram/myaitool/docs/hub-management.md`

MCP server layout, distribution, security, and verification docs:
`D:/AIprogram/myaitool/docs/mcp-management.md`
<!-- myaitool-hub-end -->


## Project Workspace Rules

1. Write task plans and task packages under `task/`.
2. Put downloaded or extracted tools under `tools/`.
3. Record issues, follow-ups, and items worth tracking under `todo/`.
4. Write technique/method documents to `docs/`.
5. Godot 项目规范见 `docs/rules/`。
6. gdscript 放置在`scripts/`
7. 资源统一放置在`resources/`
8. 场景统一放置在`scenes/`
9. `native/` 用于存放项目自有的原生扩展源码、构建配置和运行所需二进制；例如 `native/desktop_bridge/` 是 Godot 与 Windows 桌面窗口及输入系统之间的 GDExtension 桥接层。
10. `tmp/` 用于存放可随时重新生成或删除的临时文件、中间结果和短期调试输出；不得将其作为源码、正式资源或长期文档的唯一存放位置。
11. `tests/` 用于存放自动化测试脚本、测试夹具和测试专用场景；其中的 `.gd` 与 `.tscn` 可以保留在 `tests/` 内，不受运行时代码必须放入 `scripts/`、运行时场景必须放入 `scenes/` 的规则约束。

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" 鈫?"Write tests for invalid inputs, then make them pass"
- "Fix the bug" 鈫?"Write a test that reproduces it, then make it pass"
- "Refactor X" 鈫?"Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] 鈫?verify: [check]
2. [Step] 鈫?verify: [check]
3. [Step] 鈫?verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

