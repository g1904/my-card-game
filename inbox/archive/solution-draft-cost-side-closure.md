---
type: solution-draft
date: 2026-08-16
question: `selectCost` 无条件施加后，负值如何钳制、「余额不足即拒」还剩哪些消费点、以及 Explore 遮罩下展示哪一份 `selectCost`
source: open-questions/02-event-options.md → 「寿元打穿后怎么办」·「『余额不足即拒』还剩哪些消费点」·「遮罩下的 `selectCost` 呈现」
targets: systems/services/profile-service.md · systems/adventure-event/common-properties.md · systems/adventure-event/explore/_index.md · systems/adventure-event/exchange/_index.md · systems/architecture.md（共享核心类型）· systems/character-profile/currency.md · systems/character-profile/life-total.md · systems/services/life-cycle-service.md
status: distilled
reviewed: 2026-08-16 —— 用户裁决三项取向（T1 / T2 / T3）与 mana 处置一律取推荐项；interview 追加裁决 `AdvanceResult.MissingElement` 一并删除
distilled-to: handoffs/2026-08-16d-cost-side-closure.md
decided: 2026-08-16 —— 三项取向（T1 / T2 / T3）与 mana 张力的澄清处置一律按推荐定案
---

# 方案草稿 — 成本侧收口：负值钳制 · 拒绝语义的残留消费点 · 遮罩下的成本展示

## 问题

三条待答项同属 `selectCost` 成本侧的**同一条语义链**，必须一起答——分开答会各自定出互相不自洽的规则：

1. **负值施加的钳制规则（承重）。** `selectCost` 已定为**无条件施加**、支付后做终态判定，于是 `ProfileManager.TryApply` 必须回答：施加负值使某个资源低于 0 时，**截断到 0 还是允许为负**？哪些资源的耗尽构成终态？寿元归 0 = `defeated` 已定，其余 element 全部悬空。它直接决定 `TryApply` 的施加语义，也决定 `Status` 里那些数值字段的取值域。
2. **「余额不足即拒」还剩哪些消费点。** 事件推进路径已不需要它，成本侧只剩 `lifeSpanCost` 一项；`CanAfford` / `AdvanceResult.CostRejected` / `MissingElement` 三样东西是否整体删除？
3. **遮罩下的 `selectCost` 呈现。** Band 2 要如实展示 `selectCost`，但 Explore 的真身隐藏——展示 Explore 壳自己的成本还是真身的？两者不一致会泄漏真身类型。

第 3 条看似是 UX 问题，实为成本侧问题：**它问的是「这一步到底扣的是哪一份成本」**，而这正是第 1 条的施加语义要回答的事。

## 约束（来自既有设计）

- **`selectCost` 无条件施加，不做「付得起」校验；支付后立即做终态判定 ①，判负则短路进失败流程**（`systems/adventure-event/common-properties.md`、`systems/services/life-cycle-service.md`、`systems/architecture.md` 三处同形明写，并附「不要把它们加回来」）。
- **成本侧 element 现只有 `lifeSpanCost` 一项**，但**复合形态 `ProfileChangeSpec` 保留不塌缩**（`systems/adventure-event/common-properties.md`）。
- **`ProfileChangeSpec` = 三个平级只读列表**；资源族「可加、要钳制、走 modifier pipeline」，能力族与统计族**不**钳制（`systems/architecture.md`「共享核心类型」）。
- **`PowerFragmentAccumulated` 是万分比整数、施加后钳制到 `[0, 10000]`**——本库已有的**第一个**钳制案例，且明写它是「负值钳制规则」这条待答项在账号级侧的第一个已定案例（`systems/services/profile-service.md`）。
- **`DefeatReason { Discarded, LifeSpanExhausted, LifeTotalExhausted }` 封闭三值**；战斗失败本身不终结角色（`systems/architecture.md`）。
- **剩余寿元跨篇章结转**，且 `Status.ChapterLifeSpanBudget` 是寿元 Band 百分比的分母（`systems/services/life-cycle-service.md`）。
- **`PastEventEntry.LifeSpanAfter` 存结算后剩余寿元**，且 `AppliedChange` 是「可直接重放的账」（`systems/adventure-event/common-properties.md`）。
- **Explore 遮罩的是一个固定的真身事件；揭示发生在 `eventStart` 阶段**，而 `TryApply(SelectCost)` 在其**之前**（同上两文档的流程图）。
- **`selectCost` 展示挂寿元 Band：Band 0 / 1 完全不显示，Band 2 如实展示精确扣减量**（`systems/adventure-event/common-properties.md`）。
- **事件选择面不设不可选 / 置灰态**（三档一律，同上）。
- **`lifeSpanCost` 定价 = 「事件类型 × 篇章」统一定价表 + 条目级偏移 / 覆盖**（同上）。
- **后端对 `characterDiffs` 整体不透明、纯透传，不递归不比对不校验**（`backend-design-documents/contracts/profile-sync.md` §5）——**故本问题不跨库**，见「后果」。

