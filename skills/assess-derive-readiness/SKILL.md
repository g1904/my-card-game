---
name: assess-derive-readiness
description: 全量扫描 game-design-documents/ 的全部主题文档，逐份判定它们是否已详尽到可以 /derive-requirements，并把结论整体重写进 open-questions.md 的「derive 就绪度」小节。由用户在时机成熟时手动调用。
argument-hint: <留空 = 全量扫描 | 单个文档路径 = 只报告该文档（仍不写入）>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Assess Derive Readiness

判定**设计意图是否已详尽到可以转化为功能需求**，并维护全库唯一的就绪度台账。

**为什么单独成为一个技能：** 就绪度是一个**全库横切**的判断——一份文档能否 derive，取决于它自身、它依赖的 vision、约束它的 ADR，以及它引用的其他系统是否也已落定。由 `/analyze-new-ideas` 在每次 handoff 时顺带评估，会产出**迅速过时且互相矛盾**的局部结论。因此就绪度只在**用户主动要求**时、以**一次全量扫描**的方式重新产出。

## 范围守则（强制）

- **唯一写入目标：`game-design-documents/open-questions.md` 的「derive 就绪度」小节**——整体重写该小节（不是追加），它是就绪度的唯一权威落点。
- **只读一切其他文档。** 不改主题文档、不改 handoff、不改 ADR、不改 `60-requirements/`、不碰游戏代码。发现设计缺口时**只报告**，不顺手补设计——那是 `/analyze-new-ideas`。
- **不生成 FR。** 产出 FR 是 `/derive-requirements` 的事；本技能只回答「能不能 derive、被什么卡住」。
- 唯一例外：若在扫描中发现主题文档 / handoff 里**遗留的旧就绪度断言**（「可 derive」「暂缓 derive」「解锁 derive」等），可就地删除或中性化——保持全库只有一处就绪度结论。

## 步骤

### 1. 解析目标
解析 `$ARGUMENTS`：
- **空（默认）→ 全量扫描**：`00-vision/`、`20-systems/**`（含子文件夹的 `_index.md` / `common-properties.md` / 各具体设计）、`40-ux/`、`50-decisions/`。
- **单个文档路径** → 只评估并**报告**该文档；**仍然不写入** `open-questions.md`（避免用局部结论污染全量台账）。明确告知用户这是一次局部预览。

### 2. 建立判定所需的上下文（写之前先读）
1. `game-design-documents/README.md` — 流水线与状态词汇。
2. `game-design-documents/open-questions.md` — 索引（含既有「derive 就绪度」小节，本技能的唯一写入目标）；待答问题条目本身在 `game-design-documents/open-questions/` 的各分片中，按需读取。
3. `game-design-documents/10-handoffs/_index.md` — 最近的意图流向（哪些文档刚被改动 = 结论最易过时）。
4. `game-design-documents/50-decisions/` — 哪些方向已固化为 ADR。
5. `game-design-documents/60-requirements/_index.md` — 哪些已经 derive 过（避免重复判定；已 derive 的部分标注为「已覆盖」）。
6. 逐份读取待评估的主题文档。

### 3. 逐份判定（判定标准）
一份文档 **ready**，当且仅当**三条全部**成立（与 `/derive-requirements` 的就绪性门一致）：
1. 它的 `## 意图` / `## Intent` 有**真实内容**，不只是模板占位符（`> _..._`）。
2. 它的 `## 待决问题` / `## Open questions` **为空，或每一条都已有决策 / ADR 覆盖**。
3. 它所挂靠的 `00-vision/` 意图在该点上**没有未决问题**，且约束它的 ADR 均为 Accepted。

**再叠加两条横切检查**（这是全量扫描相对逐份评估的价值所在）：
4. **依赖闭合：** 它显式依赖的其他系统 / 服务，在被依赖的那个点上也已落定。一份文档不能因为把关键机制"甩给"另一份仍空白的文档而显得就绪。
5. **无孤儿路径：** 文档描述的每条玩家路径 / 状态转换都有归属系统。（例：新增一条"跳过事件"通道却没有服务承接它 → 未就绪。）

**判定三档，不要含糊：**
- **ready** — 三条 + 两条横切全部满足。
- **partial** — 存在一个**可独立成立的就绪切片**，其余被明确列出的问题卡住。必须写清哪个切片可 derive、其余被什么卡住。
- **blocked** — 未就绪。必须列出**具体**的卡点（哪条 Open question、缺哪个决策、依赖哪份空白文档）。

**判定纪律：** 宁可判 blocked，不要为了推进而放宽。**「可用占位数值 / 占位机制先 derive」不构成 ready** —— 若某机制未定，就如实标 blocked 或 partial，把占位与否交给用户决定。

### 4. 重写「derive 就绪度」小节
整体重写 `open-questions.md` 的该小节：
- 顶部一句：`最近全量评估：<日期>（由 /assess-derive-readiness 产出）`，以及一句全局结论（例：「全库尚未进入可 derive 阶段」/「N 份 ready」）。
- 一张表：`文档 | 判定(ready/partial/blocked) | 卡点 / 就绪切片`。**覆盖扫描到的每一份**主题文档，包括空占位（判 blocked，卡点写「尚无设计意图」）。
- 若有 ready / partial 项，在表下给出**建议的 derive 顺序**（先无依赖的、先薄纵向切片）。
- 保留该小节的守则说明：**本小节由 `/assess-derive-readiness` 独占写入，`/analyze-new-ideas` 不得改动。**

### 5. 报告
- 给出全局结论 + 三档各自的文档清单。
- 对每个 blocked 项给出**最短解锁路径**：需要回答哪几个问题 / 需要哪个 ADR——并指引用户用 `/analyze-new-ideas` 去解决它们。
- 若存在 ready 项，指引 `/derive-requirements <doc>`；**若一个都没有，明确说出来**，不要为了给用户一个"下一步"而勉强推荐某份文档。

## 输出形态
```
## Derive readiness — 全量评估 <日期>

全局结论：<一句话>

### ready
- <doc>: <为何就绪>

### partial
- <doc>: 就绪切片 = <切片>；其余卡于 <卡点>

### blocked
- <doc>: 卡于 <具体 Open question / 缺失决策 / 空白依赖>

### 建议顺序
1. /derive-requirements <doc>   (若无 ready 项则写「暂无——先解决下列问题」)

### 最短解锁路径
- <doc>: 需先回答 <问题>  → /analyze-new-ideas
```
