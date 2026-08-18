# S3 报告 — EventOption 派生实例落存档

> worker 的报告文件写入被 harness 拦截，内容由 orchestrator 代为落盘（原文照录）。草稿文件本身已写入。

- library: `game-design-documents`（客户端库 · 单库；问题整个属客户端——派生与存档全在 Godot 进程内，后端契约把 `characterDiffs` 整体划为不透明段 ⇒ 零跨库面）
- 依据构成：**既有推演 7 项 · 通行做法 0 项 · 取向选择 5 项**
- 只写了预分配的那一个文件；未写任何台账 / 主题文档 / ADR / handoff / 代码。

## 草稿文件

`game-design-documents/inbox/solution-draft-event-option-derived-persistence.md`（`status: awaiting-review`）

## inbox/_index.md 待处理表应追加的行

⚠ 该文件的「在办清单」表实际是 **3 列**（`文件 | status | 说明`），与技能第 6b 步描述的 5 列不一致。按实际表结构给出；当前表体 `| *（空）* | | |` 应被替换：

```
| `solution-draft-event-option-derived-persistence.md` | awaiting-review | 结算进行中的 `EventOption` 派生实例（Explore 揭示 / Exchange 刷新）的承载与落盘形态；评审 5 项取向后 `/analyze-new-ideas` |
```

## 依据构成（既有推演 7 条）

1. 承载形态整体从 **`ActiveCombat` 先例**导出（可空块 / 挂 `CharacterProfile` / `eventInstanceId` 交叉校验 / 收口置空 / 不进 `pastEvent` / 不新增同步单元）。
2. **当前批必须有一个具名载体**——「当前批落存档」已答定（`answer-logs/log-service-api-contracts.md`、`architecture.md` 总则 6 推论 1），但 `character-profile/_index.md` 的字段清单里没有它。
3. 刷新那一笔的原子性要求「`-jade` + 新库存 + `RerolledCount`」同一次 `TryApply` ⇒ 需要一条能装结构块的 spec 列（`Elements` 装不下，`StatusChanges` 的 `StatusFields` 表也装不下）。
4. **Explore 揭示不需要独立存档点**：`ct` 只在决策点被观察 ⇒ 揭示与后续第一个决策点之间不存在可退出窗口（三种真身的第一个点全是既有点：Combat→D0、Exchange→面板决策点、Travel→收口）。
5. 刷新即时提交 = 「事件内部的主动消费即时提交」两条判据的第四个实例，push 走 `Debounced`、不计软阻塞闸门。
6. 痕迹快照须取自派生后的实例；`ExchangeStock` / `RerolledCount` **不进 `PastEventEntry`**（按完整口径「重算不出来**且有消费方**」，收口后无消费方）⇒ 痕迹侧零 schema 增量。
7. 「重掷不可刷」落成 7 条可断言的不变式 / 读档校验（含 `activeCombat.eventInstanceId == activeEvent.eventInstanceId`）；恢复即读结果、绝不重走取池链。

## 建议要点

- **承载 = `CharacterProfile.activeEvent`（新可空块，持派生后的整份定稿实例）**，当批那份原实例一字不动 ⇒ `explore/_index.md` 与 `adventure-event/common-properties.md` 的「原实例不动」两句原样保留。
- **顺带补上当前批的具名载体 `CharacterProfile.eventOptions`**（`batchId` / `options[]` / `effectivePriority`，每次 `RefreshAfterEvent` 整块替换）——这是本问题的前置缺口，不补则派生实例的校验无处交叉。
- **一条读取规则收口全部歧义**：`activeEvent != null` 时本次结算涉及的 `EventOption` 一律读 `activeEvent.option`；批中原实例只用于呈现未开始的选项与组装 `Unchosen`。
- **写入走 `ProfileChangeSpec` 新列 `EventStateChanges`**（绝对置值 · 恒不走 modifier pipeline · `selectCost` 内恒空且**独立断言不与前两条合并**），组装方 = life-cycle-service（resolver 只描述结果）。
- **零新增**：结算阶段 · 存档点类型 · resolver · 服务方法 · RNG 子流 · `PastEventEntry` 字段 · `EventOutcome` 成员。future-event-service **零改动**，只需补一句「`Current` 是内存视图，权威在 `CharacterProfile.eventOptions`」。
- **bump 一次 schema、空迁移**；两字段都挂 `CharacterProfile` ⇒ 不新增同步单元，体积 +1–8 KB / 事件，顺带给出 `sync-service.md` 第 60 行「随每批 eventOptions 数量答定需复核」的复核口径。
- **新指出一处裂缝**：消耗子流随机的提交必须与该子流 `State` / `DrawCount` 落在同一次原子写内——两个方向各自都是可利用漏洞（`State` 落库存没落 = 重掷通道；库存落 `State` 没落 = 重复同一批）。同一裂缝对 `ActiveCombat` 一样成立。

