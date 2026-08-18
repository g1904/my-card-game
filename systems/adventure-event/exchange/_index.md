# adventure-event / exchange（AdventureEvent-Exchange）

> 交易：**以资源换取 card / cultivationTechnique / item / power**，含与 NPC / 势力打交道的社交语境。本子类型只承载**交易机制**；商品的内容定义一律归各自的内容子树（见「对应 / 边界」）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 定位与结算形态

- **交易（Exchange）= 玩家以资源换取 card / cultivationTechnique / item / power。** 一种非战斗 AdventureEvent 子类型，走事件式结算。
- **Exchange 吸收社交语境。** 与 NPC / 势力的社交互动**不单列为一类**：「与 NPC 谈条件」与「在商店买东西」共有同一套事件式结算形状与呈现形状，分成两类只是在内容风味上切一刀，而**风味不需要枚举值来承载**。因此坊市商贾、同门师长、宗门势力一律是 Exchange 条目的不同风味。
- **仍走 `GenericEventResolver`，不为 Exchange 开第三个 resolver（承重）。** resolver 的拆分轴是「有没有状态机」，而 Exchange 没有——没有回合循环、没有跨帧的规则推进、没有需要引擎驱动的阶段机。「浏览 → 买若干件 → 离开」是一串**事件内决策点**，与战后奖励面板、能力置换面板、Research 构筑面板同构，那三处都已明写「不新增机制」。开第三个即打开「每类事件各开一个 resolver」的滑坡。
- **每一笔交易即时提交一次 `TryApply`，不攒到 `eventEnd`（承重）。** 这是「一个事件的收口是一次事务、一个存档点；**事件内部的主动消费即时提交**」这条全局纪律在 Exchange 上的落地（纪律本体见 `systems/adventure-event/common-properties.md` 与 `systems/services/profile-service.md`）。三条理由：
  - **`CanAfford` 的正确性要求余额是真的。** 买第二件时的灰显判据必须读**扣掉第一件之后**的 jade；攒到收口就要维护一份「已扣未提交」的影子余额，而它与 `Evaluate(spec)` 是两条路径——正是「`CanAfford` 与 `TryApply` 必须走同一条 pipeline」要防的分裂。
  - **它堵死「买完退出重进拿回灵玉」**，与古宝使用次数即时写入是同一条理由。
  - **一笔交易本身就是自足事务**（`-jade` + 一条产出），「全有或全无」在这一笔内已闭合，不需要跨笔原子性。
  - **接受的代价（明写）：** 中途退出的玩家停在「已买两件、第三件没买」的状态。**这正是玩家的真实意图**，不是半成品状态。
  - **不新增存档点类型。** 每笔提交是一次 Profile 变更，走既有「变更后由 sync-service 上行」通道，与战斗内即时写入同形；`eventEnd` 的自动存档点照常。
- **一笔交易的 spec 形状：** `Elements` 一条 `ChangeElement(Jade, -ListPrice, Add)` + 该商品族对应的产出 element——道具 / 神通走 `AbilityElements` 的 `Grant`（携带 `Source.ExchangePurchase`），功法走 `DeckElements` 的 `LearnTechnique`，单卡走 `DeckElements` 的 `AddLooseCard`（`Tier = -1`，一条 element 一张）。逐族载体见 `common-properties.md`。
- **`ResolveOutcome` 只带账，不带第二次施加。** resolver 在玩家点「离开」时收口，`ResolveOutcome` 携带 ① 本次已提交的交易清单（**记账用，不再施加**）② 非购买 outcome / effect（对话结果、赠礼、隐藏属性推拉）。②照常并入 `eventEnd` 那一次合并 `TryApply`；①由 life-cycle-service 累加进 `PastEventEntry.AppliedChange`。
- **商店购买是「余额不足即拒」的唯一消费点。** 事件推进路径不做付得起校验（`selectCost` 无条件施加），主动消费则相反：买不起的商品**灰显并保留价格可见**，不产生一次注定失败的提交。所需的两样东西——`ProfileService.CanAfford(spec)` 与 `ApplyResult.MissingElement`（告诉 UI 差的是哪一样）——因此保留。
  - **判据（写下判据而非结论）：「明知做不到仍然去做」有没有意义。** 事件选择面有意义（明知是死路仍然走，与「打不过也得打」同构，且换来一段终局叙事），故不设不可选 / 置灰态；商店里点一件买不起的商品**没有任何意义**——不产生终态、不产生叙事、不推进任何东西，只产生一次挫败。两处不同处置出自同一条判据，不是双标；「事件面不灰显」不得被推广到商店。
  - 灰显 / 售罄 / 刷新按钮的呈现形态见 `ux/screen-flow.md`。

### 库存生成

