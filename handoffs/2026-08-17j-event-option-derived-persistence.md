# 结算进行中的 `EventOption` 派生实例：承载、写入通道与落盘时机

- id: 2026-08-17j-event-option-derived-persistence
- date: 2026-08-17
- topic: systems/character-profile/_index.md · systems/services/profile-service.md · systems/services/future-event-service.md · systems/adventure-event/common-properties.md · systems/adventure-event/explore/ · systems/adventure-event/exchange/ · systems/services/life-cycle-service.md · systems/services/sync-service.md · systems/architecture.md
- status: distilled
- distilled-to: systems/character-profile/_index.md, systems/services/profile-service.md, systems/architecture.md, systems/services/future-event-service.md, systems/adventure-event/common-properties.md, systems/adventure-event/explore/_index.md, systems/adventure-event/exchange/_index.md, systems/services/life-cycle-service.md, systems/services/sync-service.md

## Intent（distilled）

`EventOption` 是「产出即定稿、不得回查模板重算、不得改写其字段」的实例，而结算进行中有**两处**会派生它：Explore 揭示（`IsRevealed = true`）与 Exchange 刷新（新 `ExchangeStock` + `RerolledCount + 1`）。两处都必须在玩家可退出之前落盘，否则退出重进即可重看一次揭示、或把刷新价按回起点再刷一次。缺口有三层：派生实例住在哪 · 当前批本身住在哪 · 写入走哪条通道。本次一次答齐。

### 1. 当前批的具名载体：`CharacterProfile.eventOption`（可空）

「当前批落存档」本是定案，缺的只是字段。它登记为与 `pastEvent` / `activeCombat` / `disabledAbility` / `plotKeyPoint` 平级的一格，**可空**——`null` = 尚无批次（`StartCycle` 之前 / 老档迁移）。可空而非「写一个空 `Option` 的哨兵批」：哨兵批要制造一个语义上不存在的 `BatchId`，且 `EffectivePriority` 无意义；也不在迁移里现场重算一批（迁移只做结构搬运，不掷 map 子流、不读内容注册表）。

批**整块替换、不做增量**，与「批次刷新只有一种形态：整批重算」「本服务不持有跨批次状态」同构。

### 2. 派生实例的承载：`CharacterProfile.activeEvent`（新的可空块）

形状逐条搬 `ActiveCombat` 先例：挂 `CharacterProfile` 的可空块 · 带 `eventInstanceId` 供读档交叉校验 · 收口置空 · 不进 `pastEvent` · 不新增同步单元。当前批里那份原实例**一字不动**。

一条读取规则收口全部歧义：**`activeEvent != null` 时，本次结算涉及的 `EventOption` 一律读 `activeEvent.option`**；批中的原实例只用于呈现尚未开始的选项与组装 `Unchosen` 轻摘要。

否决的三条替代及其理由（理由承重，否则会被重新提出）：**原地替换当批实例**要正面改写两处「原实例不动」的明文，并给「无记忆的纯产出侧」装上一个运行时写入面，且把「有事件在结算」这个态藏进批里、读档时无法一次判空；**只存派生增量的散字段**每新增一个可派生字段就要加一个散字段，而存整份快照对字段增删完全中立；**派生态不落存档、退出即回滚并退还刷新费**与「`SelectCost` 不回滚、已经发生的事就是发生了」正面冲突，且 Explore 一侧根本无法回滚——真身已被看见，回滚只是让他免费看一次。

`activeEvent` 与 `activeCombat` **并存不合并**：前者是事件级中间态，后者是战斗状态机的中间态；硬约束 `activeCombat != null ⇒ 两者的 eventInstanceId 相等`，落读档校验。

### 3. 写入通道：`ProfileChangeSpec` 的 `EventStateChanges` 列

