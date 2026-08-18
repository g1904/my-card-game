# Answer log profile-field-schema

- 日期：2026-08-17
- 来源：`inbox/archive/solution-draft-profile-field-schema.md` → `handoffs/2026-08-17-profile-field-naming.md`
- 移出条数：2（均为草稿「仍需用户决定」的两项；本库 `open-questions/` 分片无对应条目，分片移出 0 条）
- counterpart：`game-design-documents/answer-logs/log-profile-field-schema.md`（客户端侧结论，本 log 只记后端侧）

## 逐条

**透明路径改名的切换时序：A 直接切，还是 B 走一次带版本判别的双读期？** → **取 A**。判据是「线上有无真实账号数据」，答复为**无真实账号数据** ⇒ 白名单一次性改名、不写迁移、不设兼容期，与客户端两层 Profile 字段面收口并入同一次 `schemaVersion` bump。B 的双读分支与它那条要记得关闭的开关一并不写。理由同时写进契约：§7a 的处置是「仅记账、不拒绝、不改写」，双读期内没有任何信号能告诉任一侧「对方还没改」，兼容期在这里不是安全网而是让不一致永久不可见。（→ `contracts/profile-sync.md` §5b）

**§7 的复算校验 ①/②/③ 是否确按「递增后的 `finaleWinOrdinal`」实现与描述？** → **是，两侧已对齐，零改动关闭**。§7 原措辞「后端在 `finaleWinOrdinal` 递增的那一次 push 上」已蕴含自增后口径；客户端同批把同一口径写成显式的先算后写。本次只做措辞消歧：客户端伪码行标注「本次（自增后）的胜利序号」+ 正文点明校验 ① 的 `ordinal` 输入两侧同数。**算法与 §6a 的 8 组测试向量一字未动。**（→ `contracts/profile-sync.md` §7；客户端侧通则回链 `game-design-documents/systems/common-properties.md`）

## 连带落笔（非移出项）

- 白名单四条路径改名：`/playerPower[*]/powerId` · `/playerPower[*]/sourceCode` · `/playerPower[*]/status`（排除项）· `/playerItem`（排除项）。条目键 `id → powerId` 随客户端四类持有条目的键名收口一并落地。（→ `contracts/profile-sync.md` §5）
- 新增 §5b「透明路径的集合命名通则：恒为单数」+ 一次性切换的三个成立前提（线上无真实账号数据 · 两侧同批落笔 · 一次性不留双读期）。
- `characterDiffs` 不改名——它是 diff 报文的结构键，不在该通则的约束面内；§5 排除清单就此补了一句。
- `envelope.md` §8 可见性表的路径示例随白名单同步（`playerPower[*]` 的 `powerId` 与 `sourceCode`）。
