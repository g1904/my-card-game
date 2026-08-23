---
type: solution-draft
date: 2026-08-22
question: 战斗之外三类事件（Exchange / Explore / Travel）的事件内决策点清单
source: open-questions/01-combat.md → 「结构与配置的残留」→「战斗之外的事件类型的决策点清单」（亦见 systems/services/life-cycle-service.md 的同名待决项）
targets: systems/services/life-cycle-service.md · systems/adventure-event/exchange/_index.md · systems/adventure-event/explore/_index.md · systems/adventure-event/travel/_index.md · systems/adventure-event/research/_index.md
status: distilled
reviewed: 2026-08-22 — 3 项取向全部裁决；合并 interview 另裁定置换/禁用候选前移到物化时掷定、落 EventOption 定稿字段（故「零结构增量」那句须改写）· life-cycle-service 的「每个决策点立即原子写」全称表述一并改写 · Travel 零决策点上取消请求返 Success 且取消在收口后生效 · Research 中途退出照既有返 Cancelled 并保留 activeEvent。**待复核 2 项**：X0 标记 · 不触发第二次写入口径
confirmed: 2026-08-22 —— 全部 [采纳推荐 — 待复核] 项经批量评审确认，无推翻；其中「非战斗类决策点不触发第二次写入」一项**连带确认**它对 life-cycle-service「每个决策点立即原子写本地缓存」全称表述的改写（降为「该时刻若产生了尚未落盘的新状态才写」）
distilled-to: handoffs/2026-08-22-non-combat-decision-points.md
---

# 方案草稿 — 非战斗四类事件的事件内决策点清单

## 问题

战斗内的 **D0–D6** 已定案（见 `systems/services/combat-service.md`）；其余四类 AdventureEvent 的**事件内决策点**尚未逐类给出。**Research 那一条已给出**（构筑面板的每个决策槽各是一个决策点，候选在物化时即已掷定），**仍欠 Exchange / Explore / Travel 三类**。五类共享同一形状，清单应当很短。

它卡住的是三件事：**取消语义的落点**（`ct` 只在决策点被观察）、**软阻塞闸门的计数口径**（闸门只数事件级存档点）、以及**「退出重进恢复到同一局面」这条承诺在非战斗事件上到底承诺了什么**。

## 约束（来自既有设计）

- **共用公理**（combat-service 明写，本条沿用不另立）：**决策点 = 战斗状态机唯一可以停下来的地方**；判据 = 「状态机即将停下来等玩家输入的时刻，**且该时刻之前消耗的随机已全部反映在持久化的 RNG `State` 里**」。
- **取消点与存档点永远重合**：`ct` 只在决策点被观察（推进到下一个决策点 → 持久化 → `ThrowIfCancellationRequested()` → 等玩家输入）⇒ **中间态永不需要持久化**。→ `systems/services/life-cycle-service.md`
- **事件内部的主动消费即时提交**（两条判据缺一不可：① 玩家主动按下的一次消费 ② 不即时写就开出「退出重进即回滚」的窗口或影子余额）；**事件的后果一律留到收口**。当前四个实例：古宝使用次数 · 战斗内血 / mana · Exchange 逐笔交易 · Exchange 刷新。→ `systems/adventure-event/common-properties.md`
- **一次提交即一次本地原子写**；「不新增存档点」说的是**不新增决策点与存档点类型**，不是「这一次提交不落盘」。→ 同上
- **事件内提交不计软阻塞闸门**（闸门只数事件级存档点；连按刷新不弹模态）。→ `systems/adventure-event/exchange/_index.md`
- **奖励选择不是决策点**：候选在收口时一次算定、退出重进得到同一组选项 ⇒ 无需为它单独落点；D6 并入 `eventEnd` 的单一事务存档点。→ `systems/services/combat-service.md`
- **置换 / 禁用的施加是一个事件内决策点**，候选走 `reward` 子流掷定并**落决策点存档**。→ `systems/services/life-cycle-service.md`
- **`ActiveEventState` 只有两格**：`EventInstanceId` + `Option`（派生后的定稿实例）。**没有承载「玩家已做出但尚未提交的选择」的格。** → `systems/character-profile/_index.md`
- **Explore 的揭示不新增决策点、不新增存档点类型**，但 `TryApply(EventStateChanges[ActiveEvent = revealed])` 的本地写照常发生；三种真身各自的第一个可退出点都是既有的。→ `systems/adventure-event/explore/_index.md`
- **Travel 的写入由 life-cycle-service 在 `eventEnd` 组装**（`GenericEventResolver` 对 Travel **不产出任何写入描述**）。→ `systems/services/life-cycle-service.md`
- **`Immediate` push 只在既定五处**：篇章边界 · 轮回结束 · `defeated` · 进入战斗前 · 应用失焦；其余 `Debounced`（5 秒）。→ 同上
- **凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 必须在同一次原子写内更新**（不变式）。→ 同上

