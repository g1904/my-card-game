# Answer log lifespan-gain-paths

- 日期：2026-08-17
- 来源：`inbox/solution-draft-lifespan-gain-paths.md`（`status: decided`）→ `handoffs/2026-08-17f-lifespan-restoration-paths.md`
- 移出条数：**1**

---

**非境界突破的寿元增长途径。是否存在（回寿类事件产出）未定。**（原 `open-questions/04-hidden-attributes-plot.md`）
→ **存在。** 三条获取通道共用一条施加路径 `ChangeElement(CostKey.LifeSpan, +n)`：① 回寿事件的 outcome 侧产出（并入 `eventEnd` 那一次合并 `TryApply`）· ② 补天丹一类的法宝（`Scope = Character` · `UsableScene = OutOfCombat` · `Charges` 有限，使用时即时提交）· ③ 商店购入 ②（`ExchangeGoodsKind.CharacterItem` 一族的普通商品，走既有购买路径与「族 × 稀有度」定价表）。**零结构增量：不新增字段、不新增 element、不 bump 存档 schema。**

同时定下的五条承重口径：

- **回寿只走 outcome 侧**，`selectCost` 内的 `LifeSpan` 取值域收紧为非负（内容侧表值 / 覆盖值 ≥ 0，物化后 `BaseValue ≤ 0`）。**这改写了三处现有文本**（`systems/adventure-event/common-properties.md` 两处、`systems/balance.md` 一处原写「内容条目可标产出向（回寿）的覆盖值」）。落为两条 `PushError`（内容模板加载期 + 物化组装后断言）。**代价：** 内容作者少一个书写位。
- **回寿的数字与 `selectCost` 同一个开关**：Band 0 / Band 1 只给定性文案，Band 2 才给精确 `+n`；适用于 eventOption 收益标注、道具描述、结算面板寿元行三处。它是寿元档位表的**第六个消费方**。
- **回寿量的标定口径 = 占本章 `ChapterLifeSpanBudget` 的百分比**，三档 5% / 10% / 20%，中档 10% 使「濒死时一颗丹恰好拉回一档」成立（经回滞 δ = 3 个百分点校验：Band 1 退出阈值 13% < 15%）。绝对点数归 ch1 数值标杆专场。
- **不设每篇章回寿总量硬上限**，靠三道软闸（回寿事件照常付 `selectCost` · 占 `eventCountLimit` 配额 · 补天丹占储物袋一格）+ 一条结构性禁令（**Travel 条目不得带回寿产出**——它不计入配额，占配额那道闸对它整条失效）。
- **回寿源的三条准入边界**（均为加载期 `PushError`）：`PowerData` 两个 `Scope` 皆不得含 `LifeSpan` 产出（它没有 `Charges` ⇒ 无次数上限的回寿源）· `ItemData.Scope == Player` 不得含（付费续命的软形态）· 含寿元产出者 `UsableScene` 不得含 `InCombat`（战斗内没有寿元结算通道）。`LifeSpan.GainModifier` 保持 `null`，故法则也不能放大回寿。

**归档去向：** `systems/adventure-event/common-properties.md`（通道 / 取值域收紧 / 展示门控 / 平衡护栏，权威）· `systems/balance.md`（回寿量三档表与标定口径）· `systems/character-profile/item/_index.md`（法宝形态与两条校验）· `systems/character-profile/power/_index.md`（`PowerData` 禁令）· `systems/services/profile-service.md`（`GainModifier` 理由 + 失败语义表一行）· `systems/services/plot-manager.md`（档位表第六个消费方）· `systems/monetization.md`（付费续命排除项的连带）· `systems/adventure-event/travel/_index.md`（Travel 禁令）· `systems/adventure-event/exchange/_index.md`（通道 C 的落点）· `ux/screen-flow.md`（呈现）。

**未随本次答定、仍留在待答清单的部分：** 回寿量三档的**绝对点数**（归 ch1 数值标杆专场，`systems/balance.md`）；**战斗外道具的使用入口**（本次**新增**的待答项，落 `open-questions/03-adventure-event-types.md`，它阻塞回寿法宝的定稿）。
