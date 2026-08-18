---
name: provide-solution-draft
description: 取一个待答问题（open-questions.md 中的条目、主题文档的 Open question，或粘贴的问题文本），基于本库既有设计与行业通行做法推演出一份**提案式**解决方案，写成 inbox/solution-draft-<slug>.md 供用户评审。作用于客户端或后端设计库（二选一）。只写这一个草稿文件，不改任何设计文档、不裁决问题。
argument-hint: [--lib=game|backend] <问题文本 | open-questions.md 中的条目关键词 | 主题文档路径（留空则列出候选问题）>
allowed-tools: Read, Write, Glob, Grep, Bash
---

# Provide Solution Draft

系统设计成熟到一定程度后，`open-questions.md` 里的很多问题**不再需要用户凭偏好拍板**——它们可以由**行业通行做法**加上**本库既有决策的逻辑推演**得出答案。本技能就是那一步：把一个待答问题变成一份**有依据、可评审的解决方案草稿**，落在 `<LIB>/inbox/`。

**它不是拍板。** 草稿是提案，人类评审（保留 human-in-the-loop）后，再由 `/analyze-new-ideas` 把它当作原始意图输入，走 handoff → 主题文档的正常提炼流水线。

流水线定位：
```
open-questions.md 中的待答项
  → /provide-solution-draft <问题>          （本技能：推演 + 写草稿）
  → inbox/solution-draft-<slug>.md       （用户评审 / 修改 / 部分否决）
  → /analyze-new-ideas inbox/solution-draft-<slug>.md   （提炼进主题文档 + 移出待答项）
```

**范围守则（强制）：** 只写 `<LIB>/inbox/solution-draft-<slug>.md` 这一个草稿文件，外加在 `<LIB>/inbox/_index.md` 的「待处理」表登记一行（见第 6b 步）。**若问题本身横跨客户端 ↔ 后端边界**，按 `.claude/rules/design-library-routing.md` 的「跨库纪律」，**允许在对侧库同样落一份草稿 + 台账行**（两份草稿各写自己那一半、互相回链，见第 6c 步）。**不**改 `open-questions.md` 与 `open-questions/`（移出待答项归 `/analyze-new-ideas` / `/summarize-open-questions`）、**不**改任何主题文档（客户端 `systems/` / `art/` / `ux/` / `vision/`；后端 `contracts/` / `systems/` / `operations/` / `vision/`）、**不**写 ADR、**不**碰 `handoffs/`、**不**碰代码。**不评估 derive 就绪度**（归 `/assess-derive-readiness`）。

## 步骤

### 0. 确定目标设计库（强制，先于一切）
按 `.claude/rules/design-library-routing.md` 解析本次作用于 `game-design-documents/` 还是 `backend-design-documents/`：显式库参数 → 参数中的路径前缀 → 相对路径落地探测 → 都判不出就**询问用户，绝不静默默认**。

选定后，**下文所有写作 `game-design-documents/` 的路径一律读作 `<LIB>/` 下的同名路径**。在报告开头点明本次作用的库。

**问题的归属先于方案。** 若锁定的问题实际**整个**属于另一库（判据见路由规则的归属表——由谁实现），**停下并指出**，不要在当前库里给它写草稿。

**若问题横跨边界**（一半归客户端、一半归后端——典型：协议契约不一致、一侧定案给另一侧新增义务），**不要拆成两次运行**：确定主库后，按第 6c 步在**两侧各写一份草稿**，每份只承载归属判据判给它的那一半，互相回链。理由见路由规则「跨库纪律」的改写说明——拆成两次运行时，第二次经常不会发生。

### 1. 锁定问题
解析 `$ARGUMENTS`：
- **粘贴的问题文本** → 直接采用；同时在 `open-questions/` 的各分片中检索是否已有对应条目（有则以清单里的措辞为准，并记下其所在分片与 `→` 指向的权威文档）。
- **关键词 / 条目片段** → 在 `open-questions/` 分片与各主题文档的 `## 待决问题` / `## Open questions` 中 `Grep`，定位唯一匹配；多个匹配 → 列出让用户选。
- **主题文档路径** → 读该文档的待决问题小节，列出其条目让用户选（一次一个问题，不要一口气批处理多个不相关问题）。
- **空（无参数）** → 读 `open-questions.md` 的分片导航表并逐份读取分片，按主题列出待答条目，并**标注哪些适合本技能**（可由通行做法 / 既有约定推演）vs **哪些必须由用户取向决定**（纯玩法手感、美术基调、商业化取舍）。询问处理哪一个。

一次运行处理**一个问题**（或一组紧密耦合、必须一起答的子问题）。范围过宽的草稿无法评审。

