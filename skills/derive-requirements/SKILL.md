---
name: derive-requirements
description: 设计→实现的桥梁。阅读详细设计文档（vision + 一个主题文档），并向选定设计库（客户端或后端）的 requirements/ 输出离散、可构建、带验收标准的功能需求规格（FR-*）。受就绪性检查把关。
argument-hint: [--lib=game|backend] <system/文档名 | FR 领域 | "all detailed docs">
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Derive Requirements

把**详细设计意图**转化为**功能需求**：这是设计库 `<LIB>/`（写代码前的"是什么"）与 `/blueprint` → `/implement`（"怎么做"）之间的桥梁。产出是一份或多份带验收标准的 `FR-*.md` 规格。

**范围守则：** 你**只**写入 `<LIB>/requirements/`（并更新其 `_index.md`），且只写**本次选定的那一个库**。**不要**编辑源设计文档（客户端 `vision/` / `systems/` / `art/` / `ux/` / `decisions/`；后端 `vision/` / `contracts/` / `systems/` / `operations/` / `decisions/`）——那是 `/analyze-new-ideas`。**不要**触碰代码（`game-*-branch/` / `backend-*-branch/`）——那是 `/blueprint` → `/implement`。

**充实 vs. 臆造（强制，与 `analyze-new-ideas` 相同）：** 对设计所述内容进行拆解与结构化；**不要**臆造它未陈述的机制、数字或决策。源文档未回答的任何内容都放入该 FR 的 `## Open questions`，以问题形式表述——绝不断言为需求。

## 步骤

### 0. 确定目标设计库（强制，先于一切）
按 `.claude/rules/design-library-routing.md` 解析本次作用于 `game-design-documents/` 还是 `backend-design-documents/`：显式库参数 → 参数中的路径前缀 → 相对路径落地探测 → 都判不出就**询问用户，绝不静默默认**。

选定后，**下文所有写作 `game-design-documents/` 的路径一律读作 `<LIB>/` 下的同名路径**。在报告开头点明本次作用的库。

### 1. 解析目标
剔除库参数后解析剩余 `$ARGUMENTS`：
- 一个**文档 / 系统名**（客户端如 `adventure-event/combat`；后端如 `contracts/profile-sync`）→ 为该文档 derive FR。
- **"all detailed docs"** → 扫描该库主题文档区的每份文档（客户端 `systems/` / `art/` / `ux/`；后端 `contracts/` / `systems/` / `operations/`），并为每个通过就绪性门（第 3 步）的文档 derive。
- **空** → 列出候选文档及其就绪性，然后询问要 derive 哪个。

### 2. 阅读源文档（写任何东西之前）
1. `<LIB>/README.md` — 流水线与状态词汇。
2. `<LIB>/requirements/_TEMPLATE.md` 与 `_index.md` — FR 形态与既有台账（避免重复 id；查看已 derive 的内容）。**两库的模板不同**：后端模板另有 `## Contract touchpoints` 与**强制**的 `## Failure & retry semantics`，按该库模板产出。
3. 目标主题文档，加上它们依赖的 `vision/*` 意图，以及任何约束它们的 `decisions/ADR-*`。
4. **客户端库**：对应的 `.claude/knowledge/` 笔记，以了解预期架构的背景。**后端库无知识引用层**——改为读 `contracts/` 的现状与被该 FR 牵动的 `game-design-documents/systems/services/*`（客户端侧已定的语义是硬前提）。

### 3. 就绪性门（执行前置条件——"一旦 vision 与机制已详尽"）
一个源文档**可以 derive**，当且仅当：
- 它的 `## Intent` 有真实内容（不只是 `> _placeholder_`），**且**
- 它的 `## Open questions` 为空或已解决（存在一个决策/ADR），**且**
- 它所挂靠的 vision（`vision/`）本身在该点上没有未决问题。

若目标**尚未就绪**，**不要**编造需求。停下并如实报告卡住的确切原因（哪些 Open questions、缺哪个决策），并建议先用 `/analyze-new-ideas` 去解决。仅当文档中*就绪*的切片时才允许部分 derive——在报告中把其余部分标为 blocked。

### 4. 拆解为功能需求
从就绪的意图中，切出**离散、可独立构建的增量**。准则：
- 一个 FR = 一个带自身验收标准的可构建切片——而非整个系统。拆分大型系统（按子行为拆分），并用 `depends-on` 串起构建顺序。
- 优先做**薄的纵向切片**，而非宽的横向层。可验证的形态按库而定：**客户端** = 能在 Godot 编辑器中运行 / 观察；**后端** = 能表述为「给定请求 / 状态 → 期望应答 / 存储结果」（技术栈未定前不指定测试工具）。
- 每条验收标准都必须**可通过运行游戏来观察**（依据 `environment-rules.md`——验证靠游玩，而非 CLI 测试）。使用 Given/When/Then。
- 在意图层面填好 **Data & state touchpoints**——**客户端**：CycleState 字段、EventBus 信号、`.tres` id、save 点；**后端**：持久化状态（profile 记录、`revision` 计数器、`pushId` 窗口、manifest），另填模板要求的 `## Contract touchpoints` 与**强制**的 `## Failure & retry semantics`（弱网下的幂等与重试是承重设计）。足够让后续设计据以展开，而不臆造实现形态。
- **后端 FR 不发明报文。** 涉及新字段 / 新端点时，先确认它已在 `contracts/` 中定义；未定义则记入该 FR 的 `## Open questions` 并标为 blocked，不要在 FR 里自造契约。

### 5. 写 FR 文件 + 台账
- 为每个 FR，从该库的 `_TEMPLATE.md` 创建 `<LIB>/requirements/FR-<system>-<slug>.md`（后端库的 `<system>` 即模板中的 `<service>`）。复用文档命名，使其与主题文档匹配。
- 设 `status: draft`（等待用户签署），并列出所有 `source-docs`。
- 若某 FR 会与既有的重复，则**增量更新它**而非创建第二个——不要覆盖先前的验收标准。
- 在 `requirements/_index.md` 中新增/更新行（最新的置顶）：`id | system | title | status | blueprint | source-docs`。

### 6. 报告并闭环
- 列出产出的 FR（id + 一行标题 + status）及 `depends-on` 顺序。
- 浮现每个 **Open question / blocked 切片**——尤其是任何在能进入 `ready` 前需要决策的部分。
- 告诉用户下一步：审阅每个 FR 并把 `draft → ready`，然后对一个 ready 的运行 `/breakdown-requirements FR-<id>` 或 `/blueprint FR-<id>`。

## 输出形态
```
## Derived requirements from: <源文档>

- library: <game-design-documents | backend-design-documents>

### Feature requirements
- FR-<system>-<slug> (draft): <title>   [depends-on: ...]
- ...

### Blocked / not derived (readiness gate)
- <doc/slice>: blocked by <open question / missing ADR>

### Next
- Review & mark ready: requirements/FR-*.md
- Then: /breakdown-requirements FR-<id>
```
