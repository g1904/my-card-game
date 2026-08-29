# 环境规则（机器相关）

> 这记录的是**维护者的机器**实况。它不是普适约定 —— 克隆到另一台机器后需重新核对。

## 平台
- 操作系统：Windows 11。Shell：PowerShell（主要）。Bash（Git Bash）也可用。

## 仓库拓扑 —— 一个裸仓库中枢 + 十个 worktree（2026-08-16 起）

十个分支目录**不再是十份独立 clone**，而是同一个裸仓库中枢 `D:\MyCardGame\.repo.git`
的十个 **git worktree**，每个钉在一个分支上（`.claude`→`claude-config`、`main`→`main`、
`game-*-branch`→`game-*`、`game-design-documents`→`game-design`，后端同构）。

- **一份对象库、一份 fetch 状态。** 在任意一个目录里 `git fetch` 即更新全体的 remote-tracking
  引用；`push-all.cmd` 据此按 `git rev-parse --git-common-dir` 去重，整轮只 fetch 一次。
- **worktree 的 `.git` 是文件不是目录**（内容 `gitdir: …/.repo.git/worktrees/<name>`）。
  写脚本判断「是不是 git 工作区」**一律用 `git rev-parse --git-dir` 的退出码**，
  绝不能写成 `Test-Path <dir>/.git -PathType Container` —— 那在 worktree 下永远为假。
- **一个分支同时只能被一个 worktree 检出。** 要在别处再看同一分支用 `git worktree add --detach`。
- 每个分支的上游跟踪已逐一设为 `origin/<branch>`，各目录照常 `git status` / `commit` / `push`。
- 增删目录用 `git -C D:\MyCardGame\.repo.git worktree add|remove`，**不要**手工 `rm -rf`
  （会留下悬空登记；真删了就跑一次 `worktree prune`）。
- **根目录 `D:\MyCardGame\` 本身不是仓库。** 它只放三个 `.cmd` 包装脚本
  （`push-all` / `promote` / `session-manager`）与 `.repo.git`。根级 `.gitignore` 已删除——
  git 从不向仓库根以上查找忽略规则，那份文件从来就没生效过；其内容已并入
  `game-feature-branch/.gitignore`。**根级 `.cmd` 三件套不受任何分支版本控制**，改动前请自行留意。

## 可用工具（可直接使用）

| 工具 | 说明 |
|------|------|
| `git` | 版本控制。 |
| `dotnet` | .NET SDK —— 为 Godot 项目构建 C# 程序集。 |
| Godot 编辑器 | Godot 4.7（.NET 构建）。打开/运行/导出游戏通过**编辑器 GUI** 完成，不假定其在 PATH 上。 |
| Rider | C# IDE。 |
| `chrome` | 在 PATH 上可用（对网页导出目标很有用）。 |
| `python` | Python 3.14.7（`C:\Python314\python.exe`）。已核实在 PATH 上、可直接调用——脚本与钩子可以依赖它。 |
| `node` | Node.js v24.19.0（`E:\Nodejs\node.exe`）。已核实在 PATH 上。 |
| `npm` | npm 11.17.0（`E:\Nodejs\npm.ps1`）。已核实在 PATH 上。 |

> 核实日期：2026-08-16。版本号会随升级漂移——只把「在 PATH 上可用」当作稳定事实，具体版本用时现查。
>
> `python` 曾经指向 Windows 应用商店的应用执行别名桩并失败（旧的 python 编辑守卫钩子因此被移除）。现已装上真实的 Python，那条限制**不再成立**；若要恢复基于 python 的钩子，见下方「钩子」一节——目前仍无任何钩子配置。

## 不可用 —— 不要依赖

- 假定 `docker`、`gh` **不**在 PATH 上，除非已核实。如果某个步骤需要它们，跳过并告知用户手动运行。

> `node` / `npm` 可用不构成引入前端工具链的理由——本项目的客户端是 Godot，npm 只作辅助脚本 / `npx` 一次性工具用。

## 构建 / 运行 / 验证

- **默认不对玩法代码做 CLI 编译检查。** 通过在 Godot 编辑器中打开项目并按 Play，或通过运行一次导出来验证。仅当确有一个 Godot 二进制在 PATH 上（先核实）时，无头的 `godot --headless` 构建检查才有效。
- 对项目的 `.csproj` 运行 `dotnet build` 能捕获 C# 编译错误，但权威检查是 Godot 编辑器构建（它以正确的 Godot 引用驱动 .NET 构建）。
- 除非用户要求，不要求任何单元/集成测试。

## 钩子

- **PostToolUse 的台账体积告警。** `settings.json` 的 `hooks.PostToolUse` 以 matcher `Edit|Write` 挂了 `.claude/scripts/index-size-guard.ps1`：被写入的文件若命中 `*_index.md` / `open-questions/update-log.md` / `answer-logs/_index.md` 且超过阈值（一般 20KB；`update-log.md` 因保留最近 ~10 条完整条目而单独放宽到 48KB），打印一行中文告警。它**只告警、永不拦截**（任何情况下 exit 0），职责是提醒「索引又在长回台账」（`game-design-documents/decisions/ADR-0005`）。调用形态固定为 `powershell -NoProfile -ExecutionPolicy Bypass -File <脚本>`。
- **PreToolUse(Bash) 的快照目录写入守卫。** `hooks.PreToolUse` 以 matcher `Bash` 挂了 `.claude/hooks/check-bash-readonly-dir.sh`（bash + python）：Bash 命令的重定向写入、写命令（rm/touch/tee/sed -i 等）或移动类命令的**目标**落在四个只读快照目录时 exit 2 拦截；只读访问与全部 git 子命令放行（分支提升走根级 `promote.cmd`，钩子不干涉）。python 不可用或 JSON 解析失败时 fail-closed（拒绝）。
- **没有 Notification 钩子。** 工作方式以单会话内分发子代理为主，后台单个代理完成任务不构成需要打断的信号，故不做桌面通知。
- **没有 SessionStart 钩子。** 分支文件夹纪律主要由 `Context.md` 约束；此外 `settings.json` 的 permission **deny 规则**会拦截对四个只读快照目录（`game-testing-branch/`、`game-production-branch/`、`backend-testing-branch/`、`backend-production-branch/`）的文件写入。规则一律写成 `Edit(<路径>)` —— 它覆盖所有文件编辑工具（Edit / Write / NotebookEdit）；`Write(<路径>)` 形式在文件权限检查中不被匹配，是无效规则，不要添加。**路径不带 `./` 前缀**（`Edit(./game-testing-branch/**)` 这种写法匹配不上，规则等于失效）。（Bash 写入不在拦截范围内。）
