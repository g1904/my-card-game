# Answer log exchange-mechanics

- 日期：2026-08-17
- 来源：`inbox/solution-draft-exchange-mechanics.md`（`status: decided`）→ `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md`
- 移出条数：4（下方第 2 段「售出机制是否开放」是第 1 条内部的取向子项，单列只为便于检索，不另计一条）

---

**Exchange 通用结算器的数据形态（库存生成 / 定价 / 折扣 / 刷新 / 售出）** → **整段收口，且不新增 resolver。** 仍走 `GenericEventResolver`（拆分轴是「有没有状态机」，Exchange 没有）；交易**逐笔即时提交**一次 `TryApply`，`ResolveOutcome` 只带账不带第二次施加。库存在 future-event-service 物化时经既有 `RngStream.Shop` 子流掷定、随 `EventOption` 落存档，五个商品族一一映射到既有仓储、**不新建任何抽取池**；模板侧载体 `ExchangeSpec` / `ExchangeStockRule`，定稿实例 `ExchangeOffer`。定价走 `systems/balance.md` 的「商品族 × 稀有度」统一表 + 两条折扣通道（`ModifierKey.ShopPrice` 在物化侧施加 · 内容侧 `DiscountPercent`），`ListPrice` 物化时定稿。刷新机制落地但首批内容默认关闭。`EventOption` 骨架九字段 → 十一字段（`ExchangeStock` / `RerolledCount`），bump 一次存档 schema（当前无线上存档 ⇒ 空迁移）。（归档去向：`systems/adventure-event/exchange/_index.md`、`systems/adventure-event/exchange/common-properties.md`、`systems/services/future-event-service.md`、`systems/architecture.md`、`systems/balance.md`、`ux/screen-flow.md`）

**售出机制是否开放** → **开放，但仅 `CharacterItem`（法宝）一族，准入为代码级常量判据**（不做成内容可配的族白名单——内容侧若能逐条目开族，一个填错的条目就打开一条本该封死的通道，而校验无从判断作者是不是故意的）。条目侧保留 `SellEnabled` / `SellRatePercent`；回收率折算基准取定价表基准价而非 `ListPrice`。连带新增 `Source.ExchangeSell`（code 8，清单里唯一只出现在 `Op == Remove` 上的成员，合法子集表只对 `(Item, Character)` 开 ✅）。**代价如实记入文档：储物袋 9 格从纯取舍位变成一个可换灵玉的位置**，缓解只靠回收率（30–50%）与折算基准两个旋钮。（归档去向：`systems/adventure-event/exchange/_index.md`、`systems/common-properties.md`、`systems/character-profile/item/_index.md`）

**NPC / 势力模型是否仍需要（含社交型产出是否触发 AdventurePlot 分支）** → **降级为风味层，不建数据模型。** 不新建 `NpcData` / `FactionData`、不设好感 / 关系度数值、不跨轮回留存——好感度若有持久数值它就是第四个隐藏属性（牵动 12 档档位表、`Status` 字段、`HiddenStat` 枚举迁移），而 `PlotArcData` + `PlotKeyPoint` 本来就是「与某人 / 某势力的关系走到哪一步」的离散表达。「势力」由三个既有字段组合承载（`ExclusiveGroup` · `EventWhitelist` / `EventWeights` · location 的类型修正），零新增。NPC 唯一新写的是一条 `Id` 前缀编排约定，不加字段、不加校验。**社交型产出触发剧本分支已经成立**（`PlotCondition.Kind = EventResolved` · 读 `pastEvent` · `PlotEdge.BranchLabel`），明确不新增 `PlotCondition.Kind` 成员、不动 `EventOutcome` 四值枚举。（归档去向：`systems/adventure-event/exchange/_index.md`、`systems/services/plot-manager.md`）

**道具定义与交易机制的切分是否够清晰（两处重复登记）** → **维持现切分，但把结论换成判据**：「这条信息在游戏里没有商店时是否仍然存在？」仍然存在 → 归道具侧；不存在 → 归 Exchange 侧。硬推论：**`ItemData` 上不加 `Price`，也不加 `Purchasable`**（前者会制造第二权威，后者已由 `ExclusiveSource != null` 不进任何抽取池免费给出）。两处重复登记收口为一条：判据本体写在 `exchange/_index.md`，`player-item/_index.md` 只留一句 + 回链。同时修掉一处误导措辞——商店主要售卖的是轮回级的法宝 / 神通 / 功法 / 卡牌，故改为「商品的内容定义一律归各自的内容子树」。（归档去向：`systems/adventure-event/exchange/_index.md`、`systems/player-profile/player-item/_index.md`）

**`Jade` 的 `CostModifier` 取值** → **恒为 `null`，不再是待答项。** 价格在**物化 / 展示侧**修正、`ListPrice` 定稿后才进 `TryApply`；改填会打两次折（`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)`，传入的 `BaseValue` 已是修正后的标价 ⇒ 玩家看到 80、实扣 64，灰显判据一并偏移），正是「一个 `ModifierKey` 只能有一个施加点」要防的坏状态。连带 `ModifierKey` 增成员 `ShopPrice`——它在枚举里、不在 `ResourceElements` 表里，完全合法。**本条在 `profile-service.md` 与 `open-questions/03` 两处同名登记，一并移出。**（归档去向：`systems/services/profile-service.md`、`systems/architecture.md`、`systems/character-profile/currency.md`）
