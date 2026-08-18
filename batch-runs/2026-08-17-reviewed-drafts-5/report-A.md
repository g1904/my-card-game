# Phase B 报告 — 分片 A：solution-draft-profile-field-schema（波次 2/6）

目标库：`game-design-documents/`。**未触碰后端库**（归波次 6 分片 F）。`answers.md` 的 A-R1 / A-R2 / A-O1 / A-O2 / A-O4 与草稿评审已裁的 6 项全部照裁决落笔；A-O3（`ResourceElements` 三行）由 D 单写，本分片一字未动那张表。

## 1. 改动文件逐条清单

| 文件 | 改了什么 |
|---|---|
| `handoffs/2026-08-17-profile-field-schema.md` | **新建**（`distilled`，`distilled-to` 列 10 份活文档）；Intent 六节 + Clarifications 六条 + Open questions（2 个 `[采纳推荐 — 待复核]`） |
| `systems/character-profile/_index.md` | ① 字段罗列**整体替换**为 **`CharacterProfile` 完整字段表（23 行，只有形态列）** + **`Status` 子表（12 行）** + 三条表下纪律；② 新增五格新字段的形态代码块与六条正文（含读档校验口径）；③ `chapterRetry` 补 `Ch1/2/3RetryUsed` + `Used` 词缀理由；④ 括注 `currentMana` → `manaLimit`；⑤ 双 `contentVersion` 类型列 → **`int`**；⑥ rng 行名 `Rng.Streams[]` → `Rng.Stream[]`，片段 `CycleSeed` → `cycleSeed`、`streams` → `stream`；⑦ 待决区收窄为「隐藏属性是否还有第四项」 |
| `systems/player-profile/_index.md` | ① **`PlayerProfile` 完整字段表（15 行）** + 「不进 Profile 的三样」；② 六 Codex 具名字段 + `CodexEntry` 小节；③ 四类持有条目 record（键名 `powerId` / `itemId`）；④ **新增「集合字段名恒为单数，且这是一条跨边界通则」小节**（适用边界 / 跨边界理由 / 三条成立前提）；⑤ 命名硬约定补 `Used` 后缀；⑥ 待决区收窄 + 新增「六 Codex 计数字段」 |
| `systems/architecture.md` | ① `StatusFields` 补 `ChapterLifeSpanBudget → (Int, 0, null)`；② 枚举清单新增 `Realm`。**四个 spec / element 代码块一字未动** |
| `systems/services/sync-service.md` | ① 「存档 schema 版本」新增**本批统一 bump 段落**（5 行对象表 + 老档默认值口径 + 破坏性契约变更一句）；② 新增 `### JSON 序列化命名策略` 小节 |
| `systems/services/combat-service.md` | 参战方括注**拆开改写**：`manaLimit`（战斗内不变）· `currentMana`（回合内消耗量，决策点存档必须恢复） |
| `systems/services/life-cycle-service.md` | 两条字段罗列改为**回链**，消除第二权威 |
| `systems/services/profile-service.md` | 待决区「元进程字段结构」收窄。**`ResourceElements` 表未动** |
| `systems/player-profile/game-setting.md` | 补形态一条（具名类非字典）；两条待决项**一条未移出** |
| `systems/player-profile/achievement/_index.md` | 第 9 行改写：删「日后统一改为复数」的预言，改为「单数是全库通则（跨边界），本字段合规」 |
| `ux/screen-flow.md` | 主菜单表字段列五格改单数；权威指针改指 `player-profile/_index.md` 的完整字段表 |
| `answer-logs/log-profile-field-schema.md` | **新建**，10 条 |

溯源三条自查已跑（10 份活文档），无本次引入的违规。

## 2. 台账素材

### 2a. `handoffs/_index.md` 新增行（置顶）
```
| [profile-field-schema](2026-08-17-profile-field-schema.md) | 2026-08-17 | 两层 Profile 字段面一次收口：两张只有形态列的完整字段表（23 + 15 行）· `CharacterProfile` 补五格 · 六 Codex 具名字段与 `CodexEntry` · 四类持有条目 record（键名 `powerId` / `itemId`）· **集合字段名恒为单数**（跨边界通则，触发后端白名单改名）· `contentVersion` 统一 `int` · `currentMana` 移入 `activeCombat` · `Realm` 登记与 `StatusFields` 补行 | distilled | `systems/character-profile/_index.md` (+9) |
```

### 2b. `open-questions/`
**移出 0 条**（该问只登记在 derive 就绪度表与各主题文档待决区，后者已就地收窄）。**新增独立条目 0 条。**
**既有条目补一句**（`06-meta-progression.md`「角色模板池的形态」句末）：
```
**`CharacterProfile.characterDataId` 的字段形态已答定**（`string`，指向 `CharacterData.Id`，轮回创建时写一次不变，解析不到 → `PushError`）；本条只剩**内容侧取值面**。
```

### 2c. `update-log.md` 摘要素材
- 答结 10 条：两层完整字段结构 · 单数通则（含边界）· 键名收口 · `chapterRetry` 三字段名与 `Used` 词缀 · `contentVersion` 统一 `int` · `currentMana` 归属 · `Realm` + `StatusFields` 补行 · `schemaVersion` 不进 Profile + camelCase 单点策略 · `GameSetting` 形态。
- 新增 0 条；一处既有条目收窄。
- 新落点：两份 `_index.md` 的完整字段表 · `sync-service.md` 的统一 bump 段落 + 新命名策略小节。
- 跨库：单数改名与键名收口触发后端 §5 / §7 同批改（波次 6）。