---

## 建议方案

### 一、钳制是**逐 element 的规格**，不是一条全局规则 `[既有推演]`

建议把钳制建模为 `CostKey → (Min, Max, DepletionOutcome)` 的一张**封闭表**，而不是「资源一律截断到 0」这样一条通则。

三条推演支撑它：

1. **本库已有的唯一钳制案例就是逐条的。** `PowerFragmentAccumulated` 钳制到 `[0, 10000]`——上界 10000 是它自己的万分比语义，不可能来自任何通则。既然第一个案例就带自定义区间，形态本就是表。
2. **已经存在必然违反「截断到 0」的 element。** `HiddenStat` 三项里的道心 `Faith` 与煞气 `MaleficQi` 是**双向量**：`life-cycle-service.md` 的跨档叙事判据写作 `|newBand| > |oldBand|`，**绝对值写法证明 band 带符号**，即这两项可以落到常态的两侧。若它们进 `CostKey`（成本侧可推拉隐藏属性，见「前置依赖」），`Min = 0` 对它们直接是错的。**一条通则一旦定下，第一个例外就在门口。**
3. **终态性与钳制是同一张表的两列。** 「归 0 是不是终态」逐 element 不同（寿元是、灵玉不是），而终态判定 ① / ② 现在要么硬编码检查两个字段，要么查表。查表使「新增一个终态资源 = 表里加一行 + `DefeatReason` 加一个成员」，与「新增一张卡 = 新增一个 `.tres`」的可加性同向。

**表的落点建议 = 代码常量静态表，不进 `.tres`。** 它与 `(Kind, Scope, Source)` 合法子集表、`RngStream` 子流清单同类：**是规则语义而非平衡旋钮**——改一行会改变终态判据与存档取值域，属于「须两侧同批评审」那一档，不是策划可以随手调的数值。（这一条是取向，见「仍需用户决定」T2。）

### 二、`Min = 0` 是资源族的**默认**，例外逐条写明；寿元取默认 `[既有推演]` `[通行做法]`

建议表的首批三行（其余随「cost element 清单」逐条补）：

| `CostKey` | Min | Max | 归 Min 时 | 依据 |
|---|---|---|---|---|
| `LifeSpan` | **0** | 无 | **终态** `DefeatReason.LifeSpanExhausted` | 归 0 = `defeated` 已定 |
| `Jade` | **0** | 无 | 无（只是变穷） | `DefeatReason` 三值封闭，无灵玉项；灵玉随轮回清理，不承载终态语义 |
| `LifeTotal` | **0** | **无**（明确不设上界） | **终态** `DefeatReason.LifeTotalExhausted` | `lifeTotalLimit` 概念已整体删除、明写「不设上限截断」；归 0 = `defeated` 已定 |

寿元取 `Min = 0`（**截断，不允许为负**）的四条依据：

- `[既有推演]` **Band 百分比的分母是 `ChapterLifeSpanBudget`。** 允许为负则 Band 2 的「标红精确余量倒数」会显示负数，与该呈现的语义（还剩多少）自相矛盾——而那是寿元在全库**唯一**的精确显示通道，不能让它显示一个无意义的数。
- `[既有推演]` **终态判据的两种写法因此同解。** `lifeSpan <= 0` 与 `lifeSpan == 0` 在截断后完全等价；不截断则两者行为不同，而本库没有任何地方指定过用哪一种。截断消掉这个歧义面。
- `[既有推演]` **跨篇章结转要求剩余寿元是一个可加的非负预算。** 负数结转在语义上不成立（角色此时已 `defeated`，不会有下一篇章），但不截断意味着 `Status.LifeSpan` 会以负值落进存档，读档校验与元进程的寿元曲线都要额外处理负轴，换来零收益。
- `[通行做法]` roguelike 的资源条一律 clamp 到 0（Slay the Spire 的 HP、Balatro 的手牌数）。「欠债」只在有**还债机制**时才值得建模，本作没有——寿元透支后角色当场终结，没有下一步去偿还。

