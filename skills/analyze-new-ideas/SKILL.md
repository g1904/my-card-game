---
name: analyze-new-ideas
description: 接收一份原始想法记录（一个 handoff/inbox 文件或粘贴的文本），把它重写成整洁的 handoff，加以充实，并提炼进设计文档。
argument-hint: <原始文件路径 | 粘贴的想法文本 | 主题提示>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Analyze New Ideas

把原始的设计意图转化为整洁、充实的 handoff，并传播进 `game-design-documents/`。
这是人类意图捕获流水线：**原始 → handoff → 主题文档（→ ADR 候选）**。

**范围：** 本技能拥有全部权限，编辑范围**不限于** `game-design-documents/`。新想法本就可能牵涉工具配置（`.claude/`）、跨目录重构、乃至游戏代码——按用户意图执行。默认重心仍是设计意图捕获（`game-design-documents/`），但当想法要求触及别处时，径直去做。
- `game-design-documents/` 是用户的事实来源：不要删除或重排他们既有的意图——用取代（supersede）与追加（append）的方式处理。
- 触碰游戏代码（`game-*-branch/`）通常应留给后续的 `/blueprint` → `/implement`；仅在用户明确要求时才在本技能内直接改代码。

## 步骤

### 1. 定位原始输入
解析 `$ARGUMENTS`：
- 一个**文件路径**（如 `game-design-documents/handoffs/2026-07-13.md` 或 `inbox/draft.md`）→ 读取它。
- **粘贴的文本** → 把该消息当作原始记录；你将为它创建一个新的 handoff 文件。
- 仅有一个**主题提示** → 询问用户原始内容在哪里。
- **一份 `inbox/solution-draft-<slug>.md`**（`/provide-solution-draft` 的产物，用户已评审 / 修改过）→ 当作原始意图读取。注意其中标注 `[取向选择]` 或列在 `## 仍需用户决定` 的项：**用户已在评审中定下的按定下的处理，未定的仍按 Open question 搁置**，不要把提案当成已定案提炼。
- **空（无参数）→ 扫描收件箱**：列出 `game-design-documents/inbox/` **顶层**的草稿（`_index.md` / `_TEMPLATE.md` 与 `archive/` 除外——`archive/` 里的都是已提炼的，不再是待处理项），并与 `handoffs/_index.md` 交叉核对是否确已被处理。呈现待处理清单（文件名 + 一行内容摘要），询问处理哪个（或按用户指示批量逐个处理）。这可以防止草稿在收件箱中悄悄积压。

先逐字读完输入。此时先不要润色——理解写下的意图本身，包括那些尚未成形的想法。

### 2. 了解目标结构（写之前先读）
1. `game-design-documents/README.md` — 流水线、文件夹图例，以及状态词汇（`raw | triaged | distilled`）。
2. `game-design-documents/handoffs/_TEMPLATE.md` — 需要遵循的 handoff 形态。
3. 各主题 `_index.md` 文件，以及该想法可能注入的具体文档：
   - `terminology.md`（根级）— 术语事实来源（中文领域词 ↔ 英文/代码标识符）。凡引入/重命名领域词汇的想法都要在此登记。
   - `vision/`（支柱、参考、范围）— 用于奇幻设定/基调/范围层面的意图。
   - `systems/` — 玩法系统（map-progression、adventure-event-combat、run-manager、deck-hand 等）。
   - `30-content/` — 内容设计（cards、relics、enemies、adventure-events、events、balance）。
   - `ux/` — 屏幕、流程、手感。
   - `decisions/` — 已敲定的决策（ADR）。
   匹配文件名——主题文档与 `.claude/knowledge/` 一一对应。

目标：在动笔之前，弄清既有约定，以及这个想法应路由到哪些文档。

### 3. 把原始内容重写成整洁的 handoff
产出一份符合 `_TEMPLATE.md` 的 handoff：
- **Frontmatter：** `id: <YYYY-MM-DD-slug>`、`date`、`topic`（它注入哪个/哪些文档）、`status`、`distilled-to`。
- **Intent（distilled）：** 把用户的话重写成清晰的行文与结构——修正术语，格式化列表/表格，加一句电梯式/一行摘要，并**充实**：把隐含结构显性化（阶梯、循环、序列），把用户暗示到的后果写清楚。充实的是*措辞与组织*，**而非臆造机制**（见第 5 步）。
- 视内容需要，加入 **Design pillars / anti-goals** 等。
- 保留领域术语原样（如修真术语 炼气/筑基/金丹/元婴、被引用的游戏名），首次出现时附上简短英文注释。

