# S5 报告 — 抽取原语与实例形态

> worker 的报告文件写入被 harness 拦截，内容由 orchestrator 代为落盘（原文照录）。草稿文件本身已写入。

- library: `game-design-documents`（三条问题均为客户端侧，无跨边界一半 ⇒ 未在后端库落任何文件）
- 分片 S5 · slug `draw-pool-and-instance-shapes`

## 草稿文件

`game-design-documents/inbox/solution-draft-draw-pool-and-instance-shapes.md`（唯一写入的文件；未写任何台账 / 主题文档 / ADR / handoff / 代码）

## inbox/_index.md 待处理表应追加的行
（worker 按技能正文五列给出；⚠ 实际表头三列，orchestrator 落笔时改写）
```
| `solution-draft-draw-pool-and-instance-shapes.md` | solution-draft | 2026-08-17 | 统一抽取原语（残卷 / 礼包 / 置换共用一段伪码）· `PoolScope` 数据形态 · 物化后 `EnemyInstance` 的类型落位 | 评审 6 项取向后 /analyze-new-ideas |
```

## 依据构成

**既有推演 14 项 · 通行做法 0 项 · 取向选择 6 项**

通行做法为 0 是如实结果而非遗漏：三条问题全是本库内部的类型与算法收口，同类作品在这三处没有可迁移的公开形态，而既有决策已把解空间压得很窄。

## 建议要点（逐条对应三个子问题）

**子问题 1 · 统一抽取形态**

1. **原语只有两级，不新增第三级**：`DrawPool<T>`（content-service，语言层唯一抽取入口）+ `GrantPoolPicker`（profile-service `internal`，能力条目专用）。**分界判据 = 这道过滤需不需要读 `Profile`**——同时解释了为什么其余三个 `DrawPool<T>` 调用方不经第二级。
2. **唯一那段伪码 = 照抄 `player-power/_index.md` 的既定取池链**，只把 `anchorRarity` / `rng` / `count` 三个参数化点标出。排重语义三条（排重在取池阶段 ⇒ 不存在「抽到重复」分支）、空池行为按渠道六档、稀有度权重接入点唯一。
3. **分表维度：按「用途」分表（授予一张 / 战后奖励三张），不按渠道、不按 `(Kind, Scope)`。**
4. **门面缺一个方法**：置换要传 `anchorRarity`，profile-service 的四个方法都没有该形参。建议补**具名方法** `TryPickReplacement<TRng>(kind, scope, RarityTier anchorRarity, rng, out pickedId)`——不用可空重载，因为可空默认值会让「忘了锚定」成为最短路径，而漏锚定 = Tier1 换 Tier5，能上线且线上不可见。
5. **`ordinal` 先算后写**：账号级两渠道统一「先算 `ordinal = 旧值 + 1` → 掷骰 → 同一次 `TryApply` 写回」。礼包侧已明写，**残卷侧未明写**——这是一处会在**每个正常账号上稳定误报**的缺口。
6. **调用点参数化差异表共 9 行**（残卷 / 礼包①② / 置换 / Research 法宝·功法 / Exchange 库存 / 战后奖励 / 敌人物化），逐列给出是否经第二级、`(Kind,Scope)`、`count`、锚定、加权表、rng、空池处置、授予 `Source`。

**子问题 2 · `PoolScope`**

7. **取具名可空字段的内嵌 `Resource`（形态 A），否决 tag。** 承重理由：**tag 丢类型 ⇒ 既定的悬空校验根本写不出来**，或需一张不可机械校验的「前缀→仓储」约定表；且维度封闭（`PlotModulation` 六字段已封死剧本侧权力面），tag 的唯一优势不存在。
8. **命名修正（承重）：本库没有 `PlotLine` 这个类型**——剧情线的载体是 `PlotArcData`。字段应定名 **`PlotArcId`**，否则它将是全库唯一一个指向不存在类型的 `Id` 字段名。
9. **匹配语义 = 逐维度与门、空维度恒真；剧情线一侧传的是「全部 `Active` arc 的集合」而非单值**（`MaxConcurrentSideArcs` 允许并发）。不写出来，实现会取主线那一条并让 side arc 的专属敌人永不出现。
10. **交叉校验六条**，含一条新提且为三层框定叠加所必然：**通用敌人池在某 `(EventType, 篇章)` 组合下为空 → 启动期 `PushError`**（否则既定的「内容池为空 → 抛」会在玩家进程里炸）。

**子问题 3 · `EnemyInstance`**

11. **这一问已在别处答定**（`answer-logs/log-combat-solutions.md` 第 8 条 + `systems/enemies/_index.md` 的 `## 决策(-> ADR)`）。**清单与 `future-event-service.md` 没跟上**，后者仍列为待决。
12. **真正未定的是字段级形态**：`EventOption` 的 record 上没有任何承载敌人的字段，而 `EncounterSpec.Enemy` 恒非空、`EncounterSpec` 另外六个字段也全是物化产物 ⇒ **问题的准确形态是「战斗类 `EventOption` 如何承载整份 `EncounterSpec`」**。
13. **推荐：加一个可空 `EncounterSpec Encounter`，`EnemyInstance` 嵌其内**（加 1 字段 vs 平铺 7；单一副本；`RunCombatAsync` 签名不动、无第二装配点）。配套：**真身为战斗类的 Explore 壳其 `Encounter` 在物化时即填好**（同 `DestinationLocationId` 的既定处置，依据同为防重掷）；校验按**真身类型**判。
14. **`PastEventEntry` 加轻摘要 `EnemyTraceRef(string EnemyId, int Level)`**，不存 `DeckCardIds`/`ItemIds`/`PowerIds`（已结算、永不再消费 + `pastEvent` 已有体积护栏）。

