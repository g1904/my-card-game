# Phase A — remaining-event-decision-points

来源草稿：`game-design-documents/inbox/solution-draft-remaining-event-decision-points.md`（`status: awaiting-review`，但 `## 仍需用户决定` 已标注「已全部裁决（2026-08-22 · 批量评审）」）
目标库：`game-design-documents/`（客户端）—— 全部落点为客户端结算形态与存档口径，后端零改动，不跨库。

## 一句话意图

把战斗之外四类 AdventureEvent（Research / Exchange / Explore / Travel）的**事件内决策点**逐类列出（只有 R1/R2/X1/X2/X3 五行 + 两条「无」），并补一句落地口径「非战斗类的决策点不触发第二次写入，它只是可退出点（`ct` 的观察位）」，零结构增量。

## 已裁决（不进 interview）

| # | 问题 | 裁决 | 性质 |
|---|---|---|---|
| 1 | Research 槽的「已选未提交」是否落存档 | **A · 不落**（`ActiveEventState` 不加格；恢复回面板初始态、候选一字不变） | 用户拍板 |
| 2 | Exchange「面板打开」是否要显式 X0 标记 | **A · 不要**（清单只有 X1/X2/X3） | `[采纳推荐 — 待复核]` |
| 3 | 是否把「非战斗类决策点不触发第二次写入」写成明文口径 | **A · 写进 `life-cycle-service.md`** | `[采纳推荐 — 待复核]` |

- 裁决 1 附带一条**新裁决**：「置换 / 禁用候选的承载格」与它作为同形问题合并裁决 ⇒ **置换候选另找落点，不共用新格**。该裁决只给了否定面，**正面落点仍未指定** → 见 🔴-1。
- 裁决 2 / 3 按 `.claude/rules/batch-orchestration.md` 铁律 ① 处理：**不重新提问**，但 Phase B 须在 handoff 中标 `[采纳推荐 — 待复核]` 并在 `open-questions/` 留一条待复核项。

## 🔴 冲突

- **[问题陈述] 「置换 / 禁用候选另找落点」的正面落点未指定，而既有设计明写它必须落决策点存档 —— 当前它没有任何承载结构。**
  ✗ 权威一：`systems/adventure-event/common-properties.md` L54–60 —— 置换 / 禁用「候选何时掷定 = **结算时**（`eventEnd` 之前），走 `reward` 子流」；「落存档 = 决策点存档记录已掷定的候选」；「**候选必须预先算定并落决策点存档**，否则退出重进可以重掷候选」。
  ✗ 权威二：`systems/character-profile/_index.md` L100–103 —— `ActiveEventState` 恰两格（`EventInstanceId` + `Option`），`ActiveCombat` 是战斗专属块。
  ⇒ 「结算时掷定」+「不加格」+「必须落存档」三者当前**不可同时成立**。裁决 1 关掉了加格这条路，缺口因此从「隐性」变成「显性且必须处理」。
  - **选项 (a)（推荐）**：把置换 / 禁用候选的**掷定时点前移到物化阶段**，作为 `EventOption` 上的一个定稿字段随批次落存档（形状与 `EventOption.ResearchSlots` 完全同构）。
    后果：零 `ActiveEventState` 增量；防重掷由「物化时掷定并随批落存档」免费兑现，与 Research 走同一条既有纪律；**先例已存在**——`systems/adventure-event/research/common-properties.md` 明写构筑候选「随机源 = `RngStream.Reward` 子流，不新开子流」且在物化时掷定，故「走 `reward` 子流」这句可原样保留。代价：改写 `common-properties.md` 那张表的「候选何时掷定」一格；`EventOption` 加一个物化字段（**不是** `ActiveEventState` 加格，不撞裁决 1）。
  - **选项 (b)**：维持「结算时掷定」，把候选挂到 `ActiveEventState` 新增的一格上。**与裁决 1 直接冲突**（用户已明确「不共用新格」），除非用户改判。
  - **选项 (c)**：本次只登记为一条新待答项（落 `open-questions/01-combat.md`），本草稿不触及。后果：`common-properties.md` 里那条「必须落决策点存档」继续悬空；但本草稿的五行清单不受影响，可照常落笔。
  - **推荐 (a)**，理由：它是**唯一同时满足三条既有约束**的形态；Research 已把「候选物化时掷定 + 走 Reward 子流 + 随 `EventOption` 落存档」跑通一遍，置换面板与它被既有文档明写为「完全同构」的两个实例（`ADR-0022` L27：「既有决策点面板的第三个实例，前两个是战后奖励面板、能力置换面板」），让三者掷定时点一致反而消掉一处不对称。若用户希望本批只收口非战斗清单，取 (c) 亦可接受，但须明确它是**已知悬空**而非遗漏。

