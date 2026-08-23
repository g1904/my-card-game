# Phase A — enemy-pool-chapter-scoping

来源草稿：`game-design-documents/inbox/solution-draft-enemy-pool-chapter-scoping.md`（`status: awaiting-review`，含「已全部裁决」块）
目标库：`game-design-documents/`（草稿路径带库前缀，判定无歧义）

## 一句话意图

敌人取池的第三层「篇章框定」落成 `EnemyData` 上与 `EncounterScopes` 平级的新字段 `ChapterScope : int[]`（取值 1–3，空 = 三章通用），取池第三层写成一行 `Length == 0 || Contains(currentChapter)`，通用池空池校验由 `EventType` 单维扩到 `(EventType × 篇章)` 两维，并新增两条 `ChapterScope` 加载期校验；跨分片合并裁决要求 `AdventureEventData` 同步新增同名同形字段。

## 已裁决（不进 interview）

草稿「仍需用户决定」三题在 `/batch-provide-solution-draft` 合并 interview 中已答，按定案处理：

1. **保留「篇章框定」这一层** → A · 落成 `EnemyData.ChapterScope : int[]`。（连带：备选 B/C/D/E 全部作废，不再讨论。）
2. **空数组语义** → A · 空 = 不限（三章通用），不报错；与 `PlotArcData.ChapterScope` 同名同义。
3. **字段名 `ChapterScope`** → A · 是。标 `[采纳推荐 — 待复核]`，须在 handoff 与提炼处保留该标注，并留在待答清单（技能第 4.5 步）。
4. **跨分片合并裁决** → `AdventureEventData` 同样新增同名同形 `ChapterScope : int[]`（空 = 不限）。**「加不加」已定，但「写在哪份文档、由谁写、事件侧的校验口径是什么」未定** —— 见 🔴-1 / 🔴-2 / 🟠-1。

以上四条不再出题；下列问题全部是**裁决落地时新暴露的**冲突与含糊。

## 🔴 冲突

### 🔴-1 事件侧 `ChapterScope` 的写入面与本分片的写入面重叠（编排冲突 · 铁律 ③）

- **[问题陈述]** 合并裁决把 `AdventureEventData.ChapterScope` 挂在**本草稿**的裁决块里，但草稿正文写「事件侧的落笔见 `solution-draft-future-event-generation-weighting.md`」；而那份草稿的 `targets:` 是 `systems/services/future-event-service.md` · `systems/game-progression.md` · `systems/adventure-event/common-properties.md` · `systems/services/plot-manager.md` · `systems/adventure-event/travel/_index.md` · `systems/balance.md`。
  ✗ 两个分片因此**同时写 `systems/services/future-event-service.md`**（本分片写敌人取池框定输入；对方写管线①–⑦ 步与 `SelectionWeight`），并且**都可能写 `systems/adventure-event/common-properties.md`**。
  ✗ 该分片草稿第 350 行的「前置依赖」明写：本条答定后「管线第 ① 步的过滤链据此落笔，且**闸 ② 的池计数口径要跟着改**」——即事件侧的落笔确实在对方分片，但**字段本身的定义面**（形态 / 取值域 / 校验）在本库没有 `AdventureEventData` 字段表可挂（`systems/adventure-event/common-properties.md` 只有「共有属性」条目式行文与「物化」小节，无字段总表）。
  - 选项 (a) **事件侧全部归 future-event-generation-weighting 分片**（本分片只写 `EnemyData` 那一半，并在报告中交回一条「事件侧承接项」）→ 后果：写入面干净不重叠；风险是本分片的裁决块与对方草稿的裁决块必须由 orchestrator 显式对齐，漏传即两侧同名字段语义分叉。
  - 选项 (b) **事件侧字段定义归本分片**（在 `systems/adventure-event/common-properties.md` 新写一条 `ChapterScope` 共有字段条目），对方分片只写①步过滤链与闸②口径 → 后果：同名字段两处定义一次落笔、语义一定同形；但两个 worker 写同一份文件，必须串行波次。
  - 选项 (c) **两份草稿合并给同一个 worker** → 后果：最安全；代价是该 worker 的范围显著变大（对方草稿含七个 targets）。
  - **推荐 (a) + 串行波次**：本分片先跑（`EnemyData` 侧定形），future-event-generation-weighting 后跑并承接同形字段；理由是归属判据「谁定义这类内容的规则」在事件侧本就属对方分片的 `AdventureEventData` 字段扩张段（它已在扩 `SelectionWeight`，两格一起落笔更自洽），而本分片保持在 `systems/enemies/*`。若 orchestrator 选 (a)，仍须在 `future-event-service.md` 上做**单写者分区**——见「拟改动文档清单」的具体行。

