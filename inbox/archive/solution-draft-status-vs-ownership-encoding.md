---
type: solution-draft
date: 2026-09-06
question: `status`（启用 / 禁用）与「拥有 / 失去」两个正交维度如何编码进存档 schema？
source: open-questions.md「derive 就绪度 · 仍在的承重卡点」第 1 条 → systems/services/profile-service.md · systems/character-profile/item/common-properties.md · systems/character-profile/power/common-properties.md
targets: systems/character-profile/item/common-properties.md · systems/character-profile/power/common-properties.md · systems/character-profile/power/_index.md · systems/player-profile/player-power/common-properties.md · systems/player-profile/player-power/_index.md · systems/services/profile-service.md（另见「后果」中的连带面：systems/architecture.md · systems/services/profile-schema-versions.md）
status: distilled
reviewed: 2026-09-06 · 批量评审（/batch-analyze-new-ideas · 合并 interview）——全部取向项已由用户当面裁决，逐条见 handoff 的 Clarifications
distilled-to: handoffs/2026-09-06-status-vs-ownership-encoding.md
---

# 方案草稿 — `status` × 「拥有 / 失去」的存档编码

## 问题

`open-questions.md` 的「derive 就绪度」把本条列为 **🔴 全库解锁面最宽的单一裁决**，判定它是 `item/common-properties.md` 与 `power/common-properties.md` 两份 blocked 的共同且唯一卡点，并称 `profile-service.md:336` 与 `:420` 自相矛盾（前者已给出语义答案、后者仍登记为未定）。

**直读两处原文后，这个前提不成立——两处并不矛盾，`:420` 同样说「已成文」：**

> `profile-service.md:336` —
> 「**`status`（启用 / 禁用）与「拥有 / 失去」是正交两维：** 列表成员表达「拥有哪些」，`status` 表达「拥有的这些里哪些当前生效」。失去 = 移出 `List<PlayerPower>`，不是置 `status = 禁用`。详见 `systems/player-profile/player-power/common-properties.md`。」

> `profile-service.md:420` —
> 「**元进程字段结构。** `Achievement` 条目 schema 未定；各账号级条目的解锁 / 获取 / 失去的具体触发未定。（**`PlayerPower` / `PlayerItem` 的持有条目形态——含 `status` 与「拥有 / 失去」两个正交维度的存档编码——以及 `AccountInfo` 与 `GameSetting` 的字段面均已成文，见 `systems/player-profile/_index.md`。**）」

`:420` 这条待决项的**主体是 `Achievement` schema 与账号级触发**；括号是一句**显式排除**，明写本编码**已成文并给出权威**。索引把括号读成了「登记为未定」。

**编码的实体确实已经落笔**，权威在 `systems/player-profile/_index.md:57-72`：

> 「**四类持有条目的 record 形态。** 四者共有 `SourceCode`……`Status` 归 power 两类与 item 两类共有的启用开关，`Charges` 只归 item 两类：」
> ```csharp
> public readonly record struct CharacterItem (string ItemId,  int Charges, bool Status, Source SourceCode);
> public readonly record struct CharacterPower(string PowerId,              bool Status, Source SourceCode);
> public readonly record struct PlayerItem    (string ItemId,  int Charges, bool Status, Source SourceCode);
> public readonly record struct PlayerPower   (string PowerId,              bool Status, Source SourceCode);
> ```
> 「**`Status` 落 `bool`（true = 启用）而非枚举**：它是二值开关；「本轮回禁用」是第三维、已落 `CharacterProfile.disabledAbility`，不挤进这一格。」（`:70`）

并且已进 v1 登记表：`profile-schema-versions.md:43` 第 21 行「四类持有条目定形，条目键名 `powerId` / `itemId`；集合字段名一律单数」，`:52` 第 30 行与 `:54` 第 32 行登记四个持有列表顶层键。

**因此本草稿的实际内容是两件事，而不是一次开放裁决：**
① **确认并对齐**——把已定的编码写成一段可复述的完整投影，把四份下游文档里指向一个**已不存在的待决项**的陈述改掉；
② **补上唯一真正的缺口**——`Status` 这一格**没有任何写入通道**（下文「建议方案 · 子项 3」）。

## 约束（来自既有设计）