**写入哪个文件：**
- 原始输入已经在 `handoffs/` 中且 `status: raw`（刚捕获、未处理）→ **就地**清理。
- 粘贴的文本或来自 `inbox/` 的内容 → 创建一个**新的** `handoffs/<YYYY-MM-DD-slug>.md`。
- 取代 / 修订一份已经 `distilled` 的 handoff → 通常新建一份新 handoff 承载新意图；但 handoff **并非仅追加**，若就地编辑更清楚（订正、去重、合并）则直接改（历史归 git；见 README）。

### 4. 提炼进设计文档
对该 handoff 注入的每个文档，把意图折进其活跃小节（`## Intent`，以及相关时的 `Open questions`、`Decisions`）。保持增量——扩展既有条目，不要抹掉先前的意图。每条提炼出的条目都应可回溯：加上 `Source: handoffs/<id>.md`。
- 用真实内容填充空的模板占位符（`> _..._`）。
- 当想法带有系统/内容/UX 层面的含义（而不仅是愿景）时，为主题文档（`systems/` / `art/` / `ux/`）播种。
- 把已敲定的方向性决策记为 **ADR 候选**（除非用户要求，否则不要写 ADR——那是 `decisions/` 的步骤）。ADR 可自由编辑：要改一个决定，直接改那份 ADR，不必新开取代 ADR（历史归 git）。

### 5. 区分充实与臆造（强制）
- **充实：** 澄清、结构化，并推演出从用户所说内容中逻辑上必然得出的含义。
- **不要臆造**用户未陈述的机制、数字或决策。任何无法从输入推导出的内容都放入 **`## Open questions`**，以问题的形式表述——绝不断言为意图。
- **标出矛盾**：把原始输入中的矛盾（如"说是三个，却列了四个"）在 Open questions 中明确指出，附上你解读后的结论，并向用户点明以待确认。

### 6. 维护 open-questions 清单 + answer-logs（跨 session 循环，强制）
`game-design-documents/open-questions.md`（索引）+ `open-questions/`（按主题分片）是跨 session 的**待答清单**——让未拍板的问题不丢失、下次能拾起。它**只跟踪仍待答的问题**：不含「已解决」区，已答定的问题一律移入 `game-design-documents/answer-logs/`。**每次运行本技能，在收尾时都要刷新两者：**

**6a. open-questions 清单（索引 + 分片）**
- **结构：** 索引 `open-questions.md` 只承载说明、`## 分片导航`、`## 当前焦点`（判据）、`## derive 就绪度`、`## 下一阶段`；**问题条目一律落在 `open-questions/<分片>.md` 中**（`01-combat.md` … `07-codex-monetization.md`、`deferred-content.md`），逐次更新摘要落在 `open-questions/update-log.md`。**不要把问题条目写回索引。**
- **移出已答：** 本 session 被用户拍板/回答的问题，从所在分片删除，并确认已归档进对应主题文档（`## 决策` 或 `## 意图`）。**移出的条目写进本次的 answer log（见 6b），不要在分片里留「已解决」区。**
- **并入新增：** 本 session 新产生、仍未决的 Open questions 汇总进对应主题的分片（没有合适分片时新建一份并在索引导航表中登记），并指向其所属文档。
- 索引顶部记一句"最近更新：<日期>"，并在 `open-questions/update-log.md` **顶部**追加本次摘要（答结 / 推翻 / 新增落点 / 对应 answer log）。保持清单与各主题文档 `## Open questions` 一致（清单是导航/拾取用，主题文档是权威归属）。
- **分片过长时再拆**：某分片膨胀到难以通读，就按其内部小节拆成两份并更新索引导航表。
- 若正文里有指向已移出条目的引用（如「见上方已解决」），改为指向对应的 `answer-logs/log-<draftSuffix>.md`。
- **不要碰「derive 就绪度」小节（强制）。** 该小节由 `/assess-derive-readiness` 独占写入——见下方第 8 步。

