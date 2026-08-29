---
type: solution-draft
date: 2026-08-28
question: 效果原语 / 异能语法底座的剩余缺口 —— `ItemData` 无使用效果格、战斗外效果无执行面、`Sorcery` 触发式校验缺口、`AbilityKind` 两个同名枚举撞车；连带三条已过时的阻塞登记
source: 分派单称「效果原语 / 异能语法未定案（`content/_index.md` 标 🔴）」。**该前提经核查已过时**，本草稿据核查结果重新界定问题，见「问题」一节。原始待答条目已于 2026-08-27 移出 `open-questions/01-combat.md`（见 `open-questions/update-log.md`「效果原语 / 异能语法整条答结」）
targets: systems/character-profile/item/_index.md · systems/character-profile/item/common-properties.md · systems/player-profile/player-item/_index.md · systems/character-profile/deck/common-properties.md · systems/services/combat-service.md · systems/architecture.md · content/_index.md · open-questions/deferred-content.md
status: distilled
reviewed: 2026-08-28 — 批量合并 interview，六题全取推荐项（本稿相关：Q1 `Charges −1` 走新列 `ItemElements` 而非 `ChangeElement` · Q2 单一使用门面 `UseItemOutOfCombat(scope, itemId)` 一次事务 · Q4 采纳 P-1 并就地限定 `ADR-0099` 措辞）。草稿两项取向（战斗外表达力上界取 A · `ItemData.Abilities` 整格移除）按 08-28 评审裁决落笔，连带 I-9 不落笔、加载期校验实为 13 条。
distilled-to: handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md
---

# 方案草稿 — 效果原语底座的剩余缺口收口

## 问题

### 前提核查：原问题的主体已定案，🔴 登记已过时

分派本题时的前提是「效果原语 / 异能语法未定案，是五个内容类型的共同底座」。**核查后这条前提不成立**：

| 分派单称「未定」的项 | 实际状态 | 权威落点 |
|---|---|---|
| 效果原语 / 异能语法 | **已定案**（2026-08-27） | `systems/character-profile/deck/common-properties.md`「效果原语与定义体」 |
| 效果流水线阶段划分 | **已定案** —— 五阶段 + 六条规则 | `systems/services/combat-service.md`「效果流水线」 |
| `CardData` 的费用与触发器两格是结构占位 | **已收口** —— `ManaCost` 独立整数格；**取消触发器格**（`Abilities` 已承载）；新增 `OnPlay` | `deck/common-properties.md`「`CardData` 的字段清单收口」 |
| `content/_index.md` 的 `ability/` 行标 🔴 | 该文件**当前已标 🟢「语法已定案」** | `content/_index.md` 类型登记表第 51 行 |

`open-questions/update-log.md` 亦已记「**效果原语 / 异能语法整条答结**（移出 `01-combat.md` 1 条）」，`answer-logs/log-ability-primitive-grammar.md` 是它的归档。故**本草稿不重开已定案的语法本体**——重开等于把一份刚定案的设计再讨论一遍，且极可能与既定判据打架（该 log 里有十二条被明确否决的备选，本草稿逐条避开）。

**那个 🔴 的出处已找到**：`open-questions.md`（索引文件）**第 99 / 112 / 144 行仍写着旧文本**「效果原语 / 异能语法未定案（`content/_index.md` 标 🔴）」，并把它列为「玩法侧三处欠账」之首——**索引落后于分片与 `content/_index.md`**。这是一处需要对账的失真，不是一个待答问题。

### 重新界定：真正仍悬着的是底座的四处缺口 + 三条过时登记

底座定案后，`content/_index.md` 登记表里仍有**三个类型标 🟠 且阻塞理由指向效果面**，另有 08-27 定案自己列出的两条 Open questions 未闭合。逐条核查后，真正的缺口是：

| # | 缺口 | 来源 | 卡住谁 |
|---|---|---|---|
| **G1** | **`ItemData` 没有使用效果格。** `UseItem(itemId, targets)` 是已定案的一等玩家动作、签名里带 `targets`，但 `ItemData` 上没有任何一格能提供这些 `TargetSlots` 与效果本体；道具不是战场条目，走不了 `ActivateAbility(entryId, abilityId, targets)` | `handoffs/2026-08-27-ability-primitive-grammar.md` 的 Open questions 第 3 条（原文：「**属既有 under-specification，本次未引入也未闭合**」） | `content/character-item/` · `content/player-item/`（登记表两行的阻塞理由「阻于 `ItemData` 尚无效果格」逐字对应本条） |
| **G2** | **战斗外效果没有执行面。** 首批八原语的取值域**全部**是战斗内运行态（道念 / `currentMana` / 三区牌 / 战场条目 / `counters`），战斗外一条都没有可写的对象；而回寿法宝的效果被明写为 `ChangeElement(CostKey.LifeSpan, +n)`——那是 `ProfileChangeSpec` 的形状，不是 `EffectData` 的形状 | `open-questions/deferred-content.md`「`PlayerItem` …**战斗外的效果形态**均未设计」；`systems/character-profile/item/_index.md`「补天丹一类的回寿法宝」条 | 同 G1；也是「回寿法宝」这个已被举为样板的条目形态**目前写不出来**的原因 |
| **G3** | **`Sorcery` 带 `Triggered` 异能的合法性未被任何校验覆盖。** 既有规则只禁 `Static` / `Activated` | `handoffs/2026-08-27-ability-primitive-grammar.md` 的 Open questions 第 4 条 | 卡牌条目写作（一条永不触发的异能在加载期完全合法） |
| **G4** | **`AbilityKind` 是两个不同的枚举、同名。** `deck/common-properties.md` 定义 `enum AbilityKind { Static, Activated, Triggered }`；`systems/architecture.md` 的 `AbilityChangeElement` 定义 `enum AbilityKind { Power, Item }`。**两者在同一 C# 程序集内不可能共存** | 本次核查新发现，此前不在任何清单上 | 一切引用 `AbilityData.Kind` 或 `AbilityChangeElement.Kind` 的落地（第 1 级「写不出来」的纪律阶梯上，它现在是「编译不过」） |
| **P1** | **七处台账 / 文档登记已与主题文档矛盾**（含分派单那个 🔴 的出处、`CardData` 两格占位的旧措辞、`RelicData` 的四处同源表述、`power/` 两份文档的骨架抬头）。逐条见子项 9 | 08-27 定案后未回收 | 登记不实；`content/player-power/` 被一条已不成立的理由挡住，且下一次 `/assess-derive-readiness` 会照着失真的索引重估 |

