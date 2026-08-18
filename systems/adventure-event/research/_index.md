# adventure-event / research（AdventureEvent-Research）

> 闭关：玩家**调整 / 升阶自己的卡组**。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **闭关（Research）= 玩家调整 / 升阶自己的卡组。** 一种非战斗 AdventureEvent 子类型，走事件式结算；语义上是角色静修钻研，机制上是**轮回内构筑的落点**——升阶 / 弃置 / 学新功法都发生在这里。见 `systems/character-profile/deck/_index.md`。
- **开局那个强制的构筑事件归 Research。** 起始批次中**必有一个强制事件**，让玩家选**一门功法**与**一件法宝**（各三选一）——形态取 Slay the Spire 第一章的味道。它是 Research 的一个条目，**不需要第六类**；承载机制是既有的 `eventPriority = 1`（本批有效可选集收窄为该档），**不新增机制**。**推论：Research 既定起手形状（开局），也承担整个轮回的多轮构筑（途中）**——两者是同一类事件的两种编排。
- **Research 不可被 Explore 遮罩。** 卡组编辑是玩家主动规划的动作，把它藏在未知后面只制造挫败，不制造张力。见 `../explore/_index.md`。
- **不单列「休养 / Rest」。** 休养语义并入 战斗 或 闭关——闭关承担其中的静养 / 修整语义。见 `systems/adventure-event/_index.md`、`terminology.md`。
- **闭关比常规事件耗时更长。** 这是寿元定价上的一条既定差异：定价表里 Research 的 `lifeSpanCost` 高于常规事件。表的形态与取值归 `systems/balance.md`。

### 结算形态 = 构筑面板，由若干决策槽组成（承重）

**模板持有 N 个决策槽（slot）；物化时为每个槽预先掷定一组候选操作；结算时玩家逐槽择一，全部选择与 `lifeSpanCost` 合并为 `eventEnd` 的一次 `TryApply`。** Research 走 `GenericEventResolver`，resolver 只描述结果、不自行写档。

- **它不是新机制，是既有决策点面板的第三个实例**（前两个：战后奖励面板、能力置换面板）。「预先掷定候选 + 玩家择一 + 并入 `eventEnd` 那一次 `TryApply`」这套形状零新增结构。
- **槽的复数形态是被开局构筑事件逼出来的，不是为扩展预留。** 开局要求「一门功法 + 一件法宝，各三选一」= 同一事件内的**两个**槽；常态条目填 1 个槽。若只支持单槽，开局事件就必须另设机制，而它已明写「不需要新机制」。
- **它与「一批只有一次操作：择一进入」不冲突**——那条约束的是**批次层**，槽是**事件内部**的结算结构，与战后奖励面板在事件内做一次选择同层。
- **候选掷定的时机 = 物化阶段，随 `EventOption` 落存档。** 依据是「候选必须预先算定并落决策点存档，否则退出重进可以重掷」加上「物化产出的数值必进快照」。**这同时是风险档能够成立的前提**——结果已定、只是尚未展示。字段形态见 `common-properties.md`。

### 操作清单 = 六类，闭合

| 操作 | 语义 | 载体 element |
|---|---|---|
| **`LearnTechnique`** | 学会一门新功法（入组，层数 = 1） | `DeckChangeElement` |
| **`UpgradeTechnique`** | 已持有功法层数 +1（该组牌整组替换） | `DeckChangeElement` |
| **`ForgetTechnique`** | 弃置一门已持有功法（含角色绑定的两门） | `DeckChangeElement` |
| **`RemoveLooseCard`** | 移除一张游离散牌（业障 / 单卡奖励） | `DeckChangeElement` |
| **`GrantItem`** | 获得一件法宝 `CharacterItem` | `AbilityChangeElement(Grant, Item, Character, id, Source.EventOutcome)` |
| **`Recuperate`** | 回复 `lifeTotal` | `ChangeElement(CostKey.LifeTotal, +n)` |

**`manaLimit ±1` 不单列为一种操作**——它是上述操作的**附带产出**（钻研到位则容量提升，走火入魔则容量受损），与「压低只以负向奖励条目的形态出现、不另立结构」一致。

**明确不在清单内的三项：**

- **加一张游离散牌不作为 Research 的正向操作。** 构筑单位是功法，正向的卡组增长走 `LearnTechnique`；单卡入组的既有通道是**战斗奖励与事件负向奖励**，Research 再开一条会让「功法是构筑单位」的颗粒度被单卡稀释。（业障作为 Research 的**负向**结果进卡组不受此限——那走既有的负向奖励条目通道。）
- **领悟法则（`PlayerPower`）不做。** 合法子集表里 `EventOutcome × (Power, Player)` 是 ❌，这是一条现成的机械约束，不是取向问题。
- **授予神通 `CharacterPower` 暂不放进 Research。** 语义上归战斗奖励与 Exchange 更自然；技术上随时可开（合法子集表该格已 ✅），属内容口径而非规则改动。

### 产出面的边界：卡组 + `manaLimit` + `lifeTotal` + 共有的隐藏属性推拉，此外不给

