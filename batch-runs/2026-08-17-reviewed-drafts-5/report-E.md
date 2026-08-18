# Phase B 报告 — 分片 E：solution-draft-draw-pool-and-instance-shapes（波次 5/6）

目标库：`game-design-documents/`。**未触碰后端库**（对侧承接归波次 6）。`answers.md` 的 E-R1 / E-R2 / E-R3 / E-O1 / E-O2 / E-O3 与草稿评审已裁六项全部照裁决落笔；第 2、6 项标 `[采纳推荐 — 待复核]`。前四波硬边界一律未碰。

## 1. 改动文件逐条清单

| 文件 | 改了什么 |
|---|---|
| `handoffs/2026-08-17-draw-pool-and-instance-shapes.md` | **新建**（`distilled`，列 16 份活文档）；Intent 五节 + Clarifications 六条 + Open questions 四条 |
| `systems/enemies/_index.md` | ① 字段表 `PoolScope` 行填类型与可空语义；② **新增 `PoolScope` 类型定义块 + `Matches` 语义 + 五条要点**；③ **新增「叠加而非替代」承重段**（含反查归 `LocationCodex` 的代价）；④ 取池伪码改 `PoolScope == null ||`，参数 → `activeArcIds`；⑤ 嵌套三条依据的第三条**整条重写**为「同一份定稿实例内只有一个落点」；⑥ 意图残留两处清理；⑦ 决策行补「池归属唯一权威 = `PoolScope`」；⑧ 待决区删 1 增 1 |
| `systems/enemies/common-properties.md` | ① 字段表填类型；② **新增「`PoolScope` 的加载期校验」整节**（四条表 + 三条说明，第四条明写只按 `EventType` 单维）；③ 图鉴措辞改「事前知识的主通道」；④ 待决区替换 1 条 |
| `systems/services/future-event-service.md` | ① `EventOption` 加第 13 格 `EncounterSpec Encounter`（前 12 格未动）；② **新增 `Encounter` 顶层形态段**；③ location 框定「三组字段」→「两组」并改写推论；④ 五旋钮管线「选池」→「框定」、产出行补嵌载；⑤ `PoolScope` 条补与门 / 集合 / 叠加口径；⑥ 图鉴措辞；⑦ Exchange 取池链补能力族走 `TryPickGrantableMany`；⑧ 待决区**删 1 增 1**（`PickMany` 不足 `count`） |
| `systems/architecture.md` | 总则 6 的 `EventOption` 副本加第 13 格，与 future-event-service **逐字一致**（已 grep 核对两处同文）。其余一字未动 |
| `systems/adventure-event/common-properties.md` | ① `PastEventEntry` 加 `EnemyTraceRef Enemy`，占位注释第二行换实字段说明、**保留第一行**；② 新增 `EnemyTraceRef` record；③ 新增「战斗类痕迹只存轻摘要」承重 bullet。**C 落的结算权威段未动** |
| `systems/services/combat-service.md` | ① 参战方字段行后新增两条 bullet：`enemyRef = EnemyInstance.InstanceId` + 读档经 `activeEvent.Option.Encounter.Enemy.InstanceId` 比对；战斗读到的敌人实例来自 `activeEvent.Option.Encounter.Enemy`（**只写主从指向**）；② `EncounterId` 冗余「写明的例外、不是先例」 |
| `systems/services/plot-manager.md` | ① `EnemyPoolScope` 注释改写为「一个 `PlotArcData.Id`，通常填本 arc 自己的 `Id`」；② **新增加载期悬空校验段 + 保留该权力的理由**。**六字段结构、「六字段」措辞、剧情线 boss 段、B 新增的落面判据段全部保留** |
| `systems/services/profile-service.md` | ① API 表新增 `TryPickReplacement`；② `GrantPoolPicker` 职责行（2 处）补「具名方法而非可空形参」理由。**`ResourceElements` / `EventStateChanges` / `Project(spec)` 一字未动** |
| `systems/services/content-service.md` | ① **新增「抽取原语只有两级」承重段**；② 调用方计数「三处」→ 五个已登记调用方 |
| `systems/services/life-cycle-service.md` | 残卷掷骰行改为显式 `ordinal = FinaleWinOrdinal + 1` 先算后写 + 回链 |
| `systems/common-properties.md` | 账号级 RNG 小节**新增「先算后写」通则**（含后端复算稳定误报的正面理由） |
| `systems/player-profile/player-power/_index.md` | 「只多传一个 `anchorRarity`」→ 具名方法 `TryPickReplacement`；掷骰行改「本次」口径 + 回链 |
| `systems/game-progression.md` | ① `LocationData` 删 `EnemyTemplateIds`（8 → 7 格）；② 三组字段 → 两组；③ 「硬分池只发生在敌人那一侧」**整条改写**为「两侧的框定都不是分池」+ 单权威理由；④ 「location 决定派谁来」→「当前 location 影响派谁来」 |
| `terminology.md` | location 词条：三组 → 两组，删「硬框定取池」，补「不持敌人清单」。**其余词条未动** |
| `systems/balance.md` | `GrantPoolWeights` 补**分表维度结构结论**（按用途，不按渠道 / 不按 `(Kind, Scope)`）。**不新增数值** |
| `systems/monetization.md` | `ordinal` 伪码行补一句回链（不复述） |
| `answer-logs/log-draw-pool-and-instance-shapes.md` | **新建**，3 条完整 + 1 条部分 + 连带 3 项 + 新增待答 3 条 |