**G1 与 G2 是同一件事的两半**（一件 `UsableScene = Both` 的道具两侧都要有效果），必须一起答；G3 / G4 是同批定案自带的机械缺口，顺手闭合；P1 是台账对账。

## 约束（来自既有设计）

**这些是硬边界，方案不得与之冲突。**

1. **效果定义必须是纯数据 `.tres`、可被 overlay 热更**，且交叉引用须能在合并后被静态校验为不悬空。→ `ADR-0007`
2. **否决带求值器的效果小语言 / 表达式串**（`ADR-0061` 与 `deck/common-properties.md` 两处逐字否决）。理由：overlay 能热更一段脚本，风险面远大于改一个数值。**任何新的效果表达面都必须继承这条禁令。**
3. **档案写入唯一入口 = `profile-service.ProfileManager.TryApply(spec)`**，全量校验 → 全有或全无 → 单点提交；modifier pipeline 在此生效。→ `systems/architecture.md`「两条唯一入口」
4. **资源写入必须落在 `ResourceElements` 表已登记的行上**，漏配在结构上不可能静默（`TryApply` 查表失败即报错）。→ `ADR-0063`
5. **产出侧统一走 `ProfileChangeSpec`，模式是「复用宽类型 + 恒空列断言」**，不新建窄类型（转换处就是漏字段的地方）。→ `ADR-0078`
6. **`EffectData` 恒不落存档**（内容侧静态定义，经 `CardId` / `abilityId` 解析）。→ `deck/common-properties.md`「存档面」
7. **模板 `Data` 是 ContentRegistry 的共享只读单例，运行时不得写它**；「内容定义 + 情境」的组合恒为两个类型（`ItemData ↔ CharacterItem` / `PlayerItem`）。→ `ADR-0012`
8. **道具的使用窗口 = 自己回合的行动阶段、栈为空时**，与出牌完全同窗口；**道具不是战场条目**，容器（储物袋）与本场视图（本场可用道具）分开。→ `ADR-0097` · `combat-service.md`
9. **两条已定的 `LifeSpan` 加载期校验**：`ItemData.Scope == Player` 且其效果含 `LifeSpan` 产出 → `PushError`；含 `LifeSpan` 产出且 `UsableScene` 含 `InCombat` → `PushError`。**这两条要求「道具的效果里有没有 `LifeSpan` 产出」必须能在加载期机械读出。**
10. **纪律的可执行化阶梯**：「能上线且线上不可见 → 必须第 1 / 2 级（写不出来 / 编译不过）」。→ `ADR-0013`
11. **`ItemData` 的既有字段形态**：`Id · Scope: AbilityScope · UsableScene`（必填）`· ManaCost`（可选）`· Charges · Abilities · Rarity`（必填）`· Subtypes`（+ 顶层共有的 `ContentEnabled` / `LocalizedText` / `ExclusiveSource` / `CodexFlavor`）。
12. **`PowerData.Abilities` 取值域不收窄**（`Power` 可挂启动式异能，启动键落长按弹层）。→ `ADR-0099`

---

## 建议方案

### 1. `ItemData` 的使用效果面 = 按世界分两格，格的必填性由 `UsableScene` 驱动

`[既有推演]`

**建议新增两格，取代把使用效果塞进 `Abilities` 的做法：**

| 格 | 类型 | 何时必须非空 |
|---|---|---|
| `CombatUseEffects` | `EffectData[]` | `UsableScene ∈ { InCombat, Both }` |
| `OutOfCombatUseOutcome` | `ProfileChangeSpec`（内容侧模板，形态见子项 2） | `UsableScene ∈ { OutOfCombat, Both }` |

**为什么是两格而不是一格（三条依据，与既有否决理由逐字同构）：**

| 判据 | 两格 | 一格塞两族语义 |
|---|---|---|
| **执行引擎不同** | 战斗内经 `StackManager > EffectProcessor > handler` 的五阶段流水线；战斗外经 `ProfileManager.TryApply` 的单点事务 | 每次读这一格都要先分辨它属于哪一族——**与 `AbilityData.ManaCost` 不塞进 `ProfileChangeSpec` 那条否决理由逐字同构**（「让 spec 承载两族语义，此后每次读 spec 都要先分辨」） |
| **值域不相交** | 八原语写道念 / mana / 战场条目 / 三区牌 / `counters`；`ProfileChangeSpec` 十一列里没有任何一列能表达「产 3 点道念」，反之亦然 | 一格必然是两个可空子格 + 一条 XOR 校验，即两格的坏形态 |
| **加载期可校验性** | 约束 9 的两条 `LifeSpan` 校验落成一行：`OutOfCombatUseOutcome.Elements.Any(e => e.Key == CostKey.LifeSpan && e.BaseValue > 0)` | 值域混装后要先分辨再筛，校验退化为 `switch` —— 正是可加性纪律要消灭的那个 switch |

- **`Both` 档两格都填，这不是冗余而是如实**：一件既能在战斗内产道念、又能在战斗外回寿的道具，本来就是两条不同的效果，它们**在任何一处都不会同时执行**。
- **形状与 `AbilityData` 的 `Effects` / `StaticModifiers` 两格 + XOR 校验同构，不新造风格**；差别只在这里的必填性由 `UsableScene` 驱动而非 `Kind`（`Both` 档要求两格皆非空，故是「按档的必填表」而不是 XOR）。
- **命名带 `Use` 前缀**是为了与 `Abilities` 里可能存在的其他效果区分（见子项 4），且与已定案的动词分工一致——`combat-service.md` 明写「**动词取 `Activate` 不取 `Use`——`Use` 已被道具占用，两个动词分给两条不同的来源路径**」。

**`targets` 的来源就此闭合：** `UseItem(itemId, targets)` 的 `targets` 长度 = `Σ(CombatUseEffects[i].TargetSlots.Length)`，顺序即扁平化 `slotIndex`——与 `PlayCard` / `ActivateAbility` 逐字同构（「玩家主动发起的动作，槽位一律在发起前一次收齐」，判据是**主动发起**）。入栈即 `targetState = Resolved`。