## 建议方案

### ① 沿用战斗侧那条判据，不为非战斗类另立

`[既有推演]`

判据一字不改。但要补一句**落地口径**，它不是新规则，是既有事实的归纳：

> **非战斗四类没有状态机**（resolver 拆分轴就是「有没有状态机」）⇒ 它们的每个决策点，其**全部可恢复状态都已被既有的写入覆盖**（`activeEvent` 的整块置值、或即时提交的那一笔）。**故非战斗类的决策点不触发第二次写入**——它只是一个**可退出点标记**（`ct` 的观察位）。

这一句必须写下来，否则「决策点 = 存档点」会被读成「每个决策点都要新增一次持久化动作」，而在非战斗类上那会凭空造出一批重复写盘。

### ② 四类清单（Research 补全 + 三类新给）

`[既有推演]`

| 类 | # | 决策点 | 精确时刻 | 持久化 | push policy |
|---|---|---|---|---|---|
| **Research** | **R1** | 每个决策槽的择一 | 面板呈现该槽、等待玩家点选那一刻（逐槽，共 `ResearchSlots.Length` 个） | **无新增写**——候选已在 `activeEvent.Option.ResearchSlots` 里（物化时掷定并随批落存档） | — |
| | **R2** | 收口 | 全部槽选完 + `lifeSpanCost` 合并 | 并入 `eventEnd` 的**单一事务存档点** | 随 `eventEnd` |
| **Exchange** | **X1** | 一笔购买 / 售出结算完毕 | 该笔 `TryApply` 提交之后、面板回到可操作态 | **与既有即时提交重合**（本地立即原子写） | `Debounced` |
| | **X2** | 一次刷新结算完毕 | `TryApply(-jade + 新库存 + RerolledCount+1)` 提交之后 | 同上；**同批带 `Shop` 子流的 `RngElements`** | `Debounced` |
| | **X3** | 收口 | 玩家点「离开」 | 并入 `eventEnd` 的单一事务存档点 | 随 `eventEnd` |
| **Explore** | — | **无自有决策点** | 揭示不是决策点（既有定案） | 揭示的 `EventStateChanges[ActiveEvent = revealed]` 照常本地写 | `Debounced` |
| | — | 揭示后**接入真身那一类的清单** | Combat 真身 → D0–D6；Exchange 真身 → X1–X3；Travel 真身 → 无 | — | — |
| **Travel** | — | **无事件内决策点** | 「去哪」发生在**批次层**（就是「择一进入」本身），不是事件内部 | — | — |
| | — | 收口 | `eventEnd` | 单一事务存档点 | 随 `eventEnd` |

**⇒ 全清单只有五行（R1 / R2 / X1 / X2 / X3），另加两条「无」。** 与「清单应当很短」的预判一致。

**逐条依据：**

- **X1 / X2 与既有即时提交逐字重合，这不是巧合。** 「事件内主动消费即时提交」的两条判据（玩家主动按下 · 不即时写就开出回滚窗口）与决策点判据（等玩家输入 · 随机已持久化）在 Exchange 上指向**同一批时刻**。**故 Exchange 的决策点清单不新增任何写入动作，只是给既有的四个即时提交实例中的两个贴上「这里也是取消点」的标签。**
- **Exchange「面板打开」不单独落点**：该时刻的全部状态（库存 · `RerolledCount` · 已扣的 `SelectCost`）已由 `TryApply(SelectCost + EventStateChanges[ActiveEvent])` 那一次覆盖；恢复即读 `activeEvent.Option.ExchangeStock` 直接呈现（既有明写「绝不重走取池链」）。
- **Explore 零自有决策点**是既有定案的直接改写：`ct` 只在决策点被观察 ⇒ 揭示与随后进入的第一个决策点之间不存在可退出窗口；重进后 `IsRevealed == true` ⇒ 直接呈现真身、不再播转场。
- **Travel 零事件内决策点**：整条结算路径上**没有任何玩家输入**——目的地在物化时已掷定并落在 `DestinationLocationId` 上，两条 `StatusAssignment` 由 life-cycle-service 在 `eventEnd` 组装。**推论（代价明写）：Travel 一经选中即不可取消**——`ct` 无处被观察，流程直接走到收口。这落在既有的「取消不是即时的」语义内，且 Travel 的结算是纯内存计算，毫秒级，无实际影响。
- **R1 的「无新增写」是本清单最容易被写错的一格**，见 ③。

