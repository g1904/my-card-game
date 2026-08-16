---
type: solution-draft
date: 2026-08-13
question: 共有属性提炼粒度——哪些字段应下沉到子树各自的 common-properties.md、哪些留在顶层
source: open-questions/05-service-contracts.md → 共有属性提炼粒度（同条目亦在 systems/common-properties.md 的「## 待决问题」）
targets: systems/common-properties.md、systems/_index.md（结构约定一句话）、systems/player-profile/player-power/common-properties.md、systems/character-profile/power/common-properties.md、systems/character-profile/item/common-properties.md
status: distilled
decided: 2026-08-13（用户裁定两项取向：顶层分两大节 · `SourceCode` 投影段现在压回模板）
reviewed: 2026-08-13 用户评审 —— 两项取向均取推荐项 (a)；其余部分未提异议，按草稿原文提炼。2026-08-14 `/analyze-new-ideas` interview 追加一项：草稿写「三份 `SourceCode` 投影段」实为四份（漏 `player-profile/player-item/`），裁定四份一并压回模板。
distilled-to: handoffs/2026-08-14-common-properties-layering.md
---

# 方案草稿 — 共有属性提炼粒度（common-properties 的分层判据）

## 问题

`systems/` 是类模型化结构：每一层都可以有一份 `common-properties.md`（顶层一份、`adventure-event/` 中间层一份、九个子类型各一份、`enemies/` 一份、`character-profile/` 与 `player-profile/` 的各叶子子树各一份）。原始意图是「共有属性显式化——每一层的共有字段抽到 `common-properties.md`」（`handoffs/2026-07-24-docs-restructure-class-model.md`），但**没有留下「一个字段属于哪一层」的判据**。

它悬着的后果不是理论上的：顶层 `systems/common-properties.md` 已长到 238 行，其中既有全库工程约定（`Id` / 命名 / RNG / 存档 / null / 日志 / 服务协作 / API 总则），也有具体的内容共有字段权威定义（`ContentEnabled` · `LocalizedText` · `Rarity` · `SourceCode`+`Source` · `ExclusiveSource`）；而 `SourceCode` 同时在三份叶子 `common-properties.md` 里各写了一段。**没有判据就无法回答「这段是必要的投影还是重复的第二权威」**，也无法回答「中间层 `character-profile/` 与 `player-profile/` 缺的那两份要不要补」。

原条目自己写的是「边界待随子树填充而细化」。本草稿的主张是：**要定的不是一张字段归属表，而是一条可反复套用的判据**——字段清单会一直增长（多份子树文档的「待定的字段清单」仍是 `⟨待定⟩`），判据不会。

## 约束（来自既有设计）

- **活文档只保留最新设计，`.claude/knowledge/*` 是薄引用层，本库是唯一权威。** 同一条设计有两处「定义级」表述即产生第二权威，是漂移源。Source: `decisions/ADR-0005-knowledge-thin-reference-layer.md`、`README.md`。
- **类模型化结构：复杂类型下沉为文件夹（`_index.md` + `common-properties.md`），简单主题保持单 `.md`。** 「只有在确有真实设计意图时才新增系统文档 / 文件夹」是 `systems/_index.md` 的明文收尾约定。
- **已有一个成型的分层范例可直接归纳：`SourceCode`（08-12b）。** 枚举清单、`(Kind, Scope)` 分域校验表、「入口严 / 读档宽」、置换继承等**不变式全在顶层**；`player-power` / `power` / `item` 三份叶子文档各写**本层合法取值列 + 本层有无规则消费点 + 回链顶层**。这不是随手写成的，它是「分域差异由校验表承载、不由类型系统承载」那条决策在文档结构上的同一投影。
- **`Rarity` 与 `Tier` 的教训（08-10c）：同名不同义不得合并。** 任何「把两处同名字段上提为一条共有字段」的动作，必须先过语义同一性检查。
- **文档结构不对称是既有的、有理由的事实：** `player-profile/_index.md` 已明文定案「`player-item/` / `player-power/` / `achievement/` / `codex/` 各成文件夹；`account-info.md` / `game-setting.md` 结构轻，各为独立 markdown」——**建不建文件按内容量与子结构决定，不按对称决定**。本草稿的建档判据只是把这条已定的取舍推广到 `common-properties.md` 这一层。