### 2. 战斗外使用效果 = 一份内容侧的 `ProfileChangeSpec` 模板，复用宽类型 + 恒空列断言

`[既有推演]`

**建议 `OutOfCombatUseOutcome : ProfileChangeSpec`，只开放三列、其余恒空**，形态**直接照抄 `ADR-0078` 已示范的模式**：

| 列 | 是否开放 | 理由 |
|---|:--:|---|
| `Elements` | ✅ | 回寿（`LifeSpan`）、回 `LifeTotal`、给灵石 / 仙玉、给经验——道具战斗外产出的主体 |
| `CodexElements` | ✅ | 「使用后解锁一条图鉴词条」是幂等收录，无副作用；不开它日后必然再开一格 |
| `Stats` | ✅ | 纯计数自增、失败不阻断，天然安全 |
| `AbilityElements` | ❌ 恒空 | 道具**不得**授予 / 移除 / 禁用能力。账号级资产的授予渠道受 `ExclusiveSource` 与残卷机制约束（`ADR-0049` / `ADR-0051`），一件可购道具若能直接给法则，那两套约束全部旁路——与 `ADR-0078`「事件产出不能给账号级法则或古宝」同一条理由，且道具比事件更易获取 |
| `DeckElements` | ❌ 恒空 | 卡组构筑操作的闭合清单归 Research 面板（`ADR-0022` 六类）；从储物袋按一下就改卡组，绕开构筑面板这个唯一编排点 |
| `StatusChanges` / `EventStateChanges` / `RngElements` / `TraceElements` / `SettingChanges` / `PlotElements` | ❌ 恒空 | 逐条都是「内容侧不该有权改写」的量（地图位置、事件态、RNG 子流状态、履历、账号设置、剧本进度）。`architecture.md` 已对这几列逐列写明「恒不走 modifier pipeline」，恒空是同一条判据的延伸 |

- **断言落加载期**（不是物化期）：`ItemData` 是内容定义、没有物化环节，故恒空列的校验在 ContentRegistry 合并后全量执行，违规 → `PushError` + 条目 `Id`。这与「坏数据在启动期大声失败」的既定标准一致。
- **符号方向沿用既定纪律**：内容侧写正数量值，取负的变换发生在组装时（与 `SelectCost` / `OutcomeSpec` 同处），**每一层只做自己那一次变换**。
- **`Elements` 的每一行仍受 `ResourceElements` 表约束**（约束 4）——道具改不了表里没有的资源，漏配在结构上不可能静默。
- **modifier pipeline 照常在 `TryApply` 内生效**，`Elements` 侧仍是 opt-in 白名单：一件回寿道具吃不吃 `LifeSpanCost` 修正由表决定、不由道具决定。**按符号分向**保证「寿元消耗 −20%」的法则不会削掉道具的寿元回复。

**执行链路（可 derive）：**
```
储物袋详情卡片「使用」键
  → item 侧门面方法（形态见「具体形态」）
  → 组装 spec = OutOfCombatUseOutcome + ChangeElement(该道具的 Charges −1 那一笔)
  → ProfileManager.TryApply(spec)      ← 单次事务，全有或全无
```
**扣次数与产出必须在同一次 `TryApply` 内**——分两次调用即「先扣次数后产出失败」这种半套写入，正是 `CostSpec` / `RewardSpec` 被合并的那条理由。

### 3. 战斗外使用不设目标面

`[既有推演]`

**`OutOfCombatUseOutcome` 不带 `TargetSlots`，战斗外的使用入口不进入选目标态。** 三条支撑：

- 目标的定义是「结算那一刻由 `TargetRef` 锚定到**具体条目**」（`ADR-0062`），而战斗外没有战场、没有战场条目、`TargetRef.EntryId` 无对象；
- `ProfileChangeSpec` 的每一列都是「按枚举键 / 内容 `Id` 索引」的形状，结构上装不下 `TargetRef`；
- 已定的 UX 形态是「储物袋面板内经详情卡片的『使用』键**直接使用**」（`ux/screen-flow.md`），本就没有选目标这一步。

### 4. 道具的战斗内代价与配额面 = `ManaCost` 一格 + 新增 `MaxUsesPerCombat` 一格

`[既有推演]`

**现状是一处语义双关，建议拆开。** `combat-service.md` 同时写着两件事：① 「**本作确实存在『每场限用一次』这类本场配额效果**，`CombatItemSave.UsesThisCombat` 是唯一的载体」；② 拒绝理由 `ItemUsesThisCombatExceeded` 触发于「本场配额撞上 **`ItemData.Charges`**」。但 `Charges` 的语义是**Profile 侧的总剩余次数**（即时写、跨战斗持久），拿它当本场配额上限意味着：

- 一件 `Charges = -1`（无限）的法宝，**「每场限用一次」在结构上写不出来**——而这正是文档声称已存在的那类效果；
- 一件 `Charges = 5` 的古宝，「本场配额」恒等于 5，与「每场限 N 次」这个设计面无关，该拒绝理由在玩家侧实际上不可达（Profile 侧的 `ItemChargesExhausted` 总是先命中）。

**建议：新增 `MaxUsesPerCombat : int`，与 `AbilityData.MaxActivationsPerCombat` 逐字同构** —— `-1` = 不限（缺省语义）、`>= 1` = 配额、**`0` 未定义**（恰是 `[Export]` 默认值，故漏填必须在加载期被拦，与既有那条哨兵校验同款）。

