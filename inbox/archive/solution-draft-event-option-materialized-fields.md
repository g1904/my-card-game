---
type: solution-draft
date: 2026-08-17
question: `EventOption` 的完整物化字段清单——还有哪些数值可被情境改写、outcome 权重是否在物化时固化、`lifeSpanCost` 的形态、`combatTier` 的落点
source: open-questions/02-event-options.md → 「`EventOption` 的完整物化字段清单」（并入 open-questions/04-hidden-attributes-plot.md → 「`PlotModulation` 的字段面是否还需扩」与 systems/adventure-event/common-properties.md → 「`Priority` 是否从 `int` 退化为 `bool`」）
targets: systems/services/future-event-service.md · systems/adventure-event/common-properties.md · systems/services/plot-manager.md · systems/services/profile-service.md · systems/services/life-cycle-service.md · systems/architecture.md · systems/adventure-event/combat/_index.md · systems/balance.md
status: distilled
reviewed: 2026-08-17 —— 四项取向全部取推荐项 A（第 3 项 lifeSpanCost 定值标 [采纳推荐 — 待复核]）；合并 interview 另裁定：不抄 EventOutcomeSpec 的内部形态（不写 int FailureRatio / HiddenStatPush / ReplacementOffer，既有 0.5 比率口径不动）、字段名取 OutcomeSpec、明写结算走向映射表与 Combat 产出边界、删掉不可实现的 Priority 加载期校验、PlotModulation 维持六字段、顺手改写 ADR-0002 尾部的 combatTier 待办
distilled-to: handoffs/2026-08-17i-event-option-materialized-fields.md
---

# 方案草稿 — `EventOption` 的完整物化字段清单

## 问题

`AdventureEventData` 是模板，「**多数**具体属性由 future-event-service 依情境物化产出」。骨架**十一字段**已定（`InstanceId` / `EventId` / `EventType` / `Priority` / `SelectCost` / `IsRevealed` / `RevealedEventId` / `DestinationLocationId` / `ResearchSlots` / `ExchangeStock` / `RerolledCount`），但「多数」这个词至今没有闭合的清单。四个分叉悬着：

1. **还有哪些数值可被情境改写？**（清单如何收口、缺哪几格）
2. **outcome 权重是否在物化时固化？**
3. **`lifeSpanCost` 是固定值还是可带区间 / 公式？**
4. **`combatTier` 除 `EncounterSpec` 外是否也要出现在 `EventOption` / `PastEventEntry` 上？**

它卡住三处：`EventOption` 的类型定稿（`/derive-requirements` 无从切出可验收的字段面）、`PastEventEntry` 的扩充位（它明写「随本项答定后扩充」）、以及 `PlotModulation` 的字段面复核（它明写「待本项落定后复核」）。

**四类事件的收口已把地基铺好**：Exchange / Travel / Research / Explore 均已于 08-17 各自落定专有物化字段，Explore 的专有字段清单甚至已明写「闭合，只有 `RevealedEventId` 一个」。剩下的不是逐字段猜，而是**给清单一条判据、把判据没覆盖到的那一格补上**。

## 约束（来自既有设计）

- **唯一物化点 = future-event-service；产出即定稿（immutable）；定稿实例必须落存档，消费侧不得回查模板重算、不得改写其字段。**（`systems/services/future-event-service.md`、`systems/architecture.md` 总则 6）
- **快照判据（已是权威，字段表只是它的投影）：「重算不出来的存，重算得出来的不存」。** 文本类字段一律不物化、不进快照；模板上的基准数值、参数空间、outcome / effect 定义不进 `PastEventEntry` 快照。（`systems/adventure-event/common-properties.md`「`pastEvent` 的痕迹 schema」）
- **防重掷纪律：** 候选 / 掷定结果必须在玩家可退出之前算定并落盘，否则退出重进即可重掷。（Research 候选 + `ManaDelta`、Exchange 库存与重掷、Travel 目的地、Explore 真身、敌人赋级、`FirstSide` 六处均据此）
- **成本侧三条不变式：** `SelectCost.AbilityElements` 恒空 · `DeckElements` 恒空 · `Elements` 中 `LifeSpan` 恒 ≤ 0（物化后）。均为「加载期校验 + 物化组装后断言」两处 `PushError`。
- **`lifeSpanCost` 定价 = 「事件类型 × 篇章」统一定价表 + 条目级偏移 / 覆盖（Explore 例外，禁覆盖）；内容侧写正数量值、物化取负；判据是目标游玩时长（ch1 30–40 / ch2 35–45 / ch3 45–55 分钟）。**（`systems/adventure-event/common-properties.md`、`systems/balance.md`）
- **`ModifierKey.LifeSpanCost` 的施加点在 `TryApply`，不在物化侧；「一个 `ModifierKey` 只能有一个施加点」。**（`systems/services/profile-service.md`「`ResourceElements` 表」）
- **`selectCost` 的精确数值只在寿元 Band 2 展示**（Band 0 / Band 1 完全不显示）；回寿数字同一个开关。
- **`combatTier` 落 `EncounterSpec.Tier`，由物化时从 `AdventureEventData` 代入；`EnemyData` 完全不携带；PlotManager 写不出它。**（`systems/adventure-event/combat/_index.md`、`systems/services/plot-manager.md`）
- **`Source.EventOutcome` 的定义：** 由通用结算器**从物化后的 `EventOption` 的 outcome / effect 定义**算出的授予。（`systems/common-properties.md`「授予来源」）
- **PlotManager 只调内容不调约束；`PlotModulation` 六字段是其权力面的逐条投影，越权的写法在内容层根本没有字段可填。**（`systems/services/plot-manager.md`）
- **`Priority` 取值域两档、置位方唯一（本服务，PlotManager 不得改）；`EffectivePriority` 由服务算好放进 batch。**
- 相关 ADR：`decisions/ADR-0002-adventure-event-taxonomy.md`（五类 + `combatTier` 三档不各占一个 `eventType`）。