## 建议方案

### 一、主判据：**定义在最小公共祖先，投影在各落点**

`[既有推演]`

一个共有属性在文档树上有两种出现形态，权限不同：

| 形态 | 写什么 | 允许出现在几层 |
|---|---|---|
| **定义（权威）** | 类型 / 枚举清单 / 取值域 / 不变式 / 校验语义 / 与其他字段的关系 | **恰好一层**：它全部挂载面的**最小公共祖先** |
| **投影（引用）** | 本层落在哪个类上、本层的合法子集、本层的消费点、回链 | 每个实际落点各一份，**可以有多份** |

**「最小公共祖先」按挂载面算，不按「感觉有多通用」算。** 例：`ExclusiveSource` 只覆盖 `PowerData` / `ItemData` 两个类，但这两个类的落点横跨 `character-profile/` 与 `player-profile/` 两棵子树 ⇒ 最小公共祖先是 `systems/` 顶层 ⇒ 定义留顶层。

**它是既有实践的归纳，不是新规。** `SourceCode` 已经完全按这个形状写成；本条只是把它从「一次巧合的写法」升为「下一个共有字段照抄的模板」。

**推论（承重，也是这条判据唯一的硬边界）：同一个字段的「定义级内容」在两份 `common-properties.md` 中同时出现即为违规。** 投影段里出现枚举成员表、code 数值、校验语义的完整复述，都算把权威复制了一份——它们会各自漂移，而本库没有任何机制能发现两份表不一致。

### 二、投影段的固定格式（四项 + 回链）

`[既有推演]`

投影段只答四个问题，**建议控制在 5 行以内**：

1. **落点** —— 本层落在哪个类上（内容定义 `XxxData` / 持有条目 / 集合字段）；
2. **本层的合法子集或默认值** —— 若顶层定义了分域取值表，此处只抄**本层那一列**；
3. **本层的消费点** —— 有则点名，**无则明写「本层无规则消费点」**（这条信息量很大，见 `character-profile/power/common-properties.md` 与 `item/common-properties.md` 已写下的那句）；
4. **回链** —— 「枚举清单 / 校验表 / 不变式见 `systems/common-properties.md`」。

**为什么必须明写「本层无消费点」而不是省略：** 省略与「还没想」不可区分。已经写下这句的两份文档因此是可信的；没写的地方读者只能去顶层重读一遍再自己推断。

### 三、上移 / 下沉的触发器

`[通行做法]`（面向对象重构里的 pull-up field / push-down field，判据在文档树上同样成立）

- **上移**：**同一字段在 ≥2 个兄弟节点出现，且语义同一** ⇒ 定义上移到它们的最小公共祖先，原处降为投影段。**「语义同一」是硬前置**——同名不同义（`RarityTier` vs `Tier`）不上移，且不得为了上移而给两个不同概念改成同一个名字。
- **下沉**：**顶层某条只被单一子树消费** ⇒ 下沉到该子树，顶层不留摘要（活文档不留考古）。
- **只有一个落点的字段不进任何 `common-properties.md`**，留在该类自己的 `_index.md` 里——`common-properties` 的语义是「共有」，一个落点的字段写进去会让读者误以为还有别的落点。

**按此核对，当前顶层的五个共有字段一条都不需要下沉**（核对表见下）。这不是巧合：它们能被写进顶层，正是因为当初每一条都是在第二个落点出现时才被抽上去的。

### 四、中间层要不要补 `common-properties.md`：按内容建，不按对称建

`[既有推演]`

