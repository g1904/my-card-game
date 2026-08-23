# 战斗内运行态计数器：键约定、消费面与读档校验

- id: 2026-08-22-combat-runtime-counter-persistence
- date: 2026-08-22
- topic: systems/services/combat-service.md · systems/character-profile/power/_index.md · systems/player-profile/player-item/_index.md
- status: distilled
- distilled-to: systems/services/combat-service.md, systems/character-profile/power/_index.md, systems/player-profile/player-item/_index.md

## Intent（distilled）

战斗内两块运行态计数器——`CharacterPower` / `PlayerPower` 的「本场已触发 N 次」，`PlayerItem` / `CharacterItem` 的「本场已用几次」——的**承载字段本就已经定了**：战场条目的 `counters : Dictionary<string,int>`、`CardInstanceSave.Counters`、`CombatItemSave(ItemId, UsesThisCombat)`。本次不重新设计承载结构，只补齐**真正还没写的那三块**，并把落后的登记回填。

### 一、`counters` 的键约定（本次的实质新内容）

```
键 ::= <abilityId> | <abilityId> "#" <子名>
```

- 键的主体是 **`AbilityData.Id`**，不是 `PowerId` / `CardId`：`PowerData.Abilities` 可含多个异能，配额天然挂在**某一个异能**上；以条目为单位记数就写不出「A 每场一次、B 不限」。
- `#` 前那一段**必须能经 `ContentRegistry` 解析出一条 `AbilityData`**——取具名 id 而非自造裸字符串，是为了让键具备与全库其他跨类型引用同款的悬空校验能力。
- **`AbilityData.Id` 不得含 `#`**（加载期 `PushError`）。这是键约定的隐含前提，否则 `#` 分隔在语法上不成立。子名本身的字符集正则**待 `content/` 的 id 约定表成型时统一定**。
- 值域 `>= 0`；为 0 的键不写入。
- **战场条目 `counters` 与 `CardInstanceSave.Counters` 共用同一套键约定**，不写成两套。
- **当前合法的键形态仅此一种**；非异能计数器（关键字状态叠加层数等）当前不表态。

### 二、消费面 API 与计数时机

`GetCounter(entryId, key)` / `BumpCounter(entryId, key, by)` 落 **BattlefieldManager**，不新增 manager、不新增事件。

- **计数只在弹栈结算成功之后 +1**，`BumpCounter` 调用点唯一、落在 StackManager 的结算收口回调。判据：**一条没结算的异能不该吃掉配额**，而 fizzle 发生在弹栈结算那一刻，晚于压栈与付费。
- **`ActivationCost` 已付但 fizzle 的启动式不吃配额，成本仍不退**——与「`SelectCost` 不回滚」同一条纪律。
- **配额闸门双查**（宣告 / 触发注册时 + 结算时）：因计数在结算后才 +1，连锁触发能在同一次结算链内全部通过第一道闸门；结算时的第二次查询让链内第二条自然被拦。不为配额引入「已预留」这类第二份运行态。
- **`CardInstanceSave.Counters` 的消费面是已知的未覆盖面**：本次只定它的存档形态与键约定，读写 API 待卡牌效果系统落地时再定。「共用一套键约定」不等于 API 也共用。

### 三、两条新增读档校验（四检查点 → 六检查点）

- ⑤ `counters` 值为负 / `UsesThisCombat < 0` → `PushError` + 抛（内部一致性破损，与既有 ③ ④ 同档）。
- ⑥ `CombatItemSave.ItemId` 不在该侧「本场可用道具」的重建结果内 → `PushWarning` + 丢弃该条、不阻断恢复。
- **`counters` 键的 `abilityId` 段走既有的 ②（`PushError` + 报出 id），不开例外。**

### 四、对称性与回填

