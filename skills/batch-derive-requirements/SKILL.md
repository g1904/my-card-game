---
name: batch-derive-requirements
description: /derive-requirements 的批量版：按最近一次 /assess-derive-readiness 的就绪台账，一次为一批 ready/partial 文档并行产出 FR，收尾交叉核对 FR id 撞名、跨文档重复切片与 depends-on 悬空，统一写 requirements/_index.md。不重新评估就绪度、不裁决任何 Open question。
argument-hint: [--lib=game|backend|两库] <文档清单（分号分隔）| ready（=就绪台账里全部 ready 项）| 空（列出候选让用户圈选）>
---

# Batch Derive Requirements

编排规则见 `.claude/rules/batch-orchestration.md`。worker 执行的单会话技能是 **`/derive-requirements`**——就绪门、拆解准则、FR 形态与「充实 vs 臆造」，全部以它为准。

批量相对逐个（或单会话 `all detailed docs`）的价值：多份文档并行 derive，且收尾**跨文档核对**——同一行为被两份文档各切出一个 FR、跨文档 `depends-on` 指向不存在的 FR、id 撞名，这些只有把一批产出摆在一起才看得见。

## 步骤

### 1. 圈定批次（以就绪台账为准，强制）
- 读各库 `open-questions.md` 的「derive 就绪度」小节（`/assess-derive-readiness` 的独占产出）。**本技能不重评就绪度**：台账缺失或明显过时（评估日期早于多份相关文档的最近改动）→ 停下，建议先跑 `/assess-derive-readiness`。
- `ready` 参数 → 取台账全部 ready 项（partial 项列出其就绪切片，问用户是否纳入）；给了文档清单 → 核对各自在台账中的判定，blocked 的**不纳入**并如实说明；空 → 列出 ready / partial 候选请用户圈选。
- worker 在自己分片上仍执行单会话技能第 3 步的就绪门——台账与现状不符时以现状为准拦下并报告，不硬 derive。

### 2. 排波次与分区
- 依赖顺序照就绪台账的「建议的 derive 顺序」：**被依赖的契约 / 服务先于依赖它的系统**成波次，后波 worker 可读前波已产出的 FR 来写 `depends-on`。无依赖关系的并行。
- orchestrator 预分配各分片的 FR 命名空间（`FR-<system>-*` 的 `<system>` 段互不相同）防撞名。
- 写入面：worker 只写自己的 `FR-*.md` 文件（既有 FR 的增量更新也算独占——同一 FR 不得出现在两个分片）；`requirements/_index.md` 由 orchestrator 收尾写。**FR 与台账两库各自独立、永不合并**（同单会话守则）。

### 3. 并行 derive（worker）
按 worker 契约派单执行 `/derive-requirements`：读源文档 + vision + ADR + 知识层（后端分片按其规则改读 `contracts/` 与客户端服务文档），产出 FR 文件（`status: draft`），blocked 切片与 Open questions 写进报告。**不发明报文、不臆造机制**（原技能强制条款照守）。

### 4. 收尾交叉核对（orchestrator，本技能的核心增值）
- **id 撞名**：全批 + 既有台账范围内查重。
- **重复切片**：两个 FR 的验收标准覆盖同一可观察行为 → 合并或裁边界；拿不准的列「待确认」问用户。
- **depends-on 闭合**：每条 `depends-on` 指向的 FR 存在（本批或既有）；跨库依赖写全 `<LIB>/FR-<id>` 且不缺对侧承接——缺的报告为跨库缺口（落笔归 `/analyze-new-ideas`，本技能不代写）。
- 统一写各库 `requirements/_index.md`（新行最新置顶）。

### 5. 报告
```
## Batch derived: <N> 份文档 → <M> 个 FR

- 范围：game <n> · backend <m>（波次：<划分>）

### Feature requirements（按库、按源文档分组）
- <源文档>: FR-... (draft) <title> [depends-on: ...]

### Blocked / 未 derive
- <文档/切片>: 卡于 <就绪门原因>

### 交叉核对
- id 撞名 <0/n> · 重复切片 <结论> · depends-on 悬空 <结论> · 跨库缺口 <清单>

### Open questions（汇总，按 FR）
- ...

### Next
- 审阅并签核 draft → ready，然后 /batch-breakdown-requirements 或逐个 /breakdown-requirements
```
