# Phase B 报告 — 分片 F：后端 counterpart（波次 6/6）

目标库：**`backend-design-documents/`**。未触碰客户端库任何文件，未写任何共享台账。`answers.md` 的 R-01 / F-1 / F-2 / F-3 与 A-R1 / A-R2 / E-O3 全部照裁决落笔。

## 1. 改动文件逐条清单

| 文件 | 改了什么 |
|---|---|
| `handoffs/2026-08-17-profile-field-naming.md` | **新建**（`distilled`，`counterpart` 指客户端 handoff）；Intent 四节 + Clarifications 四条 + Notes + 客户端侧影响 |
| `contracts/profile-sync.md` | ① 文档头 `Source:` 追加；② §3a 示例 `playerPowers` → `playerPower`；③ §5 白名单两行改名 `/playerPower[*]/powerId` · `/playerPower[*]/sourceCode`；④ §5 排除清单两行改名 `/playerPower[*]/status` · `/playerItem`，并给 `characterDiffs` 补一句「它是 diff 报文结构键、不受集合命名通则约束」；⑤ **新增 §5b「透明路径的集合命名通则：恒为单数」**（通则 + 跨边界机械映射理由 + 回链客户端字段面权威 + `characterDiffs` / `playerDiff` 划界 + **一次性切换的三个成立前提** + 兼容期不是安全网的理由 + 并入客户端同一次 bump）；⑥ §7 客户端伪码行补注「`finaleWinOrdinal` = 本次（自增后）的胜利序号」，并新增一段「`ordinal` 口径两侧一致 ⇒ 校验 ① 无歧义」+ 回链客户端通则 |
| `contracts/envelope.md` | §8 三段可见性表的路径示例随白名单同步：`playerPowers[*]` 的 `id` → `playerPower[*]` 的 `powerId` |
| `answer-logs/log-profile-field-schema.md` | **新建**，2 条移出 + 4 项连带落笔 |

**一字未动**：§6 算法块 · **§6a 的 8 组测试向量表** · §6a 全部说明与备选方案 · §7 三条校验与三条写入约定本体 · §7a · §8–§12 · `contracts/vectors/splitmix64.json` · `contracts/_index.md` · `decisions/` · 一切共享台账。

**§5b 落位修正**：初次插入落在 §5a 之前，已移到 §5a 之后（当前小节序 5 → 5a → 5b → 6）。

**溯源三条自查**（两份活文档）：本次新增文本零命中；`Source:` 计数 = 2，16 个 `##` 小节。

## 2. §6a 测试向量核对（定向回答）

**8 组测试向量确实零改动。** 三重自查：
1. `git diff -U0 contracts/profile-sync.md` **不含任何一行**带向量值（`238275bc` / `2f101fe2` / `80abe802` / `fc042709` / `df8b7d9f` / `b4acb5a8` / `e911376e` / `7834afc7`），也不含 `Mix(z)` / `GOLDEN` / `next[0]` 行。
2. 向量表当前 8 行逐行核对与原文一致。
3. `contracts/vectors/splitmix64.json` 未被打开、未被修改。

理由已写进 handoff：三参数派生的输入是 `(accountSeed, stream, ordinal)`，与字段名无关。

## 3. 台账素材

### 3a. `handoffs/_index.md` 新增行（置顶）
```
| `2026-08-17-profile-field-naming` | 2026-08-17 | contracts/profile-sync（§3a 示例 · §5 白名单与排除清单四行由复数改单数、条目键 `id → powerId` · 新增 §5b 集合命名通则与一次性切换的三个成立前提 · §7 `ordinal` 口径消歧）· contracts/envelope（§8 可见性表路径示例）· open-questions/cross-boundary（确认性承接项） | distilled | `contracts/profile-sync.md`、`contracts/envelope.md`、`open-questions/cross-boundary.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-profile-field-schema.md`、`answer-logs/_index.md` |
```

