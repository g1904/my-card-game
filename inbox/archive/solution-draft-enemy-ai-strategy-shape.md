---
type: solution-draft
date: 2026-08-26
question: 敌人 AI 的定制策略在 `EnemyData` 上落成什么形态（独立 `Resource` / 内联字段），连带具体算法、决策粒度、多回合倾向与「兜底 vs 定制」的强弱差口径
source: open-questions/01-combat.md → 「内容与数值的残留」→ 敌人 AI 的决策形态（08-25 收窄）
targets:
  - systems/enemies/_index.md（`EnemyData` 字段总表那一格 + 「敌人 AI」小节 + 待决问题）
  - systems/enemies/common-properties.md（共有字段表「定制 AI 策略」行 + 加载期校验）
  - systems/services/combat-service.md（EnemyManager 职责 + AI 决策的纯函数签名与输入面）
  - systems/adventure-event/combat/_index.md（待决问题「敌人 AI 的规划形态」）
  - systems/balance.md（`CombatRulesData` 的兜底权重向量与取值域，数字待校准）
  - content/_index.md（是否开张 `enemy-ai` 类型档案——建议暂不开）
status: distilled
reviewed: 2026-08-26 —— 评审裁定：随机化取向取 A（全确定性）；强弱差取 A（只写结构性上界，不写胜率数字）；`ADR-0092` 张力按「不推翻、只加固」处理，§7 三条全采纳、越界保留 `PushError`；`AiCombatView.Battlefield` 复用 `BattlefieldEntryView`。批量合并 interview 另裁定两项，**推翻草稿正文**：① 不新增 `AiCombatView`，改为给 `CombatSnapshot` 加 `ViewerSide`，AI 与 UI 共用同一投影（§具体形态「两个投影，不复用」整段作废）；② profile 逐条权重取值归内容层 `content/enemy-ai/<id>.md`，`systems/balance.md` 只写兜底向量与取值域（§9「权威落在 balance.md 的权重表」那句作废；类型档案开张归 `/scaffold-content-type`）。另：候选集里启动式异能一项按 `ability` 稿的契约写作 `ManaCost` 可付且 `counters[abilityId] < MaxActivationsPerCombat`（草稿的 `ActivationCost` 字段名已弃且漏配额闸）。
distilled-to: handoffs/2026-08-26c-enemy-ai-strategy-shape.md
---

# 方案草稿 — 敌人 AI 定制策略的表达形态

## 问题

`ADR-0092` 已把敌人 AI 的**归属与约束**定死：两层结构（通用兜底实现在 EnemyManager 内 + 挂 `EnemyData` 的模板级定制策略、可空即回落兜底）、策略只表达打法风格不作强度旋钮、AI 决策是「局面 + `combat` 子流」的纯函数且输入面限对称可见信息。

**但那一格写不出字段类型。** `enemies/common-properties.md` 的共有字段表里，「定制 AI 策略」一行的「形态」列写的是「表达形态待定」，校验列只有一句「允许为空 = 走通用兜底」。字段类型写不出 ⇒ `systems/enemies/_index.md` 无法 derive。连带四项同样悬着：**具体算法**、**决策粒度**（一次性 vs 逐张）、**多回合行为倾向**、**兜底与定制的强弱差口径**。

本草稿的核心张力是一条正面冲突：**AI 策略是算法，而本库的数据驱动纪律要求「新增一个敌人 = 新增一个 `.tres`，而不是编辑 switch」**。下方「## 数据驱动纪律：正面处理」一节专门处理它，不回避。

## 约束（来自既有设计）

**硬边界（不得违反）**

- **`ADR-0092`**：策略挂 `EnemyData`、字段可空、空即兜底；`EnemyInstance` 六字段不变；策略经 `EnemyId` → `ContentRegistry.Get<EnemyData>()` 读取。
- **`ADR-0092` · 纯函数**：不得依赖真实时间、帧序或未持久化的隐藏记忆；输入面限**对称可见信息**——战场全部条目（含 `OwnerSide`）· 双方道念与回合数 · 对手埋伏**计数** · 对手手牌**张数** · 自己的手牌 / 卡组 / 本场可用道具；**不读玩家手牌内容与抽牌堆顺序**（`systems/services/combat-service.md`）。
- **策略运行态归 EnemyManager、不进 `ActiveCombat`**；多回合倾向若落地，其状态**要么可由 `ActiveCombat` 现有字段重算，要么必须新增存档字段**（`combat-service.md` 推论 ③）。
- **D5 一个决策点覆盖整个敌人回合**，敌人回合是一段**可确定性重放的区间**；敌人侧的目标选择由 EnemyManager 自行决定、**不产生决策点**（`combat-service.md` 决策点清单）。
- **定制策略不作强度 / 难度旋钮**；难度只由 `baseMomentum` 与内容编排承担（`ADR-0090` 否掉层数浮动的同一条论证）。
- **`ADR-0074`**：凡可调数值一律住平衡资源 `.tres`，本库不存在「服务配置」这一层；`[Export]` 服务配置的三条致命问题 = 绕开 overlay 热更 · 绕开启动期强校验 · 制造第二种「可调数值住哪」的答案。
- **`ADR-0030` / `.claude/rules/data-resource-rules.md`**：内容一律 `[GlobalClass] partial class XxxData : Resource` + 稳定 `Id` + ContentRegistry 索引 + 启动期大声失败；平衡资源经 `Content.Single<T>()` 取。
- **`combat-service.md` 已明写**：兜底「是算法而非可调数值，故不另立内容条目、不建『默认策略』资源（**日后若需数值旋钮，走 `CombatRulesData` 一类平衡资源**）」。
- **通用表达式已被否决过一次**（`deck/common-properties.md` 的 `KeywordData` 参数化）：「通用表达式会把『效果是数据不是代码分支』拖回一个需要求值器与沙箱的小语言，而 overlay 热更一段脚本的风险面远大于改一个数值」。本题必须尊重同一条判据。
- **`ADR-0013`** 的四级阶梯与两条选级判据：**能上线且线上不可见 → 必须做到第 1 / 2 级**。

