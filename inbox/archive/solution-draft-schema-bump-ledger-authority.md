---
type: solution-draft
date: 2026-09-03
question: 存档 schema bump 的登记权威在哪里、谁在什么时点登记、漏登如何被机制发现？（**客户端那一半**：清单的唯一权威落点与形态、全部表外登记的补齐、11 处自称改回链的做法与顺序、客户端侧可执行的护栏）
source: open-questions/05-service-contracts.md → 「`systems/character-profile/_index.md` 的 11 处 schema bump 自称改为回链（09-02 新增）」
counterpart: backend-design-documents/inbox/solution-draft-schema-bump-ledger-authority.md
targets: systems/services/sync-service.md · systems/character-profile/_index.md · systems/services/profile-service.md · systems/services/combat-service.md · decisions/ADR-0122 · ADR-0126 · ADR-0127 · ADR-0128 · ADR-0132 · systems/architecture.md（阶梯的第二个实例）· open-questions/cross-boundary.md
status: distilled
reviewed: 2026-09-03 · 用户评审定案三项（授权改写四份 ADR 措辞并给 `ADR-0127` 补第 ⑤ 步 · 形状护栏取 golden JSON 快照文件 · 现在就拆出 `systems/services/profile-schema-versions.md`，全部回链一次性写对不经中转）；2026-09-03 合并 interview 追加裁决三项（统计层区分「引入顶层键」与「键内追加」· 删除类只描述形状不进 v1 行 · 后端矩阵本批即登 `schemaVersion = 1`）+ 标准默认一项（新文档在 `services/_index.md` 以一句说明登记，不用 `⊃` 记法）。**落笔时核实出改动面远大于草稿所列**：就地自称实为 24 处 + 5 份 ADR，v1 行补齐 27 条。
distilled-to: handoffs/2026-09-03-schema-bump-ledger-authority.md
---

# 方案草稿 — 存档 schema bump 的登记（客户端半：权威落点、补齐、回链与护栏）

## 问题

`systems/services/sync-service.md`「### 存档 schema 版本」小节 :334 自称：

> **bump 清单只有上表一份**——列面与字段面的每一项都登记在这里；别处提到「增列 ⇒ bump」指的都是**这同一次**。

**这句话今天是假的，而且假得比 09-02 登记时以为的更彻底。**

- **上表（:324–336 的五行表）之外，同一份 `sync-service.md` 里就另有四处独立 bump 断言**（:55 禁用表 + 统计层 · :320 `entitlement` · :321 `PlayerPowerFragment` 两格 · :322 `rng` / 两个 `contentVersion` / `activeCombat` / `PastEventEntry`）。**自称「只有一份」的那句话，连它自己所在的文件都不成立。**
- **`systems/character-profile/_index.md` 有 11 处**「随本次落定 bump schema 版本」（:160 · :188 · :222 · :225 · :230 · :252 · :280 · :293 · :306 · :327 · :328），逐条核对全部准确。
- **至少八类已定案的存档结构改动完全没有出现在上表里**（详见下方「具体形态」的补齐清单），其中包括 `immortalJade` / `spiritStone`、`plotKeyPoint`、`Status` 的 `FaithBand` / `BloodlustBand` / `CurrentLocationId` / `LocationEventCount`、`EventOption` 的 `DestinationLocationId` 与 barter 格、Exchange 三格、`pastItemUse` 与 `ProfileChangeSpec` 的三个新列、`activeCombat` 内的两格。
- **`profile-service.md` :233 与 `combat-service.md` :304 也各自宣称「与上表那一次合并」**——被指向的表里没有它们的行。

### 病因（这是本方案要修的东西，不是把清单补一遍就完）

**上表是「一次 bump 的内容清单」，却被当成「所有 bump 的登记簿」使用。** 它的开头写着「下列改动**合并为同一次 bump**」——它的形态天生是**一次**的，而 :334 那句自称把它宣布成了**永久唯一**的。两者不匹配，于是每一次新的落笔都面临一个没有答案的问题：「我这一格该加进哪一行？」，而最省事的答案是**就地写一句「随本次落定 bump」**——那正是 11 处 + 八类表外断言的产生方式。

