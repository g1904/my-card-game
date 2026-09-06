---
type: solution-draft
date: 2026-09-05
question: `sync-service.md` 的 schema bump 清单漏至少四批、且与 `character-profile/_index.md` 的第二处 bump 断言互斥，而后端把 bump 权威指回客户端 ⇒ 两侧都以为对方在记
source: open-questions.md → 「本次新识别的台账 / 投影缺口」第一条（🟠）；连带 `open-questions.md` 第 90 / 151① / 159#7 三处同源标注
targets: `systems/services/profile-schema-versions.md`（主要）· `decisions/ADR-0127-life-merged-into-lifespan.md`（一处计数）· `open-questions.md`（条目处置，归 `/analyze-new-ideas` / `/summarize-open-questions`）
status: distilled
reviewed: 2026-09-05 · 批量评审 —— ① 过期条目改写而非关闭，但改写后移入 `open-questions/05-service-contracts.md`、`open-questions.md` 的 `## derive 就绪度` 小节一字不碰（推翻草稿「撤销第 90 / 151 / 159 三处标注」的写法）；② 草稿断言「对侧无残留错指」不成立，后端 `open-questions.md` 两处失效陈述本次一并删除；③ `ADR-0127` 两处计数直接订正、登记表 #12 删计数改回链、立形态纪律 ⑥。另按标准默认采纳 11 项，其中覆盖空缺由 7 处修正为 11 处
distilled-to: handoffs/2026-09-05-schema-ledger-v1-coverage.md
---

# 方案草稿 — schema bump 登记表：漏批已补齐，残留的是登记表自身的覆盖空缺

## 问题

问题条目（2026-08-30 由 `/assess-derive-readiness` 写下）陈述的是三件事：

1. `sync-service.md` 内那张 bump 清单自陈「只有一份」，却零处出现四批改动（`pastItemUse` / `ItemElements` / `ItemUseElements`（`ADR-0122`）· `StatusChanges` 列（`ADR-0128`）· `Status` 删 `lifeTotal` / `LifeSpanBand` / `ChapterLifeSpanBudget`（`ADR-0127`）· 栈条目 `itemId`（`ADR-0132`））；
2. `character-profile/_index.md:160` 存在第二处 bump 自称，与「清单只有一份」互斥；
3. 后端 `contracts/profile-sync.md` 把 bump 权威指回客户端 ⇒ 两侧都以为对方在记。

**核实结论：三件事在 2026-09-03 已被 `handoffs/2026-09-03-schema-bump-ledger-authority.md`（及其后端 counterpart）整段答结，本问题条目自那天起即已过期。** 逐条核过：

| 条目断言 | 当前实况 | 证据 |
|---|---|---|
| 清单在 `sync-service.md` 内、自陈唯一 | 清单已拆出为独立文档 `systems/services/profile-schema-versions.md`；`sync-service.md:321` 只留一句「权威落点在该表，别处一律回链、不得就地宣布 bump」 | `sync-service.md:56` · `:321` |
| 漏 `pastItemUse` / `ItemElements` / `ItemUseElements` | 已登记 | v1 行 #8 · #22 |
| 漏 `StatusChanges` 列 | 已登记 | v1 行 #22 |
| 漏 `Status` 删三格 | **有意不登记**，由形态纪律 ④「首发前删除的字段不进任何版本行」承接 | 形态纪律 ④ · `ADR-0127:50` |
| 漏栈条目 `itemId` | 已登记 | v1 行 #27 |
| `character-profile/_index.md:160` 第二断言 | 已改为回链固定句式；该文件内 11 处自称**全部**改完，全库 24 处 + 5 份 ADR 同批 | `_index.md:160` · `:188` · `:222` · `:225` · `:230` · `:252` · `:280` · `:293` · `:306` · `:327` · `:328`；`ADR-0021` / `0122` / `0126` / `0128` / `0132` |
| 后端把权威指回客户端 | 后端已改指 `profile-schema-versions.md`，且 `operations/_index.md` 与 `open-questions/cross-boundary.md` 均以「登记表新增一行」为触发点 | `backend-design-documents/contracts/profile-sync.md:190` · `contracts/envelope.md:257` · `operations/_index.md:42` |

**所以本草稿的实质内容不是「补四批」，而是：**（a）请求把这条过期条目按事实收口；（b）报告在核实过程中发现的**新登记表自身的三类残留**——它们与原问题同源（同一条「漏登不可见」的失效模式），且**同样是 derive 第 7 步落笔前该看一眼的**。

