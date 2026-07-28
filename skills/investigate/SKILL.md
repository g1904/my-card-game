---
name: investigate
description: 给定一个症状，追踪处理链，列出按可能性排序的潜在根因及诊断步骤。
argument-hint: [env: feature/testing/production/backend-feature/backend-testing/backend-production], <症状：预期 vs 实际、日志/数据>
allowed-tools: Read, Grep, Glob, Bash
---

# Investigate

为一个上报的症状追踪代码链，找出状态在何处被错误设置或丢失，并对可能的根因排序。

## 步骤

### 0. 选择环境
从 `$ARGUMENTS` 解析 **env**。它决定在哪个分支文件夹中追踪：

| env | 文件夹 | 何时使用 |
|-----|--------|------|
| `feature`（默认） | `game-feature-branch/` | 开发期复现、进行中的工作 |
| `testing` | `game-testing-branch/` | 在测试快照中看到的问题 |
| `production` | `game-production-branch/` | 在发布快照中的问题 |
| `backend-feature` | `backend-feature-branch/` | 后端开发期复现 |
| `backend-testing` | `backend-testing-branch/` | 在后端测试快照中看到的问题 |
| `backend-production` | `backend-production-branch/` | 在后端发布快照中的问题 |

若未指定，默认 `feature` 并说明这一点。把所有读取/搜索限制在所选文件夹内，以便你针对匹配的代码进行推理。症状可能横跨客户端 ↔ 后端边界时，同时读两侧的 feature 文件夹，并明确指出根因落在边界哪一侧。

### 1. 解析症状
提取（缺失则询问）：**预期**行为、**实际**行为、**关键线索**（日志行、存档数据、种子、屏上数值）、**涉及的实体**（card/relic id、系统、场景、信号）。

### 2. 确定追踪端点
- **起点**：状态已知正确的最后一点（一个存档值、一条上游日志、数据资源）。
- **终点**：出错之处（一条下游日志、错误的 UI 值、崩溃点）。

### 3. 追踪链条（每一跳都读完整代码）
留意本游戏常见的这些变换点：

- **数据解析**：`DataRegistry` 的 get-by-id——id 对不对？是否检查了 null 结果（`null-check-rules.md`）？
- **CycleState 变更**：哪个系统写了该字段？之后是否被另一个系统/EventBus 处理器覆盖？
- **EventBus 流**：信号发出了吗？所有预期订阅者都连上了吗？有无顺序/重入问题（某处理器再次发信、relic 响应 relic）？
- **Seeded RNG**（`rng-determinism.md`）：结果是否从正确的 seeded 子流抽取？某个无关的抽取是否让流失步？加载时 RNG 状态是否恢复？
- **Save/load**（`save-format.md`）：版本不匹配、缺少迁移、未知/悬空的内容 id、非原子写入损坏文件、RNG 状态未持久化。
- **信号载荷**：跨总线传递的是 id/原语，还是一个丢失了数据的富对象？
- **节点生命周期**：一个已释放的节点仍被引用、一个实例化的 card/enemy 跨轮回泄漏、在尚未就绪的树上 `GetNode`。
- **被吞的错误**：一个空 `catch`，或一个既未 `PushError` 也未 `PushWarning` 的 null，掩盖了真正的失败。

### 4. 标注每一跳的状态
逐跳展示目标字段的值流动，标出它在哪里发散：
```
[start] save: cycle.seed=12345, deck=[strike,strike,bash]
  ↓ DeckSystem.Draw() (map RNG vs combat RNG?)
[hand] expected 5 cards, actual 4  ← divergence
  ↓ EventBus.CardDrawn subscribers
[UI] HandView shows 4
```

### 5. 对根因排序
从高到低可能性。对每个：**可能性**、**变换点**（`file:method`）、**机制**（状态如何被破坏/丢失）、**证据**（支持/反对的代码）、**如何验证**（日志关键词、断点、可复现的种子、要检查的存档字段）。

排序：可由代码证明的问题在前，运行期数据问题居中，环境/配置问题最后。

### 6. 诊断步骤
具体、有优先级的检查：要搜索的确切 `GD.Print` 标签及每个值的含义；用于确定性 bug 复现的种子 + 脚本化输入；要检查的存档字段/版本；要在编辑器中打开哪个场景来复现。

### 7. 输出格式
```
## Investigation: <一行症状>

### Symptom
- env: <feature/testing/production>
- expected / actual / key clues

### State trace
<字段跨跳的箭头图>

### Root causes
#### #1 [high] <title>
- point / mechanism / evidence / how to verify
#### #2 [med] ...

### Diagnostic steps
<有优先级的检查；要找什么，以及每个结果意味着什么>
```