## 仍需用户决定（5 项）

**① 派生实例的承载形态。** A 新可空块 `activeEvent` / B 原地替换当批实例 / C 三个散字段记增量。
后果：A = 与 `ActiveCombat` 同形、读档一次判空即知有事件在结算、**不需改写任何既有明文**；代价是多存 0.3–2 KB 与一条读取优先级规则。B = 单一承载、体积最小；代价是要改写两处明写「原实例不动」的文本、给 future-event-service 加一个它明确没有的写入面、「事件进行中」态无法一次判空。C = 体积最小；代价是每新增一个可派生字段就加一个散字段，与同期扩充字段清单那条待答正面相撞。
**推荐 A**——`ActiveCombat` 每一条形状可逐条对位搬用，且三者中唯一不改既有明文。

**② 写入通道。** ②-a 增一列只装 `activeEvent`/`eventOptions` / ②-b 增同一列并把 `activeCombat` 一并收进来 / ②-c 不增列、服务直写。
后果：②-a 保住唯一写入入口与刷新原子性，但 `activeCombat` 的通道仍未明写 ⇒ 两条同形的路长出两套纪律。②-b 三个事件内中间态一条通道一套纪律，代价是要动 `combat-service.md`（**超出本问题范围，需用户点头**）。②-c 零 schema 增量但刷新那一笔无法保证同一事务——正是漏洞所在。
**推荐 ②-b，其次 ②-a**（判据 = 既有的「施加语义根本不同就分列」）。

**③ Explore 揭示是否需要独立存档点 / `Immediate` flush。** ③-a 不新增（随后续第一个决策点落盘）/ ③-b 新增一个揭示存档点。后者多一次写入，换「强杀也不会重看一次揭示」——而重看只是转场动画重播，真身在物化时已定不会变。**推荐 ③-a。**

**④ RNG 同事务不变式怎么落笔。** ④-a 只落一条不变式 + 一条恢复自校验 / ④-b 现在就把 `Rng` 块纳入 spec 列收口形态（牵动 `ActiveCombat` 与四条子流全部写入点，范围明显超出本问题）。**推荐 ④-a**，形态独立成轮。

**⑤ 当前批载体的字段命名。** `eventOptions`（草稿采用）/ `eventOptionBatch` / 听 S1。纯命名，不影响任何不变式；本库既有集合字段是单数风格（`pastEvent` / `disabledAbility` / `plotKeyPoint`），但改单数与「一批」的语义冲突。**推荐保留复数或 `eventOptionBatch`，最终由 S1 统一裁决。**

## 与既有决策的张力

1. **「future-event-service 是 eventOptions 的唯一出口」 vs `activeEvent.option` 是一份不由它产出的 `EventOption`。** 建议明写极小松动：**「唯一出口」管的是「物化」这一动作，不管已定稿实例的 `with` 派生**（派生不取池、不重新物化、不改 `InstanceId`/`EventId`）。不写这句，日后必有人据此把派生逻辑推回该服务，而它明写「无记忆、不持有跨批次状态」。
2. **`ProfileChangeSpec` 增列 vs 「列表数不进承重表述」**——不是冲突，是同一纪律的第三度应用（前两次 `StatusChanges` / `DeckElements`）；代价照惯例明写：bump 一次 schema · 三处列举同改 · 新增一条**独立**的成本侧恒空断言与加载期校验（不得合并成通则）。
3. **`activeCombat` 的写入通道从未明写**，本方案给 `activeEvent` 明写了一条 ⇒ 两条同形的路各走各的。已列为 ②-b 供裁决，未擅自改动。
4. **不构成张力（写明以免误判）**：本方案与「产出即定稿、不得改写其字段」不冲突——两个派生点都是 `with` 产新实例。

