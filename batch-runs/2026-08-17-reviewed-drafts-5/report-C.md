# Phase B 报告 — 分片 C：solution-draft-event-option-derived-persistence（波次 4/6）

目标库：`game-design-documents/`。未触碰后端库。`answers.md` 的 C-R1 / C-A1 / C-A2 / C-A3 / C-A4 与草稿评审已裁 5 项全部照裁决落笔；③ 与 ④ 标 `[采纳推荐 — 待复核]`。前三波硬边界一律未碰。

## 1. 改动文件逐条清单

| 文件 | 改了什么 |
|---|---|
| `handoffs/2026-08-17-event-option-derived-persistence.md` | **新建**（`distilled`，列 9 份活文档）；Intent 七节 + Clarifications 五条 + Open questions 五条 |
| `systems/architecture.md` | ① 共享核心类型**新增 `EventStateAssignment` record + `EventStateKey` 枚举**；② 分列语义补「事件态是整块绝对置值」；③ **新增 `EventStateChanges` 承重段**（六面判据 + 不用裸 `object` 的理由 + 恒不走 pipeline）；④ 总则 6 新增「`with` 派生不违反产出即定稿」一段；⑤ 总则 8 流程伪码三行改写。**7 列代码块 / `ChangeElement` / `ElementSpec` / `ResourceElements` / 三级判据段 / `Realm` / `PlotArcState` 一字未动** |
| `systems/character-profile/_index.md` | ① 字段表第 18 / 19 行**只改类型列**；② **新增「两个事件态字段」整节**（两个 record + 读取权威 + 三条否决理由 + 生命周期 + **7 条读档校验表** + 恢复路径 + 痕迹侧零增量）。**字段表未重排，`Status` 子表未动** |
| `systems/services/profile-service.md` | ① 失败语义表**新增 4 行**；② **新增「事件态经 `EventStateChanges` 写入」承重小节**；③ **新增「只读投影 `Project(spec)`」承重小节**；④ API 表新增 `Project` 一行；⑤ 待决区新增 4 条。**`ResourceElements` 表一字未动** |
| `systems/services/future-event-service.md` | ① 物化小节新增两条 bullet（批的权威在 `CharacterProfile.eventOption` · 「唯一出口」松动明写）；② 重算依据段补「更新后」硬要求 + 投影调用顺序；③ API 表补「可接受投影 profile」；④ 待决区**删 1 条**。`EventOption` record 12 格未动 |
| `systems/adventure-event/common-properties.md` | ① 结算伪码同步改写；② **新增「结算期间的读取权威是 `activeEvent`」承重段**；③ 事务纪律：收口并入两条置值 + 投影一句、事件内部「三个实例」→**四个**、**新增「一次提交即一次本地原子写」**；④ `pastEvent` 判据新增一条 bullet。`PastEventEntry` record 与占位注释**未动**（留给 E） |
| `systems/adventure-event/explore/_index.md` | ① 揭示伪码加一行 `TryApply(EventStateChanges[...])`；② 「字段保留」理由句改写为指向 `activeEvent.Option`；③ 新增 bullet：不新增决策点 / 存档点类型但本地写照常发生 |
| `systems/adventure-event/exchange/_index.md` | ① 刷新段新增三条（`-jade` 与新库存同一次 `TryApply` + 两方向破裂后果 · `Shop` 子流同事务不变式 · 恢复即读结果）；② 待决区**删 1 条** |
| `systems/services/life-cycle-service.md` | ① `AdvanceEventAsync` 伪码改写（+5 行）；② 新增「两个事件态字段由本服务组装写入」bullet；③ **新增 RNG 同事务不变式 bullet**；④ 待决区新增 2 条 |
| `systems/services/sync-service.md` | ① **新增「commit 与 push 的粒度对位」承重 bullet**；② 体积段给出复核结论（+1–8 KB / 事件、不新增同步单元）。**统一 bump 段落与 5 行表一字未动** |
| `answer-logs/log-event-option-derived-persistence.md` | **新建**，1 条移出 + 7 条连带 + 4 条剩余待答 |

**未触碰**：`combat-service.md`（守 ②-a）· `terminology.md` · 共享台账 · `open-questions*` · `inbox/`。溯源三条自查已跑，新增文本零命中。

## 2. 台账素材

### 2a. `handoffs/_index.md` 新增行（置顶）
```
| [event-option-derived-persistence](2026-08-17-event-option-derived-persistence.md) | 2026-08-17 | 结算中的 `EventOption` 派生实例一次收口：承载 = 新可空块 `CharacterProfile.activeEvent`（整份派生快照）+ 当前批具名载体 `CharacterProfile.eventOption`，当批原实例不动；写入走 `ProfileChangeSpec.EventStateChanges`（整块绝对置值 · 恒不走 pipeline · `SelectCost` 内恒空）；零新增决策点 / 存档点类型，刷新那一笔 `-jade` 与新库存同事务；新增只读投影 `Project(spec)` 使「依更新后 profile 重算」与「收口是一次事务」并存；连带落 RNG 同事务不变式与 7 条读档校验 | distilled | `systems/character-profile/_index.md` (+8) |
```