### 三、**spec 不截断，字段截断**（承重的分层） `[既有推演]`

截断只作用在「把 element 施加到 Profile 字段」那一刻；`ProfileChangeSpec` 内 `ChangeElement.BaseValue` 与落进 `PastEventEntry.SelectCost` / `AppliedChange` 的快照，**一律保留未截断的原值**。

- 它保住了 `AppliedChange` 「可直接重放的账」这条既有定位——截断进 spec 等于让账本记的不是实际发生的事。
- 它使**「超支了多少」这一信息不丢**：由 `LifeSpanAfter == 0` 与 `AppliedChange` 中的原值相减即可得出。这直接回收了截断方案唯一真实的代价（日后若要做「最后一步透支 7 点寿元」的死因叙事，数据现成）。
- 它与既有的「内容侧写正数量值、物化时取负、`TryApply` 按带符号施加」是同一条分层纪律的第四段：**每一层只做自己那一次变换，不把下游的语义提前**。

### 四、`AdvanceResult.CostRejected` 删除；`CanAfford` / `MissingElement` 保留 `[既有推演]` `[通行做法]`

三样东西命运不同，不应打包处置：

| | 建议 | 依据 |
|---|---|---|
| `AdvanceResult.CostRejected` | **删除** | `[既有推演]` 它**只服务于事件推进路径**，而该路径已定「无条件施加、不做付得起校验」⇒ 该成员**已经不可达**。留着不只是死代码，它会主动诱导后来者把校验加回来——`common-properties.md` 已不得不明写一句「不要把它们加回来」，那句话的存在本身就是这个成员在施加压力。 |
| `CanAfford(spec)` | **保留** | `[既有推演]` 它有一个**已知且已定存在**的消费点：Exchange 的商店购买。Exchange 是五类之一（ADR-0002），交易必然涉及货币结算，而主动消费与事件推进的语义**根本不同**。 |
| `ApplyResult.MissingElement` | **保留** | 它是 `CanAfford` 失败时唯一能告诉 UI「差的是哪一样」的通道；删掉它等于让 Exchange 日后重新发明一个。 |

**为什么商店可以灰显、而事件选择面不可以** —— 这不是双标，两者的判据是同一条：

> **「明知做不到仍然去做」有没有意义。** 事件选择面有意义（明知是死路仍然走，与「打不过也得打」同构，且它换来一段终局叙事）；商店里点一件买不起的商品**没有任何意义**——不产生终态、不产生叙事、不推进任何东西，只产生一次挫败。

`[通行做法]` Slay the Spire / 月圆之夜的商店一律灰显买不起的商品并保留价格可见，这是玩家的强预期。

建议在 `exchange/_index.md` 与 `profile-service.md` 两处同时写下这条判据（而不是只写结论），否则日后「事件面不灰显」这条纪律很容易被误推广到商店。

### 五、遮罩下展示的是 **Explore 壳自己的 `selectCost`**——因为那是唯一被施加的成本 `[既有推演]`

这条待答项的前提（「两份成本要选一份展示」）**在既有流程下不成立**。结算流程明写：

```
→ TryApply(SelectCost)          ← 支付发生在这里
→ 终态判定 ①
→ 【eventStart 阶段】选 resolver、Explore 揭示    ← 揭示发生在这里
```

**支付先于揭示。** 被施加的必然是 `EventOption.SelectCost`，而 Explore 的 `EventOption` 是由 Explore 模板物化的——**真身模板的成本字段从头到尾不在链路上**。`PastEventEntry` 也只有**一份** `SelectCost`（「一次选择仍只结算一个事件、`pastEvent` 上仍是一条痕迹」）。

所以答案不是「二选一」，而是：**只有一份成本存在**，泄漏面随之消失。

配套需要落定四条，否则这个干净的结论会被内容侧重新捅破：

1. **物化纪律（可机械检查）：** 物化一个 Explore `EventOption` 时，`SelectCost` 一律取 Explore 模板 + 定价表的 **Explore 行**，**不读真身模板的任何成本字段**。物化组装后加一条断言，与既有的「`SelectCost.AbilityElements` 恒空」同一处、同一档（`PushError`）。
2. **Explore 在定价表上自成一行，且该行不得由真身推导。** 若 Explore 的成本取自真身（例如「遮罩什么就收什么价」），Band 2 的精确展示会让玩家**用成本数值反推真身类型**——Combat / Travel / Exchange 三行定价不同即构成指纹。这是本问题真正的泄漏面所在，须在 `explore/_index.md` 明写封死。
3. **真身模板的成本字段不是死字段。** 同一个 Combat / Travel / Exchange 条目**也可能作为普通选项直接出现**在同批 eventOptions 里，那时它自己的 `selectCost` 照常施加。「被遮罩时不读」是 Explore 这条路径的局部规则，不是对该字段的全局否定——写清楚以免日后被当成冗余删掉。