**形态先例（本库既有做法，方案照抄不发明）**

- **`AbilityData`** —— 跨载体可复用的资源：`[GlobalClass] : Resource`、有稳定 `Id`、进 ContentRegistry、由 `CardData` / `PowerData` / `ItemData` / 战场条目**以直接类型引用**持有。这是「可复用内容资源」在本库的标准形状。
- **`TechniqueRef`** —— 内嵌 `Resource` + 两个具名字段 + 「同一 id 重复列出 → `PushError`」。
- **`PoolScope`** —— 可空 = 通用、不报错；**非 null 但两字段皆空 → `PushWarning`**（空壳与有意留白不可区分）。
- **`EffectData` 原子操作清单** —— 「初值，开放可加」，**原语在代码、组合在数据**；「新增一张卡 = 新增一个 `.tres` 并组合已有元素，而不是编辑 switch」。

## 建议方案

### 1. 那一格 = 对一条**独立可复用资源**的直接类型引用

`[既有推演]`

```csharp
// EnemyData 上新增（可空）
[Export] public EnemyAiProfileData AiProfile { get; set; }   // null = 走通用兜底
```

**建议取「独立可复用资源」而非内联字段**，判据正是待答项要求交代的那一条——**是否需跨条目复用**：需要，且是常态。

- 定制策略表达的是**打法风格原型**（守势 / 抢攻 / 消耗 / 埋伏流），一种风格天然被一批敌人共享。内联意味着「把守势打法调一档」要逐个敌人条目改一遍，**漏一个即得到一条半改的风格**——这与 `KeywordData` 拒绝「纯文案简写」的理由 ② 逐字同构。
- 反面判据同样成立：`PoolScope` / `TechniqueRef` 取内联，是因为它们**逐条目独有、从不共享**（这个敌人出现在哪个地域、带哪门功法第几层）。AI 风格不属这一类。
- **引用形态照抄 `AbilityData`**（直接类型引用，不写 `AiProfileId : string`）：`AbilityData` 就是本库「有稳定 `Id`、进注册表、被多个载体引用」的既有形状，`CardData.Abilities` 是 `AbilityData[]` 而非 id 数组。取 id 字符串会与它形成两套引用惯例，而本题没有任何理由开第二套。

```csharp
[GlobalClass]
public partial class EnemyAiProfileData : Resource   // .tres 落 res://content/enemy_ai/<slug>.tres
{
    [Export] public string  Id            { get; set; } = string.Empty;  // enemy_ai.<snake_case_slug>
    [Export] public bool    ContentEnabled{ get; set; } = true;          // 全库共有字段；读取侧不过滤
    [Export] public AiWeight[] Weights    { get; set; } = [];            // 只列要覆写的项
}

[GlobalClass]
public partial class AiWeight : Resource             // 内嵌 Resource + 两个具名字段，同 TechniqueRef
{
    [Export] public AiTerm Term  { get; set; }
    [Export] public float  Value { get; set; } = 1.0f;
}
```

- **不挂 `Rarity`** —— 它不进任何抽取池，与 `KeywordData` 同判据（`systems/common-properties.md`「凡会被抽取或置换的内容定义才带 `Rarity`」）。
- **profile 只列它要覆写的项**，未列项取兜底默认值。收益有二：兜底调参**自动惠及全部 profile**（不必逐条同步）；profile 文件短到一眼能读出「这个敌人偏在哪」。
- **无第二类字段。** profile 里**只有权重向量**，没有「优先打关键卡」「保留 N 点 mana」这类结构位——那些一律表达为某个 term 的权重（见下表的 `KeyCardAffinity` / `ManaEfficiency`）。多开一格结构就是多开一条与权重并行的表达通道，此后每条策略都要回答「这件事该写在哪一格」。

### 2. 决策粒度 = 逐张，且每次重算候选集

`[既有推演]`

`combat-service.md` 已定「EnemyManager 不受回合级一次性规划约束，AI 可在自己回合内逐张决策」。本方案落实为：**一次决一个动作，执行到栈清空后重新组装候选集再决下一个**。