**未触碰**：`sync-service.md` · `character-profile/_index.md` · 共享台账 · `inbox/` · 后端库。
溯源三条自查已跑（16 份）：新增文本零命中（grep 报出的「取代」全为「抽**取代**码」跨词假阳性）。

## 2. 台账素材

### 2a. `handoffs/_index.md` 新增行（置顶）
```
| [draw-pool-and-instance-shapes](2026-08-17-draw-pool-and-instance-shapes.md) | 2026-08-17 | 抽取原语与物化实例形态一次收口：抽取只有两级（`DrawPool<T>` + `GrantPoolPicker`，分界判据 = 这道过滤要不要读 `Profile`），门面补具名方法 `TryPickReplacement`，权重表按用途分表；账号级 `ordinal` 一律先算后写（后端复算据此对齐）；`PoolScope` = 两个具名可空字段的内嵌 `Resource`（与门 · 空维度恒真 · arc 一侧传全部 `Active` arc）+ 四条加载期校验；敌人池归属收归单权威（删 `LocationData.EnemyTemplateIds`，专属条目叠加而非替代，`PlotModulation.EnemyPoolScope` 保留 + 悬空校验）；`EventOption` 加第 13 格 `EncounterSpec Encounter`、`PastEventEntry` 加 `EnemyTraceRef` | distilled | `systems/enemies/_index.md` (+15) |
```

### 2b. `open-questions/`

**移出 3 条**：
- `01-combat.md`「一次合并收口的机会（非阻塞）」整条（附带消解一处悬空指路）。
- `01-combat.md`「`PoolScope` 的数据形态」整条。
- `02-event-options.md`「物化后敌人实例的类型形态（08-09c 新增）」整条。

**收窄 1 条** —— `01-combat.md`「`RarityTier` 的分布与权重表」整条替换为：
```
- **`RarityTier` 的分布与权重表（08-10c 新增）。** 五档已定名并挂上 `PowerData` / `ItemData` / `CardData`；**结构面已答定**——授予池权重表已给出结构与初值，置换候选池不需要权重表（同档等概率），分表维度按**用途**（授予 / 战后奖励）而非渠道、亦非 `(Kind, Scope)`。仍待定：**战后奖励池**各档权重（按优势档 `Tier` 三档各一张表）、内容侧「每档应有多少条目」的编排口径、`GrantPoolMargin` / `K` 的取值。→ `systems/balance.md`、`systems/services/combat-service.md`。
```

