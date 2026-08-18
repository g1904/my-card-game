# Exchange 的交易机制与「事件内即时提交」纪律

- id: 2026-08-17d-exchange-mechanics-and-transaction-discipline
- date: 2026-08-17
- topic: systems/adventure-event/exchange · systems/services/profile-service · systems/services/life-cycle-service · systems/services/future-event-service · systems/adventure-event/common-properties · systems/common-properties · systems/architecture · systems/character-profile/currency · systems/character-profile/item · systems/character-profile/deck · systems/player-profile/player-item · systems/services/plot-manager · systems/balance · ux/screen-flow
- status: distilled
- distilled-to: systems/adventure-event/exchange/_index.md, systems/adventure-event/exchange/common-properties.md, systems/adventure-event/common-properties.md, systems/architecture.md, systems/common-properties.md, systems/services/profile-service.md, systems/services/life-cycle-service.md, systems/services/future-event-service.md, systems/services/plot-manager.md, systems/services/combat-service.md, systems/character-profile/_index.md, systems/character-profile/currency.md, systems/character-profile/item/_index.md, systems/character-profile/deck/_index.md, systems/player-profile/player-item/_index.md, systems/balance.md, ux/screen-flow.md

## Intent（distilled）

**一句话：** Exchange 是五类里唯一一类「一次事件内玩家要做多次主动消费」的类型，它逼出的不是一个 Exchange 专用补丁，而是**两条全局纪律的准确化**——事务纪律从「一个事件 = 一次事务」改写为「**收口是一次事务，事件内部的主动消费即时提交**」，`AppliedChange` 从「那一次 `TryApply` 的入参」放宽为「**本次事件的最终账**」。交易机制本身则几乎全部落在既有结构上：不开第三个 resolver、不新建抽取池、不新增存档点，只加两个物化字段、一个 `Source` 成员、一个 `ModifierKey` 成员。

### ① 事务纪律改写：收口是一次事务，事件内部的主动消费即时提交（承重 · 适用面不限 Exchange）

> **一个事件的收口是一次事务、一个存档点；事件内部的主动消费即时提交。**

- **它统一的是三个已经存在的实例，不是为 Exchange 开例外**：古宝使用次数的即时写入 · 战斗过程中的血 / mana 即时写入 · Exchange 的逐笔交易。前两者的措辞本来就是「不攒到收口」，旧表述与它们已经对不上。
- **落笔处必须同改**：`systems/services/profile-service.md` 与 `systems/adventure-event/common-properties.md` 是这条纪律的两个承载点，另有 life-cycle-service / combat-service / character-profile 数处引用它的句子。**留一处旧措辞就是留一个第二权威。**
- **逐笔提交的三条理由：**
  - **`CanAfford` 的正确性要求余额是真的。** 买第二件时的灰显判据必须读扣掉第一件之后的 jade；攒到收口就要维护一份「已扣未提交」的影子余额，而它与 `Evaluate(spec)` 是两条路径——正是「`CanAfford` 与 `TryApply` 必须走同一条 pipeline」要防的分裂。
  - **它堵死「买完退出重进拿回灵玉」**，与古宝次数即时写入是同一条理由。
  - **一笔交易本身就是自足事务**（`-jade` + 一条产出），「全有或全无」在这一笔内已闭合，不需要跨笔原子性。
- **接受的代价（明写）：** 中途退出的玩家停在「已买两件、第三件没买」的状态。**这正是玩家的真实意图**，不是半成品状态。
- **不新增存档点类型。** 每笔提交是一次 Profile 变更，走既有「变更后由 sync-service 上行」通道，与战斗内即时写入同形；`eventEnd` 的自动存档点照常。

### ② `PastEventEntry.AppliedChange` 放宽为「本次事件的最终账」

- 由 life-cycle-service 在组装痕迹时把**逐笔已提交的 spec 累加**进 `AppliedChange`——**记账，不再施加**；它不是第二个写入点。
- **不这样做的代价**：履历 / 剧本 / 诊断三个消费方都读不出玩家在商店里做了什么，而这正是 `AppliedChange` 被引入时要消除的坏状态。
- **代价明写（不得省略）：** `AppliedChange` 不再与「`eventEnd` 那一次 `TryApply` 的入参」逐字段相等，**两者的一致性不能再机械断言**；诊断与回放读它时一律以「最终账」为准。

### ③ 结算形态：不开第三个 resolver

Exchange 仍走 `GenericEventResolver`。resolver 的拆分轴是「有没有状态机」，而 Exchange 没有——没有回合循环、没有跨帧的规则推进、没有需要引擎驱动的阶段机。「浏览 → 买若干件 → 离开」是一串**事件内决策点**，与战后奖励面板、能力置换面板、Research 构筑面板同构，那三处都已明写「不新增机制」。

