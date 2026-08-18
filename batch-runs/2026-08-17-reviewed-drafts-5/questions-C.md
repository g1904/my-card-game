# Phase A 报告 — 分片 C：solution-draft-event-option-derived-persistence.md

目标库：`game-design-documents/`（草稿路径带库前缀 + 全部 targets 皆为客户端主题文档；无后端契约面 ⇒ **不触及后端库**）。

## 1. 意图要点（我的理解）

1. 结算中会派生 `EventOption` 的两处（Explore 揭示 `IsRevealed=true`、Exchange 刷新 `ExchangeStock`+`RerolledCount+1`）必须在玩家可退出之前落盘。
2. 承载 = `CharacterProfile` 上新增**可空块 `activeEvent`**（`EventInstanceId` + 派生后的整份 `EventOption` 快照），形状逐条搬 `ActiveCombat` 先例；当前批里那份原实例**一字不动**。
3. 顺带给「当前批」一个具名载体（草稿写 `eventOptions`，用户裁定改**单数** `eventOption`）：`BatchId` + `Options` + `EffectivePriority`，每次刷新**整块替换**。
4. 写入通道 = `ProfileChangeSpec` 新增第六列 `EventStateChanges`（绝对置值、恒不走 modifier pipeline、`SelectCost` 内恒空），**不**把 `activeCombat` 收进来。
5. 落盘时机：零新增存档点 / 阶段。揭示随后续第一个决策点落盘；刷新即时提交（`-jade` 与新库存同一次 `TryApply`），push 走 `Debounced`，不计软阻塞闸门。
6. 一条读取规则收口歧义：`activeEvent != null` 时本次结算一律读 `activeEvent.option`；批中原实例只用于呈现未开始的选项与组装 `Unchosen`。
7. 七条不变式 / 读档校验保「重掷不可刷」；恢复即读结果、绝不重走取池链。
8. 痕迹侧零增量：`PastEventEntry` 快照取自 `activeEvent.option`，`ExchangeStock`/`RerolledCount` 不进痕迹。
9. 新指出一条裂缝：消耗子流随机的提交必须与该子流 `State`/`DrawCount` 同一次原子写（同样约束 `ActiveCombat`）。

## 2. 校验发现

### 🔴 冲突（必须 interview）

- **C-R1 · `eventEnd` 那一次 `TryApply` 里同时写入「新一批 `eventOption`」，与「重算依据 = 更新后的 CharacterProfile 且 `pastEvent` 是一等输入」在时序上打架。**
  - 想法侧：草稿「三条写入时序」的收口行写
    `【eventEnd】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉 + EventStateChanges[ActiveEvent = null, EventOptionBatch = 新一批] → 一次 TryApply、一个存档点`，
    而 `记入 pastEvent（快照取自 activeEvent.option）` 排在这一次 `TryApply` **之后**。
  - 既有权威：`systems/services/future-event-service.md`——「future-event-service **依更新后的 characterProfile** 重算一批新的 eventOptions」「**重算依据 = 角色的整体历程**……**`pastEvent` 是本服务的一等输入**」「批与批之间唯一的信息通道是 CharacterProfile 本身」；`systems/services/profile-service.md`——`TryApply` 是**单点提交**，提交前 profile 未变更；`ProfileManager.Snapshot` 只给已提交的只读视图，本库没有任何「投影出一份未提交 profile」的设施。
    ⇒ 若新一批要塞进同一次 `TryApply`，它只能算在**本次结算尚未落账、`pastEvent` 尚未追加**的旧 profile 上，直接违反上面两句；若把它拆成第二次 `TryApply`，则「一个事件的收口是**一次**事务、一个存档点」（`adventure-event/common-properties.md`「事务纪律」承重）被破。这是一个真实的二难，草稿两侧都没交代。
  - 选项与后果：
    (a) **收口拆成一次 `TryApply` + 一次「重算并写入新批」的后续提交**，并把「收口是一次事务」改写为「收口的**账**是一次事务；新一批的写入是紧随其后的第二次提交，同一个存档点内」⇒ 要改写 `adventure-event/common-properties.md` 的事务纪律段与 `life-cycle-service.md` 的流程伪码；新增一条不变式「两次提交之间不存在决策点，故无可退出窗口」。
    (b) **life-cycle-service 先在内存里把本次 spec 施加成一份投影 profile（含新 `pastEvent` 条目），交给 `RefreshAfterEvent` 算新批，再把批一并放进同一次 `TryApply`** ⇒ 需要在 `profile-service.md` 上明写一个投影 / 预演设施（形如 `Project(spec)` 返回只读投影，不提交），并在 `future-event-service.md` 写明「`RefreshAfterEvent` 接受投影 profile」。收口仍是一次事务。
    (c) **新一批不进 `eventEnd`，改为「下一次呈现选择区之前惰性重算并单独提交」** ⇒ `eventOption` 载体在收口后短暂为空 ⇒ 与「非空、轮回进行中恒有一批」相抵（连带 C-A1），且开出一个「收口后、重算前」的可退出窗口需要恢复分支。
    - **推荐：(b)**——理由是它是唯一**不改写任何一条承重纪律**的路：既保住「收口是一次事务、一个存档点」，又保住「重算依据是更新后的历程」；本库已有「`AppliedChange` 可重放」「`CanAfford`/`TryApply` 共用 `Evaluate(spec)`」两处先例说明「先算后提交」在本模型内是自然的。代价只是 `profile-service` 多一个只读投影方法（不新增写入面）。