理由不是偏好而是必然：**栈结算会改变局面**（连锁触发、道念被下限 0 截断、条目落场 / 离场），一次性规划出的第 2、3 个动作在执行到时的合法性与价值都可能已经变了。且「逐张」与既定的「敌人回合内部不落决策点、D5 一个点覆盖整段」完全自洽——逐张说的是 AI 内部推进顺序，不是对玩家的响应。

### 3. 兜底算法 = 单层（1-ply）加权效用评分 + 确定性 argmax

`[通行做法]`（utility AI / 加权启发式评分，是卡牌 AI 的行业默认解；Slay the Spire 一类的敌人行为则更简单，属脚本序列，与本作「敌人也构筑、也出牌」的对称参战方模型不匹配）

```
EnemyTurn():
    while (step == Action && stack.IsEmpty):
        candidates ← { PlayCard(c)        | c ∈ hand, c.ManaCost <= currentMana, 每个槽位 LegalTargets 非空 }
                   ∪ { UseItem(i)         | i ∈ 本场可用道具, 本场配额未尽 且 Charges 未尽 }
                   ∪ { ActivateAbility(e) | e ∈ 战场己方条目的启动式异能, ActivationCost 可付 }
                   ∪ { EndTurn }
        对每个候选先解析目标（见 §4），再算 score(a) = Σ_k  w_k · term_k(a, view)
        score(EndTurn) ≡ 0                       // 天然基线：无正分动作即结束回合
        取 argmax；平手按 §5 的确定性字典序打破
        若选中 EndTurn → break；否则执行该动作、等栈结算干净、回到循环
```

- **`score(EndTurn) ≡ 0` 是承重的**：它把「还该不该继续行动」变成 argmax 的自然产物，不需要第二套「何时收手」的规则；同时它意味着**权重向量恒有一个绝对零点**，`w` 的取值域因此可被钳制（见 §7）。
- **单层试算（1-ply），不模拟连锁触发。** 每个候选的收益按该动作自身 `EffectData` 在**求值管线**（加法层 → 乘法层 → 下限 0 截断）上跑一遍得出，**不展开它可能引发的触发链**。这是刻意的：模拟连锁等于把 StackManager 的结算在评分里重跑一遍（性能与正确性双重风险），且它正是「强度上界」的主要来源之一（见 §7）。**须明写为规则，不是实现细节**——否则日后有人「顺手加一层」，强度上界当场失效。
- **term 清单（初值，开放可加——形态照抄 `EffectData` 原子操作清单）**：

  | `AiTerm` | 语义（全部只读对称可见信息） |
  |---|---|
  | `MomentumGain` | 试算得到的自己道念净产出 |
  | `MomentumDenial` | 对对手道念的**有效**削减 = `min(声明削减量, 对手当前道念)`。直接复用「下限 0 逐次截断、溢出不结转」这条既定规则，故 AI 天然不会把大削减砸在残血对手上 |
  | `ManaEfficiency` | `(MomentumGain + MomentumDenial) / max(1, manaCost)`；打满 mana 的倾向由它承担 |
  | `BoardPresence` | 本动作落场的永久物条目数（阵法 / 启动式载体） |
  | `Removal` | 本动作移除的**对手**战场条目数（`RemoveEntry` 元素计数） |
  | `AmbushCaution` | 对手埋伏计数 > 0 时对高费一次性投入的折价（**只读计数，不读内容**——埋伏的威慑力与实际效果是两件事，本 term 正是那条既定表述的落地） |
  | `HandRetention` | 打出后手牌张数过低时的负分（消耗流留手） |
  | `KeyCardAffinity` | 本动作的 `CardId` ∈ 该敌人的 `KeyCardIds` 时加分 |
  | `ClosingUrgency` | 己方剩余回合数 ≤ 2 时，对即时收益加权、对铺垫类收益减权 |
  | `ItemEagerness` | 己方剩余回合数 ≤ 2 时对 `UseItem` 加分（道具不带走，末回合不用即浪费） |

- **`KeyCardAffinity` 有一条免费的正向副作用**：`KeyCardIds` 是图鉴「关键卡牌」词条的数据源，而图鉴是**事前知识的主通道**。让 AI 真的偏向打出关键卡，使图鉴所述与玩家实际观察到的行为对齐——这是本 term 存在的第二个理由，不只是打法风格。
- **数字初值待校准。** 权重的具体数字被「卡牌产 / 削道念的量纲基准」这条待答项阻塞（见 `## 前置依赖`），与全库既有做法一致：**结构可定、数字随内容扩充后的统计校准**。

### 4. 目标选择 = 同一评分函数，零随机

`[既有推演]`

敌人侧的目标选择由 EnemyManager 自行决定、不产生决策点（既定）。落实为：对每个槽位，在**既定的 `LegalTargets` 求解结果**（`combat-service.md` 的四条过滤）中取**使该动作试算分数最高**的那一个；仍平手 → 取 `LegalTargets` 序列中的**第一个**（该序列由战场条目顺序确定性产出）。