现状：`adventure-event/` 有中间层 `common-properties.md`（213 行），`character-profile/` 与 `player-profile/` 没有。**建议维持现状，并写明判据**，而不是为对称补两份空壳。

**建档判据（两条同时成立才建）：**
1. 该层存在**其子节点共有、且不适用于全库**的属性或机制（不然它属顶层）；
2. 这批内容的**篇幅已压过 `_index.md` 的索引职责**（经验界：约 40 行以上，或超过该层 `_index.md` 的一半）。

按此逐层核对：

- `adventure-event/` —— `selectCost` / `eventPriority` / 物化 / `pastEvent` schema 全是九类共有且全库不适用，篇幅 213 行 ⇒ **两条都成立，该建，已建**。
- `enemies/` —— `EnemyData` 的共有字段表 + 加载期校验，45 行 ⇒ **成立，已建**。
- `character-profile/` —— 该层真正的横切共性是「轮回级生命周期：随 `defeated` / `completed` 清理」，一两句话，且已写在 `_index.md` 与 `power/common-properties.md` 里 ⇒ **不建**。
- `player-profile/` —— 该层横切是「账号级持久 + 严格 / 宽松两层同步口径」，已在 `_index.md` 内成节 ⇒ **不建**。

**推论：结构不对称不是缺陷，是判据的正确产物。** 这句建议写进 `systems/_index.md` 的收尾约定，否则日后必然有人（或一次 `/update-readme`）以「补齐结构」为由建出两份空壳文件，而空壳 `common-properties.md` 的代价是实打实的：它会成为一个看起来该写点什么的坑，把本属顶层的字段吸下来复述一遍。

### 五、顶层 `systems/common-properties.md` 内部分两大节（已裁定 · 2026-08-13）

`[取向选择 → 已定]`

顶层文件重排为两大节，**纯重排、不改一个字的语义**：

- **`## 通用约定`** —— 稳定 `Id` · 字段命名与类型一致性 · 数据即资源 · seeded RNG 派生 · 存档版本化与原子写入 · null / 结果校验 · 日志约定 · 服务协作约定 · API 契约总则 · 物化模型 · 与 `.claude` 的主从关系。
- **`## 内容共有字段`** —— `ContentEnabled` · `LocalizedText` · `Rarity: RarityTier` · `SourceCode` + `Source` 枚举 · `ExclusiveSource: Source?`。

**判据卡（见「具体形态」）落在 `## 内容共有字段` 节首，不落文件顶部**——判据只对本节成立，`## 通用约定` 那批条目不谈「挂载面」，也不产生投影段。这正是分节的目的：让判据的适用范围一眼可见，新字段有明确的落笔位置。

**`## 决策(-> ADR)` / `## 待决问题` / `## 对应` 三节位置与内容不变**，仍在文件尾部。

### 六、三份 `SourceCode` 投影段现在压回模板（已裁定 · 2026-08-13）

`[取向选择 → 已定]`

趁只有三处时做，它同时是本判据的第一个执行样例。逐份的压缩面：

| 文件 | 保留 | 删除（权威在顶层） |
|---|---|---|
| `player-profile/player-power/common-properties.md` | 落点（持有条目，非 `PowerData`）· 本层合法取值 `FinaleWin` / `PremiumBundle` / `AchievementReward` + 读档兜底 `Unknown` · 本层消费点 = 残卷的 `x`（唯一规则消费点）· 回链 | 「唯一消费点」的完整论证（不对玩家可见 / 不进图鉴 / 不参与其他判定）· **置换继承来源**及其防刷论证 · `CombatReward` / `InitialGrant` / `EventOutcome` / `ExchangePurchase` 各自为何不合法的逐条理由（合法子集表本身已在顶层） |
| `character-profile/power/common-properties.md` | 落点 · 本层合法取值四值 + `Unknown` · **明写「本层无规则消费点」+ 一句代价** · 回链 | 08-10b 封闭三值的冲突始末与「推翻『清单是封闭的』」的论证 · 礼包 / 成就为何是账号级发放的推理 |
| `character-profile/item/common-properties.md` | 同上（法宝列与神通列取值相同） | 同上 |

