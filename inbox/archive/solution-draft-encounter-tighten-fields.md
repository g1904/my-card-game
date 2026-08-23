---
type: solution-draft
date: 2026-08-22
question: `EncounterTighten` 的字段面未定 —— 合并算子表里 `Tighten` 一行只能写「逐字段取更紧」，因为这个类型自己的字段面全库从未定义。
source: open-questions/02-event-options.md → 「`EncounterTighten` 的字段面未定（08-22 新增）」；亦见 systems/services/plot-manager.md#待决问题
targets: systems/services/plot-manager.md · systems/services/combat-service.md · systems/services/future-event-service.md · systems/balance.md
status: distilled
distilled-to: handoffs/2026-08-22-encounter-tighten-fields.md
reviewed: 2026-08-22 —— 形态取增量、Finale 整档豁免、四常量住 `CombatRulesData`（均按推荐）；**覆盖面逆推荐裁定为一并覆盖五格**（回合数 / 胜负门槛 + 起手抽牌数 / 每回合抽牌数 / 手牌上限），新增三格各需一个上界常量与下界钳制，取值归 ch1 数值标杆专场。
---

# 方案草稿 — `EncounterTighten` 的字段面与「更紧」算子

## 问题

`PlotModulation` 的六个字段里，五个的合并算子已在 08-22 逐字段定死（`TypeWeights` / `EventWeights` 相乘 · `EventWhitelist` 非空者取并 · `EnemyPoolScope` 取并 · `LevelBias` 相加），唯独 `Tighten` 一行写的是「逐字段取**更紧**的那一个」。

这句话**当前不可机械判定**：`EncounterTighten` 这个类型全库从未落笔——它有哪几个字段、每个字段是 `int` 还是可空、"更紧" 在每个字段上是取 `min` 还是取 `max`、未覆写时的默认值是什么，一样都没有定义。后果是三重的：

- **合并表留一格半成品**——写实现的人对着这一行写不出代码，只能自己发明一套语义。
- **物化管线上有一步无形态**——敌人物化管线的旋钮 ⑤「遭遇参数」明写「按 eventType 改写 `TurnLimit` 与 `VictoryRule`」，并把剧本调制挂在同一处，但挂上去的东西长什么样没写。
- **它是 `PlotModulation` 六字段中唯一没有取值域与加载期校验的一格**，其余五格的校验行都已在 `plot-manager.md` 的剧本条目校验表里。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| C1 | 合并算子**已定为「逐字段取更紧」**——本方案要嵌进这一格，不重开合并语义 | `plot-manager.md`「多条 `Active` arc 的合并算子」 |
| C2 | `Tighten` 的作用面 = **拧紧遭遇参数（`TurnLimit` / `VictoryRule`）**；PlotManager 的权力收敛为三项（框定敌人池 · 偏移带内赋级权重 · 拧紧遭遇参数），**碰不到模板任何字段** | `plot-manager.md`「`PlotModulation` 的字段集合 = 权力面的逐条投影」· `future-event-service.md`「剧情线不可调制敌人模板」 |
| C3 | **`Tighten` 拧 `VictoryRule` 对 `Finale` 无效果**；该档 `WinMargin` 恒为 `0`，剧本要加压 Finale **只能走敌人侧的两个字段** | `plot-manager.md` · `balance.md`「Finale 的难度不再有专属旋钮」· `handoffs/2026-08-22-finale-failure-is-death.md` |
| C4 | 遭遇参数**由 future-event-service 在物化时代入 `EncounterSpec`，产出即定稿落存档**；`EnemyData` 完全不携带，消费侧不得回查模板重算 | `future-event-service.md`「遭遇参数由本服务在物化时代入」· `combat/common-properties.md` |
| C5 | 三档的遭遇参数初值：Practice `8 / 0` · Standard `10 / 1` · Finale `12 / 0`；**回合数 = 节奏旋钮，`WinMargin` 由档语义直接推出、不是可调难度参数** | `balance.md`「`combatTier` 三档的遭遇参数」 |
| C6 | 遭遇参数**不允许用来抵消等级带的约束**；`±2` 赋级带是无例外硬规则 | `future-event-service.md` 旋钮表 · 「推论 ③」 |
| C7 | 内嵌子资源（`EventTypeWeight` / `EventWeight`）**不带 `Id`、不带 `ContentEnabled`、不进 ContentRegistry** | `plot-manager.md` 两个权重类型的声明 |
| C8 | `EventTypeWeight.Multiplier <= 0` 一类的**方向 / 取值域违规在加载期 `PushError`**；`LevelBias` 越界只 `PushWarning`（带不越界由赋级函数保证） | `plot-manager.md` 剧本条目加载期校验表 |
| C9 | **不设先后手差**——先后手不是平衡数值，由 `EncounterSpec.FirstSide` 承载 | `balance.md` 战斗规则卡牌侧数值表 |

> **C2 的作用面在 2026-08-22 扩张（用户裁决 · 逆推荐）：** 「拧紧遭遇参数」不再只指 `TurnLimit` / `VictoryRule`，而是**五格** —— 再加起手抽牌数 / 每回合抽牌数 / 手牌上限。依据：R1-1 已把这三格可空覆写补进 `EncounterSpec`，且 `balance.md` 本就把它们与回合数 / 胜负判据列为**同一档旋钮**。PlotManager 的权力面仍是三项，只是第三项「拧紧遭遇参数」的投影面变宽；模板字段、约束面、产出侧照旧碰不到。