- 复用同一个评分函数，不为目标另写一套启发式——两套会各自漂移，而本库没有机制发现它们不一致（与「目标 target 与作用域 scope 共用同一个 `EntryFilter`」同款判据）。
- `LegalTargets.Count == 0` 的槽位使该候选**整个不进候选集**（不是先选中再 fizzle）——AI 没有理由主动打出一张必然落空的牌。

### 5. 全流程零随机（承重，且这是与 `combat` 子流裁决解耦的关键）

`[既有推演]` + `[通行做法]`

**建议兜底与定制策略均不消耗任何随机。** 平手打破取确定性字典序：`(−score, 动作种类序 PlayCard < UseItem < ActivateAbility < EndTurn, SubjectId 的组装序)` 取最小。

- 组装阶段的实例发号本就是确定性的（`c#0` / `e#0`…，闭集按固定顺序发号），故「组装序」是一个现成的、可复现的全序，**不需要新增任何状态**。
- 零随机使 `ADR-0092`「随机只取 `combat` 子流、不再派生新流」在本方案下成为一条**空约束**——保留它，作为日后引入随机化权重项时的约束。
- **它同时使本方案对「`combat` 子流的三句互相矛盾」那条待答项完全中立**，见 `## 前置依赖`。
- 承重理由不止工程：本作的可读性支柱把**敌人图鉴定为事前知识的主通道**（敌人不作任何事前预告）。图鉴的价值建立在「这个敌人会怎么打是**可学习**的」之上；给 AI 掷骰等于直接稀释这份价值。「重复对局显得机械」是它的代价，见 `## 仍需用户决定` 第 1 条。

### 6. 多回合行为倾向 = 局面函数，零记忆，`ActiveCombat` 一格不加

`[既有推演]`

硬约束是「跨回合记忆必须可由 `ActiveCombat` 现有字段重算，否则必须新增存档字段」。本方案取**零记忆**这一端：

**一切「倾向」都写成当前局面的函数**——`turnIndex` / `turnLimit`（剩余回合数）· 双方道念差 · 自己抽牌堆余量（疲劳临近）· 自己战场上的条目 · 手牌张数。这些**全部已在 `ActiveCombat` 内**（`turnIndex` / `turnLimit` / `sides[].momentum` / `sides[].drawPile` / `battlefield` / `sides[].hand`）。

- 「前期铺场、后期梭哈」这类跨回合叙事因此由 `ClosingUrgency` / `BoardPresence` 两个 term 表达，**不需要一个「我打算铺场」的记忆位**。
- 收益是结构性的：`ActiveCombat` schema **一格不加**、**零迁移**，且 D5「敌人回合是一段可确定性重放的区间」原样成立——退出重进重放整段，不可能分叉，因为压根没有不在存档里的东西。
- 明写为规则：**AI 不得持有任何跨动作、跨回合的私有字段。** 这条做到 `ADR-0013` 的**第 1 级**（写不出来）——把 `ChooseAction` 写成 `static` 纯函数（见 `## 具体形态`），私有记忆在语言层无处存放。

### 7. 强弱差口径 = 三条结构性上界（不再是不可校验的软口径）

`[既有推演]`

`ADR-0092` 把「策略不得强于兜底多少」定为**不可机械校验的编排口径、不设校验**。本方案**不推翻它**，但把它的绝大部分变成结构性事实——定制层拿到的表达力被三条硬上界封住：

| # | 上界 | 它封住了什么 | `ADR-0013` 级别 |
|---|---|---|---|
| ① | **定制层只提供 `w` 向量，不提供代码** | 定制策略与兜底跑**同一条 argmax 循环、同一套 term、同一个候选集**。它无法多看一层、无法多算一步、无法读到兜底读不到的输入 | **第 1 级**（写不出来） |
| ② | **搜索深度恒为 1-ply，且试算不展开连锁** | 强度天花板由算法深度决定，而深度是代码常量、不在数据面上 | **第 1 级** |
| ③ | **`Value` 钳在 `[WeightMin, WeightMax]`（建议 `[0, 2]`，默认 `1.0`），加载期越界即 `PushError`** | 极端权重只能让 AI **偏科**（更像某种风格），不能让它更强——因为分数是同一批 term 的线性组合，缩放不改变可达动作集 | **第 3 级**（启动期大声失败） |

- **推论：定制策略在结构上「不强于兜底」已近乎自动成立**——它是兜底在同一搜索空间内的一次重新加权。剩余的自由度（某种偏科恰好特别克某类玩家套路）确实不可机械校验，那一小块**仍留在编排口径**，与 `ADR-0092` 一致。
- 取值域住 `CombatRulesData`（见下），故它可随 overlay 热更收紧，不必发版。

### 8. 兜底权重的默认向量与取值域 → `CombatRulesData`（平衡资源）

`[既有推演]`

`ADR-0074`：凡可调数值一律住平衡资源。`combat-service.md` 已点名「日后若需数值旋钮，走 `CombatRulesData` 一类平衡资源」。故：

