# Phase A 报告 — 分片 B：solution-draft-event-option-materialized-fields.md

目标库：`game-design-documents/`（客户端）。判定依据：输入路径带 `game-design-documents/` 前缀；全部 targets 落在客户端 `systems/`。**不跨库**——本草稿全在客户端进程内（物化点、结算器、存档 schema），后端无承接项。

## 1. 意图要点（我的理解）

1. 给「`EventOption` 完整物化字段清单」一条**物化判据**（① seeded RNG 掷定 / ② 情境代入而定 / ③ 物化时组装变换；三条皆不中留模板侧），与既有的**快照判据**（「重算不出来的存」）成孪生两条，分工是「在不在定稿实例上」vs「要不要再抄进 `PastEventEntry`」。清单从此不再逐字段重开。
2. 按判据核过，只缺两格：**缺口 A = outcome / effect 的定稿载体**；**缺口 B = `EncounterSpec` 的承载**（本草稿不表态，已由同批 S5 答定）。
3. 缺口 A 的结论：`EventOption` 新增一格 `EventOutcomeSpec`，**抽取 / 权重全部在物化时掷定**，结算时只**选一侧**（胜/负、成/败）与做 `FailureRatio` 折算，**不掷任何骰子**。顶层按「结算走向」分侧，内部分解留给「效果关键字体系」那次专门 handoff。
4. `lifeSpanCost` = **定值**，不带区间、不带公式（时长旋钮精度 + Band 0/1 不显示成本 ⇒ 方差不可感知 + 已有 `ModifierKey.LifeSpanCost` 一条运行期变异通道）。
5. `combatTier` 在 `EventOption` / `PastEventEntry` **两处都不加字段**，走 `EventId` → 模板溯源（它是模板常量，非物化产物；两个消费方本就要查表取显示名；额外收益是 Explore 遮罩少一个守点）。
6. `Priority` **保留 `int`**，另加「加载期校验 + 物化后断言 `∈ {0,1}`」。
7. `PlotModulation` 复核结论：**不为新增物化格扩字段**，并把「落内容面 → 已有字段够用；落约束面 / 模板字段面 → 不加」这条判据写进 `plot-manager.md`。
8. Band 2 的 `selectCost` 精确展示走**只读 `ApplyModifier` 查询**，不写回定稿实例 ⇒ 不构成第二个施加点；`profile-service.md` 补一句明文。
9. 四项 `## 仍需用户决定` 用户已在评审中全取推荐项 A（其中第 3 项标 `[采纳推荐 — 待复核]`）。

## 2. 校验发现

### 🔴 冲突（必须 interview）

- **`FailureRatio` 的数据形态与既有主题文档直接打架（比率 vs 百分比整数）。**
  - 想法侧：`具体形态` 代码块写 `int FailureRatio, // 百分比；默认 50，逐条可覆写`。
  - 既有权威：`systems/adventure-event/common-properties.md`「隐藏属性推拉」小节原话——「经验有 `FailureRatio`（默认 **0.5**）是因为经验的语义是『学到多少』」。既有口径是**比率小数**，不是百分点整数。
  - 选项与后果：
    (a) **保留既有 `0.5` 比率口径，本次不动它** ⇒ 只在 `future-event-service.md` / `adventure-event/common-properties.md` 写「载体存在 + 固化时点 + 分侧判据」，`EventOutcomeSpec` 的内部字段一律写成 `⟨待定：内部分解归「效果关键字体系」那次 handoff⟩`，不落 `int FailureRatio` 这行。不触及后端库，不改任何 ADR。
    (b) **改成百分点整数 `int`（默认 50）** ⇒ 要同改 `adventure-event/common-properties.md` 那句原话、`balance.md` 里与 `ExperienceGrade` 倍率映射并列的口径，且与「内容侧不落裸数字、走枚举档 + 平衡表映射」的既有范式相抵（50 就是裸数字）。
  - **推荐：(a)**。理由：草稿自己明写「⚠ 内部分解不在本方案的可定稿范围」，那段 C# 是**示意**而非可定稿面；把它逐字抄进活文档等于在一份声明「不定内部形态」的方案里把内部形态定了，且顺手推翻一条与它无关的既有取值口径。