### ③ 承重发现：Research 槽的「已选未提交」没有承载格

`[取向选择]` —— 见「仍需用户决定」第 1 项，推荐**不新增字段**。

R1 被登记为决策点，但**「决策点存档要存什么」在 Research 上没有答案**：`ActiveEventState` 只有 `EventInstanceId` + `Option` 两格，`Option` 里的 `ResearchSlots` 装的是**候选**（物化时掷定），**没有一格装「玩家在槽 0 选了第 2 个候选」**。而 Research 的选择明写「全部选择与 `lifeSpanCost` 合并为 `eventEnd` 的一次 `TryApply`」——即它们是**后果**，不走即时提交（不满足即时提交的判据 ①：它不是一次消费）。

**⇒ 玩家在多槽面板上选了一半退出，重进时会回到面板初始态。** 这需要一次明确的裁决，而不是让它作为一处实现分歧留着。

**推荐不新增字段**，三条依据：

1. **防重掷已由候选定稿闭合**：候选与 `ManaDelta` 在物化时即已掷定并落存档，退出重选**拿不到不同的候选** ⇒ 不存在可利用的窗口，而决策点存档存在的**全部理由**就是关掉这类窗口。
2. **代价极小且可量化**：常态条目 1 个槽（重选 = 0 次多余点击）、开局构筑事件 2 个槽（至多重选 1 次）。
3. **加一格要 bump 存档 schema，还要连带一条「槽数 / 索引一致性」读档校验**（overlay 改了 `CandidateCount` 之后旧索引可能越界）——用一条新校验换几次点击不成比例。

**落地为一句明写**（避免后来者把它读成遗漏）：「Research 的槽内选择**不落存档**；决策点在此的语义是**可退出点**，恢复回到面板初始态、候选一字不变。」

### ④ 与「决策点粒度 ↔ 存档点」纪律的逐条对齐核对

`[既有推演]`

| 既有不变式 | Research | Exchange | Explore | Travel |
|---|---|---|---|---|
| 退出重进恢复到**同一局面** | ✅ 候选不变（选择不保留，见 ③） | ✅ 已买的已落账、库存已落存档 | ✅ `IsRevealed` 已落，直接呈现真身 | ✅ 无中间态 |
| **防重掷**（退出重进不能重掷） | ✅ 候选 + `ManaDelta` 物化时掷定 | ✅ 刷新价与新库存同一次 `TryApply` | ✅ 真身与 `DestinationLocationId` / `Encounter` 物化时掷定 | ✅ 目的地物化时掷定 |
| 消耗随机的提交须同批带 `RngElements` | ✅ 无事件内随机消耗（候选已掷完）⇒ 无义务 | ✅ 刷新消耗 `Shop` 子流 ⇒ **X2 必须同批带**（既有不变式，本清单不新增） | ✅ 揭示不掷骰 ⇒ 无义务 | ✅ 无义务 |
| 事件内提交**不计**软阻塞闸门 | ✅（无提交） | ✅（既有明写） | ✅ | ✅ |
| `Immediate` 只在既定五处 | ✅ | ✅ 全部 `Debounced`（失焦时另由既定规则兜底） | ✅ 真身为 Combat 时 D0 走「进入战斗前」那个既定 `Immediate` 点 | ✅ |

**一处也没有需要新增的机制。**

### ⑤ 密度与体积：非战斗四类合计远低于战斗

`[既有推演]`

| 类 | 事件内决策点数 | 单点 diff |
|---|---|---|
| Research | 1–2（等于槽数）· **零写盘** | 0 |
| Exchange | 交易笔数 + 刷新次数（典型 0–5） | 一笔交易的 spec，数百字节量级 |
| Explore | 0（+ 真身那一类） | 揭示一次整块 `ActiveEvent` 置值 |
| Travel | 0 | 0 |
| （对照）Combat | ≈ 31（上界） | 2–4 KB |

**推论：既有的体积护栏与 push 频率讨论完全由战斗侧主导，非战斗四类不构成任何新压力**——这也解释了为什么本条清单可以这么短。

## 具体形态（可 derive 的落地面）

**写进 `systems/services/life-cycle-service.md`（与 combat-service 的 D0–D6 表并列的一张表）：**