- **唯一写入面**：两层 Profile 的一切运行态写入只经 `profile-service.ProfileManager.TryApply(spec)`，全量校验、全有或全无、单点提交。→ `systems/services/profile-service.md`、`.claude/rules/state-save-rules.md`
- **`ProfileChangeSpec` 逐条按施加语义分列，列表数不写进承重表述**（随字段族增长）。判据：「施加语义根本不同就分列」。→ `systems/architecture.md:540`、`profile-service.md:37`
- **`AbilityElements` 的定位是「改变**持有**」**：「`AbilityElements` 的载荷带 `(CarrierKind, Scope, Source, Op, PairKey)` 且改变**持有**」（`profile-service.md:198`）。`AbilityChangeOp` 现有三个语义面：`Grant` / `Remove` / `Disable`（`profile-service.md:40`）。
- **`StatusChanges` 与本题无关**：它的元素是 `StatusAssignment(StatusKey Key, int IntValue, string StringValue)`，明文绑定 `CharacterProfile.Status` 上的**数值型规则字段**（`architecture.md:345`、`:542`；`Status` 装的是 `lifeSpan` / `manaLimit` / `experiencePoint` / 隐藏属性档位，见 `character-profile/_index.md:259`）。**名字撞车，语义无交集。**
- **禁用第三维已定案**：`CharacterProfile.disabledAbility : IReadOnlyList<DisabledAbilityEntry>`，三档 `DisableDuration { NextEvent, ThisChapter, ThisCycle }`，存「施加时坐标 + 时长」不存到期坐标，经 `AbilityElements` 的 `Op == Disable` 写入。→ `character-profile/_index.md:258-280`、`answer-logs/log-ability-deprivation-and-player-statistics.md:9`
- **生效判据是三条与门**：拥有 · `status == 启用` · 不在 `disabledAbility` 内（`profile-service.md:308`、`power/_index.md:35`）。禁用一律**截断在「进入生效面」那一步**。
- **`ContentEnabled` 是第四件事，且不落存档**：内容侧 `XxxData.ContentEnabled: bool`，**过滤只发生在产出侧**（`AllEnabled()` 取池），读取侧 `Get(id)` 不过滤，故存档引用被关闭的条目仍能解析。→ `systems/common-properties.md:169-172`
- **首发前不 bump**：一切首发前改动归 `schemaVersion = 1`，补齐 = 往 v1 清单补条目，不产生新 bump。→ `profile-schema-versions.md:19`、形态纪律 ①/④
- **`x`（残卷分档自变量）只数 `SourceCode == FinaleWin` 的条目、不落字段**，与 `Status` / `disabledAbility` 无关；抽取池也**不按 `status` / `disabledAbility` 过滤**（生效维度与持有维度正交，被禁用的照常算已持有）。→ `player-profile/_index.md:117`、`player-power/_index.md:91`

## 建议方案

### 子项 1 · 四条维度的落点表（把「三件事」明确为四件）
`[既有推演]`

题面要求分清三件事；直读后实为**四维**，其中两维落存档、一维落存档但属另一字段、一维完全不落存档：

| # | 维度 | 语义 | 落点 | 写入通道 | 权威 |
|---|---|---|---|---|---|
| ① | **内容启用**（`ContentEnabled`） | 运营放量开关：这条内容当前是否发放 | `XxxData` 上的 `bool`，**不落存档**（内容侧，随 overlay 热更） | overlay 覆盖内容资源，不经任何 spec | `systems/common-properties.md:169` |
| ② | **拥有 / 失去** | 玩家手上有哪些 | **持有列表的成员资格**：`playerPower` / `playerItem` / `characterPower` / `magicPack` | `AbilityElements`，`Op ∈ { Grant, Remove }`（置换 = `Remove` + `Grant` 同 `PairKey`） | `player-profile/_index.md:15-16`、`character-profile/_index.md:130-131`、`profile-service.md:39` |
| ③ | **启用 / 禁用（玩家开关）** | 拥有的这些里哪些**我要用** | 持有条目 record 上的 **`bool Status`（true = 启用，默认 true）** | **现无通道 —— 见子项 3** | `player-profile/_index.md:57-70` |
| ④ | **本轮回禁用（外部抑制）** | 拥有的这些里哪些**被剥夺了、暂时不许用** | `CharacterProfile.disabledAbility : DisabledAbilityEntry[]`（顶层键，**不落 `Status` 内**） | `AbilityElements`，`Op == Disable` 带 `Duration` | `character-profile/_index.md:258` |