### 2b. `open-questions/`

**移出 1 条 —— `02-event-options.md`「结算进行中的 `EventOption` 派生实例如何落存档（承重）」整条删除**（Explore 与 Exchange 两侧同时收口）。

**新增 4 条（原文照写）** —— 落 `02-event-options.md`：
```
- **收口时的只读投影设施形态（08-17 新增 · 承重）。** `profile-service.Project(spec)` 已定为「施加 spec 得到一份未提交的只读视图，供 `RefreshAfterEvent` 依更新后的 profile 重算新一批」，但语义面未定：它与 `Evaluate(spec)` 能否复用同一段施加代码 · 投影是否同样做钳制与终态判定（若做，一份「已判负」的投影交给重算方意味着什么）· 投影视图的生命周期（一次性值还是可缓存）。它是「收口是一次事务、一个存档点」与「重算依据是更新后的历程」两条承重纪律并存的唯一支点。→ `systems/services/profile-service.md`、`systems/services/life-cycle-service.md`。
```
落 `05-service-contracts.md`：
```
- **`activeCombat` 的写入通道未明写（08-17 新增 · 承重）。** `activeEvent` 已定走 `ProfileChangeSpec.EventStateChanges`（整块绝对置值），而形态完全相同的 `activeCombat` 至今没有任何列可落、写入路径来路不明 ⇒ 两个同形的事件内中间态各长一套写入纪律。现成方案是把它收进同一列，范围落在战斗存档段，本轮明确不动。→ `systems/services/combat-service.md`、`systems/services/profile-service.md`。
- **RNG 状态的写入通道形态未定（08-17 新增 · 承重）。** 已落不变式「凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 必须在同一次原子写内更新」+ 一条恢复自校验，但 `Rng` 块目前没有任何 `ProfileChangeSpec` 列可落 ⇒ 该不变式暂由组装方自律兑现、无机械保证。是否纳入 `EventStateChanges` / 另开一列，牵动 `activeCombat` 与四条子流的全部写入点。→ `systems/services/life-cycle-service.md`、`systems/services/profile-service.md`。
- **`pastEvent` 的追加同样没有 `ProfileChangeSpec` 列（08-17 新增 · 承重）。** `profile-service.md` 明写「`pastEvent` 写入经 life-cycle-service 组装 → `ProfileManager`」，但各列里没有一列装得下 `PastEventEntry`，而结算流程把「记入 pastEvent」画在收口那次 `TryApply` 之外。这是与 `activeCombat` 同类的第三处「有纪律、无通道」缺口。→ `systems/services/profile-service.md`、`systems/adventure-event/common-properties.md`。
```
> 后三条已同时写进相应主题文档的待决区（`profile-service.md` 4 条 / `life-cycle-service.md` 2 条）。

### 2c. `update-log.md` 摘要素材
- 答结 1 条（派生实例落存档，整条关闭）。
- 连带答定 7 项：承载形态 · 写入通道 · 落盘时机 · commit/push 粒度对位 · 收口先投影后提交 · 命名全链单数 · 痕迹侧零 schema 增量。
- 新增 4 条（投影设施形态 · `activeCombat` 写入通道 · RNG 写入通道 · `pastEvent` 无 spec 列）。
- 新落点：`character-profile/_index.md` 的「两个事件态字段」整节 + 7 条读档校验表；`profile-service.md` 的 `EventStateChanges` 段与 `Project(spec)` 段；`architecture.md` 的两个新类型；`sync-service.md` 的 commit/push 粒度对位。
- 两个 `[采纳推荐 — 待复核]`：Explore 揭示不新增独立存档点 · RNG 只落不变式不落形态。

### 2d. `answer-logs/_index.md` 新增行
```
| `log-event-option-derived-persistence.md` | 2026-08-17 | `inbox/archive/solution-draft-event-option-derived-persistence.md` → `handoffs/2026-08-17-event-option-derived-persistence.md` | 1 |
```

### 2e. `inbox/_index.md`
- 待处理表：删 `solution-draft-event-option-derived-persistence.md` 行。
- 已归档表新增：
```
| `solution-draft-event-option-derived-persistence.md` | solution-draft | 2026-08-17 | `handoffs/2026-08-17-event-option-derived-persistence.md` | `answer-logs/log-event-option-derived-persistence.md` |
```