## 约束（来自既有设计）

- **登记表是唯一权威，别处一律回链。** —— `systems/services/profile-schema-versions.md` 形态纪律 ②；`sync-service.md:321`。
- **本表的语义是「每一版的形状」，判据是与 `ProfileShapeCheck` 的 golden 快照严格同构、逐行对得上。** —— 同上，形态纪律 ①。**这条把「表内每一格都必须能对上一个序列化字段」变成了硬要求**，也是下面三类残留全部成立的判据。
- **首发前一切改动归 `schemaVersion = 1`，补齐不产生任何新的 bump。** —— 同上，v1 说明；`handoffs/2026-09-03-schema-bump-ledger-authority.md` ③。
- **登记时点 = 写下该次设计改动的那一次落笔，不设周期性对账。** —— 同上，「登记时点与责任人」。
- **漏 bump 能上线且线上不可见 ⇒ 按「纪律的可执行化」必须做到第 1 或第 2 级。** —— `systems/architecture.md`；护栏形态已定为 `ProfileShapeCheck` + golden JSON 快照，落地时点绑定在既有实测项那一批（`open-questions/05-service-contracts.md`）。
- **计数不进承重表述。** 本库已有两条同款先例：`ProfileChangeSpec`「列表数不进承重表述——它随字段族增长，把数字写死等于每加一列就要改一次这条纪律」（`profile-service.md:37`）· 「一律用不带计数的措辞指代全部 Codex 顶层键」（`sync-service.md:310`）。
- **本表只写对象 + 字段名 + 一句话，不复述类型 / 取值域 / 校验语义。** —— 同上，v1 清单尾注。

## 建议方案

### 子项 1 —— v1 行的首发形状清单存在 7 处覆盖空缺，建议直接补齐

`[既有推演]`

把 v1 清单（27 条）与两层 Profile 的字段表逐格对位后，下列顶层字段**在登记表中零处出现**。按形态纪律 ①（「与 golden 快照逐行对得上」），它们一格不落地都会在 golden 文件里出现、却在表里找不到对应行——那正是本表要消除的那种不一致。

`CharacterProfile`（字段表 25 行，`systems/character-profile/_index.md:116–142`）：

| 缺登字段 | 类型 | 权威 | 备注 |
|---|---|---|---|
| `status` | `CycleStatus` | `decisions/ADR-0004-realm-checkpoint-retry-model.md` | 轮回状态机的落档格，`defeatReason` 的可空性判据即它 |
| `chapter` | `int`（1–3） | 同上 | |
| `realm` | `Realm` | `systems/game-progression.md` | 与 `level` 合成全局等级序，是敌人赋级的判据 |
| `level` | `int`（境界内层号） | 同上 | |

`PlayerProfile`（字段表 16 行，`systems/player-profile/_index.md:13–28`）：

| 缺登字段 | 类型 | 权威 | 备注 |
|---|---|---|---|
| `characterProfile` | `IReadOnlyList<CharacterProfile>` | `systems/character-profile/_index.md` | 两层聚合的容器键本身；它是 diff 的寻址面，形状上确实是一个顶层键 |
| `accountInfo` 的其余 4 格 | `AccountInfo`（5 字段） | `systems/player-profile/account-info.md` | 表内 #17 **只登记了 `AccountSeed` 一格**；`accountInfo` 是**受回声约束的两个顶层键之一**，按形态纪律 ⑤ 第三档「受回声校验约束的顶层键内追加字段 ⇒ 进版本行」，它的每一格都该在表内 |
| `achievement` | `IReadOnlyList<Achievement>` | `systems/player-profile/achievement/_index.md` | **不是漏登、是前置未决**——`Achievement` 条目 schema 仍在 `profile-service.md` 的 `## 待决问题` 里，见「前置依赖」 |

**建议落笔形态**（拟追加至 v1 清单，编号接 #27）：