- **写入面冲突（编排风险，非设计冲突）：三份主题文档本分片与同批其他分片同写。**
  - `systems/services/plot-manager.md` —— 本分片写「`PlotModulation` 新增物化字段时是否扩字段」的判据；**同批 S5 要删 `EnemyPoolScope`（六字段 → 五字段）**。两个 worker 并行写同一小节必然互相覆盖。
  - `systems/services/future-event-service.md` —— 本分片改 `EventOption` record（+`Outcome`）、补物化判据、移除一条待决问题；**S5 要在同一 record 上加 `EncounterSpec Encounter`**；**S3（派生实例落存档）可能改「产出即定稿」与派生段**。
  - `systems/adventure-event/common-properties.md` —— 本分片改物化小节 + `PastEventEntry` 注释 + 移除两条待决问题；S3 / S5 同样触及该文件的物化与痕迹小节。
  - 选项与后果：(a) **三份文档合并给同一个 Phase B worker 串行落笔**（推荐）；(b) 拆波次：S5 先写 → 本分片后写（要求本分片的「`PlotModulation` 六字段」措辞按 S5 结果改为**五字段**）；(c) 并行 ⇒ 覆盖，不可取。
  - **推荐：(a) 或 (b)**。依据 `.claude/rules/batch-orchestration.md` 铁律 ③「绝不让两个并行 worker 写同一份文件」。

### 🟠 含糊（必须 interview）

- **`EventOutcomeSpec` 引入的两个类型名在库中完全不存在，属未定义引用。**
  `HiddenStatPush` / `ReplacementOffer` 全库 `grep` 零命中（既有的是 `HiddenStatGrade`、以及 `player-power/_index.md` 的置换候选描述，未命名类型）。
  - 选项：(a) **不写这两个名字**，顶层载体只写「按结算走向分侧的定稿产出 spec」+ `⟨内部分解待定⟩`（推荐）；(b) 照抄草稿，把两个新类型名写进活文档 ⇒ 制造两个无定义、无字段表、无校验的类型名，后续 `/derive-requirements` 会照它切 FR。
  - **推荐 (a)**：与第 7 步「不臆造用户未陈述的机制」和草稿自带的 ⚠ 一致。

- **`EventOption.Outcome` 与既有两处 `Outcome` / `EventOutcome` 三重撞名。**
  既有：`PastEventEntry.Outcome`（类型 `EventOutcome` 枚举，四值 `{Resolved, CombatWon, CombatLost, Aborted}`）；`Source.EventOutcome`（授予来源枚举成员，`systems/common-properties.md`）。草稿新增 `EventOption.Outcome`（类型 `EventOutcomeSpec`）。三者同名不同物，且都在同一条链路上被同时提及。
  - 选项：(a) 字段名改为 `OutcomeSpec`（类型仍 `EventOutcomeSpec`）；(b) 照草稿用 `Outcome`，靠类型区分；(c) 类型与字段一并改名（如 `MaterializedOutcome`）。
  - **推荐 (a)**：`terminology.md` 是术语事实来源、撞名要登记；`data-resource-rules.md` 与「贯穿链路的类型一致性」都要求层间名字不歧义。改一个字段名的成本为零。

