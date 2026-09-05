# ADR-0021 — `pastEvent` 的痕迹 schema：快照判据 + `PastEventEntry` + 未选项轻摘要

- **状态：** Accepted
- **日期：** 2026-08-09
- **来源：** handoffs/2026-08-09c-past-event-trace-schema.md · answer-logs/log-past-event-trace-schema.md

## 背景

`CharacterProfile.pastEvent` 有三个消费方（剧本调制、角色履历、诊断），却没有 schema。定稿实例已定为必须落存档（见 `decisions/ADR-0012-materialization-model.md`），但「痕迹要不要把定稿实例整份抄一遍」「未被选中的选项要不要留」都没有答案；而它同时约束存档 schema、同步粒度与剧本读取面。

## 决策

**① 判据先于字段表：「重算不出来的存，重算得出来的不存」。** 凡「模板 + `EventId` 在任意 `contentVersion` 下都能稳定重建」的不进快照；凡「由本次物化的情境 / seeded RNG / 当时角色状态决定」的必进快照。**判据本身是这条设计的权威，字段表只是它当下的投影。** 由它自动落定：**所有文本类字段一律留在模板侧，快照里一个字符串正文都不存**；物化产出的数值必进快照。完整口径是**「重算不出来且有消费方」**。

**② 痕迹条目 ≠ `EventOption`，而是「定稿实例快照 + 本次事件的最终账」。** `PastEventEntry` 的核心字段是 **`AppliedChange`**（复用既有 `ProfileChangeSpec`，不引入新类型）——它是一条可直接重放的账，语义为**本次事件的最终账**（收口那一次 + 事件内逐笔已提交的累加，见 `decisions/ADR-0020-event-transaction-discipline.md`）。

**③ 未被选中的选项 = 归档轻摘要**（`UnchosenOptionRef` 四字段：`InstanceId` / `EventId` / `EventType` / `Priority`）。**「定稿实例必须落存档」对未选项不成立**——它们在下一次整批重算时即被丢弃，永远不会被任何流程消费；它们不需要**可重建**，只需要**可回溯**。

**④ 战斗类痕迹只存敌人的轻摘要**（`EnemyTraceRef(EnemyId, Level)`），不存整份 `EnemyInstance`、不存 `DeckCardIds` / `ItemIds` / `PowerIds`。

字段表、`EventOutcome` 四值、`Seq` 的语义与读档校验见 `systems/adventure-event/common-properties.md`「`pastEvent` 的痕迹 schema」。

## 理由

- **一个事件的权威事实是这次事件总共发生了什么**，而非分散在 `ResolveOutcome` / `lifeSpanCost` / 隐藏属性推拉 / 逐笔消费里的若干片段——**存最终账一份，胜过存若干片段再让读取方自己合**。没有 `AppliedChange`，履历 / 剧本 / 诊断三个消费方各自去猜。
- **文案不进快照**保住了既有收益「文案改版不触发存档迁移」，也让「定稿实例必须落存档」与「存档态只带 `Id` + 可变状态」两条不相撞：后者管展示文本，前者管物化数值。
- **未选项归档轻摘要**（~240 B / 事件）：不归档则回避信号**永久丢掉**、日后想补要改 schema + 迁移；归档完整快照则体积翻数倍换零新增信息（多出的字段无消费方）。副产品是**批次的完整性得以保留**——`pastEvent` 成为一串批次而非一串孤立事件。
- **敌人轻摘要三条理由**：事件已结算，卡组 / 道具 / 法则三项永不会再被任何流程消费；它们是本作最胖的物化产物；三个消费方（EnemyCodex 遭遇即记 · 履历「这一步打了谁」· 诊断的越阶分布）要的都只是「打了谁、几级」。
- **`Seq` 显式写出来**才能在日志、履历展示与诊断中安全提及；「绝不用数组索引作内容的键」约束的是内容键，`Seq` 是时序坐标。

## 备选方案

- **不归档未选项** — 否决：回避信号永久丢掉。
- **归档未选项的完整快照** — 否决：体积翻数倍换零新增信息。
- **痕迹里存整份 `EnemyInstance`（含 `DeckCardIds`）** — 否决：最胖的物化产物 + 无消费方；日后若要做战斗回放，正确做法是给回放单独存一份，而不是让每条痕迹都胖一整副牌。
- **为 DnD 式选分支预留一个枚举成员** — 否决：分支形态未定时预留即臆造；日后若需要是**新增一个可空字段**（`ChosenBranchId`），因为枚举成员的增删牵动存档迁移、可空字段不牵动。

## 后果

- **`LifeSpanAfter` 是判据的明示例外**（可由 `AppliedChange` 全序列重放得出，但已在 `EventResolved` 负载里、且履历要画寿元曲线；成本 4 字节 × 200 条）。**它是写明的例外，不是先例**——不得据此放宽判据。
- **`EventType` 存、`combatTier` 不存**：前者存的是「当时呈现给玩家的口径」（Explore 时 = `Explore` 本身，模板重建不出来），后者一个内容条目只有一个档、查一次模板即得。
- **`Aborted` 是跳过通道移除后的直接产物**：支付 `selectCost` 后立即判负会短路，但这一步仍然发生过，必须留痕且与正常结算可区分。
- **`LocationId` 记「这一步发生在哪」，故 Travel 记出发地**，目的地由下一条痕迹自然给出。
- **`pastEvent` 与 AdventurePlot key points 零结构耦合**（互不引用），故两者的 schema 各自定稿、互不阻塞。
- `pastEvent` 的条目结构属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`。
- 影响文档：`systems/adventure-event/common-properties.md`（权威）· `systems/services/life-cycle-service.md`（组装方）· `systems/services/profile-service.md`（`TraceElements` 的施加与入口校验）· `systems/services/plot-manager.md`（只读输入）· `systems/services/sync-service.md`（只追加不变式与体积护栏）· `systems/architecture.md`（`TraceElements` 列）。