- **[问题陈述] 裁决 3 的明文口径与 `life-cycle-service.md` 现存的一句承重表述直接相抵，须一并改写。**
  ✗ 权威：`systems/services/life-cycle-service.md` L209「**自动存档点：** 在状态机边界……**以及事件推进过程中的每个决策点**（含战斗内）触发 —— **每点立即原子写本地缓存**」。
  ⇒ 新口径说「非战斗四类的决策点**不触发第二次写入**」，这句话把 L209 的「每点立即原子写」从全称命题降为「战斗内 + 有新状态产生时」。两句并置即自相矛盾。
  - **选项 (a)（推荐）**：改写 L209 为「每个决策点都是一个**可退出点**；该时刻若产生了尚未落盘的新状态，则立即原子写本地缓存——非战斗四类的新状态已由既有写入（`activeEvent` 整块置值 / 即时提交那一笔）覆盖，故不触发第二次写入」。后果：一句改写，L209 与新表一致；D0–D6 与既有战斗侧描述不受影响。
  - **选项 (b)**：只加新口径、不动 L209。后果：文档内两处直接打架，读者按 L209 会在非战斗类上凭空造出一批重复写盘——正是裁决 3 要防的那处误读。
  - **推荐 (a)**。裁决 3 本身是 `[采纳推荐 — 待复核]`，而它**连带改写一句既有承重表述**这一点在裁决时未被点出，故在此显式提请确认。

## 🟠 含糊

- **[问题陈述] Travel（及 Explore 揭示出 Travel）「一经选中不可取消」时，`AdvanceEventAsync` 返回什么？**
  草稿 ② 明写「Travel 零事件内决策点 ⇒ `ct` 无处被观察，流程直接走到收口」，但未说返回值。
  ✗ 相关权威：`life-cycle-service.md` L232 取消语义表——「玩家主动退出到主界面 / 切角色 → 在最近决策点停下 → `Immediate` flush → `AdvanceResult(Success: false, FailedAt: Cancelled)`」；L242「`Cancelled` 表示『这一步还没结束』，编排顶点据此**不清理 `ActiveCombat`、不推进状态机、不记 `pastEvent`**」。
  ⇒ 在 Travel 上，玩家点退出后事件**已经走完收口并记了 `pastEvent`**，此时返回 `Cancelled` 会让编排顶点按「未结束」处理一个已结束的事件。
  - **选项 (a)（推荐）**：返回 `AdvanceResult(Success: true, FailedAt: None)`，事件正常收口；退出请求在收口**之后**才生效（编排顶点收到成功结果后照常推进到事件屏，再执行退出到主界面）。并在取消语义表补一行明写：**零决策点的事件类型上，取消请求不改变本次事件的结局**。
  - **选项 (b)**：返回 `Cancelled` 但注明「Travel 上 `Cancelled` 语义特殊：`pastEvent` 已记」。后果：`AdvanceStage.Cancelled` 的含义在一类事件上被改写，编排顶点要加一个分支——与「不可达的拒绝语义留在类型上会诱导后来者」同族的坏形状。
  - **推荐 (a)**：它与既有「取消不是即时的 / 取消不产生任何回滚 / `SelectCost` 不回滚」逐条自洽，且零类型改动。

- **[问题陈述] Research 面板中途退出（R1 处观察到 `ct`）时的返回值与 `activeEvent` 处置未明写。**
  R1 是决策点、`ct` 在此被观察、但**不写盘**（裁决 1），事件也**未收口** ⇒ `activeEvent != null`、`pastEvent` 未记。
  - **选项 (a)（推荐）**：照 L232 原样返回 `AdvanceResult(Success: false, FailedAt: Cancelled)`，`activeEvent` 保留，重进读 `activeEvent.Option` 直接重开面板（候选一字不变、槽内选择丢失）。后果：与既有取消语义完全一致，零新增；只需在 `research/_index.md` 那一句里写清「恢复回到面板初始态」。
  - **选项 (b)**：Research 中途退出视同放弃、直接走收口（零选择 + `lifeSpanCost`）。后果：玩家的一次误触退出会白付一份最贵档的 `lifeSpanCost`，与「玩家主动退出取静默退出」的手感取向反向。
  - **推荐 (a)**。列为 🟠 而非 🔵，是因为草稿把 R1 的语义收窄为「可退出点」时没有交代退出后 `activeEvent` 的归宿，两种读法都说得通。