最硬的约束来自 Exchange 刷新的原子性：`-jade` 与「新库存 + `RerolledCount`」必须落在**同一次** `TryApply`。两个方向的破裂都是可利用的漏洞——只落 `-jade` 则同一笔钱可再刷一次，只落库存则免费刷新。`Elements` 只装带符号的量、`StatusChanges` 的值是标量或 id，都装不下一个结构块，故按三级判据的 ① 分列。

语义 = **绝对置值**（组装方先算好整块再置入，`ProfileManager` 不做合并 / 增量）· **恒不经 modifier pipeline** · **`SelectCost` 内恒空**（独立成行的断言，不与 `AbilityElements` / `DeckElements` 合并成通则）。载荷落成两个具名可空字段而非裸 `object`，与 `StatusAssignment` 的「双字段单列表、另一格填缺省」同构。

组装方 = life-cycle-service；`activeCombat` **不**收进这一列（那要动战斗存档段，超出本问题范围，作为一条待答留下）。

### 4. 落盘时机：零新增决策点、零新增结算阶段

- **`activeEvent` 的创建并入 `TryApply(SelectCost)` 那一次**——「这一项已被选中」与支付落在同一笔最贴合，零新增提交。代价明写：判负短路那一路会留下一个非 `null` 的 `activeEvent`，**由失败流程明写清理**（失败流程本就要拆解整个 CharacterProfile）。
- **Explore 揭示不新增决策点、不新增存档点类型，本地写照常发生。** `ct` 只在决策点被观察 ⇒ 揭示与随后进入的第一个决策点之间不存在可退出窗口；三种真身各自的第一个可退出点都是既有的（Combat → 进入战斗前的 `Immediate` flush 点 · Exchange → 商店面板的事件内决策点 · Travel → 收口）。
- **Exchange 刷新即时提交**，与逐笔交易同形（主动消费即时提交的第四个实例）：本地立即原子写，push 走 `Debounced`，**不计软阻塞闸门**（闸门只数事件级存档点）。
- **收口** `eventEnd`：`activeEvent` 置空与新一批 `eventOption` 并入同一次 `TryApply`。

### 5. 收口时的只读投影：先算后提交

新一批要依**更新后的** profile 重算（`pastEvent` 是 future-event-service 的一等输入），而收口又必须是一次事务、一个存档点——两条承重纪律都不放松，故 `profile-service` 提供一个形如 `Project(spec)` 的**只读投影**（施加 spec 得到一份未提交的 profile 视图），life-cycle-service 用它算出新一批，再把批一并放进同一次 `TryApply`。`RefreshAfterEvent` 因此可接受一份投影 profile。

本库已有两处先例说明「先算后提交」在本模型内是自然的：`AppliedChange` 可重放、`CanAfford` / `TryApply` 共用 `Evaluate(spec)`。代价只是多一个只读方法，**不新增写入面**。

### 6. RNG 同事务不变式（本次发现的一处裂缝）

刷新消耗 `Shop` 子流的随机 ⇒ 该子流的 `State` / `DrawCount` 必须与新库存落在同一次原子写内。两侧不同步各自都是漏洞：`State` 落了库存没落 ⇒ 再刷一次得到不同结果，等于一条重掷通道；库存落了 `State` 没落 ⇒ 下一次从同一 `State` 起掷、重复同一批结果且 `DrawCount` 诊断口径失真。本次只落这条不变式 + 一条恢复自校验；`Rng` 块纳入 spec 列的形态另立一轮。**同一条裂缝对 `ActiveCombat` 一样成立**，它不是本问题引入的。

### 7. 「重掷不可刷」的机械保证与痕迹侧零增量

不靠自律，落成七条不变式 / 读档校验（`eventInstanceId` 可在当前批按 `InstanceId` 找到 · `InstanceId` 与 `EventId` 一致 · `RerolledCount` 单调不减 · `IsRevealed` 只允 `false → true` · `RerolledCount` 增则库存整批替换 · `activeCombat` 的实例 id 一致 · `RerolledCount` 不超上限）。**恢复即读结果、绝不重走取池链**——与「奖励候选预先算定、恢复时读结果不重抽」同一条纪律。