### 🟠 含糊（必须 interview）

- **C-A1 · 当前批载体是「非空」还是「可空 / 可空批」？草稿自相矛盾。**
  - 想法侧：「建议方案 1」与字段表写 **非空**（`EventOptionBatchSave eventOptions; // 非空：轮回进行中恒有一批`）；而「后果」段写「老档缺 `eventOptions` → 无法凭空重建 ⇒ 只能按**无进行中批次**处置并在下一次 `RefreshAfterEvent` 重算一批」。「非空」与「无进行中批次」不能同时成立。
  - 既有权威：`.claude/rules/state-save-rules.md` 与 `sync-service.md`——存档带版本 + 迁移路径，「绝不在较旧的存档上崩溃」；`character-profile/_index.md` 其余字段的既有口径是「老档缺字段 → 空列表 / 空迁移」。
  - 选项与后果：(a) 字段**可空**（`EventOptionBatchSave?`），`null` = 尚无批次（`StartCycle` 之前 / 迁移老档 / 若取 C-R1(c) 则收口后瞬间），读档时 `null` → 触发一次重算 ⇒ 读取侧多一处判空；(b) 字段**非空**，迁移写入一个**空 `Options` 的批**（`BatchId` 用哨兵值）⇒ 无判空但制造一个语义上不存在的 batch，且 `EffectivePriority` 无意义；(c) 非空 + 迁移期**直接重算一批**写进老档 ⇒ 迁移里跑物化（读内容注册表、掷 map 子流），与「迁移只做结构搬运」相抵。
  - **推荐：(a) 可空**——`activeCombat` 先例就是可空块，读档一次判空即知状态；且它是唯一同时容纳「迁移老档」「C-R1 三条路任一」的形状。

- **C-A2 · `activeEvent` 的创建写在哪一次提交？草稿两处写法不同。**
  - 想法侧：「建议方案 2」写「`AdvanceEventAsync` 校验合法性、施加 `SelectCost`、**终态判定 ① 未判负之后创建**」；「三条写入时序」却写 `TryApply( SelectCost + EventStateChanges[ActiveEvent = 该项原样拷贝] ) ← 同一次事务`，再走终态判定 ①（并注「判负 → 短路；activeEvent 随失败流程一并清理」）。
  - 既有权威：`life-cycle-service.md` / `architecture.md` 的固定流程——`TryApply(SelectCost)` → 终态判定 ①（判负则**短路**，不进 resolver）；`profile-service.md`——`selectCost` 无条件施加、支付后判定。
  - 选项与后果：(a) **同一次 `TryApply`**（与 `SelectCost` 合并）⇒ 零新增提交；代价是判负短路那一路会留下一个非 `null` 的 `activeEvent`，必须在失败流程里明写清理，且失败角色的存档在清理前的一瞬是「有事件在结算但已 defeated」；(b) **判定 ① 之后单独一次 `TryApply`** ⇒ 状态永远干净；代价是事件推进多一次提交（既有流程图里没有这一步，要在 `life-cycle-service.md` 与 `architecture.md` 两处流程伪码加行）。
  - **推荐：(a)**——`selectCost` 不回滚、「已经发生的事就是发生了」，把「这一项已被选中」与支付放在同一笔最贴合；失败流程本就要拆解整个 CharacterProfile，清理是免费的。但必须由用户拍板，因为它决定两处流程伪码怎么写。

