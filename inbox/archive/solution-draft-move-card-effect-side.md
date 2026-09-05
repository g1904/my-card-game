---
type: solution-draft
date: 2026-09-01
question: `MoveCardEffect` 没有方位声明，`ADR-0119` 断言的「从对手抽牌堆移牌」在字段面无法表达——补 `Side` / 复用 `EffectScope` / `From` 恒作用己方，三种收法择一。
source: open-questions/01-combat.md → 结构与配置的残留
targets: systems/character-profile/deck/common-properties.md（原语表第 7 行 · 加载期校验表）· systems/character-profile/deck/_index.md（第一层原语清单的 `MoveCard` 签名与其下的说明条）· systems/services/combat-service.md（推论 ④ 的 `MoveCard` 表述，仅措辞对齐）
status: distilled
reviewed: 2026-09-02 批量评审 —— 草稿自陈无取向项；按推荐形态执行：补单格 `Side : SideConstraint`，加载期校验新增第 21 条（不插队为 20，因 derive 就绪度小节逐字引用了「第 20 条」）。
distilled-to: handoffs/2026-09-02-move-card-effect-side.md
---

# 方案草稿 — `MoveCardEffect` 的方位声明

## 问题

`ADR-0119`（Accepted，2026-08-27）的后果段明写：

> `MoveCardEffect` 的 `From` 可取对手抽牌堆，使「削减对手抽牌堆」结构上成立。

但 `deck/common-properties.md` 的首批原语表给 `MoveCardEffect` 的 `[Export]` 只有五格 —— `From : CardZone` · `To : CardZone` · `Insert : InsertPosition` · `Count : int` · `Selection`，**没有 `Side : SideConstraint`**。同表另外五个带方位语义的原语（`ModifyMomentumEffect` / `DrawEffect` / `DiscardEffect` / `ModifyManaEffect` / `ApplyStateEffect`）逐个都有 `Side`。

后果是：一条 `MoveCardEffect` 在 `.tres` 里根本写不出「作用于对手的区」这件事，`ADR-0119` 的那句断言在字段面落空。

它的严重性不在于少一格，而在于**位置**：`/assess-derive-readiness` 2026-08-30 全量评估把它列为**本次唯一一处结构面倒退**，并因此给 derive 队列加了两条排除指令 —— 第 10 步（`deck/common-properties.md`）须显式排除 `MoveCardEffect` 一行、第 23 步（`combat-service.md`）须排除 `MoveCard` 的方位面。不关掉它，第一批 `.tres` 会把一个错的字段面冻进内容层；而「三格取池余量」那类问题**只欠数字、不欠结构**，本条是少数几个真正卡结构的之一。同一份评估把它列为最短解锁路径第 4 项，判语是「成本极低、且它是唯一一处挡在已就绪切片内部的结构缺口」。

## 约束（来自既有设计）

1. **`SideConstraint { Any = 0, Self = 1, Opponent = 2 }` 一律相对施放者（`controllerSide`）解析，枚举里不放绝对方取值。** 这是 `CardData.Pool = Both` 的直接推论 —— 同一张牌可能同时出现在玩家与敌人卡组里。→ `deck/common-properties.md`「声明侧的形态」
2. **`EffectScope(SideConstraint, EntryFilter)` 是静止式修正 `StaticModifierData.Scope` 的那一格**，其定义是「求值那一刻按筛选条件动态匹配、永不需要玩家输入、不落存档」。`EffectData` 的其余原语上**它恒无意义**（`deck/_index.md` 明写：「`TargetSlots` 对它恒空、`EffectScope` 对其余原语恒无意义」）。
3. **一场战斗的卡牌集合是闭集，且闭集是按侧成立的。** `sides[]` 各自持有 `drawPile` / `hand` / `discardPile` / `instances`；读档校验 ④ = **三区 `Id` 序列的并集 ≠ `instances` 全集 → `PushError`**。`CardInstanceId` 的确定性发号亦按侧分前缀（`c#0` 先、`e#0` 后）。→ `ADR-0041`、`systems/services/combat-service.md`
4. **`EffectData` 恒不落存档、恒不进 diff** —— 它是内容侧 `Resource`，经 `CardId` / `abilityId` 解析而来。→ `deck/common-properties.md`「存档面」
5. **可加性纪律：新增原语 / 新增一格 = 纯加法，不编辑任何既有原语的文件、不编辑任何 switch。** 加载期校验按子类逐条挂。→ 同上「扩展方式」
6. **对手手牌不可见是一条已被封住的信息面。** `SideSnapshot.HandCardInstanceIds` 敌方恒为空、`HandCount` 只给计数 ⇒「指定对手某张手牌」不可能成为合法目标（既有校验：`TargetSlot.Kind == HandCard` 且 `Side != Self` → `PushError`）。跨方的**点选**因此在本库是被结构性关掉的。
7. **`ADR-0119` 的护栏落在载体消耗性与 `Count` 有限上**，不落在「能不能移」上；「整堆 / 全部」形态硬禁。