**三条不变式（均已在库内成文，此处只汇总）：**
- **失去 ≠ 禁用。** 失去 = 移出列表（②），不是置 `status = 禁用`（③）。`profile-service.md:336` 一字不改。
- **禁用不挤进 `Status` 那一格。** ④ 是第三维、集合型 build 状态，`Status`（③）是账号 / 角色级二值开关；混住即「轮回结束后忘了恢复 = 永久剥夺」（`player-power/_index.md:59` 推论 ④）。
- **生效 = ② ∧ ③ ∧ ④ 的三条与门**，禁用一律截断在进入生效面那一步；②③④ 三者互不覆盖，故不需要任何优先级或裁决表。

**`StatusChanges` 一条也不管本题的任何一维**——建议在 `profile-service.md` 与 `player-profile/_index.md` 各留一句反向澄清（见「具体形态」），否则「`Status` 的变更走 `StatusChanges`」是一个几乎必然会被写出来的误推。

### 子项 2 · 编码本身：维持现状，不改一格
`[既有推演]`

建议**原样确认** `player-profile/_index.md:57-72` 的四条 record，理由逐条已在该处写明且经复核成立：

- `Status` 取 `bool` 不取枚举——二值开关，第三维另有承载面；用枚举会立刻引出「枚举里要不要放 `Disabled`」，而那一格属 ④。
- 四条 record 取 `readonly record struct`——字段少、要落存档且进 diff，与 `StatusAssignment` / `DeckChangeElement` 同款。
- 条目键名取 `<Kind>Id` 而非 `Id`——`Id` 在本库指条目自身的稳定 Id，这一格指向内容条目。
- `magicPack` 的元素是「一份实例」而非「一条 Id 一行」，按 `ItemId` 堆叠是呈现层聚合。

**JSON 形态推论（机械得出，不新增决策）：** camelCase 单点策略 ⇒ `/playerPower/[i]/status`、`/playerItem/[i]/status`、`/characterProfile/<id>/characterPower/[i]/status`、`/…/magicPack/[i]/status`。`playerPower` 属**透明段**（`player-profile/_index.md:15`），故这些 path 受路径稳定性纪律约束：改名 = 破坏性契约变更。**形状本身不变 ⇒ 本方案零迁移、零后端配合。**

**老档缺 `status` 格 → 补 `true`**（默认启用）。默认值口径按 `profile-schema-versions.md` 形态纪律 ③ 留在字段所在处（`player-profile/_index.md`），不搬进登记表。

### 子项 3 · 唯一真实缺口：`Status` 没有写入通道 —— 建议新开一列 `AbilityStatusChanges`
`[既有推演]`

**缺口的事实：** 门面上已有 `ApplyResult SetPowerStatus(string powerId, bool enabled)`（`profile-service.md:363`），但

- `AbilityChangeOp` 只有 `Grant` / `Remove` / `Disable` 三个语义面（`profile-service.md:40`），**没有一个能表达「把已持有条目的 `Status` 置为 X」**；
- `StatusChanges` 绑定 `CharacterProfile.Status` 的规则字段，装不下 `(Kind, Scope, AbilityId) → bool`；
- 而唯一写入面纪律要求它必须落在某一列上。

⇒ `SetPowerStatus` 目前**无法在不违反纪律的前提下实现**。这才是本题剩下的实质内容。

**建议：给 `ProfileChangeSpec` 新增一列（分列，而非给 `AbilityElements` 加 `Op`）。**

```csharp
public IReadOnlyList<AbilityStatusAssignment> AbilityStatusChanges { get; }
// 能力启用开关：按 (Kind, Scope, AbilityId) 的绝对置值

public readonly record struct AbilityStatusAssignment(
    AbilityCarrierKind Kind,        // Power | Item
    AbilityScope       Scope,       // Character | Player
    string             AbilityId,   // PowerData / ItemData 的稳定 Id
    bool               Enabled);    // 绝对置值：true = 启用
```

**为什么分列而不是加一个 `AbilityChangeOp.SetStatus`（按库内既定的三级判据逐面比对）：**