| # | 对象 | 纳入的结构 | 权威 |
|---|---|---|---|
| 28 | `CharacterProfile` | `status : CycleStatus` · `chapter : int` | `decisions/ADR-0004-realm-checkpoint-retry-model.md` |
| 29 | `CharacterProfile` | `realm : Realm` · `level : int` | `systems/game-progression.md` |
| 30 | `PlayerProfile` | `characterProfile : CharacterProfile[]`（两层聚合的容器顶层键） | `systems/character-profile/_index.md` |
| 31 | `PlayerProfile` | `AccountInfo` 其余四格（`Nickname` · `CreatedAtUtc` · `Identities` · 见权威列）——与 #17 的 `AccountSeed` 合为该受回声约束顶层键的完整形状 | `systems/player-profile/account-info.md` |

- **`achievement` 不在本次追加内**，理由见「前置依赖」；建议在 v1 清单尾注加一句「`achievement` 的条目结构待 `Achievement` schema 答定后补入本行，届时仍属 `schemaVersion` 1、不产生新 bump」，使这处空缺**有承载**而不是继续不可见。
- **`AccountInfo` 的四格逐字字段名以权威列所指文档为准**，本表照形态纪律只写字段名 + 一句话，不复述类型与校验。上表第 31 行的括号内容以 `account-info.md` 现行字段面为准回填。
- 本次全部落在 v1 行内 ⇒ **不产生任何新的 bump、不触发后端兼容矩阵登记**（矩阵的触发点是「登记表新增**一行版本**」，不是 v1 行内补条目——见 `backend-design-documents/operations/_index.md:42`）。

### 子项 2 —— v1 行 #12 的「22 格」是一处不可核对的计数，建议删掉计数改回链

`[既有推演]`

v1 行 #12 写「`CharacterProfile.Status` 首发形状 **22 格**」，`ADR-0127:19` 写「`Status` 25 → 22 格」、`:50` 复述「22 格、不含这三格」。但**全库唯一一份 `Status` 字段枚举只有 9 行**（`systems/character-profile/_index.md:146–156`：`manaLimit` · `experiencePoint` · `faith` · `bloodlust` · `lifeSpan` · `FaithBand` · `BloodlustBand` · `CurrentLocationId` · `LocationEventCount`），且这 9 格与两张封闭表**双向满射**——`ResourceElements` 全表 15 行中属 `Status` 的恰是前五格（`profile-service.md:265` 明写），`StatusFields` 覆盖 `StatusKey` 全部成员即其余四格。

- 25 恰是 `CharacterProfile` **字段表的行数**（当前 25 行，且未因 `ADR-0127` 减 3）。「25 → 22」很可能是把 `CharacterProfile` 的行数误当成 `Status` 的格数写下的，此后被登记表原样继承。
- **无论 22 从何而来，它现在是一格无法核对的数**：形态纪律 ① 要求本表与 golden 快照逐行对得上，而没有任何文档能推出 22。护栏一旦落地，这一行会**必然对不上**——它会成为 `ProfileShapeCheck` 的第一条假阳性，而假阳性正是护栏最容易被关掉的死法。

**建议：**

- **v1 行 #12 的「本版纳入的结构改动」列删掉计数**，改为不带数的措辞 + 回链：
  > `Status` 子类的首发形状（逐格见 `systems/character-profile/_index.md` 的 `CharacterProfile.Status` 子表），**不含** `currentMana`（战斗内运行态，落 `activeCombat`）。
- **`ADR-0127` 的两处计数同批订正**：`:19` 的「`Status` 25 → 22 格」改为「`Status` 删 `lifeTotal` / `LifeSpanBand` / `ChapterLifeSpanBudget` 三格」（结论一字不改、只去掉两个不可核对的数）；`:50` 的「22 格、不含这三格」改为「不含这三格」。ADR 的**决定与理由零改动**，改的只是一处计数表述。
- **不是只修这一处：建议把「本表不写任何计数」立为形态纪律的第 ⑥ 条。** 依据是本库已有的两条同款先例（`ProfileChangeSpec` 列表数不进承重表述 · 全部 Codex 顶层键用不带计数的措辞），而本表比那两处更需要它——它是**唯一登记面**，一处计数漂移会同时误导两侧。拟措辞：

  > **⑥ 本表不写任何计数（格数 / 条数 / 行数）。** 计数是随字段族增长的第二真值，且与形态纪律 ① 的可机检判据相抵——golden 快照能逐行对，对不了一个数。指代一组字段一律用不带计数的措辞 + 指向字段表的回链，与 `ProfileChangeSpec` 的「列表数不进承重表述」及 Codex 顶层键的「不带计数的措辞」同一条。

### 子项 3 —— 防再漏的机制：现状已在阶梯第 2 级，建议不加码，只补一条零成本的第 3 级旁证

