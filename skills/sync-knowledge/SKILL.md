---
name: sync-knowledge
description: 对账 .claude/knowledge/* 与两个事实来源（game-feature-branch/ 的代码现状、game-design-documents/ 的设计意图），修复知识笔记中的漂移，并把偷偷长回来的副本压回薄引用。只写知识文件，不碰代码与设计文档。
argument-hint: [systems | scenes | data | autoloads | dictionary | standards | all]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Sync Knowledge

`knowledge/*` 是**薄引用层**（已定案），夹在两个事实来源之间：**代码**（`game-feature-branch/`——「实际是什么」）与**设计文档**（`game-design-documents/`——「应该是什么」）。本技能把它对齐到这两者。

## 知识层的职责（决定什么该写、什么该只留链接）

知识层只回答三件事：

1. **代码现在是什么样** —— 这是它**独有的真值**，设计库里没有。存在哪些场景 / 脚本 / autoload / `.tres`，`project.godot` 配了什么，哪些系统真的落地了。
2. **权威文档在哪** —— 导航表：领域 ↔ `game-design-documents/` 的对应文件。
3. **写代码时会改变写法的承重纪律** —— 每条一句话 + 回链。例：抽取走 `AllEnabled()` 而不是 `All().Where(...)`；`_Ready` 订阅 / `_ExitTree` 退订；B/C 带 `Async` 后缀、A 不带；运行时绝不写 `XxxData : Resource`。

**其余一律只留链接。**

## 副本判据（本技能的核心）

> **凡在 `game-design-documents/` 里已是代码形态的东西——方法签名、枚举、`record` / `interface` 定义、EventBus 负载表、JSON schema、数值旋钮表、完整流程步骤——知识层只留链接，不留副本。**
>
> 理由：副本不增加任何信息，却是下一次漂移的唯一来源。历史证据：某次全量 sync 修复的漂移 100% 是「设计定了、知识不知道」，0% 来自代码。

**例外——两类文件保留实质内容，因为设计库里没有它们的权威：**

| 类别 | 文件 | 处理 |
|------|------|------|
| **本作设计的投影** | `architecture.md`、`systems/*`、`data/*`、`scenes/*`、`autoloads/*`、`dictionary.md`、`standards/{signal-eventbus,rng-determinism,save-format}.md` | **薄引用**：导航 + 代码现状 + 承重一句话，**零代码块** |
| **C#/Godot 引擎实践** | `standards/{csharp-conventions,godot-scene-conventions,mobile-portrait-ui}.md` | **保留实质** ——它们讲的是引擎 / 语言，不是本作设计，在设计库里无权威、不是副本 |

## 步骤

### 1. 确定对账范围
解析 `$ARGUMENTS`：`systems` / `scenes` / `data` / `autoloads` / `dictionary` / `standards` 之一 → 只对账该领域；`all` 或空 → 全部领域。

### 2. 采集代码现状（game-feature-branch/）
- 场景：Glob `game-feature-branch/**/*.tscn`。
- 脚本：Glob `game-feature-branch/**/*.cs`；略读类名、autoload 候选、EventBus 事件。
- 数据：Glob `game-feature-branch/**/*.tres` 及 `*Data.cs` 资源类。
- Autoload / 主场景：读 `project.godot` 的 `[autoload]` 与 `run/main_scene`。
- **若某侧仍为空目录 / 只有 README**（典型：`backend-feature-branch/`），如实记作「尚未开工」，**不要因为设计库写了就断言代码存在**。

### 3. 采集设计现状（game-design-documents/）
按 `knowledge/architecture.md` 的「知识 ↔ 设计文档对照」表读权威文档：
- `terminology.md`（根级）↔ `dictionary.md`
- `systems/` ↔ `systems/*`、`data/*`（内容即系统的字段 / 内嵌类型；`30-content/` 已并入）
- `systems/services/` ↔ `autoloads/*`
- `ux/` ↔ `scenes/*`
- `decisions/ADR-*`（已 Accepted 的决策必须反映）
- `handoffs/` 中 `status: distilled` 的**最近数份**——漂移通常最先出现在这里
- `requirements/_index.md`（status 为 `built` 的 FR，其系统应有知识笔记）

### 4. 三方比对并修复
对每个领域，找出并**直接修复**：

- **副本化（首要检查）**：知识层出现了设计库已有的代码形态内容（签名 / 枚举 / record / 负载表 / schema / 完整流程）→ **删掉，替换为一句话 + 回链**。若它同时是一条承重纪律，压缩成祈使句的一行（「抽取走 `AllEnabled()`」），不保留形状。
- **过时**：知识笔记声称的状态与代码不符（`_index` 标 TODO 但系统已存在，或反之）→ 改为如实描述。**特别注意 `architecture.md` 的代码现状段**——首次落地代码后它最容易滞后。
- **缺失**：代码中已有、知识中没有的系统 / 场景 / 数据类型 / autoload → 补一条**导航条目 + 回链**（不是补一段设计说明）。系统真正落地后才建 `systems/<name>.md`，写代码侧事实（文件路径、EventBus 事件、RNG 子流、存档触点、坑），**不复制设计意图**。
- **超前**：知识断言了代码里不存在、设计里也未定案的东西 → 降级为「规划中」或删除断言。
- **失效的待决**：知识层标着「待决 / 待定」，而设计库已裁决 → 改写为定案 + 回链。反向亦然（设计库新开的待决未反映）。
- **术语漂移**：`dictionary.md` 与 `terminology.md` 冲突 → 以 `terminology.md` 为准。`dictionary.md` **只保留通用体裁词汇**（Balatro / StS 惯例），本作专有术语一律指向 `terminology.md`。
- **决策未落**：已 Accepted 的 ADR 未反映在相关知识笔记 → 补一句 + ADR 编号。
- **跨库契约冲突（必查）**：`game-design-documents/` 里出现了与 `backend-design-documents/contracts/` 不一致的协议契约描述 → **契约权威在后端库**。这是设计库**内部**的矛盾，**如实报告给用户，不自行裁决、不改设计库**——但知识层一律回链后端库。

**范围守则：** 只写 `.claude/knowledge/*`（以及 `.claude/blueprints/_index.md` 的状态行，若发现失真）。**不**改游戏代码（那是 `/implement`），**不**改设计文档（那归用户，走 `/analyze-new-ideas`）。发现两个事实来源*彼此*矛盾（代码 ≠ 设计意图），或设计库**内部**滞后（新 handoff 已裁决、主题文档的待决清单没跟上）→ **如实报告，不自行裁决**。

### 5. 报告
```
## Knowledge sync: <范围>

### Fixed
- <knowledge 文件>: <改了什么、依据（代码路径 / 设计文档）>

### Thinned（副本压回引用）
- <knowledge 文件>: 删除 <什么代码形态内容> → 回链 <权威文档>

### Code ≠ Design / 设计库内部滞后（需用户裁决，未改动）
- <矛盾点>: <现状> vs <意图>

### 跨库契约冲突（需用户裁决，未改动）
- <客户端库说 X> vs <后端库说 Y> —— 契约权威在后端库

### Clean（已核对，无漂移）
- <领域>
```