4. **Explore 条目禁用条目级成本覆盖值**（**T1 定案**）。Explore 的 `lifeSpanCost` 一律取定价表的 Explore 行，内容条目**不得**标偏移 / 覆盖值——否则作者写出的差异化成本本身就是第二种指纹（玩家会记住「这个秘境花 4 点的总是打架」），把上一条封死的泄漏面从另一侧重新捅开。落地为**内容模板加载期校验**，违规条目 `PushError` + `Id`。
   - **代价（明写接受）：** Explore 作者失去一个风味旋钮，无法用成本表达「这个秘境格外凶险」——那类表达改由文案与美术承载。
   - **它是 Explore 独有的例外，不是对定价表通则的收紧。** 其余四类照常「不填即取类型基准，需要时标偏移 / 覆盖」，不受影响。

---

## 具体形态（可 derive 的落地面）

### 1. 钳制表（代码常量，`src/Core/`）

```csharp
internal readonly record struct ClampSpec(
    int  Min,                       // 施加后的下界
    int? Max,                       // null = 无上界
    DefeatReason? DepletionDefeat); // null = 触底不构成终态

// 封闭表；新增一行 = 新增一个资源 element 的完整语义，须与 CostKey 同批评审
internal static readonly IReadOnlyDictionary<CostKey, ClampSpec> ResourceClamps = ...
// LifeSpan  → (0, null, DefeatReason.LifeSpanExhausted)
// Jade      → (0, null, null)
// LifeTotal → (0, null, DefeatReason.LifeTotalExhausted)
// ⟨其余随「cost element 清单（资源族）」逐条补⟩
```

### 2. `ProfileManager.TryApply` 的施加语义（增补，不改签名）

```
对 spec.Elements 中每个 element：
    effective = ApplyModifier(key, baseValue)          ← 既有 modifier pipeline
    raw       = 当前值 + effective
    落值      = Clamp(raw, spec.Min, spec.Max)          ← 新增：查 ResourceClamps
    ※ spec 与快照记录 effective（未截断），不记落值差额
```

- **不新增失败语义**：截断**不**构成 `ApplyResult.Fail`。「全有或全无」约束的是「三个列表是否一起落」，不是「每个 element 是否落满」。
- **不改 `ApplyResult` 的字段**（见 T3）：终态判定读 `Snapshot.Status`，判据即「该字段 == 对应 `ClampSpec.Min` 且 `DepletionDefeat != null`」。

### 3. 终态判定 ①/② 的判据具体化（`life-cycle-service`）

```
终态判定(character):
    foreach (key, spec) in ResourceClamps where spec.DepletionDefeat != null:
        if 读取(character, key) == spec.Min:
            DefeatCharacter(spec.DepletionDefeat.Value); return;
```

替换掉「硬编码检查寿元和 lifeTotal 两个字段」的写法。两处判定共用同一个私有方法。

### 4. API 面增删（`profile-service.md` / `life-cycle-service.md`）

| 项 | 变更 |
|---|---|
| `bool CanAfford(ProfileChangeSpec spec)` | **保留**，失败语义栏补一句「唯一消费点 = Exchange 商店购买；事件推进路径不调用」 |
| `ApplyResult.MissingElement` | **保留** |
| `AdvanceResult.CostRejected` | **删除**（不可达成员） |

### 5. Explore 物化与内容校验

| 检查点 | 时机 | 语义 |
|---|---|---|
| Explore `EventOption.SelectCost` 未引用真身模板成本 | 物化组装后断言 | 必需缺失 → `PushError`（同 `AbilityElements` 恒空的断言处） |
| Explore 模板未设条目级成本覆盖 | 内容模板**加载期**校验 | 必需缺失 → `PushError` + 条目 `Id` |

---

## 后果