- **C-A3 · 「一次 `TryApply` 提交」与「一个存档点 / 本地原子写」是否解耦？③-a 依赖这个前提，而本库从未明写。**
  - 想法侧：「Explore 揭示不需要自己的存档点……随后续第一个存档点一并落盘」，同时揭示本身是一次 `TryApply`。
  - 既有权威：`sync-service.md`——「每个存档点**立即原子写**本地缓存，push 走 5 秒防抖」；`profile-service.md`——事件内主动消费「**即时经本 manager 写档**」「不新增存档点类型，走既有『变更后由 sync-service 上行』通道」。本库没有一句话说「`TryApply` 可以不落本地」。
  - 选项与后果：(a) **提交即本地原子写**（`TryApply` ⇒ 立即写本地缓存，push 另计）⇒ ③-a 那句「不落存档点」应改写为「**不新增决策点 / 不新增存档点类型**，本地写照常发生」，`sync-service.md` 补一句把 commit 与 push 的粒度对位写清；(b) **提交与本地写解耦**，只有决策点才本地写 ⇒ 要在 `sync-service.md` 明写「commit ≠ 落盘」，并回答崩溃时那些已提交未落盘的变更如何处置（与「绝不回退存档点」相抵）。
  - **推荐：(a)**——(b) 会打开一个本库明确要封的窗口（已提交但未落盘 = 退出重进即回滚），而 (a) 只是把 ③-a 的措辞校正为「不新增点位」，用户的裁决（不新增揭示存档点）实质不变。

- **C-A4 · 当前批载体的**确切**字段名 / 类型名 / 枚举成员名（⑤ 裁定单数后需要一次性钉死，且与 S1 / S3 交叉）。**
  - 想法侧：草稿通篇写 `eventOptions` / `EventOptionBatchSave` / `EventStateKey.EventOptionBatch`；用户裁定「按 S1 的单数裁决落笔 ⇒ 应定名 `eventOption`」。
  - 既有权威：`character-profile/_index.md` 既有单数风格 `pastEvent` / `disabledAbility` / `plotKeyPoint`（明写「单数命名，沿用 pastEvent 的既有风格」）；但 `future-event-service.md` 全篇把这一批叫 **`eventOptions`**（服务名、循环名、`EventOptionBatch` 类型名皆然），术语面是复数。
  - 选项与后果：(a) 存档字段 `eventOption`，类型仍叫 `EventOptionBatchSave`，spec 枚举成员 `EventStateKey.EventOptionBatch` ⇒ 字段名单数、类型名带 Batch，三处不同拼法；(b) 存档字段 `eventOption`，类型 `EventOptionSave`，枚举成员 `EventStateKey.EventOption` ⇒ 全链单数一致，但「它装的是一批」这一语义只能靠内部 `Options` 列表体现；(c) 字段 `eventOptionBatch`（草稿自己给的折中）⇒ 单数、语义准确，但与 S1 的「单数」裁决措辞是否算一致需用户确认。
  - **推荐：(b)**，其次 (c)——理由是本库对存档字段的既有纪律是「链路上类型一致、不做隐式转换」，三处不同拼法（字段 / 类型 / 枚举）是最容易在 derive 阶段长出分歧的形状。**这题必须与 S1 / S3（`CharacterProfile` 字段总表）同时裁决**，否则两份文档会各写一个名字。

### 🔵 可推演（不进 interview）