### 2f. 草稿 frontmatter
```yaml
status: distilled
reviewed: 2026-08-17 —— 五项裁决全部取推荐项（③ 揭示不新增存档点 与 ④ RNG 只落不变式 标 [采纳推荐 — 待复核]；⑤ 命名与草稿的复数形态相反，按单数落笔）；合并 interview 另裁定：新增只读投影 Project(spec) 先算后提交（两条承重纪律都不改写）、当前批载体可空、activeEvent 与 SelectCost 同一次 TryApply 创建且判负那一路由失败流程清理、提交即本地原子写（措辞校正为「不新增决策点 / 不新增存档点类型」）、全链单数一致
distilled-to: handoffs/2026-08-17-event-option-derived-persistence.md
```

## 3. 落笔时的两处判断（orchestrator 过目）

1. **`EventStateAssignment` 的两个载荷格取名 `ActiveEvent` / `EventOption`**，与 `EventStateKey` 成员一一对应（不用草稿的 `Batch`，避免把已被 C-A4 移除的 "Batch" 拼法带回来）。副产品：「`Key` 与哪一格有效」成为可机械核对的一条。
2. **`EventOptionSave` 的集合字段取单数 `Option`。** 依据 A 落笔的单数通则边界——两层 Profile 及其子对象的存档字段名受约束，而 `EventOptionBatch.Options` 是运行时属性、明列在不受约束的两类里。两者拼法不同是通则的直接后果、不是漏改；已在 answer-log 写明。

## 4. 越界发现

1. `profile-service.md`「与其他服务的关系」仍写 `future-event-service`（key points 推进）是上游写入方——实际推进方是 PlotManager，且本次答定后 future-event-service 明确**零写入面**。既有漂移。
2. `profile-service.md` 待决区首条括注仍写「隐藏属性推拉？」（D 与 B 都已点名）。
3. `sync-service.md` 的软阻塞闸门条文本身没有一句「事件内提交不计」。
4. `architecture.md` 第 ~493 行残留已删除的 `AdvanceMode`（B 已点名）。
5. `.claude/knowledge/systems/*` 多处标「待建」，归 `/sync-knowledge`。

## 5. 交给波次 5（分片 E）

### 5a. `activeEvent` 的最终 record 形态（已落笔 · 勿重写）
落 `character-profile/_index.md`「两个事件态字段」小节：
```csharp
EventOptionSave?  eventOption;   // null = 尚无批次（StartCycle 之前 / 老档迁移）
ActiveEventState? activeEvent;   // null = 当前没有事件在结算

public sealed record EventOptionSave(
    string                     BatchId,
    IReadOnlyList<EventOption> Option,             // 本批定稿实例，1–5 项
    int                        EffectivePriority); // 0 或 1

public sealed record ActiveEventState(
    string      EventInstanceId,
    EventOption Option);
```
spec 侧（`architecture.md` 共享核心类型）：
```csharp
public readonly record struct EventStateAssignment(
    EventStateKey     Key,
    ActiveEventState? ActiveEvent,
    EventOptionSave?  EventOption);
public enum EventStateKey { ActiveEvent, EventOption }
```
**E 无需改动以上任何一处** —— 承载是整份 `EventOption` 快照，对字段增删完全中立；E 加第 13 格后 `activeEvent.Option` 自动带上它。

### 5b. 「结算期以 `activeEvent` 为权威」的落点
**权威落点：`adventure-event/common-properties.md`「结算阶段」小节紧跟固定流程伪码之后**。另有三处以**回链**形态出现（`character-profile/_index.md` 首条 bullet；`life-cycle-service.md` 与 `architecture.md` 总则 8 伪码的 `resolver.ResolveAsync(activeEvent.Option, ct)`）——**E 不必也不应在第五处复述**。

E-O1 / E-O2 的对齐要点：
- `EnemyInstance` 嵌在 `EventOption.Encounter` 内 ⇒ 随 `activeEvent.Option` 整份复制一次。**E 在 `combat-service.md` 侧只写「战斗读到的敌人实例来自 `activeEvent.Option.Encounter.Enemy`」这一主从指向，不重述权威规则本身。**
- 本片读档校验第 6 条已是 `activeCombat != null ⇒ activeCombat.eventInstanceId == activeEvent.EventInstanceId`。E 补 `enemyRef` 悬空校验时**措辞取「经 `activeEvent.Option.Encounter.Enemy.InstanceId` 比对」**，不要写「反查当前批」——两者同值，但读取权威只有一处，写「反查当前批」会形成两条读取路径。
- **体积段**：`sync-service.md` 已按「`Encounter` 内嵌 `EnemyInstance` 后进一步上抬」写入，E 无需再改。
- **bump 表**：`EventOption` 行已含 E 那一半，`CharacterProfile` 行已含本片两字段，E 两处都无需再补。