- **影响的文档：** `systems/services/profile-service.md`（钳制表 + `CanAfford` 定位）· `systems/architecture.md`（共享核心类型加 `ClampSpec`；`AdvanceResult` 删成员）· `systems/adventure-event/common-properties.md`（成本侧三条待答项收口）· `systems/adventure-event/explore/_index.md`（展示与定价纪律三条）· `systems/adventure-event/exchange/_index.md`（拒绝语义的唯一消费点）· `systems/services/life-cycle-service.md`（终态判定查表化）· `systems/character-profile/currency.md` 与 `life-total.md`（各自补一行钳制与终态语义）。
- **存档 schema：** **不 bump。** 截断只收窄既有字段的取值域（`Status.LifeSpan` 等本就是 `int`，此后恒 ≥ 0），不增删字段；`PastEventEntry` 的两个 spec 字段形状不变（本方案明确它们**不**截断）。
- **迁移：** 无（当前无线上存档）。
- **不跨库。** `backend-design-documents/contracts/profile-sync.md` §5 明写 `characterDiffs` **整体落不透明段、纯透传**，透明字段表只覆盖 `/accountInfo/` · `/playerPowerFragment/` · `/playerPowers[*]/` · `/entitlement/`，**不含任何 `characterProfile` 字段**；后端对不透明段「不递归、不比对、不校验」，因此**不重放 `AppliedChange`**，客户端的截断语义对后端零可见。故本次不写对侧草稿、不产生跨边界承接项。
  - **护栏（建议一并写下）：** 若日后要把寿元 / 灵玉 / 耐久任一字段提进透明档，**必须同批把本方案的钳制语义写进契约**——否则后端复算会在正常账号上误报（它看到的 `AppliedChange` 是未截断值，而快照是截断值）。建议登记进桥接台账 `cross-boundary.md` 作为一条预警条目。
- **`.claude/rules/*`（薄引用，各一句 + 回链，不展开设计）：** `state-save-rules.md` 加「资源 element 的钳制与终态判据查 `ResourceClamps` 表，不散落字段判断」；`data-resource-rules.md` 加 T2 的配套护栏「取值域与终态语义走常量表，平衡数值走 `.tres`」。两处均由 `/sync-knowledge` 落笔，不在本次提炼范围内。

## 备选方案（已考虑并否决）

- **寿元允许为负、终态判据写 `<= 0`。** 否决：Band 2 的精确余量会显示负数（寿元唯一的精确显示通道）；负值落存档使读档校验与履历曲线要处理负轴；换来的「超支量」信息本方案已用「spec 不截断」免费拿到。
- **一条全局通则「资源一律截断到 0」，不建表。** 否决：`PowerFragmentAccumulated` 的 `[0, 10000]` 与带符号的道心 / 煞气 band **各自已是反例**，通则从第一天起就要挂例外；且终态性无处安放，只能继续硬编码。
- **`CanAfford` / `MissingElement` / `CostRejected` 三样一起删。** 否决：前两者有已知的未来消费点（Exchange），删了要原样加回来；后者有已知的**不会有**消费点。「有无消费点」正是三者应当分开处置的判据。
- **Explore 展示真身的 `selectCost`。** 否决：真身成本根本不在施加链路上，展示它等于**展示一个不会发生的扣减**——比泄漏更糟，它是错的。
- **Band 2 下 Explore 一律不显示成本（用不显示回避泄漏）。** 否决：Band 2 的整个设计意图是「让玩家算得出这一步可能是最后一步」，对 Explore 关掉它，恰好在玩家最需要算账时挖一个洞；而泄漏面本方案已由「Explore 自成定价行」封死，不需要牺牲这条。

## 与既有决策的张力

- **与 `mana.md`「不设 `manaLimit` 下界护栏、不做死牌转化」。** 若 `manaLimit` 日后进 `CostKey`，本方案会给它 `Min = 0`。**这不是护栏**——被否决的护栏指的是「保底 ≥ 1」或「高费卡在费用被压低后转化为可用形态」，那两条本方案都不做；`Min = 0` 只是排除负 `manaLimit` 这个无意义状态（每回合恢复到负值无法定义）。**处置（08-16 定案）：不视为对该决策的松动**，在 `mana.md` 补一句澄清（「`Min = 0` 是取值域，不是下界护栏；护栏指的『保底 ≥ 1』与『死牌转化』两条仍然不做」），以免日后被当作不一致而「顺手统一」。
- **与 `data-resource-rules.md`「可调数值不硬编码在系统逻辑里」。** 钳制表落代码常量与之表面冲突。辩护：表里三列**没有一列是平衡旋钮**——`Min` 是取值域、`DepletionDefeat` 是终态语义，改任一列都改变规则而非难度。同类先例是既有的 `(Kind, Scope, Source)` 合法子集表（已明写为「代码常量静态查表」）与 `RngStream` 子流清单（「本 manager 内的常量」）。**处置（08-16 定案）：落代码常量**（T2），并在 `data-resource-rules.md` 的规则摘要里留一句边界——**「取值域与终态语义走常量表，平衡数值走 `.tres`」**，使这条例外可判、不至于被援引去把别的数值也搬进代码。
- **与 `life-total.md`「不设上限截断」。** 不冲突：本方案只给 `Min`，`Max` 对 `LifeTotal` 明确为 `null`。写进草稿以免日后误读。