`ResolveOutcome` 在玩家点「离开」时收口，携带 ① 本次已提交的交易清单（**记账用，不再施加**）② 非购买 outcome / effect（对话结果、赠礼、隐藏属性推拉），②照常并入 `eventEnd` 那一次合并 `TryApply`。

### ④ 库存：物化时掷定，随 `EventOption` 落存档

- 用既有的 **`RngStream.Shop` 子流**，经 `AllEnabled()` 取池，**不新建任何抽取池**。依据是三条已定纪律的直接推论：唯一物化点 · 产出即定稿不得回查模板重算 · 物化产出的数值必进快照。
- **模板侧载体 `ExchangeSpec`**（挂 `AdventureEventData`，非 Exchange 为 null）+ **`ExchangeStockRule`**（一条规则 = 若干同族槽位）；**定稿实例 `ExchangeOffer`**（immutable）。
- **商品族 `ExchangeGoodsKind` 五值 = 已存在的抽取池的一一映射**：`Card` / `CultivationTechnique` / `CharacterItem` / `CharacterPower` / `PlayerItem`。**法则 `(Power, Player)` 不在族内**——`Source` 合法子集表对它是 ❌。
- 取池链沿用授予池那一条：`AllEnabled()` → 按 `Kind` 映射仓储 → 排除 `ExclusiveSource != null` → 排除已持有（能力族）→ `RarityFilter` → 按 `RarityTier` 权重 `PickMany(shopRng, SlotCount)`（**无放回 ⇒ 同批不出现重复商品，免费成立**）。
- **买完即售罄，同一 offer 不可重复购买**：不设售罄，一个高价值 offer 会把 jade 全部单点吸走，库存槽位失去意义。

### ⑤ 定价 = 一张「商品族 × 稀有度」定价表 + 两条折扣通道

- 与 `lifeSpanCost` 的「事件类型 × 篇章」定价表完全同构：表放 `balance.md`，**内容条目默认不填、取表值**，需要风味差异时在 `ExchangeStockRule.PriceOffset` 上标偏移。**不设篇章维**——jade 随轮回清理、每章重置，篇章差异应由「掉落多少 jade」承载，而非「同一件东西涨价」。
- **折扣通道一 `ModifierKey.ShopPrice`**（PlayerPower 的具名 modifier）：**在物化时施加、写入 `ExchangeOffer.ListPrice`**，因此**不进 `ResourceElements` 表**。
- **折扣通道二 `ExchangeStockRule.DiscountPercent`**（内容侧静态折扣，表达「这位商贾对同门有优待」），与 D2 来源不同、可叠加：
  `ListPrice = ApplyModifier(ShopPrice, (BasePrice + PriceOffset) × (100 − DiscountPercent) / 100)`，`Clamp` 到 `>= 1`（免费商品走非购买 outcome 的赠礼，不由折扣产生）。
- **`ListPrice` 物化时定稿，代价明写：** 轮回中途新获得的降价修正不影响已定稿库存，下一个 Exchange 事件才生效。理由与「产出即定稿」一致，反例（展示时现算）会让同一 offer 在两次进入之间变价。

### ⑥ `Jade` 的 `CostModifier` 恒为 `null`

由 ⑤ 直接答结，不含取向成分：价格在**物化 / 展示侧**修正、`ListPrice` 定稿后才进 `TryApply`。若改填 `CostModifier = ShopPrice` 会**打两次折**（`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)`，传入的 `BaseValue` 已是修正后的 `ListPrice` ⇒ 玩家看到 80、实扣 64，灰显判据一并偏移），正是「一个 `ModifierKey` 只能有一个施加点」要防的坏状态。

**连带：`ModifierKey` 增成员 `ShopPrice`。** 「表里出现的 key 必须是 `ModifierKey` 成员，反向不要求」⇒ 它在 `ModifierKey` 里、不在 `ResourceElements` 表里，完全合法。

### ⑦ 售出：仅 `CharacterItem` 一族可售出

```
可售出 ⟺ 该持有物的 ExchangeGoodsKind == CharacterItem
```