### 2d. `answer-logs/_index.md` 新增行
```
| `log-profile-field-schema.md` | 2026-08-17 | `inbox/archive/solution-draft-profile-field-schema.md` → `handoffs/2026-08-17-profile-field-schema.md` | 10 |
```

### 2e. `inbox/_index.md`
- 待处理表：删 `solution-draft-profile-field-schema.md` 行。
- 已归档表新增：
```
| `solution-draft-profile-field-schema.md` | solution-draft | 2026-08-17 | `handoffs/2026-08-17-profile-field-schema.md` | `answer-logs/log-profile-field-schema.md` |
```

### 2f. 草稿 frontmatter
```yaml
status: distilled
reviewed: 2026-08-17 —— 6 项裁决（④ 为逆推荐：集合字段名改单数、改后端契约；③ 与 ⑥ 标 [采纳推荐 — 待复核]）；合并 interview 另裁定：单数通则边界 = 两层 Profile 及其子对象的存档字段名、条目键名同批收口为 powerId / itemId、rng 片段一并 camelCase、currentMana 移位连带修正 combat-service 措辞、角色集合字段取 characterProfile、后端 counterpart 同批落笔
distilled-to: handoffs/2026-08-17-profile-field-schema.md
```

## 3. 越界发现

1. `life-cycle-service.md` 待决区仍有「隐藏属性完整清单」，与 `character-profile/_index.md` 收窄后的同题条目并存（同一问两处登记）。
2. `content-service.md` 的双 `contentVersion` 表**只有语义列、无类型列**（草稿说的「两处字段表」不成立）；日后补类型列须写 `int`。
3. `terminology.md` 未登记 `Realm` 的英文枚举成员名。
4. `codex/common-properties.md` 的「待定字段清单」与新落的 `CodexEntry` 尚未互相回链。
5. `ux/screen-flow.md` 的储物袋「已耗尽」筛选 chip 依赖 `Charges == 0`，未在 ux 侧补回链。

## 4. 交给后续波次（勿重写）

### 4a. `CharacterProfile` 字段表 23 行（已落笔）
`id` · `characterDataId` · `status` · `defeatReason` · `chapter` · `realm` · `level` · `Status` · `jade` · `technique` · `looseCard` · `magicPack` · `characterPower` · `disabledAbility` · `pastEvent` · `plotKeyPoint` · `activeCombat` · **`eventOption`** · **`activeEvent`** · `chapterRetry` · `rng` · `startContentVersion` · `lastContentVersion`

- **分片 C：两行行位已预留**（第 18 / 19 行，字段名按单数写死）。现填：
  - `eventOption` | `EventOptionSave?`（形状 ⟨待定⟩） | `EventStateChanges` | `future-event-service.md`
  - `activeEvent` | ⟨待定⟩ | `EventStateChanges` | `future-event-service.md`
  - C **只改类型列**去掉 ⟨待定⟩，不重排表、不改字段名与通道列。
- `Status` 子表 12 行：`lifeTotal` · `manaLimit` · `experiencePoint` · `faith` · `maleficQi` · `lifeSpan` · `FaithBand` · `MaleficQiBand` · `LifeSpanBand` · `ChapterLifeSpanBudget` · `CurrentLocationId` · `LocationEventCount`。**`currentMana` 已删**，落 `activeCombat`。

### 4b. `PlayerProfile` 字段表 15 行（已落笔）
`accountInfo` · `characterProfile` · `playerPower` · `playerItem` · `achievement` · `enemyCodex` · `characterPowerCodex` · `playerPowerCodex` · `characterItemCodex` · `playerItemCodex` · `locationCodex` · `statistics` · `playerPowerFragment` · `entitlement` · `gameSetting`
（六 Codex 与 `gameSetting` 的写入通道列填 ⟨待定⟩，不臆造。）

### 4c. 单数通则的落点与边界（B / C / E / F 照此）
- 通则正文落 `player-profile/_index.md` 新小节；跨边界机械对应理由落 `sync-service.md` 的 `### JSON 序列化命名策略`。
- **受约束**：两层 Profile 及其子对象的存档字段名。**不受约束**：`characterDiffs` / `playerDiff`、`EventOptionBatch.Options`、`PlotNodeData.CharacterIds`。
- **分片 F 直接引用三条成立前提**（线上无真实账号数据 · 两侧同批落笔 · 一次性不设兼容期），措辞已对齐，勿另起说法。

### 4d. schema bump 统一段落（B / C / E 只补自己那一行的单元格，勿重建表）
位置：`sync-service.md` → `### 存档 schema 版本` → bullet「两层 Profile 的字段面收口 ⇒ bump 一次、一段迁移说明」下的 5 行对象表：

| 表内行 | 已写入 | 后续动作 |
|---|---|---|
| `ProfileChangeSpec` | 增两列 + `ChangeElement.Op` + `ElementSpec.AllowedOps` + `DeckChangeOp.AddLooseCard` | D 已完 |
| `CharacterProfile` | 五格新字段 + `eventOption` / `activeEvent` + 删 `currentMana` + `contentVersion` 改 `int` + rng camelCase | C 无需再补 |
| `PlayerProfile` | 六 Codex + 四类持有条目 + 键名 + 单数 | 已完 |
| `EventOption` | **增 `OutcomeSpec` 与 `Encounter` 两格** | B / E 核对即可 |
| `PastEventEntry` | **增 `EnemyTraceRef` 一格** | E 核对即可 |

表下两条 bullet 已写：老档默认值口径 · 改单数是破坏性契约变更 + 三条前提。