**两条硬边界（压缩不得越过）：**
- **「本层无规则消费点」那句必须保留**（含它后面那句「字段有信息但暂无规则消费者」的代价说明）——它是本层独有的信息，顶层写不出。
- **删除的是复述，不是设计**——被删的每一条在顶层 `systems/common-properties.md` 都已成文且更完整；压缩后**全库信息量不减**。执行时逐条核对顶层确有对应表述再删，若发现某条**只存在于叶子文档**，则先把它补进顶层再删叶子（顶层是最小公共祖先，它本就该在那里）。

## 具体形态（可 derive 的落地面）

### 判据卡（建议原文落入 `systems/common-properties.md` 顶部，作为该文件的自述）

> **一个共有属性写在哪一层：定义在其全部挂载面的最小公共祖先，恰好一份；每个实际落点写一段投影（落点 · 本层合法子集 · 本层消费点 · 回链），投影不得复述定义。**
> 上移：≥2 个兄弟节点出现且语义同一。下沉：只剩单一子树消费。单一落点的字段不进 `common-properties.md`。
> 某一层是否建 `common-properties.md`：该层有子节点共有且全库不适用的内容，且篇幅已压过 `_index.md` 的索引职责——**按内容建，不按对称建**。

### 当前顶层共有字段的归属核对表（判据的一次全量自检）

| 字段 | 挂载面 | 最小公共祖先 | 结论 | 现有投影段 |
|---|---|---|---|---|
| `ContentEnabled` | 一切 `XxxData` | 顶层 | 留顶层 | `enemies/common-properties.md`（合格） |
| `LocalizedText` | `CardData` / `AdventureEventData` / `ItemData` / `EnemyData` / `PowerData` / 档位条目 / 剧本 | 顶层 | 留顶层 | 尚无（各子树填充时按模板补） |
| `Rarity: RarityTier` | `PowerData` / `ItemData` / `CardData` | 顶层 | 留顶层 | 尚无 |
| `SourceCode` + `Source` | PlayerPower / PlayerItem / CharacterPower / CharacterItem 四类**持有条目** | 顶层 | 留顶层 | 三份已写（格式合格，篇幅偏长，见「仍需用户决定」②） |
| `ExclusiveSource: Source?` | `PowerData` / `ItemData` | 顶层（跨两棵子树） | 留顶层 | 尚无 |
| 物化模型（`XxxData` ↔ 实例） | `AdventureEventData`↔`EventOption`、`CardData`↔`CardInstance` | 顶层（跨 `adventure-event/` 与 `deck/`） | 留顶层 | `adventure-event/common-properties.md` 有完整展开（**这一处超出投影格式**，但它展开的是 `AdventureEventData` 侧的物化规则本身，属该层自有内容，不算复述） |

**核对结论：当前无任何字段需要迁移。** 判据是对既成事实的追认，采纳它不产生一次文档搬迁。

### 投影段模板（新字段落到某一层时照抄）

```markdown
- **`<FieldName>`（共有字段 · 类型 `<T>` · 已定案 · <日期>）。** <一句话：本层落在哪个类上>。
  - **本层合法取值 / 默认值 =** <只抄本层那一列>。
  - **本层消费点：** <点名，或明写「本层无规则消费点」+ 一句代价说明>。
  - 类型定义、取值清单、校验语义见 `systems/common-properties.md`。Source: `handoffs/<...>`。
```

### 可机械检查的一条（供日后文档审计，不是代码需求）

同一个字段名在两份及以上的 `common-properties.md` 中同时出现**枚举成员表 / 数值 code / 完整校验语义**任一者 ⇒ 违规（第二权威）。当前全库扫描：`SourceCode` 的三份投影段**均未复述枚举表**，无违规项。