### 3b. `open-questions/cross-boundary.md`
**「待承接」区新增 0 条**（同批落笔，落笔即关闭）。
**「对账基线（不是待办）」区新增 2 条（原文照写）：**
```
- **两层 Profile 字段命名两侧同批落笔**（2026-08-17）：客户端把集合字段名统一为单数并收口条目键名，本库同批改 `contracts/profile-sync.md` §5 白名单与排除清单四条路径 + 新增 §5b 命名通则与一次性切换的三个成立前提。**两侧无遗留欠账。**
- **球在对侧、本库无欠账的第三处：** 残卷 `ordinal` 的口径**两侧已对齐**——本库 §7 复算读的就是本次（自增后）的 `finaleWinOrdinal`，客户端侧的账号级 RNG 通则权威在 `game-design-documents/systems/common-properties.md`（本库不复述）。本次只在 §7 做了一句零风险的措辞消歧，**算法与 §6a 的 8 组测试向量未改**。**本库不重复设计、也不催办。**
```
其余分片无增删（已 grep 确认无跟踪透明路径命名或 `ordinal` 口径的条目）。

### 3c. `update-log.md` 摘要素材
- 答结 2 条：切换时序取 A（线上无真实账号数据 ⇒ 直接切、不写迁移、不设兼容期）· §7 复算的 `ordinal` 口径确按递增后的值 ⇒ 零改动关闭。
- 新增待答 0 条。
- 新落点：`contracts/profile-sync.md` **§5b** · §7 的 `ordinal` 口径消歧段。
- 跨库：与客户端 `2026-08-17-profile-field-schema` 同批落笔，两侧互相回链；`schemaVersion` 合并进客户端那一次 bump。
- 零改动核对：§6 算法与 §6a 的 8 组向量未被触碰。

### 3d. `answer-logs/_index.md` 新增行
```
| `log-profile-field-schema.md` | 2026-08-17 | `inbox/archive/solution-draft-profile-field-schema.md` → `handoffs/2026-08-17-profile-field-naming.md` | 2 |
```

### 3e. `inbox/_index.md` 与 `inbox/archive/_index.md`
- `inbox/_index.md`「在办清单」：删 `solution-draft-profile-field-schema.md` 行；表清空后保留 `*（空）*` 占位。
- `inbox/archive/_index.md`（表头 `| 草稿 | 对应 handoff | 日期 |`）新增：
```
| `solution-draft-profile-field-schema.md` | `handoffs/2026-08-17-profile-field-naming.md` | 2026-08-17 |
```

### 3f. 草稿 frontmatter
```yaml
status: distilled
reviewed: 2026-08-17 —— 2 项待决均已裁决：第 3 节切换时序取 A（线上无真实账号数据 ⇒ 直接切、不写迁移、不设兼容期，B 双读期不写）；残卷 ordinal 确认项确按递增后的值 ⇒ 零改动关闭，只做措辞消歧。合并 interview 另裁定：条目键名随客户端全族收口为 powerId；characterDiffs 属 diff 报文结构、不在单数通则约束面内，一格不动；§5 补命名通则并写明一次性切换的三个成立前提；算法与 §6a 的 8 组测试向量一字不动
distilled-to: handoffs/2026-08-17-profile-field-naming.md
```

## 4. answer-log
路径 `backend-design-documents/answer-logs/log-profile-field-schema.md`；**2 条** + 4 项连带落笔记录。与客户端同名 log 互为 counterpart，只记后端侧结论、回链客户端 log。

## 5. 落笔时的三处判断（orchestrator 过目）

1. **`envelope.md` §8 那一行一并改了。** 它是本库内唯一复述白名单路径的第二处；只改 `profile-sync.md` 会留下一处仍写 `playerPowers[*]/id` 的相反表述——正是「路径是契约的一部分」这条纪律要防的漂移形态。纯机械替换，无设计自由度。
2. **三个成立前提写成正面的成立条件**，未写「这是该纪律成文以来的第一次行使」（过程坐标）。承重理由（§7a 的处置语义使兼容期内的不一致永久不可见）以正面陈述保留在 §5b。
3. **`schemaVersion` 只写「须与客户端那一次 bump 同批」，不写具体数字。** 版本号的结构权威在客户端；§2 报文示例里的 `"schemaVersion": 7` 是示例值，未动。

## 6. 越界发现

1. `inbox/archive/solution-draft-profile-sync-contract.md` 第 110 / 111 / 115 / 116 行仍写旧的复数路径。归档草稿属过程档案，按纪律不改。
2. `handoffs/2026-08-14-profile-sync-contract.md` 第 35 行同样写着 `playerPowers[*]` 的 `id` 与 `sourceCode`。同属过程档案，未改。
3. `contracts/_index.md` 第 40 行的摘要未点名具体字段名，不受本次改名影响（已核对）。
4. `open-questions/cross-boundary.md` 的「对账基线」区在本次之后达 5 条，只增不减。日后可考虑下沉，归台账体积专场。