- **准入是代码级常量判据，不做成内容可配的族白名单。** 内容侧若能逐条目开族，一个填错的条目就打开一条本定案要封的通道，而**校验无从判断作者是不是故意的**；钉在代码里，误开在编译期就不存在。其余四族恒不可售。
- **条目侧仍保留两个字段**：`SellEnabled`（该商店是否收购，让「只卖不收」的商店可编排）与 `SellRatePercent`（回收率旋钮）。
- **原三条反对理由的现状（如实记账）：** 卖卡 = 第二条弃卡通道 → **已消解**（卡牌 / 功法不可售，卡组增删仍唯一归 Research）· 古宝被贱卖 → **已消解**（`PlayerItem` 不可售）· **储物袋 9 格从纯取舍位变成可换 jade 的位置 → 仍然成立，且正落在被开放的这一族上**。9 格明写为「真正会咬人的构筑取舍位，不是溢出防护」；能卖 ⇒ 满袋从「必须放弃一件」变成「换成 jade」。
- **两个缓解旋钮（不改定案）：** 回收率显著低于标价（建议 30–50%，归 ch1 标杆）；**`SellRatePercent` 折算基准取「族 × 稀有度」定价表的基准价，不取 `ListPrice`**——后者已含 `ShopPrice` 与 `DiscountPercent`，按它折算会让「在打折商店卖东西更亏」，玩家读不出因果。
- **售出即时提交**，与购买同一条路径。
- **新增 `Source.ExchangeSell`**（买与卖在履历、成就与诊断上是两件事；复用 `ExchangePurchase` 会让「购买次数」这类统计永远算不准）。它是**本定案唯一的结构增量**。**它本身不单独 bump schema**——字段形状不变（仍是一个整数 code），仅值域扩大，与既有那条通则一致；但它随同批的 `EventOption` 两个新物化字段落在**一次** bump 内（当前无线上存档 ⇒ 空迁移）。合法子集表加一行，只有 `(Item, Character)` 为 ✅；它也是清单里**唯一只出现在 `Op == Remove` 上**的成员，故 `Op == Grant` 带 `ExchangeSell` 是必需缺失、整批拒绝。

### ⑧ 刷新（reroll）：机制落地，首批内容默认关闭

- 花 jade 重掷整批库存，价格 `RerollBaseCost + RerollCostStep × 已刷新次数`，上限 `MaxRerollCount`；掷定走 `Shop` 子流，**重掷结果即时落存档**（与「候选须预先算定并落决策点存档，否则退出重进可以重掷」同一条纪律——这是 reroll 能存在的前提）。
- 支付走购买同一条路径，不新增机制。
- **首批内容默认关闭**（`RerollBaseCost = 0` / `MaxRerollCount = 0`）：机制先落地、数据先留空是本库既有偏好。

### ⑨ NPC / 势力：降级为风味层，不建数据模型

- **不新建 `NpcData` / `FactionData`，不设好感 / 关系度数值，不跨轮回留存。** 四条依据：
  - **ADR-0002 的判据原样延伸**——「风味不需要枚举值来承载」对字段同样成立。NPC 若只影响文案与插图，它就是 `Id` 命名约定 + `LocalizedText` + 图标字段，已经全部就位。
  - **好感度若有持久数值，它就是第四个隐藏属性**，而档位表已定为三属性 12 档且明写「档数永远不是该动的旋钮」；加一条要连带新增 `Status` band 字段、一套档位数据、回滞 δ、加载期校验与 `HiddenStat` 枚举成员（存档迁移）。代价与收益完全不成比例。
  - **跨轮回留存撞既有分层**——账号级持久数据归 `PlayerProfile`（其字段结构本身仍是待答项），且它与 jade「随轮回清理」的经济分层不同轴，会让「新轮回是干净重置」不再为真。
  - **表达「关系」的既有通道更贴合本作形态**：`PlotArcData` + `PlotKeyPoint`（每条已激活 arc 一条带 `State` 的锚点）天然就是「与某人 / 某势力的一段关系走到哪一步」，`pastEvent` 则直接读得出「见过谁、跟谁做过交易」。**好感度本质上就是一条 arc 的进度**，只是用离散节点而非连续数值表达——恰与「给方向不给数字」同向。
- **「势力」= 三个既有字段的组合，零新增**：`PlotArcData.ExclusiveGroup`（投靠了甲就进不了乙的线）· `PlotModulation.EventWhitelist` / `EventWeights`（该势力的事件更常出现）· location 的事件类型出现概率修正（坊市多 Exchange）。
- **NPC 唯一需要新写的东西是一条内容编排约定**：`Id` 前缀承载身份（`event.exchange.npc.<npc_slug>.<n>`），同一 NPC 的多个条目共用 slug。**不加字段、不加校验**——不给字段就不存在「谁有权用它」的问题。
- **社交型产出触发 AdventurePlot 分支已经成立**，三条通道现成：`PlotCondition.Kind = EventResolved` · PlotManager 读 `pastEvent`（`Op == Grant` 且 `Source == ExchangePurchase` 的 element）· `PlotEdge.BranchLabel` + `ChooseBranch`。**明确不做两件事**：不为「买了什么」新增 `PlotCondition.Kind` 成员（`pastEvent` 已读得出，新增 = 第二条判定路径）· 不动 `EventOutcome` 四值枚举（枚举增删牵动存档迁移，且 Exchange 的一切走向都落在 `Resolved`）。

