# 敌人 AI 定制策略 = 权重向量的重新加权

- id: 2026-08-26c-enemy-ai-strategy-shape
- date: 2026-08-26
- topic: systems/enemies/_index.md · systems/enemies/common-properties.md · systems/services/combat-service.md · systems/adventure-event/combat/_index.md · systems/balance.md
- status: distilled
- distilled-to: `systems/enemies/_index.md`、`systems/enemies/common-properties.md`、`systems/services/combat-service.md`、`systems/adventure-event/combat/_index.md`、`systems/balance.md`

## Intent（distilled）

### 起因：`EnemyData` 的「定制 AI 策略」一格写不出字段类型

`ADR-0092` 已把归属与约束定死（两层结构 · 可空即回落兜底 · 只表达打法风格 · 决策是纯函数 · 输入面限对称可见信息），但**形态列只写着「表达形态待定」**。字段类型写不出 ⇒ `systems/enemies/` 无法 derive。连带四项同样悬着：具体算法、决策粒度、多回合行为倾向、兜底与定制的强弱差口径。

本次一次性给出这五项的落地形态。

### 1. 那一格 = 对一条独立可复用资源的直接类型引用

```csharp
// EnemyData 上（可空）
[Export] public EnemyAiProfileData AiProfile { get; set; }   // null = 走通用兜底

[GlobalClass]
public partial class EnemyAiProfileData : Resource
{
    [Export] public string     Id             { get; set; } = string.Empty;  // enemy_ai.<snake_case_slug>
    [Export] public bool       ContentEnabled { get; set; } = true;
    [Export] public AiWeight[] Weights        { get; set; } = [];            // 只列要覆写的项
}

[GlobalClass]
public partial class AiWeight : Resource        // 内嵌 Resource + 两个具名字段，同 TechniqueRef
{
    [Export] public AiTerm Term  { get; set; }
    [Export] public float  Value { get; set; } = 1.0f;
}
```

判据正是待答项要求交代的那一条——**是否需跨条目复用**：需要，且是常态。定制策略表达的是**打法风格原型**（守势 / 抢攻 / 消耗 / 埋伏流），一种风格天然被一批敌人共享；内联意味着「把守势打法调一档」要逐个敌人条目改一遍，漏一个即得到一条半改的风格。反面判据同样成立：`PoolScope` / `TechniqueRef` 取内联，是因为它们逐条目独有、从不共享。

引用形态照抄 `AbilityData`（直接类型引用，不写 `AiProfileId : string`）——那是本库「有稳定 `Id`、进注册表、被多个载体引用」的既有形状。

- **不挂 `Rarity`**：它不进任何抽取池。
- **profile 只列要覆写的项**，未列项取兜底默认值：兜底调参自动惠及全部 profile，且 profile 文件短到一眼能读出「这个敌人偏在哪」。
- **profile 内无第二类结构位**：只有权重向量，「优先打关键卡」「保留 N 点 mana」这类偏好一律表达为某个 term 的权重。多开一格结构就是多开一条与权重并行的表达通道，此后每条策略都要回答「这件事该写在哪一格」。

### 2. 决策粒度 = 逐张，且每次重算候选集

一次决一个动作，执行到栈清空后重新组装候选集再决下一个。理由是必然而非偏好：**栈结算会改变局面**（连锁触发、道念被下限 0 截断、条目落场 / 离场），一次性规划出的第 2、3 个动作在执行到时的合法性与价值都可能已经变了。「逐张」说的是 AI 在自己回合内的内部推进顺序，与「敌人回合内部不落决策点、D5 一个点覆盖整段」完全自洽。

### 3. 兜底算法 = 单层（1-ply）加权效用评分 + 确定性 argmax

```
EnemyTurn():
    while (step == Action && stack.IsEmpty):
        candidates ← { PlayCard(c)           | c ∈ 己方手牌, c.ManaCost <= currentMana, 每个槽位 LegalTargets 非空 }
                   ∪ { UseItem(i)            | i ∈ 本场可用道具, Profile 侧充能未耗尽 且 本场配额未用尽 }
                   ∪ { ActivateAbility(e, a) | a ∈ 己方战场条目 e 的启动式异能,
                                               a.ManaCost <= currentMana 且 counters[a.Id] < a.MaxActivationsPerCombat }
                   ∪ { EndTurn }
        对每个候选先解析目标，再算 score(a) = Σ_k  w_k · term_k(a, view)
        score(EndTurn) ≡ 0                       // 天然基线：无正分动作即结束回合
        取 argmax；平手按确定性字典序打破
        若选中 EndTurn → break；否则执行、等栈结算干净、回到循环
```