## 前置依赖

- **`EventOption` 完整物化字段清单**（S2）：**不阻塞**（存整份快照，对字段增删中立）。交界见下节。
- **`CharacterProfile` / `PlayerProfile` schema**（S1）：本方案占两格 ⇒ 命名 / 排位须对齐；形态与不变式不变。
- **「战斗之外的事件类型的决策点清单」**（`life-cycle-service.md` 待决）：决定 `activeEvent` 被写盘的**精确点位数**，不影响形态；「揭示随后续第一个决策点落盘」在它答定前只有形状没有点位。
- **`MaxRerollCount` / `RerollBaseCost` / `RerollCostStep` 取值**（ch1 数值标杆专场）：只影响校验 #7 的钳制边界。
- **RNG 状态的写入通道**（本草稿新指出，同时约束 `ActiveCombat`）：建议独立裁决。

## 与 S2 / S1 的交界（假设，供交叉核对）

对 **S2**：① 已定十一字段名与语义不变，未提议增删任何字段。② **假定「结算中可被改写」的字段族只有两族**（`IsRevealed` 单调 false→true；`ExchangeStock`+`RerolledCount` 同批变动）——**若 S2 引入第三类可在结算中被改写的字段**，它自动落入 `activeEvent.option`（承载不变），但需给不变式表补一行方向性约束。**请 orchestrator 核对。** ③ 假定 `ResearchSlots` 不产生派生（候选物化时掷定且 immutable，玩家逐槽选择是 outcome）；若 S2 把「已选槽位」物化进 `EventOption`，则出现第三个派生点，承载照旧覆盖但要多写一条派生伪码。④ 假定 `lifeSpanCost` 形态与本问题无关（物化时已定稿进 `SelectCost`，结算中不派生）。⑤ 假定 `combatTier` / `Priority` 与本问题无关；`Priority` 若退化为 `bool` 只改 `EffectivePriority` 的类型。⑥ **反向**：主张 `ExchangeStock`/`RerolledCount` 不进 `PastEventEntry`；若 S2 为痕迹侧新增了它们的消费方，这条要撤。

对 **S1**：⑦ 假定 `CharacterProfile` 仍可新增平级具名字段，占两格（`eventOptions` 非空 / `activeEvent` 可空）。⑧ 假定 `activeCombat` 仍是独立可空块（明写不把它塞进 `activeEvent`，最小扰动）；若 S1 重新分区「事件进行中态」，字段随之调整、形态与 7 条不变式不变。⑨ 假定 `Rng.Streams[]` 仍挂 `CharacterProfile`。⑩ 假定 `Status` 仍只装数值型运行状态 + 已登记的 6 个规则字段，故结构块不落 `Status`。⑪ **反向**：本方案要求 bump 一次 schema（两新字段 + 一条新 spec 列），且老档缺 `eventOptions` **无法凭空重建**（物化不可重算）⇒ 迁移按「无进行中批次」处置并在下一次 `RefreshAfterEvent` 重算一批；若 S1 本轮已在 bump，两处应合并为同一次 bump、同一段迁移说明。

## 越界发现（记录，未处理）

1. **`activeCombat` 的写入通道在本库从未明写**——`combat-service.md` 只给了 `PersistDecisionPoint()` 这个内部调用名，未说是否经 `ProfileManager.TryApply`，与「一切 Profile 写入经 ProfileManager」构成一处沉默的例外。已作为 ②-b 提交裁决。
2. **RNG `State` / `DrawCount` 的写入通道与原子性同样从未明写**（`systems/common-properties.md` 只说 `State` 是恢复权威字段）。建议单独立一条待答项。
3. **`inbox/_index.md` 的在办清单表是 3 列，与技能第 6b 步描述的 5 列不一致**。
4. **`character-profile/_index.md` 的字段清单缺当前批**，与 `architecture.md` 总则 6 推论 1 矛盾。草稿在自己的方案里补了载体，**未改那份文档**。
5. **`sync-service.md` 第 60 行自挂的复核项**（「估算随每批 eventOptions 数量答定需复核」）本可由 08-15 的「常态 3、区间 1–5」立即复核，与本问题无关地悬着。