### 🔴-2 `EncounterScopes` 的取值域在 ADR-0002 与 `systems/enemies/*` 之间已经不一致，而本次要把它作为「9 组合枚举」的一个轴固化下来

- **[问题陈述]** 草稿 §4 写「对每个 `(eventType ∈ { Practice, Combat, Finale }, chapter ∈ {1,2,3})` 组合」。
  ✗ 权威一：`decisions/ADR-0002-adventure-event-taxonomy.md` 第 40 / 42 / 45 行 —— **`eventType` 是五值 `{ Combat, Exchange, Research, Explore, Travel }`**；Practice / Standard / Finale 是 **`combatTier` 三值**，且明写「`EnemyData.EncounterScopes` 两层敌人池（`[Practice]` / `[Combat]`）**改为按档位取值**」。
  ✗ 权威二：`systems/adventure-event/combat/_index.md:31` 与 `:152` 用的是 `[Practice]` / `[Standard]` / `[Practice, Standard]` —— **`Standard`**。
  ✗ 权威三：`systems/enemies/_index.md:22` 与 `systems/enemies/common-properties.md:21` 写的是 `EncounterScopes : EventType[]`，取值 `{ Practice, Combat, Finale }` —— **类型名错（应为 `combatTier`）、成员名错（`Combat` 应为 `Standard`）**。
  草稿逐字照抄了权威三。这直接撞 `Context.md` 的「贯穿整条链路的类型一致性」，且这次要把它写死成一张 3×3 校验表 —— 一旦落笔，`EventType.Combat`（五值枚举的成员）与「Standard 档」会在同一份校验里指同一个东西，实现侧必然分歧。
  - 选项 (a) **就地订正为 `EncounterScopes : CombatTier[]`，取值 `{ Practice, Standard, Finale }`**，9 组合改写为 `(combatTier × chapter)` → 后果：与 ADR-0002 / `combat/_index.md` 对齐；需同改 `enemies/_index.md` 字段表、`enemies/common-properties.md` 字段表与第四条校验、`future-event-service.md:104/108/127` 的伪码与遭遇参数行、以及取池伪码里的 `spec.EventType`（应为 `spec.Tier`，`EncounterSpec.Tier` 是既有承载格）。
  - 选项 (b) **保留 `EventType[]` 与 `{ Practice, Combat, Finale }` 的现状**，只在本次加篇章维 → 后果：改动面最小；代价是把一处已知的类型不一致固化进启动期校验表，且与 ADR-0002 正面相抵（按根约定，这需要用户明确裁决要不要改写 ADR-0002）。
  - **推荐 (a)**。理由：ADR-0002 是 Accepted 的硬边界且论证充分（「`combatTier` 是必需的，不是修饰」），`combat/_index.md` 与 `EncounterSpec.Tier` 两处也已按档位写；`enemies/*` 那两行是孤例。**注意这是一次超出本草稿范围的顺手订正**，改动面涉及本分片全部三份目标文档 + `combat/_index.md`（后者不在本分片 targets 内 → 若采纳，需 orchestrator 明确授权把 `systems/adventure-event/combat/_index.md` 纳入本分片写入面，或交回作承接项）。

### 🔴-3 草稿改写第四条校验时，静默删掉了既有定义里的「空壳 `PoolScope`」分支