## 后果

- **影响文档（两项取向裁定后已收敛为确定清单）：**
  - `systems/common-properties.md` —— 重排为 `## 通用约定` / `## 内容共有字段` 两大节，判据卡落后者节首；
  - `systems/_index.md` —— 收尾约定补一句「`common-properties.md` 按内容建，不按对称建」；
  - `systems/player-profile/player-power/common-properties.md` · `systems/character-profile/power/common-properties.md` · `systems/character-profile/item/common-properties.md` —— `SourceCode` 段压回四项 + 回链模板。
  - **不新建任何文件**（`character-profile/` 与 `player-profile/` 的中间层 `common-properties.md` 确认不补）。
- **不影响任何机制、字段语义、存档 schema、API 签名**——纯文档结构约定，不 bump schema、无迁移、无跨库影响。
- **对 `.claude/knowledge/*` 零影响**：引用层照旧逐文件回链，判据管的是本库内部哪一份文件承载定义。
- **对下游流水线的正面影响：** `/derive-requirements` 与 `/breakdown-requirements` 读一个字段时不必判断「这三处哪一处是权威」；`/sync-knowledge` 的「把偷偷长回来的副本压回薄引用」有了本库内部的对应判据。

## 备选方案（已考虑并否决）

- **列一张完整的字段归属表作为答案** —— 否决：字段清单仍在增长（多份子树的字段清单是 `⟨待定⟩`），表会在下一次 handoff 后过时，而问题会原样复发。判据不会过时；表只作为判据的一次自检产物（已附）。
- **一切共有字段全部只写顶层、子树不留投影** —— 否决：`SourceCode` 的分域合法子集、「本层无规则消费点」这类信息**本质上是逐层的**，赶到顶层会把顶层变成一张四列大表，且读者在子树文档里读不出本层能填什么。
- **按「是否跨越两棵子树」以外的标准（例如是否落存档、是否内容定义）分层** —— 否决：这些是字段的属性，不是位置的属性；同一条判据要能同时安置 `ContentEnabled`（内容定义、不落存档）与 `SourceCode`（持有条目、落存档），只有挂载面能做到。
- **为对称补齐 `character-profile/common-properties.md` 与 `player-profile/common-properties.md`** —— 否决：空壳 `common-properties.md` 会成为一个「看起来该写点什么」的坑，把本属顶层的字段吸下来复述一遍。**用户未推翻建议方案四，此否决随定案生效。**
- **顶层拆成两个文件（`common-properties.md` + `common-fields.md`）** —— 否决：破坏「一层一份 `common-properties.md`」的结构对称，且新路径要同步 `systems/_index.md`、`.claude/knowledge/*` 与大量回链。**同一诉求由文件内分两大节满足**（见建议方案五）。

## 与既有决策的张力

**无。** 本方案不推翻任何已定案内容，也不触及任何 ADR；它把 08-12b `SourceCode` 已经采用的写法归纳成通则，并把 `player-profile/_index.md` 已定的「按内容建文件、不按对称建」推广到 `common-properties.md` 这一层。

唯一需要点明的一处**措辞张力**（不是决策冲突）：`handoffs/2026-07-24-docs-restructure-class-model.md` 写的是「每一层的共有字段抽到 `common-properties.md`」，字面读法接近「每层都该有一份」。本方案把它读作「共有字段要显式化」，而非「每层必须建档」。**该读法已随定案确认**（用户评审时未推翻建议方案四）——`handoffs/` 是历史文档、不回改，判据以本次提炼进 `systems/_index.md` 的表述为准。

## 前置依赖

**无硬依赖。** 判据不依赖任何待答问题，且**采纳后无需等待任何子树填充**——它恰好是用来消化后续填充的。

一条弱耦合：`systems/common-properties.md` 的另一条待决项（**`Source` 在上行负载里的序列化形态**，收口归后端库）若最终改动 `Source` 的表示形态，改的是顶层那一份定义，三份投影段一字不动——**这正好是本判据成立的一次预演**。