- **两侧分法（`OnResolved` / `OnFailure`）与既有四值 `EventOutcome`、三值 `CombatOutcome` 的映射未明写。**
  既有 `EventOutcome { Resolved, CombatWon, CombatLost, Aborted }`；`CombatOutcome { Victory, Draw, Defeat }`，且 `combat/_index.md` 明写「**平**：只发 `baseReward`、不扣 lifeTotal」，`Practice` 档 `Draw` 永不可达。
  - 待明确：`Draw` 落哪一侧？`Aborted`（支付后短路、未进 resolver）是否**两侧都不施加**？
  - 选项：(a) 明写映射表 `CombatWon/Resolved → OnResolved`、`CombatLost → OnFailure`、`Draw → OnResolved`（对齐「平只发 baseReward」）、`Aborted → 两侧皆不施加`（推荐）；(b) 不写，留给结算侧实现 ⇒ 一个可机械判定的分支被留成实现分歧。
  - **推荐 (a)**：既有库对同类分叉一律明写（`Aborted` 那条痕迹语义就是先例）。

- **Combat 类事件的 `Outcome` 与 combat-service `Spoils` / `EncounterSpec` 的分工未明写（跨草稿核对点）。**
  既有：战斗战利品出自 `CombatResult.Spoils`，记 `Source.CombatReward`，`BaseReward` / `RewardPoolId` 在 `EncounterSpec` 上（S5 的缺口 B 承载）；而 `HiddenStatGrade` 推拉对 Combat 三档同样开放、走 outcome 侧。
  - 故 Combat 事件的 `Outcome` **既不能恒为空**（还要装隐藏属性推拉与经验档），**也不能装战利品**（那是 combat-service 的）。这条边界草稿一字未写，而 `Outcome` 与 S5 的 `Encounter` 将同批落在同一个 record 上。
  - 选项：(a) 明写「Combat 类的 `Outcome` 只承载隐藏属性推拉 + 经验档 + 事件级产出；战斗战利品恒不进 `Outcome`，走 `EncounterSpec.BaseReward` / `RewardPoolId` → `Spoils`」（推荐）；(b) 不写 ⇒ 两格边界含糊，`/derive-requirements` 无从切验收标准。
  - **推荐 (a)**：依据 `systems/common-properties.md`「成员的分野判据 = 谁组装出这条 element」这条既有承重判据。

- **「加载期校验：`Priority` 非模板字段（内容作者不得填）」这条检查的可实现形态不明。**
  既有库从未在 `AdventureEventData` 上定义过 `Priority`/`eventPriority` 字段（明写「不由内容作者在 `.tres` 写死」）。一个**从不存在的字段**没有「加载期检出它出现了」的机制（Godot `Resource` 的 `[Export]` 面是编译期决定的）。
  - 选项：(a) **删掉这条加载期校验**，只保留物化后断言 `Priority ∈ {0,1}` + 文字纪律（推荐）；(b) 保留 ⇒ 写下一条无法实现的校验，`/blueprint` 会照它开工。
  - **推荐 (a)**。

### 🔵 可推演（不进 interview）

- **物化判据三条 + 反向硬边界**可直接落笔：它与既有快照判据同形，且 `systems/services/future-event-service.md` 已明写「快照存哪些字段由一条判据给出，不逐字段拍板」。（依据：该文件「意图」小节 + `adventure-event/common-properties.md`「判据先于字段表」）
- **清单闭合的表述**：本分片答缺口 A、S5 答缺口 B ⇒ 「多数属性由物化决定」自此有可核对边界。（依据：草稿子项 1 推论 + S5 裁决）
- **`PastEventEntry` 注释改写要保留后半**：`⟨随「EventOption 完整物化字段清单」与「敌人实例类型形态」两项答定后扩充⟩` → 改写为「本项不带来痕迹侧扩充」时，**敌人实例那一项是否带来扩充由 S5 决定**，不能由本分片一口咬定 0 新增。（依据：既有注释同时挂了两项）
- **存档 schema bump 合并**：五份草稿同批 ⇒ 一次 bump、空迁移，走既有 MigrationManager 骨架。（依据：`sync-service.md` + 用户裁决块）
- **溯源三条剥离**：草稿的裁决块含大量过程坐标（「同批 S5」「本轮」「08-17」「推翻」）——提炼进活文档时一律删坐标、留理由的正面陈述；`Source:` 每小节至多一条。（依据：SKILL 第 6b 步）
- **不评估 derive 就绪度**：报告与文档均不给就绪度结论。（依据：SKILL 第 10 步）
- **`ModifierKey.LifeSpanCost` 只读查询的落点**：`profile-service.md` 第 99 行「一个 `ModifierKey` 只能有一个施加点」那条判据旁补一句即可，不动 `LifeSpan` 行的两个修正列（`LifeSpanCost` / `null` 维持原样）。（依据：该表 `Jade` 行的「两列恒为 `null`」是**另一种**情形——那是施加点已移到物化侧；本条是施加点不动、只多一次只读查询）