- **[问题陈述]** 既有权威 `systems/enemies/common-properties.md:34`：「某 `EventType` 下的**通用池**（**`PoolScope == null` 或两字段皆空**）为空 → `PushError`」。
  ✗ 草稿 §4 的改写：「**通用池**（`PoolScope == null` 且 `ChapterScope` 命中该章）为空 → `PushError`」——「或两字段皆空」这一支**没了**。
  同时草稿 §1 的理由 ① 又反复以「`PoolScope == null` 是通用池的判据」立论，与既有文本的「或两字段皆空」互相打架。这不是措辞问题：一个只填了空壳 `PoolScope`（已 `PushWarning` 但不阻断）的条目，在两种口径下**分别算 / 不算通用池**，直接决定启动期是否误报 `PushError` 拦下正当内容。
  - 选项 (a) **保留既有口径**：通用池 = `PoolScope == null` **或**两字段皆空；改写只在其后 `AND ChapterScope 命中该章` → 后果：与既有文本一致，空壳条目照旧计入通用池（它语义上确实等同通用池，这正是既有 `PushWarning` 而非 `PushError` 的理由）。
  - 选项 (b) **收窄为草稿口径**：只有 `PoolScope == null` 才算通用池 → 后果：空壳条目从通用池里被踢出，`PushWarning` 的性质从「提示写法不规范」升级为「这条内容不再兜底空池校验」，须同步改写第三条校验的语义说明。
  - **推荐 (a)**。理由：既有文本是当前权威且自带理由（空壳「语义等同通用池」），草稿的删除看起来是行文压缩而非有意裁决；且 (b) 会让两条校验之间产生隐藏耦合。

### 🔴-4 事件侧加篇章框定后，「Travel 兜底恒可产出 ⇒ 轮回死锁在规则层不成立」这条承重结论失去支撑

- **[问题陈述]** 既有权威 `systems/services/future-event-service.md:36 / :183`：「**邻接集合不经 `AllEnabled()`，这是本服务取池纪律的唯一例外** …… 这条例外也是『Travel 兜底恒可产出』的前提」「闸 ② 移出条目后的退化情形…… **邻接集合不经 `AllEnabled()` ⇒ Travel 兜底恒可产出，轮回死锁在规则层不成立**」。
  ✗ 该例外只豁免了**邻接图**，没有豁免 **Travel 事件条目本身**——闸门批仍要「这些邻接各**物化一个 Travel EventOption**」，而物化取的是 `AdventureEventData`。给 `AdventureEventData` 加 `ChapterScope` 后，若某一章没有任何 `ChapterScope` 命中它的 Travel 条目，闸门批产不出任何选项 ⇒ **轮回死锁在规则层重新成立**，且这个洞是「能上线、线上不可见」的形态（内容编排疏漏，启动期无人拦）。
  - 选项 (a) **事件侧也做 `(EventType × 篇章)` 通用池空池校验**（五类 × 3 章 = 15 组合，`PushError`）→ 后果：与敌人侧同形，洞被提到启动期；代价是事件侧此前**没有任何空池加载期校验**，这是新增一整类断言（闸 ① 只覆盖 Research / Exchange 的候选池条数）。
  - 选项 (b) **Travel 一类豁免 `ChapterScope`**（`eventType == Travel` 的条目其 `ChapterScope` 必须为空，加载期 `PushError`）→ 后果：兜底纪律原样保住，只加一条极便宜的校验；代价是五类事件里有一类不对称，须写明理由（与既有的「Travel 不计入 `eventCountLimit`」「Travel 的 outcome 不得含 `LifeSpan` 产出」同族，Travel 本就是结构性通道而非内容）。
  - 选项 (c) (a) + (b) 同时做。
  - **推荐 (b)，其次 (c)**。理由：Travel 在本库已被明确建模为**结构性闸门**而非内容池的一员，既有已有两条 Travel 专属禁令作先例；(a) 单独做不够——它只保证「非空」，不保证闸门批那一刻邻接方向上有可用条目。**这一题必须先于事件侧落笔回答。**

## 🟠 含糊

### 🟠-1 事件侧 `ChapterScope` 的校验与闸 ② 计数口径未定