- 承载取 A（新可空块）后，`explore/_index.md` 那句「**字段保留**：当前批 eventOptions 落存档，退出重进后呈现层需要它判断『这一步已经揭示过了』」的**理由句已失真**——`IsRevealed = true` 只存在于 `activeEvent.option`，不在当前批里。须就地改写为指向 `activeEvent.option`（依据：草稿的读取优先级规则 + `explore/_index.md` 原文）。
- `explore/_index.md` 与 `adventure-event/common-properties.md` 的「派生实例，当前批里那份原实例不动」两句**原样保留**，A 案不需要改写它们（依据：草稿建议方案 2 与两份文档原文）。
- `EventStateAssignment.Value` 落成两个具名可空字段而非 `object`：与 `StatusAssignment` 的「双字段单列表、另一格填缺省」完全同构（依据：`profile-service.md` 的 `StatusFields` 段 + `architecture.md` 共享核心类型）。
- 新列**恒不走 modifier pipeline**、**`SelectCost` 内恒空且断言独立不合并**：`profile-service.md` 明写「不得合并成『非 `Elements` 的列一律为空』的通则」，`AbilityElements` / `DeckElements` 已是两个先例（依据：`profile-service.md` 施加失败语义表第 6 / 11 行）。
- 组装方 = life-cycle-service：`future-event-service.md` 明写本服务「不负责写档」、`profile-service.md` 明写三个上游写入方都只经 ProfileManager 写（依据：两处原文）。
- 不新增同步单元、diff 粒度不变：两个字段都挂 `CharacterProfile`（依据：`sync-service.md` + `combat-service.md` 战斗存档段）。
- 恢复路径「读 `ExchangeStock` 直接呈现、绝不重走取池链」与「候选预先算定、恢复时读结果不重抽」同一条纪律（依据：`future-event-service.md` Research / Exchange 两段）。
- `PastEventEntry` 零字段增量：`RevealedEventId` 恒存在、库存与刷新次数收口后无消费方，合「重算不出来**且有消费方**」的完整口径（依据：`character-profile/_index.md` `plotKeyPoint`「不记已走分支路径」同款处置）。
- `sync-service.md` 第 ~60 行「估算随……『每批 eventOptions 数量』答定需复核」由本次给出复核口径（每批按 1–5 项、整块替换、+1–8 KB/事件）（依据：该行原文）。
- schema bump 一次、当前无线上存档 ⇒ 空迁移，走既有 MigrationManager 骨架（依据：`character-profile/_index.md` 各字段的既有口径）。

### ✅ 用户已在评审中定下（照定案处理，不进 interview）

- ① 承载取 **A** = 新可空块 `CharacterProfile.activeEvent`，持派生后的整份定稿实例；当批原实例不动。
- ② 取 **②-a** = 新列 `EventStateChanges`，**不**把 `activeCombat` 收进来（不动 `combat-service.md`）。
- ③ 取 **③-a** `[采纳推荐 — 待复核]` = Explore 揭示不新增独立存档点（措辞校正见 C-A3）。
- ④ 取 **④-a** `[采纳推荐 — 待复核]` = 只落「消耗子流随机的提交须与该子流 `State`/`DrawCount` 同一次原子写」一条不变式 + 一条恢复自校验；`Rng` 块进 spec 列的形态另立一轮。
- ⑤ 当前批载体按 **S1 的单数裁决**落笔（确切拼法仍需 C-A4 收口）。
- 连带：`ProfileChangeSpec` 本轮一次增两列（本片 `EventStateChanges` + S4 `PlotElements`），`ChangeElement` 增 `Op`、`ElementSpec` 增 `AllowedOps`——**三处同一段代码块，必须一次落笔**；成本侧恒空断言逐列独立。
- 连带：S5 的 `EncounterSpec Encounter`（内嵌 `EnemyInstance`）随 `activeEvent` 整份快照复制，存档体积上抬，用户已知悉。
- 连带：五份草稿的 schema bump 合并为同一次；老档按「无进行中批次」迁移（形状取决于 C-A1）。

## 3. 拟改动文档清单（供跨草稿核对）

> 下表按 **C-A4 推荐项 (b)** 书写（字段 `eventOption`、类型 `EventOptionSave`、枚举成员 `EventStateKey.EventOption`）。若用户改选 (a)/(c)，把三处名字整体替换即可，形态与不变式不变。

