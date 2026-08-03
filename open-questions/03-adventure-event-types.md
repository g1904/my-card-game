# ③ 逐类型 AdventureEvent 机制（焦点 · 各开一次专门 session）

> 本分片属 `../open-questions.md` 的当前焦点区。逐类型 AdventureEvent 的机制将**各开一次专门 session**（九类各一场），不在一次 handoff 里做完 —— 见 `systems/adventure-event/_index.md`。

- **各类型的结算 / 机制细化。** 九类分类法已定（`decisions/ADR-0002` 九值枚举）。**Combat 已开过第一场专场**（07-30b：参战方结构、意图三档、mana、存档）；仍待设计：**Mystery** 揭示权重 / 机制；**Practice** 的风险 / 回报差异（结构已定为战斗变体）；**Finale** 的独立胜负条件与奖励结构（结构已定为战斗变体、天劫为 Enemy）；Exchange / Research / Explore / Social / Travel 各自的通用结算器数据形态。→ `systems/adventure-event/<type>/`、`decisions/ADR-0002`。
- **ADR-0002 补订。** Explore / Travel 尚未正式并入 ADR-0002 枚举。→ `systems/adventure-event/_index.md`。
- **location 机制细节。** 地域的枚举 / 层级、Travel 如何映射到具体 location、一个 location 开放哪些修行事件池、location 是否随篇章 / 境界变化。→ `systems/game-progression.md`。
- **子类型间的公平配比与出现频率。** 一段修行历程中各类事件的分布、权重、由 location 与 AdventurePlot 如何调制。→ `systems/adventure-event/_index.md`、`systems/services/future-event-service.md`。