### 2. 读全上下文（写之前先读）
在推演之前，必须读到：
- `open-questions/` 中该条目所在的整份分片（相邻问题往往互相约束）。
- 该条目 `→` 指向的**每一份**权威文档：既有的 `## 意图` / `## 决策`，以及它的待决问题。
- `<LIB>/vision/scope.md`（范围 / 硬约束）与 `vision/pillars.md`。
  - **客户端库**另读 `program-overview.md` + `system-overview.md`（运行时 + 工程视角的结构约束）、`terminology.md`（该问题涉及的领域词与代码标识符）。
  - **后端库**另读 `contracts/_index.md`（边界报文的现状与计划）、以及被该问题牵动的 `game-design-documents/systems/services/*`（客户端侧已定的语义是硬前提）；术语沿用 `game-design-documents/terminology.md`。
- 相关 `decisions/ADR-*`——**已固化的决策是硬边界**，方案不得与之冲突（若确有冲突，见第 5 步）。
- 涉及实现形态时：**客户端库**读 `.claude/rules/*` 中对应领域规则（数据资源、存档 / RNG、UI / 输入、C#↔Godot）与 `game-feature-branch/` 的现状（**不要假定某系统已存在**）；**后端库**无对应规则与知识层，且技术栈未定——**不要指定语言 / 框架 / 库**，把方案停在协议与语义层面，实现形态留给栈落定后。
- 相关 `answer-logs/log-*.md`——避免重新提出一个已被答定或已被否决的方案。

### 3. 推演方案（三类依据，逐条标注）
每一项提案都必须标注它站在什么之上：
- **`[既有推演]`** —— 从本库已定的决策 / 约定逻辑上必然（或强烈倾向）得出。**最强依据**，应优先。引用具体来源（文档 + 小节）。
- **`[通行做法]`** —— 行业标准实践或同类作品（Balatro / Slay the Spire / 月圆之夜 等）的惯常解法。写明为什么它适用于本作的约束（移动优先 · 竖屏 · 强制在线 · 云端权威 · 休闲）。
- **`[取向选择]`** —— 无客观最优、取决于用户的玩法 / 产品取向。**不要替用户拍**：并列 2–3 个选项 + 各自后果，给出**推荐项与理由**，明确标注「待用户选定」。

同一问题内可混用；关键是读者一眼能看出哪些是安全的、哪些需要他点头。

### 4. 给出可落地的具体形态
一份「方向正确但无法实现」的草稿没有价值。视问题类型给出具体到能被 `/derive-requirements` 消费的形态：
- **数据 / 内容问题** → 字段名（用 `terminology.md` 的标识符）、类型、取值范围、默认值、`Id` 约定、校验规则。
- **服务 / API 契约问题** → 方法签名、参数 / 返回类型、事件负载 schema、所属服务与 manager、调用方向（遵守两条唯一入口与编排顶点的约定）。
- **存档 / 同步问题** → schema 字段、版本化与迁移、原子写入点、云端冲突语义。
- **UX 问题** → 竖屏布局位置、触控交互、状态与反馈、无 hover-only 可供性。
- **平衡数值问题** → 给**初值 + 推导过程 + 可调旋钮位置**（数值属数据资源，不硬编码），并明确它是待实测校准的初值。

### 5. 冲突与不可推演项（强制）
- **与既有决策 / ADR 冲突** → 不要偷偷绕过，也不要擅自改 ADR。在草稿的 `## 与既有决策的张力` 中写明：冲突的是哪一条、为什么方案需要它松动、松动的代价、以及**不松动时的替代方案**。由用户裁决。
- **依赖尚未答定的其他问题** → 列在 `## 前置依赖` 中，写明「本方案的 X 部分在 <前置问题> 答定前无法定稿」，不要用臆造的前提把它填满。
- **确实无法由推演 / 通行做法得出**（纯取向、或缺关键信息）→ 如实说明，把它留在 `## 仍需用户决定`，并说明缺什么信息。**绝不为了让草稿完整而臆造机制、数字或决策**（与 `/analyze-new-ideas` 的「充实 vs 臆造」同一条边界）。