**新增 2 条（原文照写）** —— `01-combat.md`：
```
- **敌人池的篇章框定载体未定（08-17 新增 · 承重）。** 敌人取池的第三层写着「篇章框定照旧」，而 `EnemyData` 的字段面（`EncounterScopes` / `PoolScope` / `OverridesDeck`）没有任何一格表达篇章。载体定下之前，「通用池在某组合下为空 → 启动期 `PushError`」这条校验只能按 `EventType` 单维实现；它同时决定内容侧「一个敌人属于哪几章」写在哪。→ `systems/enemies/`、`systems/services/future-event-service.md`。
```
`02-event-options.md`：
```
- **`PickMany` 抽不足 `count` 时的调用侧处置未定（08-17 新增 · 轻）。** 契约那一侧已定（返回 false + `PushWarning`，不静默少给），但 Research 的法宝 / 功法候选与 Exchange 的库存两个调用点各需一个处置：少给几个槽位 / 商品位，还是另有兜底？两处都不能留空面板。→ `systems/adventure-event/research/common-properties.md`、`systems/adventure-event/exchange/_index.md`。
```

**`cross-boundary.md`（客户端侧）新增 1 条**（「球在对侧」形态）：
```
- **球在对侧的第二条：** 残卷 `ordinal` 的口径本库已明写为**本次（自增后）序号**（`systems/common-properties.md` 的账号级 RNG 通则 + `systems/services/life-cycle-service.md` 的显式先算后写）。对侧 `backend-design-documents/contracts/profile-sync.md` §7 ① 的复算输入与之一致，**两侧无需改动即认为已对齐**；后端侧同批留了一条确认性承接项与一处措辞消歧。本库不再跟踪，本条只作对账留痕。
```

### 2c. `update-log.md` 摘要素材
- 答结 3 条：统一抽取收口 · `PoolScope` 数据形态 · 物化后敌人实例类型形态。部分答定 1 条（`RarityTier` 只答结构面）。
- 连带答定：账号级 `ordinal` 先算后写 · 敌人池归属单权威（**叠加而非替代**）· `PlotModulation` 六字段保留 + 悬空校验 · `activeCombat.enemyRef` 定形 · 调用方计数订正为五处 · 门面补 `TryPickReplacement`。
- 新增 3 条：敌人池篇章框定载体 · `PickMany` 不足 `count` 处置 · 跨边界 `ordinal` 对齐留痕。
- 新落点：`enemies/_index.md` 的 `PoolScope` 类型块与「叠加而非替代」段；`enemies/common-properties.md` 的四条加载期校验节；`content-service.md` 的「抽取原语只有两级」段；`common-properties.md` 的 `ordinal` 通则；`future-event-service.md` 的 `Encounter` 形态段。
- 两个 `[采纳推荐 — 待复核]`：`PoolScope` 取具名可空字段的内嵌 `Resource` · Exchange 能力族商品走 `TryPickGrantableMany`。

### 2d. `answer-logs/_index.md` 新增行
```
| `log-draw-pool-and-instance-shapes.md` | 2026-08-17 | `inbox/archive/solution-draft-draw-pool-and-instance-shapes.md` → `handoffs/2026-08-17-draw-pool-and-instance-shapes.md` | 3 完整 + 1 部分 |
```

### 2e. `inbox/_index.md`
- 待处理表：删 `solution-draft-draw-pool-and-instance-shapes.md` 行。
- 已归档表新增：
```
| `solution-draft-draw-pool-and-instance-shapes.md` | solution-draft | 2026-08-17 | `handoffs/2026-08-17-draw-pool-and-instance-shapes.md` | `answer-logs/log-draw-pool-and-instance-shapes.md` |
```