- **`score(EndTurn) ≡ 0` 是承重的**：它把「还该不该继续行动」变成 argmax 的自然产物，不需要第二套「何时收手」的规则；同时它意味着权重向量恒有一个绝对零点，`w` 的取值域因此可被钳制。
- **单层试算，不模拟连锁触发**：每个候选的收益按该动作自身 `EffectData` 在求值管线（加法层 → 乘法层 → 下限 0 截断）上跑一遍得出，不展开它可能引发的触发链。模拟连锁等于把 StackManager 的结算在评分里重跑一遍（性能与正确性双重风险），且它正是强度上界的主要来源之一。**须明写为规则**，否则日后有人顺手加一层，上界当场失效。
- **`AiTerm` 十项初值，开放可加**（形态照抄 `EffectData` 原子操作清单）：`MomentumGain` · `MomentumDenial` · `ManaEfficiency` · `BoardPresence` · `Removal` · `AmbushCaution` · `HandRetention` · `KeyCardAffinity` · `ClosingUrgency` · `ItemEagerness`。逐项语义落 `systems/enemies/_index.md`。
- **`KeyCardAffinity` 有一条免费的正向副作用**：`KeyCardIds` 是图鉴「关键卡牌」词条的数据源，而图鉴是事前知识的主通道；让 AI 真的偏向打出关键卡，使图鉴所述与玩家实际观察到的行为对齐。

### 4. 目标选择 = 同一评分函数，零随机

对每个槽位，在既定的 `LegalTargets` 求解结果中取**使该动作试算分数最高**的那一个；仍平手 → 取 `LegalTargets` 序列中的第一个（该序列由战场条目顺序确定性产出）。

- 复用同一个评分函数，不为目标另写一套启发式——两套会各自漂移，而本库没有机制发现它们不一致。
- `LegalTargets.Count == 0` 的槽位使该候选**整个不进候选集**（不是先选中再 fizzle）。

### 5. 全流程零随机

兜底与定制策略均不消耗任何随机。平手打破取确定性字典序：`(−score, 动作种类序 PlayCard < UseItem < ActivateAbility < EndTurn, SubjectId 的组装序)` 取最小。实例发号本就是确定性的（`c#0` / `e#0`…，闭集按固定顺序发号），故「组装序」是一个现成的、可复现的全序，不需要新增任何状态。

- 承重理由不止工程：可读性支柱把**敌人图鉴定为事前知识的主通道**（敌人不作任何事前预告）。图鉴的价值建立在「这个敌人会怎么打是可学习的」之上；给 AI 掷骰等于直接稀释这份价值。代价是重复遭遇同一敌人时行为完全一致，可能显得机械——解法更便宜：多写两条 profile，让同一批敌人打法各异。
- 零随机使 `ADR-0092`「随机只取 `combat` 子流」成为一条**空约束**——保留它，作为日后引入随机化权重项时的约束。

### 6. 多回合行为倾向 = 局面函数，零记忆，`ActiveCombat` 一格不加

一切「倾向」都写成当前局面的函数——`turnIndex` / `turnLimit`（剩余回合数）· 双方道念差 · 自己抽牌堆余量（疲劳临近）· 自己战场上的条目 · 手牌张数，**全部已在 `ActiveCombat` 内**。

- 「前期铺场、后期梭哈」这类跨回合叙事由 `ClosingUrgency` / `BoardPresence` 两个 term 表达，不需要一个「我打算铺场」的记忆位。
- 收益是结构性的：`ActiveCombat` schema 一格不加、零迁移，且「敌人回合是一段可确定性重放的区间」原样成立——退出重进重放整段不可能分叉，因为压根没有不在存档里的东西。
- **AI 不得持有任何跨动作、跨回合的私有字段**：把 `ChooseAction` 写成 `static` 纯函数，私有记忆在语言层无处存放（`ADR-0013` 第 1 级）。