| 面 | `AbilityElements` | 本列 |
|---|---|---|
| 施加语义 | 集合成员**增删** | 已有成员上的**字段绝对置值** |
| 幂等 | 是（增删幂等） | 是（置值幂等），但**语义不同**：重复 `Grant` 是空操作，重复置值是覆盖 |
| `Source` | **强制携带**且校验合法子集、`Unknown` 即整批拒绝 | **无落点**——开关不是一次授予，没有来源可言 |
| `PairKey` / `Duration` | 承载置换配对与禁用时长 | 两格恒空 |
| 失败语义 | 目标不在持有列表 = 可选缺失 + 空操作 | 同左（可沿用） |

`AbilityElements` 明文定位是「改变**持有**」（`:198`）；把一个不改变持有、无 `Source`、无 `Duration`、无 `PairKey` 的操作塞进去，等于让该列的载荷有一半字段对某个 `Op` 恒空——正是 `ChangeElement` 拒绝加可空字段时否决过的形状（`architecture.md:540`）。**新增一列的成本在本库被明确定价为低**：「列表数不进承重表述，它随字段族增长」。同族先例是 `SettingChanges`（同样是「玩家自己拨的开关 · 按固定键绝对置值 · 恒不走 modifier pipeline」）。

**本列的语义六面（供写进 `architecture.md` 的分列理由段）：** 键是 `(Kind, Scope, AbilityId)` 三元组 → 载荷是单个 `bool`；**不钳制**、**无量纲**、**幂等绝对置值**、**恒不走 modifier pipeline**（一条法则若能改写玩家的开关，等于内容替玩家做主）、**无 `Source`**。

**施加失败语义（沿用既有分档，新增三行）：**

| 情形 | 语义 | 处置 |
|---|---|---|
| 目标 `(Kind, Scope, AbilityId)` 不在对应持有列表 | 可选缺失 | `PushWarning` + 该 element 空操作，不使整批失败（与 `Remove` / `Disable` 同档） |
| 同一批内出现两条同 `(Kind, Scope, AbilityId)` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（绝对置值下两条同键 = 调用方自己也不知道该落哪一份；与 `EventStateChanges` / `SettingChanges` 同款） |
| `AbilityStatusChanges` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` / `PlotElements` 同款、**独立成行**）。理由同构：成本侧只放可如实计价的量，「把一个开关关掉」不可计价 |
| `AbilityStatusChanges` 出现在 `EventOutcomeSpec` 任一侧非空 | 必需缺失 | `PushError` + 整批拒绝（判据同 `Stats` / `StatusChanges` 那一行：内容作者能如实声明的量才进 `OutcomeSpec`；**内容不得代替玩家拨开关**） |

**连带：`CapabilityManager.Recompute()` 的触发源清单不变**——`profile-service.md:312` 已列有「`status` 开关」这一触发源，本列只是把它变得可实现。

### 子项 4 · 门面方法收敛为一个，覆盖四类
`[既有推演]`

`SetPowerStatus(string powerId, bool enabled)` 只覆盖 power 且不带 `Scope`，而 `Status` 在**四类** record 上都有（`player-profile/_index.md:57`）、两层都可能有同 `Id` 条目。建议改名并补齐维度：

| 方法 | 形态 | 完整签名 | 失败语义 |
|---|---|---|---|
| 能力开关 | A | `ApplyResult SetAbilityStatus(AbilityCarrierKind kind, AbilityScope scope, string abilityId, bool enabled)` | 未持有 → `ApplyResult.Fail`（业务失败，绝不抛），供 UI 灰显；内部组装单条 `AbilityStatusAssignment` 交一次 `TryApply` |

**判据是库内已用过两次的同一条：** 「两层用同一个门面，用 `AbilityScope` 选层」——`UseItemOutOfCombat` / `ConsumeItem` 正是这样做的，理由明写为「为法宝另开一个 `ConsumeCharacterItem` 会重演按类分裂的方法 / 枚举」（`profile-service.md:388`）。`PowerScope` / `ItemScope` 合并为 `AbilityScope`、`Source` 不按类拆四个是同一条纪律的两个先例。

> **`kind` / `scope` 是否该有默认值：不给。** 与 `GrantPower` 的 `source` 无默认值同款理由——省略即产生歧义调用，而两层可能存在同 `Id` 条目。

### 子项 5 · 道具两类是否对玩家开放这个开关
`[取向选择]` —— **见「仍需用户决定」**

`Status` 结构上四类都有，但库内只有 power 侧写了「玩家可关闭」的产品语义（`player-power/common-properties.md:8`「always-available 且**带开关**……玩家可关闭」）；**道具两类从未陈述过玩家可否关掉一件法宝 / 古宝**。这一格的取舍决定 `CharacterItem.Status` / `PlayerItem.Status` 是活字段还是死字段。

## 具体形态（可 derive 的落地面）

**存档字段（零改动，仅确认）**

| 对象 | 字段 | 类型 | 默认 / 老档缺失 | JSON path | 权威 |
|---|---|---|---|---|---|
| `PlayerPower` | `Status` | `bool` | `true` | `/playerPower/[i]/status`（透明段） | `player-profile/_index.md:57` |
| `PlayerItem` | `Status` | `bool` | `true` | `/playerItem/[i]/status` | 同上 |
| `CharacterPower` | `Status` | `bool` | `true` | `/characterProfile/<id>/characterPower/[i]/status` | 同上 |
| `CharacterItem` | `Status` | `bool` | `true` | `/characterProfile/<id>/magicPack/[i]/status` | 同上 |
| 拥有 / 失去 | — | 列表成员资格 | 缺字段 → 空列表 | 四个持有列表顶层键 | `player-profile/_index.md:15-16` · `character-profile/_index.md:130-131` |

**`ProfileChangeSpec` 新增一列（唯一结构改动）**

```csharp
public IReadOnlyList<AbilityStatusAssignment> AbilityStatusChanges { get; }
public readonly record struct AbilityStatusAssignment(
    AbilityCarrierKind Kind, AbilityScope Scope, string AbilityId, bool Enabled);