## 建议方案

### 子项 1 —— 补一格 `Side : SideConstraint`，与同表五个原语逐字同构

`[既有推演]`

三种收法里，**补 `Side` 是唯一一个不与既有分工相抵的**：

- **复用 `EffectScope` 不成立。** 约束 2 明写 `EffectScope` 是静止式修正的那一格、对其余原语恒无意义；`MoveCardEffect` 是结算时执行的原子操作（第一层），不是求值瞬间被读取的静止式修正（第三层）。把它挂上去等于让一个字段承载两族语义，与「`ManaCost` 不进 `ProfileChangeSpec`」「`KeywordRef.Amount` 不进 `counters`」被否决的理由逐字同构。
  （分片里提到「`DiscardEffect` 的 `Random` 分支复用了 `EffectScope`」—— 那句话在原文里指的是**作用域式语义**：无 `TargetRef`、不产生目标交互、不 fizzle；`DiscardEffect` 自己的方位仍由它**独立的 `Side` 一格**承担。这正是本方案要照抄的形状。）
- **`From` 恒作用己方不成立。** 它与 `ADR-0119` 后果段的明文断言直接冲突，收掉的是一整条已被 Accepted 的设计面（「削减对手抽牌堆」），且要回头改一份 Accepted 的 ADR —— 代价远高于补一格。

字段形态：

```csharp
[GlobalClass] public sealed partial class MoveCardEffect : EffectData
{
    [Export] public SideConstraint  Side   { get; set; }   // 新增；相对 controllerSide 解析
    [Export] public CardZone        From   { get; set; }
    [Export] public CardZone        To     { get; set; }
    [Export] public InsertPosition  Insert { get; set; }   // 仅 To == DrawPile 有意义
    [Export] public int             Count  { get; set; }
    [Export] public /* 既有 */      Selection { get; set; }
}
```

- **不设哨兵、不设特殊默认值** —— 取 `[Export]` 枚举的天然默认 `Any = 0`，与同表五个原语完全同款。给它单开一个 `Unspecified` 哨兵（或单开一条「`Side == Any` 时 `PushWarning`」）会让六个方位原语里有一个长得不一样，而漏填风险在那五个上是同样存在且已被接受的；一致性优先。

### 子项 2 —— 单格 `Side`，两端同侧；**不**拆成 `FromSide` / `ToSide`

`[既有推演]`

一格 `Side` 同时解析 `From` 与 `To`，语义 = 「在**该侧**的两个区之间搬 `Count` 张」。`Side = Opponent` + `From = DrawPile` + `To = DiscardPile` 即 `ADR-0119` 要的「削减对手抽牌堆」。

**跨方转移（从对手抽牌堆拿一张进自己手牌）由此在结构上写不出来，这是有意的**，理由是约束 3：

