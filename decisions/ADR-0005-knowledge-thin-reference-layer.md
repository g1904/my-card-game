# ADR-0005 — `.claude` 是工程层，对设计只做薄引用

- status: Accepted
- date: 2026-07-30
- supersedes:
- superseded-by:

## Context

`.claude/knowledge/*` 是面向 Claude 的提炼视图，夹在两个事实来源之间：代码（`game-feature-branch/`——「实际是什么」）与设计文档（`game-design-documents/`——「应该是什么」）。`2026-07-24` 的文档重构已把本库确立为**游戏内容 + 技术结构的双重事实来源**，并把知识层「降为引用层」，但**未定义引用层的具体形态**——`open-questions.md` 将其列为 ADR 候选：逐文件替换为**薄引用**，还是保留**提炼摘要 + 回链**？该问题直接决定 `/sync-knowledge` 的语义。

2026-07-28 的一次全量 sync 提供了判据性证据：

- 该次修复的漂移**100% 是「设计定了、知识不知道」，0% 来自代码**。知识层当时的全部维护成本，都花在与一个它本该只是指针的库做同步上。
- 同步过程本身把 EventBus 14 行负载表、`OpResult` / `EventOption` 定义、四个后端接口等**逐字抄进了知识层**——即「提炼摘要」形态在实践中会自发退化为副本。
- 副本不增加任何信息（权威文档里已是最终的代码形态），却是下一次漂移的唯一来源。

本 ADR 初版只覆盖 `.claude/knowledge/*`，把 `.claude/rules/*` 的主从关系留作待答项。2026-07-30 的意图把范围提到整个 `.claude`：**`.claude` 应当只关乎工程配置、工程规则与可复用技能，设计的内核活在设计库、在 `.claude` 内只被引用与轻描述** —— 薄引用因此不是 knowledge 一个文件夹的形态，而是 `.claude` 对**设计内容**的统一形态。

## Decision

### 0. `.claude` 的定位 = 工程层（本 ADR 的总纲）

`.claude` **只承载两类东西**：**① 工程相关的配置与规则**（harness 配置、C#/Godot 互操作与场景 / 数据 / 存档 / UI / null 校验纪律）与 **② 可复用的技能**（推进项目的流程封装）。**一切设计相关的知识与细节归设计库**（`game-design-documents/` / `backend-design-documents/`）；`.claude` 内**只做引用与轻描述**。

**主从关系（冲突裁决规则）：**

| 冲突性质 | 以谁为准 | 判据 |
|----------|----------|------|
| **设计性内容**（机制、数值、字段、契约、流程） | **设计库** | 讲「游戏是什么」 |
| **工程性约束**（命名、生命周期、热路径、工具 / PATH、目录纪律） | **`.claude/rules/*`** | 讲「代码怎么写」 |

`.claude` 的目的是**帮助实现设计意图**；愿景的内核活在设计库。因此设计一侧改动时，`.claude` 必须跟着改（它是从）；而工程一侧设计库无权威，不构成冲突源。

**这条总纲适用于整个 `.claude`**，`rules/` 与 `skills/` 同样受约束：规则文件里凡属设计结论的，形态只能是**一句话承重纪律 + 回链设计库**，不得展开为设计说明。Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。

### 1. 知识层的具体形态

**采用薄引用形态。** 知识层只回答三件事：

1. **代码现在是什么样** —— 这是它**独有的真值**，设计库里没有：存在哪些场景 / 脚本 / autoload / `.tres`，`project.godot` 配了什么，哪些系统真的落地了。
2. **权威文档在哪** —— 领域 ↔ `game-design-documents/` 的导航表。
3. **写代码时会改变写法的承重纪律** —— 每条一句话 + 回链（例：抽取走 `AllEnabled()`；`_Ready` 订阅 / `_ExitTree` 退订；B/C 带 `Async` 后缀、A 不带；运行时绝不写 `XxxData : Resource`）。

**副本判据（本 ADR 的可执行核心）：**

> 凡在 `game-design-documents/` 里**已是代码形态**的东西——方法签名、枚举、`record` / `interface` 定义、EventBus 负载表、JSON schema、数值旋钮表、完整流程步骤——知识层**只留链接，不留副本**。

**两类文件的分界（例外由「设计库里有没有它的权威」决定）：**

| 类别 | 文件 | 形态 |
|------|------|------|
| **本作设计的投影** | `architecture.md`、`systems/*`、`data/*`、`scenes/*`、`autoloads/*`、`dictionary.md`、`standards/{signal-eventbus,rng-determinism,save-format}.md` | **薄引用**：导航 + 代码现状 + 承重一句话，**零代码块** |
| **C#/Godot 引擎实践** | `standards/{csharp-conventions,godot-scene-conventions,mobile-portrait-ui}.md` | **保留实质** —— 讲的是引擎 / 语言而非本作设计，在本库中无权威，不构成副本 |

`dictionary.md` 只保留**通用体裁词汇**（Balatro / StS 惯例）；本作专有术语一律指向根级 `terminology.md`。

## Consequences

- **`/sync-knowledge` 的语义随之改变**（已落地）：新增**「副本化」为首要漂移类型**（发现代码形态内容 → 删除并替换为回链）；「缺失 → 补一条目」改为「补一条**导航条目 + 回链**，不是补一段设计说明」；报告模板新增 `### Thinned` 段；对账范围新增 `standards`（此前那三份设计投影文件不在任何范围内，从未被对账）。
- **首次执行结果：** 知识层 76 KB / 709 行 → **48 KB / 451 行**（-37%），全库仅剩 1 个代码块（`data/_index.md` 的三层存储方位示意图，判定为导航而非代码形态）。
- **本库的权威地位增强。** 设计文档成为代码形态契约的唯一书写地；改一处即全局生效，不再需要「同一决定写两遍」。
- **代价：** Claude 读知识层后若需具体形状，多一跳去读权威文档。已接受——这一跳是**按需**发生的，而副本的同步成本是**每次 sync 必付**的。
- **新增的纪律负担：** 写知识笔记时须自觉执行副本判据。`/sync-knowledge` 每次运行会做首要检查，构成兜底。
- **`.claude/rules/*` 的主从关系随之答结**（此前是 `systems/common-properties.md` 的待决问题）：规则文件在**工程约束**上是权威、在**设计内容**上是从属摘要；冲突按上表裁决。`.claude/rules/Context.md` 与 `.claude/README.md` 已落下这条约定。
- **`.claude/skills/*` 一并纳入。** 技能是流程封装（工程），可自由新增 / 改写；但技能文本中引用的设计结论同样只留一句话 + 回链。
- **系统落地后的 `systems/<name>.md`** 写**代码侧事实**（文件路径、EventBus 事件、RNG 子流、存档触点、已知的坑）并回链权威文档，**不复制设计意图**。
