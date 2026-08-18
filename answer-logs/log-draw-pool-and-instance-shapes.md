# Answer log draw-pool-and-instance-shapes

- 日期：2026-08-17
- 来源：`inbox/archive/solution-draft-draw-pool-and-instance-shapes.md` → `handoffs/2026-08-17k-draw-pool-and-instance-shapes.md`
- 移出条数：3 条完整 + 1 条部分

## 完整移出

**一次合并收口的机会（非阻塞）——三条渠道的候选池、排重规则与调用点参数化差异** → 抽取原语只有两级：`DrawPool<T>`（content-service，只认内容侧过滤）+ `GrantPoolPicker`（profile-service，读 `Profile` 的排重与稀有度锚定），分界判据 = 这道过滤需不需要读 `Profile`；不设第三级。排重发生在取池阶段而非掷骰之后 ⇒ 不存在「抽到重复怎么办」这个分支。门面补一个具名方法 `TryPickReplacement`（不给既有方法加可空 `anchorRarity` 形参）。权重表分表维度 = 按用途，不按渠道 / 不按 `(Kind, Scope)`。Exchange 的能力族商品走 `TryPickGrantableMany`、其余三族直用第一级。（归档去向：`systems/services/content-service.md` · `systems/services/profile-service.md` · `systems/player-profile/player-power/_index.md` · `systems/balance.md` · `systems/services/future-event-service.md`）

**`PoolScope` 的数据形态** → 带两个具名可空字段（`LocationId` / `PlotArcId`）的内嵌 `Resource`；匹配 = 逐维度与门、空维度恒真，arc 一侧传全部 `Active` arc 的集合；`EnemyData.PoolScope` 允许为 `null` = 通用池。加载期四条校验：两条悬空 `PushError`、空壳 `PushWarning`、某 `EventType` 下通用池为空 → 启动期 `PushError`。同批答定池归属的单权威归属：`LocationData.EnemyTemplateIds` 删除，地域 / arc 专属条目是**叠加而非替代**；`PlotModulation.EnemyPoolScope` 保留并加一条悬空校验。（归档去向：`systems/enemies/_index.md` · `systems/enemies/common-properties.md` · `systems/game-progression.md` · `systems/services/plot-manager.md` · `terminology.md`）

**物化后敌人实例的类型形态（08-09c）** → `EventOption` 加第 13 格可空 `EncounterSpec Encounter`，`EnemyInstance` 嵌其内（嵌一格而非平铺七格；`RunCombatAsync` 签名不动，不产生第二装配点）；校验按真身类型判，战斗真身的 Explore 壳其 `Encounter` 物化时即填好；`EncounterId` 与 `InstanceId` 的冗余写明为例外而非先例；`activeCombat.enemyRef` = `EnemyInstance.InstanceId`；`PastEventEntry` 加 `EnemyTraceRef(EnemyId, Level)`，不存卡组 / 道具 / power 三个列表。（归档去向：`systems/services/future-event-service.md` · `systems/services/combat-service.md` · `systems/adventure-event/common-properties.md` · `systems/enemies/_index.md` · `systems/architecture.md`）

## 部分移出

**`RarityTier` 的分布与权重表** → 本次只答**结构面**：分表维度按用途（授予 / 战后奖励），不按渠道、不按 `(Kind, Scope)`；权重表住 `systems/balance.md`、不落 `DrawPool<T>`。**数值仍待定**——战后奖励三表各档权重、内容侧每档条目数、`GrantPoolMargin` / `K` 取值，条目留在清单并收窄措辞。（归档去向：`systems/balance.md`）

## 连带答定（不单列条目，随上述一并落笔）

- 账号级授予的 `ordinal` 一律「先算后写」（先算 `旧值 + 1` → 掷骰 → 同一次 `TryApply` 写回），残卷侧补齐与礼包侧一致；对侧契约的复算输入据此对齐。
- 「敌人实例只有一份」的依据重写：嵌套让它在同一份定稿实例内只有一个落点，跨落点副本由既定快照语义统一管辖。
- `DrawPool<T>` 的调用方计数订正为五处。

## 本次新增的待答

- 敌人池的篇章框定载体未定（`EnemyData` 上无字段表达篇章）。
- `PickMany` 抽不足 `count` 时 Research 候选与 Exchange 库存的调用侧处置未定。
- 残卷 `ordinal` 口径待对侧确认（跨边界，两侧同名承接项互相回链）。