- 闭集不变式是**按侧**成立的（`sides[].instances` 各一份，读档校验 ④ 逐侧比对）。跨方搬运会让一枚 `e#` 前缀的实例出现在玩家侧的三区序列里，读档校验 ④ 当场误报，除非把它改写成跨侧全集比对 —— 那是动存档不变式，与「补一格」不在同一个成本量级。
- 与 `ADR-0119` 自身「首批只开确定性的顶 / 底两位，不开随机位」的保守取向同向：先开最小的那一步。
- **日后要开是纯加法**：加一格 `ToSide`（默认 = `Side`）+ 一次闭集不变式的重估，零存档迁移压力（`EffectData` 不落存档）。这与「一槽位 = 恰好一个目标，日后真需要多选时补一个字段是纯加法」的既定处置同款。

沿用「静止式异能在结构上就装不下原子操作」那条风格：**纪律由类型形状承担，不必再写一条校验。**

### 子项 3 —— 新增一条加载期校验，既有各条一字不动

`[既有推演]` + `[通行做法]`

| # | 规则 | 违反时 |
|---|---|---|
| 新增 | `MoveCardEffect`：`Selection == Chosen` 且 `Side != Self` | `PushError`，带宿主 `Id` 与 `.tres` 路径 —— 对手的区玩家看不见（约束 6），点选无从发起；跨方搬运一律走 `Random` |

- **既有第 6 条（`MoveCardEffect.Count < 1` → `PushError`）与第 8 条（`From == To` 且 `To != DrawPile` → `PushError`）原样保留、语义不变。** 单格 `Side` 使两端恒同侧 ⇒ 第 8 条的 `From == To` 判定不需要看 `Side`，不存在「同区但不同侧」这一情形。
- **本条按最严收口。** 本库当前只对**手牌**明确了敌方不可见（`HandCardInstanceIds` 恒空），对手弃牌堆的可见性无明文；把「跨方即不得点选」一次收死，日后若定案弃牌堆双方可见，放宽成 `Side != Self 且 From ∈ {DrawPile, Hand}` 是纯加法。
- 不新增任何 `PushWarning` 清单项 —— 「载体消耗性」那条护栏已由 `ADR-0119` 落在载体类型上，不需要在本原语上重复。

### 子项 4 —— 存档面零影响、内容面零迁移、derive 排除面当场解除

`[既有推演]`

- **存档：零新增字段、空迁移、不 bump `schemaVersion`、后端零影响。** `EffectData` 及其全部子类是内容侧静态定义，经 `CardId` / `abilityId` 解析，恒不落 `ActiveCombat`（约束 4）。存档记的仍只是三区 `Id` 序列 —— 一次 `MoveCard` 改变的是序列内容，而这条通道早已存在。
- **内容迁移：零。** 关键字清单与次类型清单均已归零、`content/card/` 尚无条目 ⇒ 没有任何已写就的 `.tres` 需要补填这一格。**这一格的成本此刻恒为零**，与 `RealmArtworks` / 战场条目 `amount` 那两处「在内容清单为空时先行铺下」同一条取舍。
- **derive 队列：** 关闭后第 10 步（`deck/common-properties.md`）不再需要「显式排除 `MoveCardEffect` 一行」、第 23 步（`combat-service.md`）的排除面减一项 `MoveCard` 的方位面 —— 与 `open-questions.md`「最短解锁路径」第 4 项的判语一致。

## 具体形态（可 derive 的落地面）

**① `deck/common-properties.md`「首批原语八个」表第 7 行的 `[Export]` 参数列**改为：

> `Side` · `From : CardZone` · `To : CardZone` · `Insert : InsertPosition { Top, Bottom }` · `Count : int` · `Selection`

语义列追加一句：**`Side` 相对 `controllerSide` 解析，`From` 与 `To` 恒落在同一侧；跨方转移不可表达（闭集不变式按侧成立）。**

**② 同文档「加载期校验（本节新增；既有各条原样保留）」表追加一行**（子项 3 的那条）。

**③ `deck/_index.md`「第一层 · `EffectData` 的原子操作清单」的签名**由

> `MoveCard(From, To, InsertPosition, Count, Selection)`

改为

> `MoveCard(Side, From, To, InsertPosition, Count, Selection)`

并在其下「`MoveCard` 是闭集内的流转」条内追加一句：**方位由 `Side` 一格声明，两端同侧；「削减对手抽牌堆」= `Side = Opponent` + `From = DrawPile` + `To = DiscardPile`。**