| 文档 | 拟新增 / 修改的要点 |
|---|---|
| `systems/character-profile/_index.md` | 「意图」新增两条平级字段登记（与 `pastEvent` / `activeCombat` / `disabledAbility` / `plotKeyPoint` 同层）：`EventOptionSave? eventOption`（当前批定稿快照；可空取决于 C-A1）与 `ActiveEventState? activeEvent`（可空块，`null` = 无事件在结算）。 |
| 同上 | 写出两个 record 的**确切形状**：`public sealed record EventOptionSave(string BatchId, IReadOnlyList<EventOption> Options, int EffectivePriority);` 与 `public sealed record ActiveEventState(string EventInstanceId, EventOption Option);`。 |
| 同上 | 生命周期两行：`eventOption` —— `StartCycle` 写第一批，每次 `RefreshAfterEvent` **整块替换**（写入时点取决于 C-R1 裁决）；`activeEvent` —— 事件推进时创建（时点取决于 C-A2），`eventEnd` 收口置空，与 `activeCombat` 同一处清空。 |
| 同上 | 读档校验 7 条（`eventInstanceId` 可在 `eventOption.Options` 按 `InstanceId` 找到 / `Option.InstanceId` 与 `EventId` 一致 / `RerolledCount` 单调不减 / `IsRevealed` 只允 `false→true` / `RerolledCount` 增 ⇒ 库存整批替换 / `activeCombat != null ⇒ eventInstanceId` 一致 / `RerolledCount <= MaxRerollCount` 钳制）——前 6 条 `PushError` 带 `characterId` + `instanceId`，第 7 条 `PushWarning` + 钳到上界。 |
| 同上 | 「随本次落定 bump schema 版本（当前无线上存档 → 空迁移）」一行 + 老档缺 `eventOption` 的迁移处置。 |
| `systems/services/profile-service.md` | `ProfileChangeSpec` **新增第六列** `EventStateChanges: IReadOnlyList<EventStateAssignment>`；语义 = **绝对置值**（组装方先算好整块再置入，manager 不做合并 / 增量）。 |
| 同上 | 类型：`public readonly record struct EventStateAssignment(EventStateKey Key, ActiveEventState? ActiveEvent, EventOptionSave? Batch);` + `public enum EventStateKey { ActiveEvent, EventOption }`（`null` = 置空，仅 `ActiveEvent` 合法）。 |
| 同上 | 施加失败语义表**新增行**：`EventStateChanges` 出现在 `SelectCost` 内 → 必需缺失 → `PushError` + 整批拒绝（**独立一行，不与 `AbilityElements` / `DeckElements` 两条合并**）；`Key` 与非空字段不匹配（如 `Key == EventOption` 却填了 `ActiveEvent`）→ 必需缺失 → `PushError`。 |
| 同上 | 一句「**恒不经 modifier pipeline**」+ 理由（一条法则若能改写 `RerolledCount` / 库存，等于账号级内容改写轮回级定稿实例）。 |
| 同上 | 若取 C-R1(b)：新增只读投影方法（形如 `PlayerProfile Project(ProfileChangeSpec spec)`，**不提交**），供 life-cycle-service 在收口前算新批。 |
| `systems/architecture.md`「共享核心类型」 | 同步 `ProfileChangeSpec` 的第六个列表字段与两个新类型（**与 S4 的 `PlotElements` 同一段代码块，一次落笔**）。 |
| `systems/services/future-event-service.md` | 「意图」补一句：批的**权威在 `CharacterProfile.eventOption`**，`Current { get; }` 收窄为「内存视图」；服务**零改动、不新增写入面**，仍是无记忆的纯产出侧。 |
| 同上 | 「与既有决策的张力 1」的松动明写：**「唯一出口」管的是「物化」这一动作，不管已定稿实例的 `with` 派生**（派生不取池、不掷物化随机、不改 `InstanceId` / `EventId`）。 |
| 同上 | 「待决问题」删除「结算进行中的 `EventOption` 派生实例如何落存档」一条（已答定，指向承载）。 |
| 同上 | 若取 C-R1(b)：`RefreshAfterEvent` 一句「可接受一份**投影** CharacterProfile（含本次尚未提交的账与新 `pastEvent` 条目）」。 |
| `systems/adventure-event/common-properties.md` | 「结算阶段」段新增**读取权威一句**：`activeEvent != null` 时本次结算涉及的 `EventOption` 一律读 `activeEvent.option`；批中原实例只用于呈现未开始的选项与组装 `Unchosen` 轻摘要。 |
| 同上 | 收口时 `PastEventEntry` 的定稿实例快照**取自 `activeEvent.option`**（不取批中原实例），`PastEventEntry` **零字段增量**。 |
| 同上 | 「事务纪律」段：`eventEnd` 的那一次 `TryApply` 额外并入 `EventStateChanges[ActiveEvent = null, EventOption = 新一批]`（措辞随 C-R1 裁决调整）；Exchange 刷新是「主动消费即时提交」的**第四个实例**。 |
| `systems/adventure-event/explore/_index.md` | 改写「揭示的结算形态」末条的理由句：`IsRevealed` 的读取面从「当前批落存档」改为「`activeEvent.option` 落存档」；伪码新增一行 `TryApply( EventStateChanges[ActiveEvent = option with { IsRevealed = true }] )`。 |
| 同上 | 「待决问题」不新增（本页原无该条）；「决策」段可加一句承载指向。 |
| `systems/adventure-event/exchange/_index.md` | 「刷新（reroll）」段明写原子性：`ChangeElement(Jade, -刷新价)` 与 `EventStateChanges[ActiveEvent = option with { ExchangeStock = 新一批, RerolledCount = 前值+1 }]` 落在**同一次 `TryApply`**；两个方向的破裂后果（付了钱可再刷 / 免费刷）各一句。 |
| 同上 | 「待决问题」删除「reroll 后的库存如何落存档」一条。 |
| `systems/services/life-cycle-service.md` | `AdvanceEventAsync` 固定流程伪码**加两行**：推进时写 `EventStateChanges[ActiveEvent = 该项原样拷贝]`（并入 `SelectCost` 那一次，取决于 C-A2）；`eventEnd` 并入 `[ActiveEvent = null, EventOption = 新一批]`。 |
| 同上 | 新增 RNG 同事务不变式一条：**凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 必须在同一次原子写内更新**；恢复路径自校验（`DrawCount` 与本次提交声明的消耗数不一致 → `PushWarning`）。 |
| 同上 | 「组装方 = life-cycle-service」与既有 band / location 组装同款一句。 |
| `systems/services/sync-service.md` | `pastEvent` 估算段的「随『每批 eventOptions 数量』答定需复核」给出复核结论：`eventOption` 整块替换 1–6 KB（含 S5 的 `EncounterSpec` 后上抬）、`activeEvent` 额外复制一份最重的 option；**+1–8 KB / 事件，不新增同步单元**，体积护栏（>500 条 / >512 KB）不受威胁。 |
| `systems/architecture.md`（总则 6 附近，视需要） | 一句：定稿实例的 `with` 派生不违反「产出即定稿」——批中原实例一字未动。 |

