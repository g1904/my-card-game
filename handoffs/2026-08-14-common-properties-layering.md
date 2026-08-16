# 共有属性的分层判据：定义在最小公共祖先，投影在各落点

- id: 2026-08-14-common-properties-layering
- date: 2026-08-14
- topic: systems/common-properties.md, systems/_index.md, systems/player-profile/player-power/common-properties.md, systems/player-profile/player-item/common-properties.md, systems/character-profile/power/common-properties.md, systems/character-profile/item/common-properties.md
- status: distilled
- distilled-to: systems/common-properties.md, systems/_index.md, systems/player-profile/player-power/common-properties.md, systems/player-profile/player-item/common-properties.md, systems/character-profile/power/common-properties.md, systems/character-profile/item/common-properties.md, open-questions.md, open-questions/05-service-contracts.md, open-questions/update-log.md, answer-logs/log-common-properties-layering.md

> 输入 = `inbox/solution-draft-common-properties-layering.md`（`status: decided`，两项取向已由用户裁定）+ 本次 interview 一项范围裁定。

## Intent（distilled）

**一句话：** `common-properties.md` 的分层问题，答案不是一张字段归属表，而是一条可反复套用的判据——**定义在最小公共祖先，投影在各落点**；表会过时，判据不会。

### ① 主判据：定义 / 投影两种形态，权限不同

一个共有属性在文档树上有两种出现形态：

| 形态 | 写什么 | 允许出现在几层 |
|---|---|---|
| **定义（权威）** | 类型 / 枚举清单 / 取值域 / 不变式 / 校验语义 / 与其他字段的关系 | **恰好一层**：它全部挂载面的**最小公共祖先** |
| **投影（引用）** | 本层落在哪个类上、本层的合法子集、本层的消费点、回链 | 每个实际落点各一份，**可以有多份** |

**「最小公共祖先」按挂载面算，不按「感觉有多通用」算。** 例：`ExclusiveSource` 只覆盖 `PowerData` / `ItemData` 两个类，但这两个类的落点横跨 `character-profile/` 与 `player-profile/` 两棵子树 ⇒ 最小公共祖先是 `systems/` 顶层。

**它是既有实践的归纳，不是新规**——`SourceCode`（08-12b）已完全按这个形状写成：不变式全在顶层，叶子各写本层合法取值列 + 本层有无规则消费点 + 回链。本次只是把它从「一次巧合的写法」升为「下一个共有字段照抄的模板」。

**承重推论（这条判据唯一的硬边界）：同一个字段的「定义级内容」在两份 `common-properties.md` 中同时出现即为违规。** 投影段里出现枚举成员表、code 数值、完整校验语义的复述，都算把权威复制了一份——它们会各自漂移，而**本库没有任何机制能发现两份表不一致**。

### ② 投影段的固定格式：四项 + 回链，5 行以内

**落点**（本层落在哪个类上）· **本层合法子集 / 默认值**（只抄本层那一列）· **本层消费点**（点名，或**明写「本层无规则消费点」+ 一句代价**）· **回链**。

**为什么必须明写「本层无消费点」而不是省略：** 省略与「还没想」不可区分——写下这句的文档因此是可信的，没写的地方读者只能去顶层重读一遍再自己推断。

### ③ 上移 / 下沉的触发器（面向对象重构的 pull-up / push-down field，在文档树上同样成立）

- **上移**：同一字段在 ≥2 个兄弟节点出现**且语义同一** ⇒ 定义上移到最小公共祖先，原处降为投影段。**「语义同一」是硬前置**——同名不同义（`RarityTier` vs `Tier`，08-10c 的教训）不上移，且**不得为了上移而把两个不同概念改成同一个名字**。
- **下沉**：顶层某条只被单一子树消费 ⇒ 下沉，**顶层不留摘要**（活文档不留考古）。
- **只有一个落点的字段不进任何 `common-properties.md`**，留在该类自己的 `_index.md`——`common-properties` 的语义是「共有」，一个落点的字段写进去会让读者误以为还有别的落点。

### ④ 某一层要不要建 `common-properties.md`：按内容建，不按对称建

两条**同时成立**才建：① 该层存在其子节点共有、且不适用于全库的属性或机制（否则它属顶层）；② 这批内容的篇幅已压过 `_index.md` 的索引职责（经验界：约 40 行以上，或超过该层 `_index.md` 的一半）。