## 建议方案

### 1. `EncounterTighten` = 五格**带方向约束的增量**，不是绝对覆写值

`[既有推演]`（形态）+ **覆盖面已由用户裁决为五格**（2026-08-22 · 逆推荐，见待决项 3）

```csharp
[GlobalClass]
public partial class EncounterTighten : Resource   // 内嵌子资源：无 Id、无 ContentEnabled（C7）
{
    [Export] public int TurnLimitDelta   { get; set; } = 0;   // 恒 <= 0：只减回合，不加回合
    [Export] public int WinMarginDelta   { get; set; } = 0;   // 恒 >= 0：只抬门槛，不降门槛
    [Export] public int InitialDrawDelta { get; set; } = 0;   // 恒 <= 0：只减起手，不加起手
    [Export] public int DrawPerTurnDelta { get; set; } = 0;   // 恒 <= 0：只减每回合抽牌，不加
    [Export] public int HandLimitDelta   { get; set; } = 0;   // 恒 <= 0：只压手牌上限，不抬
}
```

> **三格牌流量的基准来自 `EncounterSpec` 的覆写组三格**（起手抽牌数 / 每回合抽牌数 / 手牌上限），该组由 2026-08-22 裁决 R1-1 以 `balance.md` 为准补进 `combat-service.md` 的 `EncounterSpec` record；**上面三个 delta 的字段名须与那三格落定后的名称对齐**，`combat-service.md` 为准。
>
> **三格的「更紧」方向一律是「少 = 更难」** ⇒ delta 恒 `<= 0`、合并取 `min`，与 `TurnLimitDelta` 同款；只有 `WinMarginDelta` 是「多 = 更难」⇒ 恒 `>= 0`、取 `max`。

**为什么是增量而不是绝对值（承重）：** 一条 arc 在 `Active` 期间会对**整批**候选生效，而这批里的 Combat 可能物化成 Practice（`TurnLimit 8`）也可能是 Standard（`10`）。绝对覆写值意味着内容作者必须**在写 arc 时就知道它会撞上哪一档**——写 `9` 对 Standard 是收紧、对 Practice 是放宽（还得再补一条"不许放宽"的钳制），而写 `7` 又把 Standard 一次砍掉 3 回合。增量对三档一致，且**与 `LevelBias` 同一种语言**——那一格之所以是 bias 而非绝对等级，正是因为基准值（角色等级）逐次不同；这里的基准值（档位默认回合数）同理。

**方向由符号约束焊死，而不是靠字段名提醒。** `Tighten` 的语义是**单向**的：剧本可以加压，不能放水（放水的正确形态是换一个更宽的 `combatTier`，那是模板侧的编排，剧本够不着 —— C2）。把它写成带符号 delta + 加载期方向校验，使"只能收紧"成为**内容层根本写不出反例**的形态，与「越权的写法在内容层根本没有字段可填」同款纪律的一次延伸。

### 2. 「更紧」逐字段落成极值算子（五行）

`[既有推演]`

| 字段 | 类型 | 方向约束 | 「更紧」= | **合并算子（多条 `Active` arc）** | 施加式 | 默认值（未覆写） |
|---|---|---|---|---|---|---|
| `TurnLimitDelta` | `int` | `<= 0` | 更少回合 | **取 `min`**（最负者 = 砍得最狠） | `TurnLimit + →min` | `0` |
| `WinMarginDelta` | `int` | `>= 0` | 更高门槛 | **取 `max`**（最大者 = 门槛抬得最高） | `WinMargin + →max` | `0` |
| `InitialDrawDelta` | `int` | `<= 0` | 更少起手牌 | **取 `min`** | `InitialDraw + →min` | `0` |
| `DrawPerTurnDelta` | `int` | `<= 0` | 更少每回合抽牌 | **取 `min`** | `DrawPerTurn + →min` | `0` |
| `HandLimitDelta` | `int` | `<= 0` | 更窄手牌上限 | **取 `min`** | `HandLimit + →min` | `0` |
| （整个 `EncounterTighten`） | `Resource?` | — | — | 全为 `null` → `null`；否则逐字段按上五行合并（`null` 视同全 `0`） | — | `null` |

**五格里四格取 `min`、一格取 `max`，差别只在方向常量而非算子族**：三格牌流量与回合数同属「少 = 更难」，`WinMargin` 是唯一「多 = 更难」的格。恒等元一律 `0`。

**取极值而不是相加（这正是 C1 那格已经写好的选择，本方案只是把它落成算子）：** 四条 `Active` arc 各写 `TurnLimitDelta = -1`，相加即 `-4`——Practice 的 8 回合掉到 4，等于把节奏旋钮打穿（对 `DrawPerTurnDelta` 更致命：每回合抽 2 相加两条 `-1` 即归零，牌流量断供），而没有任何一条 arc 的作者意图如此。取极值使**加压幅度的上界 = 单条 arc 写得出的最紧值**，内容评审逐条看得住；这与白名单取并那条「护栏由 `MaxConcurrentSideArcs` 与 `ExclusiveGroup` 架好，合并算子不必再承担一次同样职责」同向。

