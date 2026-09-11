# currency

> 轮回货币 —— 单次轮回内的两层货币：**灵石 / spiritStone**（基础）与 **仙玉 / immortalJade**（高阶），各自的获取 / 消耗。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **轮回货币分两层，两者都是轮回级。** 二者都随轮回存在、随轮回清理，归 CharacterProfile，都区别于每回合出牌资源 mana（见 `mana.md`）。
  - **灵石 / `spiritStone` —— 基础货币（软通货，官方货币名）。** 单次轮回内的日常通货，主要花销在 Exchange。
  - **仙玉 / `immortalJade` —— 高阶货币。** 用于 Exchange 中的高阶商品。**「高阶」由稀有度与价格量级表达，不由新机制表达**：它走的是与灵石**完全相同**的 element 通道、相同的 Exchange 交易 pipeline，区别只在「哪些商品收它」与「一次能拿到多少」。

- **两者的取值域同为 `[0, ∞)`，归 0 都不构成终态。** 它们在 `ResourceElements` 表中各占一行 `(Min = 0, Max = null, DepletionDefeat = null, CostModifier = null, GainModifier = null, Add)`：施加负值使其低于 0 时**截断到 0**，玩家只是变穷，不触发任何终结路径——`DefeatReason` 三值封闭、无货币项，且两种货币都随轮回清理，不承载终态语义。表的定义见 `systems/architecture.md`「共享核心类型」，逐行理由见 `systems/services/profile-service.md`。

- **消耗侧的形态至此确定：两种货币的主消耗点都是 Exchange。** 购买商品（`-ListPrice`）与刷新库存（`-RerollCost`）是当前仅有的两个消耗形态，**逐笔即时经 `ProfileManager.TryApply` 提交**，不攒到事件收口；售出法宝是反向的产出形态。定价不逐条目手写，由 `systems/balance.md` 的「商品族 × 稀有度」定价表给出——**该表的每一格同时给出支付币种与基准价**，故一件商品收灵石还是收仙玉由它落在表上的位置决定，内容侧不额外书写。机制权威见 `systems/adventure-event/exchange/_index.md`。
  - **商店价格修正在物化 / 展示侧施加，不在 element 路径重复施加**——故 `ResourceElements` 表里 `SpiritStone` 与 `ImmortalJade` 两行的两个修正列都恒为 `null`，见 `systems/services/profile-service.md`。
  - **两者都不设篇章维的涨价。** 两种货币与寿元同形，**跨篇章结转**（见下条）——价格因此必须跨章稳定，否则攒下的余额会被通胀稀释，「省着花有跨篇章回报」当场失效。篇章间的经济差异改由「掉落多少货币」承载，而不是让同一件东西在第三篇章更贵。

- **两种货币跨篇章结转，篇章边界不做任何清零动作。** 它们只随轮回清理，与寿元同为一条贯穿整个轮回的资源线；`ChapterManager` 的篇章边界职责因此不含任何货币项（见 `systems/services/life-cycle-service.md`）。**推论：省着花对货币同样有跨篇章回报**，而仙玉可以跨章攒到足以兑现顶档商品——「顶档仙玉商品 = 一次轮回至多一件」由产出量与定价的算术保证，不需要任何新机制。

- **灵石的获取渠道 = 战斗，非战斗事件默认不给（灵石 ≈ 战利品）。** 主产出口是 `EncounterSpec.BaseReward` 加道念差的线性加成；`Research` 与 `Exchange` 不给（前者已有定案，后者是消费点——在消费点发钱等于给定价表打一个不可见的折），`Travel` 由结构性禁令挡住（换图的代价不得被同一事件抵消），`Explore` 的产出随真身走、本身不再给一份。**事件 outcome 的货币通道保留但收窄**：`OutcomeRule.FixedResource` 的可写 key 白名单不改，非 Combat 类型的例外由一条加载期软检查看住（见 `systems/adventure-event/common-properties.md`）。
  - **这条口径把灵石收入钉在「战斗场数」这个已知且近似恒定的量上**，而定价表不设篇章维恰恰要求收入的形状可控。篇章缩放因此落在「一场给多少」而非「东西多贵」；逐章给予量、预期收入与 25 格定价表初值见 `systems/balance.md`。

- **仙玉的唯一主动获取通道 = 稀有 AdventureEvent 产出。** 它走既有的 `OutcomeSpec.Elements` 路径，零新机制——`systems/services/future-event-service.md` 的合法子集表相应地把仙玉列为可产出项。稀有度是仙玉「高阶」的第一重表达：它不随每场战斗涓流发放，只在少数标志性事件上出现。**售出（商店内与储物袋随售两条通道）是同币回流，不新增获取渠道**；且**售出侧结构上一枚仙玉都产不出**——唯一可售出的族是 `CharacterItem`，而定价表在该族五档全部收灵石（见 `systems/balance.md`）。出现频次与单次给予量同处该文件。
  - **不由付费获取。** 一条可反复付费购入的消耗型硬通货与「付费面一律买断式、五项排除明含消耗型货币」的付费面口径相抵（见 `systems/monetization.md`）。
  - **不由成就发放。** 成就是账号级的，用它产出轮回级货币构成跨层输血。
  - **不由 Finale 发放。** Finale 的 `BaseReward` 本就是战斗货币通道的一部分（它拿标准场的两倍），另设一条「篇章收口发放」等于对同一场战斗重复记账；而第三篇章的 Finale 是轮回终点，那一笔确实无处可花。
  - **不新增事件类型来承载它。** `eventType` 是五值封闭枚举，新增一值牵动物化链与 `AdventureEventData` 全套字段，而稀有事件产出这条既有路径已经足够。

- **仙玉的花销通道 = 高阶 Exchange 商品（唯一通道）。** Exchange 全套已成文（`ExchangeGoodsKind` 五族 · 「族 × 稀有度」定价表 · `CanAfford` / `TryApply` 单条 pipeline），仙玉计价只是让定价表的一部分格子收另一种币，`CanAfford` / `TryApply` 对 `CostKey` 本就泛化，零改动。
  - **不用于置换账号级资产。** 置换的对象是账号级资产，用轮回级货币支付即跨层输血。

- **灵石与仙玉之间完全不可兑换（正面纪律，零机制）。** 不设任何单向或双向兑换通道。**理由：两层货币的意义在于两条独立的产出曲线各自约束一片消费面**——一旦可兑换，双层立刻退化为「单层 + 一个汇率」，高阶商品的门槛从「你是否走到过那个稀有事件」变成「你攒够灵石没有」，稀有度这一重表达随之失效。这与「禁止跨层兑换以防清仓换经济成为最优解」是同一条论证结构。
  - **售出侧同币回收，因而不产生事实汇率。** `SellRatePercent` 的折算基准取「族 × 稀有度」定价表上的基准价，而币种就在那一格上 ⇒ 卖出所得恒与买入同币。不可兑换因此由既有结构闭合，不需要任何额外判断。

Source: `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-25-currency-split-spirit-stone-and-immortal-jade.md` · `handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md` · `handoffs/2026-09-05-currency-acquisition-and-pricing.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- 无。两条产出曲线的渠道口径与取值初值均已给出（逐章给予量、预期收入、25 格定价表与币种分布见 `systems/balance.md`）；剩余的只是绝对数字随内容扩充后的统计校准复核，登记在该文件的待决问题里。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/currency.md`（待建）。
