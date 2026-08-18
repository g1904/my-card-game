# Answer log event-option-derived-persistence

- 日期：2026-08-17
- 来源：`inbox/archive/solution-draft-event-option-derived-persistence.md` → `handoffs/2026-08-17j-event-option-derived-persistence.md`
- 移出条数：1（另有 2 处主题文档内的重复登记一并删除）

**结算进行中的 `EventOption` 派生实例如何落存档（Explore 揭示 / Exchange 刷新）** → 承载 = `CharacterProfile.activeEvent`（新的可空块，持派生后的**整份**定稿实例 + `EventInstanceId`）；当前批另有具名载体 `CharacterProfile.eventOption`（可空，`EventOptionSave`，每次 `RefreshAfterEvent` 整块替换）；当批原实例一字不动。写入走 `ProfileChangeSpec.EventStateChanges` 新列（整块绝对置值 · 恒不经 modifier pipeline · `SelectCost` 内恒空）。读取权威：`activeEvent != null` 时结算一律读 `activeEvent.Option`。（`systems/character-profile/_index.md`、`systems/services/profile-service.md`、`systems/architecture.md`、`systems/adventure-event/common-properties.md`）

- **同一问题在两处主题文档的重复登记一并删除：** `systems/services/future-event-service.md`「待决问题」的「结算进行中的 `EventOption` 派生实例如何落存档」整条；`systems/adventure-event/exchange/_index.md`「待决问题」的「reroll 后的库存如何落存档」整条（Explore 与 Exchange 两侧同时收口）。

**本次一并答定的连带（不是独立待答项，随本条落笔）**

- **落盘时机** → 零新增决策点、零新增结算阶段：`activeEvent` 与 `SelectCost` 同一次 `TryApply` 创建（判负短路那一路由失败流程明写清理）；Explore 揭示随后续第一个决策点落盘（`[采纳推荐 — 待复核]`）；Exchange 刷新即时提交、`-jade` 与新库存同一次事务、push 走 `Debounced`、不计软阻塞闸门；`eventEnd` 收口置空并写入新一批。（`systems/services/life-cycle-service.md`、`systems/adventure-event/explore/_index.md`、`systems/adventure-event/exchange/_index.md`）
- **「一次提交 = 一次本地原子写」的粒度对位** → 提交即本地原子写，push 另计；「不新增存档点」在全库一律读作「不新增决策点 / 不新增存档点类型」，从不表示「这一次变更不落盘」。（`systems/services/sync-service.md`、`systems/adventure-event/common-properties.md`）
- **收口时的重算时序** → 新增只读投影 `profile-service.Project(spec)`：先算新一批、再一并提交，使「依更新后的 profile 重算」与「收口是一次事务、一个存档点」两条承重纪律同时成立；`RefreshAfterEvent` 可接受投影 profile。**投影设施的语义面仍待答**（见下）。（`systems/services/profile-service.md`、`systems/services/future-event-service.md`）
- **命名收口** → 字段 `eventOption` · 类型 `EventOptionSave` · 枚举成员 `EventStateKey.EventOption`，全链单数一致（草稿原写的 `eventOptions` / `EventOptionBatchSave` / `EventStateKey.EventOptionBatch` 三处不同拼法作废）。运行时的 `EventOptionBatch.Options` 不受单数通则约束，`EventOptionSave.Option` 作为存档子对象字段受约束。（`systems/character-profile/_index.md`）
- **「唯一出口」的松动** → 它管的是「物化」这一动作，不管已定稿实例的 `with` 派生；future-event-service 零改动，`Current { get; }` 收窄为内存视图。（`systems/services/future-event-service.md`、`systems/architecture.md` 总则 6）
- **痕迹侧零 schema 增量** → `PastEventEntry` 快照取自 `activeEvent.Option`；`ExchangeStock` / `RerolledCount` 收口后无消费方，按「重算不出来**且有消费方**」的完整口径不进痕迹。（`systems/adventure-event/common-properties.md`）
- **RNG 同事务不变式** → 「凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 必须在同一次原子写内更新」+ 一条恢复自校验（`[采纳推荐 — 待复核]`）。**写入通道形态仍待答**（见下）。（`systems/services/life-cycle-service.md`）
- **体积与同步** → 两个字段都挂 `CharacterProfile`，不新增同步单元；+1–8 KB / 事件，`sync-service.md` 中「估算随每批 eventOptions 数量答定需复核」那一句由本次给出复核结论并移除。（`systems/services/sync-service.md`）

**仍留在待答清单的部分**

- 只读投影 `Project(spec)` 的语义面（与 `Evaluate(spec)` 的复用关系、是否做钳制与终态判定、投影视图生命周期）。
- `activeCombat` 的写入通道未明写（形态与 `activeEvent` 相同却各走各的）。
- RNG 状态的写入通道形态（`Rng` 块目前没有任何 spec 列可落）。
- `pastEvent` 的追加同样没有 spec 列（第三处「有纪律、无通道」缺口）。
