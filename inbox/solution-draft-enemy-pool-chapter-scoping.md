---
type: solution-draft
date: 2026-08-22
question: 敌人取池的第三层「篇章框定」由哪个字段承载？`EnemyData` 的现有字段面（`EncounterScopes` / `PoolScope` / `OverridesDeck`）没有任何一格表达篇章。
source: open-questions/01-combat.md → 内容与数值的残留 → 敌人池的篇章框定载体未定（08-17 新增 · 承重）
targets: systems/enemies/_index.md（`EnemyData` 字段表 + 取池三层 + 待决问题）· systems/enemies/common-properties.md（共有字段表 + `PoolScope` 加载期校验四条）· systems/services/future-event-service.md（物化取池的框定输入）· content/_index.md（敌人类型开张时的字段核对清单）
status: distilled
reviewed: 2026-08-22 — 3 项取向全部裁决；合并 interview 另裁定 EncounterScopes 就地订正为 CombatTier[]（草稿照抄了与 ADR-0002 相抵的一侧）· 通用池保留既有的「或两字段皆空」分支 · Travel 一类豁免 ChapterScope（否则「Travel 兜底恒可产出 ⇒ 无轮回死锁」这条承重结论失效）· Finale 行空池校验放宽为含专属条目 · 境界词文案扫描改为纯结构判定 · content/_index.md 本次不改。**事件侧 ChapterScope 归 generation-weighting 分片落笔**。**待复核 1 项**：ChapterScope 命名
confirmed: 2026-08-22 —— 全部 [采纳推荐 — 待复核] 项经批量评审确认，无推翻
distilled-to: handoffs/2026-08-22-enemy-pool-chapter-scoping.md
---

# 方案草稿 — 敌人池的篇章框定载体

## 问题

`systems/enemies/_index.md` 的取池伪码写着三层框定：

```csharp
var pool = ContentRegistry.AllEnabled<EnemyData>()
    .Where(e => e.EncounterScopes.Contains(spec.EventType))                    // ① 事件类型作用域
    .Where(e => e.PoolScope == null || e.PoolScope.Matches(currentLocationId, activeArcIds));  // ② 池归属
    // ③ 篇章框定照旧
```

第三层是一句**没有字段支撑的注释**。`EnemyData` 的字段面（`Id` / 图鉴五项 / `KeyCardIds` / 样本卡组 / item 与 power 持有列表 / `EncounterScopes` / `PoolScope` / `OverridesDeck`）里没有任何一格表达篇章，而 `future-event-service.md` 的物化伪码同样把「篇章」列为框定输入。

它卡住两件具体的事：

1. **`common-properties.md` 的第四条加载期校验只能按 `EventType` 单维实现**——「某组合下通用池为空 → 启动期 `PushError`」这条本该覆盖 `(EventType × 篇章)`，现在只能覆盖 `EventType`。而这条校验拦的正是「**能上线、线上不可见**」的死锁：物化取不出敌人 ⇒ 「内容池为空 = 坏数据」会在玩家进程里炸。
2. **内容侧「一个敌人属于哪几章」没有落笔处**——`content/enemy/` 类型档案尚未开张，字段核对清单缺这一格就没法开张。

## 约束（来自既有设计）

- **`CharacterProfile.chapter : int（1–3）`** 是篇章的既有表达（字段 5，权威 `decisions/ADR-0004`）。篇章数是**固定的游戏结构**——这一点已被 `chapterRetry`「篇章数是固定的游戏结构，不用字典 / 索引数组」明确用作判据。
- **本库已有一个同形字段作为先例：`PlotArcData.ChapterScope : int[]`**——「允许存活的篇章；空 = 不限」。→ `systems/services/plot-manager.md`
- **location 不随篇章 / 境界变化，三个篇章共用同一张 `locationMap`**；篇章间的难度差异由敌人赋级带承载，**不由换图承载**。→ `systems/services/future-event-service.md`
- **`±2` 赋级带三章统一**，赋级函数不接受任何区间覆盖参数。→ `systems/balance.md`、`systems/enemies/_index.md`
- **池归属的唯一权威在敌人条目一侧**，location 条目不持敌人清单；反向悬空因此不存在。→ `systems/enemies/common-properties.md`
- **地域 / arc 专属条目是叠加不是替代**，通用敌人在任何地域 / arc 下恒进池。→ `systems/enemies/_index.md`
- **`PoolScope == null` = 通用池，恒进池且 `Matches` 不被调用**；`PoolScope` 非 null 但两字段皆空 = 空壳 → `PushWarning`。→ 同上
- **坏数据在启动期大声失败**，把只在线上显形的洞提到启动期。→ `.claude/rules/data-resource-rules.md`、`systems/services/content-service.md`
- **具名 `Id` 字段 + 加载期悬空校验，不用 tag**（`PoolScope` 否决 tag 方案的承重论据）。→ `systems/enemies/_index.md`