## 建议方案

### 子项 1 · 清单的收口方式 = 一条物化判据，不逐字段拍板

`[既有推演]`

快照面用一条判据收口（「重算不出来的存」），**物化面应当照抄这个形状**——否则每答一类事件就要重开一次「清单闭合了吗」。建议明写为**物化判据**（与快照判据是孪生的两条，不是同一条）：

> **凡满足下列任一条的，落 `EventOption`；三条皆不满足的，留在模板侧：**
> **① 由 seeded RNG 掷定**（重算不保证同结果）；
> **② 由情境代入而定**（角色状态 / 篇章 / location / `PlotModulation` 参与，模板上只有参数空间）；
> **③ 物化时组装 / 变换而成**（`SelectCost` 的取负与 element 组装即此类）。
>
> **反向的硬边界（已答结，不再重开）：** 文本类字段一律留模板（显示名 / 描述 / 图标 / 风味文案）；随 flags 变且无消费方的（真身启用态）不落实例。

两条判据的分工：**物化判据答「这一格在不在定稿实例上」，快照判据答「这一格要不要再抄进 `PastEventEntry`」。** 二者取值不同的例子现成：`ExchangeStock` 在实例上（物化产出），但痕迹侧靠 `AppliedChange` 记账、不再存一份库存表。

**按此判据逐项核过一遍，清单只缺两格**（下表「缺口」两行）：

| 面 | 字段 | 判据命中 | 状态 |
|---|---|---|---|
| 骨架 | `InstanceId` / `EventId` / `EventType` | ③ / ③ / ③ | 已定 |
| 约束 | `Priority` | ② | 已定（见子项 5） |
| 成本 | `SelectCost` | ③ | 已定（见子项 3） |
| Explore | `IsRevealed` / `RevealedEventId` | ③ / ③（直拷零变换） | 已定 · 专有清单已闭合 |
| Travel | `DestinationLocationId` | ① | 已定 |
| Research | `ResearchSlots` | ① | 已定 |
| Exchange | `ExchangeStock` / `RerolledCount` | ① / ③ | 已定 |
| **产出** | **outcome / effect 定稿载体** | **① + ②** | **缺口 A（见子项 2）** |
| **Combat** | **`EncounterSpec` 的承载**（含 `Tier` / `Enemy` / `TurnLimit` / `VictoryRule` / `FirstSide` / `RewardPoolId` / `BaseReward`） | ① + ② | **缺口 B —— 归「物化后敌人实例的类型形态」那条待答项，本方案不表态**（见「前置依赖」） |
| 明确**不加** | `combatTier` 独立字段 | 不命中（模板常量） | 见子项 4 |
| 明确**不加** | 任何文本类字段 | —— | 已答结 |
| 明确**不加** | 真身的 `ContentEnabled` 态 | 无消费方 | 已答结 |
| 明确**不加** | 目的地进痕迹侧 | 可由下一条痕迹还原 | 已答结 |

**推论（承重）：清单在缺口 A 与缺口 B 补齐后即闭合**——「多数属性由物化决定」这句话从此有一条可核对的边界，`/derive-requirements` 可以据此切 FR。**日后新增一类专有物化字段（例如日后某类事件的新参数）走判据，不再重开本条待答项。**

### 子项 2 · 缺口 A：outcome / effect 的定稿载体必须存在；**权重在物化时固化，条件在结算时求值**

`[既有推演]`