- **[问题陈述]** 裁决只说「两侧同形」。同形指的是**字段形态**（`int[]`，空 = 不限，1–3，越界 `PushError`、重复 `PushWarning`）无疑；但事件侧还有两处敌人侧没有的消费点：① 闸 ②（取池期，Research / Exchange 条目的可产出性判定）的池计数**是否在篇章过滤之后计数**；② 事件侧要不要也有空池 `PushError`（见 🔴-4 选项 a）。
  - 选项 (a) 闸 ② 计数**在篇章过滤之后**做 → 后果：与既有「闸 ② 的计数必须与实际抽取链同口径」这条承重纪律一致（该纪律的全部依据就是同口径）。
  - 选项 (b) 不改闸 ② → 后果：出现「总池非空、篇章过滤后为空」⇒ 闸 ② 判过、闸 ③ 抽空，正是既有文本点名要防的形态。
  - **推荐 (a)**（几乎是既有纪律的机械推论，但因为它改的是别的分片的写入面且草稿未提，仍出题确认）。

### 🟠-2 「重复值 → `PushWarning`，去重后继续」中的「去重」是否写回条目

- **[问题陈述]** 草稿 §5 的校验表写「`ChapterScope` 含重复值 → `PushWarning`，**去重后继续**」。
  ✗ 若「去重」= 就地改写 `EnemyData` 上的数组，即在加载期**写回共享只读单例**，与既有的「模板是共享只读单例，本服务不得写回它」「`Get()` 只读、绝不把解析结果写回条目」（`common-properties.md` 的 `LocalizedText` 一条）同族纪律相抵。
  ✗ 且重复值对 `Contains(currentChapter)` 的结果**无任何影响**，去重在功能上是空操作。
  - 选项 (a) **只告警，不改条目**（措辞改为「`PushWarning`，取池不受影响」）→ 后果：纪律干净，校验是纯只读。
  - 选项 (b) 保留「去重」，并写明去重发生在**校验的局部副本**上、不写回 → 后果：措辞更啰嗦，收益为零。
  - **推荐 (a)**。

### 🟠-3 `Finale` 一行的空池校验可能拦下正当内容

- **[问题陈述]** 草稿 §4 论证「三章各需至少一条 `Finale` 敌人…… 两维校验顺手把『ch2 忘了写天劫』这个洞也堵上」。
  ✗ 但该校验枚举的是**通用池**（`PoolScope == null`）。天劫是篇章边界的高度定制内容，把它写成某条 Story / Chapter arc 的**专属条目**（`PoolScope.PlotArcId` 非空）是完全正当、甚至更自然的编排——那样 `(Finale, ch)` 的通用池为空，启动期直接 `PushError` 拦下正当内容。
  ✗ 另：既有文本明写「**Finale 不掷骰**（天劫是**指派**）」，而「指派」的机制在本库**未定义**（不知它是否走取池链）。草稿的「它仍须存在于池中才能被指派到」是一句**推测**，不是可引权威。
  - 选项 (a) **`Finale` 那一行放宽为「该 `(Finale, chapter)` 下的池（含专属条目）非空」** → 后果：既堵住「ch2 忘写天劫」，又不误伤专属编排；代价是该行与其余两行口径不同，须写明理由。
  - 选项 (b) **保持三行同口径**（通用池非空），并明写「天劫条目一律走通用池 + `ChapterScope` 收窄，不用 `PoolScope`」→ 后果：口径整齐；代价是把一条内容编排约束硬塞进校验，且与「`PoolScope` 是剧情线表达差异化的唯一合法途径」形成张力（「大限将至」线上的 Finale 就没法专属了）。
  - 选项 (c) **`Finale` 行本次不改**（仍单维），只把 Practice / Standard 扩到两维，把天劫的校验留作待答 → 后果：最保守，但草稿宣称的「顺手堵上 ch2 漏天劫」这一条收益作废。
  - **推荐 (a)**。

### 🟠-4 「空 `ChapterScope` + 图鉴文案含境界词 ⇒ 列进评审清单」这条软告警是否入库、以什么形态入库