- **可预判性判据照抄**：`MaxActivationsPerCombat` 是显式内容字段而不是埋在效果条件里的判断，理由是「UI 必须在点下去之前把不可用项灰显」。道具在随身抽屉里同样需要灰态预判，**判据完全相同**。
- **两侧的闸各自成立、取更严者**：玩家侧 `UsesThisCombat < MaxUsesPerCombat`（本场）**且** Profile 侧 `Charges > 0`（总量）；**敌人侧没有 Profile**，故它另受 `UsesThisCombat < Charges` 约束（`ItemData.Charges` 在敌人侧读作「整场额度」，这条既有语义原样保留）。两条闸并存不是新规则，只是把现在挤在一个字段上的两件事各归其位。
- **拒绝理由不新增**：`ItemUsesThisCombatExceeded` 改为对 `MaxUsesPerCombat`（敌人侧另含 `Charges`）判定，`ItemChargesExhausted` 不动。
- **`ManaCost` 已存在、不动**；补一条校验：`UsableScene == OutOfCombat` 且 `ManaCost != 0` → `PushError`（战斗外没有 mana，与既有「`CardType == Power` 且 `ManaCost != 0` → `PushError`」逐字同构）。
- **存档零新增字段**：`CombatItemSave(ItemId, UsesThisCombat)` 原样，只是它比对的上限换了一格。

### 5. `ItemData.Abilities` 收窄为「只承载触发式」，或整格移除

`[既有推演 · 带张力，见「与既有决策的张力」]`

子项 1 把使用效果分出去之后，`Abilities` 这一格剩下什么：

| `AbilityKind` | 道具上还成立吗 | 依据 |
|---|---|---|
| `Activated`（启动式） | **不成立** | 启动式异能经 `ActivateAbility(entryId, abilityId, targets)` 启动，**按战场条目寻址**；道具不是战场条目，没有 `entryId`。道具的主动使用是 `UseItem`，已由 `CombatUseEffects` 承接 |
| `Static`（静止式） | **不成立** | 静止式修正的生效判据是「载体一进场即生效、一离场即失效」（BattlefieldManager 的一条与栈无关的写入路径）；道具**从不进场**，永无生效时刻 |
| `Triggered`（触发式） | **不成立** | 触发器注册面归 BattlefieldManager（「谁在监听哪个时点」），由**在场的**条目注册；道具从不进场 ⇒ 从不注册 ⇒ 永不触发 |

**三档全部不成立 ⇒ 建议 `ItemData` 整格移除 `Abilities`。** 判据是「一个从不触发的机制是纯负债」（`ADR-0045` 的原话），且它现在是**第 3 级以下**的纪律：内容作者给道具挂一条静止式异能，加载期合法、运行期静默无效——正是「能上线且线上不可见」，按 `ADR-0013` 必须提到第 1 / 2 级（**写不出来**）。移除该格即第 1 级。

- **零迁移**：`ItemData` 是内容定义、`Abilities` 不落存档；当前 `content/character-item/` 与 `content/player-item/` 均未开张、条目数为零。
- **保守替代**（若不接受移除）：保留该格并加一条加载期校验「`ItemData.Abilities` 非空 → `PushError`」。效果等同、但留下一个永远为空的字段，不推荐。

### 6. `Sorcery` 不得带**任何**异能；连带改写既有两条校验

`[既有推演]`

**推理与既有的 `Static` / `Activated` 禁令逐字相同**：触发式异能须在战场上注册才可能被命中，而 `Sorcery` 结算后进弃牌堆、**从不落场** ⇒ 从不注册 ⇒ 该异能永不触发，且加载期完全合法（这正是 08-27 定案自己点名的缺口）。

建议改写：

| 现状 | 建议 |
|---|---|
| `Sorcery` 不得带 `Static` / `Activated` 异能 → `PushError` | **`Sorcery` 不得带任何异能（`Abilities` 须为空）→ `PushError`**，与 `Affliction` 那条合并同形 |
| 校验 18：`Sorcery` 且 `OnPlay` 与 `Abilities` 皆为空 → `PushWarning`（什么也不做的法术） | 校验 18 改为：**`Sorcery` 且 `OnPlay` 为空 → `PushWarning`**（`Abilities` 恒空后，那半个条件永真、写着即误导） |

**这不收窄任何设计面**：法术的一次性效果本就走 `OnPlay`（那正是 08-27 为它开这一格的理由）。

### 7. `AbilityKind` 撞名 —— 建议把 element 侧那个重命名为 `AbilityCarrierKind`

`[既有推演]`

两个同名枚举、语义正交，**在同一程序集内不可能共存**：

```csharp
// systems/character-profile/deck/common-properties.md —— 异能的三分
public enum AbilityKind { Static = 0, Activated = 1, Triggered = 2 }

// systems/architecture.md —— AbilityChangeElement 的载体族
public enum AbilityKind { Power, Item }
```

**建议保留 deck 侧的 `AbilityKind`（异能三分），把 element 侧重命名为 `AbilityCarrierKind { Power, Item }`。** 四条依据：

1. **命名与语义的贴合度**：`{ Power, Item }` 说的是「这条能力**挂在哪一族载体上**」，不是「这条异能**怎么生效**」；`AbilityKind` 这个名字属于后者。同一份 `architecture.md` 里，与它并列的 `AbilityScope` 注释写的就是「能力的**生命周期层**」——`Kind` / `Scope` 这对命名本就是「族 / 层」的二维，把族叫 `CarrierKind` 使这一对读起来是一致的。
2. **改动面的不对称**：`AbilityKind { Static, Activated, Triggered }` 被 `AbilityData.Kind`、加载期 XOR 校验、`combat-service` 的 `AbilityNotAvailable` 判定等多处引用；element 侧只被 `AbilityChangeElement` 一格与 `(Kind, Scope)` 四格合法表引用。**改引用少的那个。**
3. **`(Kind, Scope)` 这个既定短语不受影响**——四个池（`PlayerPower ↔ PlayerPower` 等）、`Source` 的分域校验表、`GrantPoolPicker` 的过滤都写作「`(Kind, Scope)` 全同」，重命名后措辞改为「`(CarrierKind, Scope)`」是纯机械替换，语义一字未动。
4. **`AbilityChangeElement` 落存档**（进 `PastEventEntry.AppliedChange`），而**枚举以成员名逐字序列化**——但**类型名不参与序列化，成员名 `Power` / `Item` 一字未改** ⇒ **零存档迁移、不 bump `schemaVersion`**。这是选择改这一侧的第五条、也是最硬的一条依据。

### 8. 战斗外的**触发式**表达面：首版不开，配一条加载期校验

`[既有推演]`

`TimingIds` 首批十个**全部是战斗内时点**（`combat.start` / `turn.*` / `card.*` / `entry.*` / `fatigue` / `momentum.changed`）。一条 `UsableScene = OutOfCombat` 的 `PowerData`（法则 / 神通）若挂 `Kind == Triggered` 的异能，那条异能**永不触发**且加载期合法——与 G3 是同一种缺口。

