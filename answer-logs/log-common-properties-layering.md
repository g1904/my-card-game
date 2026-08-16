# Answer log common-properties-layering

- 日期：2026-08-14
- 来源：`inbox/solution-draft-common-properties-layering.md`（`status: decided`，两项取向已裁决）→ `handoffs/2026-08-14-common-properties-layering.md`
- 移出条数：1

---

**共有属性提炼粒度——哪些字段应下沉到子树各自的 `common-properties.md`、哪些留在顶层**
→ **答案不是一张字段归属表，而是一条判据：定义在最小公共祖先，投影在各落点。**

- **定义**（类型 / 枚举清单 / 取值域 / 不变式 / 校验语义 / 与其他字段的关系）**恰好写一层** = 该字段全部挂载面的最小公共祖先，**按挂载面算，不按「感觉有多通用」算**。
- **投影**（本层落点 · 本层合法子集 / 默认值 · 本层消费点 · 回链）每个实际落点各一份，5 行以内；**必须明写「本层无规则消费点」**而不是省略——省略与「还没想」不可区分。
- **硬边界（可机械检查）：** 同一字段在两份及以上的 `common-properties.md` 中同时出现枚举成员表 / 数值 code / 完整校验语义 ⇒ 违规（第二权威）。
- **上移**：≥2 个兄弟节点出现**且语义同一**（`RarityTier` vs `Tier` 这类同名不同义不上移，也不得为了上移而改成同名）。**下沉**：只剩单一子树消费 ⇒ 下沉，顶层不留摘要。**单一落点的字段不进任何 `common-properties.md`。**
- **某层是否建 `common-properties.md`：按内容建，不按对称建**——两条同时成立才建（该层有子节点共有且全库不适用的内容 · 篇幅已压过 `_index.md` 的索引职责）。`character-profile/` 与 `player-profile/` 因此**有意不建**中间层；**结构不对称是判据的正确产物**。
- **全量自检：当前五个顶层共有字段无一需要迁移**——判据是对既成事实的追认，采纳不产生一次文档搬迁。

归档去向：`systems/common-properties.md`（重排为 `## 通用约定` / `## 内容共有字段` 两大节；判据卡 + 投影段模板 + 归属核对表落 `## 内容共有字段` 节首）、`systems/_index.md`（收尾约定新增建档判据）。

**连带执行**（判据的第一个执行样例，非移出项）：四份 `SourceCode` 投影段压回模板 —— `systems/player-profile/player-power/common-properties.md` · `systems/player-profile/player-item/common-properties.md` · `systems/character-profile/power/common-properties.md` · `systems/character-profile/item/common-properties.md`。草稿原写「三份」，interview 裁定**四份一并压**（漏了古宝那份）。

**未答定 / 不受影响：** `systems/common-properties.md` 的另两条待决项（`Source` 的上行序列化形态 · `EventOutcome` 与 `CombatReward` 是否合并）原样留在该文件与 `open-questions/05-service-contracts.md`；本次纯文档结构约定，不改任何机制、字段语义、存档 schema 或 API 签名，无跨库影响。

## 台账原记（自 `_index.md` 归并）

> 台账瘦身前，`answer-logs/_index.md` 本行记有以下内容，原样保留于此。

已裁决）→ ：**共有属性的分层判据** —— 要定的不是一张字段归属表（表会随子树填充过时、问题原样复发），而是一条可反复套用的判据：**定义在最小公共祖先，投影在各落点**。定义（类型 / 枚举清单 / 取值域 / 不变式 / 校验语义）**恰好写一层**，按**挂载面**算最小公共祖先而非「感觉有多通用」（例：`ExclusiveSource` 只覆盖两个类，但两类落点横跨两棵子树 ⇒ 顶层）；每个落点写一段**投影**（落点 · 本层合法子集 · 本层消费点 · 回链，≤5 行），**投影不得复述定义**——两份表会各自漂移而本库无任何机制能发现不一致，故立可机械检查的一条：同一字段名在两份及以上 `common-properties.md` 中出现枚举成员表 / 数值 code / 完整校验语义 ⇒ 违规。**必须明写「本层无规则消费点」**（省略与「还没想」不可区分）。**上移**以「语义同一」为硬前置（`RarityTier` vs `Tier` 不上移，且不得为上移而改成同名）· **下沉**后顶层不留摘要 · **单一落点的字段不进任何 `common-properties.md`**。**某层是否建档：按内容建，不按对称建**（子节点共有且全库不适用 **且** 篇幅压过 `_index.md` 索引职责）⇒ `character-profile/` / `player-profile/` **有意不建**中间层，**结构不对称是判据的正确产物**——空壳 `common-properties.md` 是个「看起来该写点什么」的坑，会把顶层字段吸下来复述成第二权威。落地：顶层重排为 **`## 通用约定` / `## 内容共有字段`** 两大节（纯重排、语义一字不改；判据卡落后者节首，因它只对内容字段成立，通用约定那批不谈挂载面也不产生投影段）+ 全量自检表（五个字段**无一需迁移** ⇒ 判据是对既成事实的追认）。**⚠ interview 一项**：草稿写「三份 `SourceCode` 投影段」实为**四份**（漏 `player-item/`），裁定**四份一并压**，顺带清掉 `player-power/` 中 08-10b 遗留的过时表述「没有第二个消费点」。**不推翻任何 ADR / 定案**（07-24「每一层的共有字段抽到 `common-properties.md`」经核为措辞张力，读作「共有字段要显式化」）；**纯文档结构约定：不改机制 / 字段语义 / 存档 schema / API 签名，不 bump schema，无跨库影响**　｜移出条数原记：1（新增待答 0 条）
