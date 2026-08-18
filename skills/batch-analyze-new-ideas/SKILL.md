---
name: batch-analyze-new-ideas
description: /analyze-new-ideas 的批量版：一次处理一批 inbox 草稿（含已评审的 solution-draft）。Phase A 并行只读校验各草稿并汇集全部 🔴/🟠 问题，合并去重后开一场大 interview 由用户统一裁决，Phase B 按写入面分区落笔提炼进设计库。覆盖客户端与后端两库。所有单会话的校验门与充实/臆造边界原样保留。
argument-hint: [--lib=game|backend|两库] <草稿路径清单（分号分隔）| 空（扫描两库 inbox 待处理，列出让用户圈选）>
---

# Batch Analyze New Ideas

编排规则见 `.claude/rules/batch-orchestration.md`。worker 执行的单会话技能是 **`/analyze-new-ideas`**——校验分级、interview 判据、溯源三条、open-questions / answer-logs 维护，全部以它为准。

批量相对逐个跑的价值：积压的草稿一次清完；同一批背景文档（scope、ADR、路由规则）不再每个 session 重读一遍；**草稿之间的矛盾在落笔前暴露**（两份草稿往不同文档写互相打架的意图——逐个跑时第二个 session 未必发现第一个刚写的内容）。

## 步骤

### 1. 圈定批次（用户确认，强制）
- **给了路径清单** → 逐个定位（库归属按 `.claude/rules/design-library-routing.md` 解析）。
- **空** → 照单会话技能第 1 步的空参数逻辑扫描**两库** `inbox/` 顶层与 `_index.md` 待处理表（不一致以实际文件为准，顺手报告），列出待处理草稿（文件名 + 一行摘要 + 库归属），请用户圈选本批。
- 粘贴文本不入批——单条粘贴文本直接走单会话 `/analyze-new-ideas`。

### 2. 分区与波次
- 快速略读每份草稿的主题与 `targets`（solution-draft 有此字段；普通草稿按内容预判），推算**每份草稿的拟写入文档集合**（主题文档 + handoff + answer-log）。
- **拟写入集合相交的草稿 → 同一 worker 或先后波次**（铁律 ③）。跨库草稿交给一个 worker 两侧落笔（单会话技能已允许）。
- 每份草稿的 handoff 文件名、answer-log 的 `draftSuffix` 按单会话技能既有规则由草稿名决定，天然不撞；orchestrator 只需确认同日多份粘贴类输入不会同名。

### 3. Phase A：并行只读校验（worker）
按 worker 契约派单：执行 `/analyze-new-ideas` 第 0–3 步（**只读，不写任何文件**），产出到 run 目录：
- 🔴 / 🟠 / 🔵 分级清单（含权威出处原话要点、选项与后果、推荐项）；
- 拟改动文档清单与各自的新增要点（供跨草稿核对）；
- 该草稿中「用户已在评审中定下」的项（solution-draft 的已裁决条目）——这些**不再进 interview**，照定案处理。

### 4. 合并 interview ⏸️
orchestrator 按 `batch-orchestration.md` 合并判据去重全部 🔴 / 🟠，并追加**跨草稿核对**：两份草稿的拟写入要点对同一对象矛盾、或一份草稿的前提被另一份推翻 → 新增 🔴。`AskUserQuestion` 分轮问齐，答案落 `answers.md`。答复引入新冲突 → 让受影响的 worker 重跑校验、补一轮。**未问完不落笔。**

### 5. Phase B：按分区落笔（worker）
worker 拿 `answers.md` 执行单会话技能第 5–8 步：写 handoff、提炼进主题文档（守溯源三条）、写自己的 `answer-logs/log-<suffix>.md`。**不写**：`handoffs/_index.md`、`open-questions.md` 与分片、`update-log.md`、`answer-logs/_index.md`、`inbox/_index.md`、草稿归档（第 9 步）——这些以「台账行 / 移出与新增条目清单」形式写进报告，orchestrator 代笔。第 10 步（不评估 derive 就绪度）照守。

### 6. 收尾（orchestrator 统一写共享台账）
逐库执行：
1. `handoffs/_index.md` 补行（最新置顶）。
2. `open-questions/` 分片：应用全部 worker 的移出与新增（同一分片多个 worker 有增删时在此合并）；`update-log.md` 顶部追加**一条**本批摘要；索引「最近更新」一行（守 ≤1 行硬上限）。
3. `answer-logs/_index.md` 补行。
4. 草稿归档：对满足单会话技能第 9 步三前置条件的草稿，改 frontmatter → `git mv` 进 `inbox/archive/` → 更新 `inbox/_index.md` 两张表；不满足的留顶层并在「下一步」列写清还差什么。
5. **不碰「derive 就绪度」小节。**

## 输出形态
```
## Batch analyzed: <N> 份草稿

- 范围：game <n> · backend <m> · 跨库 <k>（波次：<划分>）

### 校验与合并 interview
- 🔴 <a> 项 · 🟠 <b> 项 · 🔵 <c> 项 → 去重后 <Y> 问
- 跨草稿矛盾：<条目 + 裁决>
- 逐条裁决：<问题> → <裁决>

### 逐草稿（按库分区）
- <草稿> → handoff <id>（distilled）· 提炼进 <文档清单> · answer-log <文件>（<n> 条）· 归档 / 留顶层：<原因>

### Open questions（仍开放）
- <远期未知与 [采纳推荐 — 待复核] 项>

### 台账
- 已统一更新：handoffs/_index · open-questions 分片 ×<n> · update-log · answer-logs/_index · inbox/_index（逐库）
```