**建议：首版不开战斗外触发点**，战斗外那一半的表达面**收敛为 `GrantedFlags` + `Modifiers` 两格**（即 capability flag + modifier pipeline 两条通道，`ADR-0017`，这本就是 `power/_index.md` 已定的战斗外形态）。配一条校验：

> `PowerData.UsableScene == OutOfCombat` 且 `Abilities` 中存在 `Kind == Triggered` 的条目 → `PushError` + 条目 `Id`。
> （`Both` 档不受此限——它的触发式在战斗内成立。）

- **收敛判据与「首版不设 Profile 侧代价列」同款**：日后要开是新增一族 `TimingIds` + 对应广播点，**纯加法、零迁移**；而先开一族没有广播点的时点，得到的是一批静默永不触发的内容。
- **`TimingId` 的值域是代码侧封闭常量表**这条既定纪律正好承接：「**一个时点必须有一处对应的广播点，而广播点是代码**」——战斗外目前一处广播点都没有。

### 9. 七处台账 / 文档登记的过时项，建议一并对账

`[既有推演]` —— **本技能不改台账，以下仅为报告，落笔归 `/analyze-new-ideas` 与 `/summarize-open-questions`。**

| # | 登记处 | 现状 | 建议 |
|---|---|---|---|
| 1 | `open-questions.md` 索引 **第 99 / 112 / 144 行**：「效果原语 / 异能语法未定案（`content/_index.md` 标 🔴）」，列为「玩法侧三处欠账」之首 | 08-27 已整条答结并移出分片；`content/_index.md` 已标 🟢 | 删除该表述；「三处欠账」相应收缩 |
| 2 | `open-questions/deferred-content.md` **第 57 行**：「**`CardData` 的费用与触发器两格仍是结构占位**」 | 已被 08-27 推翻——费用 = 独立 `ManaCost` 整数格，**触发器格取消**（`Abilities` 承载） | 整条改写（这正是本分派单的第三个子问题，它同样已答定） |
| 3 | `content/_index.md` 的 `player-power/` 行：「阻于 `RelicData` 字段清单与触发器体系」 | `power/_index.md` 明写「两层**共用一个 `PowerData` 定义**」，字段清单齐备（`Id · Scope · UsableScene · Abilities · Rarity · Subtypes · GrantedFlags · Modifiers`）；`status` 与 `SourceCode` 落 Profile 侧持有条目；开关 UI 已在 `ux/screen-flow.md`。**`RelicData` 是一个已不存在的类型名** | 改为 🟢，或**只保留子项 8 那一条真缺口**作为阻塞理由 |
| 4 | `open-questions/deferred-content.md` **第 25 行**：「`RelicData` 的字段清单与触发器体系未设计」（四子项：触发条件枚举 / 效果关键字体系 / `status` 持久化与 UI / 字段清单） | 四项均已有权威落点（`TriggerConditionData` + `TimingIds` / `KeywordData` / Profile 侧持有条目 + `ux/screen-flow.md` / `PowerData`） | 整条移出并记入 `answer-logs/`；若采纳子项 8，改写为「战斗外触发点是否开放」一条 |
| 5 | `systems/player-profile/player-power/common-properties.md` 待决问题：「触发条件枚举、效果关键字体系……尚无实质设计」 | 与 #4 同源、同已覆盖 | 同 #4 |
| 6 | `systems/character-profile/power/_index.md` **抬头**：「占位结构，机制待一次专门 session」；`power/common-properties.md` **整份**仍是骨架，其「⟨待定：能力定义的字段（触发器、效果关键字、flag / modifier 声明）⟩」与正文已落的 `PowerData` 字段清单不同步 | `_index.md` 正文已给出完整 `PowerData` 字段清单与三条生效通道 | 抬头与 `common-properties.md` 一并回收 |
| 7 | `content/_index.md` 的 `character-item/` · `player-item/` 两行：「阻于 `ItemData` 尚无效果格」 | 本草稿子项 1–4 若被采纳即闭合 | 采纳后改 🟢 |

> **`ItemData` 的效果格缺口目前不在任何 `open-questions/` 分片内**——它只出现在 `content/_index.md` 的登记表与 08-27 handoff 的 Open questions 里。也就是说，本草稿要闭合的第一号缺口**从未被登记为待答项**，这本身是「有缺口但没进清单」的一个实例，建议 orchestrator 提请补登。

---

## 具体形态（可 derive 的落地面）

### `ItemData` 字段清单（建议的最终形态）

| 字段 | 类型 | 必填 | 说明 |
|---|---|:--:|---|
| `Id` | `string` | ✅ | `character_item.<snake>` / `player_item.<snake>`；字符集不含 `#` `:` |
| `DisplayName` / `Description` | `LocalizedText` | ✅ | 与 `Id` 分离；不落存档 |
| `Scope` | `AbilityScope { Character, Player }` | ✅ | 决定持久层 |
| `UsableScene` | `UsableScene { InCombat, OutOfCombat, Both }` | ✅ | 缺失 → `PushError`（既有） |
| `Rarity` | `RarityTier` | ✅ | 缺失 → `PushError`（既有） |
| `Charges` | `int` | ✅ | `-1` = 无限（仅 `Scope == Character`）；`Scope == Player` 时须 `> 0`（既有） |
| **`ManaCost`** | `int (>= 0)` | ✗（缺省 0） | 既有；补一条 `OutOfCombat` 时须为 0 的校验 |
| **`MaxUsesPerCombat`** | `int` | ✗（缺省 **须写 `-1`**） | **新增**。`-1` = 不限 · `>= 1` = 本场配额 · `0` 非法 |
| **`CombatUseEffects`** | `EffectData[]` | 条件必填 | **新增**。`UsableScene ∈ {InCombat, Both}` 时非空 |
| **`OutOfCombatUseOutcome`** | `ProfileChangeSpec` | 条件必填 | **新增**。`UsableScene ∈ {OutOfCombat, Both}` 时非空；只开放 `Elements` / `CodexElements` / `Stats` 三列 |
| ~~`Abilities`~~ | ~~`AbilityData[]`~~ | — | **建议移除**（子项 5） |
| `Subtypes` | `string[]` | ✗ | 既有 |
| `ExclusiveSource` | `Source?` | ✗ | 既有，顶层共有 |
| `ContentEnabled` | `bool` | ✗（缺省 `true`） | 既有，顶层共有 |
| `CodexFlavor` | `LocalizedText?` | ✗ | 既有，顶层共有 |
| 美术引用 | — | — | 既有 |