```

**门面签名一条**：`ApplyResult SetAbilityStatus(AbilityCarrierKind kind, AbilityScope scope, string abilityId, bool enabled)`（替换 `SetPowerStatus`）。

**schema 版本：不 bump。** 现为 v1 首发前，按 `profile-schema-versions.md:19` 与形态纪律 ①，一切首发前改动归 `schemaVersion = 1`。四条 record 的 `Status` 已在 v1 清单第 21 行；新列**追加进第 22 行**（该行本就在逐列枚举 `ProfileChangeSpec` 的各列与元素类型，`ProfileChangeSpec` 因 `PastEventEntry.SelectCost` / `AppliedChange` 落存档而属形状面）。**登记人 = 本次落笔那一次**（登记时点纪律），不留待日后。

**六份下游文档的逐份改动**（本草稿不落笔，供 `/analyze-new-ideas` 消费）

| # | 文档 | 现在写了什么 | 收口后应改成什么 |
|---|---|---|---|
| 1 | `systems/services/profile-service.md` | `:336` 正确（语义权威）；`:363` 门面为 `SetPowerStatus(powerId, enabled)`；`:37` / `:198` 的分列清单无本列；`:420` 括号内已说明「已成文」但被误读 | `:336` **保留并补两句**：`Status` 的 record 形态权威在 `player-profile/_index.md`、写入通道是 `AbilityStatusChanges`，**并明写「`StatusChanges` 不承载本维」**；`:363` 改为 `SetAbilityStatus(kind, scope, abilityId, enabled)`；`:37` / `:198` 各补本列及其六面；施加失败语义表补三行；`:420` 把括号提为独立句（例：「以下三项**不在本条待决范围内**，已各有权威：……」），消掉再次被读成未决的可能 |
| 2 | `systems/character-profile/item/common-properties.md` | `:23` 待决问题：「`status` 一格与「拥有 / 失去」两个正交维度如何编码进 schema 仍未定，与能力四类同源。→ `profile-service.md`」 | **整条删除**；在「意图」补一段投影：`CharacterItem` 的 `Status: bool`（true = 启用，默认 true）+ 拥有 = `magicPack` 成员资格 + 本轮回禁用是第三维（`disabledAbility`）+ 三条与门，**回链 `player-profile/_index.md:57` 与 `profile-service.md`，不复述 record 定义**。若子项 5 判「道具无玩家开关」，此处改写为「`Status` 恒 `true`、仅供日后扩展」并写明代价 |
| 3 | `systems/character-profile/power/common-properties.md` | `:23`「**持有条目侧仍待定的一格**：`status`……见 `_index.md` 的同名待决项」；`:8` 已正确写有「两个正交维度」 | `:23` 由「待定」改为**已定投影 + 回链**（同上口径）；`:8` 保留，补一句 `Status` 落 `bool` 的 record 形态回链 |
| 4 | `systems/character-profile/power/_index.md` | `:102` 待决问题「**`status` 开关的存档表达**……**仍待定的只剩一条**：`status` 与「拥有 / 失去」这两个正交维度如何编码进 schema。→ `profile-service.md` 的同名待决项」 | **整条删除**（写入面本就已定、编码已定、通道由本方案补齐）。它指向的「`profile-service.md` 的同名待决项」**并不存在** |
| 5 | `systems/player-profile/player-power/common-properties.md` | `:50` 待决问题「**`status` 与「拥有 / 失去」两态的存档表达。** 两个正交维度如何编码进 schema 未定。→ `profile-service.md` 的同名待决项」；`:13` 已是正确的语义表述 | `:50` **整条删除**；`:13` 保留并补「落 `bool Status`（record 形态见 `player-profile/_index.md`）· 写入经 `AbilityStatusChanges`」一句 |
| 6 | `systems/player-profile/player-power/_index.md` | `:14` 已正确（「开关落为 `status` 字段……与「拥有 / 失去」是两个正交维度」）；无待决条目指本编码（`:118` 的「开关 UI 亦未细化」是另一回事） | `:14` 补写入通道一句 + record 形态回链；**`:118` 的「开关 UI 未细化」保留**（本方案不解决 UI 呈现，见「前置依赖」） |

## 后果

- **两份 blocked 转 ready 的直接依据成立**：`item/common-properties.md` 与 `power/common-properties.md` 的**唯一**卡点消失（两份的其余内容均已成文）。`profile-service.md` 的排除面缩小，其剩余卡点收敛为四条元进程 / 成就项（`:418-421`），与本题无关。
- **存档 schema 零改动、零迁移、后端零配合**：`Status` 与四个持有列表的形状均已在 v1 登记，本方案不动任何 Profile 字段。
- **连带触及两份不在本分片写入面内的文档**（属越界，交回 orchestrator）：
  - `systems/architecture.md:340` 的 `ProfileChangeSpec` 代码块需加一列 + `:540` 的分列理由段需加一段（本列的六面已在子项 3 备好）；
  - `systems/services/profile-schema-versions.md:44` 第 22 行需在列枚举中追加 `AbilityStatusChanges` / `AbilityStatusAssignment`（**不 bump**）。
- **`ProfileShapeCheck` 的 golden 快照不受影响**（`ProfileChangeSpec` 不是 `PlayerProfile` 的可达对象；它经 `PastEventEntry.AppliedChange` 间接落存档，而本列在事件路径上恒为空——开关不是事件后果）。
- **索引侧的连带修正**：`open-questions.md` 的「derive 就绪度」把本条描述为「`profile-service.md:336` 与 `:420` 自相矛盾」，该描述与原文不符（见「问题」一节）。就绪度小节由 `/assess-derive-readiness` 独占写入，本草稿不改它，只如实报告。

## 备选方案（已考虑并否决）

- **给 `AbilityChangeOp` 加一个 `SetStatus`，复用 `AbilityElements`。** 否决：该列明文定位「改变**持有**」，且 `Source` 强制携带并校验合法子集（`Unknown` 即整批拒绝），而开关无来源可言；`Duration` / `PairKey` 对它恒空。等于让载荷一半字段对某个 `Op` 无意义——正是 `ChangeElement` 拒绝加可空字段时否决过的形状。
- **把 `Status` 编码进 `disabledAbility`，用一条 `Duration = ThisCycle` 的条目表达玩家关闭。** 否决：`status` 是**账号级持久**开关，`disabledAbility` 随 `CharacterProfile` 拆解 ⇒ 玩家关掉的法则会在下一轮回自己开回来；且 `player-power/_index.md:59` 推论 ④ 已明确否决反向合并（拿账号级 `status` 承载轮回级禁用），本条是它的镜像错误。
- **把「失去」编码为 `status = 禁用` + 保留列表条目（软删除）。** 否决：`profile-service.md:336` 已定「失去 = 移出列表」；软删除会让残卷的 `x`（只数 `SourceCode == FinaleWin` 的**列表条目**）把已失去的法则继续计入，档位不回落，且抽取池的「排除已持有」会把已失去条目继续排除，玩家再也抽不到它。
- **`Status` 用枚举而非 `bool`。** 否决：`player-profile/_index.md:70` 已明写理由——二值开关，第三维另有承载面；枚举会立刻引出「要不要放 `Disabled`」，而那一格属 `disabledAbility`。
- **把 `Status` 变更复用 `StatusChanges` 列。** 否决：`StatusFields` 逐行绑定 `CharacterProfile.Status` 的数值 / id 型规则字段，key 空间与作用对象都不同；混住会让「这个 key 写哪个对象」必须读上下文——正是 `SettingChanges` 拒绝并入 `StatusChanges` 时给出的同一条理由（`architecture.md:562`）。
- **不新开通道，让 UI 直接改 profile 字段。** 否决：违反唯一写入面（`ADR-0009`）。

## 与既有决策的张力

**无硬冲突。** 一处**措辞级**张力，需在落笔时一并处置：

- `open-questions.md`「derive 就绪度」称本条为「🔴 全库解锁面最宽的单一裁决」且「`:336` 与 `:420` 自相矛盾」。**直读后该判断不成立**——`:420` 明写已成文。本方案不推翻任何已定决策，只是把「一次裁决」降级为「一次对齐 + 一处补通道」。就绪度小节的写入权归 `/assess-derive-readiness`，请在下次全量评估时以此更正。

## 前置依赖

- **无阻塞项。** 子项 1–4 全部可由既有决策推演出，不依赖任何待答问题。
- **不在本方案射程内、但相邻的两条（均不阻塞本方案定稿）：**
  - **开关的 UI 形态未细化**（`player-power/_index.md:118`）——「在哪一屏、长按还是 toggle、灰态如何呈现」归元进程界面专场。本方案只定字段与通道，**不定呈现**。
  - **`Achievement` 条目 schema 与账号级条目的解锁 / 获取 / 失去触发**（`profile-service.md:420` 的主体）仍待答，与本题无关，不因本方案关闭。

## 仍需用户决定

**1 项（子项 5）：道具两类（法宝 `CharacterItem` / 古宝 `PlayerItem`）是否对玩家开放 `Status` 开关？**

`Status` 在四类持有条目上都有，但只有 power 侧写过「玩家可关闭」的产品语义；道具侧从未陈述。

- **选项 A（推荐）· 四类一律开放，门面一个方法覆盖。**
  后果：`SetAbilityStatus` 一个方法服务四类，与「两层用同一个门面、用 `AbilityScope` 选层」的既有两处先例（`UseItemOutOfCombat` / `ConsumeItem`）一致；储物袋里可以关掉一件不想在本场自动触发 / 不想误点的法宝。四条 record 的 `Status` 全是活字段。
  代价：多一处 UI（储物袋条目上的开关），且需回答「关掉的法宝算不算占储物袋位」（建议：算——`Status` 不影响持有，与 `disabledAbility` 的「禁用不影响持有、也不影响 `Charges`」逐字同构）。
- **选项 B · 只 power 两类开放，item 两类的 `Status` 恒 `true`。**
  后果：`CharacterItem.Status` / `PlayerItem.Status` 成为**当前无消费点的字段**（库内有先例并已明写接受过一次：`SourceCode` 在 item 层「字段有信息但暂无规则消费者」）。门面方法仍是同一个，但需一条入口校验拦下 `Kind == Item`。
  代价：多一条只为「不许用」而存在的校验；日后开放时要走一次回退。
- **选项 C · 从 item 两类的 record 上删掉 `Status`。**
  后果：四类 record 不再同构，`player-profile/_index.md:57` 的「四者共有」表述与 v1 清单第 21 行须同改。
  代价：**不推荐**——它把一个零成本的 `bool` 换成了一次形状不同构，而道具「按次使用、带 `Charges`」本就有「不用它就是不点它」的天然开关；日后要加回来即一次真实的形状变更（届时已非首发前，须 bump）。

**→ 已裁决（2026-09-06 · 批量评审）：选 A —— 四类一律开放，门面一个方法 `SetAbilityStatus(kind, scope, abilityId, enabled)` 覆盖。** 连带采纳草稿的配套判断：关掉的法宝仍占储物袋位、`Charges` 不变（与 `disabledAbility` 的「禁用不影响持有」逐字同构）。

**推荐 A**，理由：`Status` 已经在四类 record 上（选 B / C 都要为「不用它」额外付出成本），且「关掉一件会自动触发的法宝」与「关掉一条法则」是同一类玩家诉求；一个门面方法即覆盖，不新增任何机制。