### ✅ 用户已在评审中定下（照定案处理，不进 interview）

- 缺口 A：加 outcome 定稿载体格，权重 / 抽取**全部在物化时固化**，结算时只选侧不掷骰 → **取 A**。
- 松动的是 `life-cycle-service.md` / `architecture.md` / `adventure-event/common-properties.md` 三处 resolver 注释，**不动 `Source.EventOutcome` 定义** → 定案。
- `combatTier` 两处都不加，走 `EventId` 溯源；与 `PastEventEntry.EventType` 的口径不对称**须明写理由**（`EventType` 存的是呈现口径，Explore 时与真身不同；tier 无此分叉）→ **取 A**。
- `lifeSpanCost` 一律定值（非负整数，物化取负），不留区间 → **取 A，标 `[采纳推荐 — 待复核]`**（⇒ handoff 中须打此标，并**留在 open-questions**，见第 5 节）。
- Band 2 展示走只读 `ApplyModifier` 查询，施加点仍在 `TryApply`；`profile-service.md` 补「只读查询不构成施加点」→ **取 A**。
- `Priority` 保留 `int` + 断言（草稿 `[既有推演]`，评审未推翻）。
- `PlotModulation` 不为新增物化格扩字段 + 一条判据入 `plot-manager.md`；**但「六字段」措辞须按 S5 的 `EnemyPoolScope` 删除改为「五字段」**。
- 派生实例承载归 S3（`CharacterProfile.activeEvent`）；本草稿「派生只改字段值、不改字段面」「`Outcome` 不参与派生改写」两条假设获保留。

## 3. 拟改动文档清单

**⚠ 本分片拟定的完整 `EventOption` 字段面（供跨草稿交叉核对）** —— 本分片只主张 **+1 格**；S5 的 `Encounter` 是**另一格**，两格合并后才是最终面：

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,
    string             EventId,
    EventType          EventType,
    int                Priority,                  // { 0, 1 }；保留 int，不塌缩 bool；物化后断言
    ProfileChangeSpec  SelectCost,                // 已取负；LifeSpan 恒 ≤ 0；modifier 尚未施加
    bool               IsRevealed,
    string             RevealedEventId,
    string             DestinationLocationId,
    IReadOnlyList<ResearchSlot>  ResearchSlots,
    IReadOnlyList<ExchangeOffer> ExchangeStock,
    int                RerolledCount,
    EventOutcomeSpec   OutcomeSpec                // ★ 本分片 +1 格（字段名建议 OutcomeSpec，见 🟠 撞名）
    /* S5 另加：EncounterSpec Encounter（可空）—— 不属本分片 */);