**三条代数性质是免费送的，且它们正是合并表其余各行所依赖的那套：** `min` / `max` 幂等、可交换、可结合 ⇒ **合并顺序不是需要裁决的量**（与「乘法可交换 ⇒ location 与 arc 谁先不必定」逐字同构），且**合并算子与施加算子同构**——先合并再施加与逐条施加取最紧，结果相同。

### 3. `Tier == Finale` 整档不施加 `Tighten`

`[取向选择 — 推荐]` → **已裁决采纳（2026-08-22 · 批量评审）** `[采纳推荐 — 待复核]`（详见 `## 仍需用户决定` 第 2 项）。覆盖面扩到五格后，整档闸的价值更高：它一条闸同时挡住三格牌流量对不可逆终局的调制，不必逐格写例外。

```
if (spec.Tier == CombatTier.Finale) → 跳过 Tighten 施加（不是错误，不告警）
```

C3 明写「剧本要加压 Finale，只能走敌人侧的两个字段」（`EnemyPoolScope` + `LevelBias`）。把它落成**一条 tier 闸**而不是「`WinMargin` 那一格恰好拧不动」，是因为后者在增量形态下**并不自动成立**：`0 + 2 = 2` 是有效果的，`Finale` 的 `WinMargin` 恒 `0` 需要被显式保护。整档闸同时也覆盖了 `TurnLimitDelta`（见待决项 2 的两个选项）。

### 4. 施加点 = 敌人物化管线旋钮 ⑤ 之后、`EncounterSpec` 定稿之前，只施加一次

`[既有推演]`

```
⑤ 遭遇参数  ← combatTier 默认值（Practice 8/0 · Standard 10/0 · Finale 12/0）
⑤b 剧本收紧 ← 全部 Active arc 的 Tighten 逐字段合并 → 施加 → 钳制 → 断言
产出：EncounterSpec（定稿 · 随 EventOption 落存档）
```

- **`EncounterTighten` 本身不进 `EncounterSpec`、不落存档。** 它是物化期的一个输入，施加完即消失；落存档的是**施加后的 `TurnLimit` / `WinMargin` 定值**。依据 = C4「产出即定稿、消费侧不得回查重算」：combat-service 只见 `EncounterSpec`，不该知道剧本存在。**推论：本方案对存档 schema 零改动、零迁移。**
- **与 `LevelBias`（旋钮 ②）互不影响 ⇒ 两者先后不是需要定的量**，同上一条代数论证。
- **物化日志追加一段**（并进既有 `[FutureEvent-Materialize]` 行，不另开日志点）：`tighten=<turnΔ>/<marginΔ>/<initΔ>/<drawΔ>/<handΔ>`；未施加时省略该段。

### 5. 钳制与加载期校验

`[通行做法]` + `[既有推演]`

**两级护栏，与 `LevelBias` 的既有形态同款（内容侧上界 → `PushWarning`；结构性硬界 → 物化断言）：**

| # | 检查 | 时点 | 处置 |
|---|---|---|---|
| V1 | `TurnLimitDelta > 0`（同款：`InitialDrawDelta > 0` / `DrawPerTurnDelta > 0` / `HandLimitDelta > 0`） | 加载期 | `PushError` + arc `Id` + 节点 `Id` + 越界字段名（方向违规；同 `Multiplier <= 0` 那两行的严厉度 —— C8） |
| V2 | `WinMarginDelta < 0` | 加载期 | `PushError` + arc `Id` + 节点 `Id` |
| V3 | 五格皆为 `0` 的非空 `Tighten` | 加载期 | `PushWarning`（等价于不填，多半是编排遗漏；同 `Body` 与 `Modulation` 同时为空那行） |
| V4 | 任一 delta 的绝对值超出该格的**内容侧上界常量**（五个常量，见第 7 节） | 加载期 | `PushWarning`（同 `LevelBias` 越界那行——硬界由下方钳制保证，这里只挡明显的编排失误） |
| V5 | 施加后 `TurnLimit < MinTurnLimit` | 物化期 | 钳制到 `MinTurnLimit` + `PushWarning`（带 arc `Id` + want / got） |
| V6 | 施加后 `WinMargin > MaxWinMargin` | 物化期 | 钳制到 `MaxWinMargin` + `PushWarning` |
| **V5b** | 施加后 `InitialDraw < MinInitialDraw` | 物化期 | 钳制到 `MinInitialDraw` + `PushWarning` |
| **V5c** | 施加后 `DrawPerTurn < MinDrawPerTurn` | 物化期 | 钳制到 `MinDrawPerTurn` + `PushWarning` |
| **V5d** | 施加后 `HandLimit < MinHandLimit` | 物化期 | 钳制到 `MinHandLimit` + `PushWarning` |
| V7 | `Tier == Finale ⇒` 五格遭遇参数全部等于档默认值（`WinMargin == 0`、`TurnLimit` / 三格牌流量 == 档默认） | 物化期 | `PushError` + `EventId` + `InstanceId`（C3 的机械形态，进既有的物化断言清单） |

**三条下界钳制（V5b–V5d）是本次覆盖面扩张的硬性配套，不是可选项：** 没有它们，一条剧本条目写 `DrawPerTurnDelta = -2` 就能把每回合抽牌压到 `0`，遭遇在第 2 回合起完全断供——那不是「更紧」，是把战斗做成不可玩。**每一格牌流量都必须同时具备一个内容侧上界常量与一个物化期下界钳制。**

