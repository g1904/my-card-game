---
name: breakdown-requirements
description: 把一份 derive-requirements 产出的 FR 草稿拆成一个文件夹，内含若干更小的、可执行的子需求，每个都小到能被 /blueprint 一次吃下。作用于客户端或后端设计库（二选一）。闭合设计→代码链路的最后一环。
argument-hint: [--lib=game|backend] <FR-<id> | 空（列出可拆解的 FR）>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Breakdown Requirements

`/derive-requirements` 的产出是**从设计文档整片切下来的** `FR-*`——粒度往往偏大，一个 FR 可能仍横跨数据资源、服务逻辑、场景与接线，直接喂 `/blueprint` 会得到一份过大的蓝图。本技能补上这一环：**一份 FR → 一个文件夹的可执行子需求**。

```
systems/ux 主题文档 → /derive-requirements → FR-*（片区级）
                → /breakdown-requirements → FR-*/（可执行子需求）
                       → /blueprint → /implement
```

**范围守则：** 你**只**写入 `<LIB>/requirements/`（父 FR 文件、新建的拆解文件夹、`_index.md` 台账），且只写**本次选定的那一个库**。**不要**编辑源设计文档（客户端 `vision/` / `systems/` / `art/` / `ux/` / `decisions/`；后端 `vision/` / `contracts/` / `systems/` / `operations/` / `decisions/`）——那是 `/analyze-new-ideas`。**不要**触碰代码（`game-*-branch/` / `backend-*-branch/`）——那是 `/blueprint` → `/implement`。

**充实 vs. 臆造（强制）：** 拆解是**重排与细化父 FR 已有的内容**，不是补设计。任何新增的验收标准都必须能从父 FR 逻辑推出；推不出来的**放入该子需求的 `## Open questions`**，绝不断言为需求。父 FR 自身的 Open questions 按相关性下发到对应子需求（并在父 FR 中保留）。

## 步骤

### 0. 确定目标设计库（强制，先于一切）
按 `.claude/rules/design-library-routing.md` 解析本次作用于 `game-design-documents/` 还是 `backend-design-documents/`：显式库参数 → 参数中的路径前缀 → **FR id 落地探测**（在两库的 `requirements/` 中查该 id：只有一处命中即取之，两处都有则询问）→ 都判不出就**询问用户，绝不静默默认**。

选定后，**下文所有写作 `game-design-documents/` 的路径一律读作 `<LIB>/` 下的同名路径**。在报告开头点明本次作用的库。

### 1. 解析目标
剔除库参数后解析剩余 `$ARGUMENTS`：
- 一个 **`FR-<id>`** → 拆解它。
- **空** → 读 `requirements/_index.md`，列出所有 `status: ready`（以及 `draft`）且**尚未拆解**的 FR（`status != broken-down`、无 `breakdown:` 字段），询问拆哪个。
- **一次只拆一份 FR。** 要拆多份就跑多次——拆解需要逐条核对覆盖，批量会漏。

### 2. 读父 FR 与既有约定（写之前先读）
1. `<LIB>/requirements/_index.md` — 状态词汇、台账、命名约定。
2. `requirements/_TEMPLATE.md`（父 FR 形态）与 `_TEMPLATE-sub.md`（**子需求形态，本技能的产出模板**）。
3. 目标 `FR-<id>.md` 全文——尤其 `## Acceptance criteria`、`## Scope`、`## Data & state touchpoints`、`## Open questions`（后端 FR 另有 `## Contract touchpoints` 与 `## Failure & retry semantics`）。
4. 该 FR 的 `source-docs` 里**与拆解相关的段落**（只为理解，不为改写）。
5. **客户端库**：`.claude/knowledge/architecture.md` + 相关 `systems/*` 笔记——了解代码现状，以便切出的子需求落在真实的文件边界上。**后端库无知识引用层且技术栈未定**——改为读 `contracts/` 中相关报文，按**协议与职责边界**切分，不按不存在的文件边界切。

### 3. 前置门（父 FR 是否可拆）
可拆的条件：
- 父 FR 的 `## Acceptance criteria` 有**真实、可观察**的条目（不只是模板占位）。
- 父 FR 的 `status` 是 `ready` 或 `draft`。

**不可拆并停下的情况：**
- `status: broken-down` 且文件夹已存在 → 这是**增量更新**，不是重新拆解：只补新的子需求 / 修订既有条目，**绝不覆盖已有子需求的验收标准**，也不改已是 `blueprinted` / `built` 的子需求。
- 父 FR 的验收标准仍是占位，或 `## Open questions` 大到使范围无法确定 → **不要编造子需求**。停下，如实报告卡在哪一条，建议先 `/analyze-new-ideas` → `/derive-requirements`。

### 4. 切分（本技能的核心）

**粒度判据 —— 一个子需求 =**
- 一次 `/blueprint` 能**一口吃下**：通常 **1 ~ 5 条**验收标准；
- 一个**薄纵切片**：**客户端** = 能在 Godot 编辑器里跑起来并观察到（依据 `environment-rules.md`——验证靠游玩，不靠 CLI 测试）；**后端** = 能表述为「给定请求 / 状态 → 期望应答 / 存储结果」并被验证；
- 自成一个**可提交的增量**：做完它，项目仍可运行 / 服务仍可部署。

