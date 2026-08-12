---
name: review-local-changes
description: 在提交前审查 game-feature-branch 中所有未提交的本地改动，以捕捉潜在 bug。
allowed-tools: Read, Grep, Glob, Bash
---

# Review local changes

审查 `game-feature-branch/` 中未提交的改动，并在提交前报告潜在 bug。

## 步骤

### 1. 收集改动
从 `game-feature-branch/`：
```bash
git -C game-feature-branch status --porcelain
git -C game-feature-branch diff
git -C game-feature-branch diff --cached
```
若**没有改动** → 报告工作树干净并停止。

### 2. 审查每个改动的文件
检查这些类别：

#### C# / Godot 正确性
- Godot 派生类上有 `partial` 吗？阻断编译的 `using` 都在吗？
- `GetNode` 在 `_Ready` 中缓存、而非逐帧调用？优先用 `GetNodeOrNull` + null 检查？
- `_Process`/`_PhysicsProcess` 热路径中有分配/LINQ/字符串插值吗？
- 信号连接一致；无连接到已释放节点的泄漏；实例化的节点已释放（`QueueFree`）。
- 无 `async void`（必要的顶层处理器除外）。

#### Null / 结果校验（强制——`null-check-rules.md`）
- 在每次节点查找、`ResourceLoader.Load`/registry get-by-id、字典/集合查找、save 读取之后：有显式检查吗？
- 必需却缺失 → `GD.PushError`/抛出**并带定位上下文（id/path）**；可选却缺失 → `GD.PushWarning` + 安全默认值。标出任何静默透传的 null/空。

#### 数据资源（`data-resource-rules.md`）
- 新内容以稳定字符串 `Id`（而非 name/index/path）作键？交叉引用用 id 并在加载时校验？
- 平衡数值在数据/导出里，而非硬编码在逻辑里？

#### 状态 / RNG / 存档（`state-save-rules.md`）
- 随机性从 **seeded** 子流抽取，而非 `GD.Randi`/`Random`？
- 轮回数据通过 CycleState 变更（无游离全局变量、轮回间无残留状态）？
- save 写入是原子的（temp + rename）且感知版本的？内容按 id 引用并在加载时校验？

#### UI / 输入（`ui-input-rules.md`）
- 竖屏安全的布局（容器 + 锚点，而非绝对定位）？触摸目标足够大？无仅悬停的可用性提示？

#### 设计一致性（与代码正确性对等）
- 改动的机制、数值与流程，与 `game-design-documents/` 的 `systems/` + `ux/` 一致吗？**设计意图与实现不一致是红旗。**
- 跨边界的报文与 `backend-design-documents/contracts/` 一致吗？三者（契约文档 / 客户端调用 / 后端实现）不一致是红旗。
- 新增的玩法路径 / 交互在设计库里有归属吗？（凭空长出来的机制 = 设计漂移，报告给用户。）
- 平衡数值有没有硬编码进逻辑而绕开数据资源？

#### 复制粘贴 / 卫生
- 重复代码块、从模板复制而未修改的名字、残留的 TODO/FIXME、不匹配的 `[System-Method]` 日志标签、硬编码的常量（应是导出字段 / 数据资源）。

### 3. 报告 ⏸️
按严重程度分组发现：
- 🔴 **Bug**（运行期/编译失败/设计破坏）：缺 `using`/`partial`、未检查的 null 解引用、错误的信号签名、未播种的玩法 RNG、非原子存档、悬空的数据 id、抽取未走 `AllEnabled()`、契约三方不一致。
- 🟡 **Warning**：缺日志、命名不一致、可疑的 null 处理、逐帧分配。
- 🔵 **Info**：大 diff、值得手动查看的复杂逻辑、复用机会、硬编码数值建议提为数据。

对每个 bug：文件路径、位置、问题及建议修复。**不要自动修复。** 若干净，则确认可以安全提交。
