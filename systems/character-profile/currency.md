# currency

> 轮回货币 灵玉 / jade —— 单次轮回内的软通货，获取 / 消耗。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **轮回货币 = 灵玉 / `jade`（轮回级软通货）。** 灵玉是官方货币名（代码标识符 `jade`），是单次轮回内的货币，随轮回存在、随轮回清理，归 CharacterProfile。它区别于每回合出牌资源 mana（见 `mana.md`）。

- **灵玉的取值域 `[0, ∞)`，归 0 不构成终态。** 它在 `ResourceElements` 表中占一行 `(Min = 0, Max = null, DepletionDefeat = null, CostModifier = null, GainModifier = null)`：施加负值使其低于 0 时**截断到 0**，玩家只是变穷，不触发任何终结路径——`DefeatReason` 三值封闭、无灵玉项，且灵玉随轮回清理，不承载终态语义。表的定义见 `systems/architecture.md`「共享核心类型」，逐行理由见 `systems/services/profile-service.md`。

- **消耗侧的形态至此确定：灵玉的主消耗点是 Exchange。** 购买商品（`-ListPrice`）与刷新库存（`-RerollCost`）是灵玉当前仅有的两个消耗形态，**逐笔即时经 `ProfileManager.TryApply` 提交**，不攒到事件收口；售出法宝是反向的产出形态。定价不逐条目手写，由 `systems/balance.md` 的「商品族 × 稀有度」定价表给出。机制权威见 `systems/adventure-event/exchange/_index.md`。
  - **商店价格修正在物化 / 展示侧施加，不在 element 路径重复施加**——故 `ResourceElements` 表里 `Jade` 的两个修正列恒为 `null`，见 `systems/services/profile-service.md`。
  - **不设篇章维的涨价。** 灵玉随轮回清理、每章重置，与寿元的跨篇章结转不同；篇章间的经济差异应由「掉落多少灵玉」承载，而不是让同一件东西在第三篇章更贵。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **jade 的获取渠道与掉落权重未设计（承重）。** 消耗侧已有形态（见上），**产出侧一片空白**：哪些事件给灵玉、给多少、随篇章如何缩放均未定。它同时卡住定价表——**每格填多少无法在获取渠道答定前反推**。→ `systems/balance.md`、`systems/adventure-event/exchange/`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/currency.md`（待建）。
