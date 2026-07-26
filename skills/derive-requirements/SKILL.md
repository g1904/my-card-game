---
name: derive-requirements
description: 设计→实现的桥梁。阅读详细设计文档（vision + 一个 system/content/ux 文档），并向 game-design-documents/60-requirements/ 输出离散、可构建、带验收标准的功能需求规格（FR-*）。受就绪性检查把关。
argument-hint: <system/文档名 | FR 领域 | "all detailed docs">
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Derive Requirements

把**详细设计意图**转化为**功能需求**：这是 `game-design-documents/`（写代码前的"是什么"）与 `/blueprint` → `/implement`（"怎么做"）之间的桥梁。产出是一份或多份带验收标准的 `FR-*.md` 规格。

**范围守则：** 你**只**写入 `game-design-documents/60-requirements/`（并更新其 `_index.md`）。**不要**编辑源设计文档（`00/20/30/40/50`）——那是 `/analyze-new-ideas`。**不要**触碰游戏代码（`game-*-branch/`）——那是 `/blueprint` → `/implement`。

**充实 vs. 臆造（强制，与 `analyze-new-ideas` 相同）：** 对设计所述内容进行拆解与结构化；**不要**臆造它未陈述的机制、数字或决策。源文档未回答的任何内容都放入该 FR 的 `## Open questions`，以问题形式表述——绝不断言为需求。

## 步骤

### 1. 解析目标
解析 `$ARGUMENTS`：
- 一个**文档/系统名**（如 `adventure-event-combat`、`content/cards`）→ 为该文档 derive FR。
- **"all detailed docs"** → 扫描每个 `20/30/40` 文档，并为每个通过就绪性门（第 3 步）的文档 derive。
- **空** → 列出候选文档及其就绪性，然后询问要 derive 哪个。

### 2. 阅读源文档（写任何东西之前）
1. `game-design-documents/README.md` — 流水线与状态词汇。
2. `game-design-documents/60-requirements/_TEMPLATE.md` 与 `_index.md` — FR 形态与既有台账（避免重复 id；查看已 derive 的内容）。
3. 目标主题文档，加上它们依赖的 `00-vision/*` 意图，以及任何约束它们的 `50-decisions/ADR-*`。
4. 对应的 `.claude/knowledge/` 笔记，以了解预期架构的背景。

### 3. 就绪性门（执行前置条件——"一旦 vision 与机制已详尽"）
一个源文档**可以 derive**，当且仅当：
- 它的 `## Intent` 有真实内容（不只是 `> _placeholder_`），**且**
- 它的 `## Open questions` 为空或已解决（存在一个决策/ADR），**且**
- 它所挂靠的 vision（`00-vision/`）本身在该点上没有未决问题。

若目标**尚未就绪**，**不要**编造需求。停下并如实报告卡住的确切原因（哪些 Open questions、缺哪个决策），并建议先用 `/analyze-new-ideas` 去解决。仅当文档中*就绪*的切片时才允许部分 derive——在报告中把其余部分标为 blocked。

### 4. 拆解为功能需求
从就绪的意图中，切出**离散、可独立构建的增量**。准则：
- 一个 FR = 一个带自身验收标准的可构建切片——而非整个系统。拆分大型系统（按子行为拆分），并用 `depends-on` 串起构建顺序。
- 优先做**薄的纵向切片**（可在 Godot 编辑器中运行/验证的东西），而非宽的横向层。
- 每条验收标准都必须**可通过运行游戏来观察**（依据 `environment-rules.md`——验证靠游玩，而非 CLI 测试）。使用 Given/When/Then。
- 在意图层面填好 **Data & state touchpoints**（RunState 字段、EventBus 信号、`.tres` id、save 点）——足够让 `/blueprint` 据以设计，而不臆造类形态。

### 5. 写 FR 文件 + 台账
- 为每个 FR，从 `_TEMPLATE.md` 创建 `game-design-documents/60-requirements/FR-<system>-<slug>.md`。复用文档/知识的命名，使 `<system>` 与主题笔记匹配。
- 设 `status: draft`（等待用户签署），并列出所有 `source-docs`。
- 若某 FR 会与既有的重复，则**增量更新它**而非创建第二个——不要覆盖先前的验收标准。
- 在 `60-requirements/_index.md` 中新增/更新行（最新的置顶）：`id | system | title | status | blueprint | source-docs`。

### 6. 报告并闭环
- 列出产出的 FR（id + 一行标题 + status）及 `depends-on` 顺序。
- 浮现每个 **Open question / blocked 切片**——尤其是任何在能进入 `ready` 前需要决策的部分。
- 告诉用户下一步：审阅每个 FR 并把 `draft → ready`，然后对一个 ready 的运行 `/blueprint FR-<id>`。

## 输出形态
```
## Derived requirements from: <源文档>

### Feature requirements
- FR-<system>-<slug> (draft): <title>   [depends-on: ...]
- ...

### Blocked / not derived (readiness gate)
- <doc/slice>: blocked by <open question / missing ADR>

### Next
- Review & mark ready: 60-requirements/FR-*.md
- Then: /blueprint FR-<id>
```
