# ADR-0137 — 设计库以「类概念」组织为单一 `systems/` 树

- **状态：** Accepted
- **日期：** 2026-07-24
- **来源：** handoffs/2026-07-24-docs-restructure-class-model.md

## 背景

设计库早期把「系统怎么运作」与「有哪些数据定义」分成两棵平行的树（`systems/` 与一个独立的 `30-content/` 层）。同一件事因此有两个落点：卡牌的规则写在系统侧、卡牌的字段写在内容层，两处各自漂移而无机制发现——本库对这类重复没有任何检测手段。

## 决策

**设计库以「类概念（Java class 式）」组织为单一 `systems/` 树：每个系统是一个「类」，其数据定义是该类的「字段 / 内嵌类型」。**

- **复杂类型下沉为文件夹**（含 `_index.md` 与 `common-properties.md`），简单主题保持单 `.md`。
- 原独立的内容层**作为一个平行层撤销**，其内容并入所属系统。
- 文件名 / 文件夹与 `.claude/knowledge/systems/` 对应；后者是**指向本库的引用层**，本库是游戏内容 + 技术结构的**双重事实来源**。

树形与逐文档用途 → `systems/_index.md`。

## 理由

- **一个概念一个落点。** 「这一类内容怎么运作」与「它有哪些字段」是同一个类的两面，分成两棵树只会让两处各自漂移，而本库没有任何机制能发现两份说法不一致（同一条判据后来支撑了 `decisions/ADR-0005-knowledge-thin-reference-layer.md`）。
- **类模型让「共有属性写在哪一层」有唯一答案**：类的公共字段写 `common-properties.md`、子类型各写自己的 → `decisions/ADR-0057-common-properties-layering.md`。
- **它把 `.claude/knowledge/*` 的角色钉死为引用层**，从而工程配置层不再持有设计说明。

## 备选方案

- **保留 `systems/` + 独立内容层两棵树** — 否决：制造第二权威，且无检测机制。
- **按玩法领域（战斗 / 经济 / 元进程）分区** — 否决：领域边界随设计演化漂移，而类边界由代码结构锚定，稳定得多。

## 后果

- 新增一类内容 = 在 `systems/` 下新增一个类文档 / 文件夹，不新增顶层分区 → `systems/_index.md`。
- **后续演化（如实记录）：** 2026-08 起在 `systems/` 平级新增了一个**实例层** `content/`（`content/<类型>/<id>.md`），判据是「讲这一类内容的规则 → `systems/`；讲某一个具体条目 → `content/`」。它与本决策不抵触——本决策撤销的是与 `systems/` **重复的类定义层**，而 `content/` 只写「填了什么值 + 回链」，硬边界见 `content/_index.md`。
- `.claude/knowledge/*` 永久是薄引用层，不持有设计细节 → `decisions/ADR-0005-knowledge-thin-reference-layer.md`。
