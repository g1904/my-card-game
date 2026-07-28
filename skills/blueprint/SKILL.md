---
name: blueprint
description: 探查项目、校验请求、澄清未知项，并保存一份实现蓝图。
argument-hint: <FR-<id> | 功能描述>
---

# Blueprint

给定一个 `FR-<id>`（功能需求规格）**或**一段自由文本 `<功能描述>`，为这款 Godot/C# 卡牌游戏产出一份实现蓝图。

## 步骤

### 1. 解析并校验请求
若 `$ARGUMENTS` 是一个 **`FR-<id>`**（首选输入——来自设计的桥梁），读取 `game-design-documents/60-requirements/FR-<id>.md` 并以它为规格：
- 把它的 **Acceptance criteria** 当作蓝图的成功条件（蓝图必须使它们可达成、且可在 Godot 编辑器中验证）。
- 遵循它的 **Scope**（in/out）、**Data & state touchpoints**，以及 `depends-on` 顺序。
- 若该 FR 仍为 `status: draft` 或有非空的 `## Open questions`，则标出它：它尚未签署——在设计前与用户确认，或把他们送回去解决它（`/analyze-new-ideas` → `/derive-requirements`）。

若它是一段自由文本描述，直接使用。

然后对请求本身做合理性检查：
- 它是否自洽（无矛盾或循环依赖）？
- 对于一次 roguelike 轮回，数据流与状态转换是否合理？
- 是否有明显遗漏的边界情况（空牌堆、遭遇中途恢复轮回、种子可复现性、save/version）？
- 若逻辑上有问题，现在就向用户提出——不要继续。

### 2. 知识探查（搜代码之前先读）
1. 读 `.claude/knowledge/architecture.md` 了解宏观地图。
2. 读 `.claude/knowledge/systems/_index.md`；打开相关的 `systems/<name>.md` 笔记（如果已存在）。
3. 读相关的 `.claude/knowledge/data/_index.md` 架构，以及 `.claude/knowledge/autoloads/_index.md`（CycleState、EventBus、DataRegistry、SaveManager 等）。
4. 略读适用的规则文件（scene、data-resource、state-save、ui-input、null-check）。

目标：在动笔前理解预期架构与既有约定。

### 3. 代码探查
**只在 `game-feature-branch/` 内搜索。** `game-testing-branch/` 与 `game-production-branch/` 文件夹是只读快照——搜索它们只会得到重复项。

派出至多 3 个 Explore 智能体**并行**执行，每个都限定在 `game-feature-branch/`：
- **Agent 1 — core**：找出描述中点名的确切场景/脚本/节点；读取它们以了解当前状态。
- **Agent 2 — reusable pieces**：既有的 autoload、系统、数据资源、控件场景，以及可被接线复用而无需重建的 EventBus 信号。
- **Agent 3 — cross-system flow**（仅当功能跨系统时）：该功能所交互的信号、CycleState 字段、save 触点，以及数据资源。

综合各方发现；把描述与现有内容交叉核对。记住这个项目是一份全新的脚手架——很多东西可能尚不存在，这没问题；标出必须创建的部分。

### 4. 澄清检查点 ⏸️
呈现一份结构化摘要：
- **受影响的场景 / 脚本 / autoload / 数据**（完整路径）。
- **可复用的既有部件**（类 + 方法 / 信号 + 文件路径）。
- 需要创建的**缺失部件**。
对任何含糊之处提出有针对性的问题。**在设计前等待确认。**

### 5. 设计蓝图
产出并保存到 `.claude/blueprints/<slug>.md`。文件顶部带 frontmatter：`source-fr: FR-<id>`（自由文本请求则为 `source-fr: -`）与 `date`，供 `/implement` 闭环 FR 台账使用。正文包含：
- 要创建/修改的文件（完整路径）：场景（`.tscn`）、脚本（`.cs`）、数据（`.tres`）、autoload 注册。
- 流程：**input/UI → system → CycleState → EventBus → 响应的系统/UI**，标注哪些部分已存在、哪些必须构建。
- 类形态：字段、`[Export]`、方法、信号；数据资源字段与 id。
- **信号/事件接线**：发出/消费哪些 EventBus 信号（载荷为 id/原语）。
- **RNG 触点**：哪个 seeded 子流驱动任何随机性（依据 `rng-determinism`）。
- **Save 触点**：持久化哪些轮回状态、autosave 点、版本影响。
- **Null/校验计划**（强制）：对每次节点查找、资源加载、registry/字典查找、save 读取——说明它是必需的（带上下文报错）还是可选的（warn + 默认值）。见 `null-check-rules.md`。
- **移动端/触摸 UI 说明**：竖屏布局、容器，以及任何新 UI 的触摸目标。
- **实现顺序**（通常自底向上：数据资源 → 系统逻辑 → 场景/UI → 接线）。

### 6. 闭环
- 在 `.claude/blueprints/_index.md` 中新增/更新对应行（最新的置顶）：`blueprint | source-fr | date | status`，status 置为 `designed`。
- 若本蓝图源自某个 `FR-<id>`，更新 `game-design-documents/60-requirements/`：把该 FR 的 `blueprint:` 设为保存路径，把它的 `status` 翻为 `blueprinted`，并更新 `_index.md` 中的对应行。（这让需求台账如实反映哪些已设计、哪些仍待处理。）

最后建议：运行 `/implement` 来构建该蓝图。
