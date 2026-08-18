# MyCardGame —— 分支指南

**MyCardGame** 是一款 Godot 4.7（.NET/C#）2D roguelike 卡牌构筑游戏（Balatro / Slay the Spire 的手感），移动优先、竖屏、强制在线（云端权威存档）。

这个 `main` 分支有意只承载**这张指南地图**。所有实际内容都位于下面的分支中。每个工作分支在维护者的机器上被检出到各自的同级文件夹里。

## 分支

| 分支 | 用途 | 本地文件夹 |
|--------|---------|--------------|
| `main` | 这张指南地图。无代码。 | — |
| `game-feature` | 客户端活跃开发。新工作在此进行。 | `game-feature-branch/` |
| `game-testing` | 从 `game-feature` 提升而来的 QA / 验证快照。 | `game-testing-branch/` |
| `game-production` | 从 `game-testing` 提升而来的发布稳定快照。 | `game-production-branch/` |
| `game-design` | 客户端设计意图与交接（仅文档，孤儿历史）。 | `game-design-documents/` |
| `backend-feature` | 后端活跃开发。 | `backend-feature-branch/` |
| `backend-testing` | 从 `backend-feature` 提升而来的 QA / 验证快照。 | `backend-testing-branch/` |
| `backend-production` | 从 `backend-testing` 提升而来的发布稳定快照。 | `backend-production-branch/` |
| `backend-design` | 后端设计意图（仅文档，孤儿历史）。 | `backend-design-documents/` |
| `claude-config` | `.claude/` 工具配置（规则、知识、技能、脚本、设置）。非代码。 | `.claude/` |

## 流程

**两条彼此独立的提升线** —— 各自开发、各自验证、各自发布，从不互相合并：

```
game-feature     →  game-testing     →  game-production      (Godot 客户端)
backend-feature  →  backend-testing  →  backend-production   (云端后端)
   (develop)          (verify)             (release)
```

`game-feature` / `game-testing` / `game-production` 全都从同一个 Godot 4.7 项目脚手架播种而来。
`backend-*` 尚未开工 —— 目前只有 README，技术栈待定。

`game-design`、`backend-design` 和 `claude-config` **独立**于这两条线 —— 孤儿历史、无产品代码、从不合并进发布。
`game-design` 携带客户端设计文档（意图的事实来源）；`backend-design` 携带后端设计文档；`claude-config` 携带 Claude Code 工具配置。

十个检出目录（含 `.claude/`）是同一个裸仓库中枢 `.repo.git` 的十个 **git worktree**，各钉在一条分支上——一份对象库、一份 fetch 状态，一个分支同时只能被一个 worktree 检出。`.\push-all.cmd` 一次性把它们全部提交并推送（四个只读快照目录只推不提交）；`.\promote.cmd -Line game|backend -To testing|production` 沿提升线做 `--no-ff` 合并 + push。

### 为什么客户端与后端分线

客户端的七个「服务」全部是同一个 Godot 进程内的模块单例，彼此为直接 C# 方法调用；**唯一真实的进程边界是客户端 ↔ 后端**。把后端塞进 `game-*` 会让后端代码被编译进游戏程序集、被 Godot 导入器扫描、随客户端一起打包分发，并强行要求两侧同步提升。两侧唯一的耦合点是协议契约，其权威在 `backend-design-documents/`。

## 获取游戏

检出你需要的分支 —— 例如 `git checkout game-feature` —— 然后在 Godot 4.7 编辑器（.NET 构建）中打开项目并按 Play。游戏**强制在线**：进度实时同步云端、以云端为权威，本地 `user://` 仅作缓存 / 临时态。后端就绪前，客户端的边界服务以**离线 stub** 实现。