**钳制而非拒绝：** 一条 overlay 推上去的坏 `Tighten` 应当被削平而不是让这一批 eventOptions 产不出来——与「合法池不足 3 条目时显式降级、不静默」同一条纪律（降级但留痕）。

### 6. 字段面：五格进 `Tighten`，其余各格不进

`[既有推演]`（判据）+ **覆盖面已由用户裁决**（2026-08-22 · 逆推荐，待决项 3）

判据沿用 `plot-manager.md` 已有的那条——**「新增一格物化字段时是否跟着加一格，只看它落在哪一面」**：落内容面 → 已有字段够用；落约束面或模板字段面 → 不加字段。**再叠一条机械条件：该格上必须存在一个全序 + 一个单调难度方向**，否则「更紧」写不出来。

| `EncounterSpec` 的格 | 进 `Tighten`？ | 判据 |
|---|---|---|
| `TurnLimit` | ✅ | 遭遇参数，C2 明列。少 = 更难 |
| `VictoryRule.WinMargin` | ✅ | 同上。多 = 更难 |
| 起手抽牌数（覆写组，R1-1 补入） | ✅ | 与回合数同一档遭遇参数（`balance.md` 明写）；少 = 更难 |
| 每回合抽牌数（覆写组，R1-1 补入） | ✅ | 同上；少 = 更难。**下界钳制不可省**（见 V5c） |
| 手牌上限（覆写组，R1-1 补入） | ✅ | 同上；少 = 更难 |
| 疲劳量 | ❌ | R2-4 已裁决**不进** `EncounterSpec` 覆写组（保留 `CombatRulesData` 全局常量 `1`）⇒ 无覆写基准可拧 |
| `EncounterId` | ❌ | 溯源键，不是旋钮 |
| `Tier` | ❌ | **约束面**——它是篇章闸门 / ADR-0004 重试 / 残卷记账的判据；剧本改它等于造出第二个 Finale（`plot-manager.md`「剧情线不转入 `Finale`」四条理由） |
| `Enemy` | ❌ | **模板字段面**——剧本换敌人的唯一合法表达位是 `EnemyPoolScope`（换池，不改条目） |
| `FirstSide` | ❌ | 先后手**不是难度旋钮**（C9：不设先后手差），无「更紧」方向可言 |
| `RewardPoolId` / `BaseReward` | ❌ | **产出侧**——剧本改产出的正确形态是 `EventWeights` 抬高另一条内容条目的权重（换池，不改内容），与 `SelectCost` 被排除同一条理由 |

**「更紧」要可机械判定，还要求该字段上存在一个全序 + 一个单调方向。** 上表里五格满足：回合数、胜负门槛与三格牌流量都是 `int` 且方向由档语义 / 资源线语义给出。`Enemy`（引用）、`Tier`（枚举，序不是难度序）、`FirstSide`（二值且无难度序）连"哪边更紧"都写不出来——这也解释了为什么 `Tighten` 天然止于这五格。

### 7. 各界的初值（**十个常量**：五格 × 上界 + 硬界）

`[取向选择]`（归 ch1 数值标杆专场校准，见 `## 仍需用户决定` 第 4 项）

**原两格的四个常量（初值已推导）：**

| 常量 | 初值 | 推导 |
|---|---|---|
| 内容侧上界 `MaxTurnLimitTighten` | `2` | Standard `10 → 8` = Practice 的既有回合数，是一个已被论证过的可玩长度；再深一档就没有参照系了 |
| 内容侧上界 `MaxWinMarginTighten` | `1` | `plot-manager.md` 明写「`WinMargin` 1 → 2 是有意义的加压」，正是这一格 |
| 硬界 `MinTurnLimit` | `6` | 双方合计 6 = 各 3 个回合；起手 4 + 每回合抽 2 的资源线在 3 个己方回合内打不出任何 build，低于此即退化为纯起跑线检定（与「Finale 减回合会退化为起跑线检定」同一条论据） |
| 硬界 `MaxWinMargin` | `2` | 领先 3 点以上在 5 个己方回合内接近不可达，且 `±2` 带的起跑线落差已可达同量级 |

**新增三格牌流量的六个常量（2026-08-22 逆推荐裁决产生 · 取值待定，不在此臆造）：**

| 常量 | 初值 | 说明 |
|---|---|---|
| 内容侧上界 `MaxInitialDrawTighten` | **待 ch1 数值标杆专场** | 起手 4 的可压幅度；基准值本身尚未经 ch1 校准 |
| 内容侧上界 `MaxDrawPerTurnTighten` | **待 ch1 数值标杆专场** | 每回合抽 2 的可压幅度；这一格最敏感——基准只有 2，任何压制都是成倍削减 |
| 内容侧上界 `MaxHandLimitTighten` | **待 ch1 数值标杆专场** | 手牌上限 7 的可压幅度 |
| 硬界 `MinInitialDraw` | **待 ch1 数值标杆专场** | 起手牌数的下限；不得为 `0` |
| 硬界 `MinDrawPerTurn` | **待 ch1 数值标杆专场** | 每回合抽牌下限；**必须 `>= 1`**，否则牌流量断供、战斗不可玩 |
| 硬界 `MinHandLimit` | **待 ch1 数值标杆专场** | 手牌上限下限；须容得下起手牌数，否则起手即弃牌 |