**先指出一处已存在的不一致（详见「与既有决策的张力」①）：** `systems/common-properties.md` 定义 `Source.EventOutcome` 为「从**物化后的 `EventOption`** 的 outcome / effect 定义算出的授予」，而三处 resolver 注释写的是「读**模板上**的数据驱动 outcome / effect 定义」。两者只能有一个成立，而 `EventOption` 的十一字段里**没有任何一格承载 outcome**——今天的通用结算器实际上无处可读。

建议按 `Source` 的表述收口，即**新增一格产出侧载体**，理由三条，全部是既有纪律的直接推演：

1. **产出侧同样受防重掷纪律约束。** 若 outcome 的抽取（哪个奖励条目、掷出几个）留到结算那一刻从模板现掷，玩家退出重进即可重掷——这正是 Research 候选与 Exchange 库存被前移到物化的同一条理由。
2. **产出侧同样受「不得回查模板重算」约束。** overlay 热更可在轮回进行中覆写模板；结算时回查模板 = 同一个事件在呈现与结算两处看到不同数据。
3. **`AppliedChange` 只记最终账，不足以替代它。** 最终账是**施加之后**的产物；决策点（例如置换面板的「失去 A · 得到 B」候选）需要一份**施加之前就已定稿**的候选，而既定形状明写「候选必须预先算定并落决策点存档」。

**固化到什么程度——分两档，这是本子项的承重结论：**

| | 什么 | 何时定 | 依据 |
|---|---|---|---|
| **权重 / 抽取（固化）** | 「从哪个池抽哪一条」「掷出几个」「哪一档」 | **物化时掷定，落定稿实例** | 防重掷 + 不得回查模板 + 与 Research / Exchange / 敌人赋级同构 |
| **条件 / 分支（不固化）** | 依结算走向的分支：胜 / 负、成 / 败，`ExperienceGrade × FailureRatio` 的折算，以及读隐藏属性当前值作为输入项 | **结算时求值**（`eventEnd` 组装 spec 那一刻） | 结算走向在物化时**尚不存在**；`FailureRatio` 折算既定在「`ProfileChangeSpec` 组装时完成」；「结算输入通道 = 数据驱动 outcome 求值读取隐藏属性当前值」是既定通道 |

**关键澄清：「不固化」不等于「留一张权重表到结算时再掷」。** 条件分支的**两侧取值都已在物化时定稿**，结算时只是**选一侧**——不掷任何骰子。故「outcome 权重是否在物化时固化」的答案是**是，全部固化**；结算时发生的只有选择与折算。

**这与「模板上的 outcome / effect 定义不进快照」不冲突：** 那条管的是 `PastEventEntry`（本次掷定的结果已在 `AppliedChange` 里，再存一份权重表是无用中间态）。物化固化的结果落在**当前批 eventOptions 的存档**里，痕迹侧照旧不存。两条同时成立。

**代价明写（被接受）：** 一批 3–5 个选项的 outcome 全部预掷 ⇒ 未选项的产出永不施加，等于白掷。这与 `SelectCost` / `ResearchSlots` / `ExchangeStock` 在未选项上白算完全同构，**不是新代价**；RNG 消耗照常由 `DrawCount` 持久化，确定性不受影响。

**载体的顶层形态（内部分解待前置项，见下）：**

```csharp
public sealed record EventOutcomeSpec(          // 物化产物：抽取已掷定，条件分支两侧取值均已定稿
    ProfileChangeSpec             OnResolved,   // 正常结算侧的定稿账（条目 Id 与数量已掷定）
    ProfileChangeSpec             OnFailure,    // 失败侧；非战斗类通常为空
    ExperienceGrade               Experience,   // 档位（映射值仍查平衡表，不落裸数字）
    int                           FailureRatio, // 百分比；默认 50，逐条可覆写
    IReadOnlyList<HiddenStatPush> HiddenStats,  // 每属性一档，胜负同施、不套 FailureRatio
    IReadOnlyList<ReplacementOffer> Replacements); // 置换 / 禁用候选（若本事件带）；已掷定
```

**⚠ 内部分解不在本方案的可定稿范围。** `OnResolved` / `OnFailure` 之外还需要「效果原语」表达非授予型后果，而**效果关键字体系与目标规则**是一条明写「需一次专门 handoff」的承重待答项。故本子项**只主张三件事**：① 载体必须存在于 `EventOption` 上；② 固化时点如上表；③ 顶层按「结算走向」分侧，不按事件类型分侧（与 `Source` 的「谁组装出这条 element」同一条判据）。字段内部形态留给那次 handoff。

### 子项 3 · `lifeSpanCost` = **定值**，不带区间、不带公式

`[既有推演]`

三条既有设计各自独立地否掉区间与公式：