**ADR-0128 把这个失效演示得最完整。** 它 :44 免除自己的 bump 义务，论证是「两个 `Status` 字段此前已随 location 载体落定并 bump 过 · `EventOption` 快照多一格随『完整物化字段清单』那次 bump 一并处理」。这个论证**形式上有效**（它说的是「不另起第二次」，与 :334 逐字一致），但它依赖的两个前提「**已经有人记了**」在权威表里**都是假的**——location 那两格只记在 `character-profile/_index.md`:306，`EventOption` 行只写了 `OutcomeSpec` / `Encounter` 两格。**一个建立在「别人已登记」之上的免责，在没有人真的登记时会静默失效。**

### 一处真正的设计缺口（不只是登记问题）

**ADR-0127（`Status` 25 → 22 格，删 `lifeTotal` / `LifeSpanBand` / `ChapterLifeSpanBudget`）通篇没有提 bump**，全文唯一的迁移表述是「后端零影响 · 迁移成本为零」。而 `systems/architecture.md` 的「删除一个资源 element 恰好五步」第 ⑤ 步逐字写着「**bump 存档 schema 版本（老档丢弃该格）**」。

⇒ **删字段的老档处置口径今天在全库没有落点。** 当前无线上存档使代价为零，但这正是它最便宜的修复时机（与「就在此刻把 MigrationManager 骨架立起来」同一条判断）。

## 约束（来自既有设计）

1. **`schemaVersion` 不是 `PlayerProfile` 的字段**，落点是三处信封（`SyncEnvelope` / `ProfilePayload` / `ProfileSnapshot`）——`sync-service.md`「JSON 序列化命名策略」。
2. **C# 字段名 ↔ JSON path 由 camelCase 策略机械对应**，故重命名任一透明段字段 = 破坏性契约变更（同上）。
3. **纪律的可执行化四级阶梯 + 两条选级判据**（`systems/architecture.md`）：**「能上线且线上不可见 → 必须做到第 1 或第 2 级」**；「只在开发期显形且会累积 → 第 3 级足够」。
4. **通用补注：检查对象不在 C# 类型系统作用域内的纪律，其第 1 / 2 级等价物 = 把同一份校验放进打包 / 发布管线，不通过即不产包**（同上）。
5. **共有属性的分层判据**：定义在最小公共祖先、投影在各落点；**投影只写落点 / 本层合法子集 / 本层消费点 / 回链，不得复述定义**（`systems/common-properties.md` · `answer-logs/log-common-properties-layering.md`）。
6. **活文档只保留最新设计，不留考古**；一切皆可改，包括 ADR（根约定 `.claude/rules/Context.md`）。
7. **当前无线上存档 ⇒ 一切迁移为空迁移**；且「拆成多次只会让迁移器多几级空跳」（`sync-service.md` :324 / :334）。
8. **顺序约束已登记**：「须与该清单补齐漏项**同批**做——先改回链会把一处可见的重复登记换成一处指向不全清单的错误指向，后者更难被下一次对账发现」（`open-questions/05-service-contracts.md`）。
9. **跨边界承接分片的形态已定**（`open-questions/cross-boundary.md`）：四段式、只回链、`/analyze-new-ideas` 跨库落笔时同批写两侧。
10. **索引不该长回台账**（`decisions/ADR-0005`），且 `*_index.md` 已挂体积告警钩子。

## 建议方案

### 1. 把「一次的内容清单」改成「逐版本的登记表」，并把自称改到与形态一致

`[既有推演]`（病因 + 约束 7）

建议 `sync-service.md`「### 存档 schema 版本」小节整体改写为一张 **`schemaVersion` 登记表**，**一行一个版本号**：

| `schemaVersion` | 本版纳入的结构改动 | 老档处置口径 | 触碰透明 / 回声路径？ | 权威回链 |
|---|---|---|---|---|
| **1**（首发） | （补齐后的全量清单，见下方「具体形态」） | 空迁移（当前无线上存档） | 见该列逐条标注 | 各字段所在文档 |

三点形态纪律：