> **取值不在本草稿臆造。** 三格牌流量的基准值（4 / 2 / 7）本身仍待 ch1 校准，为它们的可压幅度先写数字只会制造两轮返工。**但「每格必须各有一个上界常量与一条下界钳制」这条结构性要求是本次裁决的附加条件，已在第 5 节 V4 / V5b–V5d 落成机械形态。**

**落点：全部住 `CombatRulesData`**（遭遇参数默认值的同一份平衡资源），不新开资源——它们与 `TurnLimit` / `WinMargin` / 三格牌流量的默认值是同一档旋钮，消费者同为物化侧。落点在 2026-08-22 已可定稿（前置依赖已解除，见 `## 前置依赖`）。

## 具体形态（可 derive 的落地面）

### 合并算子表的 `Tighten` 行改写

`plot-manager.md`「多条 `Active` arc 的合并算子」表的最后一行由

| `Tighten` | 逐字段取**更紧**的那一个 | null |

改写为

| 字段 | 合并算子 | 缺省（= 不参与） |
|---|---|---|
| `Tighten.TurnLimitDelta` | **取 `min`**（最负者；恒 `<= 0`） | `0`，恒等元 |
| `Tighten.WinMarginDelta` | **取 `max`**（最大者；恒 `>= 0`） | `0`，恒等元 |
| `Tighten.InitialDrawDelta` | **取 `min`**（最负者；恒 `<= 0`） | `0`，恒等元 |
| `Tighten.DrawPerTurnDelta` | **取 `min`**（最负者；恒 `<= 0`） | `0`，恒等元 |
| `Tighten.HandLimitDelta` | **取 `min`**（最负者；恒 `<= 0`） | `0`，恒等元 |
| `Tighten`（整体） | 全为 `null` → `null`；否则逐字段按上五行合并，`null` 参与者视同全 `0` | `null` |

**五个恒等元都是 `0`，与相乘那两格的 `1.0` 各自成立**：不修正的写法在两种语言里都是"不填"，`.tres` 里读不出歧义。

### 施加伪码

```
ApplyTighten(EncounterSpec spec, IReadOnlyList<PlotModulation> activeMods) → EncounterSpec
{
    if (spec.Tier == CombatTier.Finale) return spec;          // 建议 3（C3 的机械形态）

    int dTurn = 0, dMargin = 0, dInit = 0, dDraw = 0, dHand = 0;   // 恒等元
    foreach (var m in activeMods)
        if (m.Tighten != null) {
            dTurn   = Min(dTurn,   m.Tighten.TurnLimitDelta);      // 取更紧
            dMargin = Max(dMargin, m.Tighten.WinMarginDelta);
            dInit   = Min(dInit,   m.Tighten.InitialDrawDelta);
            dDraw   = Min(dDraw,   m.Tighten.DrawPerTurnDelta);
            dHand   = Min(dHand,   m.Tighten.HandLimitDelta);
        }
    if (dTurn == 0 && dMargin == 0 && dInit == 0 && dDraw == 0 && dHand == 0)
        return spec;                                                // 无调制 = 原样返回

    // 三格牌流量的基准 = EncounterSpec 覆写组的当前定值（null 时已在旋钮 ⑤ 代入 CombatRulesData 默认值）
    int turn   = Clamp(spec.TurnLimit            + dTurn,   MinTurnLimit,   spec.TurnLimit);
    int margin = Clamp(spec.VictoryRule.WinMargin + dMargin, 0,             MaxWinMargin);
    int init   = Clamp(spec.InitialDraw          + dInit,   MinInitialDraw, spec.InitialDraw);
    int draw   = Clamp(spec.DrawPerTurn          + dDraw,   MinDrawPerTurn, spec.DrawPerTurn);
    int hand   = Clamp(spec.HandLimit            + dHand,   MinHandLimit,   spec.HandLimit);
    // 钳制生效时 PushWarning（V5 / V6 / V5b–V5d），带 arc Id + 字段名 + want / got
    return spec with {
        TurnLimit = turn, VictoryRule = new VictoryRule(margin),
        InitialDraw = init, DrawPerTurn = draw, HandLimit = hand,
    };
}
```

每一格 `Clamp` 的**上界一律写该格的施加前值本身**、下界写各自的硬界常量（`WinMargin` 方向相反，下界写 `0`、上界写 `MaxWinMargin`）：即便方向校验被绕过（overlay 坏数据），**施加也永不放宽**——单向性由施加式自身保证，不只由加载期校验保证。

> 三格牌流量的字段名以 `combat-service.md` 落定的 `EncounterSpec` 覆写组为准（R1-1 补入），此处为示意名。

### 内容侧写法示例（无新增 `Id`，仍是纯剧本条目）

```
// plot.node.bloodlust_backlash.04 —— 煞气反噬线的加压节点
Modulation:
  EnemyPoolScope: "plot.arc.sidestory.bloodlust_backlash"   // 派煞气化身
  LevelBias:      +1                                        // 赋级权重推向带上沿
  Tighten:
    TurnLimitDelta:   -1                                    // Standard 10 → 9
    WinMarginDelta:   +1                                    // Standard 1 → 2
    DrawPerTurnDelta: -1                                    // 每回合抽 2 → 1（受 MinDrawPerTurn 钳制）
    // InitialDrawDelta / HandLimitDelta 不填 ⇒ 0，不参与
```