### 7. 强弱差口径 = 三条结构性上界

| # | 上界 | 它封住了什么 | `ADR-0013` 级别 |
|---|---|---|---|
| ① | 定制层只提供 `w` 向量，不提供代码 | 定制与兜底跑同一条 argmax 循环、同一套 term、同一个候选集：无法多看一层、无法多算一步、无法读到兜底读不到的输入 | 第 1 级 |
| ② | 搜索深度恒为 1-ply，且试算不展开连锁 | 强度天花板由算法深度决定，而深度是代码常量、不在数据面上 | 第 1 级 |
| ③ | `Value` 钳在 `[AiWeightMin, AiWeightMax]`，加载期越界 `PushError` + 抛 | 极端权重只能让 AI 偏科，不能让它更强——分数是同一批 term 的线性组合，缩放不改变可达动作集 | 第 3 级 |

推论：定制策略在结构上「不强于兜底」已近乎自动成立——它是兜底在同一搜索空间内的一次重新加权。剩余的自由度（某种偏科恰好特别克某类玩家套路）确实不可机械校验，那一小块仍留在编排口径，与 `ADR-0092` 一致。

### 8. 数值分层：兜底向量与取值域住 `CombatRulesData`，profile 逐条取值住内容层

| 数值 | 落点 |
|---|---|
| 兜底权重的默认向量（每个 `AiTerm` 一个 `float`） | `CombatRulesData`（平衡资源） |
| `AiWeightMin` / `AiWeightMax` | `CombatRulesData`——与默认向量有跨字段不变式（默认值必须落在区间内），按 `ADR-0074`「有跨字段不变式的同住一份」**必须同住** |
| 定制 profile 的权重覆写 | `EnemyAiProfileData`（内容层 `.tres`），文档权威 = `content/enemy-ai/<id>.md` |

**这不违反 `ADR-0074`**：该 ADR 的靶子是「服务配置」这第三层；内容 `.tres` 与平衡 `.tres` 两层都在它认可的范围内，而 `EnemyAiProfileData` 经 ContentRegistry 加载、受 overlay 覆盖、受启动期强校验——三条理由逐条满足。

`systems/balance.md` 只承载兜底向量与取值域，**不承载任何 profile 的逐条取值**；`systems/enemies/*` 只写类定义与形态。

### 9. 读取面：AI 与 UI 共用同一个 `CombatSnapshot`，双视角化

`CombatSnapshot` 增一格 `viewerSide`，**不新增第二个投影类型**。字段语义一字不改——`SideSnapshot.HandCardInstanceIds` 仍是「仅 viewer 己方非空、对侧恒为空」，只是「己方」随 `viewerSide` 解释。

- EnemyManager 规划时取 `viewerSide` = 该敌人的 `OwnerSide`；UI 组装与决策点存档取 `viewerSide = Character`。
- **缓存与按变更广播按 `viewerSide` 分别持有**（两份缓存，同一次组装），不跨视角复用一份。
- `viewerSide: Enemy` 的 snapshot 里玩家手牌内容**结构上不存在** ⇒ `ADR-0092`「不读玩家手牌内容 / 输入面限对称可见信息」仍停在 `ADR-0013` 第 1 级（写不出来），不退回纪律级。对手埋伏只给计数、对手手牌只给张数两条对称可见口径由同一字段语义承担，不另立规则。
- **读侧统一、写侧分权**这条既有推论因此原样成立，一字不改。

### 数据驱动纪律：正面处理

| 内容动作 | 要不要写 C# |
|---|---|
| 新增一个敌人（可引用已有 profile） | 不要 |
| 新增一种打法风格（重排权重） | 不要——新增一个 `EnemyAiProfileData.tres` |
| 调整某种风格 / 调整兜底 | 不要——改 `.tres`，走 overlay 热更 |
| 新增一个从未有过的考量维度（新 `AiTerm`） | 要——加一个枚举值 + 一个 term 函数 |

最后一行不违反「新增一张卡牌 = 新增一个 `.tres`，而不是编辑某个 switch」：它与 `EffectData` 原子操作清单逐字同构——**原语在代码、组合在数据**。纪律真正禁止的是「分支数随内容条目数增长」的 switch，而本方案里 term 的分支数 ≈ 10，与敌人条目数、profile 条目数都无关。