| 数值 | 落点 | 理由 |
|---|---|---|
| **兜底权重的默认向量**（每个 `AiTerm` 一个 `float`） | `CombatRulesData` | 它不属任何内容条目；`[Export]` 服务字段被 `ADR-0074` 三条理由封死 |
| **`WeightMin` / `WeightMax`** | `CombatRulesData` | 同上；且与默认向量有跨字段不变式（默认值必须落在区间内）⇒ 按 `ADR-0074`「有跨字段不变式的同住一份」**必须同住** |
| **定制 profile 的权重覆写** | `EnemyAiProfileData`（内容层 `.tres`） | 它是内容条目的属性，与卡牌费用、敌人层数同档 |

**这不违反 `ADR-0074`。** 该 ADR 的靶子是「服务配置」这第三层；内容 `.tres` 与平衡 `.tres` 两层都在它认可的范围内，而 `EnemyAiProfileData` 经 ContentRegistry 加载、受 overlay 覆盖、受启动期强校验——ADR-0074 列的三条理由**逐条满足**。

加载期须校验：**`CombatRulesData` 的每个默认权重落在 `[WeightMin, WeightMax]` 内**，否则 `PushError` + 抛（跨字段不变式的自校验）。

### 9. 内容层落点：暂不开张 `content/enemy-ai/` 类型档案

`[通行做法]`

建议 profile 先只作为 `.tres` + `systems/balance.md` 里的一张权重表存在，**不建 `content/enemy-ai/` 类型档案**。判据照抄「平衡数值不单开类型」那一条：它零玩家可见文案、零抽取、零 `Rarity`、唯一的交叉引用是被 `EnemyData` 引用，而「填了什么值」的权威天然落在 `systems/balance.md` 的权重表上——开一份类型档案就是制造第二权威。

条目数超过约 6 条、或 profile 开始带风味描述（「这门派的打法是……」）时，再按 `/scaffold-content-type` 正常开张。**这条是可回退的，成本对称。**

## 数据驱动纪律：正面处理（本题的核心张力）

`.claude/rules/data-resource-rules.md`：**「新增一张卡牌 = 新增一个 `.tres`，而不是编辑某个 switch 语句。」** 逐条对照本方案：

| 内容动作 | 要不要写 C# | 纪律 |
|---|---|---|
| **新增一个敌人**（可引用已有 profile） | **不要** | ✅ 成立 |
| **新增一种打法风格**（重排权重） | **不要**——新增一个 `EnemyAiProfileData.tres` | ✅ 成立 |
| **调整某种风格 / 调整兜底** | **不要**——改 `.tres`，走 overlay 热更 | ✅ 成立 |
| **新增一个从未有过的考量维度**（新 `AiTerm`） | **要**——加一个枚举值 + 一个 term 函数 | ⚠️ 见下 |

**最后一行不违反纪律，理由不是妥协而是本库既定形态：**

- 它与 **`EffectData` 原子操作清单**逐字同构——那份清单同样是「初值，开放可加」的 C# 侧原语表，而「关键是它是数据不是代码分支：新增一张卡 = 新增一个 `.tres` 并组合已有元素」正是本库对这条纪律的官方读法。**原语在代码、组合在数据**。
- 纪律真正禁止的是「**分支数随内容条目数增长**」的 switch。本方案里 term 的 `switch` 分支数 ≈ 10，**与敌人条目数、profile 条目数都无关，且不随内容扩充增长**。这正是它与被否决方案的分水岭。

**两条被正面否决的替代（它们才是真正的违反）：**

- **每类定制策略写一个 C# 策略类，`EnemyData` 上填类名字符串 / 枚举** — 否决。分支数**随内容增长**（正是纪律禁止的那个 switch）；策略无法经 overlay 热更（改一个敌人的打法要发版）；绕开启动期内容强校验。后两条逐字命中 `ADR-0074` 三条理由中的两条。
- **行为树 / 条件-动作规则 DSL 落 `.tres`** — 否决。它与 `KeywordData` 参数化否决「通用表达式」逐字同构：把「策略是数据不是代码分支」拖回一个需要**求值器与沙箱**的小语言，而 overlay 热更一段脚本的风险面远大于改一个数值。且它会让「定制不强于兜底」的结构性上界（§7 ①②）当场失效——一棵树可以表达兜底表达不了的东西。

## 具体形态（可 derive 的落地面）

### `EnemyData` 那一格

| 字段 | 类型 | 可空 | 默认 | 语义 |
|---|---|---|---|---|
| `AiProfile` | `EnemyAiProfileData`（`[Export]` 直接类型引用） | **是** | `null` | `null` = 走通用兜底；非 `null` = 以其权重覆写兜底默认向量 |

### 加载期校验（填实 `enemies/common-properties.md` 的那一行）

