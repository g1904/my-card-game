---
name: summarize-open-questions
description: 扫描 game-design-documents/ 的全部 ## Open questions 与 handoff，把散落的未决项汇总、去重、按主题归拢，并重写 open-questions.md 这份跨 session 待答清单。同时把已答定的问题移出、核对其已归档，并记入 answer-logs/log-<draftSuffix>.md。只写 open-questions.md 与 answer-logs/，不裁决问题本身。
argument-hint: [主题过滤：systems | content | ux | vision | all（默认 all）]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Summarize Open Questions

`game-design-documents/open-questions.md` 是跨 session 的**待答清单**——让未拍板的问题不丢失、下次能拾起。它**只跟踪仍待答的问题**（不含「已解决」区）；权威归属仍在各主题文档的 `## Open questions`。已答定的问题移入 `game-design-documents/answer-logs/log-<draftSuffix>.md`（一次运行一个文件，见步骤 5b）。本技能对账两者，把散落的未决项汇总成一份整洁、去重、按主题归拢的清单，并把已答定的问题移出。

`/analyze-new-ideas` 在收尾时会顺手刷新此文件；本技能是它的**专职、可独立运行**版本——不引入新想法，只做归集与整理，用于清单变脏、积压或与主题文档漂移时的一次性重整。

**范围守则：** 只写 `game-design-documents/open-questions.md` 与 `game-design-documents/answer-logs/`。**不**改各主题文档（它们是权威归属，编辑归用户/`/analyze-new-ideas`），**不**裁决任何问题（拍板归用户）。若发现某主题文档的 `## Open questions` 本身有错漏或与 `## 决策` 矛盾，如实报告给用户，不擅自改动主题文档。

## 步骤

### 1. 确定范围
解析 `$ARGUMENTS`：`systems`（`20-systems/`）/ `content`（`30-content/`）/ `ux`（`40-ux/`）/ `vision`（`00-vision/`）之一 → 只汇总该目录；`all` 或空 → 全部主题目录。

### 2. 采集散落的未决项（写之前先读）
- `Grep` 全部主题文档中的 `## Open questions`（含 `Open question` 的各种写法），连同其小节正文一并读出：`00-vision/`、`20-systems/`、`30-content/`、`40-ux/`。
- 读 `10-handoffs/` 中 `status: raw | triaged`（尚未 `distilled`）的 handoff 里标出的未决项与矛盾——这些可能还没进主题文档。
- 读根级 `terminology.md`（若有悬而未定的术语）。
- 读现有的 `open-questions.md`——保留其结构，作为对账基线。
- 读 `answer-logs/_index.md` 与既有 log 文件名——**避免把已经移出过的问题重新捞回待答清单**，并确定本次 log 的命名不与既有冲突。
- 对每个未决项，记住它的**来源文档路径**，以便在清单里指回其权威归属。

### 3. 对账「已答 → 移出并核对归档」
逐条比对现有 `open-questions.md`「待答」区的每个问题：
- 若其权威主题文档现已在 `## 决策` / `## 意图`（或 `50-decisions/ADR-*`）给出定论 → 从「待答」移除，并在**本次的 answer log**（第 5b 步）记一行，附归档去向（`文档路径`）与一句结论。**不在 `open-questions.md` 里保留任何「已解决」区。**
- 若仍无定论 → 保留。
- **只依据主题文档的既有内容判定「已答」**；本技能自身不回答问题、不把问题标记为已答。

### 4. 汇总、去重、按主题归拢
把第 2 步采集到的全部未决项 + 现有清单中仍待答的项，合并成新的「待答」区：
- **按主题分组**（与目录/知识领域对齐：run-manager、adventure-event-combat、map-progression、cards、balance、screen-flow、云同步 等）。沿用现有清单里已成形的分组名。
- **去重与合并**：同一问题在多处出现 → 合并成一条，措辞取最清晰者。相关的小问题可归到同一子弹的从属项。
- 每条以**问题形式**表述（不是断言），并**指回权威文档**（`→ 20-systems/xxx.md` 或 `→ 未来的 30-content/balance.md`）。保留原有的重点标注（但**不要**保留或新写 derive 就绪度类断言——见第 5 步）。
- **标出矛盾**：采集中发现的原始矛盾（如「说三个却列了四个」）明确列出，附解读结论，点名待用户确认。

### 5. 重写 open-questions.md
用整理后的内容整体重写该文件（这是允许覆盖它的情形——它是派生的导航清单，非事实来源）：
- 顶部保留标题与说明句，更新「最近更新：<今天日期>」。
- **清除任何误入的乱码/残留文本**（如文件头被意外粘入的字符）——这类清洗正是本技能的职责。
- 结构：`## 待答（按主题）` → `## derive 就绪度`（**原样保留，不得改动**）→ `## 下一阶段`。**没有「已解决」区**——移出的条目只存在于 `answer-logs/`。
- 若正文中残留指向已移出条目的引用（如「见上方已解决」），改为指向对应的 `answer-logs/log-<draftSuffix>.md`。
- **「derive 就绪度」小节由 `/assess-derive-readiness` 独占写入（强制）。** 整体重写本文件时**原样保留**该小节，不评估、不更新、不删除；报告中也不给就绪度结论。理由：就绪度需基于全库一次性全量扫描，顺带评估会迅速过时且互相矛盾。
- 「下一阶段」小节：只记**可固化为 ADR 的已定方向**；**不写** derive 建议。

### 5b. 写本次的 answer log（每次运行新建一个文件）
把第 3 步移出的条目写进 `game-design-documents/answer-logs/log-<draftSuffix>.md`：
- **`draftSuffix` 取值：** 本技能通常无草稿来源 → 用当天 `MMDD`；若本次整理明确对应某份 `90-inbox/draft-<suffix>.md` → 用该 `<suffix>`；若同名文件已存在，追加 `_2`、`_3`。
- **每次移出新建一个文件，绝不追加进旧 log。** 本次若没有任何条目被移出，则**不建文件**，报告里写「本次无移出」。
- 文件内容：标题 `# Answer log <draftSuffix>`，然后 `日期` / `来源`（本次整理的范围或对应草稿）/ `移出条数`，再逐条 `**<问题>** → <结论>（<归档去向文档>）`。部分答定的，写明剩余部分仍留在待答清单。
- 在 `answer-logs/_index.md` 的台账表追加一行：`log 文件 | 日期 | 来源 | 移出条数`。
- log 是**只读的历史记录**，不回头编辑旧 log；结论的权威归属仍在主题文档与 ADR。

### 6. 报告
```
## Open questions 整理：<范围>

### 移出（已答定，已核对归档）→ answer-logs/log-<draftSuffix>.md
- <问题> → <结论>（归档于 <文档>）

### 待答汇总（按主题）
- <主题>：<N 条>（新并入 <M> 条，去重合并 <K> 条）

### 需用户确认
- <标出的矛盾 / 主题文档自身的错漏>
```

> 输出中**不含** derive 就绪度——该判定归 `/assess-derive-readiness`（用户手动调用）。
