# `Priority = 1` 的抬升判据与同档共现规则

- id: 2026-08-22-priority-elevation-criterion
- date: 2026-08-22
- topic: systems/services/future-event-service · systems/adventure-event/common-properties · systems/adventure-event/combat · systems/adventure-event/research
- status: distilled
- distilled-to: `systems/services/future-event-service.md`, `systems/adventure-event/common-properties.md`, `systems/adventure-event/combat/_index.md`, `systems/adventure-event/research/_index.md`

## Intent（distilled）

**一句话：** 把 `eventPriority` 的抬升从「一张会不断被追加的清单」改写成**一条判据 + 三条与门子判据**，据此把当前清单闭合为三条，明写六条被否决的候选，并判定「同批多个 `1` 档」在当前伪码下结构不可达、不新增收窄规则。

### ① 判据取代清单

> **抬升当且仅当：不抬升会使一条结构性规则失效。**

三条与门子判据：**(a)** 该选项是某条结构性规则的**唯一出口**；**(b)** 收窄条件**由产出侧可确定判定**（配额计数 · 篇章 · `pastEvent` · 角色等级），不读隐藏属性、不读剧本状态；**(c)** 抬升表达的是**结构**，不是难度或叙事。

(b) 是最值钱的一半——它把「PlotManager 只调内容不调约束」从一句纪律变成一条可机械核对的准入条件。

### ② 闭合清单（三条）

| 条件 | 判定式 |
|---|---|
| 配额闸门 Travel | `Status.LocationEventCount >= location.EventCountLimit` |
| 开局构筑事件 | `chapter == 1` 且 `pastEvent` 为空 |
| Finale | `level == 该境界末级`（13 / 17 / 21） |

- **开局构筑事件收窄为「炼气新角色的起始批次」**，判定式读的全是既有可读状态 ⇒ 零结构增量。**ch1 的篇章重试落在收窄之内、照常抬升**；排除的是 ch2 / ch3 的续章与重试。
- **Finale 不写「本篇章尚未结算过 Finale」的守卫**：通过即离开本篇章、失败即角色终结，两支都离开 ⇒ 守卫恒不可达。
- **Finale 抬升与「满级后 Finale 恒进候选池、不参与类型加权」成对成立**（后者已由事件生成 / 加权那条落笔）。

### ③ 被否决的六条候选

剧情线关键节点 (b) · 寿元 Band 2 强制某类事件 (b)+承重取向 · 稀有 / 高价值事件 (c) · 「本批全打不过时抬一个安全选项」(c)+承重定案 · ch2 / ch3 篇章重试后首批 (a) · 付费礼包 / 账号级持有触发的抬升 (b)+分层。

### ④ 同批多个 `1` 档：不新增收窄规则

三条独立依据：**不可达**（闸门分支整批替换；开局构筑事件与闸门互斥；Finale 与闸门互斥、与开局构筑事件在时间上互斥）· **两档语义已含「同档内自由择一」兜底**（零成本、新增抬升条件时自动生效）· **「`1` 档内再排序」等于引入第三档**。

### ⑤ 落地面

零结构增量：不新增字段 / 枚举 / 加载期校验，不 bump 存档 schema；抬升原因不入快照。日志并进既有物化行：`[FutureEvent-Materialize] … prio=<n> prioReason=<QuotaGate|InitialBuild|Finale|None> …`。

## Clarifications（interview 产物）

- **「Travel 闸门与剧情线的强制事件共用同一档」这句既有正文** → **删去后半句**。它与同文件及 `future-event-service.md` 两处明写的「PlotManager 只调内容不调约束」不能同时为真；共现兜底改为中性表述「同批若出现多个 `1` 档，同档内自由择一」。推翻的是草稿「约束」一节照抄的那句既有措辞。
- **开局构筑事件的判定式** → 从草稿的 `本批是 StartCycle 写的第一批 且 CycleStartSpec.SourceCharacterId == ""` **改写为 `chapter == 1 且 pastEvent 为空`**。`CycleStartSpec` 是 `StartCycle` 的入参、不是存档字段，本服务读不到它；改写后才真正兑现草稿宣称的「零结构增量」。
- **ch1 篇章重试的归属** → **算作「新角色首批」、照常抬升**（推翻草稿正文「篇章重试同理」那句与否决表原写的「篇章重试后的首批」整行）。ch1 的篇章起始存档是空白炼气角色，(a) 成立；排除它会让最常走的那条路永远拿不到开局底盘。散文与否决表改为只排除 ch2 / ch3。
- **「本篇章尚未结算过 Finale」守卫** → **不写**。Finale 通过即离开本篇章、失败即角色终结，两支都离开，守卫恒不可达；草稿据以论证守卫承重的那句「失败后可继续消耗寿元找事件」已随 Finale 判定二值化整条消失。连带：草稿要求补写的「每篇章 Finale 各为独立 `Id`」约定不再需要（它只是守卫的前提）。
- **抬升原因的日志形态** → **并进既有 `[FutureEvent-Materialize]` 行**（新增 `prioReason=`），不另开 `[FutureEvent-Priority]` 一行。抬升是逐实例的物化产出，与 `prio` 同源同粒度；根约定的标签形态是 `[System-Method]`，而 `Priority` 不是方法名。
- **Finale 抬升的退让位** → **整条改写**。草稿把「下调 `WinMargin`」列为第一退让位，而 `WinMargin` 在 Finale 档恒为 0、拧它零效果，该退让位本身不成立。改写为：内容侧编排「满级前一批必有一个带 `Recuperate` 的 Research」+ `systems/balance.md` 的三条 Finale 难度校准手段（天劫赋级带位置 · 天劫定制卡组强度 · `TurnLimit`）。仍然**不是**回退抬升。
- **三条子判据写进 `future-event-service.md` 作为准入闸** → 按推荐落笔，标 **`[采纳推荐 — 待复核]`**，同时留在待答清单（不算用户拍板）。

## Open questions

- **三条抬升子判据作为准入闸的密度成本** `[采纳推荐 — 待复核]`：给本服务再加一条必须被后来者遵守的纪律是否值得，还是只保留当前三条清单。→ `systems/services/future-event-service.md`。

## Notes / triage

- 来源草稿：`inbox/solution-draft-priority-elevation-conditions.md`（已评审，`## 仍需用户决定` 三项全部裁决）。因含一项 `[采纳推荐 — 待复核]`，**草稿留在 `inbox/` 顶层**，不归档。
- **越界发现（不在本次写入面内）：** `combat/_index.md` 与 `enemies/*` 侧的样本卡组规模口径、`EncounterTighten` 的字段面——归其它分片。
