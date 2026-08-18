---
name: assess-derive-readiness
description: 全量扫描设计库（客户端 / 后端）的全部主题文档，逐份判定它们是否已详尽到可以 /derive-requirements，并把结论整体重写进该库 open-questions.md 的「derive 就绪度」小节。留空则两库都扫。由用户在时机成熟时手动调用。
argument-hint: [--lib=game|backend] <留空 = 两个库全量扫描 | 单个文档路径 = 只报告该文档（仍不写入）>
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Assess Derive Readiness

判定**设计意图是否已详尽到可以转化为功能需求**，并维护全库唯一的就绪度台账。

**为什么单独成为一个技能：** 就绪度是一个**全库横切**的判断——一份文档能否 derive，取决于它自身、它依赖的 vision、约束它的 ADR，以及它引用的其他系统是否也已落定。由 `/analyze-new-ideas` 在每次 handoff 时顺带评估，会产出**迅速过时且互相矛盾**的局部结论。因此就绪度只在**用户主动要求**时、以**一次全量扫描**的方式重新产出。

## 范围守则（强制）

- **唯一写入目标：`<LIB>/open-questions.md` 的「derive 就绪度」小节**——整体重写该小节（不是追加），它是该库就绪度的唯一权威落点。**两库各有一份；每个库的评估只写它自己那一份，结论绝不跨库合并。**
- **只读一切其他文档。** 不改主题文档、不改 handoff、不改 ADR、不改 `requirements/`、不碰游戏代码。发现设计缺口时**只报告**，不顺手补设计——那是 `/analyze-new-ideas`。
- **不生成 FR。** 产出 FR 是 `/derive-requirements` 的事；本技能只回答「能不能 derive、被什么卡住」。
- 唯一例外：若在扫描中发现主题文档 / handoff 里**遗留的旧就绪度断言**（「可 derive」「暂缓 derive」「解锁 derive」等），可就地删除或中性化——保持全库只有一处就绪度结论。

## 步骤

### 0. 确定目标设计库（强制，先于一切）
按 `.claude/rules/design-library-routing.md` 解析库参数：显式库参数 → 参数中的路径前缀。**本技能是该规则「无法判定就询问」的显式例外：参数为空时不询问，默认两个库都全量扫描**（就绪度台账两库各一份，互不合并，因此同时刷新两份不存在写错库的风险）。

选定后，**下文所有写作 `game-design-documents/` 的路径一律读作 `<LIB>/` 下的同名路径**。**就绪度是库内横切判断，绝不跨库合并结论**——报告与写入都按库分区块。

### 1. 解析目标
剔除库参数后解析剩余 `$ARGUMENTS`：
- **空（默认）→ 两个库都全量扫描**，各自的主题文档区：
  - **客户端库**：`vision/`、`systems/**`（含子文件夹的 `_index.md` / `common-properties.md` / 各具体设计）、`art/`、`ux/`、`decisions/`。
  - **后端库**：`vision/`、`contracts/**`、`systems/**`、`operations/**`、`decisions/`。
- **只给了库参数** → 只全量扫描该库并写入它的小节。
- **单个文档路径** → 只评估并**报告**该文档；**仍然不写入** `open-questions.md`（避免用局部结论污染全量台账）。明确告知用户这是一次局部预览。

**两库并行执行：** 两个库的扫描彼此独立（只有第 3 步第 6 条的跨边界检查需要读另一侧，且是只读），因此**默认为每个库各分派一个 subagent 并行跑**，各自写入自己库的小节，主 session 汇总两份报告。

