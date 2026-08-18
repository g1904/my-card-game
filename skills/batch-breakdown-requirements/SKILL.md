---
name: batch-breakdown-requirements
description: /breakdown-requirements 的批量版：一批 FR 并行拆解——每个 worker 仍只拆一份 FR（保住逐条覆盖核对），orchestrator 收尾做跨 FR 依赖闭合核对并统一写 requirements/_index.md。单会话技能「一次只拆一份、批量会漏」的告诫由这个结构兑现，而不是被绕过。
argument-hint: [--lib=game|backend|两库] <FR-<id> 清单（分号分隔）| 空（列出 ready/draft 且未拆解的 FR 让用户圈选）>
---

# Batch Breakdown Requirements

编排规则见 `.claude/rules/batch-orchestration.md`。worker 执行的单会话技能是 **`/breakdown-requirements`**——前置门、切分启发式、覆盖核对、签核语义，全部以它为准。

单会话技能警告「一次只拆一份 FR——批量会漏」，指的是**一个 session 摊开多份 FR 时覆盖核对必然漏**。本技能不违反它：**每个 worker 仍然只拆一份**，批量发生在 worker 之间。增值在收尾的跨 FR 核对：子需求 `depends-on` 指向他 FR 的子需求时（跨 FR、跨库），逐个 session 拆时那个子需求可能还不存在或编号对不上。

## 步骤

### 1. 圈定批次（用户确认，强制）
- 给了 FR 清单 → 逐个按路由规则定位（FR id 落地探测）；空 → 读两库 `requirements/_index.md`，列出 `ready` / `draft` 且未拆解的 FR 请用户圈选。
- 逐个过单会话技能第 3 步前置门：`broken-down` 且文件夹已存在的属**增量更新**——仍可入批，派单时点明；验收标准还是占位的**不入批**并报告。

### 2. 排波次与分区
- 按父 FR 的 `depends-on` 排波次：被依赖的 FR 先拆，后波 worker 写跨 FR `depends-on` 时能引用真实的子需求 id。无依赖的并行。
- 写入面：每个 worker 独占它的父 FR 文件 + 新建的 `FR-<id>/` 文件夹（含文件夹内 `_index.md`——这是分片独占文件，worker 自己写）；**库级 `requirements/_index.md`** 由 orchestrator 收尾写。

### 3. 并行拆解（worker）
按 worker 契约派单执行 `/breakdown-requirements`：一人一份 FR，完整走切分、覆盖核对（父验收标准 → 子需求映射表）、写文件与文件夹内台账；父 FR `status → broken-down` 由 worker 就地改（独占文件）。库级台账行写进报告。设计缺口进子需求 `## Open questions`，不改设计（原守则照守）。

### 4. 收尾交叉核对（orchestrator）
- **跨 FR 依赖闭合**：全批子需求的 `depends-on` 中指向其他 FR 子需求的条目，逐条确认目标存在且序号正确；指向本批未拆 FR 的 → 报告为悬空。
- **覆盖核对抽查**：逐份核对 worker 报告的映射表是否覆盖父 FR 全部验收标准（worker 已做，这里对账其报告与文件一致）。
- 统一写各库 `requirements/_index.md`：父行翻 `broken-down` + 子需求缩进行。

### 5. 报告
```
## Batch broken down: <N> 份 FR → <M> 个子需求

- 范围：game <n> · backend <m>（波次：<划分>）

### 逐 FR
- FR-<id>: <k> 个子需求（覆盖 <n>/<n> 条验收标准）[构建顺序摘要]

### 交叉核对
- 跨 FR depends-on：<闭合 / 悬空清单>

### Open questions（下发 / 新增，按子需求）
- ...

### Next
- /batch-blueprint FR-<id>（整个文件夹）或 /blueprint FR-<id>-01-<subslug>
```