- **「本版纳入的结构改动」列只写对象 + 字段名 + 一句话，不复述类型 / 取值域 / 校验语义**——那些的权威在字段所在文档（约束 5）。这与 `content/` 的硬边界是同一条纪律。
- **自称改为与形态一致：** :334 那句「bump 清单只有上表一份」→ 改为「**每一次 bump 在本表各占一行；某次改动属于哪一版，以本表为准。别处一律回链本表，不得就地宣布 bump**」。**旧措辞之所以失效，正因为它承诺的是一张它形态上给不了的东西。**
- **首发前的一切改动全部归入 `schemaVersion = 1`，不拆成多版**（约束 7 直接给出：拆开只会让迁移器多几级空跳，而这些版本永远不会有真实存档）。⇒ 补齐工作是**往同一行里补条目**，不产生任何新的 bump。

### 2. 登记时点 = 与设计落笔同批（变更内原子），登记人 = 写下该次改动的那一个

`[既有推演]`（后端 `contracts/_index.md` 已成文的同款判据）+ `[通行做法]`

- **判据：任何改动 `PlayerProfile` / `CharacterProfile` 及其可达对象序列化形态的设计落笔，未登记进 `schemaVersion` 登记表即视为未完成。**
- **不设周期性对账。** 理由取自后端已成文的同款论证：周期性对账允许漂移窗口存在，而那个窗口正是两侧按不同真值编码的时期。**本次的四批 + 八类漏登恰好证明了「日后统一整理」不会发生。**
- **登记人 = 写下该次设计改动的那一次运行 / 那个人**，不是「日后由谁来收拾」。四批漏登的形成方式全部是同一种：落笔时把 bump 一句写在 ADR 或字段所在文档里，**等于就地登记在了第二本账上**。

### 3. 护栏：把「漏 bump」从第 4 级抬到第 2 级

`[既有推演]`（约束 3 + 4）

先套选级判据：**漏 bump 能不能上线？能。线上可不可见？不可见。**

- 结构改了而版本号没改 ⇒ 后端与旧客户端都以为是同一个 schema，**没有任何一侧会报错**；症状是复算悄悄退化、迁移器悄悄跳过。
- 反过来，改了版本号而后端矩阵没登记 ⇒ 客户端只出一条**非模态**提示 + 暂停重试（`sync-service.md`「`Upgrade` 类错误在非闸门点」），玩家可能整个会话都不明确感知。

⇒ **按判据必须做到第 1 或第 2 级，第 3 级不够。** 而检查对象是**序列化形状**（不是 C# 类型系统能表达的东西），故取约束 4 的等价物：

> **`ProfileShapeCheck`：由 `PlayerProfile` 递归导出序列化形状（JSON path + 类型，排序后规范化），与 `SchemaVersion` 常量旁写死的期望值比对。不一致 ⇒ 校验失败。**
>
> - **落地在打包 / 发布管线，不通过即不产包**（第 2 级等价物），并在 `#if DEBUG` 启动期跑同一份校验（第 3 级，开发期即刻显形）。**一份实现、两个触发点**，与「同一个 `LoadAll()` 路径喂给发布侧」同构。
> - **登记表每行同时记下该版本的期望形状值**。于是「文档没登记」与「代码没 bump」**收敛成同一个可机检的事实** —— 这是本方案里唯一能让漏登被机制发现的部件，其余各条都只是纪律。
> - 形状的具体载体（指纹 hash vs 快照文件）见「仍需用户决定 ①」。

- **实测前置：** `game-feature-branch/` 当前**尚无 `.csproj`**（已登记于 `open-questions/05-service-contracts.md`）。本护栏的落地宜与那两条既有实测项（`#if DEBUG` 判据 · `Control` 自动翻译默认行为）**同批**，不单独排期。**设计形态不依赖实测结果。**
- **第 3 级留一条廉价旁证：** 「凡 `sync-service.md` 之外出现『bump schema 版本』字样 ⇒ 必须是回链形态」可作为 `/sync-knowledge` 的一条 grep 断言。它抓的是**文档漂移**（护栏抓的是代码漂移），两者不重叠。

### 4. 11 处自称 + 八类表外断言的改法与顺序

`[既有推演]`（约束 5 + 8）

**顺序（不重开，照已登记的判断执行）：** 先补齐登记表（第 5 节），再改回链。中间不留窗口——**先改回链会把一处可见的重复登记换成一处指向不全清单的错误指向，后者更难被下一次对账发现。**