1. **它是时长旋钮，判据是全局目标时长。** 定价表按「改一张表把时长压回区间」设计；区间掷定会让一个篇章的寿元支出成为随机变量，反推目标时长时要按期望值算并接受方差——旋钮精度直接下降，而这是它存在的唯一理由。
2. **Band 0 / Band 1 完全不显示 `selectCost` ⇒ 变异对玩家不可感知。** 一个玩家察觉不到的随机化，其设计表达为零而结构成本非零（模板侧两个字段 + 一次掷定 + 一条校验 + 定价表反推口径改写）。**这与「不给可电子表格化优化的信息」同向，但那条纪律不构成引入方差的理由。**
3. **公式另外撞上两条：** ①「内容侧不落裸数字，走枚举档 + 平衡表映射」的既有范式（公式即在内容侧引入表达式，比裸数字更远）；② 公式的求值输入若含角色状态，则同一模板在不同情境下代价不同——而**运行期的成本变异已经有一条既定通道**：`ModifierKey.LifeSpanCost`（在 `TryApply` 施加）。**再加一条公式即两处真值。**

**故形态定为：** 模板侧一个非负整数（不填 = 取定价表「事件类型 × 篇章」那一格；可填偏移 / 覆盖值，Explore 禁填）；物化时取负填入 `ChangeElement.BaseValue`，`EventOption.SelectCost` 里它是一个**已定稿的单一负值**。**已有的变异位共三个，全部保留、无一新增**：定价表按类型 × 篇章分格 · 条目级偏移 / 覆盖 · `ModifierKey.LifeSpanCost`。

**配套的一条呈现纪律（补既有空白，见张力 ②）：** Band 2 展示的精确扣减量应为 `ApplyModifier(LifeSpanCost, SelectCost 内的 LifeSpan 值)` 的**只读查询结果**，而**不把修正后的值写回定稿实例**。只读查询不构成第二个施加点（`ApplyModifier` 本就是通用查询）；写回则会打两次折——与 `Jade` 那一行明写的坑同款。

### 子项 4 · `combatTier` 两处都**不加**独立字段，走 `EventId` 溯源

`[取向选择]` —— 推荐「不加」，理由如下；对立选项与后果见「仍需用户决定」第 2 项。

**关键事实：`combatTier` 是模板常量，不是物化产物。** 它由物化时从 `AdventureEventData` 代入 `EncounterSpec`；`EnemyData` 不携带它（同一敌人条目可同时用于 `Practice` 与 `Standard`，**但一个 AdventureEvent 条目只有一个档**）；`PlotModulation` 写不出它；`±2` 赋级带对三档一视同仁。**没有任何调制源能改变某个实例的档位** ⇒ 按物化判据三条一条都不命中，按快照判据它属「重算得出来的」那一侧。

**呈现与履历两个消费方都不需要新字段，因为它们本来就要查模板：**

| 消费方 | 需要什么 | 现成通道 |
|---|---|---|
| 选择区区分「切磋 / 遭遇 / 渡劫」 | 该选项的档 | 卡面已按 `EventId` 取显示名 / 描述 / 图标 / 风味文案（文本不物化）——**tier 在同一次 `ContentRegistry.Get()` 里免费拿到** |
| 履历读出「这一步是不是渡劫」 | 该痕迹的档 | 履历每条同样要按 `EventId` 取显示名——同一次查表 |
| 剧本条件「渡劫完成」 | 判定 | `PlotCondition.EventResolved` 已接 `EventId` / `EventType` / `EventOutcome`，填 `EventId` 即可，**不需要新条件类型** |
| 篇章重试 / 残卷（ADR-0004 锚点） | 可机械判定的判据 | `EncounterSpec.Tier` 在战斗内已有；篇章边界另由篇章结构与 `chapterRetry` 承载 |

**Explore 的遮罩纪律因此自动成立**（这是「不加」的额外收益）：壳的 `EventId` 指向 Explore 模板，模板上没有 tier；真身的 tier 在 `RevealedEventId` 的模板上，而 ViewModel 在 `IsRevealed == false` 时**这两个字段一个都不读**已是既定纪律。若把 tier 拷成壳实例上的一格，就多出一个必须记得「遮罩态不许读」的字段——**同一条纪律的第三个守点，而它可以不存在。**

**唯一的退化情形（明写）：** 某条目在新 `contentVersion` 中被删除 ⇒ 该痕迹按既定语义降级为「仅标识可读」（`PushWarning`，履历显示为未知条目，不阻断读档），此时 tier 一并读不出。**这与显示名一同丢失，不构成额外损失。**

### 子项 5 · `Priority` 保留 `int`，另加一条取值域断言

`[既有推演]`

**保留 `int` 的成本是零，塌缩为 `bool` 的成本非零** —— 这与「`selectCost` 不塌缩为单一 `int`」是同一条推理的第二个实例：

