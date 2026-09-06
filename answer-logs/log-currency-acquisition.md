# Answer log currency-acquisition

- 日期：2026-09-05
- 来源：`inbox/archive/solution-draft-currency-acquisition.md` → `handoffs/2026-09-05-currency-acquisition-and-pricing.md`
- 移出条数：4 全条（`deferred-content.md` 2 条 · `03-adventure-event-types.md` 1 条部分收窄 · `balance.md` / `exchange/_index.md` / `currency.md` 的对应待决条同批改写）

---

**灵石 `spiritStone` 的获取渠道与掉落权重（承重）** → **战斗是主产出口，非战斗事件默认不给（灵石 ≈ 战利品）。** 主通道 = `EncounterSpec.BaseReward` + 道念差 × `rewardPerMomentum` 的线性加成；`Research` / `Exchange` 不给（后者是消费点，在消费点发钱等于给定价表打一个不可见的折）、`Travel` 由结构性禁令挡住、`Explore` 的产出随真身走。篇章缩放落在「给多少」：篇章标准战斗给予量 `S(c)` = 15 / 35 / 60，`Practice ≈ 0.5 × S`、`Finale ≈ 2.0 × S`。**货币量不引入档位枚举、就写绝对整数**——定价表不设篇章维 ⇒ 绝对值本身跨章可比，套档位映射不增分辨率。（归 `systems/balance.md`「货币产出与定价」· `systems/character-profile/currency.md`「意图」）

**仙玉 `immortalJade` 的获取量与花销价格量级** → **每篇章 1–2 次携带仙玉产出的事件、单次 1 / 2 / 4 枚，三章统一。** 频次载体是既有的 `SelectionWeightGrades.Rare` 档，不加字段、不加校验。**币种分布：`PlayerItem` 全五档 · `CharacterPower` T4 / T5 · `CultivationTechnique` T5 收仙玉，其余 18 格收灵石；`CharacterItem` 五档恒收灵石。** 基准价 `PlayerItem 1 / 2 / 3 / 5 / 8` · `CharacterPower` T4 3 / T5 5 · `CultivationTechnique` T5 6，与累计产出 `J_cum ≈ 2 / 5 / 10` 对齐成一条递进曲线，「顶档仙玉商品 = 一次轮回至多一件」由算术保证。（归 `systems/balance.md` · `systems/adventure-event/exchange/_index.md`）

**商店定价表每格填多少 · 哪些格填仙玉 · 两档回收率** → **25 格初值由「族系数 × 稀有度基价」外积给出**（稀有度基价逐档 ×2：20 / 40 / 80 / 160 / 320；族系数 `Card 0.75 · CharacterItem 1.0 · CharacterPower 1.5 · CultivationTechnique 2.0 · PlayerItem 2.5`），表结构不变、仍写 25 个独立整数。**回收率 `SellRatePercent` 初值 40%（区间 30–50）· `PackSellRatePercent` 初值 15%**。**载体新开一份平衡资源 `ExchangePriceTableData`**（25 格 + `PackSellRatePercent` 同住一份，两者共用同一张基准价表 ⇒ 跨字段不变式）。**仍留在待答的部分**：刷新基价 / 递增量与单事件槽位总数上界（首批刷新一律填 0），以及全部绝对数字随内容扩充后的统计校准复核。（归 `systems/balance.md` · `systems/adventure-event/exchange/_index.md`）

**「货币每章重置」这条措辞（全库零机制承载）** → **改为跨篇章结转，与寿元同形。** 篇章边界不做任何清零动作，货币只随轮回清理；`ChapterManager` 因此不新增任何职责、不新增存档点——结转在这里是「什么都不做」的结果。三处镜像措辞同批改写（`currency.md` · `balance.md` · `exchange/_index.md`），「定价表不设篇章维」的理由换成**跨章结转要求价格跨章稳定**（否则余额被通胀稀释，「省着花有跨篇章回报」当场失效）。（用户 2026-09-05 裁决；归 `systems/character-profile/currency.md` · `systems/services/life-cycle-service.md` · `systems/balance.md` · `terminology.md`）

---

## 同批裁决与订正（不在待答清单上，一并记录）

- **仙玉不落 `CharacterItem` 行，净产出敞口结构性关闭。** 可售出 ⟺ `ExchangeGoodsKind == CharacterItem` 是代码级常量判据 ⇒ 仙玉不落该族即让「售出产仙玉」不可能发生，`balance.md` 原先「被接受的取舍 + 归统计校准把关」整条删除。**代价：永远编排不出以仙玉计价的法宝**（含补天丹类顶级消耗品）。（用户 2026-09-05 裁决）
- **`currency.md`「不由 Finale 发放」的结论保留、理由重立。** 原理由（篇章收口发放随后即被清理、无处可花）在结转口径下整条失效；新理由 = Finale 的 `BaseReward` 本就是战斗货币通道的一部分（拿 `2.0 × S`），另设一条收口发放等于对同一场战斗重复记账，且 ch3 的 Finale 是轮回终点。
- **Travel 补货币产出禁令。** 校验 6 的 `ResourceKey` 集合由 `{ LifeSpan }` 扩为 `{ LifeSpan, SpiritStone, ImmortalJade }`，**`Direction == Gain` 那一半保留**——Travel 条目的货币扣减向是合法编排，草稿建议的写法会误禁它。
- **新增一条加载期软校验（`PushWarning`）：** `eventType != Combat` 的条目携带 `FixedResource(SpiritStone | ImmortalJade)` 且 `Direction == Gain` → 报出条目 `Id`（`adventure-event/common-properties.md` 校验表第 9 行）。另有一条 `BaseReward` 灵石量 > `2.5 × S(篇章)` 的软检查登记在 `balance.md`。
- **`ADR-0089` 两处订正。** ① 后果段「仙玉的唯一主动获取通道是**商店**」是误写——商店是花销出口，获取通道是稀有 AdventureEvent 产出；同段的净产出敞口改写为「由币种分布结构性关闭」。② 「`CostKey` 由 15 值增至 16 值」写于 2026-08-25 时正确，是 `LifeTotal` 退役把 16 改回 15 时漏改本处，订正措辞保留这段算术。
- **`terminology.md` 仙玉词条补「主动」二字**（「唯一获取通道 → 唯一**主动**获取通道」那次订正没落到术语表），两个词条同时补上跨篇章结转与获取通道。
- **`combat/_index.md` 的「三档奖励厚薄」待决条收窄**：`BaseReward` 的灵石量已由 `S(c)` 给出，仍待定的只剩 `RewardPoolId` 与其余 element 的厚薄。

## 仍然开放（未随本次移出）

- `I(c)` 的道念差加成项依赖两个明令不得引为承重依据的待实测格（败率 20% · `E[道念差]`），故 `I(ch1) ≈ 127` 是量级估算而非定稿。
- ch2 / ch3 无逐类型事件构成表，`I(ch2)` / `I(ch3)` 比 ch1 粗一档。
- 「玩家在 ch1 主要遇到 Tier1–Tier2」这一购买力校验前提依赖战后奖励池 / 商店库存的 `RarityTier` 分布权重，那一条仍在 `balance.md` 待决区，是本次标定的前置而非产物。