逐层核对的结论：`adventure-event/`（213 行，九类共有）与 `enemies/`（45 行）**该建、已建**；`character-profile/`（横切共性只是「随 `defeated` / `completed` 清理」一两句）与 `player-profile/`（横切是「账号级持久 + 两层同步口径」，已在 `_index.md` 内成节）**不建**。

**推论：结构不对称不是缺陷，是判据的正确产物。** 这句必须写进 `systems/_index.md`，否则日后必然有人（或一次 `/update-readme`）以「补齐结构」为由建出两份空壳——而空壳 `common-properties.md` 的代价是实打实的：它是一个「看起来该写点什么」的坑，会把本属顶层的字段吸下来复述一遍，造出第二权威。

### ⑤ 顶层 `systems/common-properties.md` 分两大节（取向裁定 · 用户 08-13）

- **`## 通用约定`** —— 稳定 `Id` · 字段命名与类型一致性 · 数据即资源 · 展示字段的归属 · 物化模型 · seeded RNG 派生 · 存档版本化与原子写入 · null / 结果校验 · 日志 · 服务协作 · API 契约总则 · 与 `.claude` 的主从关系。
- **`## 内容共有字段`** —— `ContentEnabled` · `LocalizedText` · `Rarity: RarityTier` · `SourceCode` + `Source` · `ExclusiveSource: Source?`。

**判据卡落 `## 内容共有字段` 节首，不落文件顶部**——判据只对本节成立（`## 通用约定` 那批条目不谈「挂载面」，也不产生投影段）。这正是分节的目的：让判据的适用范围一眼可见，新字段有明确的落笔位置。**纯重排，不改一个字的语义**；`## 决策(-> ADR)` / `## 待决问题` / `## 对应` 三节位置与内容不变。

### ⑥ 存量 `SourceCode` 投影段现在就压回模板（取向裁定 · 用户 08-13；范围由 interview 扩为四份）

趁存量小时做，它同时是本判据的第一个执行样例。**两条硬边界（压缩不得越过）：**
- **「本层无规则消费点」那句必须保留**（含它后面那句「字段有信息但暂无规则消费者」的代价说明）——它是本层独有的信息，顶层写不出。
- **删除的是复述，不是设计**——被删的每一条在顶层都已成文且更完整，压缩后**全库信息量不减**。执行时逐条核对顶层确有对应表述再删；若某条**只存在于叶子文档**，先补进顶层再删叶子。

逐份压缩面：

| 文件 | 保留 | 删除（权威在顶层） |
|---|---|---|
| `player-profile/player-power/common-properties.md` | 落点 · 三值 + `Unknown` · 消费点 = 残卷的 `x`（并改写为「全库唯一的规则消费点」）· 回链 | **过时的「没有第二个消费点：不对玩家可见 / 不进图鉴 / 不参与其他判定」**（08-12b 已把它改写为「规则消费点唯一 + 非规则用途两处」，此处仍是 08-10b 的旧表述）· 置换继承来源及其防刷论证 · 各成员为何不合法的逐条理由 |
| `player-profile/player-item/common-properties.md` | 落点 · 三值 + `Unknown` · **明写「本层无规则消费点」+ 代价** · 回链 | 「`ExchangePurchase` 是 08-12b 补上的那一条」这句考古 · `FinaleWin` 只发法则 / `CombatReward`·`InitialGrant` 属轮回级来路的逐条理由 · 「付费给予 vs 玩法购买是退款申诉第一手依据」（顶层原文已有） |
| `character-profile/power/common-properties.md` | 落点 · 四值 + `Unknown` · **明写「本层无规则消费点」+ 代价** · 回链 | 08-10b 封闭三值的冲突始末与「推翻『清单是封闭的』」的论证 · 礼包 / 成就为何是账号级发放的推理 |
| `character-profile/item/common-properties.md` | 同上（法宝列与神通列取值相同） | 同上 |

### ⑦ 判据的一次全量自检：当前无任何字段需要迁移

顶层五个共有字段（`ContentEnabled` · `LocalizedText` · `Rarity` · `SourceCode`+`Source` · `ExclusiveSource`）的最小公共祖先全部是顶层，核对表落入 `systems/common-properties.md`。**判据是对既成事实的追认，采纳它不产生一次文档搬迁**——这不是巧合：它们能被写进顶层，正是因为当初每一条都是在第二个落点出现时才被抽上去的。