```

- **本分片明确不加的**：`CombatTier? Tier`（两处均不加）· 任何文本类字段 · 真身 `ContentEnabled` 态 · `lifeSpanCost` 的 `[min,max]` 区间字段。
- `EventOutcomeSpec` 的**内部字段面本分片不定稿**（见 🔴/🟠）：顶层只主张「按结算走向分侧、抽取已掷定」，内部留 `⟨待定⟩`。

| 文档 | 拟新增/修改的要点 |
|---|---|
| `systems/services/future-event-service.md` | ① `EventOption` record（第 176–188 行）加一格 `EventOutcomeSpec OutcomeSpec`，删除行尾 `/* ⟨待定：其余物化字段清单，见待决问题⟩ */` 占位注释 |
| 同上 | ② 「本服务是 AdventureEvent 的唯一物化点」小节内补**物化判据三条**：① 由 seeded RNG 掷定；② 由情境代入而定（角色状态 / 篇章 / location / `PlotModulation` 参与，模板上只有参数空间）；③ 物化时组装 / 变换而成。三条皆不满足 ⇒ 留模板侧。反向硬边界：文本类字段一律留模板；随 flags 变且无消费方的不落实例 |
| 同上 | ③ 补一句两条判据的分工：物化判据答「这一格在不在定稿实例上」，快照判据答「这一格要不要再抄进 `PastEventEntry`」；例：`ExchangeStock` 在实例上、痕迹侧靠 `AppliedChange` 记账 |
| 同上 | ④ 补 outcome 固化纪律：**抽取 / 权重（从哪个池抽哪一条、掷出几个、哪一档）在物化时掷定并落定稿实例；条件 / 分支（胜负、成败、`ExperienceGrade × FailureRatio` 折算、读隐藏属性当前值）在结算时求值——条件两侧取值均已定稿，结算时只选一侧、不掷骰** |
| 同上 | ⑤ 补「未选项的 outcome 白掷」代价一句（与 `SelectCost` / `ResearchSlots` / `ExchangeStock` 同构，非新代价；RNG 消耗由 `DrawCount` 持久化，确定性不受影响） |
| 同上 | ⑥ 校验补两行：物化后断言 `Priority ∈ {0,1}`（`PushError` + `EventId`）；物化后断言 `OutcomeSpec != null`（无产出用**空 spec**，不用 `null`） |
| 同上 | ⑦ 日志形态：`[FutureEvent-Materialize] instance=<InstanceId> event=<EventId> type=<EventType> prio=<n> cost=<lifeSpan> outcomeRolls=<n>` |
| 同上 | ⑧ 待决问题小节：删除「**`EventOption` 的完整物化字段清单未定**」整条（依赖 S5 答定缺口 B；若 S5 未落地则改为只剩敌人实例那一半） |
| `systems/adventure-event/common-properties.md` | ⑨ 「物化（materialize）」小节补同一份物化判据三条（**回链 future-event-service，不复述全文**） |
| 同上 | ⑩ 第 148 行 resolver 注释 `// GenericEventResolver → 其余四类，读模板上的数据驱动 outcome / effect 定义` → 改为 **`读物化后 EventOption 上的定稿 outcome / effect`** |
| 同上 | ⑪ `PastEventEntry` 第 219–220 行占位注释 `⟨随「EventOption 完整物化字段清单」与「敌人实例类型形态」两项答定后扩充⟩` → 改写为「本项不带来痕迹侧扩充」+ 保留敌人实例那一半（**待 S5 决定是否一并清掉**） |
| 同上 | ⑫ 字段表补一条**口径不对称的正面理由**：`EventType` 存的是**当时呈现给玩家的口径**（Explore 时与真身不同，是一条独立事实）；`combatTier` 无此分叉（一个条目一个档），故按判据不存 |
| 同上 | ⑬ `lifeSpanCost` 条目补：模板侧一个**非负整数定值**（不填 = 取定价表「事件类型 × 篇章」那一格；可填偏移 / 更小的覆盖值，Explore 禁填），物化取负填 `ChangeElement.BaseValue`，`SelectCost` 内是**已定稿的单一负值**；变异位共三个且无一新增（定价表分格 · 条目级偏移/覆盖 · `ModifierKey.LifeSpanCost`） |
| 同上 | ⑭ 待决问题小节：删除「**`lifeSpanCost` 的数据形态**」与「**`Priority` 字段是否从 `int` 退化为 `bool`**」两条；「`EventOption` 完整物化字段清单」那条同⑧处理 |
| `systems/architecture.md` | ⑮ 第 203 行的 `EventOption` record 副本同步加 `OutcomeSpec` 一格（**与 future-event-service 的定义必须逐字一致**） |
| 同上 | ⑯ 第 298 行 resolver 注释同⑩改写 |
| 同上 | ⑰ 「总则 6」小节补一句物化判据的一行摘要 + 回链（**不复述三条全文**） |
| `systems/services/life-cycle-service.md` | ⑱ 第 107 行 resolver 注释同⑩改写 |
| `systems/services/plot-manager.md` | ⑲ `PlotModulation` 小节补判据：**新增一格物化字段时是否跟着加一格，只看它落在哪一面——落内容面（哪些条目进池、以什么权重出现、用哪个敌人池、带内赋级权重、遭遇参数）→ 已有字段够用；落约束面或模板字段面 → 不加字段** |
| 同上 | ⑳ 字段计数措辞：现文「六字段（`TypeWeights` / `EventWhitelist` / `EventWeights` / `EnemyPoolScope` / `LevelBias` / `Tighten`）」出现在**第 55 行、第 253 行、第 287 行**三处 —— **须按 S5 的 `EnemyPoolScope` 删除统一改为五字段**（⚠ 写入面与 S5 重叠，见 🔴） |
| 同上 | ㉑ 待决问题小节：删除「**`PlotModulation` 的字段面是否还需扩**」一条（复核完成：不扩 + 一条判据） |
| `systems/services/profile-service.md` | ㉒ 第 99 行「一个 `ModifierKey` 只能有一个施加点（承重）」判据旁补一句：**只读查询不构成施加点**——Band 2 展示的精确扣减量取 `ApplyModifier(LifeSpanCost, SelectCost 内的 LifeSpan 值)` 的只读查询结果，**不写回定稿实例**（写回即打两次折，与 `Jade` 行明写的坑同款） |
| 同上 | ㉓ 第 85 行 `LifeSpan` 行的两个修正列**维持不变**（`LifeSpanCost` / `null`）——本次不改表，只加判据旁注 |
| `systems/adventure-event/combat/_index.md` | ㉔ 删除待决问题「**`combatTier` 除 `EncounterSpec` 外的落点（轻）**」，改写为一条正面陈述：tier 是模板常量，呈现与履历两个消费方均在同一次 `ContentRegistry.Get()`（取显示名 / 描述 / 图标）里免费拿到；剧本条件填 `PlotCondition.EventResolved` 的 `EventId` 即可，不需要新条件类型；**Explore 遮罩纪律因此少一个守点**（`IsRevealed == false` 时不读真身模板已是既定纪律） |
| 同上 | ㉕ 补明写的唯一退化情形：条目在新 `contentVersion` 中被删除 ⇒ 该痕迹按既定语义降级为「仅标识可读」（`PushWarning`，履历显示未知条目，不阻断读档），tier 与显示名一同丢失，不构成额外损失 |
| `systems/adventure-event/combat/_index.md` 第 32 行 | ㉖ 「它是否也需要出现在 `EventOption` / `PastEventEntry` 上见待决问题」→ 改为「**不出现在二者上，走 `EventId` 溯源**」 |
| `systems/balance.md` | ㉗ `lifeSpanCost` 段补一句：定价**一律定值，表中不设区间列**；本次**不动任何取值**（取值仍归 ch1 数值标杆专场） |
| `systems/services/sync-service.md`（可选） | ㉘ 若既有存档 schema 版本号写在此处，本轮 bump **与同批四份草稿合并为同一次**（空迁移）——**由 orchestrator 统一落笔，避免五份草稿各 bump 一次** |
| `handoffs/2026-08-17-<slug>.md`（新建） | ㉙ 本分片的 handoff；`## Clarifications` 记四项裁决 + 本报告 interview 结论；第 3 项打 `[采纳推荐 — 待复核]` |