```
非战斗四类的事件内决策点（判据同 combat-service 的共用公理）

R1  Research 槽择一   逐槽，面板等待点选那一刻      不落第二次写（候选已在 activeEvent.Option）
R2  Research 收口     全槽选完                     并入 eventEnd 单一事务存档点
X1  Exchange 一笔交易 该笔 TryApply 提交之后        与既有即时提交重合         Debounced
X2  Exchange 一次刷新 该次 TryApply 提交之后        同上，必须同批带 Shop 子流 RngElements   Debounced
X3  Exchange 收口     玩家点「离开」                并入 eventEnd 单一事务存档点
—   Explore           无自有决策点；揭示不是决策点；揭示后接入真身那一类的清单
—   Travel            无事件内决策点；「去哪」在批次层；一经选中不可取消（ct 无观察位）

明确不是决策点：Exchange 面板打开 · Explore 揭示 · Research 面板打开 · Travel 的任何一步 ·
                战后奖励选择（既有）
```

**连带三处子类型文档各补一句**（各自的权威页，不复述）：

- `exchange/_index.md`：「逐笔即时提交的那两处**同时是事件内决策点**（取消点与存档点重合），不新增写入动作。」
- `explore/_index.md`：「Explore 自身零决策点；揭示后按真身接入该类清单。」（既有已写「揭示不新增决策点」，此处补全另一半）
- `travel/_index.md`：「Travel 零事件内决策点 ⇒ 一经选中不可取消；结算为纯内存计算，毫秒级。」
- `research/_index.md`：「槽内选择不落存档，恢复回到面板初始态、候选不变。」（③ 的裁决落点）

**零结构增量**：不加字段、不加枚举、不 bump 存档 schema、不新增存档点类型、不新增 push policy。

## 后果

- **改动面**：`systems/services/life-cycle-service.md`（新增一张表 + 落地口径一句，并移除同名待决项）· `systems/adventure-event/exchange/_index.md` · `explore/_index.md` · `travel/_index.md` · `research/_index.md`（各补一句）。
- **解锁面**：`AdvanceEventAsync` 的取消语义在四个非战斗类上闭合（此前只有战斗侧有观察位清单）；软阻塞闸门的计数口径在四类上闭合；`life-cycle-service` 的 blocked 理由减一条。
- **不解锁的**：`life-cycle-service` 仍卡在 `Project(spec)` 语义面（已于 08-19 大部收口）· `experiencePoint` 阈值 · 隐藏属性增减触发 · 重试上限存档表达 —— 本条不触及。

## 备选方案（已考虑并否决）

- **给每类事件各定义一套 Dx 编号**（如 X0–X3、R0–R2、E0、T0）—— 部分采纳：只给实际存在的点编号（R1/R2/X1–X3），**不为「无决策点」的类造占位编号**。造占位编号会诱导后来者去填满它。
- **把 Exchange 面板打开也列为决策点** —— 否决：该时刻的全部状态已被 `TryApply(SelectCost + ActiveEvent)` 覆盖，列进去只会诱发一次无内容的重复写。
- **给 Research 槽的中途选择加存档格** —— 见 ③，列为取向题；推荐否决。
- **为 Travel 造一个「确认前往」的事件内确认步** —— 否决：「去哪」已经是批次层的一次真实选择，再加一次确认就是在最频繁的操作上加一次模态，与「玩家主动退出取静默退出、不做二次确认弹窗」的手感取向反向。
- **把揭示升格为决策点** —— 否决（既有已论证）：换到的只是「强杀后不重播一次转场动画」，而重进只重看、不改真身。

## 与既有决策的张力

**一处，轻。** 「置换 / 禁用的施加是一个事件内决策点，候选走 `reward` 子流掷定并**落决策点存档**」——它明写要落存档；而本方案对形状**完全同构**的 Research 面板判定为「不落第二次写」。两者的差别是实在的、且理由充分：

- **置换候选在 `eventEnd` 之前的结算侧掷定**（走 `reward` 子流），此前**不在任何已落存档的结构里** ⇒ 必须落一次，否则重进即重掷；
- **Research 候选在物化时掷定、已随 `EventOption` 落存档** ⇒ 重进读得到同一组候选，不需要第二次写。

**建议在文档里把这条差别写明**（「掷定时点不同 ⇒ 存档义务不同」），否则两处会被读成互相矛盾的处置。**置换候选落在哪个结构上本身仍是一个未写明的点**（`ActiveEventState` 同样没有承载格），见「前置依赖」。

## 前置依赖