`adventure-event/common-properties.md` 对物化模型的完整展开**超出投影格式但不违规**：它展开的是 `AdventureEventData` 侧的物化规则本身，属该层自有内容，不是复述。

### ⑧ 可机械检查的一条（文档审计用，不是代码需求）

同一个字段名在两份及以上的 `common-properties.md` 中同时出现**枚举成员表 / 数值 code / 完整校验语义**任一者 ⇒ 违规（第二权威）。**当前全库扫描：四份 `SourceCode` 投影段均未复述枚举表，压缩后无违规项。**

### 影响面

- **不影响任何机制、字段语义、存档 schema、API 签名**——纯文档结构约定，不 bump schema、无迁移、**无跨库影响**。
- **对 `.claude/knowledge/*` 零影响**：引用层照旧逐文件回链，判据管的是本库内部哪一份文件承载定义。
- **对下游流水线的正面影响：** `/derive-requirements` 与 `/breakdown-requirements` 读一个字段时不必判断「这几处哪一处是权威」；`/sync-knowledge` 的「把偷偷长回来的副本压回薄引用」有了本库内部的对应判据。

### 已考虑并否决

- **列一张完整的字段归属表作为答案** —— 字段清单仍在增长（多份子树的字段清单是 `⟨待定⟩`），表会在下一次 handoff 后过时、问题原样复发。表只作为判据的一次自检产物。
- **一切共有字段全部只写顶层、子树不留投影** —— `SourceCode` 的分域合法子集、「本层无规则消费点」这类信息**本质上是逐层的**，赶到顶层会把顶层变成一张四列大表，且读者在子树文档里读不出本层能填什么。
- **按「是否跨越两棵子树」以外的标准分层**（是否落存档 / 是否内容定义） —— 这些是**字段的属性，不是位置的属性**；同一条判据要能同时安置 `ContentEnabled`（内容定义、不落存档）与 `SourceCode`（持有条目、落存档），只有挂载面能做到。
- **为对称补齐 `character-profile/` 与 `player-profile/` 的中间层 `common-properties.md`** —— 见 ④。
- **顶层拆成两个文件**（`common-properties.md` + `common-fields.md`） —— 破坏「一层一份 `common-properties.md`」的结构对称，且新路径要同步 `systems/_index.md` 与大量回链；同一诉求由文件内分两大节满足。

## Clarifications（interview 产物）

- **「三份 `SourceCode` 投影段」实为四份，第四份要不要一并压？→ 四份一并压。** 草稿的核对表与执行清单都漏了 `systems/player-profile/player-item/common-properties.md`（古宝），而它同样含复述内容（各成员为何不合法的逐条理由、「付费给予 vs 玩法购买是退款申诉第一手依据」——顶层原文已有）。裁定：一并压，使「投影不得复述定义」这条硬边界在全库无例外，也贯彻「趁存量小一次做完」的原始理由。**这修正了草稿 ⑥ 与自检表中「三份」的计数。**

## 与既有决策的张力

**无。** 不推翻任何已定案内容，不触及任何 ADR。它把 08-12b `SourceCode` 已采用的写法归纳成通则，并把 `player-profile/_index.md` 已定的「按内容建文件、不按对称建」推广到 `common-properties.md` 这一层。

一处**措辞张力**（非决策冲突）：`handoffs/2026-07-24-docs-restructure-class-model.md` 写的是「每一层的共有字段抽到 `common-properties.md`」，字面读法接近「每层都该有一份」。本次把它读作「**共有字段要显式化**」，而非「每层必须建档」；该读法随本次定案确认，判据以 `systems/_index.md` 的表述为准。

## Open questions

无。判据不依赖任何待答问题，且采纳后无需等待任何子树填充——它恰好是用来消化后续填充的。

一条**弱耦合**（不是待答项）：`systems/common-properties.md` 的待决项「`Source` 在上行负载里的序列化形态」（收口归后端库）若最终改动 `Source` 的表示形态，改的是顶层那一份定义，四份投影段一字不动——**这正好是本判据成立的一次预演**。

## Notes / triage

- 输入草稿 `inbox/solution-draft-common-properties-layering.md` 已置 `status: distilled` 并移入 `inbox/archive/`。
- 答定条目「共有属性提炼粒度」已从 `open-questions/05-service-contracts.md` 与 `systems/common-properties.md` 的 `## 待决问题` 移出，记入 `answer-logs/log-common-properties-layering.md`。