- **[问题陈述] 本次要不要把非战斗四类的决策点清单登记为 ADR 候选？**
  ✗ 参照：战斗侧「`D0–D6` 决策点清单（保留 D2）」已列在 `combat-service.md` 的 `## 决策(-> ADR)` 中；`ADR-0022` 已把 Research 构筑面板固化。
  - **选项 (a)（推荐）**：在 `life-cycle-service.md` 的 `## 决策(-> ADR)` 加一行 ADR 候选（「非战斗四类事件内决策点清单 + 决策点不触发第二次写入的口径」），**不建 ADR、不动 `decisions/_index.md`**（立档归 `/write-adr`）。
  - **选项 (b)**：不登记，只落主题文档。
  - **推荐 (a)**：它与战斗侧对称，且「决策点不触发第二次写入」是一条跨四类的全局口径，够格进 ADR 候选。

## 🔵 可推演

1. **判据一字不改地沿用**（`combat-service.md` L182 的共用公理）。四类均满足「等玩家输入」+「此前消耗的随机已全部持久化」：Research 候选与 `ManaDelta` 物化时掷定（`research/common-properties.md` L50）、Exchange 库存与刷新结果与 `-jade` 同批落盘（`exchange/_index.md` L51–59）、Explore 揭示不掷骰、Travel 目的地物化时掷定。
2. **X1 / X2 与既有即时提交逐字重合**：`adventure-event/common-properties.md` L188 已把「Exchange 逐笔交易」与「Exchange 刷新」列为四个即时提交实例中的两个；本清单只是给它们贴上「这里也是取消点」的标签，**不新增任何写入动作**。
3. **Exchange 面板打开不落点**：该时刻全部状态已由 `TryApply(SelectCost + EventStateChanges[ActiveEvent])`（`life-cycle-service.md` L92）覆盖，恢复即读 `activeEvent.Option.ExchangeStock`（`character-profile/_index.md` L122「恢复即读结果、绝不重走取池链」）。与裁决 2 同向。
4. **Explore 零自有决策点**：`explore/_index.md` L83 已明写「揭示不新增决策点、不新增存档点类型，但本地写照常发生」，且已逐条列出三种真身各自的第一个可退出点。本草稿补的只是另一半（「揭示后接入真身那一类的清单」）。
5. **X2 必须同批带 `Shop` 子流的 `RngElements`**：`life-cycle-service.md` L182 的不变式 + `exchange/_index.md` L59，既有，非新增。
6. **事件内提交不计软阻塞闸门**：`exchange/_index.md` L58 已明写「闸门只数事件级存档点，连按刷新不弹模态」，四类照此成立。
7. **`Immediate` 只在既定五处**：`life-cycle-service.md` L209；Explore 真身为 Combat 时 D0 复用「进入战斗前」那个既定 `Immediate` 点（`combat-service.md` D0 行），其余 `Debounced`。
8. **体积无新压力**：非战斗四类合计决策点远低于战斗侧的 ≈31 个 / 2–4 KB 单点 diff（`combat-service.md` L178/L198），既有体积护栏不受影响。
9. **零结构增量**（在本草稿自身范围内）：不加字段、不加枚举、不 bump 存档 schema、不新增存档点类型、不新增 push policy、不新增 RNG 子流。**注意**：🔴-1 若取选项 (a)，则 `EventOption` 会加一个物化字段并 bump schema——那超出本句的「零增量」表述，Phase B 须按裁决结果改写这句话。

## 拟改动文档清单（供跨草稿核对）