> **不加的字段**（各有既定理由，写下以免日后重开）：`Price` / `Purchasable`（`ADR` 已定归定价表与 `ExclusiveSource`）· `IsProtected`（道具不进战场）· `Pool`（道具不洗进卡组，敌人侧持有列表由 `EnemyData` 给）。

### 新增 / 改写的加载期校验（逐条）

| # | 规则 | 违反时 |
|---|---|---|
| I-1 | `UsableScene ∈ {InCombat, Both}` 且 `CombatUseEffects` 为空 | `PushError` + `Id` + `.tres` 路径 |
| I-2 | `UsableScene ∈ {OutOfCombat, Both}` 且 `OutOfCombatUseOutcome` 为空 spec | `PushError` + 同上 |
| I-3 | `UsableScene == OutOfCombat` 且 `CombatUseEffects` 非空 | `PushError`（那些效果永不执行） |
| I-4 | `UsableScene == InCombat` 且 `OutOfCombatUseOutcome` 非空 | `PushError`（同上） |
| I-5 | `OutOfCombatUseOutcome` 的八条恒空列任一非空 | `PushError`，指名是哪一列 |
| I-6 | `OutOfCombatUseOutcome.Elements` 中某行的 `Key` 不在 `ResourceElements` 表内 / 其 `Op` 不在该行 `AllowedOps` 内 | `PushError` + 报出 `CostKey` 与条目 `Id` |
| I-7 | `MaxUsesPerCombat == 0` | `PushError`（`0` 是未定义取值，与 `MaxActivationsPerCombat` 同款哨兵校验） |
| I-8 | `UsableScene == OutOfCombat` 且 `ManaCost != 0` | `PushError` |
| I-9 | `ItemData.Abilities` 非空 | `PushError`（**仅在不采纳「整格移除」时需要**） |
| I-10 | `CombatUseEffects` 内出现 `BumpCounterEffect` / `CounterAtLeastCondition` | `PushError`。**与 `CardData.OnPlay` 的既有校验 10 逐字同构**：`counters` 键空间闭合于 `<abilityId>[#<子名>]`，而道具的使用效果**没有宿主 `AbilityData`**，键根本拼不出来 |
| I-11 | `CombatUseEffects` 的槽位总数 `> 32` / `> 4` | `PushError` / `PushWarning`（`FizzledSlots` 位掩码上限，与卡牌侧同一条） |
| **改写** | `CardData`：`CardType == Sorcery` 且 `Abilities` 非空 | `PushError`（取代原「不得带 `Static` / `Activated`」） |
| **改写** | 既有校验 18 → `CardType == Sorcery` 且 `OnPlay` 为空 | `PushWarning` |
| P-1 | `PowerData.UsableScene == OutOfCombat` 且 `Abilities` 含 `Kind == Triggered` | `PushError` + `Id`（子项 8） |

> **既有的两条 `LifeSpan` 校验就此可实现**：`Scope == Player` 且 `OutOfCombatUseOutcome.Elements` 含 `(LifeSpan, > 0)` → `PushError`；含 `(LifeSpan, > 0)` 且 `UsableScene` 含 `InCombat` → `PushError`（后者与 I-4 部分重叠，保留是因为它的错误消息指向不同的设计意图）。

### 调用面

**战斗内**（既有签名，不改）：
```csharp
ActionResult UseItem(string itemId, IReadOnlyList<TargetRef> targets);
// targets.Length == Σ(CombatUseEffects[i].TargetSlots.Length)，顺序即扁平化 slotIndex
// 入栈即 targetState = Resolved；栈条目的 abilityId 恒为空 ⇒ 阶段 5 的「默认 counters +1」对它不成立
//   （与 PlayedCard / Fatigue 同款，见 combat-service.md「阶段 5」）
```

**战斗外**（新增，形态 A —— 同步直返、纯本地事务，总则 1）：
```csharp
// 落点：持有储物袋那一侧的服务门面（profile-service 侧的 item 面；具体归属见「前置依赖」）
ApplyResult UseItemOutOfCombat(string itemId);
// 无 targets（子项 3）；内部组装 spec = OutOfCombatUseOutcome + Charges −1，一次 TryApply
// 业务失败（不在储物袋内 / Charges 归零 / UsableScene 不含 OutOfCombat / 在 disabledAbility 内）
//   → 返回 ApplyResult，绝不抛；itemId 经 ContentRegistry 解析不到 → PushError + 抛
```

### 存档面

**零新增字段、空迁移。**

- `CombatUseEffects` / `OutOfCombatUseOutcome` / `MaxUsesPerCombat` 全部是**内容侧静态定义**，经 `ItemId` 解析而来，不落 `ActiveCombat`、不落 Profile（与 `EffectData` / `CardType` / `Subtypes` 不落存档同款判据）。
- `CombatItemSave(ItemId, UsesThisCombat)` 结构原样，只是比对上限换成 `MaxUsesPerCombat`。
- `AbilityCarrierKind` 重命名**不改任何序列化成员名** ⇒ 不 bump `schemaVersion`（见子项 7 依据 4）。
- 战斗外使用产生的 Profile 变更走既有 `TryApply`，无新 element 类型、无新 `CostKey`。

### 代码落点

```
战斗内： combat-service > StackManager > EffectProcessor > handler   （既定四级，不变）
战斗外： profile-service > ProfileManager.TryApply(spec)             （既定唯一写入入口，不新增管线）
```
**战斗外不引入第二条效果结算管线**——这是本方案最重要的一条克制：`ProfileChangeSpec` 已经是一条完整的、带全量校验与单点提交的写入通道，为道具再造一条会立刻要求它自己的校验、自己的原子性与自己的日志。

---

## 后果