### 2f. 草稿 frontmatter
```yaml
status: distilled
reviewed: 2026-08-17 —— 六项取向全部取推荐项（第 2、6 项标 [采纳推荐 — 待复核]）；合并 interview 另裁定：维持删除 LocationData.EnemyTemplateIds 并明写「地域 / arc 专属条目是叠加而非替代」（改写 game-progression 与 terminology 的两句承重表述）、推翻第 4 项的「删」——PlotModulation.EnemyPoolScope 保留且维持六字段、注释改写 + 新增加载期悬空校验、交叉校验第 4 条降为 EventType 单维并新增「敌人池篇章框定载体」待答、activeCombat.enemyRef = EnemyInstance.InstanceId（经 activeEvent 比对）、嵌套结论保留但依据重写 + 结算期以 activeEvent 为权威、对侧承接取「确认对齐 + 措辞消歧」
distilled-to: handoffs/2026-08-17-draw-pool-and-instance-shapes.md
```

## 3. 落笔时的三处判断（orchestrator 过目）

1. **「叠加而非替代」写成三处**（`enemies/_index.md` 承重段 + `game-progression.md` 镜像一句 + `future-event-service.md` 一句口径），三处都指回 `PoolScope` 一侧权威、不复述形态。理由：被删的「硬框定」措辞原本分散在这三份文档，只改一处会留下两处相反表述。
2. **`enemies/_index.md` 嵌套依据第三条整条替换**（而非追加）——它同时消化 E-O2 与「意图档位依据作废」，两者要改的是同一句；按溯源三条只保留理由的正面陈述，未写「原依据已作废」。
3. **`combat-service.md` 只写主从指向**，权威规则本体留在 C 落的 `adventure-event/common-properties.md`；读档校验措辞取「经 `activeEvent.Option.Encounter.Enemy.InstanceId` 比对」。

## 4. 越界发现

1. `enemies/_index.md`「不设硬限」vs `enemies/common-properties.md`「规模 15」矛盾，第三票在 `combat-service.md`（不设硬限）⇒ 两票对一票，「15」是孤例且带 `PushError` 语义。归 ch1 数值标杆专场。
2. `profile-service.md` 写 `PowerFragmentWinOrdinal`，全库其余处写 `FinaleWinOrdinal`——同一字段两个名字；且 `player-profile/_index.md` 的「当前库内只有 `FinaleWinOrdinal` 一个 `Ordinal`」在 `BundleGrantOrdinal` 存在后已不成立。
3. `architecture.md` 残留已删除的 `AdvanceMode`（B / C 均已点名，仍在）。
4. `.claude/knowledge/systems/*` 多处标「待建」，归 `/sync-knowledge`。

## 5. 交给波次 6（后端分片 F）

- **客户端侧 `ordinal` 通则的落点（供 F 回链）**：`game-design-documents/systems/common-properties.md` 的 `### Seeded RNG 派生（确定性）` 小节内、账号级那一段，条目开头为「**账号级授予一律用「本次」的序号掷骰（承重 · 两条渠道同款）**」。配套显式先算后写落在 `life-cycle-service.md` 的 Finale 结算段与 `player-power/_index.md` 的掷骰行；`monetization.md` 的伪码行已回链。
- F 需写的两件事：① 后端 `open-questions/cross-boundary.md` 的确认性承接项（回链上述客户端通则，**不复述客户端语义**）；② `contracts/profile-sync.md` 客户端伪码行把 `finaleWinOrdinal` 标注为「本次（自增后）序号」。
- **算法与 §6a 的 8 组测试向量本次零改动。**

## 6. 定向提问的回答

**分片 B 那条「条件移出」的前提已成立。** 缺口 B（`EncounterSpec` 承载）已由本分片答定落笔：两处 record 均已加第 13 格（逐字一致，已 grep 核对），配套校验、Explore 壳、`EncounterId` 例外、`enemyRef` 定形、`EnemyTraceRef` 全部就位。⇒ **`02-event-options.md` 的「`EventOption` 完整物化字段清单」按整条移出处理，不必收窄。** 该条移出记入分片 B 的 answer log。
