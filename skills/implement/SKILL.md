---
name: implement
description: 依据一份蓝图或一段描述来实现功能代码。
argument-hint: [蓝图名或功能描述]
---

# Implement

依据一份蓝图或描述，为这款 Godot/C# 卡牌游戏构建功能代码。

**范围：只面向客户端**（`game-feature-branch/`）。后端实现（`backend-feature-branch/`）不在本技能范围内——技术栈未定。

## 步骤

### 1. 加载计划
从 `$ARGUMENTS`：
- **一个文件名**（带/不带 `.md`）→ 从 `.claude/blueprints/` 读取该蓝图作为计划。
- **一段描述**（无匹配的蓝图）→ 直接把它当作指令使用。
- **什么都没有，且无蓝图** → 建议先运行 `/blueprint`，或请求一段描述。

### 2. 实现
遵循蓝图的顺序（通常自底向上：数据资源 → 系统逻辑 → 场景/UI → 接线）。

**编码规则——遵循 `Context.md` 与各规则文件：**
- **只在 `game-feature-branch/` 中编辑。** 绝不写入 testing/production 分支文件夹。
- **编辑前先读既有的 `using` / 节点树。** 复用既有的短类型名与节点名；在文件顶部新增 `using`，而不是内联完全限定名。
- **C#/Godot 约定**（`csharp-godot-rules.md`）：`partial` 类、用 `[Export]` 暴露可调项、在 `_Ready` 中缓存 `GetNode`、`_Process` 中不做分配/LINQ、`QueueFree` 归属、避免 `async void`。
- **场景**（`scene-rules.md`）：每个场景单一职责、`PackedScene` 实例化、稳定引用（`%Unique`/组/导出）、数据不放进场景。
- **数据**（`data-resource-rules.md`）：内容作为 `Resource`/`.tres` 且有稳定字符串 `Id`，经 DataRegistry 加载、加载时校验；平衡数值放在数据里，而非代码里。
- **状态/RNG/存档**（`state-save-rules.md`）：通过 CycleState 变更；随机性由 seeded 子流驱动；原子且带版本地持久化。
- **UI/输入**（`ui-input-rules.md`）：竖屏、容器 + 锚点、触摸目标、无仅悬停的可用性提示。
- **Null/校验为强制**（`null-check-rules.md`）：在每次节点查找、资源加载、registry/字典查找、save 读取之后——必需却缺失 → `GD.PushError`/抛出并带定位上下文；可选却缺失 → `GD.PushWarning` + 安全默认值。不允许静默透传 null。
- **日志**：在关键转换点周围写 `GD.Print($"[System-Method] ... {value}")`。
- **信号**：跨系统事件走 EventBus，载荷为 id/原语，而非直接引用。
- **设计一致性**：机制、数值与流程**必须与 `game-design-documents/` 一致**；跨边界的报文**必须与 `backend-design-documents/contracts/` 一致**。需要偏离就停下来问，**不要边写边改设计**。
- **不要**自动提交。

### 3. 变更摘要
按领域（scene / script / data / autoload）分组列出所有创建/修改的文件：
```
## Changed files
- [new]  game-feature-branch/systems/DeckSystem.cs
- [edit] game-feature-branch/autoload/CycleState.cs
- [new]  game-feature-branch/data/cards/strike.tres
```

### 4. 验证说明
**`dotnet build` 成功不是验收标准。** 给出具体的端到端验证步骤：
1. 在 Godot 编辑器中打开项目（编辑器会用正确的引用驱动 .NET 构建）。
2. 打开哪个场景 / 从哪里按 Play。
3. 逐条走 FR 的验收标准：做什么操作、期望看到什么。
4. 要在输出里搜哪些 `[System-Method]` 日志标签，以及每个值的含义。

对 `.csproj` 运行 `dotnet build` 能捕获 C# 语法错误，是有用的**前置**检查，但不具权威性。除非要求，否则不写单元测试。

### 5. 知识更新（直接执行，不只是建议）
`knowledge/*` 是面向 Claude 的**薄引用层**，由 Claude 负责维护。若本次引入或改动了某个系统/场景/数据类型/autoload，**就地更新**对应笔记，保持增量、如实反映代码现状：
- 新增/改动系统 → 创建或更新 `.claude/knowledge/systems/<name>.md`（入口场景/脚本、涉及的类、CycleState 读写、EventBus 信号、RNG 子流、存档触点），并翻转 `systems/_index.md` 中该行状态。
- 新增/改动场景 → 更新 `.claude/knowledge/scenes/_index.md`。
- 新增/改动数据类型 → 更新 `.claude/knowledge/data/_index.md`。
- 新增 autoload → 更新 `.claude/knowledge/autoloads/_index.md`（含注册顺序）。
- 代码从"尚未开工"变为存在时 → 更新 `.claude/knowledge/architecture.md` 的代码现状段。

**只补导航条目 + 回链，不复制设计说明**——机制与字段定义的权威在设计库（`ADR-0005`）。在变更摘要中列出更新过的笔记。设计意图本身（`game-design-documents/`）仍归用户所有——不要反向改设计文档。若怀疑知识与代码已大面积脱节，建议运行 `/sync-knowledge` 做整体对账。

### 6. FR 闭环
若本次实现源自一份由 `FR-<id>` 推导的蓝图（蓝图中记有 `source-fr:`，或 FR 台账的 `blueprint:` 指向它）：
- 提醒用户按第 4 步的验证步骤走一遍验收标准。
- **验证通过后**（用户在本 session 内确认，或明确要求直接翻转），把 `game-design-documents/requirements/FR-<id>.md` 的 `status` 翻为 `built`，并同步 `_index.md` 中对应行。
- 若 session 在验证前结束，把 FR 留在 `blueprinted`，并在摘要中注明"验证通过后请把 FR-<id> 翻为 built"——**台账绝不领先于事实**。
- 同时更新 `.claude/blueprints/_index.md` 中该蓝图的状态（实现中 `implementing` → 验证通过 `built`）。
