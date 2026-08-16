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