这正是 `plot-manager.md`「替代形态 = 一场被 `PlotModulation` 拧过的 `Standard` 档 Combat（零新结构）」那句话里 `Tighten` 那一格的具体写法——本方案不新增任何结构，只把那一格填上。

## 后果

- **改动面 = 四份主题文档的文字，本方案自身零 schema 迁移。**（`EncounterSpec` 新增的三格可空覆写归 R1-1 那条裁决的账，不由本方案引入；本方案只是拧它们。）
  - `plot-manager.md`：`PlotModulation.Tighten` 的注释旁补 `EncounterTighten` 五格类型声明；合并算子表 `Tighten` 行按上表**扩为五行**；剧本条目加载期校验表加 V1–V4（V1 覆盖四格方向违规）；移除「`Tighten` 一行只能写到『逐字段取更紧』为止」那句与「待决问题」里的对应条。
  - `combat-service.md`：`EncounterSpec` **本方案不新增字段**（三格牌流量覆写组由 R1-1 单独补入）；补一句「`TurnLimit` / `WinMargin` / 三格牌流量可能已被剧本收紧，本服务只见定值、不知剧本存在」。
  - `future-event-service.md`：敌人物化管线补一步 ⑤b（五格合并 → 施加 → 钳制 → 断言）；物化断言清单加 V7（扩为五格全等档默认）；物化日志行补五段 `tighten=`。
  - `balance.md`：**十个常量**的初值与落点（原四个有初值；三格牌流量的六个标「待 ch1 数值标杆专场」）；`Finale` 那条「拧它（含剧本侧的 `EncounterTighten`）零效果」由"恰好无效"改写为"整档闸"。
- **存档 / 迁移：无。** `EncounterTighten` 不落存档；被施加的五格在 `EncounterSpec` 上本来就是 `int`（三格牌流量为可空 `int?`，物化时已代入定值），取值变化不改形状。
- **对内容层的要求：** 新增一格 `[Export]` 子资源的写法（`Tighten` 是可空引用），内容作者不填即 `null`。**不需要任何新 `Id`** ⇒ 「新增剧本条目不得引用本次 overlay 之外的新 `Id`」那条机械闸不受影响。
- **热更面：** 五个 delta 与十个常量都可 overlay 线上改（都是取值不是结构），与「阈值 / δ / 文案可线上改」同档。

## 备选方案（已考虑并否决）

- **绝对覆写值 + 取 `min` / `max`（`int? TurnLimit` / `int? WinMargin`）。** 否决：内容作者写 arc 时不知道会撞上哪一档，同一个绝对值对三档语义不同；且要额外补一条"不许放宽"的钳制才等价于本方案的符号约束。它唯一的优势是"更紧"读起来更直白（`min` 直接作用在最终值上），但那点可读性买不回跨档不可写的代价。
- **多条 arc 的 delta 相加。** 否决：加压幅度随并发 arc 数线性放大（四条各 `-1` 即 `-4`），把回合数这个节奏旋钮打穿；且它会改写 C1 已定死的那一格。**若用户希望叠加，本方案不成立，须先改合并算子表**——这是一次对既定决策的推翻，不由本草稿代做。
- **把 `Tighten` 做成一个通用的「遭遇参数覆写包」（镜像 `EncounterSpec` 的全部可覆写旋钮）。** 否决：它会把 `FirstSide` / `RewardPoolId` 一类无"更紧"方向、或落在产出侧 / 约束面的格子一并拉进来，破坏 C2 的「权力面逐条投影」——那正是 `PlotModulation` 六字段能当作可执行化阶梯第 1 级（越权写法在内容层没有字段可填）的全部依据。**注（08-22 裁决后）：** 覆盖面扩到五格**不是**采纳本条——扩进来的三格牌流量各自具备单调难度方向，仍受第 6 节判据把关；`FirstSide` / `RewardPoolId` / `Tier` / `Enemy` 照旧不进。
- **`Tighten` 落存档（进 `EncounterSpec`）以便战斗侧回溯"这场为什么更凶"。** 否决：违反 C4（消费侧不回查）与「重算得出来的不存」；溯源诉求由物化日志承担。

## 与既有决策的张力

1. **`balance.md` 与 `combat-service.md` 对 `EncounterSpec` 的字段面口径不一致（承重 · 直接影响本方案）。**
   `balance.md` 两处明写「`EncounterSpec` 可携带一组可空覆写（null = 取平衡资源默认值）：**抽牌数与手牌上限**与回合数 / 胜负判据属**同一档旋钮**」，而 `combat-service.md` 里 `EncounterSpec` 的八个字段中**没有这三格**。
   本方案第 6 节的字段面判据建立在"`EncounterSpec` 上确实存在的旋钮"之上，故这处不一致会直接改变结论：若那三格补进 `EncounterSpec`，就要重新回答"它们进不进 `Tighten`"（见待决项 3）。
   **不松动时的替代方案：** 本方案按 `combat-service.md` 的现行字段面落笔（只两格），并在文档里写明"`Tighten` 的字段面 = `EncounterSpec` 可覆写旋钮集合中**存在单调难度方向**的那些格；新增覆写旋钮时按此判据复核一次"——使日后补格不必重开本问题。
   → 已裁决（2026-08-22 · 批量评审）：**以 `balance.md` 为准**（R1-1）—— 起手抽牌数 / 每回合抽牌数 / 手牌上限三格可空覆写补进 `combat-service.md` 的 `EncounterSpec` record。张力消解，本方案第 6 节据此扩到五格。判据那句仍照写（供日后再补格时机械复核）。

