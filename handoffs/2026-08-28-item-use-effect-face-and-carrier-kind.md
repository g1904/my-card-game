# 道具的使用效果面、本场配额格、异能载体族改名与战斗外触发式禁令

- id: 2026-08-28-item-use-effect-face-and-carrier-kind
- date: 2026-08-28
- topic: systems/character-profile/item · systems/player-profile/player-item · systems/character-profile/deck · systems/character-profile/power · systems/player-profile/player-power · systems/services/combat-service · systems/services/profile-service · systems/architecture · systems/adventure-event/exchange · content
- status: distilled
- distilled-to: systems/character-profile/item/_index.md, systems/character-profile/item/common-properties.md, systems/player-profile/player-item/_index.md, systems/character-profile/deck/common-properties.md, systems/services/combat-service.md, systems/architecture.md, systems/services/profile-service.md, systems/character-profile/power/_index.md, systems/character-profile/power/common-properties.md, systems/player-profile/player-power/_index.md, systems/player-profile/player-power/common-properties.md, systems/adventure-event/exchange/_index.md, content/_index.md, decisions/ADR-0099-combat-holdings-two-tiers.md

> **一行摘要：** 效果原语语法本体已定，本次补它剩下的四处机械缺口——给 `ItemData` 开「战斗内 `EffectData[]` / 战斗外 `ProfileChangeSpec`」两格使用效果面并移除 `Abilities` 一格、给道具补 `MaxUsesPerCombat` 本场配额格、把 `Sorcery` 的异能禁令补全、把撞名的两个 `AbilityKind` 拆开；外加一条「战斗外触发式不开」的加载期校验与一批台账对账。存档 schema 一格不加。

## Intent（distilled）

### 1. `ItemData` 的使用效果面 = 按世界分两格

| 格 | 类型 | 何时必须非空 |
|---|---|---|
| `CombatUseEffects` | `EffectData[]` | `UsableScene ∈ { InCombat, Both }` |
| `OutOfCombatUseOutcome` | `ProfileChangeSpec`（内容侧模板） | `UsableScene ∈ { OutOfCombat, Both }` |

两格而非一格的三条依据：**执行引擎不同**（战斗内经栈与五阶段流水线，战斗外经 `ProfileManager.TryApply` 的单点事务）· **值域不相交**（八原语写道念 / mana / 战场条目 / 三区牌 / `counters`，`ProfileChangeSpec` 的各列没有一列能表达「产 3 点道念」，反之亦然）· **加载期可校验性**（两条 `LifeSpan` 校验落成一行读取，值域混装后校验退化为 `switch`）。`Both` 档两格皆填，因为那本来就是两条不会同时执行的效果。

`UseItem(itemId, targets)` 的 `targets` 来源就此闭合：长度 = `Σ CombatUseEffects[i].TargetSlots.Length`，顺序即扁平化 `slotIndex`，入栈即 `targetState = Resolved`。

### 2. 战斗外使用效果 = 内容侧的 `ProfileChangeSpec` 模板，只开三列

开放 `Elements` / `CodexElements` / `Stats`，其余各列恒空并配一条加载期校验。表达力上界取**恒定、无条件、无随机**：只有它能让使用结果在按下之前原样呈现给玩家，而储物袋详情卡片的形态本就是「看清楚再按」；条件门与「道具触发一个事件」两条日后要开都是纯加法。

战斗外**不设目标面**：目标的定义是结算那一刻由 `TargetRef` 锚定到具体条目，而战斗外没有战场；`ProfileChangeSpec` 的每一列都是按枚举键 / 内容 `Id` 索引的形状，结构上装不下 `TargetRef`。

### 3. 战斗外使用的门面 = 单一入口、一次事务

`ApplyResult UseItemOutOfCombat(AbilityScope scope, string itemId)`，落 profile-service。内部**一次**组装「战斗外产出 + 该道具的次数扣减 +（事件之外时）痕迹」，交**一次** `TryApply`。分两次调用即「先扣次数后产出失败」这种半套写入。次数扣减与痕迹两列的定义本体归 `systems/services/profile-service.md`。

### 4. 道具的战斗内配额面 = 新增 `MaxUsesPerCombat`

`Charges` 是 Profile 侧的总剩余次数（即时写、跨轮回持久），拿它当本场配额上限会让「一件无限法宝每场限用一次」在结构上写不出来。新增 `MaxUsesPerCombat : int`，与 `AbilityData.MaxActivationsPerCombat` 逐字同构（`-1` 不限 · `>= 1` 配额 · `0` 未定义故漏填须在加载期被拦）。两侧的闸各自成立、取更严者：玩家侧本场配额 **且** Profile 侧 `Charges > 0`；敌人侧没有 Profile，故它另受 `UsesThisCombat < Charges` 约束。

### 5. `ItemData` 移除 `Abilities` 一格

三档异能在道具上全部不成立：启动式按战场条目寻址而道具没有 `entryId`；静止式的生效判据是「一进场即生效」而道具从不进场；触发式的注册面归战场而道具从不注册。一个从不触发的机制是纯负债，且它现在能上线、线上不可见 ⇒ 必须提到「写不出来」这一级，移除该格即是。

### 6. `Sorcery` 不得带任何异能

