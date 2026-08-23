# `EventOutcomeSpec` 的内部字段面

- id: 2026-08-22-event-outcome-spec-fields
- date: 2026-08-22
- topic: systems/services/future-event-service.md · systems/adventure-event/common-properties.md · systems/architecture.md · systems/adventure-event/explore/_index.md · systems/services/profile-service.md · systems/game-progression.md · systems/adventure-event/combat/_index.md
- status: distilled
- distilled-to: systems/services/future-event-service.md · systems/adventure-event/common-properties.md · systems/architecture.md · systems/adventure-event/explore/_index.md · systems/services/profile-service.md · systems/game-progression.md · systems/adventure-event/combat/_index.md

## Intent（distilled）

**一行摘要：** `EventOption.OutcomeSpec` 的内部落定——两侧复用 `ProfileChangeSpec`（三列开放 / 其余逐列恒空）、`Elements` 的 key 取值域两层收紧、经验失败折算在物化组装时完成、模板侧五格参数空间（`OutcomeRule` 规则 → 物化展开）；并顺带答定 Explore 壳的产出取真身模板、置换 / 禁用候选前移到物化时掷定。

### 一、定稿实例侧

- **两侧的载体类型复用 `ProfileChangeSpec`，不新建窄类型。** 三条依据：成本与产出共用一个类型是既定形态；`eventEnd` 的合并零 element 翻译；`SelectCost` 已示范「复用宽类型 + 恒空列断言」这套纪律。
- **开放三列：`Elements` / `AbilityElements` / `DeckElements`；其余各列恒空。** 判据一句：**内容作者能如实声明的量才进 `OutcomeSpec`；由服务算出绝对值、或由代码采集的一律不进。**
- **恒空列逐列穷举，承重表述不写列数** —— 与「`ProfileChangeSpec` 的列表数不进承重表述」同一条纪律。
- **`AbilityElements` 只承载 `Op == Grant`，且 `(Kind, Scope)` 作用域恒为 `Character`、`Source == EventOutcome`**（正向白名单，与合法子集表逐格对齐）。**事件产出不能给账号级法则或古宝。**
- **`Elements` 的 key 取值域两层收紧：** 物化后可出现 `LifeSpan`（仅正向）/ `LifeTotal` / `ManaLimit` / `Jade` / `ExperiencePoint` / `Faith` / `Bloodlust`；`PowerFragment*` 七 key 与 `BundleRedeemedOrdinal` 恒不出现。**`ManaLimit` 的量值恒为 1。**

### 二、模板侧五格参数空间

`ExperienceGrade` · `FailureRatio`（百分比整数，默认 50）· `HiddenStatGrants` · `OnResolvedRules` · `OnFailureRules`。`OutcomeRule` 三个 `Kind`（`FixedResource` / `GrantFromPool` / `DeckOperation`）照抄 `ExchangeStockRule` / `ResearchSlotSpec` 的「规则 → 物化展开」范式。

- **`FixedResource` 的可写 key 收窄为 `LifeSpan` / `LifeTotal` / `ManaLimit` / `Jade`。** `ExperiencePoint` / `Faith` / `Bloodlust` 只能由物化组装从档位表展开——**「物化后可出现的 key」与「模板可声明的 key」是两张表**。
- **`DeckOp` 取 element 层 `DeckChangeOp` 五值；`GrantFromPool.PoolKind` 收窄为能力族两值。** 两个 `Kind` 的职责因此不重叠，断言可逐 `Kind` 写死落哪一列。
- 七条内容模板加载期校验、十条物化组装后断言，均已落文档。

### 三、置换 / 禁用候选前移到物化时掷定

不由 `OutcomeSpec` 承载，而落 `EventOption.AbilityChangeSlots`（形状与 `ResearchSlots` 同构，仍走 `Reward` 子流）。三个决策点面板的掷定时点由此一致；防重掷也更严。**存档 schema 因此有一格增量**（当前无线上存档 = 空迁移）。

### 四、术语纪律

本库「效果」一词有**两个所指**：战斗效果原语（`EffectData` / `KeywordData` / `TargetSlot` / `EffectScope` / `EntryFilter`，作用于战场条目与手牌、寿命一场战斗）与事件产出 element（`ProfileChangeSpec` 各列，作用于 Profile 字段、跨事件持久）。**两套作用面不相交。** 本条落笔起，产出侧一律称**「产出 element」**，与「字段名取 `OutcomeSpec` 而非 `Outcome`」同源。

### 五、Explore：成本取壳、产出取真身

产出在揭示前从不展示 ⇒ 成本侧的防泄漏理由在产出侧整条不成立；而防重掷的理由成立且已由 `Encounter` / `DestinationLocationId` 立过先例。这条不对称必须写明，否则后来者会去「统一」其中一条，而统一到哪一侧都造成实际损坏。

## Clarifications（interview 产物）