`[既有推演]`

问题条目问的「防再漏机制」在 09-03 已给出并选级完毕：`ProfileShapeCheck` + golden JSON 快照，**打包管线不通过不产包（第 2 级等价物）+ `#if DEBUG` 启动期（第 3 级）**，选级理由（漏 bump 能上线且线上不可见 ⇒ 第 3 级不够）已明写。本草稿**不建议改动这个形态**。

但本次核实暴露了一件既有护栏**抓不到**的事：**上面 7 处空缺与那个「22 格」，`ProfileShapeCheck` 一条都抓不到——因为它比对的是「代码形状 ↔ golden 文件」，而漏的是「golden 文件 ↔ 登记表文本」那一段。** 护栏收敛的是「文档没登记」与「代码没 bump」这两件事的**版本号维度**（每行记下该版 golden 文件名），不是**条目维度**。

**建议补一条零成本的第 3 级旁证**（沿用 09-03 已给的同一手法——那里已有一条 `/sync-knowledge` 的 grep 断言）：

> **`/sync-knowledge` 增一条对账项：v1 清单的条目集合，与两层 Profile 字段表（`systems/character-profile/_index.md` · `systems/player-profile/_index.md`）的行集合双向核对；任一侧有而另一侧无 ⇒ 报一条不一致。**

- 它与既有那条 grep 断言（「凡本表之外出现『bump schema 版本』字样 ⇒ 必须是回链或三类非自称形态」）**互补不重叠**：那条抓「别处又自己宣布了一次」，这条抓「本表少了一格」。
- **判据上它只配得上第 3 级，且这是正确的**：条目漏登的后果不是静默上线（golden 快照仍会带上那个字段、`ProfileShapeCheck` 仍会通过），而是**文档面的误导**——迁移器作者照表写会漏格。它属「能上线、开发期可发现」，第 3 级足够。**不建议为它另造工具或抬到管线闸**，那会与 09-03「不为一条尚无实例的纪律先行造工具」的同款克制相抵。
- **不建议引入周期性对账**——形态纪律已明确否决（「周期性对账允许漂移窗口存在」）。上面这条是**跟着 `/sync-knowledge` 走的机会性对账**，不是排期的巡检，两者不同。

### 子项 4 —— 过期问题条目的处置

`[通行做法]`

`open-questions.md` 现有**四处**同源标注仍按 08-30 的事实陈述：第 63/65 行的 🟠 条目本体 · 第 90 行 `sync-service.md` 就绪度行的「⚠ derive 前置」· 第 151 行「落笔前的零决策修正 ①」· 第 159 行第 7 步的「落笔前须先补齐本文件的 schema bump 清单」。**四处都已不成立**（清单已拆出、已补齐、两侧回链方向已修正）。

处置本身**不在本技能的写入面内**（`open-questions*` 归 `/analyze-new-ideas` / `/summarize-open-questions`），故此处只给建议形态，见「仍需用户决定」①。

## 具体形态（可 derive 的落地面）

**A. `systems/services/profile-schema-versions.md`**

1. v1 清单追加四行（子项 1 的 #28–#31 表）。
2. v1 清单尾注追加一句 `achievement` 的占位说明。
3. v1 行 #12 的结构列删计数、改回链措辞（子项 2）。
4. 「形态纪律」追加第 ⑥ 条（子项 2 拟措辞）。
5. `ProfileShapeCheck` 一节追加一句：本护栏比对的是代码形状 ↔ golden 文件；**「登记表条目 ↔ 字段表行」的对账由 `/sync-knowledge` 的一条断言承担**（子项 3）。

**B. `decisions/ADR-0127-life-merged-into-lifespan.md`** —— `:19` 与 `:50` 两处计数订正（结论零改动）。

**C. `open-questions.md`** —— 四处标注的处置，形态待用户裁决（见「仍需用户决定」①）。**本草稿不写该文件。**

**存档 / 同步面影响：**

- **零 bump、零迁移。** 全部落在 `schemaVersion = 1` 行内，首发形状本就包含这些格；补齐的是登记文本，不是形状。
- **对后端零义务。** 后端兼容矩阵的触发点是登记表**新增一行版本**（`backend-design-documents/operations/_index.md:42` · `open-questions/cross-boundary.md:11`），v1 行内补条目不构成触发；且本次不触碰任何透明路径与回声路径的 path 本身（`accountInfo` 四格是**补登记**，不是移动 / 重命名 / 追加）。
- **golden 文件不受影响。** `profile-shape-v1.json` 尚待建，本次改动不改变它未来的内容——只让登记表能与它对上。