| 违规 | 语义 | 处置 |
|---|---|---|
| `AiProfile == null` | **合法** —— 显式不在必填清单内，绝大多数条目走此路 | **不报错、不告警** |
| `AiProfile` 非 `null` 但其 `Id` 为空、或不在 `EnemyAiProfileData` 仓储内 | 悬空引用 | `PushError`（带敌人 `Id` + profile `Id`）+ 抛 |
| `AiProfile` 非 `null` 但 `Weights` 为空数组 | 空壳：语义等同兜底，但「填了个空壳」与「有意留兜底」不可区分 | `PushWarning`（不阻断）——**逐字照抄 `PoolScope` 空壳那条** |
| 同一 `AiTerm` 在 `Weights` 中重复出现 | 必是编排错误（后一条静默覆盖前一条） | `PushError`（带 profile `Id` + 重复 `Term`）——照抄 `TechniqueRef` 重复那条 |
| `AiWeight.Value` 落在 `[WeightMin, WeightMax]` 之外 | 越界权重是 §7 ③ 那道闸 | `PushError`（带 profile `Id` + `Term` + 越界值）+ 抛 |
| `CombatRulesData` 的某个默认权重落在 `[WeightMin, WeightMax]` 之外 | 跨字段不变式破损 | `PushError` + 抛 |
| 某条 `EnemyAiProfileData` 未被任何 `EnemyData` 引用 | 写了永不生效的内容 | `PushWarning` + 列举——与「关键字未被任何 `KeywordRef` 引用」同构 |

> **「允许为空 = 走通用兜底」在校验中的表达 = 该格显式不进必填清单，且校验表第一行把 `null` 明写为合法。** 与 `PoolScope`（`null` = 通用池、不报错）同款；反面是 `EncounterScopes`（空数组 → `PushError`），两者的不对称判据仍是既定那条——**漏填的后果不同**：`AiProfile` 漏填只是回落到一条可用路径（`ADR-0092` 原话「不产生静默污染」），不是死内容。

### 纯函数签名与输入面

```csharp
// EnemyManager 内部。static ⇒ 私有记忆在语言层无处存放（ADR-0013 第 1 级）
// 返回 EndTurn ⇒ 本回合结束
internal static EnemyAction ChooseAction(
    in AiCombatView       view,       // 唯一输入面；对称可见信息，见下
    EnemyAiProfileData?   profile,    // null = 纯兜底权重
    in AiWeightVector     fallback);  // 来自 Content.Single<CombatRulesData>()，已展开为定长向量

public enum AiTerm            // 初值，开放可加（同 EffectData 原子操作清单）
{ MomentumGain, MomentumDenial, ManaEfficiency, BoardPresence, Removal,
  AmbushCaution, HandRetention, KeyCardAffinity, ClosingUrgency, ItemEagerness }

public enum EnemyActionKind { PlayCard, UseItem, ActivateAbility, EndTurn }

public readonly record struct EnemyAction(
    EnemyActionKind          Kind,
    string                   SubjectId,   // CardInstanceId / ItemId / BattlefieldEntryId；EndTurn 时 string.Empty
    string                   AbilityId,   // 仅 ActivateAbility；否则 string.Empty
    IReadOnlyList<TargetRef> Targets);    // 按 slotIndex 顺序，已由 AI 自行解析完毕（不产生决策点）

// AI 的唯一输入面：瞬时组装、不缓存、不落存档
public sealed record AiCombatView(
    int  TurnIndex, int TurnLimit, Side Self,
    int  SelfMomentum,   int SelfCurrentMana, int SelfManaLimit,
    int  OpponentMomentum,
    IReadOnlyList<BattlefieldEntryView> Battlefield,   // 全部条目，含 OwnerSide；faceDown 者只有存在性
    int  OpponentAmbushCount,                          // 只给计数
    int  OpponentHandCount,                            // 只给张数
    IReadOnlyList<CardInstanceView>     SelfHand,      // 己方手牌，内容可见
    int  SelfDrawPileCount, int SelfDiscardPileCount,  // 只给张数——**顺序在类型层不存在**
    IReadOnlyList<CombatItemView>       SelfUsableItems);
```

- **这是把 `ADR-0092` 的输入面口径升为第 1 级的地方。** 「不读玩家手牌内容与抽牌堆顺序」不再靠纪律：`AiCombatView` 里**根本没有**承载它们的字段，写不出来。这条值得在文档里明写为承重点。
- **`AiCombatView` 与既有的 `CombatSnapshot` 是两个投影，不复用**：`CombatSnapshot` 恒以**玩家**为视角（`HandCardInstanceIds`「仅己方非空」= 敌方恒空）、且是「按变更广播 + 缓存」的呈现产物；AI 要的是以**敌方**为视角的**瞬时**局面。把 `CombatSnapshot` 参数化成双视角，会让呈现层从此背上一个「viewerSide 是什么」的问题（而 UI 永远只有一个视角），并顺带把玩家手牌内容重新暴露到一个 AI 够得着的类型里。
  - **已知代价（明写接受）：两份视图结构可能漂移。** 接受的理由是**漂移方向是安全的**——`AiCombatView` 少一格 = AI 少知道一件事，不会造成规则错误；反向（AI 多知道一件事）需要显式加字段，而加字段会撞上「输入面限对称可见信息」这条评审。两份视图**由同一次 manager 读取组装**（单一组装点、两个投影），把漂移面压到最小。

### 兜底权重向量（结构定、数字待校准）

`CombatRulesData` 新增：`AiFallbackWeights : AiWeight[]`（须覆盖 `AiTerm` 全部取值，缺项 → `PushError`）· `AiWeightMin : float = 0.0` · `AiWeightMax : float = 2.0`。全部数字**待「卡牌产 / 削道念的量纲基准」定出后随首批 starter deck 一并校准**，表落 `systems/balance.md`。