## 4. 拟移出的 open-questions 条目

- `open-questions/02-event-options.md`: **「`EventOption` 的完整物化字段清单」** → 答定为「一条物化判据收口 + 缺口 A 加 `OutcomeSpec` 一格 + 缺口 B 归 S5」。**⚠ 整条移出的前提是 S5 确已答定缺口 B**；若 S5 未落地，本条只删「outcome 权重是否固化 / `lifeSpanCost` 形态 / `combatTier` 落点」三个分叉，保留敌人实例那一半。
- `open-questions/02-event-options.md`: **「`Priority = 1` 依什么条件抬升」** → **只答定其中一半**：「字段是否从 `int` 退化为 `bool`」→ **保留 `int` + 两处断言**。**其余（依什么条件抬升、同批多个 `1` 档是否需额外收窄规则）仍留在待答清单**，条目文本相应收窄。
- `open-questions/04-hidden-attributes-plot.md`: **「`PlotModulation` 的字段面是否还需扩」** → 答定为「不扩 + 一条『落内容面 / 落约束面』判据」。**⚠ 与 S5 的 `EnemyPoolScope` 删除同处一条，须合并处理。**

> answer log 文件名（由 orchestrator 代笔）：`answer-logs/log-event-option-materialized-fields.md`（输入是 `inbox/solution-draft-event-option-materialized-fields.md` ⇒ 取该 slug）。

