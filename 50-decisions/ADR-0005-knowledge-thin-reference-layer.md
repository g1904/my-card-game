# ADR-0005 — `.claude/knowledge` 为薄引用层

- status: Accepted
- date: 2026-07-28
- supersedes:
- superseded-by:

## Context

`.claude/knowledge/*` 是面向 Claude 的提炼视图，夹在两个事实来源之间：代码（`game-feature-branch/`——「实际是什么」）与设计文档（`game-design-documents/`——「应该是什么」）。`2026-07-24` 的文档重构已把本库确立为**游戏内容 + 技术结构的双重事实来源**，并把知识层「降为引用层」，但**未定义引用层的具体形态**——`open-questions.md` 将其列为 ADR 候选：逐文件替换为**薄引用**，还是保留**提炼摘要 + 回链**？该问题直接决定 `/sync-knowledge` 的语义。

2026-07-28 的一次全量 sync 提供了判据性证据：

- 该次修复的漂移**100% 是「设计定了、知识不知道」，0% 来自代码**。知识层当时的全部维护成本，都花在与一个它本该只是指针的库做同步上。
- 同步过程本身把 EventBus 14 行负载表、`OpResult` / `EventOption` 定义、四个后端接口等**逐字抄进了知识层**——即「提炼摘要」形态在实践中会自发退化为副本。
- 副本不增加任何信息（权威文档里已是最终的代码形态），却是下一次漂移的唯一来源。

## Decision

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
- **系统落地后的 `systems/<name>.md`** 写**代码侧事实**（文件路径、EventBus 事件、RNG 子流、存档触点、已知的坑）并回链权威文档，**不复制设计意图**。