**改法（固定句式，一句话）：**

> 本字段属 `schemaVersion` 1，登记见 `systems/services/sync-service.md`「`schemaVersion` 登记表」。

**两条边界：**

- **老档默认值口径留在字段所在处，不搬进登记表。** 它是字段语义的一部分（「缺字段 → 空列表 / `0` / `null`」直接由该字段的类型与语义决定），按约束 5 应定义在最小公共祖先 = 字段本身；登记表只投影「哪一版纳入了它」+ 回链。搬进登记表会让登记表变成第二份字段规格，正是本方案要消灭的东西。
- **删字段是例外，其处置口径必须进登记表**（见第 6 节）——因为字段已经不在了，没有「字段所在处」可以承载它。

**改动面（11 处之外还有五类，一并处理，否则同型问题原样存活）：**

| 文档 | 处 | 处理 |
|---|---|---|
| `systems/character-profile/_index.md` | 11 处（:160 :188 :222 :225 :230 :252 :280 :293 :306 :327 :328） | 改回链 |
| `systems/services/sync-service.md` | 4 处表外断言（:55 :320 :321 :322） | **并入登记表行**，原处删除 |
| `systems/services/profile-service.md` | :233 | 改回链 |
| `systems/services/combat-service.md` | :304 | 改回链（并把 `amount` / `itemId` 两格补进登记表） |
| `decisions/` | ADR-0122:23 · ADR-0126:41 · ADR-0128:44 · ADR-0132:41 | 改回链（ADR 可自由改写，见约束 6） |

**`systems/architecture.md` :486 / :496 的「五步」第 ④ / ⑤ 步不改措辞，只把「bump」一词改为「**在登记表新增 / 追加一行**」**——那两条是**流程**（讲怎么做），不是**自称**（讲某次做过了），性质不同，不该一并回链掉。

### 5. 补齐清单（全部并入 `schemaVersion = 1` 那一行）

`[既有推演]`

按核实结果，登记表 v1 行须补入下列各项（对象 / 字段 / 一句话，逐条回链其权威文档）：

| # | 对象 | 补入项 | 权威 |
|---|---|---|---|
| 1 | `CharacterProfile` | `pastItemUse : ItemUseEntry[]` | ADR-0122 · `character-profile/_index.md` |
| 2 | `ProfileChangeSpec` | `ItemElements` · `ItemUseElements` 两列 | ADR-0122 · `profile-service.md` |
| 3 | `ProfileChangeSpec` | **`StatusChanges` 列**（上表已点名六列，唯独漏它） | ADR-0128 |
| 4 | `Status` | **删** `lifeTotal` · `LifeSpanBand` · `ChapterLifeSpanBudget` 三格（25 → 22） | ADR-0127 |
| 5 | `Status` | `FaithBand` · `BloodlustBand`（`sbyte`） | `character-profile/_index.md`:293 |
| 6 | `Status` | `CurrentLocationId` · `LocationEventCount` | `character-profile/_index.md`:306 |
| 7 | `CharacterProfile` | `spiritStone` · `immortalJade`（`int`，顶层） | `character-profile/_index.md`:160 |
| 8 | `CharacterProfile` | `plotKeyPoint : PlotKeyPoint[]` | `character-profile/_index.md`:327 |
| 9 | `CharacterProfile` | `disabledAbility` · `PlayerProfile.statistics` | `sync-service.md`:55（表外 → 并入） |
| 10 | `PlayerProfile` | `entitlement`（2 字段）· `PlayerPowerFragment` 增 `LastRoll` / `LastEffectiveChance` | `sync-service.md`:320–321（表外 → 并入） |
| 11 | `CharacterProfile` | `rng` · `startContentVersion` · `lastContentVersion` · `activeCombat` · `pastEvent` 条目结构 | `sync-service.md`:322（表外 → 并入） |
| 12 | `EventOption` | `DestinationLocationId`（七格 → 八格） | ADR-0128 |
| 13 | `EventOption` | barter 格 | ADR-0126 |
| 14 | `EventOptionSave` | `ExchangeStock` · `BarterStock` · `RerolledCount` 三格 | `character-profile/_index.md`:222 |
| 15 | `ActiveCombat` | 栈条目 `itemId` **与战场条目 `amount`**（**两格，不是一格**） | ADR-0132 · `combat-service.md`:306 |