- **库存在 future-event-service 物化时掷定，随 `EventOption` 落存档。** 用既有的 **`RngStream.Shop` 子流**，经 `AllEnabled()` 取池。依据是三条已定纪律的直接推论：唯一物化点 · 产出即定稿且消费侧不得回查模板重算 · **物化产出的数值必进快照**（库存由 seeded RNG + 当时角色状态决定，重算不保证同结果）。物化伪码见 `systems/services/future-event-service.md`。
- **商品族取值域 = 已存在的抽取池，不新建任何池。** `ExchangeGoodsKind` 五值一一映射到既有仓储；**法则 `(Power, Player)` 不在族内**——`Source` 合法子集表对它是 ❌，规则层本就不允许 `ExchangePurchase` 落到法则上。族的定义与取池链见 `common-properties.md`。
- **同一批库存内不出现重复商品，这条免费成立**：`PickMany` 无放回是既定契约，不需要新规则。
- **买完即售罄，同一 offer 不可重复购买。** 不设售罄，一个高价值 offer 会把 jade 全部单点吸走，库存槽位失去意义。

### 定价与折扣

- **定价归属 = `systems/balance.md` 的一张「商品族 × 稀有度」定价表，不逐条目手写。** 与 `lifeSpanCost` 的「事件类型 × 篇章」定价表完全同构：**内容条目默认不填、取表值**，需要体现风味差异时在 `ExchangeStockRule.PriceOffset` 上标偏移。理由逐条对应：改一张表即可全局调经济、不必重扫数百个 `.tres`、避免同类商品在不同作者手里定价漂移。**不设篇章维**——jade 随轮回清理、每章重置，与寿元的跨篇章结转不同，篇章差异应由「掉落多少 jade」承载而非「同一件东西涨价」。
- **折扣通道一 = `ModifierKey.ShopPrice`（PlayerPower 的具名 modifier）。** 它**在物化时施加、写入 `ExchangeOffer.ListPrice`**，因此**不进 `ResourceElements` 表**：「一个 `ModifierKey` 只能有一个施加点」，而商店价格必须先算才能标价 ⇒ 施加点在物化 / 展示侧。
- **折扣通道二 = `ExchangeStockRule.DiscountPercent`（内容侧静态折扣）。** 用于表达「这位商贾对同门有优待」一类风味；与玩家侧修正来源不同、可叠加。施加顺序：

  ```
  ListPrice = ApplyModifier(ShopPrice, (BasePrice + PriceOffset) × (100 − DiscountPercent) / 100)
  结果 Clamp 到 >= 1
  ```

  **免费商品不由折扣产生**——要免费就走非购买 outcome 的赠礼。
- **`ListPrice` 在物化时定稿，代价明写。** 轮回中途新获得的降价修正（唯一现实路径 = 中途购买 premium bundle）**不影响已定稿的库存**，下一个 Exchange 事件才生效。理由与「产出即定稿、不得回查模板重算」一致；反例（展示时现算）会让同一个 offer 在两次进入之间变价，且违反「重算不保证同结果 ⇒ 必进快照」。

### 刷新（reroll）

- **形态**：花 jade 重掷整批库存，价格 `RerollBaseCost + RerollCostStep × 已刷新次数`，上限 `MaxRerollCount`；掷定走 `Shop` 子流。**重掷结果即时落存档**——与「候选必须预先算定并落决策点存档，否则退出重进可以重掷」同一条纪律，这是 reroll 能存在的前提。
- **支付走购买同一条路径**（`-jade` 的即时 `TryApply`），不新增机制。
- **刷新价与新库存必须落在同一次 `TryApply`（承重）。**

  ```
  TryApply( Elements[ChangeElement(Jade, -刷新价, Add)]
          + EventStateChanges[ActiveEvent = option with { ExchangeStock = 新一批, RerolledCount = 前值 + 1 }] )
  ```

  两个方向的破裂各是一个可利用的漏洞：**只落 `-jade`、库存未落** ⇒ 退出重进看到旧库存，同一笔钱可再刷一次（正是防重掷纪律封死的那个窗口）；**只落库存、`-jade` 未落** ⇒ 免费刷新。这一笔是「事件内主动消费即时提交」的第四个实例：本地立即原子写，push 走 `Debounced`，**不计软阻塞闸门**（闸门只数事件级存档点，连按刷新不会弹模态）。派生实例的承载与七条读档校验见 `systems/character-profile/_index.md`。
- **消耗了 `Shop` 子流的随机 ⇒ 该子流的 `State` / `DrawCount` 必须在同一次原子写内更新**（不变式，见 `systems/services/life-cycle-service.md`）。`State` 落了库存没落 ⇒ 再刷一次得到不同结果，等于一条重掷通道；库存落了 `State` 没落 ⇒ 下一次从同一 `State` 起掷、重复同一批结果。
- **恢复即读结果：** 退出重进后读 `activeEvent.Option.ExchangeStock` 直接呈现，**绝不重走取池链**。
- **首批内容默认关闭**（`RerollBaseCost = 0` / `MaxRerollCount = 0`）：机制先落地、数据先留空是本库既有偏好。

