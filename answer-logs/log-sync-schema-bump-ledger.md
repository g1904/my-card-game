# Answer log sync-schema-bump-ledger

- 日期：2026-09-05
- 来源：`inbox/solution-draft-sync-schema-bump-ledger.md`（→ `handoffs/2026-09-05-schema-ledger-v1-coverage.md`）
- 移出条数：1

**🟠 `sync-service.md` 的 schema bump 清单已漏三批，而后端把 bump 权威指回它（2026-08-30 由 `/assess-derive-readiness` 登记）** → **条目所述三件事经逐条核实全部已答结，条目本身自登记后不久即过期**：① 那张清单已拆出为独立文档 `systems/services/profile-schema-versions.md`，`sync-service.md`「### 存档 schema 版本」只留一句回链；② 条目点名的四批中，`pastItemUse` / `ItemElements` / `ItemUseElements` 已在 v1 行 #8 · #22、`StatusChanges` 列在 #22、栈条目 `itemId` 在 #27，`Status` 删三格属**有意不登记**（形态纪律 ④「首发前删除的字段不进任何版本行」）；③ `character-profile/_index.md` 的第二处 bump 自称连同全库 24 处 + 5 份 ADR 已全部改为回链固定句式；④ 后端 `contracts/profile-sync.md` 与 `contracts/envelope.md` 均已改指登记表。

**残留部分改写后降级并移入 `open-questions/05-service-contracts.md`**（不关闭——本条自身的失效模式正是「跨步骤的第二半不会发生」）：残留 = 登记表 v1 行的 **11 处覆盖空缺** + 一处不可核对的计数，两者与原条目同源（同一条「漏登不可见」的失效模式）。本次已由 `handoffs/2026-09-05-schema-ledger-v1-coverage.md` 落笔收口：v1 清单追加 #28–#33 + `achievement` 占位说明、#18 错归属订正、#12 与表内另六处计数删除、形态纪律 ⑥「本表不写任何计数」+ 射程限定、`ProfileShapeCheck` 一节补一条 `/sync-knowledge` 条目维度对账断言、`ADR-0127` 两处同源计数同批订正。
（归档去向：`systems/services/profile-schema-versions.md`、`decisions/ADR-0127-life-merged-into-lifespan.md`）

**同批裁决两项（合并 interview）：**

- **过期条目的处置路径与索引就绪度小节的边界** → 条目改写后**移入分片**，`open-questions.md` 的 `## derive 就绪度` 小节**一字不碰**（它由 `/assess-derive-readiness` 独占写入；单次落笔去改写一份全量扫描的产物正是该独占纪律要防的事）。改写后的条目正文另带一句，指明索引就绪度小节内的相应 derive 前置标注讲的是已消失的前提，待下次全量评估清理。这推翻了草稿「就地改写 + 撤销三处标注」的写法。（归档去向：`open-questions/05-service-contracts.md`）
- **后端待答清单两处残留错指是否本次一并修正** → **一并修正**，纯删除已失效陈述，不新增后端义务、不触碰任何契约、不替后端拍板。这推翻了草稿「前置依赖 ③ 第 ②」的「无残留错指」断言：契约正文那半成立，待答清单那半不成立。（归档去向：`backend-design-documents/open-questions.md`）

**未答结、仍留在清单上的相邻项：** `open-questions/05-service-contracts.md` 的三条 `.csproj` 实测前置原样保留——`ProfileShapeCheck` 的落地时点仍绑在它们那一批，本次维持既定排期、不提前单独落地。