> **⚠ 派单摘要称漏登「四批」；核实后实为上列十五项中的大部分**，且 `sync-service.md` 自身的四处表外断言也在其中。**建议按本表全量补齐**，只补四批会让同型问题原样存活。

**同批修一处残留失真：** `character-profile/_index.md`:281 的小标题仍写「隐藏属性档位与篇章寿元预算（**四个字段**）」，而其下代码块在 ADR-0127 之后只剩 `FaithBand` / `BloodlustBand` **两格**。

### 6. 补上「删字段」的老档处置口径

`[既有推演]`（architecture.md 五步流程第 ⑤ 步已有答案，只是没有落点）

登记表的「老档处置口径」列对**删除**类改动写明：**老档中该格原样丢弃，不迁移、不告警**（当前无线上存档 ⇒ 空迁移）。同时建议在 ADR-0127 补一句回链（它今天连「合并进同一次 bump」都没说，是四批里唯一完全失联的一批）。

### 7. 跨边界的那一半：在 `open-questions/cross-boundary.md` 立一条常规触发源

`[既有推演]`（约束 9）

后端把 bump 的登记权威指回本库（`backend-design-documents/contracts/profile-sync.md`:187 / :189），而后端矩阵的 `schemaVersion` 集合写着「待客户端清单补齐」⇒ **两侧都以为对方在记**。

建议在本库 `open-questions/cross-boundary.md` 的说明区补一句：**「本库登记表新增一行（= 一次 bump 定案）是本分片的一类常规触发源」**，并按既定四段式在**对侧**库开承接条目。责任划分（开条目归发起方 = 恒为客户端 · 落笔矩阵归后端）与后端侧的告警护栏见 counterpart，**本库一字不复述**。

## 具体形态（可 derive 的落地面）

**① `sync-service.md`「### 存档 schema 版本」整节重写**：登记表（五列，形态见第 1 节）+ v1 行的十五项补齐清单 + 三条形态纪律 + 登记时点判据（第 2 节）+ 护栏一段（第 3 节）。**表外的四处 bump 断言（:55 :320 :321 :322）原处删除、内容并入表行。**

**② 固定回链句式**（第 4 节）批量替换 11 + 2 处；ADR 四份各改一句。

**③ `ProfileShapeCheck` 的形态**（第 3 节）：一份实现、两个触发点（打包管线 + `#if DEBUG` 启动期）；期望值与 `SchemaVersion` 常量同处，并在登记表每行留一列。**具体载体见「仍需用户决定 ①」。**

**④ `systems/architecture.md`**：把「纪律的可执行化」通用补注下新增本护栏为**第二个实例**（第一个是内容 `.tres` 引用图的发布管线校验）——两者是同一条「客户端侧天花板是第 3 级 ⇒ 移到发布管线取得第 2 级」的应用。

**⑤ `open-questions/cross-boundary.md`** 说明区补一句常规触发源（第 7 节）。

## 后果

- **不产生任何新的 bump。** 全部补齐并入 `schemaVersion = 1`，当前无线上存档 ⇒ 空迁移，**迁移器不多一级空跳**。
- **报文形态零改动、后端零配合**（补齐的十五项全部落不透明段或已在既有白名单内；本次不移动、不重命名任何透明路径）。
- **`sync-service.md` 会变长**（登记表 + 十五项清单），需评估是否触发文档粒度问题 → 「仍需用户决定 ②」。
- **`character-profile/_index.md` 变短**（11 处多行断言 → 11 句回链）。
- **新增一条工程义务**：打包 / 发布管线多一个校验步骤。它与已定案的「内容包发布侧校验闸」共用同一条管线，**不新增管线**。
- **对 `/derive-requirements` 的影响**：登记表成为存档 / 迁移相关 FR 的单一输入面；护栏本身是一条可 derive 的工程需求（形态已具体到可写验收标准）。

## 备选方案（已考虑并否决）