2. **`plot-manager.md`「剧本要加压 Finale，只能走敌人侧的两个字段」与 `balance.md`「校准 Finale 难度的三条替代手段之一是 `TurnLimit`」的张力。**
   前者的上下文只论证了 `VictoryRule` 那一格拧不动，却推出了"只剩敌人侧两个字段"这个**覆盖整个 `Tighten`** 的结论；后者则把 `TurnLimit` 明确列为 Finale 的有效难度旋钮（只是归平衡侧而非剧本侧）。两句话在"剧本能否用 `TurnLimitDelta` 加压 Finale"上给出不同答案。
   **建议 3 取前者**（整档闸），代价是关掉一条真实有效的加压通道；取后者则须改写 `plot-manager.md` 那句。见待决项 2。
   → 已裁决（2026-08-22 · 批量评审）：取前者 —— **`Tier == Finale` 整档豁免 `Tighten`**，`plot-manager.md` 那句维持，`balance.md` 侧的 `TurnLimit` 仍是平衡侧（非剧本侧）的 Finale 旋钮 `[采纳推荐 — 待复核]`

## 前置依赖

- **单例平衡资源如何进 ContentRegistry**（`open-questions/01-combat.md`「结构与配置的残留」）—— **已解除（2026-08-22 · 批量评审）**：R1-2 裁定不设兜底大表、按三问判据逐份切，且同批草稿定下单例进注册表的形态（`Id` 两段式 · 泛型仓储 · `Single<T>()` · `ISingletonContent`）。本方案十个常量的落点因此可定稿为**住 `CombatRulesData`**。
- **`EncounterSpec` 覆写组三格本身不存在** —— **已解除（2026-08-22 · 批量评审 R1-1）**：以 `balance.md` 为准，起手抽牌数 / 每回合抽牌数 / 手牌上限三格可空覆写补进 `combat-service.md` 的 `EncounterSpec` record。待决项 3 因此得以定稿（并裁为一并覆盖五格）。
- **ch1 数值标杆专场**——第 7 节的常量取值仍待校准：原四格是初值（`MinTurnLimit = 6` 依赖尚未定的「一张牌该产多少道念」与起始卡组平均费用），**新增三格牌流量的六个常量则完全待定、本草稿不给数字**。**它约束标定，不约束结构。**
- **疲劳量是否成为 `EncounterSpec` 的可空覆写**（`open-questions/01-combat.md`，08-11c）—— **已解除（2026-08-22 · 批量评审 R2-4）**：裁定**不加**，保留 `CombatRulesData` 全局常量 `1`。故疲劳量不进 `Tighten`（第 6 节已记）。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> - **1 形态** → **A · 带方向约束的增量**（`TurnLimitDelta <= 0` 取 `min`、`WinMarginDelta >= 0` 取 `max`，默认皆 `0`，整体默认 `null`） `[采纳推荐 — 待复核]`
> - **2 对 `Finale`** → **A · 整档豁免**（`Tier == Finale` 跳过整个 `Tighten`） `[采纳推荐 — 待复核]`
> - **3 覆盖面** → **⚠ 逆推荐 · B · 一并覆盖五格**（`TurnLimit` / `WinMargin` + 起手抽牌数 / 每回合抽牌数 / 手牌上限）。**正式拍板。** 附加要求（用户已知会）：**新增三格各需一个内容侧上界常量与一条物化期下界钳制**，否则剧本能把每回合抽牌压到 `0`；取值归 ch1 数值标杆专场，本草稿不臆造。
> - **4 常量落点与初值** → **A · 全部住 `CombatRulesData`** `[采纳推荐 — 待复核]`；原四常量初值照 A 采纳，并**随裁决 3 扩到十个常量**（新增六个取值待 ch1 专场）。
> - 前置依赖「`EncounterSpec` 覆写组三格不存在」已由 R1-1 解除，张力 1 随之消解。

1. **形态：带方向约束的增量 vs 可空的绝对覆写值。**
   - **选项 A（推荐）：增量** `TurnLimitDelta <= 0` / `WinMarginDelta >= 0`。**后果：** 一条 arc 对三档一致生效，与 `LevelBias` 同语言；代价是"更紧"作用在 delta 上而非最终值上，读表时需多想一层（`min` 作用于负数）。
   - **选项 B：绝对覆写** `int? TurnLimit` / `int? WinMargin`，合并取 `min` / `max`。**后果：** "取更紧"字面直观；代价是内容作者必须预知撞上哪一档，且要补一条"不许放宽"的钳制。
   - **理由（推荐 A）：** `PlotModulation` 已有的偏移型字段（`LevelBias`）正是因为基准值逐次不同才写成 bias，此处基准值（档位默认回合数）同理；且 A 让"只能收紧"成为内容层写不出反例的形态。
   → 已裁决（2026-08-22 · 批量评审）：A · 增量（`TurnLimitDelta <= 0` 取 `min`、`WinMarginDelta >= 0` 取 `max`，默认皆 `0`，整体默认 `null`）；三格牌流量的 delta 同为 `<= 0` / 取 `min` `[采纳推荐 — 待复核]`