**跨草稿交叉点（请 orchestrator 重点核对）：**
- 与 **S3（`CharacterProfile` 字段总表）**：本片要在 `CharacterProfile` 上占**两格**——`eventOption`（`EventOptionSave?`）与 `activeEvent`（`ActiveEventState?`）。命名 / 排位 / 可空性以 S3 的总表为准，但**形态与 7 条不变式不变**。C-A1 与 C-A4 必须与 S3 同轮裁决。
- 与 **S4（`ProfileChangeSpec` 增列 / `ChangeElement` 增 `Op`）**：本片增第六列 `EventStateChanges`，S4 增 `PlotElements`。两处在 `architecture.md` 同一段代码块与 `profile-service.md` 同一段承重表述内，**必须一次落笔**；成本侧恒空断言**逐列独立**写，不合并通则。
- 与 **S5（`EventOption` 增 `EncounterSpec Encounter`）**：`activeEvent.option` 是整份快照 ⇒ 最胖载荷被复制一份，体积估算需在 `sync-service.md` 用 S5 的最终字段面复核。本片对字段增删中立，无需为新字段改承载形状；唯一交界是若新增字段**可在结算中被改写**，需给不变式表补一行方向性约束（S5 的 `Outcome` 格已确认不参与派生改写）。

## 4. 拟移出的 open-questions 条目