### 售出

- **仅 `CharacterItem`（法宝）一族可售出，且这是一条代码级常量判据（承重）。**

  ```
  可售出 ⟺ 该持有物的 ExchangeGoodsKind == CharacterItem
  ```

  其余四族（`Card` · `CultivationTechnique` · `CharacterPower` · `PlayerItem`）**恒不可售**。**写成常量而非内容可配的族白名单**：内容侧若能逐条目开族，一个填错的条目就打开一条本该封死的通道，而**校验无从判断作者是不是故意的**；钉在代码里，误开在编译期就不存在。
- **条目侧保留两个字段**：`SellEnabled`（该商店是否收购，让「只卖不收」的商店可编排）与 `SellRatePercent`（回收率旋钮，数值归 ch1 数值标杆专场）。
- **`SellRatePercent` 折算基准取「族 × 稀有度」定价表的基准价，不取 `ListPrice`。** 后者已含 `ShopPrice` modifier 与 `DiscountPercent`，按它折算会让「在打折商店卖东西更亏」，玩家读不出因果；按基准价折算则与买价折扣完全解耦。
- **回收率显著低于标价**（建议落在 30–50%，具体归 ch1 标杆）。摩擦保住取舍感：卖仍是亏，只是比丢掉强。
- **代价明写：储物袋 9 格从纯取舍位变成一个可换 jade 的位置。** 9 格被明写为「真正会咬人的构筑取舍位，不是溢出防护」；能卖之后，满袋从「必须放弃一件」变成「换成 jade」。**这是被接受的设计取向**，缓解手段只有上面两个旋钮（低回收率 + 按基准价折算），不再加规则。见 `systems/character-profile/item/_index.md`。
- **售出即时提交**，与购买同一条路径。
- **售出走 `Source.ExchangeSell`，与买入侧的 `ExchangePurchase` 分立。** `Source` 的既定职责是「这件东西怎么来的 / 怎么没的」，买与卖在履历、成就与诊断上是两件事；复用会让「购买次数」这类统计永远算不准。它是本子类型唯一的枚举增量，合法子集表只对 `(Item, Character)` 开放，见 `systems/common-properties.md`。

### NPC / 势力：风味层，不建数据模型

- **不新建 `NpcData` / `FactionData`，不设好感 / 关系度数值，不跨轮回留存。** 四条依据：
  - **风味不需要一套数据模型来承载**（`decisions/ADR-0002-adventure-event-taxonomy.md` 的判据原样延伸到字段）。NPC 若只影响文案与插图，它就是 `Id` 命名约定 + `LocalizedText` + 图标字段，已经全部就位。
  - **好感 / 关系度若有持久数值，它就是第四个隐藏属性。** 档位表已定为三属性 12 档且明写「档数永远不是该动的旋钮」；加一条要连带新增 `CharacterProfile.Status` 的 band 字段、一套档位数据、回滞 δ、加载期校验与 `HiddenStat` 枚举成员（存档迁移）。代价与收益完全不成比例。
  - **跨轮回留存撞既有分层。** 账号级持久数据归 `PlayerProfile`（其字段结构本身仍是待答项），且它与 jade「随轮回存在、随轮回清理」的经济分层不同轴——一个跨轮回的社交数值会让「新轮回是干净重置」不再为真。
  - **表达「关系」的既有通道更贴合本作形态。** `PlotArcData` + `PlotKeyPoint`（每条已激活 arc 一条带 `State` 的锚点）天然就是「与某人 / 某势力的一段关系走到哪一步」；`pastEvent` 是 PlotManager 的只读输入，「见过谁、跟谁做过交易」直接读得出。**好感度本质上就是一条 arc 的进度**，只是用离散节点而非连续数值表达——恰与「给方向不给数字」同向。