## 5. 拟新增的 open-questions 条目

- `open-questions/02-event-options.md`: **「`lifeSpanCost` 一律定值 —— `[采纳推荐 — 待复核]`」**（强制项，依据 SKILL 第 4.5 / 第 7 步：用户以「取推荐项」方式定下的项**不算拍板**，须同时留在待答清单并在 handoff 打标）。内容：区间旋钮已否决的理由（Band 0/1 不显示成本 ⇒ 方差不可感知；时长旋钮反推精度）成立与否待实测复核。
- `open-questions/02-event-options.md`: **「`EventOutcomeSpec` 的内部字段面」** —— 顶层载体与固化时点已定；内部分解（效果原语的表达、`OnResolved` / `OnFailure` 的具体列、`FailureRatio` 的形态）**阻于「效果关键字体系与目标规则」那次专门 handoff**，本条只记依赖关系，不重复那条待答项。
- `open-questions/02-event-options.md`（视 interview 结果）: **「Combat 类事件 `OutcomeSpec` 与 `EncounterSpec` / `Spoils` 的产出边界」** —— 若 🟠 第 4 条未在合并 interview 中答定，则新增此条。

## 6. 越界发现（不处理，仅记录）

1. **`systems/architecture.md` 第 493 行残留已删除的 `AdvanceMode`**：`──▶ life-cycle-service.AdvanceEventAsync (EventOption 定稿实例; mode = Select | Skip)`。跳过通道与 `AdvanceMode { Select, Skip }` 枚举已整体移除（`adventure-event/common-properties.md` 第 69 行明写「整个枚举删除」），此处是漏改的考古残留。本分片不改（不在拟改动小节内）。
2. **`decisions/ADR-0002` 的 Consequences 尾部待办「`combatTier` 的字段形态（独立枚举字段还是折进遭遇参数结构）」**已被本次答定（落 `EncounterSpec.Tier`，两处都不加独立字段）。ADR 可自由改写，但改 ADR 属独立决定，本分片不动——**建议 orchestrator 在合并 interview 中问一句是否顺手改掉**。
3. **`systems/services/future-event-service.md` 第 68 行**在讲快照判据时列举「本服务侧的承重点是物化产出的数值必进快照（`SelectCost` / `Priority` / Explore 真身 / 敌人赋级）」——新增的 `OutcomeSpec` **按快照判据不进快照**（结果已在 `AppliedChange` 里），与该句并列关系不冲突，但读者可能误读。属相邻措辞，本分片不主动扩改。
4. **`.claude/knowledge/systems/*` 引用层多处标「待建」**，本次改动不触及；如需同步归 `/sync-knowledge`。