2. **`Tighten` 对 `Finale` 的作用面：整档豁免，还是只有 `WinMargin` 那一格无效？**
   - **选项 A（推荐）：整档豁免**——`Tier == Finale` 时跳过整个 `Tighten`。**后果：** 完整保住 `plot-manager.md` / `balance.md` / 08-22 handoff 三处同调的既定表述（剧本给 Finale 加压只剩敌人侧两个字段）；一条玩家不可见的隐藏 arc 无法给"失败即角色终结"的不可逆遭遇加压。代价 = 关掉一条真实有效的加压通道（减回合对开局落后 5 / 13 / 25 的 Finale 是强加压）。
   - **选项 B：只封 `WinMarginDelta`**，`TurnLimitDelta` 对 Finale 照常生效。**后果：** 剧情线可以给天劫加压且形态自然；代价 = 必须改写 `plot-manager.md`「只能走敌人侧的两个字段」那句，且 `balance.md`「12 回合是对开局落差的部分补偿」这条论据在被剧本收紧时不再成立，需连带重估。
   - **理由（推荐 A）：** Finale 失败不可逆（角色终结 + 篇章不推进 + 残卷记账），把不可见的调制接进不可逆终局的判定，与「隐藏属性影响遭遇是拧参数」的可接受度不在同一档；且 A 是一条闸而不是逐字段例外，机械形态更简单（V7 一条断言即可）。
   → 已裁决（2026-08-22 · 批量评审）：A · 整档豁免 —— `Tier == Finale` 跳过整个 `Tighten`（不是错误、不告警） `[采纳推荐 — 待复核]`

3. **`Tighten` 要不要覆盖「起手抽牌数 / 每回合抽牌数 / 手牌上限 / 疲劳量」？**
   - **选项 A（推荐）：不覆盖，字段面就两格。** **后果：** 本方案可立即落笔；日后那几格真的进了 `EncounterSpec`，按第 6 节写下的判据（存在单调难度方向 ⇒ 可镜像进 `Tighten`）复核一次即可，不必重开本问题。
   - **选项 B：一并覆盖。** **后果：** 剧本的加压手段更丰富（"这条线上你的手更窄"）；代价 = 它们在 `combat-service.md` 的 `EncounterSpec` 里**尚不存在**（张力 1），且"疲劳量是否成为覆写"本身仍在待答（前置依赖 3）——等于让本问题被另外两个未决项阻塞。
   - **理由（推荐 A）：** 不臆造尚未落笔的字段；且判据一旦写进文档，扩展是一次机械复核而非一次设计裁决。
   → 已裁决（2026-08-22 · 批量评审）：**⚠ 逆推荐 · B · 一并覆盖**「起手抽牌数 / 每回合抽牌数 / 手牌上限」三格（疲劳量**不覆盖** —— R2-4 裁定它不进 `EncounterSpec` 覆写组）。**正式拍板**，不带待复核。推荐 A 的两条阻塞理由均已在同批解除：三格由 R1-1 补进 `EncounterSpec`，疲劳量由 R2-4 关闭。
   **orchestrator 附加要求（用户已知会）：** 新增三格**各需一个内容侧上界常量与一条物化期下界钳制**，否则一条剧本条目即可把每回合抽牌压到 `0`。取值归 ch1 数值标杆专场，本草稿不给数字。

4. **四个常量的落点与初值。**
   - **选项 A（推荐）：全部住 `CombatRulesData`，初值 `MaxTurnLimitTighten = 2` / `MaxWinMarginTighten = 1` / `MinTurnLimit = 6` / `MaxWinMargin = 2`**，标注为待 ch1 数值标杆专场校准。
   - **选项 B：内容侧两个上界住剧本调制侧的平衡资源**（与 `LevelBias` 的上界同住），硬界两个住 `CombatRulesData`。**后果：** 按"谁产生越界"分居更贴近来源；代价 = 一个概念裂在两份资源里，读的人要跳两次。
   - **理由（推荐 A）：** 四个数的消费者同为物化侧的同一段代码，且它们与 `TurnLimit` / `WinMargin` 的默认值是同一档旋钮；`LevelBias` 上界分居的先例服务的是"赋级"这个独立子系统，此处没有对应的第二个子系统。
   - ⚠ 落点受「单例平衡资源如何进 ContentRegistry」阻塞（见 `## 前置依赖`）。**该阻塞已于 2026-08-22 解除**（R1-2 + 同批单例草稿）。
   → 已裁决（2026-08-22 · 批量评审）：A · **全部住 `CombatRulesData`**，原四常量初值照 A（`MaxTurnLimitTighten = 2` / `MaxWinMarginTighten = 1` / `MinTurnLimit = 6` / `MaxWinMargin = 2`），标注待 ch1 校准 `[采纳推荐 — 待复核]`。**随裁决 3 扩为十个常量** —— 新增 `MaxInitialDrawTighten` / `MaxDrawPerTurnTighten` / `MaxHandLimitTighten` / `MinInitialDraw` / `MinDrawPerTurn` / `MinHandLimit`，同住 `CombatRulesData`，取值全部待 ch1 数值标杆专场。
