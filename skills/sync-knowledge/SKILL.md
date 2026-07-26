---
name: sync-knowledge
description: 对账 .claude/knowledge/* 与两个事实来源（game-feature-branch/ 的代码现状、game-design-documents/ 的设计意图），修复知识笔记中的漂移。只写知识文件，不碰代码与设计文档。
argument-hint: [systems | scenes | data | autoloads | dictionary | all]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Sync Knowledge

`knowledge/*` 是面向 Claude 的提炼视图，夹在两个事实来源之间：**代码**（`game-feature-branch/`——"实际是什么"）与**设计文档**（`game-design-documents/`——"应该是什么"）。本技能把知识笔记对齐到这两者，消除随开发累积的漂移。

**范围守则：** 只写 `.claude/knowledge/*`（以及 `.claude/blueprints/_index.md` 的状态行，若发现失真）。**不**改游戏代码（那是 `/implement`），**不**改设计文档（那归用户，走 `/analyze-new-ideas`）。发现两个事实来源*彼此*矛盾（代码 ≠ 设计意图）时，如实报告给用户——那是设计或实现的问题，不是知识文件能自行裁决的。

## 步骤

### 1. 确定对账范围
解析 `$ARGUMENTS`：`systems` / `scenes` / `data` / `autoloads` / `dictionary` 之一 → 只对账该领域；`all` 或空 → 全部领域。

### 2. 采集代码现状（game-feature-branch/）
- 场景：Glob `game-feature-branch/**/*.tscn`。
- 脚本：Glob `game-feature-branch/**/*.cs`；略读类名、autoload 候选、EventBus 信号。
- 数据：Glob `game-feature-branch/**/*.tres` 及 `*Data.cs` 资源类。
- Autoload：读 `project.godot` 的 `[autoload]` 段。

### 3. 采集设计现状（game-design-documents/）
按 `knowledge/architecture.md` 的"知识 ↔ 设计文档对照"表，读对应权威文档：
- `terminology.md`（根级）↔ `knowledge/dictionary.md`
- `20-systems/` ↔ `knowledge/systems/*`
- `30-content/` ↔ `knowledge/data/*`
- `40-ux/` ↔ `knowledge/scenes/*`
- `50-decisions/ADR-*`（已定案决策必须反映进相关知识笔记）
- `60-requirements/_index.md`（status 为 `built` 的 FR，其系统应有知识笔记）

### 4. 三方比对并修复
对每个领域，找出并**直接修复**：
- **过时**：知识笔记声称的状态与代码不符（如 `_index` 标 TODO 但系统已存在，或反之）→ 改为如实描述。
- **缺失**：代码中已有、知识中没有的系统/场景/数据类型/autoload → 补一条目（或建 `systems/<name>.md`）。
- **超前**：知识断言了代码里不存在、设计里也未定案的东西 → 降级为"规划中"或删除断言。
- **术语漂移**：`dictionary.md` 与 `terminology.md` 冲突 → 以 `terminology.md` 为准修正 dictionary。
- **决策未落**：已 Accepted 的 ADR 未反映在相关知识笔记 → 补上（附 ADR 编号）。

### 5. 报告
```
## Knowledge sync: <范围>

### Fixed
- <knowledge 文件>: <改了什么、依据（代码路径 / 设计文档）>

### Code ≠ Design（需要用户裁决，未改动）
- <矛盾点>: 代码 <现状> vs 设计 <意图>

### Clean（已核对，无漂移）
- <领域>
```