## 前置依赖

- **「cost element 清单（资源族）」未定** → 钳制表只能先填 `LifeSpan` / `Jade` / `LifeTotal` 三行 + 逐条配表的**形态**。形态可立即定稿并 derive，行数随该问答定逐条补。
- **道心 `Faith` / 煞气 `MaleficQi` 是否进 `CostKey`** → 决定表中是否出现双向区间行。**不阻塞本方案**——它们的存在只是「必须配表、不能定通则」这条结论的论据之一，即使最终不进 `CostKey`，`PowerFragmentAccumulated` 的 `[0, 10000]` 单独也足以支撑该结论。
- **Exchange 专场未开** → `CanAfford` 的**呈现形态**（灰显 / 弹窗 / 价格标注）待该专场；本方案只定「保留它、唯一消费点在 Exchange」。
- **`lifeSpanCost` 定价表取值（ch1 数值标杆专场）** → Explore 行**填多少**待定；本方案只定「Explore 自成一行、不由真身推导」。

## 已定案的取向（2026-08-16 · 用户裁决，一律取推荐项）

> 本节保留每一项的**否决理由与代价**——定案后被丢弃的那半边正是日后最容易被无意重新提出的东西。

- **T1 · Explore 条目禁用条目级成本覆盖值。** 一律取定价表的 Explore 行，加载期校验 `PushError`。理由：条目级差异化成本会成为真身指纹的第二个来源，而 Explore 的全部设计价值就在「进去才知道」。
  - **代价（明写接受）：** Explore 作者失去一个风味旋钮，「这个秘境格外凶险，代价更高」只能由文案与美术承载。
  - **已否决：** 允许覆盖但要求同一 location / 篇章内取值齐平——效果等价，却**无法机械检查**、只能靠作者自律，而本库对内容侧一贯的收口方式是「能加载期校验的就不留自律」。

- **T2 · 钳制表落代码常量静态表，不落 `.tres`。** 三列（`Min` / `Max` / `DepletionDefeat`）没有一列是平衡旋钮；与既有的 `(Kind, Scope, Source)` 合法子集表、`RngStream` 子流清单同类。
  - **已否决：** 落 `.tres` 使区间可热更。**代价过高**——一次 overlay 热更即可改写终态判据（把 `LifeSpan` 的 `Min` 调成 -50 就等于取消了寿元死亡），而这类改动应当走版本发布而非热更。
  - **配套护栏：** 在 `data-resource-rules.md` 留一句可判的边界——「**取值域与终态语义走常量表，平衡数值走 `.tres`**」，使本例外不被援引去把别的数值搬进代码。

- **T3 · `ApplyResult` 不新增「触底 element」字段。** 终态判定读 `Snapshot.Status`，判据是「== 对应 `ClampSpec.Min`」；「本来就是 0 还在推进」在规则层不可达（归 0 当场 `defeated`），故触底与既有值无须区分。最小扰动，不动既有形状。
  - **已否决：** 新增 `IReadOnlyList<CostKey> Depleted`。收益仅限日志与诊断，代价是每次 `TryApply` 多一次堆分配——而 `ApplyResult` 是 `readonly record struct`（零堆分配）正是既定纪律。
  - **若日后确需触底诊断**，正确的加法是在 `ProfileManager` 内部打一行 `[ProfileManager-TryApply] depleted key=LifeSpan` 的可追溯性日志（与既有的 `AbilityChangeElement` 日志同一档），**不是**改结果类型的形状。

- **附 · mana 张力的处置：不视为松动。** `manaLimit` 若进 `CostKey`，其 `Min = 0` 是取值域而非下界护栏；被否决的两条护栏（保底 ≥ 1、死牌转化）仍然不做。在 `mana.md` 补一句澄清即可。