- 法宝 `CharacterItem.Charges` 与古宝一侧对称、同样即时写——**这是既有定案的确认，权威在 `systems/character-profile/item/_index.md`，本次只在 `combat-service.md` 侧加回链、不在 item 侧复述。**
- `CombatItemSave` 一个结构覆盖两级，**不带 `Scope` 字段**（`ItemData.Scope` 是内容侧静态字段，`ItemId` 已唯一决定层级）。
- **敌人侧次数上限只能靠 `UsesThisCombat` 对 `ItemData.Charges` 比**——敌人无 Profile 持有条目，没有 `Charges` 可写。这是 `UsesThisCombat` 的第二个不可替代用途。
- `ActiveCombat` **schema 不变**，2–4 KB / 决策点与 ≈93 KB / 场的量级不受影响，版本化仍是随下一次 bump 的空迁移。
- 内容侧多一条纪律：「每场限 N 次」类异能必须在效果定义里引用自己 `AbilityData` 的稳定 `Id` 作键。

## Clarifications（interview 产物）

- **计数时机自相矛盾（草稿「触发式 = 压栈成功时 / 启动式 = 付费成功后 +1」与同段「fizzle 不计数」互斥）→ 裁决：计数写在弹栈结算成功那一刻，删掉「压栈成功时 / 付费成功后」两句。** 推翻草稿 §3 的写法；fizzle 的启动式成本不退但不吃配额。
- **`counters` 键悬空的失败语义（草稿 §5 第一条给 `PushWarning` + 丢弃，与既有读档校验 ② 的 `PushError` 相抵）→ 裁决：统一为 `PushError` + 抛，不开例外，既有 ② 不动。** 推翻草稿 §5 第一行；只在 `counters` 字段说明处点名它同样受 ② 约束。真悬空意味着内容被删或键被写错，静默丢弃会让一次内容运维动作静默吃掉玩家的配额状态。
- **非异能计数器（关键字状态叠加层数等）往哪放 → 取「暂不表态」**：只写「当前键的合法形态是 `<abilityId>[#<子名>]`」并显式写一句「当前仅此一种形态」。依据：关键字清单当前归零，现在就为空清单定第二类键是预铺。
- **`CardInstanceSave.Counters` 的消费面无人承载 → 取「只定战场条目一侧的 API」**，并在文档中明写这是已知未覆盖面。依据：`CardData` 字段清单本就未定案。
- **配额闸门能否被连锁触发穿透 → 取「结算时再查一次（双查）」**。依据：一次额外查询、无新状态，与「结算后才 +1」组合起来行为闭合。
- **子计数器名的形态与校验 → 取「`AbilityData.Id` 不得含 `#` 为必须（加载期 `PushError`），子名正则留待 `content/` 的 id 约定表统一定」**。前者是键约定的隐含前提，草稿漏写。

## Notes / triage

- **事实订正（订正草稿的措辞）：** 草稿「与既有决策的张力」称 `systems/character-profile/item/_index.md` 对「法宝次数是否即时写」未表态 —— **不成立**，该文件已明写「消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile，不攒到收口」。草稿「后果」里那条「补『法宝次数即时写』这半句」**取消**（照写会在同一文档制造重复条目）。该文件本次**不改**。
- 草稿 §1 / §4 为**纯确认**，`combat-service.md` 既有内容未重写。
- 越界发现（不属本分片，未处理）：`open-questions/01-combat.md` 顶部摘要块与治理提示块已膨胀并含大量过程坐标。

## Open questions

- **非异能计数器（`KeywordKind.State` 展开出的 `Transient` 条目、关键字状态的叠加层数）的落点**——当前 `counters` 键约定只覆盖 per-ability 配额，关键字清单归零故暂不扩。→ `systems/services/combat-service.md`、`systems/character-profile/deck/common-properties.md`
- **`CardInstanceSave.Counters` 的读写 API**——存档形态与键约定已定，消费面待卡牌效果系统落地时再定。→ `systems/services/combat-service.md`
- **子计数器名 `<子名>` 的字符集正则与登记**——待 `content/` 的 id 约定表成型时统一定。→ `game-design-documents/content/_index.md`
- **「每场几次」的具体取值**——依赖 ch1 数值标杆专场与「一张牌该产多少道念」的量纲；字段形态不依赖它。→ `systems/balance.md`