## 已裁决（2026-08-13 · 用户评审）

**两项取向均已定，草稿整体定案，无遗留待决项。**

| # | 取向 | 裁定 |
|---|---|---|
| ① | 顶层 `systems/common-properties.md` 是否内部分两大节 | **分节**（推荐项 (a)）——形态见建议方案五 |
| ② | 三份 `SourceCode` 投影段是否现在就压回模板 | **现在压**（推荐项 (a)）——逐份压缩面见建议方案六 |

其余部分（主判据 · 投影段格式 · 上移 / 下沉触发器 · 中间层按内容建不按对称建 · 归属核对表 · 审计项）用户评审时未提异议，按草稿原文提炼。

**交给 `/analyze-new-ideas` 的执行清单：** ① 顶层重排两大节 + 判据卡落 `## 内容共有字段` 节首；② `systems/_index.md` 收尾约定补一句；③ 三份叶子文档的 `SourceCode` 段压回模板（守住建议方案六的两条硬边界：保留「本层无规则消费点」那句 · 删前逐条核对顶层确有对应表述）；④ 从 `systems/common-properties.md` 的 `## 待决问题` 与 `open-questions/05-service-contracts.md` 移出本条，记入 `answer-logs/`。**不新建任何文件、不 bump schema、无跨库影响。**

<details>
<summary>原取向选项与推荐理由（保留备查）</summary>

### ① 顶层 `systems/common-properties.md` 是否内部分两大节

顶层文件当下混装两类内容：**A · 全库工程与结构约定**（稳定 `Id`、命名与类型一致性、数据即资源、seeded RNG、存档版本化、null 校验、日志、服务协作、API 契约总则、物化模型、与 `.claude` 的主从关系）与 **B · 具体的内容共有字段**（`ContentEnabled` · `LocalizedText` · `Rarity` · `SourceCode` · `ExclusiveSource`）。

| 选项 | 后果 |
|---|---|
| **(a) 文件内分两大节 `## 通用约定` / `## 内容共有字段`（推荐）** | 判据只对 B 类成立（A 类不谈「挂载面」），分节后判据的适用范围一眼可见；新字段有明确的落笔位置。改动是一次纯重排，不改一个字的语义。 |
| (b) 维持现状，只在文件顶部加判据卡 | 改动最小；代价是判据卡悬在一份混装文件之上，读者要自己分辨哪些条目受它管。 |
| (c) 拆成两个文件（`common-properties.md` + 新建 `common-fields.md`） | 否决倾向：破坏「一层一份 `common-properties.md`」的结构对称，且新路径要同步 `systems/_index.md`、`.claude/knowledge/*` 与大量回链。 |

**推荐 (a)。** 理由：它是唯一让判据可自解释的选项，且代价是一次性的重排。

### ② 三份 `SourceCode` 投影段是否现在就压回模板

三份叶子文档（`player-profile/player-power/`、`character-profile/power/`、`character-profile/item/`）的 `SourceCode` 段格式合格（都回链了顶层、都没复述枚举表），但篇幅超出建议的 5 行——尤其 `player-power` 那段还复述了「唯一消费点」的完整论证与「置换继承来源」，而这两条的权威在顶层。

| 选项 | 后果 |
|---|---|
| **(a) 现在压回模板（推荐）** | 三处各删若干行、保留本层四项 + 回链。**趁只有三处时做**——同一段落格式一旦被后续字段照抄，返工面只会变大。它同时是判据的第一个执行样例。 |
| (b) 只立判据，存量不动，新增字段照模板写 | 零改动风险；代价是全库同时存在两种写法，「照抄邻近写法」的自然习惯会持续复制冗长版本。 |

**推荐 (a)。** 注意本项的执行归 `/analyze-new-ideas`（本技能不改主题文档），提炼时一并做掉。

</details>