- **只补四批、不改表的形态** — 病因是「一次的清单被当永久登记簿」，不改形态则下一次落笔仍会就地写「随本次落定 bump」，同型问题必然复发。且核实表明漏登远不止四批。
- **把 11 处的 bump 自称保留、只在 `sync-service.md` 加一句「另见各字段文档」** — 制造两本账并公开承认它，正是本项目反复否决的「第二权威」形态。
- **先改 11 处回链、再补清单** — 已被 `open-questions/05-service-contracts.md` 明确否决：会把一处**可见**的重复登记换成一处**指向不全清单**的错误指向。
- **把老档默认值口径全部收进登记表** — 违反「定义在最小公共祖先」判据，把登记表变成第二份字段规格。（删除类改动是例外，见第 6 节。）
- **首发前的改动拆成多个 `schemaVersion`（v1…v8）保留设计历史** — `sync-service.md` 已两次否决（「拆成多次只会让迁移器多几级空跳」），且这些版本永远不会有真实存档；历史归 git（根约定）。
- **护栏只做第 3 级（`#if DEBUG` 启动期断言）** — 直接撞选级判据：漏 bump **能上线且线上不可见**，判据明写「第 3 级不够」。
- **靠 `/audit-*` 之类的周期性对账发现漏登** — 允许漂移窗口存在；且本次的十五项漏登本身就是「日后统一整理不会发生」的证据。
- **让后端探测客户端 schema 变化** — 违反三段可见性分界与 pillar #1；且后端拿不到「应有形状」这个参照物。

## 与既有决策的张力

**两处，均建议按「改写既有措辞」处理，不需要松动任何决策本身。**

**① `sync-service.md`:334 的「bump 清单只有上表一份」。** 本方案直接改写它。**这不是松动一条决策，而是让措辞与它自己的形态一致**——它承诺的是一张永久登记簿，而上表形态上是一次的内容清单。改写方向与该句的**意图**完全一致（收敛到一处），只是把「一处」做成真的。

**② ADR-0128:44「存档 schema 不额外 bump」。** 本方案**不推翻这个结论**（它说的是「不另起第二次」，与收敛意图一致），但要指出：**它的免责论证依赖两个在权威表里为假的前提**（location 两格与 `EventOption` 那一格「已经有人记了」）。建议处置 = 补齐登记表后，把 ADR-0128 那句改为回链登记表 v1 行——届时前提**变成真的**，论证与结论都成立，**一个字的实质决定都没被推翻**。

> → 已裁决（2026-09-03 · 批量评审）：**授权改写四份 ADR 的措辞**（`ADR-0122` / `ADR-0126` / `ADR-0128` / `ADR-0132` 的就地 bump 断言改为回链登记表），**并授权给 `ADR-0127` 补上漏执行的「删除一个资源 element 恰好五步」第 ⑤ 步**（删字段的老档处置口径）。三者均**不推翻任何实质决定**，只使措辞与权威表一致。

> **附带指出（不构成张力，但值得评审注意）：** ADR-0127 未执行 `architecture.md`「删除一个资源 element 恰好五步」的第 ⑤ 步。当前无线上存档使代价为零，但**这是一条既有流程被漏执行**，而不是流程有误——修法即第 6 节。

## 前置依赖

- **counterpart（后端半）是成对前置。** 本方案第 7 节产出的承接条目要落在后端库，而后端矩阵的 `schemaVersion` 集合形态、登记触发点、未知版本的告警护栏在 counterpart 定义。**本方案第 1、2、4、5、6 节不依赖对侧，可独立采纳；第 7 节须与 counterpart 的第 1、2 节同时采纳——单侧采纳即「两侧都以为对方在记」原样存活。**
- **第 3 节护栏的落地时点依赖 `.csproj` 首次生成**（`open-questions/05-service-contracts.md` 的既有实测项）。**设计形态不依赖它**，只是实现排期上宜与那两条实测同批。
- **无其它待答项阻塞。** 本方案不裁决任何字段语义、不改任何数值、不动任何契约报文。

## 仍需用户决定

**两条。**

### ① 形状护栏的载体：**指纹（hash）** 还是 **golden 快照文件**？

- **选项 A · 形状指纹。** 递归导出 JSON path + 类型，规范化后算一个短 hash，写死在 `SchemaVersion` 常量旁与登记表每行。
  - **后果：** 仓库里只多一个字符串，零维护体积、零 churn。代价是失败时只告诉你「形状变了」，**不告诉你变在哪** —— 开发者得自己 diff 出来。
