# 非战斗四类事件的事件内决策点清单

- id: 2026-08-22-non-combat-decision-points
- date: 2026-08-22
- topic: systems/services/life-cycle-service.md · systems/adventure-event/{exchange,explore,travel,research}/_index.md · systems/adventure-event/research/common-properties.md
- status: distilled
- distilled-to: systems/services/life-cycle-service.md, systems/adventure-event/exchange/_index.md, systems/adventure-event/explore/_index.md, systems/adventure-event/travel/_index.md, systems/adventure-event/research/_index.md, systems/adventure-event/research/common-properties.md

## Intent（distilled）

战斗内的决策点清单 **D0–D6** 已定案；其余四类 AdventureEvent（Research / Exchange / Explore / Travel）的**事件内决策点**此前只有 Research 一条有答案。本次把四类逐类给全，并补一句落地口径。它卡住的是三件事：取消语义的落点（`ct` 只在决策点被观察）、软阻塞闸门的计数口径（闸门只数事件级存档点）、以及「退出重进恢复到同一局面」在非战斗事件上到底承诺了什么。

### ① 判据不另立，只补一句落地口径

判据一字不改地沿用战斗侧的共用公理（**状态机即将停下来等玩家输入，且此前消耗的随机已全部持久化**）。补一句归纳性的落地口径：

> **非战斗四类没有状态机**（resolver 的拆分轴就是「有没有状态机」）⇒ 它们每个决策点的全部可恢复状态**都已被既有的写入覆盖**（`activeEvent` 的整块置值，或即时提交的那一笔）。**故非战斗类的决策点不触发第二次写入**——它只是一个**可退出点**（`ct` 的观察位）。

不写这一句，「决策点 = 存档点」会被读成「每个决策点都要新增一次持久化动作」，在非战斗类上凭空造出一批重复写盘。

### ② 全清单只有五行 + 两条「无」

`R1` Research 逐槽择一（无新增写）· `R2` Research 收口（并入 `eventEnd`）· `X1` Exchange 一笔交易（与既有即时提交重合）· `X2` Exchange 一次刷新（同上 + 同批带 `Shop` 子流 `RngElements`）· `X3` Exchange 收口。**Explore 零自有决策点**（揭示后接入真身那一类的清单）；**Travel 零事件内决策点**（「去哪」发生在批次层）。

**明确不是决策点：** Exchange 面板打开 · Explore 揭示 · Research 面板打开 · Travel 的任何一步 · 战后奖励选择。共同判据是**这一刻有没有新状态产生**，不是形状对不对称。

只给实际存在的点编号，**不为「无决策点」的类造占位编号**——占位编号会诱导后来者去填满它。

### ③ Research 槽的「已选未提交」不落存档

`ActiveEventState` 只有 `EventInstanceId` + `Option` 两格，`Option.ResearchSlots` 装的是**候选**，没有一格装玩家的槽内选择。**裁决：不加格。** 决策点存档的全部理由是关掉「退出重进即重掷」的窗口，而候选在物化时即已掷定并落存档 ⇒ 该窗口本就不存在；剩下的只是几次点击的便利（常态 1 槽 = 0 次重选，开局构筑事件 2 槽 = 至多 1 次），不值一次 schema bump + 一条「槽数 / 索引一致性」读档校验。**恢复回到面板初始态，候选一字不变。**

### ④ 置换 / 禁用候选与 Research 候选的掷定时点统一为「物化时」

置换 / 禁用候选此前写作「结算时（`eventEnd` 之前）掷定并落决策点存档」，而它同样没有承载格。**裁决：前移到物化时掷定，随 `EventOption.AbilityChangeSlots` 落存档**（形状与 `EventOption.ResearchSlots` 同构，仍走 `Reward` 子流）。它顺带消掉「三个决策点面板掷定时点各不相同」这处既有不对称。

**代价明写：`EventOption` 因此多一个物化字段**——本条不再是纯粹的「零结构增量」；`ActiveEventState` 仍不加格。

### ⑤ 零决策点的事件类型上，取消请求不改变本次事件的结局

