# `EncounterTighten` 的字段面、「更紧」算子与敌人侧 mana 基线

- id: 2026-08-22-encounter-tighten-fields
- date: 2026-08-22
- topic: systems/services/plot-manager.md · systems/services/combat-service.md · systems/balance.md
- status: distilled
- distilled-to: systems/services/plot-manager.md, systems/services/combat-service.md, systems/balance.md

## Intent（distilled）

**一句话：** `PlotModulation.Tighten` 那一格终于有了类型——`EncounterTighten` 是**五格带方向约束的增量**（回合数 / 胜负门槛 + 起手抽牌数 / 每回合抽牌数 / 手牌上限），「更紧」落成 `min` / `max` 极值算子，`Finale` 整档豁免；同批把 `EncounterSpec` 的可空覆写组补齐，并给敌人侧 `manaLimit` 定了一个可覆写的全局常量。

### 1. `EncounterSpec` 的可空覆写组补齐三格

`balance.md` 早已写明「抽牌数与手牌上限与回合数 / 胜负判据属同一档旋钮，`EncounterSpec` 可携带一组可空覆写」，而 `combat-service.md` 的 `EncounterSpec` record 上没有这三格。以 `balance.md` 为准：**`InitialDraw` / `DrawPerTurn` / `HandLimit` 三格 `int?` 覆写补进 record**，`null` = 取 `CombatRulesData` 默认值。字段名以 `combat-service.md` 为形状权威。

### 2. `EncounterTighten` = 五格带方向约束的增量

```csharp
[GlobalClass]
public partial class EncounterTighten : Resource   // 内嵌子资源：无 Id、无 ContentEnabled
{
    [Export] public int TurnLimitDelta   { get; set; } = 0;   // 恒 <= 0
    [Export] public int WinMarginDelta   { get; set; } = 0;   // 恒 >= 0
    [Export] public int InitialDrawDelta { get; set; } = 0;   // 恒 <= 0
    [Export] public int DrawPerTurnDelta { get; set; } = 0;   // 恒 <= 0
    [Export] public int HandLimitDelta   { get; set; } = 0;   // 恒 <= 0
}
```

**取增量而非绝对覆写值：** 一条 arc 在 `Active` 期间对整批候选生效，而这批里的 Combat 可能物化成 `Practice`（`TurnLimit 8`）也可能是 `Standard`（`10`）。绝对值意味着内容作者必须在写 arc 时就知道会撞上哪一档。增量对三档一致，且与 `LevelBias` 同一种语言——那一格之所以是 bias 而非绝对等级，正因基准值逐次不同。

**方向由符号约束焊死。** `Tighten` 的语义是单向的：剧本可以加压、不能放水（放水的正确形态是换一个更宽的 `combatTier`，那是模板侧编排，剧本够不着）。写成带符号 delta + 加载期方向校验，使「只能收紧」成为内容层根本写不出反例的形态。

### 3. 「更紧」= 极值算子，四格取 `min`、一格取 `max`

三格牌流量与回合数同属「少 = 更难」⇒ 取 `min`；`WinMargin` 是唯一「多 = 更难」的格 ⇒ 取 `max`。恒等元一律 `0`；整个 `Tighten` 全为 `null` → `null`。

**取极值而非相加：** 四条 `Active` arc 各写 `TurnLimitDelta = -1`，相加即 `-4`——`Practice` 的 8 回合掉到 4，把节奏旋钮打穿；对 `DrawPerTurnDelta` 更致命（每回合抽 2 相加两条 `-1` 即归零，牌流量断供），而没有任何一条 arc 的作者意图如此。取极值使加压幅度的上界 = 单条 arc 写得出的最紧值，内容评审逐条看得住。

`min` / `max` 幂等、可交换、可结合 ⇒ 合并顺序不是需要裁决的量，且合并算子与施加算子同构（先合并再施加 = 逐条施加取最紧）。

### 4. `Tier == Finale` 整档豁免

`Finale` 的 `WinMargin` 恒为 `0`，但在增量形态下 `0 + 2 = 2` 是有效果的——「恰好拧不动」并不自动成立，须显式保护。落成一条 tier 闸而非逐格例外：一条闸同时挡住三格牌流量对不可逆终局的调制。剧本给 `Finale` 加压仍只能走敌人侧的 `EnemyPoolScope` + `LevelBias`。

### 5. 覆盖面 = 五格；新增三格各配一个上界常量与一条下界钳制

字段面判据两条连用：① 落**内容面** ⇒ 已有字段够用，落**约束面 / 模板字段面** ⇒ 不加字段；② 该格上必须存在一个**全序 + 一个单调难度方向**，否则「更紧」写不出来。`Enemy`（引用）、`Tier`（枚举，序不是难度序）、`FirstSide`（二值无难度序）、`RewardPoolId` / `BaseReward`（产出侧）、疲劳量（无覆写基准）一律不进。

**新增三格的护栏是硬性配套，不是可选项：** 没有下界钳制，一条剧本条目写 `DrawPerTurnDelta = -2` 就能把每回合抽牌压到 `0`，遭遇从第 2 回合起完全断供——那不是「更紧」，是把战斗做成不可玩。**每一格牌流量都必须同时具备一个内容侧上界常量与一个物化期下界钳制。**