**切分启发式（按优先级）**
1. **按可观察行为切**，不按代码层切。「玩家能看到 X」/「客户端发 X 会收到 Y」优于「建好 X 层」。
2. **纯横向层只有在自身可验证时才独立成子需求**——例如「定义 `XxxData` 资源 + 一个占位 `.tres` + 启动期校验能报出坏 id」是可验证的；「把所有数据类建好」不是。
3. **先立骨架、再挂行为**：第一个子需求通常是「最小可运行骨架」（场景 / 服务外壳 / 一条最短通路），其余在其上叠加。
4. **把风险与未知隔离到自己的子需求里**：带 Open questions 的部分单独成条，别污染确定的部分。
5. **依赖成链而非成网**：用 `depends-on` 串成尽量线性的构建顺序（典型：数据资源 → 服务 / 系统逻辑 → 场景 / UI → 接线 → 存档 / 同步触点）。
6. **跨边界依赖显式化**：客户端子需求依赖某个后端子需求时（或反之），`depends-on` 写全 `<LIB>/FR-<id>-NN`，**不要假定它已经存在**。

**写入形态（强制）**
子需求与 `_index.md` 都是活文档：**正文不写过程坐标、不写「已定案」**——不出现 handoff 日期戳（`08-12` 这类）、`handoffs/*.md` 路径、「推翻 X / 取代 X / 原方案」。溯源由 frontmatter 指向父 FR，正文里不重复。全文见 `/analyze-new-ideas` 第 6b 步「溯源三条」。

**覆盖核对（强制）**
父 FR 的**每一条**验收标准都必须映射到**至少一个**子需求。映射不上的条目 → 要么是切分漏了（补），要么是该条标准本身依赖未答问题（记入 Open questions 并在报告中点名）。这张映射表写进 `_index.md`。

### 5. 写文件
在 `requirements/` 下**新建与父 FR 同名的文件夹**（父 FR 的 `.md` 文件保持原位，成为文件夹的兄弟）：

```
requirements/
├── FR-<system>-<slug>.md            ← 父 FR（原位，status → broken-down）
└── FR-<system>-<slug>/              ← 本技能新建
    ├── _index.md                    ← 拆解台账 + 覆盖映射表 + 构建顺序
    ├── FR-<system>-<slug>-01-<subslug>.md
    ├── FR-<system>-<slug>-02-<subslug>.md
    └── ...
```

- **子需求 id = `<父 id>-<两位序号>-<subslug>`**。序号即**默认构建顺序**；`depends-on` 写明真实依赖（可与序号一致，也可标出并行分支）。
- 每个子需求从 **`_TEMPLATE-sub.md`** 生成，`parent:` 指回父 FR，`source-docs:` **继承父 FR 的**（子需求不新增来源——新来源意味着你在臆造）。
- **子需求 `status` 继承父 FR 的签核状态**：父 `ready` → 子 **`ready`**（父 FR 的签核即覆盖其拆解；见下方「已知边界」）；父 `draft` → 子 **`draft`**。
- `_index.md` 内容：子需求一览表（`id | title | status | depends-on | blueprint`）、**父 FR 验收标准 → 子需求覆盖映射表**、建议构建顺序、以及本次拆解未能覆盖的条目。

### 6. 闭环台账
- **父 FR**：`status` → `broken-down`，新增 `breakdown: requirements/FR-<system>-<slug>/`。**不删改父 FR 的验收标准**——它仍是覆盖核对的基准。
- **`requirements/_index.md`**：父 FR 那一行的 `status` 改为 `broken-down`，并在其下追加各子需求的行（缩进标记 `└`，`blueprint` 列留空待 `/blueprint` 填）。
- 提示用户：对第一个子需求跑 `/blueprint FR-<sub-id>`。

### 7. 已知边界（照实说，不要自己扩权）
- **签核语义：** 本技能默认「**父 FR 签核即覆盖其子需求**」，故子需求直接产出为 `ready`。若用户希望逐个签核子需求，改为一律产出 `draft` 并在报告中说明——这是用户的选择，不要替他们定。
- **不评估 derive 就绪度。** 就绪度归 `/assess-derive-readiness`（`open-questions.md`「derive 就绪度」小节的唯一写入者）。本技能不写该小节、不给就绪度结论。
- **不改设计。** 拆解过程中发现设计缺口 → 记入子需求的 `## Open questions` 并在报告中浮现，**不要**顺手去改 `systems/` / `ux/`。

## 输出形态
```
## Broken down: FR-<id> — <父 FR 标题>

- library: <game-design-documents | backend-design-documents>

### 子需求（构建顺序）
- FR-<id>-01-<subslug> (<status>): <title>   [depends-on: —]
- FR-<id>-02-<subslug> (<status>): <title>   [depends-on: 01]
- ...

### 覆盖核对
- 父 FR 验收标准 <N> 条 → 全部覆盖 ✅  /  未覆盖：<条目 + 原因>

### Open questions（下发 / 新增）
- <子需求 id>: <问题>

### Next
- /blueprint FR-<id>-01-<subslug>
```