**④ `combat-service.md` 推论 ④** 仅措辞对齐（把「卡牌效果可经 `MoveCard` 把有限张牌置于抽牌堆顶 / 底」补足为「可对声明的一侧施行」），**不改任何机制**。

**⑤ `ADR-0119` 不动。** 它的后果段那句断言正是被本方案兑现的对象，无需修订、无需新 ADR —— 本条是原语表的一格字段补全，不是一次决策变更。

## 后果

- 受影响文档：`deck/common-properties.md`（两处）· `deck/_index.md`（一处）· `combat-service.md`（一句措辞）。
- 存档 schema：**零增量、零迁移、不 bump**；后端零配合。
- 内容层：**零条目需要改写**（当前 `content/card/` 为空）。
- derive：第 10 步排除面清零、第 23 步减一项。
- 新增的设计表达面：「削减对手抽牌堆」「让对手把牌堆顶压到底」这类效果自此可写；跨方**转移**仍不可写（有意）。

## 备选方案（已考虑并否决）

- **复用 `EffectScope` 承载方位** — 否决：`EffectScope` 是静止式修正专用的作用域格（第三层），`MoveCardEffect` 是结算时执行的原子操作（第一层）；混用会让一个字段承载两族语义，与本库两次同款否决（`ManaCost` 不进 `ProfileChangeSpec`、`KeywordRef.Amount` 不进 `counters`）理由逐字同构。且 `EffectScope` 带 `EntryFilter`，而抽牌堆里的牌不是战场条目，那一半恒无对象。
- **`From` 恒作用于己方（不补格）** — 否决：直接推翻 `ADR-0119` 后果段的明文断言，收掉一整条已 Accepted 的设计面，且需回改一份 Accepted 的 ADR；而补一格的成本此刻为零。
- **拆成 `FromSide` / `ToSide` 两格，开放跨方转移** — 否决：跨方搬运会让一枚 `e#` 实例落进玩家侧三区序列，读档校验 ④（三区并集 = `instances` 全集）当场误报，须重写闭集不变式；与 `ADR-0119` 首批保守取向相反。日后要开是纯加法。
- **给 `SideConstraint` 在本原语上单开哨兵 / 给 `Side == Any` 加一条 `PushWarning`** — 否决：六个方位原语里只有一个长得不一样；漏填风险在另五个上同样存在且已被接受，一致性优先。
- **不动字段，改在 `TargetSlots` 里表达方位** — 否决：`MoveCardEffect` 的 `Random` 分支明确不产生目标交互，而 `TargetSlots` 是「结算那一刻锚定到具体条目」的目标面；用目标表达作用域正是「目标 / 作用域必须分开建模」这条承重切分要消灭的写法。

## 与既有决策的张力

**无。** 本方案不要求任何既有决策松动：`ADR-0119` 被兑现而非被修改，`ADR-0041` / `ADR-0052` 的闭集与不重洗纪律原样成立（跨方转移的否决恰恰是为了守住 `ADR-0041` 的按侧闭集），`EffectScope` / `TargetSlots` 的分工不动。

## 前置依赖

**无。** 本条不依赖任何仍待答的问题：

- 「一张牌该产多少道念」等量纲问题只影响 `Count` 的取值编排，不影响字段形态。
- 「起始卡组的具体内容」是首批原语清单最终确认的切入点（`deck/common-properties.md` 明写），但本条是给**已在清单内**的原语补一格必需参数，不属于「新增 / 删除原语」那一类决定，不必等 starter deck。

## 仍需用户决定

**无取向项。** 三种收法之间的取舍可由既有分工（`EffectScope` 归静止式修正）与既有断言（`ADR-0119` 后果段）机械判定；单格 vs 两格由存档闭集不变式（读档校验 ④）判定，且两格形态是纯加法、日后可开。若用户对「跨方**转移**（偷牌）是否应作为一条设计面永久关闭」另有取向，可在评审时直接推翻子项 2 —— 但那需要连带重估按侧闭集不变式，不宜与本条同批。
