# ADR-0121 — `ItemData` 的使用效果面按世界分两格，移除 `Abilities`，新增 `MaxUsesPerCombat`

- **状态：** Accepted
- **日期：** 2026-08-28
- **来源：** handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md

## 背景

效果原语语法定案（`ADR-0115`）后，道具的效果落点成为一处遗留缺口：`ItemData` 上只有一格 `Abilities`，而三档异能在道具上全部不成立。同时 `Charges` 被当成本场配额上限使用，使「一件无限法宝每场限用一次」在结构上写不出来。

## 决策

**使用效果面按世界分两格**：`CombatUseEffects : EffectData[]`（`UsableScene ∈ { InCombat, Both }` 时必非空）· `OutOfCombatUseOutcome : ProfileChangeSpec`（`∈ { OutOfCombat, Both }` 时必非空）。战斗外只开 `Elements` / `CodexElements` / `Stats` 三列，其余各列恒空并配一条加载期校验；表达力上界取**恒定、无条件、无随机**；**战斗外不设目标面**。

**战斗外使用的门面 = `UseItemOutOfCombat(AbilityScope scope, string itemId)`，落 profile-service，一次组装、一次 `TryApply`。**

**新增 `MaxUsesPerCombat : int`**（`-1` 不限 · `>= 1` 配额 · `0` 未定义故加载期拦），与 `AbilityData.MaxActivationsPerCombat` 逐字同构；玩家侧本场配额与 `Charges > 0` 两闸**取更严者**，敌人侧另受 `UsesThisCombat < Charges` 约束。

**`ItemData` 移除 `Abilities` 一格**；`CapabilityManager` 因此对道具两类恒为空集。

**战斗外触发点首版不开**：`PowerData.UsableScene == OutOfCombat` 且 `Abilities` 含 `Kind == Triggered` → `PushError`；`Both` 档不受限。连带 `PowerData` 的「`Abilities` 至少一个」改写为「`Abilities` / `GrantedFlags` / `Modifiers` 三格至少一格非空」。

**异能载体族枚举由 `AbilityKind` 改名为 `AbilityCarrierKind { Power, Item }`**（成员名一字未改、类型名不参与序列化 ⇒ 零存档迁移）。

字段表与 13 条加载期校验 → `systems/character-profile/item/_index.md`。

## 理由

**两格而非一格的三条依据**：执行引擎不同（战斗内经栈与五阶段流水线，战斗外经 `TryApply` 的单点事务）· 值域不相交（八原语写道念 / mana / 战场条目 / 三区牌 / `counters`，`ProfileChangeSpec` 没有一列能表达「产 3 点道念」，反之亦然）· 加载期可校验性（值域混装后校验退化为 `switch`）。`Both` 档两格皆填，因为那本来就是两条不会同时执行的效果。

**表达力上界取最窄**：只有恒定、无条件、无随机能让使用结果在按下之前原样呈现给玩家，而储物袋详情卡片的形态本就是「看清楚再按」。条件门与「道具触发一个事件」日后要开都是纯加法。

**战斗外不设目标面**：目标的定义是结算那一刻由 `TargetRef` 锚定到具体条目，而战斗外没有战场；`ProfileChangeSpec` 的每一列都是按枚举键 / 内容 `Id` 索引的形状，结构上装不下 `TargetRef`。

**单一入口一次事务**：分两次调用即「先扣次数后产出失败」这种半套写入。

**`Charges` 当不了本场配额**：它是 Profile 侧的总剩余次数（即时写、跨轮回持久），两者是不同的量。

**移除 `Abilities` 而非保留 + 校验恒空**：三档异能在道具上全部不成立（启动式按战场条目寻址而道具没有 `entryId`；静止式的生效判据是「一进场即生效」而道具从不进场；触发式的注册面归战场而道具从不注册）。一个从不触发的机制是纯负债，且它**能上线、线上不可见** ⇒ 必须提到「写不出来」这一级。

**载体族改名**：`{ Power, Item }` 说的是「挂在哪一族载体上」，而异能三分 `{ Static, Activated, Triggered }` 说的是「怎么生效」——后者才是 `Kind` 的自然所指。改动面也不对称：三分枚举被多处引用，载体族只被一格 element 与几张分域表引用。

## 备选方案

- **单格效果面（战斗内外共用）** — 否决：三条依据见上。
- **战斗外效果开条件 / 随机 / 目标面** — 否决：使用结果无法在按下之前原样呈现。
- **次数扣减塞进 `ProfileChangeSpec` 的资源列** — 否决：要给 `CostKey` 新增一个成员，破坏它与两层 Profile 字段的双向满射，且该成员没有取值域 / 终态语义可填。
- **保留 `ItemData.Abilities` + 加一条「恒空」校验** — 否决：整格移除才是「写不出来」这一级。
- **拿 `Charges` 兼作本场配额** — 否决：两者是不同的量，兼用会让一类设计写不出来。
- **改 `AbilityData.Kind` 而不改载体族枚举名** — 否决：改动面不对称，且 `Kind` 的自然所指正是三分。

## 后果

- `systems/character-profile/item/_index.md` 是效果面与配额面的权威；`systems/services/profile-service.md` 承载门面与 `CapabilityManager` 对道具的空集判定。
- **存档面零新增字段**、不 bump `schemaVersion`；`CombatItemSave(ItemId, UsesThisCombat)` 结构原样，只是比对的上限换了一格。
- 连带：`Sorcery` 不得带任何异能（禁令由「不得带 `Static` / `Activated`」扩为全禁），`PushWarning` 改为只判 `OnPlay` → `ADR-0115`。
- 战斗外那一半的表达面收敛为 `GrantedFlags` + `Modifiers` 两条通道 → `ADR-0116`。日后开战斗外时点是新增一族时点 + 对应广播点，纯加法。
- **载体族改名的机械替换面超出本次提炼所触及的文档**，仍需一轮全库扫尾。
- 待答：用道具产生的栈条目落在 `StackEntryKind` 哪个成员上。