- `systems/services/life-cycle-service.md`
  - 新增一张「非战斗四类的事件内决策点」表（R1/R2/X1/X2/X3 + Explore / Travel 两条「无」+ 「明确不是决策点」清单），与 `combat-service.md` 的 D0–D6 表并列。
  - 新增落地口径一句（裁决 3）：非战斗类决策点 = 可退出点，不触发第二次写入。
  - **改写 L209**「每点立即原子写本地缓存」这句（🔴-2）。
  - 取消语义表补一行：零决策点事件类型上取消请求的处置（🟠-1）。
  - **移除** `## 待决问题` 的「战斗之外的事件类型的决策点清单」一条（L259）。
  - 可能触及 L220「置换 / 禁用的施加……落决策点存档」一句（🔴-1 取 (a) 时须改「候选在 `eventEnd` 之前掷定」为「物化时掷定」）。
  - `## 决策(-> ADR)` 可能加一行 ADR 候选（🟠-3）。
- `systems/adventure-event/exchange/_index.md` —— 补一句：逐笔提交与刷新那两处**同时是事件内决策点**（取消点与存档点重合），不新增写入动作。
- `systems/adventure-event/explore/_index.md` —— 补一句：Explore 自身零决策点；揭示后按真身接入该类清单。
- `systems/adventure-event/travel/_index.md` —— 补一句：Travel 零事件内决策点 ⇒ 一经选中不可取消（含 🟠-1 的返回值口径）；结算为纯内存计算。
- `systems/adventure-event/research/_index.md` —— 补一句：槽内选择不落存档，恢复回到面板初始态、候选不变（裁决 1 的落点）。
- `systems/adventure-event/common-properties.md` —— **仅当 🔴-1 取 (a)**：改写 L50–60 那张置换 / 禁用表的「候选何时掷定」与「落存档」两格。
- `systems/adventure-event/research/common-properties.md` —— 可选：`ResearchSlot` 段落补一句「槽内选择不进快照」（与「短缺标记不进快照」同款判据）。**若与其他分片撞车则让出。**
- 新建 handoff：`handoffs/2026-08-22-<slug>-non-combat-decision-points.md`。

> **写入面提示（供 orchestrator 分区）：** `life-cycle-service.md` 与 `adventure-event/common-properties.md` 是高冲突面，其他草稿（如 event-outcome-spec-fields / priority-elevation-conditions）很可能也写它们 —— 建议串行或合并给同一 worker。四份子类型 `_index.md` 与 `research/common-properties.md` 冲突面较低。

## 待移出的 open-questions 条目

- `open-questions/01-combat.md` L20 —— 「**战斗之外的事件类型的决策点清单。**……仍欠 Exchange / Explore / Travel 三类。」⇒ **整条移出**（三类均已给出）。
- `systems/services/life-cycle-service.md` L259 的同名待决项 ⇒ 一并移除（主题文档侧）。
- answer log：`answer-logs/log-remaining-event-decision-points.md`（`draftSuffix` = `remaining-event-decision-points`）。

**新增待答项（Phase B 须并入分片，orchestrator 代笔）：**
- `open-questions/01-combat.md` +1：**Exchange 面板打开是否需要 X0 标记**（`[采纳推荐 — 待复核]`，已按 A 落笔）。
- `open-questions/01-combat.md` +1：**「非战斗类决策点不触发第二次写入」口径的复核**（`[采纳推荐 — 待复核]`，含连带改写的 L209）。
- `open-questions/01-combat.md` +1（**仅当 🔴-1 取 (c)**）：**置换 / 禁用候选的存档承载格未指定**。

## 越界发现

- **`ActiveCombat` / `ActiveEventState` 之外无第三个事件内中间态承载结构**，而 `common-properties.md` 已在置换 / 禁用一处依赖一个不存在的承载。这是本分片之外（「能力剥夺」片区）的问题，已作为 🔴-1 提交裁决，**不擅自处理**。
- `life-cycle-service.md` 的「战斗之外的事件类型的决策点清单」待决项在 `open-questions/01-combat.md` 与主题文档**两处各有一份**，措辞已同步——本次移出须两处同改，否则台账与主题文档漂移。
- `research/_index.md` 与 `ADR-0022` 都称构筑面板是「既有决策点面板的第三个实例」，而三个实例的**候选掷定时点并不一致**（战后奖励 = 收口时、置换 = 结算时、Research = 物化时）。这处不对称本身不是本草稿的范围，但 🔴-1 的选项 (a) 会顺手消掉它。
