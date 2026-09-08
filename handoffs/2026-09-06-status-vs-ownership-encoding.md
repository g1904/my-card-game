# `status` × 「拥有 / 失去」的存档编码 —— 对齐 + 补一条写入通道

- id: 2026-09-06-status-vs-ownership-encoding
- date: 2026-09-06
- topic: systems/services/profile-service.md · systems/architecture.md · systems/services/profile-schema-versions.md · systems/character-profile/item/ · systems/character-profile/power/ · systems/player-profile/player-power/ · systems/player-profile/_index.md
- status: distilled
- distilled-to: systems/services/profile-service.md、systems/architecture.md、systems/services/profile-schema-versions.md、systems/character-profile/item/common-properties.md、systems/character-profile/power/common-properties.md、systems/character-profile/power/_index.md、systems/player-profile/player-power/common-properties.md、systems/player-profile/player-power/_index.md、systems/player-profile/_index.md、answer-logs/log-status-vs-ownership-encoding.md

## Intent（distilled）

本题的实质不是一次开放裁决，而是**一次对齐 + 一处补通道**：编码本身早已成文（四条持有条目 record + v1 登记表三行），唯一真实的缺口是 `Status` 这一格**没有任何写入通道**。

### 1 · 四条维度的落点（三件事实为四维）

| # | 维度 | 语义 | 落点 | 写入通道 |
|---|---|---|---|---|
| ① | **内容启用** `ContentEnabled` | 运营放量开关：这条内容当前是否发放 | `XxxData` 上的 `bool`，**不落存档** | overlay 覆盖内容资源，不经任何 spec |
| ② | **拥有 / 失去** | 玩家手上有哪些 | 持有列表的成员资格（`playerPower` / `playerItem` / `characterPower` / `magicPack`） | `AbilityElements`，`Op ∈ { Grant, Remove }` |
| ③ | **启用 / 禁用（玩家开关）** | 拥有的这些里哪些**我要用** | 持有条目 record 上的 `bool Status`（true = 启用，默认 true） | **`AbilityStatusChanges`（本次新增）** |
| ④ | **本轮回禁用（外部抑制）** | 拥有的这些里哪些**被剥夺了** | `CharacterProfile.disabledAbility`（顶层键，不落 `Status` 内） | `AbilityElements`，`Op == Disable` 带 `Duration` |

**三条不变式：** 失去 ≠ 禁用（失去 = 移出列表，不是置 `status = 禁用`）· 禁用不挤进 `Status` 那一格（混住即「轮回结束后忘了恢复 = 永久剥夺」）· **生效 = ② ∧ ③ ∧ ④ 的三条与门**，禁用一律截断在进入生效面那一步。②③④ 互不覆盖，故不需要任何优先级或裁决表。

**`StatusChanges` 一条也不管本题的任何一维** —— 它绑定 `CharacterProfile.Status` 上的数值型规则字段，名字撞车、语义无交集。这条反向澄清必须写进正文，否则「`Status` 的变更走 `StatusChanges`」是一个几乎必然会被写出来的误推。

### 2 · 编码本身：维持现状，不改一格

四条 record（`CharacterItem` / `CharacterPower` / `PlayerItem` / `PlayerPower`）的 `Status : bool` 与四个持有列表顶层键的形状**零改动**。`Status` 取 `bool` 不取枚举（二值开关，第三维另有承载面）· 四条取 `readonly record struct` · 条目键名取 `<Kind>Id` —— 三条理由经复核成立。

**老档缺 `status` 格 → 补 `true`。** 默认值口径留在字段所在处，不搬进登记表。

形状不变 ⇒ **零迁移、后端零配合**。

### 3 · 唯一真实缺口：`AbilityStatusChanges` 新开一列

`AbilityChangeOp` 只有 `Grant` / `Remove` / `Disable` 三个语义面，没有一个能表达「把已持有条目的 `Status` 置为 X」；`StatusChanges` 装不下 `(Kind, Scope, AbilityId) → bool`。⇒ 门面上的开关方法此前**无法在不违反唯一写入面纪律的前提下实现**。

