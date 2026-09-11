# Art guides —— 台账

每份 art guide 是一份**结构化的生成 prompt**：由 AI 依 vision + 参考素材写出，连同参考素材一并投喂 Midjourney。

- **模板：** [`_TEMPLATE.md`](_TEMPLATE.md)
- **粒度：一个资产类目一份 guide**（公共段 + 条目变量段），逐条目只填变量；判据与理由见 `../_index.md` 的「承重约定」。
- **命名：** 类目 guide 用 `<类目slug>.md`（例：`card-art.md`、`enemy-portrait.md`、`event-backdrop.md`）；**例外升格**的单条目 guide 用 `<类目slug>-<条目slug>.md`（例：`enemy-portrait-finale-tribulation.md`），并须登记进所属类目 guide 的「例外升格」表。
- **上游：** 每份 guide 必须继承 `../art-direction.md`；只写该类目 / 该条目**特有**的部分，不复制粘贴总方向。
- **类目：** 取自 `../_index.md` 的资产类目表。**UI 元件与框架只有点缀素材那一半建 guide**，扁平底子不进 AI 流水线。

## 台账

| guide | 类目 | 覆盖条目 | 状态 |
|-------|------|----------|------|
| _（暂无）_ | | | |

> 状态词汇：`draft`（prompt 已写、未生成）｜`iterating`（已生成、结果未达标、prompt 迭代中）｜`settled`（已出可用结果、prompt 定稿）。