## 后果

- `systems/services/profile-schema-versions.md` 的 v1 行由 27 条增至 31 条 + 一条占位说明；形态纪律由五条增至六条。
- `decisions/ADR-0127` 两处计数订正（Accepted 状态不变、决定与理由不变）。
- `/sync-knowledge` 的对账项 +1，`.claude/` 侧无须改动规则文件（该技能本就以「对账 `.claude` 投影面与两个事实来源」为职责，本条是它扫描设计库时的一项）。
- **不影响 `sync-service.md` 的 derive 就绪度判定**——它本就 ready，`## 待决问题` 只剩 `pushId` 后端记忆窗口；本草稿采纳后，第 90 / 151 / 159 三处「derive 前置」标注可一并撤掉，第 7 步自此零前置。

## 备选方案（已考虑并否决）

- **照原问题条目字面「把四批补进 `sync-service.md` 的 bump 清单」** — 否决：那张表已不存在，`sync-service.md:321` 现在只留一句回链。照字面执行会在被明确拆走的位置**重建第二本账**，正是 09-03 拆分要消除的形态。
- **把 `Status` 的「22 格」按 9 格订正** — 否决：仍是一个会随字段增长漂移的数，且与本库两条「计数不进承重表述」先例相抵。删计数改回链才是既有做法。
- **把「登记表 ↔ 字段表双向核对」抬到打包管线闸（第 2 级）** — 否决：它是文档面对账，管线读不到设计库；且漏条目不构成静默上线，选级判据不支持第 2 级。
- **给登记表设季度 / 每 N 次落笔的周期性对账** — 否决：形态纪律「不设周期性对账」已明确排除，理由是它允许漂移窗口存在。
- **把 `achievement` 先按推测形状登记进 v1** — 否决：`Achievement` 条目 schema 仍待答，登一个推测形状 = 在唯一权威面上写一个会被推翻的形状，比空着更危险。改为留一句有承载的占位。
- **为本次补齐另起一次 bump（v2）** — 否决：首发前一切归 v1 是已定纪律，另起一版只会让迁移器多一级空跳、并向后端矩阵推一个假的版本号。

## 与既有决策的张力

**一处，轻。** `ADR-0127` 是 Accepted 状态，子项 2 建议改动它 `:19` / `:50` 的两处计数表述。

- **松动的是什么：** 仅计数措辞，**决定（生命合并进寿元）、理由链、备选与后果全部一字不动**；改后 `:19` 仍如实陈述「删三格」这一结构收缩。
- **为什么需要它：** 该计数是登记表 v1 行 #12 那个 22 的来源；只改登记表而留着 ADR 里的 22，下一次对账会把登记表的回链措辞判成「漏了 ADR 已给出的信息」而改回去。
- **不松动时的替代：** 只改登记表、ADR 原样保留，并在 ADR 那两处各加一句「本数为历史表述，逐格以字段表为准」。**不推荐**——那是在一份 Accepted ADR 上留一处已知不准的数加一句免责，比直接订正更难维护，且与本库「活文档只保留最新设计、直接重写替换」的根约定相抵（该约定明写 ADR 也可直接改）。

- → **已裁决（2026-09-05 · 批量评审）：直接订正 `ADR-0127` 的 `:19` / `:50` 两处计数**，同时删登记表 v1 #12 的计数改回链，并立形态纪律 ⑥「本表不写任何计数」。只动计数措辞，决定 / 理由链 / 备选 / 后果一字不变；上述「不松动时的替代」不采纳。

**除此之外无张力。** 全部建议均在既有纪律内，未与任何 ADR 的结论相抵。

## 前置依赖

