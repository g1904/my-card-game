---
name: review-feature
description: 审查某功能的完整链条（场景、脚本、数据、接线）以发现潜在 bug。既有的或新的。
argument-hint: <功能描述、类名、场景名或文件路径>
allowed-tools: Read, Grep, Glob, Bash
---

# Review feature

审查 `game-feature-branch/` 中某功能的完整链条，查找潜在 bug。

## 步骤

### 1. 界定范围
从 `$ARGUMENTS`：
- **类名/场景名** → 在 `game-feature-branch/` 中定位它。
- **文件路径** → 读取它，找出入口点。
- **描述** → 在 `game-feature-branch/` 中搜索相关的场景/脚本/数据。
- **什么都没有** → 收集未提交的改动并审查它们：
```bash
git -C game-feature-branch status --porcelain
git -C game-feature-branch diff
```
若未指定任何内容且没有改动 → 询问目标并停止。

### 2. 追踪完整链条
从入口点开始，读取**每一层的完整代码**（不只是 diff）。双向追踪：

| 入口 | 上游 | 下游 |
|-------|----------|-----------|
| UI/屏幕场景 | 什么打开/承载它 | 系统调用 → CycleState → EventBus |
| 系统/管理器 | 调用者（UI、其他系统、EventBus 订阅者） | CycleState 变更、DataRegistry 读取、save 写入 |
| Autoload（CycleState/EventBus/DataRegistry/SaveManager） | 所有发出者/消费者 | 它所拥有的数据/服务 |
| 数据资源 | 按 id 读取它的系统 | 加载时校验 |
| EventBus 信号 | 发出者 | 所有订阅者 |

一个功能可能跨越多条链——全部覆盖。

### 3. 审查每条链
- **链完整性**：每一层都实现了吗？信号既发出又处理了吗？场景是否接到了驱动它们的系统？数据 id 是否确实在某处被解析？
- **类型一致性**：input → 系统 → CycleState → 数据 → save，参数/返回类型对齐。信号载荷为 Variant 简单类型。
- **C#/Godot 正确性**：`partial`、缓存节点、无热路径分配、已释放的实例、无泄漏的信号连接、无 `async void`。
- **Null / 校验**（`null-check-rules.md`）：每次节点查找 / 资源加载 / registry-字典查找 / save 读取都被显式检查；必需→带上下文报错，可选→warn+默认；无静默透传。
- **数据**（`data-resource-rules.md`）：稳定 id、基于 id 的交叉引用在加载时校验、平衡数值在数据里。
- **状态/RNG/存档**（`state-save-rules.md`）：seeded 子流随机性、由 CycleState 拥有的变更、干净的轮回拆解、原子且带版本的存档、基于 id 的 save 引用。
- **UI/输入**（`ui-input-rules.md`）：竖屏容器/锚点、触摸目标、无仅悬停。
- **事件/信号设计**（`signal-eventbus.md`）：跨系统经 EventBus 解耦；无重入循环；在顺序重要处不假设顺序（如 relic 触发优先级）。
- **业务逻辑**（若上下文允许）：分支覆盖（空牌堆、轮回中途恢复、boss vs 普通）、状态机合理性、无效果的重复施加。
- **设计一致性**：实现的机制 / 数值 / 流程与 `game-design-documents/` 的 `systems/` + `ux/` 一致吗？跨边界报文与 `backend-design-documents/contracts/` 一致吗？**设计意图与实现不一致是红旗**，与代码缺陷同等对待。
- **复制粘贴/卫生**：重复代码块、遗留的模板名、残留的 TODO/FIXME、不匹配的日志标签。

### 4. 报告
按严重程度分组：
- 🔴 **Bug**：链条断裂（缺层）、类型不匹配、缺 `using`/`partial`、未检查的 null 解引用、未播种的玩法 RNG、非原子/无版本的存档、悬空的数据 id、信号签名不匹配、重入的事件循环。
- 🟡 **Warning**：缺日志、命名不一致、null 安全存疑、轮回状态在轮回间的可疑传递、逐帧分配。
- 🔵 **Info**：需手动复核的复杂逻辑、复用建议、潜在的性能热点。

对每个 bug：文件路径、位置、问题、建议修复。**不要自动修复。** 若干净，则确认链条看起来稳妥。

## 批量模式（worker 契约）

本技能有批量版 **`/batch-review-feature`**（多分片并行 / 波次编排，合并 interview）。被其派为 worker 运行时，按 `.claude/rules/batch-orchestration.md` 的「worker 契约」执行三点覆盖：① interview / 澄清门不调用 `AskUserQuestion`——Phase A 把问题写进 run 目录并停止，Phase B 把 `answers.md` 视同用户当面裁决；② 共享台账（各 `_index.md`、`open-questions*`、`update-log`）不写，台账行随报告交回由 orchestrator 代笔；③ 范围锁定在派单分片，越界发现只记报告。其余步骤原样执行。直接被人运行时本节不适用。