## 建议方案

### 1. 载体 = `EnemyData` 上新增顶层字段 `ChapterScope : int[]`，与 `EncounterScopes` 平级
`[既有推演]`

**沿用 `PlotArcData.ChapterScope` 的字段名、类型与语义**，一字不改：`int[]`，**空数组 = 不限（三章通用）**，取值域 `1..3`。

选**顶层字段**而非塞进 `PoolScope`，三条理由，任一条单独成立即封死另一选项：

| 理由 | 塞进 `PoolScope` 会怎样 |
|---|---|
| ① **`PoolScope == null` 是「通用池」的判据，且它恒进池、`Matches` 不被调用** | 一个「三章通用但只在 ch3 出现」的敌人**必须**把 `PoolScope` 从 null 改成非 null，于是它不再是通用条目——通用池的定义被篇章这一维污染 |
| ② **空壳校验会打架** | `PoolScope` 非 null 但 `LocationId` / `PlotArcId` 皆空 → 既定 `PushWarning`。而「只填篇章、不限地点与 arc」正是这个形状，一条完全正当的内容写法会稳定触发告警 |
| ③ **通用池空池校验需要篇章与 `PoolScope` 正交** | 第四条校验枚举的是「**通用池**（`PoolScope == null`）在某 `(EventType, 篇章)` 下是否为空」——若篇章住在 `PoolScope` 里，这句话自己就矛盾了 |

**篇章与「池归属」不是同一维度**：`PoolScope` 表达的是「**在哪个空间 / 哪条剧情线**里出现」，篇章表达的是「**在修行的哪个阶段**出现」。前者是内容的横向切分，后者是纵向的进度门。`EncounterScopes`（事件类型作用域）同样是顶层字段而非塞进 `PoolScope`，本条与它对称。

### 2. 语义 = 空数组表示不限，且**不**升级为 `PushError`
`[既有推演]` + `[取向选择]`（见「仍需用户决定」第 2 题）

这里与 `EncounterScopes` 有一处**有意的不对称**，须写明理由，否则日后必被当成漏写：

- `EncounterScopes` 空数组 → `PushError`。因为 `.Contains(eventType)` 对空数组恒假，**漏填 = 该敌人永不出现**（静默缩小抽取池，写了永不显形的内容）。
- `ChapterScope` 空数组 → **合法，表示三章通用**。因为它的过滤写成「空 ⇒ 恒真」，**漏填 = 该敌人在三章都出现**——不是死条目，只是范围偏宽。且它与 `PlotArcData.ChapterScope` 的既有语义一致，两处同名字段取相反语义是纯粹的坑。

代价（诚实标注）：漏填不会被机械发现。缓解 = **人工审阅级告警**（与既有的「专属池条目的 `EncounterScopes` 与该 arc 可达事件类型无交集 → `PushWarning` + 列举」同族）：若某敌人的 `ChapterScope` 为空**且**图鉴文案里出现境界词（筑基 / 金丹 / 元婴），列进评审清单。这条不硬校验。

### 3. 取池第三层落成一行，与前两层同形
`[既有推演]`

```csharp
var pool = ContentRegistry.AllEnabled<EnemyData>()
    .Where(e => e.EncounterScopes.Contains(spec.EventType))                    // ① 事件类型作用域
    .Where(e => e.PoolScope == null                                            // ② 池归属
             || e.PoolScope.Matches(currentLocationId, activeArcIds))
    .Where(e => e.ChapterScope.Length == 0                                     // ③ 篇章框定
             || e.ChapterScope.Contains(currentChapter));
```

- **入参 `currentChapter` 是单值 `int`**——与 `activeArcIds` 必须是集合形成对照：角色恒处于**恰一个**篇章（`CharacterProfile.chapter`），而 `Active` arc 可有多条。这一点须写出来，否则实现会照抄 arc 那一层的集合形状。
- **三层全部叠在 `AllEnabled()` 之后**，不改既有的过滤顺序纪律。
- **篇章框定同样是「叠加不是替代」**：`ChapterScope` 为空的通用敌人在三章都进池，专章条目只在自己那章加项。这与既定的「不存在地域独占生态」同构。

### 4. 空池校验从单维扩到两维：`(EventType × 篇章)` 共 9 个组合
`[既有推演]`

`common-properties.md` 的第四条校验改写为：

> 对每个 `(eventType ∈ { Practice, Combat, Finale }, chapter ∈ { 1, 2, 3 })` 组合，**通用池**（`PoolScope == null` 且 `ChapterScope` 命中该章）为空 → `PushError` + 报出该组合，启动期早失败。