### 6. 写草稿文件
写到 `<LIB>/inbox/solution-draft-<slug>.md`（**顶层 = 在办**；提炼后由 `/analyze-new-ideas` 移入 `inbox/archive/`——本技能不写 `archive/`）：
- **`<slug>`：** 由问题主题取的短横线小写 slug（英文 / 代码标识符优先，便于与主题文档对应），例：`solution-draft-hotfix-overlay-scope.md`、`solution-draft-skip-cost-semantics.md`、`solution-draft-rng-persistence.md`。同名已存在 → 追加 `-2`、`-3`（不覆盖用户可能已在评审的草稿；若确认是同一问题的重做，先问用户是否覆盖）。
- **结构：**
```markdown
---
type: solution-draft
date: <YYYY-MM-DD>
question: <一行问题陈述>
source: open-questions/<分片>.md → <主题小节>   # 或 systems/xxx.md#待决问题
targets: <本方案若被采纳应提炼进的文档路径清单>
status: awaiting-review
---

# 方案草稿 — <问题标题>

## 问题
<问题的完整陈述：它为什么悬着、卡住了什么。>

## 约束（来自既有设计）
- <硬约束 + 来源文档 / ADR>

## 建议方案
### <子项 1>
`[既有推演]` / `[通行做法]` / `[取向选择]`
<具体形态：字段 / 签名 / 布局 / 数值 + 依据>

### <子项 2>
...

## 具体形态（可 derive 的落地面）
<字段表 / 签名 / schema / 数值表——视问题类型>

## 后果
- 对哪些文档 / 系统 / 存档 schema 产生影响；是否需要迁移。

## 备选方案（已考虑并否决）
- <方案> — 否决理由。

## 与既有决策的张力
<有则写，无则写「无」。>

## 前置依赖
<依赖哪些仍待答的问题；无则写「无」。>

## 仍需用户决定
- <取向选择项：选项 + 推荐 + 理由>
```
- 语气一律是**提案**，不写成既定事实（用「建议 / 推荐 / 倾向」，不用「已定 / 决定为」）——定案权在用户，落笔权在 `/analyze-new-ideas`。
- **文件落在 `inbox/` 的顶层**，不放进 `archive/`（那里只装已 `distilled` 的旧草稿）。

### 6b. 登记进 inbox 台账（强制）
在 `<LIB>/inbox/_index.md` 的「待处理（ongoing）」表**顶部**追加一行：`文件 | 类型 | 日期 | 主题 | 下一步`。

- `类型` 写 `solution-draft`；`下一步` 写 `评审后 /analyze-new-ideas`，若草稿有 `## 仍需用户决定` 项则写成 `评审 <K> 项取向后 /analyze-new-ideas`。
- 若表中当前是 `*（空）*` 占位行，用你这一行替换掉它。
- **只动这张表**：不要碰同文件的「已归档」表（那是 `/analyze-new-ideas` 归档时才写的）。

### 6c. 跨边界问题：对侧库的配套草稿（仅当问题横跨边界）
在对侧库写 `<对侧LIB>/inbox/solution-draft-<slug>.md`（**slug 与主库那份相同**，便于成对识别），并同样登记进该库的 `inbox/_index.md` 待处理表。两份草稿的分工：

- **每份只写归属判给它的那一半**：报文 / 端点 / 服务端兑现 → 后端库；客户端字段 / 存档 / 服务调用形态 → 客户端库。
- **front matter 增加一行 `counterpart: <另一库>/inbox/solution-draft-<slug>.md`**，两份互指。
- **绝不复述对方那一半的内容**——需要引用时写路径回链。抄过去等于制造第二权威。
- 两份的 `## 前置依赖` 中互相列出对方：「本方案的 X 部分须与 `counterpart` 的 Y 部分同时采纳，单侧采纳即两侧不一致」。
- **两份都是提案**，不在任一侧替用户拍板。

### 7. 报告并交回人类
```
## 方案草稿：<问题一行摘要>

- library: <game-design-documents | backend-design-documents>
- file: <LIB>/inbox/solution-draft-<slug>.md（已登记进 inbox/_index.md 待处理表）
- 依据构成：既有推演 <N> 项 · 通行做法 <M> 项 · 取向选择 <K> 项

### 建议要点
- <每条一行>

### 需你决定（<K> 项）
- <取向选择项 + 推荐>

### 张力 / 前置依赖
- <有则列，无则省>

下一步：评审并按需修改该草稿，然后运行
  /analyze-new-ideas <LIB>/inbox/solution-draft-<slug>.md
以提炼进主题文档并把该问题移出待答清单。
```
- 若最终判定该问题**不适合**本技能（纯用户取向、或信息不足）→ **不建草稿文件**，直接报告为什么，并列出需要用户先提供的信息。

## 批量模式（worker 契约）

本技能有批量版 **`/batch-provide-solution-draft`**（多分片并行 / 波次编排，合并 interview）。被其派为 worker 运行时，按 `.claude/rules/batch-orchestration.md` 的「worker 契约」执行三点覆盖：① interview / 澄清门不调用 `AskUserQuestion`——Phase A 把问题写进 run 目录并停止，Phase B 把 `answers.md` 视同用户当面裁决；② 共享台账（各 `_index.md`、`open-questions*`、`update-log`）不写，台账行随报告交回由 orchestrator 代笔；③ 范围锁定在派单分片，越界发现只记报告。其余步骤原样执行。直接被人运行时本节不适用。
