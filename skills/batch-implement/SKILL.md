---
name: batch-implement
description: /implement 的批量版：按依赖顺序把一批蓝图（典型：一个 breakdown 文件夹对应的全部蓝图）串行波次地实现进 game-feature-branch/，波次间做编译核对，收尾统一更新知识层索引与蓝图台账。验证仍靠用户在 Godot 编辑器实际游玩——FR 状态停在 blueprinted，绝不因为批量就替用户翻 built。
argument-hint: <蓝图名清单（分号分隔）| FR-<父id>（=其全部已 blueprinted 子需求的蓝图）>
---

# Batch Implement

编排规则见 `.claude/rules/batch-orchestration.md`。worker 执行的单会话技能是 **`/implement`**——编码规则、验证说明、知识更新、FR 闭环语义，全部以它为准。范围**只面向客户端**（`game-feature-branch/`）。

**默认串行，不默认并行。** 代码不同于文档：同一工程里并行写入的文件面很难提前算准（`project.godot`、autoload、共享场景与 EventBus 都是汇聚点）。只有当两份蓝图的「要创建/修改的文件」集合经核对**确不相交**时才允许并行；拿不准 → 串行（铁律 ③ 的保守面）。批量的收益主要来自：每个 worker 只带自己蓝图的上下文开工、波次间的机械核对由 orchestrator 兜住、一次会话跑完整条链。

## 步骤

### 1. 圈定批次与排序
- 解析清单或 `FR-<父id>`（从 `requirements/FR-<父id>/_index.md` 与 `blueprints/_index.md` 取全部 `designed` 蓝图）。缺蓝图的子需求 → 报告，建议先 `/batch-blueprint`。
- 按蓝图对应子需求的 `depends-on` 排出**串行波次**；读各蓝图的文件清单，仅当集合不相交时同波并行。
- 与用户确认批次与顺序后开工。

### 2. 逐波实现（worker）
按 worker 契约派单执行 `/implement`：只在 `game-feature-branch/` 内编辑，全部编码规则照守；变更摘要、验证说明、知识笔记改动写进报告。
- worker **就地更新**它引入的系统对应的知识笔记（`knowledge/systems/<name>.md` 等——分片独占）；`knowledge/*/_index.md` 与 `architecture.md` 的行级改动写进报告由 orchestrator 收尾合并（多蓝图会同时碰索引）。
- **不自动提交**（原守则）。

### 3. 波次间核对（orchestrator）
每波结束：对 `.csproj` 跑一次 `dotnet build` 作**前置**检查（原技能定位：有用但不具权威）；失败 → 停下修复本波，不带病进入下一波。抽查本波改动是否与后续蓝图的假定一致（信号签名、方法名）——不一致时优先改后续蓝图的派单说明，不回头改已实现代码（除非确是本波错了）。

### 4. 收尾（orchestrator）
- 合并写 `knowledge/` 各 `_index.md` 与 `architecture.md` 代码现状段；`blueprints/_index.md` 状态翻 `implementing`。
- **FR / 内容条目一律停在 `blueprinted`**：批量运行里用户不可能边跑边验收。汇总一份**验证走查清单**（按构建顺序：开哪个场景、做什么操作、看什么日志标签、对应哪条验收标准），提示用户验证通过后逐个翻 `built`（或回来让 Claude 翻）——「台账绝不领先于事实」。

## 输出形态
```
## Batch implemented: <N> 份蓝图（<W> 个波次）

### Changed files（按波次 / 蓝图分组）
- [new/edit] game-feature-branch/...

### 波次核对
- wave <k>: dotnet build <通过/修复了什么>

### 知识层
- 更新：<笔记清单>（索引已由收尾合并）

### 验证走查清单（请在 Godot 编辑器逐条走）
1. <场景 / 操作 / 期望 / 日志标签> —— 对应 FR-<id> 验收标准 <n>
...
验证通过后：把对应 FR 翻为 built（可让我代办）。
```