- **[问题陈述]** 草稿 §2 提出一条人工审阅级告警，判据是「图鉴文案里出现境界词（筑基 / 金丹 / 元婴）」。
  ✗ 图鉴五项词条的类型是 **`LocalizedText`**（`systems/common-properties.md:193` 明写挂载面含 `EnemyData` 的描述 / 风味文案）。按中文境界词做子串扫描，**在任何非中文语言下都失效**，且中文侧也会误命中（「他自幼向往金丹之境」）。这条规则的可执行性远弱于草稿并列的既有先例（`EncounterScopes` × arc 可达类型无交集，那是纯结构判定）。
  - 选项 (a) **不入库**，只在 handoff 的 Open questions 里留一句「跨篇章叙事一致性目前无机械手段，靠内容评审」→ 后果：不制造一条写下来就没人能执行的规则。
  - 选项 (b) **入库但改判据**：改为纯结构判定（例：`ChapterScope` 为空的条目在 `content/enemy/` 类型档案的评审清单里逐条过一遍），不做文案扫描 → 后果：可执行，落点在尚未开张的类型档案。
  - 选项 (c) 按草稿原样入库（文案子串扫描）→ 后果：与 `LocalizedText` 的多语言形态相抵，且会被后来者当成「待实现的校验」。
  - **推荐 (b)**，其次 (a)。

### 🟠-5 `content/_index.md` 本次改不改

- **[问题陈述]** 草稿 `targets:` 列了 `content/_index.md`「敌人类型开张时的字段核对清单」。
  ✗ 但 `content/enemy/` **尚未开张**（`content/_index.md:43` 登记表里 `enemy` 一行的「已开张」列为 `✗`），字段核对清单归尚未存在的 `content/enemy/_index.md`；`content/_index.md` 本身只有登记表 + 依赖链，没有逐字段清单可填。
  ✗ 且 `Context.md` 的硬边界：`content/` **绝不复述字段的类型 / 取值域 / 枚举 / 校验语义**——把 `ChapterScope` 的 `1..3` 与 `PushError` 语义写进 `content/*` 即制造第二权威。
  - 选项 (a) **本次不改 `content/_index.md`**，把「开张时字段核对清单须含 `ChapterScope`（回链 `systems/enemies/common-properties.md`）」写进 handoff 的 Notes 与报告，交给日后的 `/scaffold-content-type enemy` → 后果：零违规、零漂移面。
  - 选项 (b) 在 `content/_index.md` 的 `enemy` 行备注里加一句「开张时须含 `ChapterScope`」→ 后果：一句轻描述不算复述语义，但它是一条会过期的施工提示放在登记表里。
  - **推荐 (a)**。

## 🔵 可推演

- **`currentChapter` 是单值 `int`，取自 `CharacterProfile.chapter`。** 依据：`decisions/ADR-0004` 与 `systems/character-profile/*` 的字段 5（`chapter : int`，1–3）；与 `activeArcIds` 取集合的对照理由（Story / Chapter 各恒一条 + 至多 `MaxConcurrentSideArcs` 条 side arc）在 `systems/enemies/_index.md:76` 已明写。草稿这一段是逐字推演，无新增。
- **三层过滤全部叠在 `AllEnabled()` 之后**，不改既有过滤顺序纪律。依据：`.claude/rules/data-resource-rules.md`「抽取一律经 `AllEnabled()`」+ `systems/enemies/_index.md:51`。
- **`ChapterScope` 空 = 不限，与 `EncounterScopes` 空 = `PushError` 的不对称是有意的**，且理由可由既有文本推出（空数组下 `Contains` 恒假 ⇒ 死条目；`Length == 0 ||` 恒真 ⇒ 范围偏宽）。这条不对称**必须在活文档里写明理由**，否则日后必被当成漏写而"修正"。
- **不设「长度必须 < 3」检查**：显式 `[1,2,3]` 与留空语义相同且是正当写法。可推演，无争议。
- **无存档迁移。** `ChapterScope` 是内容侧字段，存档只记 `EnemyId` / `EnemyInstance`（`EnemyInstance` 七字段中无篇章格），`PastEventEntry.EnemyTraceRef` 只有 `EnemyId` + `Level`。依据：`systems/enemies/_index.md:33-39`、`systems/adventure-event/common-properties.md:239`。
- **`terminology.md` 不需要改。** `ChapterScope` 是字段名不是领域词汇；「篇章 / chapter」已在库中。
- **不评估 derive 就绪度**（技能第 10 步）——本报告与 Phase B 均不给就绪度结论。