### ⑩ 道具定义 vs 交易机制：把结论换成判据

> **「这条信息在游戏里没有商店时是否仍然存在？」** 仍然存在 → 归道具侧；不存在 → 归 Exchange 侧。

- **第一条硬推论：`ItemData` 上不加 `Price`，也不加 `Purchasable`。** 价格在没有商店时不存在 ⇒ 归定价表；把 `Price` 写进 `ItemData` 会制造第二权威（表与条目各自漂移，而本库无机制发现）。「能不能买」已由 `ExclusiveSource != null` 不进任何抽取池免费给出——库存抽取也是抽取 ⇒ 成就限定条目天然不进商店。
- **两处重复登记收口为一条**：判据本体写在 `exchange/_index.md`（机制侧是提问方），`player-item/_index.md` 只留一句 + 回链。**回链而非复述。**
- **措辞修正**：`exchange/_index.md` 原写「可购道具的定义归属 `player-profile`」会误导——商店主要售卖的是轮回级的法宝 / 神通 / 功法 / 卡牌，改为「商品的**内容定义**一律归各自的内容子树，Exchange 只承载交易机制」并列出五族各自的定义位置。

### 落地面

| # | 落点 | 改动 |
|---|---|---|
| 1 | `exchange/_index.md` | 结算形态 · 库存 / 定价 / 折扣 / 刷新 / 售出 · NPC 结论 · 切分判据 · 措辞修正 |
| 2 | `exchange/common-properties.md` | `ExchangeSpec` / `ExchangeStockRule` / `ExchangeOffer` / `ExchangeGoodsKind` 字段表 + 加载期与运行期校验 |
| 3 | `adventure-event/common-properties.md` | 事务纪律改写；`AppliedChange` = 本次事件的最终账 + 代价明写 |
| 4 | `profile-service.md` | 同一条纪律改写 + 即时提交条目；`Jade` 行理由句；`ExchangeSell` 校验行；移出 `Jade.CostModifier` 待答项 |
| 5 | `life-cycle-service.md` | 逐笔已提交 spec 累加进 `AppliedChange`（记账不施加）；引用旧措辞的两句同改 |
| 6 | `future-event-service.md` | Exchange 库存物化段（`Shop` 子流）；`EventOption` 骨架九字段 → **十一字段** |
| 7 | `architecture.md` | `EventOption` +2 字段；`ModifierKey` 增 `ShopPrice` |
| 8 | `common-properties.md` | `Source` 增 `ExchangeSell`（code 8）+ 合法子集表一行 + 校验口径；bump schema |
| 9 | `plot-manager.md` | NPC / 势力由三个既有字段承载，零新增 |
| 10 | `currency.md` | jade 的消耗点至此有形态（获取渠道仍待定） |
| 11 | `character-profile/item/_index.md` | 9 格取舍位在可售出后的语义变化，明写接受 |
| 12 | `player-item/_index.md` | 切分待答项收口为一句 + 回链 |
| 13 | `character-profile/deck/_index.md` | 商店购买功法 = `LearnTechnique`；散牌入组的 element 载体缺口登记 |
| 14 | `balance.md` | 「族 × 稀有度」定价表形态 · 刷新价参数 · 回收率 · 槽位总数上界 ≤ 8 |
| 15 | `combat-service.md` · `character-profile/_index.md` | 引用旧事务措辞的三句同改（含「战斗内即时写入是同一条纪律的另一半，不是例外」） |
| 16 | `ux/screen-flow.md` | 交易屏（竖屏 · 触控 · 灰显保留价格 · 售罄占位 · 刷新按钮 · 离开收口） |

**存档 schema：** `EventOption` 增两个物化字段 + `Source` 增一个成员 ⇒ **bump 一次**，当前无线上存档 ⇒ **空迁移**，走既有 MigrationManager 骨架。
**不受影响：** `PastEventEntry` 的字段表（除 `AppliedChange` 语义放宽外）· `EventOutcome` 四值 · `PlotModulation` 六字段 · 三个隐藏属性与 12 档档位表 · `ResourceElements` 表的任何一格 · `ProfileChangeSpec` 的各列（不增列）。
**对后端库零影响**（复核见下）。

## Clarifications（评审裁决）