- **选项 B · golden JSON 快照文件。** 把一份"空 `PlayerProfile`"的序列化结果签入仓库，校验 = 与它逐字比对。
  - **后果：** 失败时 `git diff` 直接指出是哪个 path 变了，排障成本最低。代价是仓库里多一份会随每次改动而变的中等体积文件，且它**逼近"第二份字段规格"的边界** —— 虽然它是机器生成物、不承载语义，但读者可能把它当规格来读。
- **选项 C · 两者都要**（hash 进登记表作登记凭据，golden 文件作排障辅助）。成本 = A + B，收益不叠加多少。
- **推荐 B，理由：** 本护栏的**全部价值在于它失败的那一刻**，而那一刻的诉求正是"哪儿变了"。项目已有的同类实践偏向可读产物而非不透明摘要（`contracts/vectors/splitmix64.json` 就是签入仓库的机器可读对照物，且明写"对不上以该文件为准、不得单方面改表迁就实现"）。"第二权威"的顾虑可用一行文件头注释关掉（"本文件由 `ProfileShapeCheck` 生成，**不是规格**；规格见各字段文档"）。
  **若倾向把仓库保持干净，选 A 也完全成立** —— 护栏的**判定能力两者完全相同**，差别只在排障体验。

→ 已裁决（2026-09-03 · 批量评审）：**取选项 B —— golden JSON 快照文件**。落笔时须带上文件头注释（「本文件由 `ProfileShapeCheck` 生成，**不是规格**；规格见各字段文档」），把「第二权威」顾虑关掉。

### ② `schemaVersion` 登记表放在 `sync-service.md` 内，还是独立成一份文档？

- **选项 A · 留在 `sync-service.md`「### 存档 schema 版本」。** 与今天一致，**零结构改动**。
  - **后果：** 该文件今天已 377 行，登记表是**逐版增长**的（每次 bump +1 行 + 若干条目）。若干版之后，一份服务设计文档里会有一张越长越大的台账 —— 这正是 `ADR-0005`「索引不该长回台账」告诫的形态（虽然它针对的是 `*_index.md`）。
- **选项 B · 拆出 `systems/services/profile-schema-versions.md`（或 `systems/character-profile/schema-versions.md`），`sync-service.md` 留一句回链。**
  - **后果：** 服务文档保持"讲服务怎么工作"，台账单独生长、可独立套体积告警。代价是多一次跳转，且要决定它挂在 `services/` 下（sync-service 持有 `MigrationManager`）还是 `character-profile/` 下（结构的主体在那里）——**这个归属本身也需要一个答案**。
- **推荐 A（现在），并给一条明确的迁出触发条件：** 首发前只有 v1 一行，拆出去是为一个尚未发生的增长付结构成本，与本库"不为尚无实例的纪律先行造工具"那条判断同向（`sync-service.md` 透明路径纪律就是这么办的，且它同时留了触发条件）。**触发条件建议：登记表达到第 3 个版本行，或该节超过 `sync-service.md` 篇幅的三分之一时迁出**，届时归属取 `services/`（迁移器在那儿）。
  **若你倾向现在就拆**，理由也充分 —— 本方案正在把它从"一次的清单"改造成"永久台账"，**性质变更的时刻正是重新选落点的自然时机**，晚拆要多改一遍全部回链。

→ 已裁决（2026-09-03 · 批量评审）：**取选项 B —— 现在就拆出独立文档**。归属**取 `systems/services/profile-schema-versions.md`**（`MigrationManager` 在 `services/` 下，本草稿在 A 的迁出条件里已给出同一判据，故归属不另作取向）；`sync-service.md`「### 存档 schema 版本」小节留一句回链。**第 4 节的固定回链句式与第 5 节的补齐清单随之改指向新文档**，全部回链一次性写对，不经 `sync-service.md` 中转。

> 其余子项（登记表的列构成 · 全部并入 v1 不拆版 · 补齐顺序先清单后回链 · 老档默认值留字段处而删除类进表 · 护栏必须做到第 2 级 · 回链固定句式 · 五步流程措辞不回链掉）均由既有决策或既有判据直接推演得出，**不列为取向**，按本文建议直接落笔即可。