这条收窄使「Research = 调整卡组」不至于被泛化成「万能的正向事件」。

- **允许回复 `lifeTotal`。** 「休养 / Rest 并入闭关」已定，休养并进来了它的产出却没地方去等于并了一半；`life-total.md` 的「恢复途径 = 通过 event 恢复」未限定事件类型。**`Recuperate` 与 `UpgradeTechnique` 在同一决策槽内并列**，正是 StS 篝火（rest / smith）那个玩家真会犹豫的二选一——它给当前纯收益的 Research 一条内部张力。载体是既有的 `ChangeElement`，零新增。
- **隐藏属性推拉照常**：它是五类事件**共有**的通道（`eventEnd` 合并施加 + 跨档定性叙事），不是 Research 的专有产出，Research 侧无需表态。
- **不给灵玉 `Jade` 产出。** 灵玉的长期价值出口已分派给 Exchange，Research 产灵玉会与之抢同一条价值线。

### `manaLimit` 的下降承载点 = Research 的玩家自选风险档

**玩家可以选一个高风险的钻研候选：成功 `manaLimit +1`，失败 `−1`；掷定发生在物化阶段并随 `EventOption` 落存档**（退出重进不改变结果）。

- **叙事轴与 mana 的推拉分档表天然对齐。** Research 已是推高的**主通道**（钻研 / 潜修在叙事上就是提升法力容量），走火入魔是同一条轴的反面，挂同一类型不需要新叙事前提。Explore 是纯元类型、无自己的产出口径，其可揭示的三类都不是走火入魔场景。
- **它补上 Research 唯一缺失的张力。** 没有它，Research 是**纯收益事件**（付寿元、拿构筑，没有任何可能变糟），而闭关的 `lifeSpanCost` 又是全类型最贵一档——一个「最贵且必然赚」的事件会成为批次里的无脑首选，压掉「从一批里择一」的决策价值。
- **「玩家自选」而非「随机惩罚」是关键的一半。** 被系统随机扣上限只会让玩家感到被惩罚，并进而回避 Research——而 Research 是构筑的唯一落点；**自己按下那个按钮**则与「明知是死路仍然走 / 打不过也得打」是同族的取向，风险是被选择的，不是被施加的。
- 载体是 `CostKey.ManaLimit`（`ResourceElements` 该行两个修正列均为 `null`，见 `systems/services/profile-service.md`）。

### 代价：不另收资源代价

**Research 的卡组操作不另收灵玉或其他资源，代价全部由 `lifeSpanCost` 的 Research 行承载**（已定为高于常规事件）。

- 它兑现既定的核心权衡「**花寿元换永久出牌力**」。再叠一层灵玉，权衡就从一条变成两条，而寿元那条才是本作的时间压力主轴。
- 它保住「付不起在事件选择面整体消失」这条承重定案：`selectCost` 无条件施加是全局规则；若槽内操作另收灵玉，就会出现「进来了但买不起任何一个操作」的死屏，而规则层刚把这类不可选态整体删掉。
- 想表达代价差异时用既有旋钮：条目级的 `lifeSpanCost` 覆盖值（「深度闭关」耗更多寿元）。

### 开局构筑事件 = 上述形态的一个内容条目，无任何专属规则

- **`eventPriority = 1`**（本批有效可选集收窄为该档），置位方是 future-event-service——故它是「`Priority = 1` 依什么条件抬升」那条待答项的**第二个确定答案**（第一个是配额闸门的 Travel）。
- **两个决策槽**：槽 1 限定 `LearnTechnique`（候选 3），槽 2 限定 `GrantItem`（候选 3）。
- **两槽均 `AllowDecline = false`。** 开局底盘明写为「2 门角色绑定功法 + 1 门选来的功法 + 1 件选来的法宝」，允许拒绝会让底盘残缺；且它是玩家的第一屏，不该以「什么都不选」开场。**常态条目的默认值相反，是 `true`**（见 `common-properties.md`）。
- **`lifeSpanCost` 取 0 的条目级覆盖。** 它是被强制进入的第一个事件，收寿元等于开局即扣而玩家未做出任何取舍。这落在「个别事件可在表值之外设更小的覆盖值」这条既有通道内，不需要新规则。

Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-17b-research-build-panel-and-deck-elements.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Research 为五类分类法之一，语义 = 调整 / 升阶卡组；休养并入闭关（或战斗）；开局强制构筑事件归 Research** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **结算形态 = 复数决策槽的构筑面板；操作清单六类闭合；产出面收窄为卡组 + `manaLimit` + `lifeTotal`；`manaLimit` 下降挂玩家自选风险档；不另收资源代价** → **ADR 候选**（待固化）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`Recuperate` 的回复量与走火入魔候选的出现权重（归 ch1 数值标杆专场）。** 形态已定、取值未定。→ `systems/balance.md`。
- **功法的层数上限（归 ch1 数值标杆专场）。** `UpgradeTechnique` 的「未达层数上限」这条候选过滤有形态无取值，`ResearchCandidate.Amount` 的取值域待它答定。→ `systems/character-profile/deck/_index.md`、`systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/research.md`（待建）