- **`content/_index.md` 三行由 🟠 转 🟢**（`character-item/` · `player-item/` · `player-power/`），`content/` 的开张顺序不再被效果面阻塞；依赖链上 `achievement/`（奖励目录依赖法则 / 古宝条目）随之解除一层阻塞。
- **`systems/character-profile/item/` 的两条 `LifeSpan` 加载期校验从「无法实现」变为可实现**——补天丹这个已被举为样板的条目形态就此可写。
- **`ItemData` 移除 `Abilities` 需改写三处措辞**：`item/_index.md`（「可带 mana 费用与异能（以启动式为主）」「`ItemData` 的字段形态」）· `player-item/_index.md`（「可带 mana 费用与启动式异能」）· `power/_index.md`（推论 ③「`ItemData` 两类不参与聚合（带 `Charges`、启动式，效果走 `Abilities`）」——结论不变，理由句要改）。
- **`AbilityCarrierKind` 重命名**牵动 `architecture.md`（`AbilityChangeElement` 定义）· `common-properties.md`（`(Kind, Scope)` 合法子集表）· `player-power/_index.md`（同池判据、`GrantPoolPicker` 伪码）· `power/_index.md`——**纯机械替换，无语义改动，零存档迁移**。
- **`combat-service.md` 改两处**：`UseItem` 的拒绝理由判定依据（`Charges` → `MaxUsesPerCombat`）· `CombatItemSave` 那段对上限来源的表述。
- **存档 schema 一格不加**，`schemaVersion` 不 bump。
- **不新增任何 `EffectData` 子类**——首批八原语原样，本方案一个原语都没加（这是刻意的：新原语的准入判据是「既有原语的组合确实表达不出该语义」，而战斗外根本不是原语能表达的世界，答案是换执行面，不是加原语）。

## 备选方案（已考虑并否决）

- **`UseItem` 的效果来源 = `Abilities` 中恰好一条 `Activated` 异能** — 否决：`UseItem(itemId, targets)` 签名里**没有 `abilityId`**（对比 `ActivateAbility(entryId, abilityId, targets)` 有），签名本身就说明道具只有一条使用效果；用「数组里恰好一条」表达一条基数约束，是把约束藏进通用容器再靠一条加载期校验维持，与「**静止式异能因此在结构上就装不下任何原子操作**——纪律由类型形状承担，不必再写校验」这条既定判据方向相反。且启动式异能按**战场条目**寻址，道具没有 `entryId`。
- **给战斗外新开一族 `EffectData` 子类**（如 `ChangeProfileResourceEffect`） — 否决：它会让 `EffectData` 的语义从「结算时执行的原子操作」扩成两族，`EffectProcessor` 的五阶段流水线对它一个阶段都不适用（无目标重检、无关键字展开、无静止式修正求值、无收口广播），等于在同一个类型树下藏一条完全不同的执行路径。**与「静止式修正不是 `EffectData`、是并列的第二种定义体」的定案理由逐字同构。**
- **为战斗外效果新建窄类型 `ItemUseOutcomeSpec`** — 否决：`ADR-0078` 已就同一问题裁定「复用宽类型 + 恒空列断言」，理由是「新建窄类型会让同一条 element 在两个类型之间转换，转换处就是漏字段的地方」。
- **一格 `UseEffect` 内含两个可空子格 + XOR 校验** — 否决：那就是两格的坏形态（多一层解包、`Both` 档表达不出来）。
- **战斗外效果允许写表达式 / 脚本** — 否决：`ADR-0061` 与 `deck/common-properties.md` 两处已逐字否决效果小语言，理由是 overlay 可热更；战斗外的写入面直达 Profile，风险面**更大**而非更小。
- **把 element 侧的 `AbilityKind` 保留、重命名 deck 侧的三分枚举** — 否决：改动面大得多（`AbilityData.Kind` + XOR 校验 + `combat-service` 判定），且 `{ Static, Activated, Triggered }` 才是「Kind」这个词的自然所指。
- **首版就开一族战斗外 `TimingIds`** — 否决：时点必须与广播点成对增长，而战斗外目前零个广播点；先开一族没有广播点的时点 = 一批静默永不触发的内容。日后开是纯加法。
- **给道具开 `MaxUsesPerCombat` 之外再开一个 Profile 侧代价列** — 否决：与「启动式异能首版不设 Profile 侧代价列」同一条收敛，且道具的 `Charges` 本身就是它的 Profile 侧代价。
- **`OutOfCombatUseOutcome` 开放 `DeckElements`（「用一件道具直接学一门功法」）** — 否决：卡组构筑操作的闭合清单归 Research 面板（`ADR-0022` 六类），从储物袋按一下就改卡组会绕开那个唯一编排点。

## 与既有决策的张力

1. **子项 5（移除 `ItemData.Abilities`）与三处既有措辞正面冲突。**
   - `item/_index.md`：「**可带 mana 费用与异能（以启动式为主）**，零费亦合法」与「`ItemData` 的字段形态 … `Abilities` …」；
   - `player-item/_index.md`：「可带 mana 费用与**启动式异能**」；
   - `power/_index.md` 推论 ③：「`ItemData` 两类不参与聚合（带 `Charges`、**启动式，效果走 `Abilities`**）」。
   **为什么方案需要它松动**：这三句写在「道具的使用 = 启动它的启动式异能」这个假设上，而该假设**已被 `ActivateAbility` 的定案推翻**——启动式异能按战场条目寻址，道具没有 `entryId`，这条路径在契约层已不通。08-27 handoff 自己把这称作「既有 under-specification」。
   **松动的代价**：三处措辞要改；若日后确有「道具带静止式修正」的需求（例：一件在储物袋里就让全场符箓 −1 费的法宝），需要重开一格。
   **不松动时的替代**：保留 `Abilities` 一格 + 校验 I-9（`PushError` 使其恒空），效果等同但留下一个永远为空的字段，且措辞仍与实际不符。**裁决权在用户。**

2. **子项 7（`AbilityKind` 重命名）触及一个落存档的类型。** `AbilityChangeElement` 进 `PastEventEntry.AppliedChange`。已核实**成员名 `Power` / `Item` 不改、类型名不参与序列化 ⇒ 零迁移**，但「枚举以成员名逐字序列化 ⇒ 重命名即破坏性契约变更」这条纪律的措辞会让人以为改不得；**建议在改写时把「类型名不在契约内」这一句一并写进 `architecture.md`**，否则这条张力会反复出现。