```csharp
public IReadOnlyList<AbilityStatusAssignment> AbilityStatusChanges { get; }
// 能力启用开关：按 (Kind, Scope, AbilityId) 的绝对置值

public readonly record struct AbilityStatusAssignment(
    AbilityCarrierKind Kind,        // Power | Item
    AbilityScope       Scope,       // Character | Player
    string             AbilityId,   // PowerData / ItemData 的稳定 Id
    bool               Enabled);    // 绝对置值：true = 启用
```

**分列而不是给 `AbilityElements` 加一个 `Op`**，判据是库内既定的三级分列判据逐面比对：`AbilityElements` 明文定位「改变**持有**」且 `Source` 强制携带（`Unknown` 即整批拒绝），而开关无来源可言、`Duration` / `PairKey` 恒空。塞进去即制造「载荷一半字段对某个 `Op` 恒空」的形状 —— 正是 `ChangeElement` 拒绝加可空字段时否决过的那种。同族先例 `SettingChanges` 逐面同构（玩家自己拨的开关 · 按固定键绝对置值 · 恒不走 modifier pipeline）。

**本列的语义六面：** 键是 `(Kind, Scope, AbilityId)` 三元组 → 载荷是单个 `bool`；不钳制 · 无量纲 · 幂等绝对置值 · **恒不走 modifier pipeline**（一条法则若能改写玩家的开关，等于内容替玩家做主）· **无 `Source`**。

**施加失败语义新增四行**（不在持有列表 = 可选缺失 · 同批两条同键 = 必需缺失 · 出现在 `SelectCost` 内 = 必需缺失 · 出现在 `EventOutcomeSpec` 任一侧非空 = 必需缺失）。末两行独立成行，与既有各列同款；后者的理由是**内容不得代替玩家拨开关**。

**`CapabilityManager.Recompute()` 的触发源清单不变** —— 「`status` 开关」本就在列，本列只是把它变得可实现。

### 4 · 门面收敛为一个方法，覆盖四类

```csharp
ApplyResult SetAbilityStatus(AbilityCarrierKind kind, AbilityScope scope, string abilityId, bool enabled)
```

替换只覆盖 power 且不带 `Scope` 的旧签名。判据是库内已用过两次的同一条：「两层用同一个门面，用 `AbilityScope` 选层」（`UseItemOutOfCombat` / `ConsumeItem`）。**`kind` / `scope` 不给默认值** —— 省略即产生歧义调用，而两层可能存在同 `Id` 条目。失败语义：未持有 → `ApplyResult.Fail`（业务失败，绝不抛），供 UI 灰显。

### 5 · 道具两类一律开放开关

`Status` 在四类持有条目上都是**活字段**：储物袋里可以关掉一件不想自动触发 / 不想误点的法宝。**关掉的法宝仍占储物袋位、`Charges` 不变** —— 与「禁用不影响持有、也不影响 `Charges`」逐字同构。

### 6 · schema：不 bump

`AbilityStatusChanges` 追加进 v1 登记表既有的 `ProfileChangeSpec` 分列行（该行本就在逐列枚举各列与元素类型），**不新开行、不 bump**。

## Clarifications（interview 产物）

- **道具两类（法宝 / 古宝）是否对玩家开放 `Status` 开关** → **四类一律开放，门面一个方法覆盖**（未取「只 power 两类开放、item 两类恒 `true`」，也未取「从 item record 上删掉 `Status`」）。连带采纳：关掉的法宝仍占储物袋位、`Charges` 不变。
- **索引对本题的前提描述** → 直读裁定：`profile-service.md` 的「正交两维」句与元进程待决项**并不矛盾** —— 后者的括号是一句显式排除，明写本编码已成文并给出权威，被索引读成了「登记为未定」。落笔时把该括号**提为独立句**，消掉再次被读成未决的可能。
- **标准默认（自动采纳）：** 新开一列而非加 `Op`（三级判据逐面比对 + `SettingChanges` 先例）· 门面收敛为 `SetAbilityStatus`（`UseItemOutOfCombat` / `ConsumeItem` 两处先例）· 四条失败语义行与「`SelectCost` 内恒为空」散文段照既有各列同款落笔 · 零 bump、零迁移、后端零配合。

## Open questions

- **开关的 UI 形态未细化**（在哪一屏、长按还是 toggle、灰态如何呈现）—— 归元进程界面专场。本次只定字段与通道，不定呈现。
