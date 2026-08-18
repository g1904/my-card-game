# 透明路径的集合字段命名：复数 → 单数（一次性切换）· 残卷 `ordinal` 口径确认

- id: 2026-08-17-profile-field-naming
- date: 2026-08-17
- topic: contracts/profile-sync（§3a 示例 · §5 白名单四行改名 · 新增 §5b 命名通则与三个成立前提 · §7 `ordinal` 口径消歧）· contracts/envelope（§8 可见性表的路径示例）· open-questions/cross-boundary（确认性承接项）
- status: distilled
- distilled-to: `contracts/profile-sync.md`、`contracts/envelope.md`、`open-questions/cross-boundary.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-profile-field-schema.md`
- counterpart: `game-design-documents/handoffs/2026-08-17h-profile-field-schema.md`

## Intent（distilled）

**一句话：客户端把两层 Profile 的集合字段名统一为单数，而透明路径是契约的一部分 ⇒ 白名单必须同批改名，且这次改名要连同它的成立前提一起写下来。**

### 1. 白名单四条路径改名

| 现路径 | 新路径 |
|---|---|
| `/playerPowers[*]/id` | `/playerPower[*]/powerId` |
| `/playerPowers[*]/sourceCode` | `/playerPower[*]/sourceCode` |
| `/playerPowers[*]/status`（排除项） | `/playerPower[*]/status` |
| `/playerItems`（排除项） | `/playerItem` |

条目键 `id → powerId` 随客户端四类持有条目的键名收口一并落地（`CharacterItem.ItemId` / `CharacterPower.PowerId` / `PlayerItem.ItemId` / `PlayerPower.PowerId` 全族一致，形态权威在客户端库）。

**不动的三处：** `/playerPowerFragment/*` 与 `/entitlement/bundleGrantOrdinal` 非集合字段；`characterDiffs` 是本契约自己定义的 diff 报文结构键，不经字段映射产生，故不在这条通则的约束面内。

### 2. 命名通则进契约（§5b）

透明路径中的集合字段名**恒为单数**。它跨边界，是因为存档字段名经客户端的 camelCase 单点策略**机械映射**成 JSON path——任一侧留一个复数例外，边界上就得挂一张例外表，而那张表本身即第二权威。

### 3. 一次性切换，不设兼容期；三个前提写进契约

**线上无真实账号数据 · 两侧同批落笔 · 一次性不留双读期**——三者同时成立才允许把一次破坏性改名做成一次性切换。缺一即不成立，这是路径稳定性纪律的行使条件，不是它的松动。

**兼容期在这里不是安全网。** §7a 的处置是「仅记账、不拒绝、不改写」⇒ 双读期内没有任何信号能告诉任一侧「对方还没改」；不一致的症状是风控噪声而非报错，会随双读分支长期存活而永久不可见。硬信号只能来自一次性切换 + 一次 `schemaVersion` bump（本次并入客户端两层 Profile 字段面收口的同一次 bump，清单权威在客户端库）。

### 4. 残卷 `ordinal` 口径：两侧已对齐，只做措辞消歧

§7 的复算伪码原就写「后端在 `finaleWinOrdinal` **递增的那一次** push 上」，蕴含的正是「本次（自增后）序号」；客户端同批把同一口径写成显式的先算后写。**两侧算法与实现无需任何改动。** 本次只在客户端伪码行补一句标注，并在正文点明「校验 ① 的 `ordinal` 输入两侧同数」，把一个靠推断成立的一致变成一个写在纸上的一致。

**§6a 的 8 组测试向量与 §6 的算法一字未动**——三参数派生的输入是 `(accountSeed, stream, ordinal)`，与字段名无关。

## Clarifications（interview 产物）

- **切换时序取 A（直接切、不写迁移、不设兼容期）。** 草稿把它列为待后端裁决的取向（A 直接切 / B 带版本判别的双读期），判据是线上有无真实账号数据 —— 答复为「线上无真实账号数据」，故取 A。B 的双读分支连同「要记得关闭的开关」一并不写。
- **`ordinal` 确认项的处置 = 确认对齐 + 顺手消歧。** 草稿留了两条出路（确认则关闭 / 否认则升级为契约缺陷）。核实结论是 §7 现有措辞已蕴含自增后口径 ⇒ 关闭该项，只做零风险的措辞消歧，不改算法、不改向量。
- **条目键名一并收口为 `powerId`。** 草稿的改名表把 `/playerPowers[*]/id` 只改容器段（`/playerPower[*]/id`）；随客户端四类持有条目的键名全族一致，本次连键名一并改为 `powerId`。
- **`characterDiffs` 不改名。** 单数通则的适用面是两层 Profile 及其子对象的存档字段名；diff 报文结构键不在内。草稿的改名表未列它，与该边界一致。

## Open questions

无。本 handoff 的两项待决均已裁决，改名面封闭。

## Notes / triage

来源：`inbox/solution-draft-profile-field-schema.md`（跨边界承接的对侧那一半）。与客户端库同批运行，counterpart 见文件头。

本 handoff 只承载归属后端的那一半（透明路径白名单、复算校验、契约版本化）；客户端的字段语义、层归属与存档形态一律回链客户端库，不复述。

## 客户端侧影响

改动客户端 ↔ 后端边界语义，受影响成分 **`sync-service`**（上行 `playerDiff` 中两条集合字段的 JSON path 改名）。客户端侧的字段面收口已于同批在 `game-design-documents/` 落笔，见 counterpart。**两侧须同批采纳**——单侧采纳即两侧不一致，且按 §7a 该不一致不会报错、只产生风控噪声。