1. **`Achievement` 条目 schema**（`systems/services/profile-service.md` 的 `## 待决问题` 第四条：「`Achievement` 条目 schema 与各账号级条目触发」）。→ `PlayerProfile.achievement` 那一行**在它答定前无法定稿**，故本方案只为它留占位说明，不写形状。其余六处空缺与「22 格」订正**不依赖它**，可独立采纳。
2. **`accountInfo` 其余四格的逐字字段名**以 `systems/player-profile/account-info.md` 现行字段面为准回填；若该文件的字段面在本草稿评审期间变动，第 31 行随之对齐。这是回填动作，不是待答项。
3. **对侧库不需要配套草稿。** 判断依据三条：① 本次全部落在 `schemaVersion = 1` 行内、**不新增版本行**，而后端的承接触发点恰是「登记表新增一行」（`backend-design-documents/operations/_index.md:42` · `open-questions/cross-boundary.md:11`）⇒ 不触发；② 权威指向的两侧修正已在 09-03 成对完成（`contracts/profile-sync.md:190` · `contracts/envelope.md:257` 均已改指 `profile-schema-versions.md`），无残留错指；③ 本次不移动 / 不重命名 / 不向受回声约束顶层键**追加**任何 path——`accountInfo` 四格是补登记既有格，不是形状变更 ⇒ 不落「两侧同批落笔」那一档。故按跨库纪律的归属判据，本问题**当前整个归客户端库**。

## 仍需用户决定

1. **过期问题条目的处置路径（流程取向）。** `open-questions.md` 的四处同源标注（第 63/65 条目本体 · 第 90 就绪度行 · 第 151 零决策修正 ① · 第 159 第 7 步前置）已全部不成立，但本次核实出的 7 处覆盖空缺与「22 格」与它同源。
   - **选项 A（推荐）：改写而非关闭。** 把 🟠 条目就地改写为「四批漏登已于 09-03 补齐；残留 = 登记表 v1 行的 7 处覆盖空缺 + 一处不可核对计数」，级别降为 🔵，同时撤掉第 90 / 151 / 159 三处「derive 前置」标注（那三处讲的是**已消失**的前提）。**后果：** 问题的余量有承载、不会在本草稿被采纳前后凭空消失；代价是清单上多留一条低级别项到本草稿落笔为止。
   - **选项 B：直接关闭进 answer-log。** 按 09-03 已答结收口，7 处空缺另开一条新待答项。**后果：** 台账更干净，但「新开一条」这一步若没发生，本次核实的发现即刻蒸发——而那正是本问题原本的失效模式（跨步骤的第二半经常不会发生）。
   - **选项 C：不动清单，等本草稿经 `/analyze-new-ideas` 落笔时一并处置。** **后果：** 期间任何一次 derive 都会读到「须先补齐 bump 清单」这条已失效的前置并据此停下。
   - **推荐 A**，理由：它是三者中唯一不依赖「后续某一步一定会发生」的路径，与本问题的根因同向。
   - **无论选哪一项，写入动作都不属本技能**（`open-questions*` 的写入者是 `/analyze-new-ideas` / `/summarize-open-questions`）。
   - → **已裁决（2026-09-05 · 批量评审）：选项 A —— 改写而非关闭**（🟠 改写为「四批已补齐；残留 = v1 行 7 处覆盖空缺 + 一处不可核对计数」，降 🔵，并撤销第 90 / 151 / 159 三处已失效的 derive 前置标注）。

2. **`ProfileShapeCheck` 是否因本次发现而提前单独落地（排期取向）。** 09-03 已定「宜与那批既有实测项同批落地，不单独排期；设计形态不依赖实测结果」。本次发现「登记表在纯人工维护下 3 天内即出现 7 处空缺」，可被读作提前落地的证据。
   - **选项 A（推荐）：维持既定，不单独排期。** 依据：本次 7 处空缺 `ProfileShapeCheck` **一条也抓不到**（它比对代码形状 ↔ golden 文件，漏的是登记表文本那一段）⇒ 提前落地它并不能防住本次这类问题，真正对位的是子项 3 那条 `/sync-knowledge` 断言（零成本、可立即生效）。**后果：** 排期不动，护栏仍在 `game-feature-branch/` 有 `.csproj` 后随实测项落地。
   - **选项 B：提前单独落地。** **后果：** 客户端分支尚无 `.csproj`，落地要先起构建面；且如上，它防不住本次这类问题——付出排期换一个不对症的护栏。
   - **推荐 A。**
   - → **已裁决（2026-09-05 · 批量评审）：选项 A —— 维持 09-03 既定排期，不单独提前落地。** 该项经批量编排判定为「可由既有推演得出」（备选不对症：`ProfileShapeCheck` 比对代码形状 ↔ golden 文件，本次 7 处空缺是文档面漏登，一条也抓不到），按标准默认采纳，未单独出题。