## 仍需用户决定（6 项）

**1. 🔴 `PoolScope` 与 `LocationData.EnemyTemplateIds` 的权威归属。** 本库两处表达同一关系（location ↔ 敌人池），无任何机制发现不一致：`LocationData.EnemyTemplateIds`（已进 `terminology.md` 词条）与 `EnemyData.PoolScope`（取池伪码 `.Matches(currentLocationId, …)`）。
- **A（推荐）** `PoolScope` 唯一权威，删 `EnemyTemplateIds`：三层框定成一段统一 `Where` 链；加一条通用敌人到某地域**零改动**；作用域与敌人条目同侧。代价：需反查（本是 `LocationCodex` 职责）；改 `game-progression.md` + `terminology.md`（三组字段变两组）。
- **B** `EnemyTemplateIds` 唯一权威，`PoolScope` 只留 `PlotArcId`：location 自解释。代价：加通用敌人要改 N 份 location；两个同性质维度分居两侧。
- **C** 两侧都留 + 主从 + 双向校验。代价：「两份表 + 一条校验」正是本库反复否决的形态。
- **此项优先于第 2 项**——B 会让 `PoolScope` 退化为单字段。

**2. `PoolScope` 形态：具名可空字段（推荐 A）vs tag（B，丢类型 ⇒ 校验写不出）**；并确认 `PlotArcId` 命名与「集合匹配」。

**3. 战斗类 `EventOption` 的敌人承载：A（推荐）嵌 `EncounterSpec` vs B 平铺 7 字段**（B 会产生第二装配点，撞既定封死项）。

**4. `PlotModulation.EnemyPoolScope` 是否删除。** 删（推荐）= 改为隐式取当前 arc 的 `Id`；当前形态允许一条 arc 框定另一条 arc 的池，无用例且与既定判据相悖。代价：六字段变五，而那六字段被明写为「逐条投影、不多一个字段」⇒ 删一个 = 收窄已宣告的权力面。

**5. 🟠 残卷侧 `ordinal` 口径确认。** 统一为「本次序号」。请确认是「补写既有意图」（纯客户端落笔）还是需通知对侧库（`backend-design-documents/contracts/profile-sync.md` §7 三条校验）。

**6. Exchange 能力族商品的排重走哪一级。** A（推荐）能力族走 `TryPickGrantableMany`、其余三族直用第一级（不新增入口）；B 给 picker 加「按 `RarityFilter` 取多条」入口（写法统一但入口变多）。

## 与既有决策的张力

1. 🔴 待决 1 那处**已落笔的第二权威**——不裁决就落笔会固化进内容层，届时改法从「改两份文档」退化为「改 N 份 `.tres`」。
2. `future-event-service.md`（未定）与 `enemies/_index.md`（已进决策）**对同一问题给出相反状态**；落笔动作归 `/analyze-new-ideas`。
3. 删 `EnemyPoolScope` = 收窄一个被明写为「不多一个字段」的权力面。
4. `EncounterSpec.EncounterId` 在嵌套下冗余——建议保留但须像 `LifeSpanAfter` 那样**明写为例外而非先例**。
5. 残卷 `ordinal` 缺口触及一条已冻结的客户端 ↔ 后端契约。

## 前置依赖

`RarityTier` 权重数值 / `GrantPoolMargin` / `K` / 战后奖励三表 / 敌人卡组改写算子 → ch1 专场，**均不阻塞结构面**。`content/enemy/` 尚未开张 ⇒ 此刻是纯加法窗口，与 `DrawPool<T>` / `LocalizedText` 排期理由同构。

## 与 S1 / S2 / S3 的交界

- **S2**：只主张**加一个** `Encounter` 字段，不主张其余任何字段。**假设 S2 不主张平铺敌人字段；若它主张，两侧矛盾，须一次合并裁决**。
- **S3**：`Encounter` 嵌在 `EventOption` 上 ⇒ 任何 `with { … }` 派生**连带复制最胖载荷**。未替 S3 定承载形态；**S3 若选「另有承载」，须明确 `Encounter` 是否随派生一起搬**。
- **S1**：`PastEventEntry.Enemy` 落 `CharacterProfile.pastEvent`；**建议与 S2/S3 合并进同一次 schema bump**（三者都动 `EventOption`）。未替 S1 定 bump 编排、未动任何 `PlayerProfile` 字段（只在 `FinaleWinOrdinal` 的**语义**上提一条口径确认）。

## 越界发现（未处理）

1. `enemies/_index.md`（「规模逐条编排、**不设硬限**」）与 `common-properties.md`（「**规模 15**」+ `PushError`）**对样本卡组规模自相矛盾**。
2. `enemies/_index.md` 有**三处意图机制残留**（08-15d 已整条移除）。**第三处尤其要紧——「意图档位在进入战斗前即需可算」是「`EnemyInstance` 嵌在 `EventOption` 上」的三条依据之一，依据本身已作废**（另两条仍成立，结论不变，理由要重写）。
3. `enemies/` 两份文档都写「图鉴在意图黑箱档位下是唯一的信息来源」——应改为「图鉴是事前知识的主通道」。
4. `EnemyTemplateId`（清单措辞）与 `EnemyId`（record 实际字段名）指同一个东西，宜统一为后者。
5. `content-service.md` 的 `DrawPool<T>` 「共五处调用方」与本草稿九行调用点表口径不同（后者把同宿主内不同渠道拆开数）。不是矛盾，但宜落笔时统一，否则「五处」这个数会随下次拆分失真。