- **枚举面是封闭且极小的**（3 × 3 = 9），故这条是纯粹的加法，没有组合爆炸风险。这正是「篇章数是固定的游戏结构」这条既有判据买来的好处。
- **`Finale` 一行值得单独看一眼**：天劫是指派而非抽取（`diff` 恒 +1、`OverridesDeck == true`），但它仍须**存在于池中**才能被指派到——三章各需至少一条 `Finale` 敌人。两维校验因此顺手把「ch2 忘了写天劫」这个洞也堵上了，而单维校验堵不住（ch1 有天劫就够它满意）。

### 5. 加载期校验（新增两条，与既有四条并列）
`[既有推演]`

| 违规 | 语义 | 处置 |
|---|---|---|
| `ChapterScope` 含 `1..3` 之外的值 | 越界，指向不存在的篇章 | `PushError` + 抛，带敌人 `Id` + 越界值 |
| `ChapterScope` 含重复值 | 无害但多半是手误 | `PushWarning`，去重后继续 |
| （改写既有第四条）某 `(EventType, 篇章)` 组合下通用池为空 | 能上线、线上不可见的死锁 | `PushError` + 报出组合 |

**不设「`ChapterScope` 长度必须 < 3」这类检查**：显式写 `[1,2,3]` 与留空语义相同，但显式写是内容侧表达「我确认过，三章都出」的正当方式，不该被判为错。

## 具体形态（可 derive 的落地面）

```csharp
// EnemyData 新增一格，与 EncounterScopes 平级
[Export] public int[] ChapterScope { get; set; } = System.Array.Empty<int>();
// 允许出现的篇章（CharacterProfile.chapter，1–3）；空 = 不限（三章通用）
// 取值须在 1..3 内，否则加载期 PushError
```

`EnemyData` 字段表新增行（供 `enemies/_index.md` 与 `common-properties.md` 直接采用）：

| 字段 | 形态 | 语义 | 缺失 / 违规时 |
|---|---|---|---|
| `ChapterScope` | `int[]`，取值 `1..3` | 可出现在哪几个篇章；**空 = 不限**（与 `PlotArcData.ChapterScope` 同名同义） | 空数组**合法**；越界值 → `PushError`（带 `Id` + 越界值）；重复值 → `PushWarning` + 去重 |

物化取池入参（`future-event-service.md` 的框定输入）：

```
框定输入 = (spec.EventType, currentLocationId, activeArcIds, currentChapter)
                                                             ^^^^^^^^^^^^^^ 单值 int，取自 CharacterProfile.chapter
```

## 后果

- **`EnemyData` schema +1 字段。** 它是内容侧字段、不进存档（存档只记 `EnemyId` / `EnemyInstance`），故**无存档迁移**；`EnemyInstance` 不变。
- **加载期校验从 3 个组合扩到 9 个组合**，纯加法，无性能面影响（启动期一次）。
- **内容侧的「一个敌人属于哪几章」有了唯一落笔处**，且与「池归属的唯一权威在敌人条目一侧」同构——location / 篇章两侧都不持敌人清单，反向悬空仍然不存在。
- **`content/enemy/` 类型档案开张时**，字段核对清单须含 `ChapterScope` 一行。该类型档案目前**尚未存在**（`content/` 下只有 `_index.md`），故这是开张时的输入，不是回填。
- **`enemies/_index.md` 与 `common-properties.md` 各删掉一条待决问题。**

## 备选方案（已考虑并否决）

- **B：复用 `PoolScope.PlotArcId` 指向 Chapter arc**（`PlotArcData.Tier == Chapter` 恒有一条 `Active`，看起来现成）。**否决三条**：① 篇章 arc 是**剧本内容**，其 `Id` 随 Story 内容走（一个 Story 含三个 Chapter，换一条主线就换一批 arc id），而「敌人属于第几章」是**结构性的进度位置**，不该绑在可替换的剧本条目上；② 它会把敌人池对 `plot-manager` 的推进状态产生**运行时依赖**——arc 未激活 / 排队时敌人池会莫名变空；③ 撞上第 1 条的三个理由（`PoolScope` 非 null 即不再是通用条目 / 空壳告警 / 空池校验的正交性）。
- **C：篇章框定由 location 承载**（不同篇章走不同地图）。**否决**：与既定的「**location 不随篇章 / 境界变化，三个篇章共用同一张 `locationMap`**」正面冲突，且那条定案自带理由（难度差异由赋级带承载，不由换图承载）。
- **D：一组 tag 字符串**（`"ch1"` / `"ch2"`）。**否决**：与 `PoolScope` 否决 tag 的论据逐条同构——丢掉类型信息、越界写法（`"ch4"`、`"CH1"`）无从机械校验。篇章是 `int`，本库既有表达就是 `int`。
- **E：整层删除「篇章框定」，取池只保留两层。** 认真考虑过，见「仍需用户决定」第 1 题——它不是荒谬选项，但本草稿倾向保留（理由见该题）。