草稿以 `status: decided` 进入本次提炼，三项取向 + 两条全局纪律改写均已由用户裁决：

1. **是否开放玩家侧售出** → **仅 `CharacterItem` 一族可售出**（**推翻原推荐**「完全不开放」）。代价按定案如实落笔：储物袋 9 格从纯取舍位变成可换 jade 的位置。
2. **是否开放刷新 reroll** → **机制落地、首批内容默认关闭**（与推荐一致）。
3. **jade 能否购买账号级古宝** → **不铺开**；合法子集表 `ExchangePurchase × (Item, Player)` 那一格**不动**，规则层保持开放，只是首批内容不编排（与推荐一致）。
4. **事务纪律的措辞** → **改写为准确形态**，且**适用面不限 Exchange**；两处承载点必须同改。
5. **`AppliedChange` 语义** → **放宽为「本次事件的最终账」**，逐笔已提交的 spec 由 life-cycle-service 累加进去；**代价须一并写进文档、不得省略**。
6. **两项轻量确认一并落笔**：新增 `Source.ExchangeSell` · 槽位总数上界 ≤ 8（具体数字归 balance）。

**跨库复核（本次独立执行，结论与草稿自判一致：不跨库）：** `Source.ExchangeSell` 只落在 `(Item, Character)` = 法宝 = 轮回级持有条目上，而 `backend-design-documents/contracts/profile-sync.md` §5 把 `characterDiffs` **整体划为不透明段**（后端不递归、不比对、不校验），透明路径只有 `/playerPowers[*]/sourceCode` 一条且用于 `x = count("FinaleWin")` 的复算——新成员对它零可见，`x` 不受影响。`AppliedChange` 同样落在 `characterProfile` 内、属不透明段，后端明写**不重放 `AppliedChange`**。故本次**不写对侧库、不产生跨边界承接项**；既有的那条预警（资源字段一旦提进透明档须同批把语义写进契约）**适用面因本次而变宽**，已在 `open-questions/cross-boundary.md` 的基线段补一句。

**顺带发现的既有缺口（不由本次答结，登记为待答）：** `DeckChangeOp` 只有 `RemoveLooseCard` 没有增向，故**游离散牌入组没有 element 载体**——它同时卡住 Exchange 的 `Card` 族购买、战斗奖励的单卡入组、以及事件负向奖励塞业障三条既有通道。这是 Research 专场排除 `AddLooseCard` 时留下的缺口，不是 Exchange 制造的。

## Open questions

- **游离散牌入组的 element 载体未定（承重 · 本次新增）。** 见上。→ `systems/character-profile/deck/_index.md`、`systems/services/profile-service.md`。
- **结算进行中的 `EventOption` 派生实例如何落存档。** reroll 重掷后的库存与 `RerolledCount` 必须在玩家可退出之前落盘，而 `EventOption` 是「产出即定稿、不得改写其字段」的 immutable 实例；`with` 派生出的新实例是否替换当前批中的原实例、还是另有承载，本库尚未指定。**它与 Explore 的 `IsRevealed` 是同一个缺口**（该字段保留的理由正是「退出重进后呈现层需要判断这一步已揭示过」）。→ `systems/services/future-event-service.md`、`systems/adventure-event/common-properties.md`。
- **定价表每格填多少 · 刷新基价与递增量 · 回收率 · 槽位总数上界的具体值。** 形态均已定，只欠取值，**归 ch1 数值标杆专场**；且**定价表的绝对数字在 jade 获取渠道答定前无法反推**。
- **jade 的获取渠道与掉落权重**仍未设计（消耗侧至此有形态）。→ `systems/character-profile/currency.md`。
- **储物袋满袋处理**（承重）仍未定 ⇒「满袋时能否购买道具」无法定稿：拒收 / 强制择一丢弃 / 库存侧过滤三种处置给出三套不同的购买前置校验，它同时决定商店库存深度是否需要同步下调。→ `systems/character-profile/item/_index.md`。
- **是否为「购买次数」设一个 `StatKey` 成员。** 不统计则本方案零依赖；统计则挂在「`StatKey` 完整成员清单」那条待答项上。

## Notes / triage

- 输入：`inbox/solution-draft-exchange-mechanics.md`（`status: decided`），已归档进 `inbox/archive/`。
- 本次答结并移出 4 条待答项，见 `answer-logs/log-exchange-mechanics.md`。
- 本次是同日第四场专场。Travel / Research / Explore 三场已把 `EventOption` 骨架推到九字段、`ProfileChangeSpec` 推到逐条按施加语义分列的五列；本次**只加两个物化字段，不增 spec 列**。