- **塌缩要连改三处：** `EventOption.Priority` · `PastEventEntry.Priority`（**落存档**）· `EventOptionBatch.EffectivePriority` 与「有效可选集 = 本批最高优先级档」这条语义（`bool` 下退化为 `AnyGated`，可选集判定要改写成两次布尔比较）。
- **日后需要第三档时要迁回来**，而 `PastEventEntry.Priority` 是存档字段 ⇒ 那时是一次真实迁移。今天无线上存档、改哪边都是空迁移，故**该按「哪一侧日后更贵」选，而不是按「今天哪个更省」选**。
- **「让类型说实话」这个诉求由断言兑现，不需要改类型：** 物化组装后断言 + 加载期校验 `Priority ∈ { 0, 1 }`，违规 `PushError` + `EventId`。置位方本就唯一（future-event-service），故这条断言是对**自己代码**的防呆，与「`SelectCost.AbilityElements` 恒空」同一档、同一处。

### 子项 6 · `PlotModulation` 复核结论：**六字段不变，不扩**

`[既有推演]`

`open-questions/04` 明写该字段面「是下界不是上界，待本清单落定后复核」。以本方案的清单逐格核过：

| 本清单新增 / 已定的物化格 | PlotManager 是否该有字段 | 判据 |
|---|---|---|
| **outcome 定稿载体（缺口 A）** | **否** | 它是模板 outcome 定义的物化产物；给剧本一个字段去改它 = 「改模板字段」，而该权力已被明确禁止（权力面三项之外无字段）。剧本要改产出，正确形态是 `EventWeights` 抬高另一条**内容条目**的权重——换池，不改内容。 |
| `SelectCost` | 否 | 成本侧是玩家的账；剧本改它等于隔着遮罩改定价，而定价是全局时长旋钮。既有 `Tighten` 只及遭遇参数。 |
| `Priority` | **否（承重，已定案）** | 「只调内容不调约束」；表里明写「抬 `eventPriority` → 无字段」。 |
| `DestinationLocationId` / `TravelFullFanoutChance` | 否 | 后者明写 PlotManager 不得推拉（它改玩家选择空间的宽窄 = 约束面）。 |
| `ResearchSlots` 候选池 | 否 | 「候选池不接 modifier pipeline」已定案，唯一例外是呈现向 capability flag。 |
| `ExchangeStock` / `RerolledCount` | 否 | 库存取池链沿用授予池那一条；剧本改库存 = 改内容条目的抽取结果，越过「换池」这条唯一合法表达位。 |
| Explore 真身类型分布 | **否（已答结）** | 「不加第七个字段」已明写在 `explore/_index.md`。 |

**结论：复核完成，`PlotModulation` 维持六字段。** 并建议把这条复核的**判据**写进 `plot-manager.md`，使它不必随每次清单增长再复核一遍：

> **新增一格物化字段时，`PlotModulation` 是否跟着加一格，只看它落在哪一面：落内容面（哪些条目进池、以什么权重出现、用哪个敌人池、带内赋级权重、遭遇参数）→ 已有字段够用；落约束面或模板字段面 → 不加字段，这正是「越权的写法在内容层根本没有字段可填」要保住的东西。**

**推论：`open-questions/04` 的这一条可移出待答清单**（它明写「不阻塞任何结构」，答案是「不扩 + 一条判据」）。

## 具体形态（可 derive 的落地面）

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,
    string             EventId,
    EventType          EventType,
    int                Priority,                  // { 0, 1 }；物化后断言 + 加载期校验
    ProfileChangeSpec  SelectCost,                // 已取负；LifeSpan 恒 ≤ 0；modifier 尚未施加
    bool               IsRevealed,
    string             RevealedEventId,
    string             DestinationLocationId,
    IReadOnlyList<ResearchSlot>  ResearchSlots,
    IReadOnlyList<ExchangeOffer> ExchangeStock,
    int                RerolledCount,
    EventOutcomeSpec   Outcome                    // ★ 缺口 A：产出侧定稿载体（抽取已掷定）
    /* ★ 缺口 B：EncounterSpec 的承载 —— 归「物化后敌人实例的类型形态」那条待答项，本方案不表态 */);