## 后果

- **`systems/enemies/_index.md`** 字段总表「定制 AI 策略」一格与「敌人 AI」小节可写实；**待决问题第 1 条（表达形态）可整条移出**，第 2 条（规划形态）收窄为「权重数字待校准」。
- **`systems/enemies/common-properties.md`** 共有字段表末行与加载期校验表按上表填实。
- **`systems/services/combat-service.md`** 的 EnemyManager 行补纯函数签名与 `AiCombatView`；「AI 决策是纯函数」那条补一句「本方案下零随机消耗」。
- **`systems/adventure-event/combat/_index.md`** 待决问题「敌人 AI 的规划形态」可整条收口。
- **`systems/balance.md`** 新增一张兜底权重表（数字待校准）+ `AiWeightMin/Max` 两格。
- **存档面零改动**：`ActiveCombat` 一格不加、`EnemyInstance` 六字段不变、`CardInstanceSave` 不变 ⇒ **零迁移**。
- **`content/_index.md`** 的类型登记表：建议**不新增** `enemy-ai` 行，只在「不单开类型的两项」旁补一句说明（见 §9）。
- **ADR 候选（本技能不写 ADR，只登记）**：「敌人 AI 策略 = 权重向量的重新加权，定制层不提供代码；AI 决策全流程零随机」——它给 `ADR-0092` 的软约束补上了结构性上界，值得单独立档。

## 备选方案（已考虑并否决）

- **内联字段（把权重直接摊在 `EnemyData` 上）** — 否决：跨条目复用是常态，内联使「调一档风格」变成改 N 个条目、漏一个即半改；且 `EnemyData` 已是本作最重的内容单元，再摊 10 格权重会淹没它。
- **`AiProfileId : string` + 加载期悬空校验** — 否决：`AbilityData` 已经确立了「可复用内容资源以直接类型引用持有」的形状，取 id 字符串会造出第二套引用惯例，收益为零。
- **每类策略一个 C# 类 + 条目上填类名** — 否决：见「数据驱动纪律」一节（分支数随内容增长 · 无法热更 · 绕开启动期强校验）。
- **行为树 / 规则 DSL 落 `.tres`** — 否决：与 `KeywordData` 否决通用表达式同一条判据；且会击穿 §7 的结构性上界。
- **多层搜索（2-ply 及以上 / 蒙特卡洛）** — 否决：与「反应速度不是难度旋钮」正面冲突（更深的搜索就是更强的 AI），且在移动端每个敌人回合做树搜索的开销与本作低交互定位不匹配。
- **定制策略允许覆写候选集或 term 实现** — 否决：那等于把代码放回数据面，§7 ①② 两条上界同时失效。
- **给 AI 一个跨回合记忆位（如「本场已铺场 N 次」）** — 否决：既定硬约束要求它可重算或落存档；而所有真实需求都能写成局面函数，为它加一格存档字段是给一个已被满足的需求造结构。
- **分数前 k 名内掷骰以增加变化** — 未否决，升为取向题，见 `## 仍需用户决定` 第 1 条。
- **profile 必填、无默认** — 否决（`ADR-0092` 已裁定）：漏填只回落到一条可用路径，不产生静默污染。

## 与既有决策的张力

**一处轻微张力，建议按「不推翻、只加固」处理：**

`ADR-0092` 明写「『策略不得强于兜底多少』是**不可机械校验的编排口径**（软约束），不设校验」。本方案的 §7 把其中**大部分**变成了结构性上界（第 1 级）与取值域校验（第 3 级）。

- **这不是推翻**：ADR 的裁定是「不为强弱差设一条**度量胜率的**校验」，本方案同样没有设——它是通过**限制定制层的表达力**，让「更强」在结构上难以发生。剩余那一小块（某种偏科恰好克制某类套路）仍然不可机械校验，仍留在编排口径。
- **若用户认为这构成收紧**：可只采纳 §7 ①②（它们是算法形态的自然结果，不需要任何新规则），把 ③ 的取值域钳制降为 `PushWarning`。代价是一条写成 `Value = 999` 的 profile 能上线且线上不可见——按 `ADR-0013` 的选级判据，那正是**必须做到第 1 / 2 级**的那一档，故**建议保留 `PushError`**。

**→ 已裁决（2026-08-26 · 批量评审）：按「不推翻、只加固」处理，§7 三条全部采纳，取值域越界保留 `PushError`。** 依据即 `ADR-0013` 的选级判据，按分类纪律**按标准默认直接采纳**，未单独出题。

**另有一处需要文档同改（不是张力，是收口）：** `enemies/_index.md` 现写「AI 决策……随机只取 `combat` 子流、不再派生新流」。本方案下 AI 零随机，该句应改写为「本方案不消耗随机；日后若引入随机化权重项，随机只取 `combat` 子流」——保留约束、明确其当前为空。

## 前置依赖

**① `combat` 子流的三句互相矛盾（`open-questions/01-combat.md`，另有 worker 正在裁决）——本方案对它中立。**

