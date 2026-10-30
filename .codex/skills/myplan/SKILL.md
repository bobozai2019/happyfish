---
name: myplan
description: Create an executable implementation plan from a product idea, HTML plan, PRD, rough task description, or existing project notes. Use when the user asks to "按模板输出", "写执行计划", "拆任务", "生成任务结构", "做计划标准模板", "subagent执行计划", "显示进度", or wants a plan that includes scope, DAG, contracts, task details, gates, validation, progress tracking, and execution status.
---

# MyPlan

Turn a product idea or planning document into an executable task package for a main agent and optional subagents.

## Workflow

1. Read the user's task, linked files, current repository conventions, and any existing task structure.
2. If source material is large, extract only product goals, MVP scope, non-goals, data/API/UI boundaries, risks, and acceptance criteria.
3. Produce a plan using the template in `references/execution-plan-template.md`.
4. Keep plan-state, execution-state, and verification evidence separate:
   - Plan-state: desired scope, tasks, contracts, gates.
   - Execution-state: current progress, locks, decisions, task status.
   - Verification evidence: commands, screenshots, API results, test output.
5. Add progress displays at three levels: overall plan, major tasks, and task-level goals.
6. Prefer concise, actionable Markdown. Do not create a PRD unless the user asks for a PRD.

## Required Output Shape

For a normal response, output these sections:

1. Project objective
2. Scope table: MVP / placeholder / vNext / out of scope
3. Requirement mapping
4. Contract list, including API field-level contract needs
5. Execution DAG and safe concurrency windows
6. Gate checklist
7. Progress dashboard with bracketed statuses
8. Task breakdown with per-goal progress
9. Validation and evidence plan
10. Recommended file structure
11. Immediate next steps

When the user asks to create files, create a `task/<project_slug>/` package using the same structure.

## Rules

- Make the MVP boundary explicit before task breakdown.
- Treat contracts as implementation boundaries, not just endpoint lists.
- Include request/response schemas or a required OpenAPI generation step for core APIs.
- Mark route/page/API items as `MVP`, `placeholder`, `vNext`, or `out_of_scope`.
- Add a runtime mode matrix when development and production dependencies differ.
- Use bracketed Chinese statuses for progress: `[未开始]`, `[进行中]`, `[已完成]`, `[阻塞]`, `[需返工]`, `[暂停]`, `[已跳过]`.
- Show progress at the overall plan, major task, and small-goal levels.
- Put actual test results in `验收/` or `execution_status`, not inside contract files.
- Keep old/generated planning documents labeled as `source`, `draft`, `archive`, or `execution_record`.
- Avoid over-documentation: add a risk register only when long-term operation or compliance requires it.

## References

Read `references/execution-plan-template.md` when generating a full template, creating files, or reviewing an existing task structure.
