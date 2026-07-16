# MyCardGame —— 分支指南

**MyCardGame** 是一款 Godot 4.7（.NET/C#）2D roguelike 卡牌构筑游戏（Balatro / Slay the Spire 的手感），移动优先、竖屏、离线。

这个 `main` 分支有意只承载**这张指南地图**。所有实际内容都位于下面的分支中。每个工作分支在维护者的机器上被检出到各自的同级文件夹里。

## 分支

| 分支 | 用途 | 本地文件夹 |
|--------|---------|--------------|
| `main` | 这张指南地图。无游戏代码。 | — |
| `feature` | 活跃开发。新工作在此进行。 | `game-feature-branch/` |
| `testing` | 从 `feature` 提升而来的 QA / 验证快照。 | `game-testing-branch/` |
| `production` | 从 `testing` 提升而来的发布稳定快照。 | `game-production-branch/` |
| `design` | 设计意图与交接（仅文档，孤儿历史）。非游戏代码。 | `game-design-documents/` |
| `claude-config` | `.claude/` 工具配置（规则、知识、技能、设置）。非游戏代码。 | `.claude/`（当前为本机上一份本地的、未跟踪的副本） |

## 流程

```
feature  →  testing  →  production
(develop)   (verify)     (release)
```

`feature`、`testing` 和 `production` 全都从同一个 Godot 4.7 项目脚手架播种而来。
`design` 和 `claude-config` **独立**于这条线 —— 孤儿历史、无游戏代码、从不合并进发布。
`design` 携带设计文档（意图的事实来源）；`claude-config` 携带 Claude Code 工具配置。

## 获取游戏

检出你需要的分支 —— 例如 `git checkout feature` —— 然后在 Godot 4.7 编辑器（.NET 构建）中打开项目并按 Play。游戏完全离线；存档持久化到 `user://`。