- `open-questions/02-event-options.md`: **「结算进行中的 `EventOption` 派生实例如何落存档（08-17d 新增 · 承重）」** → 答定为：承载 = `CharacterProfile.activeEvent`（可空块，持派生后的整份定稿实例），当批原实例不动；写入走 `ProfileChangeSpec.EventStateChanges` 新列；揭示随后续第一个决策点落盘，刷新即时提交且与 `-jade` 同一次 `TryApply`。**整条关闭**（Explore 与 Exchange 两侧同时收口）。
- 同一问题在两处主题文档的**文档级**待决登记一并删除（非分片，由 worker 在 Phase B 写）：`systems/services/future-event-service.md`「待决问题」第 3 条、`systems/adventure-event/exchange/_index.md`「待决问题」第 4 条。
- answer log 命名：`answer-logs/log-event-option-derived-persistence.md`（输入为 `inbox/solution-draft-<slug>.md` ⇒ 取 slug）。

## 5. 拟新增的 open-questions 条目

- `open-questions/05-service-contracts.md`: **`activeCombat` 的写入通道未明写（承重）。** `activeEvent` 已定走 `ProfileChangeSpec.EventStateChanges`，形态相同的 `activeCombat` 仍来路不明 ⇒ 两套写入纪律的风险。②-b 是现成方案（把 `activeCombat` 收进同一列），范围落在 `combat-service.md`，本轮用户明确不动。→ `systems/services/combat-service.md`、`systems/services/profile-service.md`。
- `open-questions/05-service-contracts.md`: **RNG 状态的写入通道形态（④-b 留待）。** 本轮只落「消耗子流随机的提交须与该子流 `State`/`DrawCount` 同一次原子写」这条不变式，但 `Rng` 块目前**没有任何 spec 列可落** ⇒ 不变式暂无机械保证。是否把 `Rng` 纳入 `EventStateChanges` / 另开一列，牵动 `ActiveCombat` 与四条子流的全部写入点。→ `systems/services/life-cycle-service.md`、`systems/services/profile-service.md`。
- `open-questions/02-event-options.md`（**仅当 C-R1 裁为 (b)**）: **收口时的投影施加设施形态。** `Project(spec)` 的只读投影语义、它与 `Evaluate(spec)` 的复用关系。→ `systems/services/profile-service.md`。
- `open-questions/05-service-contracts.md`（**仅当 C-A3 裁为 (b)**）: **`TryApply` 提交与本地原子写的粒度对位。** → `systems/services/sync-service.md`。
- 若 ③-a / ④-a 保留 `[采纳推荐 — 待复核]` 标记：两条在 handoff 的 `## Open questions` 中同时留一行待复核项。

## 6. 越界发现（不处理，仅记录）

- **`pastEvent` 的追加同样没有 `ProfileChangeSpec` 列。** `profile-service.md` 明写「`pastEvent` 写入经 life-cycle-service 组装 → `ProfileManager`」，但六列里没有一列装得下 `PastEventEntry`；`architecture.md` 的流程伪码把「记入 pastEvent」画在 `eventEnd` 那次 `TryApply` **之外**。这是与 `activeCombat` 同类的第三处「有纪律、无通道」缺口，本片不处理（属 S3 / `profile-service` 专场）。
- **`exchange/_index.md` 与 `02-event-options.md` 的同一问题重复登记**已由本次一并收口；但 `03-adventure-event-types.md` 第 5 行「Exchange 已收口」的措辞在本条答定后仍成立，无需改动（已核）。
- **`future-event-service.md` 待决「`EventOption` 的完整物化字段清单未定」**与 S5 直接相撞，本片不碰。
- **`sync-service.md` 的软阻塞闸门「只数事件级存档点 ≥ 3」**在 Exchange 连续刷新场景下被本片明确排除（事件内点不计），但该闸门条文本身是否需要补一句「事件内提交不计」由 sync 专场裁决，本片只在体积段落笔。
