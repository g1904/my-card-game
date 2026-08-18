---
name: batch-blueprint
description: /blueprint 的批量版：为一批子需求（典型：一个 breakdown 文件夹的全部 FR-*-NN）或一批已签核内容条目并行产出实现蓝图。Phase A 并行探查到澄清检查点，全部含糊合并成一场 interview，Phase B 按依赖波次写蓝图；收尾交叉核对各蓝图对共享部件（EventBus 信号、服务方法、数据类）的形状一致性。只面向客户端。
argument-hint: <FR-<父id>（=其文件夹全部子需求）| FR/条目路径清单（分号分隔）>
---

# Batch Blueprint

编排规则见 `.claude/rules/batch-orchestration.md`。worker 执行的单会话技能是 **`/blueprint`**——请求校验、知识 / 代码探查、蓝图内容要求（RNG / save / null 计划等）与 FR 台账闭环语义，全部以它为准。范围同样**只面向客户端**（后端 FR 不接受）。

批量相对逐个跑的价值：一条 breakdown 链的公共背景（架构、知识层、既有代码）不再每个 session 重读；**共享部件的形状冲突提前暴露**——子需求 03 的蓝图假定 02 的服务方法签名是 X、而 02 的蓝图写的是 Y，逐个跑要到 implement 才撞上。

## 步骤

### 1. 圈定批次
- **`FR-<父id>`** → 读 `requirements/FR-<父id>/_index.md`，取全部子需求；`status` 非 `ready`（含 `draft`）的照单会话技能标出（尚未签核——与用户确认是否纳入）。
- **清单** → 逐个定位（子需求 id 或 `content/<类型>/<id>.md`；内容条目须已 `ready`，`draft` 的送回 `/author-content`）。
- 已 `blueprinted` / `built` 的跳过并报告。

### 2. 排波次与分区
- 按 `depends-on` 成波次：被依赖者的蓝图先出，后波 worker **必读前波蓝图**，接口形状以前波为准。无依赖的并行。
- 写入面：worker 独占自己的 `.claude/blueprints/<slug>.md`（slug 由 orchestrator 预分配）；`blueprints/_index.md` 与 `requirements/`（或内容台账）的状态翻转由 orchestrator 收尾统一做。

### 3. Phase A：并行探查（worker，只读）
按 worker 契约派单执行 `/blueprint` 第 1–4 步：校验规格、知识探查、代码探查（每个 worker 内部仍可派 Explore 子代理），走到**澄清检查点**为止——把结构化摘要（受影响文件 / 可复用部件 / 缺失部件）与全部含糊问题写进 run 目录，**不写蓝图**。发现设计意图未定 / 契约缺失 → 照单会话技能规则报告「应回退 /analyze-new-ideas」，该分片搁置。

### 4. 合并 interview ⏸️
orchestrator 去重合并全部澄清问题（多个分片对同一共享部件发问 → 合一），并追加跨分片核对：**各分片摘要中对同一部件（信号、服务方法、CycleState 字段、数据类）的假定不一致** → 新增一问或由 orchestrator 依据前波权威直接对齐（对齐结论写进 answers 告知各分片）。`AskUserQuestion` 分轮问齐；未问完不落笔。

### 5. Phase B：写蓝图（worker，按波次）
worker 拿 `answers.md` 执行第 5 步写蓝图（frontmatter `source-fr` 照规则填）。后波开工前 orchestrator 把前波蓝图路径塞进派单。

### 6. 收尾（orchestrator）
- **一致性终检**：抽各蓝图的共享部件形状（信号名与载荷、方法签名、`.tres` 字段）两两比对，不一致 → 修蓝图或报告待裁决。
- 统一写 `.claude/blueprints/_index.md`（status: designed）与 `requirements/` / 内容台账的 `blueprint:` + `status: blueprinted` 翻转。

## 输出形态
```
## Batch blueprint: <N> 份 → <M> 份蓝图

- 波次：<划分（按 depends-on）>；搁置：<分片 + 原因（未签核 / 设计未定）>

### 合并 interview
- 澄清 <X> 项 → 去重后 <Y> 问；逐条：<问题> → <裁决>
- 共享部件对齐：<条目>

### 蓝图
- .claude/blueprints/<slug>.md ← FR-<id>（台账已翻 blueprinted）

### Next
- /batch-implement <蓝图清单>（按构建顺序）或逐个 /implement
```