触发式异能须在战场上注册才可能被命中，而 `Sorcery` 结算后进弃牌堆、从不落场。禁令由「不得带 `Static` / `Activated`」扩为「不得带任何异能」，与 `Affliction` 那条合并同形；连带把「`Sorcery` 且 `OnPlay` 与 `Abilities` 皆为空 → `PushWarning`」改为只判 `OnPlay`。法术的一次性效果本就走 `OnPlay`，不收窄任何设计面。

### 7. 异能载体族枚举改名为 `AbilityCarrierKind`

`{ Power, Item }` 说的是「这条能力挂在哪一族载体上」，而异能三分 `{ Static, Activated, Triggered }` 说的是「这条异能怎么生效」——后者才是 `Kind` 的自然所指。同一份架构文档里与它并列的 `AbilityScope` 注释写的是「能力的生命周期层」，`CarrierKind` / `Scope` 读起来因此是一致的「族 / 层」二维。改动面也不对称：三分枚举被 `AbilityData.Kind`、XOR 校验、战斗侧可启动判定多处引用，载体族只被一格 element 与几张分域表引用。**成员名 `Power` / `Item` 一字未改、类型名不参与序列化 ⇒ 零存档迁移。**

### 8. 战斗外触发点首版不开

时点常量表首批十个全部是战斗内时点，战斗外一处广播点都没有。故 `PowerData.UsableScene == OutOfCombat` 且 `Abilities` 含 `Kind == Triggered` → `PushError`；`Both` 档不受此限。战斗外那一半的表达面收敛为 `GrantedFlags` + `Modifiers` 两条通道。日后要开是新增一族时点 + 对应广播点，纯加法。

同批推出的一条连带：`PowerData` 的「`Abilities` 至少一个」改写为「`Abilities` / `GrantedFlags` / `Modifiers` 三格至少一格非空」——一件纯战斗外、只靠 flag / modifier 生效的法则本来合法，而原措辞会把它拦下；理由（没有任何生效通道的条目是纯负债）一字未变。

### 9. 存档面

零新增字段、不 bump `schemaVersion`。三个新格全部是内容侧静态定义，经 `ItemId` 解析而来；`CombatItemSave(ItemId, UsesThisCombat)` 结构原样，只是比对的上限换了一格。

## Clarifications

- **战斗外使用时「次数 −1」走哪一列** → 走 `ProfileChangeSpec` 上新增的道具次数列，不塞进资源列。塞进资源列要给 `CostKey` 新增一个成员，破坏它与两层 Profile 字段的双向满射，且该成员没有取值域 / 终态语义可填。该列的定义本体落 `systems/services/profile-service.md`。
- **战斗外使用的门面形状** → 单一使用门面 `UseItemOutOfCombat(AbilityScope, string)`，一次事务；「只扣次数、无产出」的路径另有门面。草稿原写的无 `scope` 参数形态被补齐，以遵 `AbilityScope` 作路由键的纪律。草稿自陈「服务归属未定」就此答定：归 profile-service。
- **战斗外触发式禁令与「`PowerData.Abilities` 取值域不收窄」的字面冲突** → 采纳禁令，同时把那条决定的措辞限定为「不按启动式 / 被动式收窄」（区分在呈现层），并注明战斗外触发式另受加载期校验约束。事实基础：首批时点全部在战斗内。
- **战斗外道具效果的表达力上界** → 取最窄的一档：纯 `ProfileChangeSpec` 模板，恒定、无条件、无随机。
- **`ItemData.Abilities` 的处置** → 整格移除，不采用「保留 + 校验使其恒空」。
- **恒空列的表述形态**（自动采纳的标准默认）→ 逐列穷举列名、不写列数，依据是既有的「列表数不进承重表述」纪律。
- **`Sorcery` 校验的改写方向**（自动采纳）→ `Abilities` 恒空后原条件的后半永真，故只判 `OnPlay`。

## Open questions

- **用道具产生的栈条目落在 `StackEntryKind` 的哪个成员上。** 已定的是它的 `abilityId` 恒空，故收口阶段的「默认 counters +1」对它不成立；但栈条目类型枚举当前四个成员中没有一个显然对应「用道具」，是复用既有成员还是新增一个未定。→ `systems/services/combat-service.md`。
- **战斗外道具使用是否单独构成一个存档点，以及事件之外使用时的痕迹落点。** → `systems/character-profile/item/_index.md` 的同名待决项。
- **回寿法宝的总量护栏在内容编排面的具体口径**（出现频率 / 商店库存深度 / 定价）仍未给。
- **数值全部留空**：`MaxUsesPerCombat` 的典型取值、各道具的效果量、折价系数的绝对数字均属内容扩充后的统计校准。

## Notes / triage

- 台账侧连带：`content/_index.md` 三行由 🟠 转 🟢；`open-questions/deferred-content.md` 两条整条移出、一条部分答定；`open-questions.md` 索引中三处已过时的表述需对账。
- 载体族改名的机械替换面超出本次提炼所触及的文档，仍有若干处引用旧类型名，需一轮全库扫尾。
- 两处引用出处订正：道具使用窗口的权威是 `systems/services/combat-service.md`；Research 面板的六类操作不是「卡组构筑」的同义词。