- **列数口径三处对不上（草稿写「12 列 / 9 条恒空」，库中实为 11 列）** → 承重句**不写列数**、断言清单逐列穷举；并顺手补齐 `architecture.md` 漏登的 `CodexElements` 一行。推翻草稿 ① / ② 的「12 列 / 9 条」两处数字。
- **`ExperiencePoint` / `Faith` / `Bloodlust` 是否进 `OutcomeRule.FixedResource` 白名单** → **排除**。推翻草稿 ③ 的白名单——根因是草稿把「物化后可出现的 key」与「模板可声明的 key」写成了同一张表。
- **`ManaLimit` 的 `Magnitude` 无约束** → 加一条加载期校验 + 一条物化断言：`ResourceKey == ManaLimit ⇒ Magnitude == 1`。补上草稿未覆盖的一个口。
- **`PoolKind` 含 `PlayerItem`（古宝）而合法子集表对它是 ❌** → 改为**正向白名单**：作用域恒 `Character`、`PoolKind ∈ { CharacterItem, CharacterPower }`。推翻草稿断言 6 的负向排除写法（它排的 `(Power, Player)` 恒不可达，真正的缺口是 `PlayerItem`）。
- **置换 / 禁用的承载与掷定时点** → 前移到物化时掷定、落 `EventOption` 上一个定稿字段。**不给 `OutcomeRule` 增第四个 `Kind`**（推翻草稿 ② 的「`AbilityElements` ✅ 含置换 / 禁用」）；`OutcomeSpec.AbilityElements` 收窄为只承载授予。
- **`DeckOp` 复用面板层六值枚举** → 改用 element 层 `DeckChangeOp` 五值 + `PoolKind` 只含能力族。推翻草稿 ⑥ 的 `DeckOperationKind`（它装不下 `AddLooseCard`、又装进了不落 `DeckElements` 的两个成员）。
- **`FailureRatio` 由 `0.5` 改百分比整数 `50`** → 采纳，且改动面补上 `systems/game-progression.md`（草稿改动面漏列）。
- **`RngStream.Reward`「三者从不并发」在一次批物化内不再自明** → 明写批内抽取顺序（option 索引升序；单 option 内 Research 槽 → `OnResolvedRules` → `OnFailureRules`）+ `#if DEBUG` 顺序断言。
- **`SelectCost` 侧不变式口径数（草稿写「三条 / 七条」）** → 实为 **9 条**（8 列恒空 + 1 条取值域收紧），outcome 侧镜像按 9 条口径逐条补进 `profile-service.md` 的施加失败语义表。
- **Combat 条目能否声明 `GrantFromPool` 产出** → **允许**，并在 `combat/_index.md` 留一句编排须知（明写「战后奖励厚度轴不覆盖这一批」这条代价）。
- **「阻于效果关键字体系与目标规则」这处登记** → 核实为**误挂**：两套作用面不相交，本条从一开始就不被它阻塞。落笔时把术语纪律写清。
- **隐藏属性推拉的承载** → 两侧各展开一份相同 element，不加顶层 `Always` 第三格。
- **Explore 壳的 `OutcomeSpec` 由谁的模板物化** → 取真身模板，并在两份文档写明「成本取壳、产出取真身」这条不对称及其理由。

## Open questions

- **`GrantFromPool` 型产出不加加载期池断言（闸 ①）** `[采纳推荐 — 待复核]` —— 短缺时降级 + `PushWarning`，运营上要靠日志发现「某事件长期发不出东西」。若判定「一个永远发不出奖励的事件条目」属必须启动期拦下的编排错误，则应补闸 ①（代价：第三个余量常量 + 拉长启动期校验）。
- **`OutcomeRule` 不支持多选一 / 加权掷一条** `[采纳推荐 — 待复核]` —— 一条规则一条产出；具名互斥产出要拆成多个内容条目。
- **`HiddenStatGrant` 的推拉方向如何表达。** 道心可正可负，而 `HiddenStatGrade` 的映射值是正量。本条只定 `(HiddenStat, HiddenStatGrade)` 这一格的形状，**方向位落在哪里（第三个字段 / 映射表带符号 / 逐属性约定）未定**。→ `systems/balance.md`、`systems/adventure-event/common-properties.md`。
- **`ExperienceGrade` / `HiddenStatGrade` / `SelectionWeightGrades` 的映射值**归 ch1 数值标杆专场——不阻塞本条（本条定的是结构与取值域）。
- **「隐藏属性的增减触发」**（哪些事件推哪一档）是内容编排口径，不阻塞本条。

## Notes / triage

- 输入：`inbox/solution-draft-event-outcome-spec-fields.md`（已评审）。
- 本次答结 `open-questions/02-event-options.md` 的「`EventOutcomeSpec` 的内部字段面」整条（含其附带的「⚠ 阻塞来源待重新确认」）；`future-event-service.md`「待决问题」的同名一条随之删除。
- **不移出**：`open-questions/02-event-options.md` 的「生成 / 加权规则与叠加顺序」—— 本条不答它。
- 越界发现（不在本次写入面内）：`research/common-properties.md` 写「`DeckChangeOp`（四值 · element 层）」是未跟上的旧值（`architecture.md` 为五值）；`explore/_index.md`「待决问题」的「事件类型出现概率修正的运算形态未定」已被同批的生成 / 加权管线答定，该条应删。
