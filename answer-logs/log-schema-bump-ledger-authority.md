# Answer log schema-bump-ledger-authority

- 日期：2026-09-03
- 来源：`inbox/solution-draft-schema-bump-ledger-authority.md`（→ `handoffs/2026-09-03-schema-bump-ledger-authority.md`）
- 移出条数：1

**`systems/character-profile/_index.md` 的 11 处 schema bump 自称改为回链（09-02 新增，须与清单补齐同批做）** → 已完成，且改动面比登记时更大：核实后同型自称实为 **24 处 + 5 份 ADR**（`profile-service.md` 一家就有 8 处，`ADR-0021` 是第五份带就地断言的 ADR）。顺序约束照既定执行——先补齐清单、再改回链，中间不留窗口。清单的权威落点同批拆出为 `systems/services/profile-schema-versions.md`（逐版登记表，v1 行 27 条首发形状），`sync-service.md`「### 存档 schema 版本」只留一句回链，全部回链一次性写对、不经中转。三类非自称表述（否定式 / 假设式 / 纪律式）按判据保留不动。（归档去向：`systems/services/profile-schema-versions.md`、`systems/services/sync-service.md`、`systems/character-profile/_index.md`）

**同批裁决三项（合并 interview）：**

- **统计层新增字段是否 bump（两侧文档写反）** → 区分「引入顶层键」与「键内追加」：首次引入 `statistics` / `disabledAbility` 两个顶层键本身进 v1 行；此后在 `statistics` 内加计数项不 bump。两侧各补一句分界，**不推翻任何一侧**。（归档去向：`systems/services/profile-schema-versions.md`、`systems/services/sync-service.md`、`backend-design-documents/contracts/envelope.md`）
- **删除类改动如何进登记表** → 登记表语义取「每一版的形状」，与 `ProfileShapeCheck` / golden 快照严格同构；删除类不进 v1 行，处置口径作为形态纪律落说明区（适用于 v2+）。`ADR-0127` 据此补上漏执行的第 ⑤ 步。（归档去向：`systems/services/profile-schema-versions.md`、`decisions/ADR-0127`）
- **形状护栏的载体** → 取 golden JSON 快照文件（非指纹 hash），须带文件头注释「本文件由 `ProfileShapeCheck` 生成，不是规格；规格见各字段文档」。快照落 `game-feature-branch/`，设计库只记文件名。（归档去向：`systems/services/profile-schema-versions.md`、`systems/architecture.md`）

**未答结、仍留在清单上的相邻项：** `open-questions/05-service-contracts.md` 的三条 `.csproj` 实测前置原样保留 —— `ProfileShapeCheck` 的**落地时点**依赖它们，本次只定设计形态。
