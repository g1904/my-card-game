# Answer log splitmix64-test-vectors

- 日期：2026-08-14
- 来源：`inbox/archive/solution-draft-splitmix64-test-vectors.md` → `handoffs/2026-08-14-splitmix64-test-vectors.md`
- 移出条数：1（`open-questions/01-contracts.md`）

## 移出的条目

**`profile-sync.md` §6 测试向量表的实际数值未填** → **已填，8 组。** 数值权威落 `contracts/vectors/splitmix64.json`，`contracts/profile-sync.md` 新增 §6a 承载人类可读对照表与选取依据。

同一条裁决内附带三项定案：

1. **填值时机提前**（本次唯一的取向裁决）——由「向量值在任一侧首次实现 SplitMix64 时填入」改为「由独立参考实现**预先算出**并落 `vectors/splitmix64.json`；两侧各自实现后**逐位对表**，对不上以该文件为准」。依据：向量是已冻结算法的函数，不含设计自由度，等待换不来信息；先有表则两侧是对着验收物写实现。（归档去向：`contracts/profile-sync.md` §6a）
2. **新增一条承重纪律**——实现与表不符时**先复核实现、再复核表**；两者都复核完仍不符则重算并同批改 markdown + JSON，**不得单方面改表迁就实现**。它是为「表由第三方参考实现算出」这一代价配的护栏。（归档去向：`contracts/profile-sync.md` §6a + `vectors/splitmix64.json` 的 `$comment`）
3. **`vectors/splitmix64.json` 的字段形态**——64 位值走 16 位小写 hex 字符串（`envelope.md` §2 判据）；算法常量与 `streams` 冻结映射同文件承载；`vectors` 为有序数组、每项带 `name`；不为其建 JSON Schema（不满足 `_index.md` 的两条 `schemas/` 拆分判据）。（归档去向：`contracts/vectors/splitmix64.json` + `contracts/_index.md` 现状段）

## 未答结 / 明确不做

- **第四条机检断言**「markdown §6a 表格 ⇔ `vectors/splitmix64.json` 逐值一致」**不立**——与 `06` 的自动化承载耦合，在此之前只作 `contracts/_index.md` 人工清单第 2 项下的一次具体检查。**不进待答清单**（它是一个被否决的增项，不是悬而未决的问题），仅作 `06` 落定时的候选记于 handoff。
- `01-contracts.md` 余下四条（`auth.md` 三处留白 · `compliance.*` 码清单 · `bundleGrantOrdinal` 透明路径 · 三条机检断言的承载位置）与本次无关，**原样留在待答清单**。

## 跨库

本次**不改动任何报文语义**，客户端侧无需承接性 handoff。既有跨库欠账（`handoffs/2026-08-14-profile-sync-contract.md` 七点）中的第 6 点（`AccountRng` 换随机源）自此有可直接消费的验收物，客户端可先于后端完成并自验。
