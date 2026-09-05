# `MoveCardEffect` 补一格 `Side : SideConstraint`（两端同侧 · 一条新校验）

- id: 2026-09-02-move-card-effect-side
- date: 2026-09-02
- topic: systems/character-profile/deck/common-properties.md · systems/character-profile/deck/_index.md · systems/services/combat-service.md
- status: distilled
- distilled-to: systems/character-profile/deck/common-properties.md, systems/character-profile/deck/_index.md, systems/services/combat-service.md

## Intent（distilled）

首批原语表里，`MoveCardEffect` 是六个带方位语义的原语中**唯一一个没有 `Side` 格**的（`ModifyMomentum` / `Draw` / `Discard` / `ModifyMana` / `ApplyState` 逐个都有）。后果是「作用于对手的区」这件事在 `.tres` 里根本写不出来，而 `ADR-0119` 的后果段明写「`From` 可取对手抽牌堆，使『削减对手抽牌堆』结构上成立」—— 那句断言在字段面上落空。本次**补一格 `Side : SideConstraint`**，把既有断言坐实。

### 子项 1 —— 与同表五个原语逐字同构

`[Export] public SideConstraint Side { get; set; }`，相对 `controllerSide` 解析，取枚举天然默认 `Any = 0`。**不设哨兵、不为 `Side == Any` 单开 `PushWarning`** —— 那会让六个方位原语里有一个长得不一样，而漏填风险在另五个上同样存在且已被接受；一致性优先。

两条备选被否决：

- **复用 `EffectScope` 承载方位** —— `EffectScope(SideConstraint, EntryFilter)` 是静止式修正 `StaticModifierData.Scope` 专用的作用域格（第三层，求值瞬间被读取），`MoveCardEffect` 是结算时执行的原子操作（第一层）；混用会让一个字段承载两族语义，与「`ManaCost` 不进 `ProfileChangeSpec`」「`KeywordRef.Amount` 不进 `counters`」被否决的理由逐字同构。且 `EffectScope` 带 `EntryFilter`，而抽牌堆里的牌不是战场条目，那一半恒无对象。
- **`From` 恒作用己方（不补格）** —— 它收掉一整条已被 Accepted 的设计面，且要回头改一份 Accepted 的 ADR，代价远高于补一格；而补格的成本此刻恒为零（`content/card/` 尚无条目）。

### 子项 2 —— 单格 `Side`，两端同侧；不拆 `FromSide` / `ToSide`

一格 `Side` 同时解析 `From` 与 `To`，语义 = 「在该侧的两个区之间搬 `Count` 张」。`Side = Opponent` + `From = DrawPile` + `To = DiscardPile` 即「削减对手抽牌堆」。

**跨方转移（从对手抽牌堆拿一张进自己手牌）由此在结构上写不出来，这是有意的：** 闭集不变式是**按侧**成立的（`sides[].instances` 各一份，读档校验 ④ 逐侧比对三区 `Id` 序列的并集）。跨方搬运会让一枚 `e#` 前缀的实例出现在玩家侧的三区序列里，读档校验 ④ 当场误报，除非改写成跨侧全集比对 —— 那是动存档不变式，与「补一格」不在同一个成本量级。日后要开是纯加法：加一格 `ToSide`（默认 = `Side`）+ 一次闭集不变式重估，零存档迁移压力（`EffectData` 不落存档）。

### 子项 3 —— 新增一条加载期校验，既有各条一字不动

`MoveCardEffect`：`Selection == Chosen` 且 `Side != Self` → `PushError`，带宿主 `Id` 与 `.tres` 路径。理由：对手的区玩家看不见（对手手牌不可见已被 `SideSnapshot.HandCardInstanceIds` 恒空封住），点选无从发起；跨方一律走 `Random`。

- 既有第 6 条（`MoveCardEffect.Count < 1`）与第 8 条（`From == To` 且 `To != DrawPile`）原样保留、语义不变 —— 单格 `Side` 使两端恒同侧 ⇒ 不存在「同区但不同侧」这一情形。
- **本条按最严收口。** 本库当前只对手牌明确了敌方不可见，对手弃牌堆的可见性无明文；把「跨方即不得点选」一次收死，日后若定案弃牌堆双方可见，放宽成 `Side != Self 且 From ∈ {DrawPile, Hand}` 是纯加法。

### 子项 4 —— 存档 / 内容 / 后端三面零影响

`EffectData` 及其全部子类是内容侧静态定义，经 `CardId` / `abilityId` 解析，恒不落 `ActiveCombat` ⇒ **零新增存档字段、空迁移、不 bump `schemaVersion`、后端零配合**。存档记的仍只是三区 `Id` 序列，一次 `MoveCard` 改变的是序列内容，而这条通道早已存在。内容侧 `content/card/` 尚无条目 ⇒ **零 `.tres` 需要补填这一格**，这一格的成本此刻恒为零，与 `RealmArtworks`、战场条目 `amount` 那两处「在内容清单为空时先行铺下」同一条取舍。

## Clarifications

- **三种收法的取舍 → 无取向项，按方案推荐执行**（`EffectScope` 归静止式修正、`ADR-0119` 后果段的明文断言，两条即可机械判定）。用户评审未追加任何标注。
- **`MoveCardEffect.Selection` 的枚举类型本次不指名、不改名、不新造** —— 原语表第 7 行现有措辞保留，新增校验照现有措辞写 `Selection == Chosen`（采纳标准默认：最小扰动，改名会连带改第 3 行已成文措辞、收益为零）。
- **`ADR-0119` 不动、不新开 ADR** —— 本条是原语表补一格必需参数，它的断言被兑现而非被推翻（采纳标准默认）。
- **`systems/balance.md` 疲劳段的 `MoveCard` 表述不改** —— 单格 `Side` 语义下该句仍然成立（区是抽牌堆、侧由 `Side` 声明），无实质失真（采纳标准默认）。

## Open questions

- **跨方转移（「偷牌」）是否作为一条设计面永久关闭** —— 本次按「结构上不可表达」落笔，理由是按侧闭集不变式；日后若要开放，须连带重估该不变式，不宜与本条同批。

## Notes / triage

- 路由：`deck/common-properties.md`（原语表第 7 行的 `[Export]` 列 + 语义列；加载期校验表追加一行）· `deck/_index.md`（第一层原语清单的 `MoveCard` 签名 + 其下说明条）· `systems/services/combat-service.md`（推论 ④ 的一句措辞对齐，不改机制）。
- `decisions/` 本次零改动。存档 / 内容 / 后端零改动。