## 拟改动文档清单（供跨草稿核对）

**本分片独占（无其他分片声明）：**

- `systems/enemies/_index.md`：
  ① `EnemyData` 字段表（第 14–24 行的表）**新增一行 `ChapterScope`**，紧邻 `EncounterScopes` 之下；
  ② 取池伪码（第 50–56 行）把 `// ③ 篇章框定照旧` 这句悬空注释**替换为实际的一行 `.Where`**，入参补 `currentChapter`；
  ③ 「地域 / arc 专属条目是叠加不是替代」那一条**追加一句**：篇章框定同构（空 = 三章都进池，专章条目只在自己那章加项）；
  ④ 「待决问题」**删除第 4 条**（`敌人池的篇章框定载体未定`，第 112 行整条）；
  ⑤ 若 🔴-2 取 (a)：字段表 `EncounterScopes` 行的类型与取值域改为 `combatTier`/`{ Practice, Standard, Finale }`，伪码 `spec.EventType` → `spec.Tier`，「决策(-> ADR)」第 2 条同改；
  ⑥ `Source:` 行不动（本次不新增 `##` 小节）；写完跑技能 6b 的两条 grep 自查。
- `systems/enemies/common-properties.md`：
  ① 「敌人专有的共有字段」表（第 15–23 行）**新增 `ChapterScope` 一行**（形态 `int[]` 取值 `1..3`；缺失时：空数组合法 / 越界 `PushError` 带 `Id` + 越界值 / 重复值按 🟠-2 的裁决措辞）；
  ② 小节标题「**`PoolScope` 的加载期校验（四条…）**」需**改名**——新增的两条属 `ChapterScope` 不属 `PoolScope`（建议「取池相关字段的加载期校验（六条）」），表内新增两行；
  ③ **改写第四条**为 `(EventType|combatTier × 篇章)` 两维，通用池定义按 🔴-3 的裁决、`Finale` 行按 🟠-3 的裁决；
  ④ 删除第 36 行「第四条只按 `EventType` 单维枚举……（见 `_index.md` 待决问题）」整条说明，替换为两维的理由（枚举面封闭且极小 3×3=9）；
  ⑤ 「人工审阅级（不硬校验）」按 🟠-4 的裁决决定是否追加一条；
  ⑥ 「待决问题」**删除第 2 条**（`敌人池的篇章框定载体`，第 55 行）。
- `answer-logs/log-enemy-pool-chapter-scoping.md`（worker 独占新建；台账行 `answer-logs/_index.md` 交回 orchestrator）。
- `handoffs/2026-08-22-enemy-pool-chapter-scoping.md`（worker 独占新建，`status: distilled`）。
- `inbox/solution-draft-enemy-pool-chapter-scoping.md`：front matter 改 `status: distilled` + 补 `reviewed:` / `distilled-to:`，随后 `git mv` 进 `inbox/archive/`（台账行交回 orchestrator）。

**⚠ 与 `future-event-generation-weighting` 分片重叠 —— 需 orchestrator 分区或串行：**