- **「势力」的承载 = 三个既有字段的组合，零新增：** `PlotArcData.ExclusiveGroup`（同组 arc 一次轮回内至多激活一条 ⇒「投靠了甲就进不了乙的线」）· `PlotModulation.EventWhitelist` / `EventWeights`（该势力的事件更常出现）· location 的事件类型出现概率修正（坊市多 Exchange）。见 `systems/services/plot-manager.md`。
- **NPC 唯一需要新写的东西是一条内容编排约定：** `Id` 前缀承载 NPC 身份（形如 `event.exchange.npc.<npc_slug>.<n>`），同一 NPC 的多个事件条目共用 slug。**不加字段、不加校验**——不给字段就不存在「谁有权用它」的问题。
- **社交型产出触发 AdventurePlot 分支已经成立，不需要新机制。** 三条通道现成：

  | 想表达的 | 既有承载 |
  |---|---|
  | 「与某 NPC 完成过某次交易」推进剧本 | `PlotCondition.Kind = EventResolved`（参数 `EventId` / `EventType` / `EventOutcome`） |
  | 「买下了某件东西」推进剧本 | PlotManager 读 `pastEvent`：`AppliedChange` 里有 `Op == Grant` 且 `Source == ExchangePurchase` 的 element |
  | DnD 式显式选择（答应 / 拒绝某人的条件） | `PlotEdge.BranchLabel` 非空 + `ChooseBranch(branchId)` |

  **明确不做的两件事：** ① **不为「买了什么」新增 `PlotCondition.Kind` 成员**——`pastEvent` 已经读得出，新增等于制造第二条判定路径；② **不动 `EventOutcome` 四值枚举**——枚举成员的增删牵动存档迁移，且 Exchange 的一切走向都落在 `Resolved` 上。

### 道具定义 vs 交易机制：判据

> **「这条信息在游戏里没有商店时是否仍然存在？」** 仍然存在 → 归道具侧；不存在 → 归 Exchange 侧。

| 归内容侧（各自的内容子树） | 归 Exchange 侧 |
|---|---|
| `Id` · `Scope` · `UsableScene` · `ManaCost` · `Charges` · `Abilities` · `Rarity` · `Subtypes` · 折价系数 `itemPowerRatio` | 库存槽位规则 · 标价 / 折扣 / 刷新 / 售出 · `ExchangeOffer` · 购买 / 售出流程与 `Source.ExchangePurchase` / `Source.ExchangeSell` |

- **第一条硬推论：`ItemData` 上不加 `Price`，也不加 `Purchasable`。**
  - **价格**在没有商店时不存在 ⇒ 归定价表。把 `Price` 写进 `ItemData` 会制造第二权威：表与条目各自漂移，而本库无机制发现。
  - **「能不能买」**已由既有字段免费给出：`ExclusiveSource != null` 的条目不进任何抽取池，而库存抽取也是抽取 ⇒ **成就限定条目天然不会出现在商店里**，不需要第二个布尔。
- **回寿法宝（补天丹一类）是 `CharacterItem` 族的一个普通商品，零机制增量。** 它使商店成为「灵玉 → 寿元」的一条兑换通道，但**不需要任何新接口**：库存抽取、定价（「族 × 稀有度」表的 `CharacterItem` 行）、购买 spec（`ChangeElement(Jade, -ListPrice)` + `AbilityChangeElement(Grant, Item, Character, id, Source.ExchangePurchase)`）全部照既有路径走。**账号级古宝 `PlayerItem` 一族被结构性排除在这条通道之外**——含寿元产出的 `ItemData.Scope == Player` 在加载期即 `PushError`，见 `systems/character-profile/item/_index.md`。回寿通道的完整形态与平衡护栏见 `systems/adventure-event/common-properties.md`。
- **商品的内容定义一律归各自的内容子树，Exchange 只承载交易机制。** 五个商品族的定义位置：`Card` → `systems/character-profile/deck/`；`CultivationTechnique` → 同上；`CharacterItem` → `systems/character-profile/item/`；`CharacterPower` → `systems/character-profile/power/`；`PlayerItem` → `systems/player-profile/player-item/`。

Source: `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Exchange 为五类分类法之一，社交语境并入其中** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **交易逐笔即时提交；收口才是一次事务、一个存档点** → **ADR 候选**（它是一条全局纪律的改写，适用面不限 Exchange）。
- **仅 `CharacterItem` 一族可售出，准入为代码级常量判据。**
- **定价走「商品族 × 稀有度」统一表；`ItemData` 不加 `Price` / `Purchasable`。**
- **NPC / 势力为风味层，不建数据模型。**

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **定价表每格填多少 · 刷新基价与递增量 · 回收率 · 槽位总数上界的取值。** 形态均已定，归 **ch1 数值标杆专场**；且**绝对数字在 jade 的获取渠道答定前无法反推**。→ `systems/balance.md`、`systems/character-profile/currency.md`。
- **满袋时能否购买道具。** 阻于「储物袋满袋处理」那条待答项——拒收 / 强制择一丢弃 / 库存侧过滤三种处置会给出三套不同的购买前置校验，它同时决定商店库存深度是否需要同步下调。→ `systems/character-profile/item/_index.md`。
- **是否为「购买次数」设一个 `StatKey` 成员。** 不统计则零依赖。→ `systems/services/profile-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/exchange.md`（待建）
商品的内容定义见各内容子树（见上方判据表），本处不重复。
