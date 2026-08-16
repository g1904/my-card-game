---
name: session-manager
description: 管理 Claude Code 会话历史的收藏与标签。在会话中收藏/取消收藏当前或指定会话、增删标签、检索已收藏或按关键词搜索历史会话（绕过 --resume 的 50 条上限）。
argument-hint: -save/-unsave/-tag/-untag/-saved/-grep [id] [标签... 或关键词]
allowed-tools: Bash
---

# 会话收藏与标签管理

调用项目封装脚本 `.claude/scripts/session-manager` 管理会话收藏。它是对底层实现 `session-manager-impl.ps1` 的薄封装，把冗长的 PowerShell 命名参数换成简洁的子命令语法，并自动处理执行策略与 Git Bash 路径转换。收藏数据存于 `.claude/session-tags.json`（项目本地，按 session ID 记录）。

## 参数解析

从 `$ARGUMENTS` 解析**操作动词**（首个 `-xxx`）、**会话 id**（可为 UUID 前缀）、**一个或多个标签名/关键词**。标签支持多个，以空格分隔。约定：

| 用户输入 | 含义 | 传给脚本的子命令 |
|---------|------|--------------|
| `-save [id]` | 收藏；省略 id = **当前会话** | `save <id 或 .>` |
| `-save [id] <标签...>` | 收藏并打一个或多个标签 | `save <id 或 .> <标签1> [标签2 ...]` |
| `-unsave <id>` | 取消收藏 | `unsave <id>` |
| `-tag <id> <标签...>` | 给会话加一个或多个标签（自动收藏） | `tag <id> <标签1> [标签2 ...]` |
| `-untag <id> <标签...>` | 移除一个或多个标签 | `untag <id> <标签1> [标签2 ...]` |
| `-saved [标签...]` | 列出已收藏（给多个标签时须**同时含全部**标签） | `saved [标签1] [标签2 ...]` |
| `-grep <关键词>` | 在用户发言中搜索会话 | `grep <关键词>` |
| （无参数） | 列出全部会话 | `list`（或省略） |

规则：
- **id 省略或写作 `.` / `current` 时代表当前会话**（脚本取最近写入的 jsonl）。`-save`、`-tag` 常用来收藏「当前这次对话」，此时直接传 `.`。
- id 支持前缀（如 `ae6eb11d`），脚本会解析成完整 UUID；前缀不唯一会报错，需给更长前缀。
- 参数大小写不敏感。

## 执行步骤

1. 解析 `$ARGUMENTS`，按上表映射成子命令。识别不出动词时，默认执行 `list`（列出全部）。
2. 用 Bash 在项目根目录运行封装脚本（它内部会自动定位会话目录、收藏文件，并带上 `-NoProfile -ExecutionPolicy Bypass`）：
   ```bash
   bash .claude/scripts/session-manager <子命令> [参数...]
   ```
   例：
   - 收藏当前会话并打多个标签 → `bash .claude/scripts/session-manager save . 库存审查 待跟进`
   - 给指定会话移标签 → `bash .claude/scripts/session-manager untag 3eee5beb 库存审查`
   - 看某标签下的收藏 → `bash .claude/scripts/session-manager saved 库存审查`
   - 查看用法 → `bash .claude/scripts/session-manager --help`
3. 原样回显脚本输出。若为列表结果，提醒用户可用 `claude --resume <Id>` 恢复对应会话。

## 说明

- 该封装脚本只读会话文件、只写 `session-tags.json`，不修改任何业务代码，无副作用。底层解析逻辑仍由 `session-manager-impl.ps1` 承担。
- **入口按环境选择**（三个入口，均转发到 `.claude\scripts\session-manager-impl.ps1`）：
  - Git Bash / 本 skill 的 Bash 工具 → `bash .claude/scripts/session-manager <子命令>`（子命令语法，如 `save . 标签`）。
  - **PowerShell 提示符下手动执行（推荐）** → 仓库根的 `.\session-manager.cmd -save . -Tags 标签1,标签2`（多个标签用逗号分隔）。`.cmd` 不受 PowerShell 执行策略约束，内部已带 `-ExecutionPolicy Bypass`，在 `Restricted` 策略下也能直接运行。
  - 同一个 `.cmd` 在 `.claude\scripts\` 下也有一份（`.\.claude\scripts\session-manager.cmd`），两者等价，用哪个都行。
  - 常见坑：PowerShell 里不要用 `bash`（通常不在 PATH）；除根目录的 `session-manager.cmd` 外，其余脚本都在 `.claude\scripts\` 下，路径必须含 `scripts\`。
- 关键词搜索**仅匹配用户发言**（`type == user`），不搜工具输出与助手回复。
- 收藏与保留期无关：`cleanupPeriodDays` 控制磁盘保留天数；本 skill 解决的是超出 `--resume` 列表 50 条上限后仍能检索、恢复旧会话。