3. **`content/_index.md` 与 `open-questions/deferred-content.md` 的 `RelicData` 条目已与主题文档矛盾**（子项 9 · P1）。本技能**不改台账**，仅报告；但在裁决前，`content/player-power/` 的开张判断不应依赖那条已不成立的理由。

4. **`architecture.md` 与 `ADR-0078` 的 `EventOutcomeSpec` 名称撞车**（`architecture.md` 定义 `record EventOutcomeSpec(OnResolved, OnFailure)`，而 ADR 把「新建窄类型 `EventOutcomeSpec`」列为**否决**项）。二者可调和（ADR 否决的是窄 element 类型，架构里的是胜负两侧的容器），但**名字相同**。这不是本草稿的射程，只作报告——它与 G4 是同一类失误（同名不同物），建议一并对账。

## 前置依赖

- **`UseItemOutOfCombat` 的服务归属未定。** 储物袋跨两个持久层（`CharacterProfile.magicPack` + `PlayerProfile` 的 `PlayerItem`），两者的写入都经 `ProfileManager`，故门面**多半**落 profile-service；但「谁在什么时机调它」涉及编排顶点 game-progression 与储物袋 UI 的入口。本方案的调用面小节在此答定前无法定稿。→ `systems/services/profile-service.md`
- **战斗外道具使用是否单独构成一个存档点，以及无 `PastEventEntry` 时的痕迹落点** —— 这两问是**本批次分片 F** 的题目（`item/_index.md`「战斗外道具使用的两处空缺」）。本方案的 `UseItemOutOfCombat` 链路**必须与 F 的裁决对齐**：若 F 判定它构成存档点 / 需要痕迹落点，spec 组装处要相应追加列（`TraceElements` 目前在本方案里被判为恒空 —— **这一条恒空列的判定须以 F 的裁决为准**）。orchestrator 合并 interview 时请把这两条并置。
- **`ModifierKey` 的其余具名修正**（`architecture.md` 的行内 `⟨待定⟩`）—— 若日后要让道具的战斗外产出吃某条修正，须先在 `ResourceElements` 表的对应行登记 `GainModifier`。不阻塞本方案（缺省豁免）。
- **数值全部留空**：`MaxUsesPerCombat` 的典型取值、各道具的效果量、折价系数 `itemPowerRatio` 的绝对数字，**均属内容扩充后的统计校准**（`systems/balance.md`），本草稿一个数字都不给。前置是「一张牌该产多少道念」那条承重待答项。

## 仍需用户决定

### ① 战斗外道具效果的表达力上界 `[取向选择]`

**这决定「战斗外的道具能做什么」这个设计面的宽度**，与 08-27 handoff 把「`ModifierTarget` 首批清单宽度」判为真取向同性质：没有客观最优，取决于你想让储物袋里的东西有多大戏份。

| 选项 | 形态 | 能写出什么 | 写不出什么 | 代价 |
|---|---|---|---|---|
| **A（推荐）** | 纯 `ProfileChangeSpec` 模板，恒定、无条件、无随机 | 补天丹「+n 寿元」· 丹药「+n `LifeTotal`」· 「+n 灵石」· 「解锁一条图鉴」 | 「随机回复 3~8 点」· 「若寿元 < X 则加倍」· 「打开锦囊触发一个事件」 | 表达力最窄；日后要开是纯加法 |
| **B** | A + 允许挂条件门 | 「若已进入第三章则加倍」类 | 同 A 的随机与事件 | 既有三个 `EffectCondition` 谓词读的**全是战斗内量**（`counters` / 战场条目 / 道念），战斗外一个都不可求值 ⇒ 实际上要新造一族战斗外谓词，**是新机制不是新参数** |
| **C** | A + 允许道具触发一个 `AdventureEvent` | 「打开锦囊 → 进入一个事件」· 事件能做的一切 | — | 把道具使用变成事件入口，撞 future-event-service 的**唯一物化点**与事件位 / `lifeSpanCost` 预算；储物袋的「使用」键会变成可能改变流程的动作，与「先看后决」的既有取向张力大 |

**推荐 A**，三条理由：① 与「`Amount` 单参数不做通用表达式」「首版不设 Profile 侧代价列」两条既定收敛纪律同款；② 只有 A 能让使用结果**在按下之前原样呈现给玩家**（B 的条件与 C 的事件都做不到），而储物袋详情卡片的形态本就是「看清楚再按」；③ B / C 都是纯加法，日后想开随时能开，反向收回则要改内容条目。

**若选 A**，`OutOfCombatUseOutcome` 的三列开放表（子项 2）即为最终形态；**若选 B / C**，本草稿的子项 2 与校验 I-5 须重写，请一并说明希望的表达形态。

→ **已裁决（2026-08-28 · 批量评审）：选 A —— 纯 `ProfileChangeSpec` 模板，恒定、无条件、无随机。** 子项 2 的三列开放表即为最终形态，校验 I-5 无需重写。

---

### ② `ItemData.Abilities` 一格的处置（由「## 与既有决策的张力」T1 提出，同批裁决）

→ **已裁决（2026-08-28 · 批量评审）：移除该格。** 不采用「保留 + 校验使其恒空」的替代方案（本库反复否决过恒无对象的伸缩位）。
连带须改的三处措辞——`item/_index.md`「可带 mana 费用与异能（以启动式为主）」· `player-item/_index.md`「可带…启动式异能」· `power/_index.md` 推论 ③「效果走 `Abilities`」——随本草稿的提炼一并处理。

---

> **一句话总结（供快速评审）：** 效果原语语法本体已于 08-27 定案、无须重开；本草稿只补它剩下的四处机械缺口——给 `ItemData` 开「战斗内 `EffectData[]` / 战斗外 `ProfileChangeSpec`」两格使用效果面并配十四条加载期校验、给道具补 `MaxUsesPerCombat` 配额格、把 `Sorcery` 的异能禁令补全、把撞名的 `AbilityKind` 拆开——外加三条已过时的台账登记待对账。只有一条真取向待裁决（战斗外效果的表达力上界，推荐最窄的选项 A）。