- **置换 / 禁用候选的存档承载格未指定。** 既有明写「落决策点存档」，但 `ActiveEventState` 只有两格、`ActiveCombat` 是战斗专属 ⇒ **它当前没有落点**。这条**不阻塞本草稿**（置换面板不在本分片的三类里，且它属「能力剥夺」片区），但它与 ③ 是同一形状的问题，**建议在同一场里一并裁决**——若第 1 项选了「加一格」，置换候选正好共用它。
- **战斗内运行态计数器的字段形态**（`CharacterPower` / `PlayerPower` 的本场触发次数、`PlayerItem` 的本场剩余次数，见 `open-questions/01-combat.md`）—— 战斗侧的残留，与本条正交。
- **`future-event-service` 的生成 / 加权运算形态**（🔴）—— 与本条完全正交（决策点发生在事件已被选中之后）。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> 逐条裁决（`/batch-provide-solution-draft` 合并 interview）：
> 1. Research 槽的「已选未提交」是否落存档 → **已裁决：A · 不落**（`ActiveEventState` 不加格；本项与「置换 / 禁用候选的承载格」作为同形问题合并裁决 ⇒ **置换候选另找落点，不共用新格**）
> 2. Exchange 的「面板打开」要不要显式 X0 标记 → **A · 不要** `[已确认 2026-08-22 · 批量评审]`
> 3. 是否把「非战斗类决策点不触发第二次写入」写成明文口径 → **A · 写进 `life-cycle-service.md`** `[已确认 2026-08-22 · 批量评审]`
>    —— **连带一并确认**：这条口径改写了 `life-cycle-service.md`「每个决策点立即原子写本地缓存」那句**全称表述**，降为「**该时刻若产生了尚未落盘的新状态才写**」。用户在 2026-08-22 合并 interview 中连同该连带一并确认。
>
> **全部待复核项已于 2026-08-22 经批量评审逐项确认，本草稿再无待复核项。**


1. **Research 槽的「已选未提交」是否落存档？**（承重 —— 此前无答案）
   - **选项 A（推荐）**：**不落**。决策点在 R1 的语义收窄为「可退出点」，恢复回到面板初始态、候选一字不变。后果：多槽面板中途退出会丢失已做的选择（常态 1 槽 = 无影响；开局 2 槽 = 至多重选一次）；零结构增量。
   - **选项 B**：给 `ActiveEventState` 加一格（如 `IReadOnlyList<int> ChosenCandidateIndex`，`-1` = 未选 / 弃权）。后果：中途选择被保留；代价 = bump 存档 schema + 一条读档一致性校验（槽数与索引越界，overlay 调低 `CandidateCount` 后旧档会撞上）+ 置换面板可以共用这一格（见「前置依赖」）。
   - **理由**：决策点存档的**全部理由**是关掉「退出重进即重掷」的窗口，而 Research 候选在物化时就已掷定并落存档 ⇒ 该窗口本就不存在；剩下的只是几次点击的便利，不值一次 schema bump + 一条新校验。**但若用户打算同时给置换候选找承载格，B 的边际成本会显著下降**，故留给裁决。

2. **Exchange 的「面板打开」要不要一个显式的决策点标记？**
   - **选项 A（推荐）**：**不要**，清单只有 X1 / X2 / X3。后果：清单最短；玩家在「进店但一件没买」时退出，恢复读 `activeEvent` 即得同一店面（既有保证）。
   - **选项 B**：列一个 X0（面板打开），持久化沿用既有的 `SelectCost + ActiveEvent` 那一次、不新增写。后果：清单与战斗侧的 D0（战斗开始）形状更对称，读者少一处「为什么战斗有 D0 而商店没有」的疑问；代价是清单里多一行零动作的条目。
   - **理由**：D0 之所以存在，是因为**参战方组装**（含 `Power` 入场、洗牌）在它之前发生且必须被持久化；Exchange 的对应物（库存）在**物化时**就已落存档，进店那一刻没有任何新状态产生。**判据是「这一刻有没有新状态」，不是「形状对不对称」。**

3. **是否把「非战斗类的决策点不触发第二次写入」写成一条明文口径？**（见 ①）
   - **选项 A（推荐）**：写进 `life-cycle-service.md` 与决策点表并列。后果：防住「决策点 = 必须写一次盘」这一处必然发生的误读。
   - **选项 B**：不写，靠清单里「持久化」那一列自明。后果：文档更短；但该列写的是「不落第二次写」这种否定式表述，缺一句解释为什么它成立。
   - **理由**：本条的三个「无」（Explore / Travel 零决策点、Research 零写盘）都会让读者怀疑是不是漏了，一句判据比三处否定更省。
