# Git Workflow Knowledge

## 2026-06-07: 用 git diff 定位引入 bug 的提交，而非 git blame

- **标签**: #git #debugging #workflow
- **经验**: 修复 bug 后用 `git blame` 查看代码行会显示修复者的提交，而非引入 bug 的提交。正确方式是 `git show <可疑commit> -- <file>` 查看该提交的 diff，确认是否引入了问题。
- **How to apply**: 排查历史 bug 时，先用 `git log --oneline --all -- <file>` 找出所有修改过该文件的提交，然后逐个 `git show <hash> -- <file>` 查看 diff，定位引入问题的具体提交。blame 只适合查看当前代码的最后修改者。

---

## 2026-08-11: Git 权限问题优先使用批处理脚本

- **标签**: #git #windows #batch #authentication #workflow
- **偏好**: 遇到 Git 认证或终端权限阻塞时，优先检查并使用项目目录已有的 `.bat` 一键脚本；没有现成脚本时，可创建操作范围明确的批处理脚本执行。
- **执行约束**: 运行前先读取脚本，确认工作目录、暂存范围、远端、目标分支和具体命令。删除、覆盖、强制推送或其他高风险动作仍须单独确认，不能借批处理绕过安全检查。
- **验证**: 在 GitHub CLI 未登录的环境中，项目已有上传脚本通过本机 Git 凭据成功完成 `git add`、commit 和向指定 `master` 分支的 push；随后本地 HEAD 与远端分支哈希一致、工作区干净。