## 与既有决策的张力

**一条，是设计层面的真张力，值得用户明确表态：**

既定的「**篇章间的难度差异由敌人赋级带（相对角色当前等级）承载，同一张图在三个篇章重走，敌人强度自动跟着角色走**」意味着——**从数值角度看，任何敌人在任何篇章都能用**。若纯按数值走，`ChapterScope` 会是一个永远为空、没有真实消费者的字段。

本草稿主张保留它，理由是**叙事一致性**而非数值：ch1 炼气期的凡俗山贼在 ch3 金丹篇章以「金丹初期」的赋级出场，图鉴词条（人物背景 / 功法简介）会与实际遭遇当场对不上——而**图鉴是敌人可读性的主通道**（意图机制移除后更是如此），既有的「叙事一致性靠内容纪律：标为 `[Practice, Combat]` 的条目其图鉴与台词必须同时说得通两种语境」这条纪律，在跨篇章上靠纯人工是撑不住的（3 章 × N 条比 2 种语境难得多）。**`ChapterScope` 是把这条内容纪律变成机械可校验的那一格。**

这条张力不需要松动任何既有决策——赋级带照旧三章统一、地图照旧三章共用；`ChapterScope` 只切「哪些条目参与」，不切「怎么赋级」。但它确实**新增了一条内容编排负担**，故取舍权在用户。

## 前置依赖

- **无阻断性前置。** 字段形态、语义与校验全部可由既有决策推出。
- 弱依赖：`content/enemy/` 类型档案尚未开张（`/scaffold-content-type enemy` 未跑），故本方案的内容侧落点目前是「开张时带上」而非「回填」。这不阻塞设计侧定案。
- 相邻但不阻塞：「敌人是否也以功法构筑卡组」若定为「是」，`EnemyData` 的字段面会另有变动，但与 `ChapterScope` 正交。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> 逐条裁决（`/batch-provide-solution-draft` 合并 interview）：
> 1. 是否保留「篇章框定」这一层 → **已裁决：A · 保留，落成 `EnemyData.ChapterScope : int[]`**。
>    **跨分片扩展（合并裁决）：`AdventureEventData` 同样新增同名同形的 `ChapterScope : int[]`** —— 两处是同一个空格（事件侧的取池链第 ① 步此前只有 `AllEnabled()`），用户裁定两侧同形，不分开处置。事件侧的落笔见 `solution-draft-future-event-generation-weighting.md`。
> 2. `ChapterScope` 空数组的语义 → **已裁决：A · 空 = 不限（三章通用），不报错**（与 `PlotArcData.ChapterScope` 同名同义）
> 3. 字段是否就叫 `ChapterScope` → **A · 是** `[已确认 2026-08-22 · 批量评审]`
>
> **全部待复核项已于 2026-08-22 经批量评审逐项确认，本草稿再无待复核项。**


1. **是否保留「篇章框定」这一层？**（承重取向）
   - **A（推荐）：保留，落成 `EnemyData.ChapterScope : int[]`。** 理由见「与既有决策的张力」——它把跨篇章的叙事一致性从人工纪律变成机械可校验，且顺手补上「每章至少一条 `Finale` 敌人」这条启动期断言。代价：内容侧多一格要填、多一条编排考量。
   - B：删除第三层，取池只保留 `EncounterScopes` + `PoolScope` 两层，并把 `enemies/_index.md` 与 `future-event-service.md` 里的「篇章框定照旧」整句删掉。理由：赋级带已让任何敌人在任何篇章数值可用，叙事一致性交给内容纪律。代价：ch1 的凡俗对手会在 ch3 以金丹赋级出场且图鉴对不上；空池校验永远停在单维；且「篇章框定」这句悬空注释必须删干净，否则它会一直被当成待实现项。
   > **这一题必须先答**——答 B 则第 2–4 题全部作废。
2. **`ChapterScope` 空数组的语义取哪一档？**（仅当第 1 题答 A）
   - **A（推荐）：空 = 不限（三章通用），不报错。** 与 `PlotArcData.ChapterScope` 同名同义，且漏填的后果是「范围偏宽」而非「死条目」。
   - B：空 = `PushError`，强制每条敌人显式声明篇章。与 `EncounterScopes` 对称、漏填必被发现；代价是与 `PlotArcData.ChapterScope` 同名反义（真实的踩坑源），且每条通用敌人都要写一遍 `[1,2,3]`。
3. **字段是否就叫 `ChapterScope`？**（仅当第 1 题答 A · 轻）推荐**是**——与 `PlotArcData.ChapterScope` 同名是特性不是冲突：同名同义同类型，读者一次学会两处。若担心跨类型同名混淆，备选 `ChapterScopes`（与 `EncounterScopes` 的复数形式对齐），但那会与 `PlotArcData` 的单数形式分叉。