- `systems/services/future-event-service.md`：**本分片只动敌人物化那一段**，具体三处：
  ① 第 98 行「输入：`EnemyData`（经 `AllEnabled()` 取池，按 `PoolScope` / location / 全部 `Active` arc / **篇章** / eventType 框定）」——把「篇章」由词落成 `ChapterScope` 并回链；
  ② 第 104 行「① 框定 + 选模板 ← `PoolScope`…… + **篇章** + eventType 框定」同上，并补 `currentChapter` 单值入参的说明；
  ③ 第 127 行「抽取时按 `EncounterScopes` + `PoolScope` + **篇章框定**叠加」——把「篇章框定」补成 `ChapterScope`。
  **对方分片动的是第 12–36 行（location 框定 / Travel 段）、第 53–94 行（物化模型 / 批次规模）、第 156–193 行（闸 ①②③）与「待决问题」小节**，与上述三处不重叠，但**同文件并行写必然互相覆盖 ⇒ 必须串行**。另：`Source:` 行与「待决问题」小节两侧都可能碰（本分片不动「待决问题」；对方要删「生成 / 加权规则未定」那条）。
- `systems/adventure-event/common-properties.md`：**本分片默认不写**（按 🔴-1 推荐项）。若 orchestrator 选 🔴-1 的 (b)，本分片需在「共有属性 / 字段」小节新增一条 `ChapterScope` 条目（该文件**没有 `AdventureEventData` 字段总表**，只能以条目式行文承载，紧邻 `eventType` 那一条之后最自然）。对方分片已声明该文件为 target。
- `systems/adventure-event/combat/_index.md`：**仅当 🔴-2 取 (a)** 才需要动（第 31 / 152 行的 `[Practice]` / `[Standard]` 表述本就正确，需核对是否要同步补一句 `ChapterScope`）。**不在本分片原 targets 内**，需 orchestrator 授权或交回作承接项。
- `content/_index.md`：**按 🟠-5 推荐项不改**。草稿的 `targets:` 列了它，此处显式标注为「不改」以免跨分片核对时被当成漏写。

## 待移出的 open-questions 条目

（worker 不写，交 orchestrator 代笔）

- `open-questions/01-combat.md` 第 31 行整条：**「敌人池的篇章框定载体未定（08-17 新增 · 承重）」** → 本次答定，移出并记入 `answer-logs/log-enemy-pool-chapter-scoping.md`。
- **不移出**：同分片第 33 行「敌人是否也以功法构筑卡组」（草稿明写与本条正交，未答）。
- **本分片不动** `open-questions/02-event-options.md` 的「生成 / 加权规则与叠加顺序」——它归 `future-event-generation-weighting` 分片。
- 待答清单**新增**（因 🔵 中的 `[采纳推荐 — 待复核]`）：`ChapterScope` 字段命名与 `PlotArcData.ChapterScope` 同名是否会造成跨类型混淆 —— 落 `open-questions/01-combat.md`（`[采纳推荐 — 待复核]`，技能第 4.5 步要求同时留在待答清单）。
- `open-questions/update-log.md` 与 `answer-logs/_index.md` 台账行随 Phase B 报告交回。

## 越界发现

1. **样本卡组规模两处矛盾（本分片目标文档内，但不属本草稿范围）。** `systems/enemies/_index.md:19` 写「样本卡组…… **规模逐条编排、不设硬限**，允许同名条目重复」；`systems/enemies/common-properties.md:18` 写「样本卡组 | `CardData.Id` 序列，**规模 15**，允许同名重复」。同一对象两处不同结论 —— 一处是「不设硬限」，一处给了定值。`open-questions/01-combat.md:34` 另有「卡组规模的实际取值（08-11c 重定）—— 规则层两侧均**不设硬限**」在办。本分片**不顺手改**（不在本次改动触及的小节，且改哪一侧是设计裁决）。建议 orchestrator 作为独立一条提请用户，或留待 ch1 数值标杆专场。
2. **🔴-2 的类型不一致波及 `systems/architecture.md:590`**（把 `EncounterScopes` 列为「`.tres` 引用图」类纪律的例子）——若采纳订正，该行的措辞不受影响（只提字段名），**无需改动**，此处仅作已核对的备案。
3. `systems/adventure-event/combat/_index.md:152` 的三档遭遇参数初值（`Practice` 8 / `Standard` 10 / `Finale` 12）与 `future-event-service.md:108` 的「⑤ 遭遇参数 ← eventType（Combat 10 回合……）」在**参数名**上同样是 `eventType` 与 `combatTier` 混用。归 🔴-2 的同一根因，处置随该题裁决。