### 6. 常量落点 = `CombatRulesData`（十个）

`MaxTurnLimitTighten 2` / `MaxWinMarginTighten 1` / `MinTurnLimit 6` / `MaxWinMargin 2` 有初值；三格牌流量的六个常量取值归 ch1 数值标杆专场——它们的基准值（4 / 2 / 7）本身尚未经 ch1 校准，先写数字只会制造两轮返工。落点定在 `CombatRulesData` 而非新开资源：它们与遭遇参数默认值是同一档旋钮，消费者同为物化侧。

### 7. 敌人侧 `manaLimit` = 全局常量 `EnemyManaLimit`（初值 5），可被 `EncounterSpec` 覆写

`manaLimit` 落在参战方模型上、每回合刷满，而敌人侧的取值来源全库从未落笔——`baseMomentum` 有表、卡组由 `EnemyData` 逐条编排，唯独 mana 无处可读。定为 `CombatRulesData` 上的一个全局常量并开放 `EncounterSpec` 覆写：与三格牌流量同一档旋钮、同一份资源、同一条覆写纪律。

**代价明写：参战方对称在 mana 这一项被打破，且差距不小。** 玩家侧 `manaLimit` 每次大境界提升 `+1`，第三章玩家约 9~12 而敌人恒 5。这必须在 `combat-service.md` 里列名为**已知例外**，否则「敌人回合的可读性依赖对称」这条纪律会被静默违反而无人察觉。敌人的实际强度差由 `baseMomentum` 与卡组编排承载，不由 mana 承载。

## Clarifications（interview 产物）

| 问题 | 用户裁决 | 推翻 / 细化了原始输入的哪一句 |
|---|---|---|
| `balance.md` 与 `combat-service.md` 对 `EncounterSpec` 覆写组口径不一致，以哪一侧为准 | **以 `balance.md` 为准**，三格补进 `combat-service.md` 的 record | 消解草稿「张力 1」；草稿曾备有「按 `combat-service.md` 现行字段面只写两格」的替代方案，不再采用 |
| `EncounterTighten` 的形态 | **增量**（方向约束 + 极值算子，默认皆 `0`，整体默认 `null`） | 采纳草稿建议方案 1，否决「绝对覆写值」备选 |
| `Tighten` 对 `Finale` | **整档豁免** | 采纳草稿建议方案 3；`plot-manager.md`「只能走敌人侧的两个字段」维持，`balance.md` 侧的 `TurnLimit` 仍是平衡侧（非剧本侧）的 `Finale` 旋钮 |
| 覆盖面：两格还是五格 | **⚠ 逆推荐 · 一并覆盖五格**，并附加要求：新增三格各需一个上界常量与一条下界钳制，取值归 ch1 专场 | 推翻草稿第 6 节「字段面就两格」的推荐；草稿的两条阻塞理由（三格不存在 / 疲劳量待定）已分别由本批的覆写组裁决与「疲劳量不进覆写组」裁决解除 |
| 常量落点 | **全部住 `CombatRulesData`**，随覆盖面扩为十个 | 采纳草稿建议方案 7 |
| 敌人侧 `manaLimit` 取值来源（本批新发现的结构缺口） | **全局常量 `EnemyManaLimit`（初值 5）住 `CombatRulesData`，可被 `EncounterSpec` 覆写**；对称破坏须在 `combat-service.md` 列名为已知例外 | 原始草稿未涉及此项，为提炼过程中发现的缺口 |

## Open questions

- **`EncounterTighten` 三格牌流覆写的上界常量与下界钳制取值。** `MaxInitialDrawTighten` / `MaxDrawPerTurnTighten` / `MaxHandLimitTighten` / `MinInitialDraw` / `MinDrawPerTurn` / `MinHandLimit` 六个常量的具体数字，归 ch1 数值标杆专场；结构性要求（每格各有一个上界与一条下界）已定，**只欠标定**。硬性下限约束已知两条：`MinDrawPerTurn >= 1`（否则牌流量断供）、`MinHandLimit >= MinInitialDraw`（否则起手即弃牌）。
- **`EnemyManaLimit` 初值 `5` 的校准。** 它与玩家侧随境界成长的 `manaLimit` 之间的差距在第三章达到 4~7，敌人的行动空间是否仍够用需实测；校准归 ch1 数值标杆专场。若实测证明敌人在后两章行动空间不足，第一顺位的补法是逐条 `EncounterSpec` 覆写，第二顺位才是改全局常量。

## Notes / triage

- **`future-event-service.md` 有一份承接项未写入本次范围：** 敌人物化管线需补一步「⑤b 剧本收紧」（五格合并 → 施加 → 钳制 → 断言），物化断言清单需加一条「`Tier == Finale` ⇒ 五格遭遇参数全部等于档默认值」，物化日志行需补 `tighten=` 五段。三条钳制（`MinInitialDraw` / `MinDrawPerTurn` / `MinHandLimit`）的施加时点同在该处。
- **`systems/character-profile/mana.md` 持有玩家侧 `manaLimit` 的成长语义**（每次大境界提升 `+1`）；本 handoff 只定敌人侧取值来源与对称例外的措辞，不复述玩家侧语义。