本方案的 §5 使 **AI 决策零随机消耗**，故两种裁决下方案的形态差异为零：

| 裁决 | 本方案会长成什么样 |
|---|---|
| **统一为单一 `combat` 子流** | **一字不改。** AI 不掷骰；抽牌不由 AI 发起，属 `DeckModule` 的既定路径 |
| **保留敌人抽牌的独立子流** | **一字不改。** 同上——AI 与子流数量无接触面 |

唯一接触点是 `ADR-0092` 那句「随机只取 `combat` 子流」：本方案下它是空约束，**无论哪种裁决都不需要为本方案确定句柄名**。仅当用户在 `## 仍需用户决定` 第 1 条选择「引入随机化」时，才需要按该裁决确定 AI 掷骰用哪个流句柄——届时的差异仍是**一行**（一个流句柄）。

> 本方案**不替该问题拍板**，也不假定任何一种裁决。

**② 卡牌产 / 削道念的量纲基准（承重 · 已归属统计校准）** —— 兜底权重向量的**数字初值**在它定出前无法校准。**结构不受阻塞**：字段形态、term 清单、校验规则、纯函数签名全部可先落笔并 derive，数字随首批 starter deck 一并校准（与全库既有做法一致）。

**③ `CardData` 的费用字段** —— `ManaEfficiency` 的分母是 `manaCost`，而费用格目前仍是结构占位（`deck/common-properties.md`「仍为结构占位：费用与触发器两格的具体类型与枚举」）。**不阻塞本方案**：term 的定义只需要「有一个 mana 费用」这一事实，该事实已由「战斗模型 = mana（出牌）+ 道念」定死。

## 仍需用户决定

> **全部裁决完毕（2026-08-26 · 批量评审）。** 逐条裁决见各项下的 `→ 已裁决` 行。
>
> 另有一项跨分片注记，同批**按标准默认采纳**：`AiCombatView.Battlefield` **复用** `BattlefieldEntryView`
> （含同批草稿 `solution-draft-activate-ability-contract.md` 为它新增的 `ActivatableAbilities` 一格），不分叉出第二个类型。
> 依据：异能可用性属**对称可见信息**（战场条目公开 · mana 公开 · `counters` 为公开计数），不违反 `ADR-0092` 的输入面约束。

**1. AI 是否需要随机化？（真取向：可学习性 vs 新鲜感）**

| 选项 | 后果 |
|---|---|
| **A · 全确定性（推荐）** | 同一局面恒出同一动作。敌人行为**可学习** ⇒ 图鉴这条「事前知识主通道」的价值最大化；零随机消耗 ⇒ 与 `combat` 子流那条待答项完全解耦；确定性重放天然成立。代价：重复遭遇同一敌人时行为完全一致，可能显得机械 |
| **B · 分数前 k 名内按权重掷 `combat` 子流** | 重复对局更有变化。代价：① 玩家更难从遭遇中学到「这个敌人会怎么打」，直接稀释图鉴价值；② 引入随机消耗 ⇒ 与 `combat` 子流的裁决产生耦合；③ 多一个「k 取几、怎么加权」的旋钮要校准 |

**推荐 A。** 理由：本作已把「敌人不作任何事前预告」定为承重决策，其代价由六条可读通道承接，而**图鉴是其中唯一的事前通道**。给 AI 掷骰是在唯一的事前通道上再打一个折扣，与那条论证方向相反。「显得机械」的解法更便宜——多写两条 profile，让同一批敌人打法各异（这正是定制层存在的意义）。

**→ 已裁决（2026-08-26 · 批量评审）：A —— 全确定性。** 连带确认：本方案与 `combat` 子流那条待答项**完全解耦**（同批裁决为「单一 `combat` 子流」，而本方案零随机消耗，故两种裁决下均一字不改）；`ADR-0092`「随机只取 `combat` 子流」在本方案下为**空约束**，`enemies/_index.md` 那句应按 §「与既有决策的张力」末段改写为「本方案不消耗随机；日后若引入随机化权重项，随机只取 `combat` 子流」。

**2. 「兜底与定制的强弱差」要不要在结构性上界之外，再加一条带数字的人工评审口径？**

| 选项 | 后果 |
|---|---|
| **A · 只写结构性上界（推荐）** | §7 的三条（同候选集 · 1-ply 深度 · 权重钳在 `[0,2]`）即全部口径；文档不写任何胜率数字 |
| **B · 另加「定制 profile 相对兜底的基准胜率偏差 ≤ ±5pp」，落 `/audit-content` 的人工评审级** | 多一条可被援引的编排标尺 |

**推荐 A。** 理由：该数字在「卡牌产 / 削道念的量纲基准」定出、starter deck 成型之前**无法测量**，此刻写下即是一条无人执行的第 4 级条款——而 `ADR-0013` 的整个用意就是不写这种条款。若日后确有需要，它是纯加法。

**→ 已裁决（2026-08-26 · 批量评审）：A —— 只写结构性上界，不加带数字的胜率口径。** 本项依据充分（不可测量的条款不写），按批量编排的分类纪律**按标准默认直接采纳**，未单独出题。