### 2. 建立判定所需的上下文（写之前先读）
1. `<LIB>/README.md` — 流水线与状态词汇。
2. `<LIB>/open-questions.md` — 索引（含既有「derive 就绪度」小节，本技能的唯一写入目标）；待答问题条目本身在 `<LIB>/open-questions/` 的各分片中，按需读取。
3. `<LIB>/handoffs/_index.md` — 最近的意图流向（哪些文档刚被改动 = 结论最易过时）。
4. `<LIB>/decisions/` — 哪些方向已固化为 ADR。
5. `<LIB>/requirements/_index.md` — 哪些已经 derive 过（避免重复判定；已 derive 的部分标注为「已覆盖」）。
6. 逐份读取待评估的主题文档。
7. **另一侧库的相关文档**（跨边界依赖检查，见第 3 步第 6 条）。**本技能对另一库仍是只读**——就绪度台账两库各一份、结论永不合并，且跨边界缺口由本技能**报告**、由 `/analyze-new-ideas` 或 `/provide-solution-draft` 去两侧落笔（那两个技能已按 `.claude/rules/design-library-routing.md` 解除单库限制）。

### 3. 逐份判定（判定标准）
一份文档 **ready**，当且仅当**三条全部**成立（与 `/derive-requirements` 的就绪性门一致）：
1. 它的 `## 意图` / `## Intent` 有**真实内容**，不只是模板占位符（`> _..._`）。
2. 它的 `## 待决问题` / `## Open questions` **为空，或每一条都已有决策 / ADR 覆盖**。
3. 它所挂靠的 `vision/` 意图在该点上**没有未决问题**，且约束它的 ADR 均为 Accepted。

**再叠加三条横切检查**（这是全量扫描相对逐份评估的价值所在）：

4. **依赖闭合：** 它显式依赖的其他系统 / 服务，在被依赖的那个点上也已落定。一份文档不能因为把关键机制"甩给"另一份仍空白的文档而显得就绪。
5. **无孤儿路径：** 文档描述的每条玩家路径 / 状态转换都有归属系统。（例：新增一条"跳过事件"通道却没有服务承接它 → 未就绪。）
6. **跨边界闭合（强制）：** **客户端文档若依赖某个尚未在 `backend-design-documents/contracts/` 定案的协议契约 → 判 blocked，卡点写明缺哪份契约。** 反向亦然：后端文档若其存在理由完全取决于一个尚未定案的客户端需求，也应标出。契约的权威在后端库——客户端库自称"契约已定"但后端库没有对应文档，**以后端库为准判 blocked**。

**判定三档，不要含糊：**
- **ready** — 三条 + 三条横切全部满足。
- **partial** — 存在一个**可独立成立的就绪切片**，其余被明确列出的问题卡住。必须写清哪个切片可 derive、其余被什么卡住。
- **blocked** — 未就绪。必须列出**具体**的卡点（哪条 Open question、缺哪个决策、依赖哪份空白文档）。

**判定纪律：** 宁可判 blocked，不要为了推进而放宽。**「可用占位数值 / 占位机制先 derive」不构成 ready** —— 若某机制未定，就如实标 blocked 或 partial，把占位与否交给用户决定。

### 4. 重写「derive 就绪度」小节
整体重写 `open-questions.md` 的该小节：
- 顶部一句：`最近全量评估：<日期>（由 /assess-derive-readiness 产出）`，以及一句全局结论（例：「全库尚未进入可 derive 阶段」/「N 份 ready」）。
- 一张表：`文档 | 判定(ready/partial/blocked) | 卡点 / 就绪切片`。**覆盖扫描到的每一份**主题文档，包括空占位（判 blocked，卡点写「尚无设计意图」）。
- 若有 ready / partial 项，在表下给出**建议的 derive 顺序**（先无依赖的、先薄纵向切片；**被依赖的契约 / 服务先于依赖它的系统**）。
- 保留该小节的守则说明：**本小节由 `/assess-derive-readiness` 独占写入，`/analyze-new-ideas` 不得改动。**

### 5. 报告
- **每个库分别**给出全局结论 + 三档各自的文档清单（两库同扫时输出两个区块，不合并）。
- 对每个 blocked 项给出**最短解锁路径**：需要回答哪几个问题 / 需要哪个 ADR——并指引用户用 `/analyze-new-ideas` 去解决它们。
- 若存在 ready 项，指引 `/derive-requirements <doc>`；**若一个都没有，明确说出来**，不要为了给用户一个"下一步"而勉强推荐某份文档。

## 输出形态
```
## Derive readiness — 全量评估 <日期>

- library: <game-design-documents | backend-design-documents>

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