**6b. answer-logs/log-\<draftSuffix\>.md（每次运行新建一个文件）**
- **`draftSuffix` 取值：** 本次处理的输入是 `inbox/draft-<suffix>.md` → 用该 `<suffix>`（例：`draft-0725_2.md` → `log-0725_2.md`）；输入是 `inbox/solution-draft-<slug>.md`（`/provide-solution-draft` 的产物）→ 用该 `<slug>`（例：`solution-draft-rng-persistence.md` → `log-rng-persistence.md`）；输入是粘贴文本或已在 `handoffs/` 的文件 → 用当天 `MMDD`；若同名文件已存在，追加 `_2`、`_3`。
- **每次移出新建一个文件，绝不追加进旧 log。** 本次若一个问题都没答定，则**不建文件**。
- 文件内容：标题 `# Answer log <draftSuffix>`，然后 `日期` / `来源`（handoff 或草稿路径）/ `移出条数`，再逐条 `**<问题>** → <结论>（<归档去向文档>）`。若某问题只答定了一部分，写明剩余部分仍留在待答清单。
- 在 `answer-logs/_index.md` 的台账表追加一行：`log 文件 | 日期 | 来源 | 移出条数`。
- log 是**只读的历史记录**，不是权威——结论的权威归属仍在主题文档与 ADR。不要回头编辑旧 log。

### 7. 更新索引并闭环
- 在 `handoffs/_index.md` 中新增/更新对应行（最新的置顶）：`id | date | topic | status | distilled-to`。一旦折进主题文档，就把 `status` 设为 `distilled`，并在 `distilled-to` 填上你改动过的文件。
- **归档草稿（强制）：** 若本次输入是 `inbox/` 顶层的一份草稿，且已产出 `status: distilled` 的 handoff，就把该草稿**移入 `inbox/archive/`**（`solution-draft-*` 同时把 front-matter 的 `status` 改为 `distilled`），并在 `inbox/archive/_index.md` 的对应表追加一行「草稿 → handoff」。若它仍留在顶层的在办清单里，从 `inbox/_index.md` 的清单中删掉该行。**顶层只留在办草稿**——这是收件箱不再堆积的机制。
- 向用户汇报：
  - 该 handoff 现在的内容（清理/充实后的版本）。
  - 你扩展了哪些设计文档以及关键新增内容。
  - 你标出的 **Open questions 与任何矛盾**——尤其是需要用户确认的部分。

### 8. 不评估 derive 就绪度（强制边界）
**本技能绝不评估、断言或更新任何文档的 derive 就绪度**，也不建议用户去跑 `/derive-requirements`。

- 不写入 `open-questions.md` 的「derive 就绪度」小节；不在主题文档中写「可 derive / 暂缓 derive / 已解锁 derive」之类的判定；报告中也不给就绪度结论。
- 理由：设计仍在快速演进，逐次 handoff 顺带下的就绪度判定会迅速过时、且不同 session 之间互相矛盾。就绪度必须**基于全库一次性全量扫描**才有意义。
- 就绪度归 **`/assess-derive-readiness`**（全量扫描，是该小节的唯一写入者），**由用户在时机成熟时手动调用**。若用户在本技能中问起就绪度，就指向那个技能，不要就地判断。
- 若在提炼过程中发现某处**遗留的**就绪度断言（旧 handoff / 主题文档中的「可 derive」等），**顺手删除或中性化**，不要沿用。

## 输出形态
```
## Analyzed: <一行想法摘要>

### Handoff
- file: handoffs/<id>.md  (status: <raw→distilled>)
- key enrichments: <条目>

### Distilled into
- <doc>: <新增了什么>
- ...

### Open questions / needs confirmation
- <已解决的矛盾、以问题形式搁置的未知项>

### Answered (moved out)
- file: answer-logs/log-<draftSuffix>.md  (<N> 条；无则写「本次无移出」)
```

> 输出中**不含** derive 就绪度 / 下一阶段建议——见第 8 步。