两条被正面否决的替代：**每类策略写一个 C# 策略类 + 条目上填类名**（分支数随内容增长 · 策略无法经 overlay 热更 · 绕开启动期内容强校验）；**行为树 / 规则 DSL 落 `.tres`**（把「策略是数据不是代码分支」拖回一个需要求值器与沙箱的小语言，overlay 热更一段脚本的风险面远大于改一个数值，且会让 §7 ①② 两条上界当场失效）。

## Clarifications

- **AI 的读取面（🔴：草稿的 `AiCombatView` 与「读侧统一读 `CombatSnapshot`」正面打架）→ 单一投影，`CombatSnapshot` 双视角化。** 不新增 `AiCombatView`；给 `CombatSnapshot` 加 `viewerSide`，AI 与 UI 共用同一投影，缓存按 `viewerSide` 分别持有。字段语义不变，故输入面约束仍停在 `ADR-0013` 第 1 级。推翻了原始输入中「两个投影，不复用」的整段，连带作废它自陈的「两份视图可能漂移」代价。`ADR-0092` 本体不改——本次只改变它的实现载体。
- **profile 逐条权重取值的权威落点（🔴：草稿 §8 判它属内容层、§9 又说权威在 `balance.md`）→ 归内容层。** `content/enemy-ai/<id>.md` 是 profile「填了什么值」的文档权威；`systems/balance.md` 只写兜底默认向量与取值域；`systems/enemies/*` 只写类定义与形态。推翻原始输入中「权威天然落在 `systems/balance.md` 的权重表」那句。**本次不开张 `content/enemy-ai/` 文件夹、不写条目**——开张动作归 `/scaffold-content-type enemy-ai`。
- **AI 是否需要随机化 → 全确定性**（评审裁决）。零随机消耗，与 `combat` 子流的形态完全解耦；`ADR-0092` 那句在本方案下为空约束，`enemies/_index.md` 相应改写为「本方案不消耗随机；日后若引入随机化权重项，随机只取 `combat` 子流」。
- **强弱差是否另加带数字的胜率口径 → 不加**（评审裁决）。只写结构性上界；该数字在量纲基准与 starter deck 成型之前无法测量，此刻写下即是一条无人执行的第 4 级条款。
- **`ADR-0092` 的软口径张力 → 不推翻、只加固**（评审裁决）。§7 三条全部采纳，取值域越界保留 `PushError` + 抛：一条写成 `Value = 999` 的 profile 能上线且线上不可见，按 `ADR-0013` 的选级判据正是必须做到第 1 / 2 级的那一档。
- **AI 读到的战场条目复用 `BattlefieldEntryView`**（采纳的默认），不分叉第二个类型。异能可用性属对称可见信息（战场条目公开 · mana 公开 · `counters` 为公开计数），不违反输入面约束。
- **候选集里启动式异能一项的准入条件 = `a.ManaCost <= currentMana` 且 `counters[a.Id] < a.MaxActivationsPerCombat`**（采纳的默认）——`ActivateAbility` 的契约权威在 `systems/services/combat-service.md` 的 API 面，AI 侧只是引用方，两个闸一个都不能漏。
- **道具一项的措辞对齐既有概念**（采纳的默认）：`ItemData.Charges` 的 Profile 侧充能与 `CombatItemSave.UsesThisCombat` 的本场配额，不新造第三个词。
- **`EnemyAiProfileData` 挂 `ContentEnabled`、不挂 `Rarity`、`Id` 形态 `enemy_ai.<snake_case_slug>`**（采纳的默认）——逐条出自全库共有字段与 `Id` 约定。
- **五条加载期校验的严重度分档**（`null` 合法不报 · 悬空 `PushError` + 抛 · 空壳 `PushWarning` · 同 `Term` 重复 `PushError` · 越界 `PushError` + 抛 · 未被引用 `PushWarning`）（采纳的默认）——逐条与 `PoolScope` / `TechniqueRef` / `EncounterScopes` 的既有不对称判据同构。

## Open questions

- **兜底权重向量的数字初值。** 结构可定、数字待校准：它被「卡牌产 / 削道念的量纲基准」阻塞，随首批 starter deck 一并校准。该前置依赖已在待答清单内，本条不另开条目。