Travel（含 Explore 揭示出的 Travel）上 `ct` 无处被观察，流程直接走到收口。此时 `AdvanceEventAsync` 返 `AdvanceResult(Success: true, FailedAt: None)`，退出请求在收口**之后**才生效。返 `Cancelled` 会让编排顶点按「这一步还没结束」去处理一个已结束（`pastEvent` 已记）的事件。**推论：Travel 一经选中即不可取消**——其结算是纯内存计算，毫秒级，玩家感知不到。

### ⑥ 与既有纪律的逐条对齐核对：一处也没有需要新增的机制

退出重进恢复同一局面 · 防重掷 · 消耗随机的提交须同批带 `RngElements` · 事件内提交不计软阻塞闸门 · `Immediate` 只在既定五处——四类逐条成立。体积上非战斗四类合计远低于战斗侧的 ≈31 个决策点 / 单点 2–4 KB diff，既有护栏不受影响。

## Clarifications（interview 产物）

- **置换 / 禁用候选另找落点后，正面落点是什么？** → **前移到物化时掷定，落 `EventOption` 上的一个定稿字段**（不是 `OutcomeRule` 增第四个 `Kind`，也不是 `ActiveEventState` 加格）。这**改写了草稿「零结构增量」那句**，也改写了既有的「候选在 `eventEnd` 之前掷定」表述。
- **新口径与「每个决策点立即原子写本地缓存」这句既有承重表述相抵，取哪一侧？** → **改写既有表述**为「每个决策点都是一个可退出点；该时刻若产生了尚未落盘的新状态，则立即原子写本地缓存」。草稿只提出新口径、未点出它连带改写一句承重表述。
- **Travel 零决策点上收到取消请求时 `AdvanceEventAsync` 返什么？**（草稿未说返回值）→ 返 `AdvanceResult(Success: true, FailedAt: None)`，取消在收口后生效，并在取消语义表补一行。依据：`Cancelled` 明写表示「这一步还没结束」，用在已结束的事件上会让编排顶点走错分支。
- **Research 面板中途退出时的返回值与 `activeEvent` 处置？**（草稿把 R1 收窄为「可退出点」时未交代退出后的归宿）→ 照既有返 `Cancelled`、`activeEvent` 保留、重进直接重开面板。否决「中途退出视同放弃、直接收口」——一次误触会白付最贵档的 `lifeSpanCost`。
- **要不要把本清单登记为 ADR 候选？** → **要**，在 `life-cycle-service.md` 的 `## 决策(-> ADR)` 加一行，与战斗侧的「D0–D6 决策点清单」对称。**不建 ADR、不动 `decisions/_index.md`。**
- **Exchange「面板打开」要不要显式 X0 标记？** → **不要**，清单只有 X1 / X2 / X3。判据是「这一刻有没有新状态」，不是「形状对不对称」。`[采纳推荐 — 待复核]`
- **「非战斗类决策点不触发第二次写入」写成明文口径？** → **写**，与决策点清单并列。`[采纳推荐 — 待复核]`

## Open questions

- **`[采纳推荐 — 待复核]`：Exchange 面板打开是否需要 X0 标记。** 已按「不要」落笔；若日后认为与战斗侧 D0 的形状不对称构成阅读负担，可加一行零动作条目。
- **`[采纳推荐 — 待复核]`：「非战斗类决策点不触发第二次写入」口径的复核**，含它连带改写的那句「每个决策点立即原子写本地缓存」。

## Notes / triage

- 本条答结了 `life-cycle-service.md` 与 `open-questions/01-combat.md` 两处同名待决项「战斗之外的事件类型的决策点清单」。
- 顺手删除 `explore/_index.md` 一条已被答定的待决项（事件类型出现概率修正的运算形态 —— 已定为乘性系数，权威在 `systems/game-progression.md` 与 `systems/services/future-event-service.md`）。
- **越界发现（不擅自处理）：** `research/_index.md` 与 `ADR-0022` 都称构筑面板是「既有决策点面板的第三个实例」；三个实例的候选掷定时点此前并不一致（战后奖励 = 收口时、置换 = 结算时、Research = 物化时）。本次把置换前移到物化时，剩余的不对称只在战后奖励一侧，且它已由「奖励选择不是决策点」独立论证过。