痕迹侧零 schema 增量：`PastEventEntry` 的定稿实例快照**取自 `activeEvent.option`**（否则履历会记下 `IsRevealed = false` 与刷新前的旧库存）；`ExchangeStock` / `RerolledCount` 不进痕迹——库存虽重算不出，但收口后**永无消费方**，合「重算不出来**且有消费方**」的完整口径。

### 连带

- **「唯一出口」的松动明写**：它管的是「物化」这一动作，不管已定稿实例的 `with` 派生（派生不取池、不掷物化随机、不改 `InstanceId` / `EventId`）。不写这一句，日后必有人据「唯一出口」把派生逻辑推回 future-event-service，而那会给这个明写「无记忆」的服务装上一个事件内的状态机。
- future-event-service **零改动**：不新增方法、不新增写入面；`Current { get; }` 收窄为内存视图，权威在 `CharacterProfile.eventOption`。
- 两个字段都挂 `CharacterProfile` ⇒ **不新增同步单元**，diff 粒度不变；体积 +1–8 KB / 事件，护栏不受威胁。
- bump 存档 schema 版本一次（与同批其余草稿合并为同一次；当前无线上存档 ⇒ 空迁移）。

## Clarifications（interview 产物）

- **新一批塞进收口那一次 `TryApply`，与「依更新后的 profile 重算」在时序上打架，取哪条路？** → 两条承重纪律都不改写，改为在 `profile-service` 上新增一个只读投影设施（形如 `Project(spec)`，不提交），先算后提交。原草稿在这一处两侧都没交代。
- **当前批载体非空还是可空？** → **可空**。原草稿的字段表写「非空：轮回进行中恒有一批」，而后果段又写老档按「无进行中批次」处置，两者不能同时成立；取可空，`null` = 尚无批次。
- **`activeEvent` 的创建写在哪一次提交？** → 与 `SelectCost` **同一次** `TryApply`；判负短路那一路留下的非 `null` `activeEvent` 由失败流程明写清理。原草稿「建议方案 2」写「终态判定 ① 未判负之后创建」，与它自己的时序伪码不一致。
- **「一次 `TryApply` 提交」是否等于一次本地原子写？** → **等于**。原草稿「揭示不落存档点」这句校正为「**不新增决策点 / 不新增存档点类型，本地写照常发生**」；`sync-service.md` 补一句把 commit 与 push 的粒度对位写清。
- **当前批载体的确切拼法？** → 全链单数一致：字段 `eventOption` · 类型 `EventOptionSave` · 枚举成员 `EventStateKey.EventOption`。原草稿通篇写的 `eventOptions` / `EventOptionBatchSave` / `EventStateKey.EventOptionBatch` 三处不同拼法全部收口。

## Open questions

- **`[采纳推荐 — 待复核]` Explore 揭示不新增独立存档点**，随后续第一个决策点落盘。若复核推翻，改动面是加一个揭示 flush 点，形态与不变式不变。
- **`[采纳推荐 — 待复核]` RNG 只落「同一次原子写」这条不变式 + 一条恢复自校验**，`Rng` 块纳入 spec 列的形态另立一轮；在那之前该不变式暂无机械保证。
- **只读投影设施的形态。** `Project(spec)` 的只读投影语义、它与 `Evaluate(spec)` 的复用关系（能否直接复用同一段施加代码、投影是否也做钳制与终态判定）。
- **`activeCombat` 的写入通道未明写。** `activeEvent` 已定走 `EventStateChanges`，形态相同的 `activeCombat` 仍来路不明 ⇒ 两套写入纪律的风险。现成方案是把它收进同一列，范围落在 `combat-service.md`。
- **`pastEvent` 的追加同样没有 `ProfileChangeSpec` 列**（第三处「有纪律、无通道」的缺口），本次不处理。

## Notes / triage

来源草稿：`inbox/solution-draft-event-option-derived-persistence.md`（`/provide-solution-draft` 产物，用户已评审，五项裁决全部取推荐项）。