```

- **字段面变化：+1 格（`Outcome`），无删除、无改名。**
- **`PastEventEntry` 的扩充：本方案主张 0 新增字段。** `Outcome` 的施加结果已在 `AppliedChange` 里（本次事件的最终账）；tier 走 `EventId` 溯源；`Priority` / `EventType` / `RevealedEventId` 已在表内。**「随本项答定后扩充」这条注释因此可改写为「本项不带来痕迹侧扩充；敌人实例那一项仍可能带来」。**
- **存档影响：** `EventOption` 落在「当前批 eventOptions」快照里 ⇒ 增一格即 **bump 存档 schema 版本**；当前无线上存档 ⇒ **空迁移**，走既有 MigrationManager 骨架。`PastEventEntry` 不动。
- **校验（一律 `PushError` + `EventId`）：**

  | 时点 | 检查 |
  |---|---|
  | 加载期 | `Priority` 非模板字段（内容作者不得填）—— 若模板上出现该字段即漏改 |
  | 加载期 | `lifeSpanCost` 的表值 / 覆盖值 < 0（既有） |
  | 加载期 | outcome 定义引用的内容 `Id` 悬空 |
  | 物化后断言 | `Priority ∈ { 0, 1 }` |
  | 物化后断言 | `SelectCost.AbilityElements` / `DeckElements` 恒空、`LifeSpan` ≤ 0（既有） |
  | 物化后断言 | `Outcome != null`（无产出的事件用**空 spec**表达，不用 `null`——避免下游到处判空） |
- **日志：** `[FutureEvent-Materialize] instance=<InstanceId> event=<EventId> type=<EventType> prio=<n> cost=<lifeSpan> outcomeRolls=<n>`。

## 后果

- **`systems/services/future-event-service.md`：** `EventOption` 定义增一格 `Outcome`；「多数属性由物化决定」一句补上**物化判据**三条；待决问题里本条移除（缺口 B 与「框定叠加顺序」等仍留）。
- **`systems/adventure-event/common-properties.md`：** 物化小节补物化判据；`PastEventEntry` 的 `⟨随…扩充⟩` 注释改写为「本项不带来扩充」；待决问题里「`lifeSpanCost` 的数据形态」与「`Priority` 是否退化为 `bool`」两条移除。
- **`systems/adventure-event/combat/_index.md`：** 待决问题「`combatTier` 除 `EncounterSpec` 外的落点」移除，改为一条正面陈述（走 `EventId` 溯源 + 遮罩态不读真身模板）。
- **`systems/services/plot-manager.md`：** `PlotModulation` 小节补「新增物化字段时是否扩字段」的判据；`open-questions/04` 的复核项移出。
- **`systems/services/profile-service.md`：** 「一个 `ModifierKey` 只能有一个施加点」旁补一句「**只读查询不构成施加点**」，并点名 Band 2 的 `selectCost` 展示走查询。
- **`systems/services/life-cycle-service.md` / `systems/architecture.md` / `systems/adventure-event/common-properties.md`：** 三处 resolver 注释「读模板上的数据驱动 outcome / effect 定义」改为「读**物化后 `EventOption` 上**的定稿 outcome」（见张力 ①）。
- **`systems/balance.md`：** `lifeSpanCost` 一律定值（无区间列）；本方案不动任何取值。
- **存档 schema：** bump 一次，空迁移。**同步粒度不变**（`EventOption` 本就随当前批上行）。

## 备选方案（已考虑并否决）

- **逐字段枚举出一份「完整清单」而不给判据** — 否决：四类事件每次收口都会新增专有字段（08-17 一天内新增了四格），逐字段清单每次都要重开本条待答项；判据式收口是本库对同类问题的既有解法（快照判据即先例）。
- **outcome 留在模板侧，结算时现掷现读** — 否决：与防重掷（退出重进可重掷产出）和「不得回查模板重算」（overlay 热更 ⇒ 呈现与结算不同数据）两条正面冲突，且 `Source.EventOutcome` 的既有定义已否掉它。
- **outcome 全部留到结算时才求值（含抽取）** — 否决：置换 / 奖励候选明写「必须预先算定并落决策点存档」；把抽取推迟到结算意味着要么开重掷窗口，要么新造一个「结算中已掷定但未施加」的第二承载。
- **`lifeSpanCost` 带 `[min, max]` 区间，物化时掷定** — 否决：Band 0 / Band 1 不显示成本 ⇒ 玩家不可感知，设计表达为零；且损害时长旋钮的反推精度。
- **`lifeSpanCost` 带公式（依角色状态求值）** — 否决：与「内容侧不落裸数字 / 枚举档 + 映射表」范式冲突，且运行期变异已有 `ModifierKey.LifeSpanCost` 一条通道，再开一条即两处真值。
- **`EventOption` / `PastEventEntry` 各加一格 `CombatTier? Tier`** — 否决（可被推翻，见「仍需用户决定」第 2 项）：tier 是模板常量，两个消费方都已在同一次查表里拿到它；新增一格反而多出一个「遮罩态不许读」的守点。
- **`Priority` 改 `bool`** — 否决：见子项 5（塌缩要连改三处含一个存档字段，而保留的成本是零）。
- **给 `PlotModulation` 加一格 outcome 调制** — 否决：等于给剧本开「改模板字段」的口子，而该权力被数据形态本身禁止，这正是该类型最强的一条性质。

## 与既有决策的张力

**① `Source.EventOutcome` 的定义 vs 三处 resolver 注释（🔴 需裁决，且不是措辞问题）。**
`systems/common-properties.md` 说 outcome 定义在**物化后的 `EventOption`** 上；`systems/services/life-cycle-service.md`、`systems/architecture.md`、`systems/adventure-event/common-properties.md` 三处注释说 `GenericEventResolver`「读**模板上**的数据驱动 outcome / effect 定义」。而 `EventOption` 的十一字段里**没有 outcome 那一格**——今天两种读法都无法落地。本方案取前者（新增载体）。**若用户选后者**（outcome 恒读模板），则要同时接受三件事：产出可被退出重进重掷、overlay 热更可让呈现与结算读到不同数据、`Source.EventOutcome` 的定义须改写。**建议松动的是那三处注释，不是 `Source` 的定义。**

**② Band 2 的 `selectCost` 精确展示 vs 「一个 `ModifierKey` 只能有一个施加点」（🟠）。**
该纪律的判据原文是「**该修正后的值是否需要在施加之前呈现给玩家**：需要 → 施加点在物化 / 展示侧」，而 `LifeSpanCost` 被归为「不需要 → 施加点在 `TryApply`」。但 Band 2 明写「**如实展示精确扣减量**」——它正是「需要在施加之前呈现」。两条按字面读会打起来：若玩家持有一条「寿元消耗 −20%」的法则，Band 2 会显示未修正值而实扣修正后值，玩家在最关键的一档看到一本假账。本方案的解法是**把展示读作只读查询**（不写回定稿实例，故不是第二个施加点），代价是要在 profile-service 那条纪律旁补一句明文。**替代解法**（把 `LifeSpanCost` 的施加点移到物化侧，写进 `SelectCost`）会引入 Exchange 已明写接受的那个代价——「轮回中途新获得的修正不影响已定稿的实例」，而法则是**账号级永久持有**，在寿元这条终态资源上更难接受。

**③ tier 不落快照 vs `PastEventEntry.EventType` 落快照（🟠 口径不对称）。**
`EventType` 同样可由 `EventId` 溯源，却存了一份（注释理由是「当时呈现给玩家的类型」）。若 tier 不存，两个形状相近的枚举一个存一个不存，日后必有人问「为什么」。**建议在字段表里明写这条不对称的理由**：`EventType` 存的是**呈现口径**（Explore 时它与真身不同，是一条独立事实）；tier 没有这种分叉（一个条目一个档），故按判据不存。若用户不接受这条不对称，走「仍需用户决定」第 2 项的 B 选项。

## 前置依赖

- **缺口 B —— `EncounterSpec` / `EnemyInstance` 的承载形态**（`open-questions/02-event-options.md` 的「物化后敌人实例的类型形态」）。**本方案对它不表态**，但指出它比原措辞更宽：`EncounterSpec.EncounterId` 既定 `= EventOption.InstanceId`，而 `TurnLimit` / `VictoryRule` / `FirstSide` / `RewardPoolId` / `BaseReward` / `Tier` 全部在物化时定稿，今天**一格都没有落点**。本方案的清单在它答定后才算闭合；**子项 4 的 tier 结论不依赖它**（两种承载下都成立）。
- **效果关键字体系与目标规则**（`combat/_index.md` 待决，明写「需一次专门 handoff」）。`EventOutcomeSpec` 的**内部分解**在它答定前无法定稿；本方案只定「载体存在 + 固化时点 + 顶层按结算走向分侧」。
- **ch1 数值标杆专场。** `lifeSpanCost` 定价表每格取值、`ExperienceGrade` / `HiddenStatGrade` 映射值、`FailureRatio` 是否改默认——本方案只定形态，不给任何取值。
- **结算进行中的 `EventOption` 派生实例如何落存档**（并行处理中的另一条待答项）。**承载形态见该项，本方案只约束字段本身**：本方案假定派生只改字段**值**、不改字段**面**（`with` 派生沿用同一 `record`），新增的 `Outcome` 在派生时原样携带、不参与改写。
- **`Card` 族购买的入组 element 载体**（`exchange/common-properties.md` 待决）。它卡住的是「单卡入组」这一类 outcome 的 element 表达，故 `EventOutcomeSpec.OnResolved` 里那一类产出暂无载体——**不阻塞本方案的顶层结论**。

## 仍需用户决定 → **已全部裁决（2026-08-17 · 批量评审）**

> **定案（四项一律取推荐项 A）：**
> **1 取 A** —— 加 `EventOutcomeSpec Outcome` 格，outcome 权重全部在物化时固定；结算时只求值条件分支、不掷骰。松动三处 resolver 注释（`life-cycle-service.md` / `architecture.md` / `adventure-event/common-properties.md`），**不动 `Source.EventOutcome` 定义**。
> **2 取 A** —— `combatTier` 两处都不加，走 `EventId` → 模板溯源；与 `PastEventEntry.EventType` 的口径不对称须明写理由（`EventType` 存的是**呈现口径**，Explore 时与真身不同；tier 无此分叉）。
> **3 取 A `[采纳推荐 — 待复核]`** —— `lifeSpanCost` 一律定值（非负整数，物化取负），不留区间旋钮。
> **4 取 A** —— Band 2 展示走只读 `ApplyModifier` 查询，施加点仍在 `TryApply`；profile-service 补一句「只读查询不构成施加点」。单一施加点判据不松动。
>
> **本轮同批裁定的连带（跨分片，orchestrator 合并）：**
> - 缺口 B（`EncounterSpec` 承载形态，本草稿未表态）已由同批 S5 答定：**`EventOption` 加一个可空 `EncounterSpec Encounter`，`EnemyInstance` 嵌其内**。⇒ **`EventOption` 本轮共加两格**（`Outcome` + `Encounter`），清单至此闭合。
> - 派生实例的承载由同批 S3 答定为 `CharacterProfile.activeEvent`（新可空块，持派生后整份定稿实例）——本草稿「派生只改字段值、不改字段面」「`Outcome` 不参与派生改写」两条假设**均获保留**。
> - `PlotModulation` 复核结论（六字段不变）在同批被 S5 的一项裁决改写：**`EnemyPoolScope` 删除，六字段收窄为五**（改为隐式取当前 arc 的 `Id`）。本草稿写的「六字段不变」须按此更新后再提炼。
> - 五份草稿的 schema bump **合并为同一次**。
>
> 下列原文保留为选项与理由的溯源。

1. **outcome 定稿载体：加还是不加（张力 ① 的裁决）。**
   - **A（推荐）：加一格 `Outcome`，抽取在物化时掷定。** 后果：`EventOption` +1 格、bump schema（空迁移）、三处 resolver 注释改写；产出侧获得与 Research / Exchange 同款的防重掷保证。
   - **B：不加，outcome 恒读模板、结算时现掷。** 后果：`EventOption` 不动，但须接受「退出重进可重掷产出」「overlay 热更下呈现与结算可能不同」，且 `Source.EventOutcome` 的定义要改写。
   - **理由：** A 是三条既有纪律（防重掷 · 不得回查模板 · 候选须预先算定）的直接推演，B 要同时松动其中两条。

2. **`combatTier` 的落点。**
   - **A（推荐）：两处都不加字段，走 `EventId` → 模板溯源。** 后果：零字段增量；Explore 遮罩纪律少一个守点；条目在新版本被删除时履历读不出 tier（与显示名一同丢失）；须接受与 `PastEventEntry.EventType` 的口径不对称（张力 ③）。
   - **B：`EventOption` 与 `PastEventEntry` 各加一格 `CombatTier?`（非 Combat 为 `null`）。** 后果：+2 格、bump schema；履历与呈现不依赖模板解析；但多出一个必须记得「遮罩态不许读」的字段，且与快照判据「重算得出来的不存」相悖（须写成明示例外，像 `LifeSpanAfter` 那样）。
   - **C：只在 `PastEventEntry` 上加一格，`EventOption` 不加。** 后果：折中；仍需一条明示例外，且两处口径分叉（呈现查表、履历读字段）。
   - **理由：** tier 是模板常量而非物化产物，两个消费方本来就要按 `EventId` 查模板取显示名；A 的增量为零。

3. **`lifeSpanCost` 是否给「区间」留一个风味旋钮（少数条目可用）。**
   - **A（推荐）：不留，一律定值。** 后果：时长旋钮精度最高；作者少一个风味位（与 Explore 已接受的那个代价同款）。
   - **B：模板侧允许可选的 `[min, max]`，物化时经 map 子流掷定。** 后果：+2 个模板字段、一次掷定、一条校验（`min ≤ max` 且 `min ≥ 0`）、定价表反推改按期望值；而 Band 0 / Band 1 不显示成本 ⇒ **玩家在常态档完全感知不到这个方差**。
   - **理由：** 感知不到的随机化只有结构成本没有设计收益。

4. **Band 2 展示与 `LifeSpanCost` 修正的关系（张力 ② 的裁决）。**
   - **A（推荐）：展示走只读 `ApplyModifier` 查询，施加点仍在 `TryApply`。** 后果：需在 profile-service 补一句「只读查询不构成施加点」；Band 2 显示的是玩家实际会被扣的数。
   - **B：把 `LifeSpanCost` 的施加点移到物化侧，写进 `SelectCost.BaseValue`。** 后果：与 `ShopPrice` 同款形状（先算后标），但引入「轮回中途新获得的修正不生效」这一代价，而法则是账号级永久持有。
   - **C：维持现状不改。** 后果：Band 2 在持有相关法则时显示一本假账——**不建议**，它落在唯一给精确数字的那一档上。
