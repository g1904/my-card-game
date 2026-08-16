# ③ 逐类型 AdventureEvent 机制（焦点 · 各开一次专门 session）

> 本分片属 `../open-questions.md` 的当前焦点区。逐类型 AdventureEvent 的机制将**各开一次专门 session**（五类各一场），不在一次 handoff 里做完 —— 见 `systems/adventure-event/_index.md`。

- **各类型的结算 / 机制细化。** 五类分类法已定（`decisions/ADR-0002` 五值枚举 + Combat 的 `combatTier` 三档）。**Combat 已开过多场专场**（07-30b 参战方结构 / mana / 存档，08-15d 意图机制整条移除，08-06d 三档遭遇参数，08-09b Finale 档的残卷与重试）；仍待设计：**Exchange**（库存生成、定价 / 折扣、刷新、售出）· **Research**（卡组操作清单与代价、除卡组外是否另有产出、开局构筑事件的候选生成）· **Explore**（揭示池权重、揭示 UI、遮罩下的成本呈现）· **Travel**（常规出场概率、80 / 20 是否可被剧本调制）各自的通用结算器数据形态。→ `systems/adventure-event/<type>/`。
- **NPC / 势力模型是否仍需要（08-15c 新增）。** 社交语境并入 Exchange 后，NPC / 势力是**降级为交易条目的风味层**（只是文案与插图），还是仍需一套数据模型（NPC 如何定义、好感 / 关系度是否有持久数值、跨轮回是否留存）？社交型产出是否触发 AdventurePlot 分支亦未定。→ `systems/adventure-event/exchange/_index.md`、`systems/services/plot-manager.md`。
- **`manaLimit` 下降（−1）的承载点（08-15c 新增）。** 「罕见 −1（走火入魔类）」此前挂在探索秘境上；Explore 现为纯元类型、无自己的产出口径，而它可揭示的三类都不是自然的走火入魔场景。**改挂 Research（闭关走火入魔）还是接受「本作没有 `manaLimit` 下降」**未定——取消它等于让 `manaLimit` 变成单调不减。→ `systems/character-profile/mana.md`、`systems/adventure-event/research/_index.md`。
- **`Practice` / `Finale` 档的奖励厚薄。** 三档的回合数与胜负门槛已定；**`BaseReward` 与 `RewardPoolId` 随档位如何调厚薄**未定，归 **ch1 数值标杆专场**。→ `systems/balance.md`。
- **非战斗形态的 Finale。** 哪些境界突破走非战斗路径、其结算形态如何（仍是 Combat 类的一个特例还是另起路径），留待日后定制。→ `systems/adventure-event/combat/_index.md`。
- **各档与隐藏属性的交互。** `Practice` 是否推拉道心 / 煞气 / 寿元；「大限将至」等隐藏属性剧情线触发后是否转入 `Finale`、`Finale` 是否消耗 / 检定隐藏属性，均未定。→ `systems/services/plot-manager.md`。
- **location 机制细节。** 地域的枚举 / 层级、Travel 如何映射到具体 location、一个 location 开放哪些修行事件池、location 是否随篇章 / 境界变化。→ `systems/game-progression.md`。
