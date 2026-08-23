# Phase A — priority-elevation-conditions

来源草稿：`game-design-documents/inbox/solution-draft-priority-elevation-conditions.md`（已评审，`## 仍需用户决定` 三项全部裁决）
目标库：`game-design-documents/`

## 一句话意图

把 `Priority = 1` 的抬升从「一张会不断被追加的清单」改写成**一条判据 + 三条与门子判据**（唯一出口 / 产出侧可确定判定 / 表达结构而非难度叙事），据此闭合当前清单为**三条**（配额闸门 Travel · 开局构筑事件（收窄为新角色首批） · Finale），明写六条被否决的候选，并判定「同批多个 `1` 档」在当前伪码下结构不可达、**不新增收窄规则**；落地面宣称零结构增量（不加字段 / 枚举 / 校验、不 bump schema）。

## 已裁决（不进 interview）

1. **Finale 抬升为 `Priority = 1`** —— A · 抬升。`game-progression.md` 那条「多重进度闸」的警惕由用户裁定不阻挡；退让位为下调 `WinMargin`，而非回退抬升。
2. **开局构筑事件收窄为「新角色首批」** —— A · 收窄；`research/_index.md`「起始批次中必有一个强制事件」须改为「**炼气新角色**的起始批次」。
3. **三条子判据写进 `future-event-service.md` 作为准入闸** —— A，标 `[采纳推荐 — 待复核]`（按批量契约，该项须同时留在待答清单，不算用户拍板）。
4. 判据本体、否决表六条、「同批多个 `1` 档不新增收窄规则」、`PriorityReason` 不落存档、不开第三档 —— 均为 `[既有推演]`，与既有定案一致，不再出题。

## 🔴 冲突

### 🔴-1 「剧情线的强制事件与 Travel 闸门共用 `1` 档」这句既有正文，与本稿 ③ ④ 正面相抵

- **[问题陈述]** 本稿 ③ 用子判据 (b) **否决剧情线关键节点的抬升**，④ 据此断言「同批多个 `1` 档结构上不可达」。
  ✗ `systems/adventure-event/common-properties.md:78` 原话：「Travel 闸门用的『最高优先级』就是 `1`，**与剧情线的强制事件共用同一档**——两者同批出现时玩家在它们之间自由择一。」
  该句同时预设了「剧情线有强制事件（= 会被抬到 `1`）」与「它可与闸门同批共现」，两个预设本稿都要推翻。
  （旁证：同文件 `:76` 与 `future-event-service.md:87` 已明写「PlotManager 不得改变它 / 剧本的强制性只能靠收窄候选池表达」——`:78` 这半句本就是与之打架的既有残留，本次是收口它的窗口。）
  - **(a) 改写 `:78`**：删去「与剧情线的强制事件共用同一档」，保留「两档 ⇒ 无层叠语义」这一结论，把共现兜底改写为中性表述（「同批若出现多个 `1` 档，同档内自由择一」）。后果：`common-properties.md` 一处正文改写；本稿 ③ ④ 站得住。
  - **(b) 保留 `:78` 原意**（承认剧情线可有 `1` 档强制事件）。后果：子判据 (b) 被架空、否决表第一行作废、「多个 `1` 档不可达」不成立，须真写一条同档收窄规则——而那被本稿论证为「第三档的变体」。
  - **推荐 (a)**。理由：置位方唯一 + 「PlotManager 只调内容不调约束」是两处明写的承重边界，`:78` 的那半句与它们不能同时为真；且 (b) 会连带推翻本稿 ④ 的全部三条依据。

### 🔴-2 开局构筑事件的判定式读的是产出侧读不到的东西（「零结构增量」前提不成立）

- **[问题陈述]** 本稿把判定式写成 `本批是 StartCycle 写的第一批 且 CycleStartSpec.SourceCharacterId == ""`。
  ✗ `CycleStartSpec` 是 `life-cycle-service.StartCycle` 的**入参**（`life-cycle-service.md:68`），不是存档字段；`systems/character-profile/_index.md` 的字段表里**没有 `sourceCharacterId`**。
  ✗ 而 `future-event-service.md:89` 明写「本服务不持有跨批次的状态；批与批之间唯一的信息通道是 CharacterProfile 本身」——本服务无从读到那个 spec。
  ⇒ 照字面落笔，要么给 `CharacterProfile` 加一格（bump schema，直接推翻本稿「零结构增量」与⑤），要么给本服务开一个入参口子（推翻「无记忆」）。
  - **(a) 改写为等价的可读形态**：`chapter == 1 且 pastEvent 为空`（`chapter` 是既有字段 `#5`；`pastEvent` 是本服务的一等输入）。后果：真正零结构增量；语义等价——`SourceCharacterId` 非空只出现在 ch2 / ch3 续章上，故 `chapter == 1` ⟺ 炼气新角色；`pastEvent` 为空 ⟺ StartCycle 写的那一批。**副产品：它自动把 ch1 篇章重试算作「新角色首批」**（见 🔴-3）。
  - **(b) 给 `CharacterProfile` 增一格 `sourceCharacterId`**。后果：schema bump + 读档校验 + 迁移路径，换来的只是一个可由 `chapter` 推出的量。
  - **(c) 由 life-cycle-service 在调用时把「这是首批」作为参数传入**。后果：本服务多一个入参、且是一处跨批次状态的入口。
  - **推荐 (a)**。理由：既有字段已足够，(b) (c) 各自撞上一条明写纪律。

### 🔴-3 ch1 篇章重试：判定式包含它，散文排除它（本稿自相矛盾），且排除会让重开的炼气角色没有开局底盘

- **[问题陈述]** 本稿正文写「**篇章重试同理**（`RetryChapter` 从该篇章起始存档带回全部信息）」，据此把重试首批排除在抬升之外；裁决项 2 的选项 A 也写「排除 ch2 / ch3 续章**与篇章重试**」。
  ✗ 但它给出的判定式 `SourceCharacterId == ""` **恰恰把 ch1 重试算进来**（ch1 重试的角色仍是炼气新角色）。
  ✗ 且 `life-cycle-service.md:32` 明写「篇章重试 = 重开一局……角色状态按 ADR-0004 从**该篇章起始存档**带回」——ch1 的篇章起始存档就是**尚未做过任何构筑的空白炼气角色**，「开局底盘」这条结构性规则在它身上**成立**，(a) 子判据成立。排除它 ⇒ ch1 重试（上限无限，是最常走的一条路）永远拿不到那门功法与那件法宝。
  - **(a) ch1 重试算「新角色首批」，照常抬升**（= 判定式原样，散文改为「排除 ch2 / ch3 的续章与重试」）。后果：`research/_index.md` 的收窄措辞写成「**炼气新角色的起始批次**（含 ch1 篇章重试）」。
  - **(b) 一律排除全部重试**。后果：需在判定式里另加「非重试」条件——而 `CharacterProfile` 上没有「本局是不是重试」的可读标记（`chapterRetry` 是计数，不区分本局），要新增字段；且 ch1 重试的角色开局底盘残缺。
  - **推荐 (a)**。理由：与 (a) 子判据、与「篇章继承 = 全部继承」的实际含义（ch1 无可继承）都一致，且零新增字段。

### 🔴-4 「本篇章尚未结算过 Finale」这条守卫：既可能不可达，也可能是防止轮回卡死的唯一一道闸——两读法必须先定一个

- **[问题陈述]** 本稿伪码含 `且 本篇章尚未结算过 Finale`，读取源写为「`pastEvent` 中是否存在 `EventId` 指向本篇章 Finale 条目的痕迹」，并称「不新增字段」。三处问题：
  - ✗ **读法冲突。** `combat/_index.md:45` 「Finale 失败但存活 ⇒ **篇章照常完成、境界照常突破**」+ `:36`「通过后……**等级归位为新境界的初期**」⇒ 任何 Finale 结算后 `level == 末级` 立刻为假，守卫**不可达**（纯负债）。但同文件 `:42` 又写「失败后 `lifeTotal` 未归零**即可继续消耗寿元找事件**」，字面读作**角色仍留在本篇章内**——若如此，则**没有这条守卫，满级角色会被永久锁死在一个已不可再战的 Finale 上（`EffectivePriority` 恒为 1、批内无 Finale ⇒ 无可选项），轮回卡死**。两句在同一份文档里，本次必须择一。
  - ✗ **判定不可机械化。** `PastEventEntry`（`common-properties.md:221-237`）**没有 chapter 坐标**（对照：`DisabledAbilityEntry` 有 `AppliedAtChapter`）。「本篇章的 Finale」要成立，必须依赖「**每篇章各有独立的 Finale 条目 `Id`**」这一前提——库里从未明写（`combat/_index.md` 只写「每篇章只有一个 Finale」，`Id` 层面的一一对应没写）。
  - **(a) Finale 结算即离开本篇章**（`:45` 为准，`:42` 那半句改写为「继续在下一篇章消耗寿元找事件」）+ **不写守卫**，伪码只留等级条件。后果：伪码最短；风险全押在「等级归位」这一条上。
  - **(b) 同 (a) 的读法，但保留守卫作为防呆**，并同时明写「每篇章的 Finale 是各自独立的内容条目 `Id`」。后果：多一条 `pastEvent` 扫描 + `combat/_index.md` 补一句 `Id` 层面的约定；换来「即使等级归位那条日后被改动，也不会卡死轮回」。
  - **(c) `:42` 为准（失败存活后仍留在本篇章）**：守卫是承重的，必须写，且 `combat/_index.md:45` 的「篇章照常完成」需改写澄清时点。后果：改动面扩到 `combat/_index.md` 与 `game-progression.md:13-15`，超出本稿宣称的改动面。
  - **推荐 (b)**。理由：它不需要裁决 `:42` / `:45` 哪句更权威（两读法下都安全），代价只是一条扫描与一句 `Id` 约定；而 (a) 把「不卡死轮回」这件事托付给另一份文档的一句话，(c) 的改动面最大且与 `:45` 的「承重」标注正面相撞。

## 🟠 含糊

### 🟠-1 抬升原因的日志落成独立一行，还是并进既有物化日志

- **[问题陈述]** 本稿建议新增 `[FutureEvent-Priority] batch=<BatchId> elevated=<InstanceId> reason=<QuotaGate|InitialBuild|Finale>`。
  含糊点：既有日志是 `[FutureEvent-Materialize] instance=… prio=<n> …`（`future-event-service.md:84`），已带 `prio`；且根约定的标签形态是 `[System-Method]`（`.claude/rules/Context.md`），而 `Priority` 不是方法名，`ComputeEventOptions` / `Materialize` 才是。
  - **(a) 并进既有行**：`[FutureEvent-Materialize] … prio=<n> prioReason=<QuotaGate|InitialBuild|Finale|None>`。后果：不新增日志点、标签仍是方法名、逐实例可对齐。
  - **(b) 保留独立一行**，标签改为 `[FutureEvent-ComputeEventOptions]`。后果：抬升事件按批出现一行，回溯时更醒目；但同一件事分散在两行。
  - **推荐 (a)**。理由：抬升是**逐实例的物化产出**，与 `prio` 同源同粒度；标签规范也天然满足。

## 🔵 可推演

- **满级恰逢配额用尽 ⇒ 先 Travel 一次再渡劫**，且不会丢失 Finale。依据：闸门分支整批替换（`future-event-service.md:21-30`）、Travel 不计入配额（`:37`）、`Finale 不绑定 location`（`game-progression.md:152`、`travel/_index.md:58`）⇒ Travel 后新 location 的 `LocationEventCount == 0`，走常规分支，等级条件仍成立。
- **`Priority` 的既有形态一律不动**：`int` 载体、物化后断言 `Priority ∈ {0,1}`、不设加载期校验、`PastEventEntry.Priority` 已落存档 ⇒ 抬升原因无需入快照（可由 `Priority` + `LocationId` / `Seq` / 等级重算，符合快照判据）。依据：`common-properties.md:77`、`:214`、`future-event-service.md:83`。
- **Finale 抬升并非新决策，而是把既有断言补全。** `combat/_index.md:49` 已明写「**Finale 的出现条件 = 角色已达本境界巅峰**——不需要新机制，`eventPriority = 1` 已能表达」。⇒ 待答清单 `open-questions/02-event-options.md:10` 那句「配额闸门与开局构筑事件之外还有哪些」其实早已被主题文档超前回答；本次是把它写实并补上代价，不是推翻。**（台账与主题文档的一处既有漂移，报告点名。）**
- **零结构增量成立（在 🔴-2 / 🔴-4 按推荐落笔的前提下）**：三条抬升条件读的全是既有可读状态——`Status.LocationEventCount` · `chapter` · `pastEvent` · `realm` + `level`。

## 拟改动文档清单（供跨草稿核对）

- `systems/services/future-event-service.md`：在「选择约束只有一条轴」小节下补 **① 抬升判据 + 三条与门子判据**（标 `[采纳推荐 — 待复核]`）· **② 当前闭合清单三条**（配额闸门 / 开局构筑事件 / Finale，各带判定式）· **③ 否决表六条** · **④ 「同批多个 `1` 档不新增收窄规则」及其三条依据** · **⑤ 置位段伪码**（落在既有 `ComputeEventOptions` 描述内，不新增方法）· **⑥ 日志一处**（按 🟠-1 的裁决落形）。
- `systems/adventure-event/common-properties.md`：`eventPriority` 小节补「抬升判据」一段（回链本服务，不复述三条子判据全文）；**改写 `:78`「与剧情线的强制事件共用同一档」**（按 🔴-1 裁决）。
- `systems/adventure-event/combat/_index.md`：`Finale` 档补「**Finale 以 `Priority = 1` 出场**」及其代价（满级即封锁其余选项 / 取消备战窗口 / 退让位为 `WinMargin`）；按 🔴-4 裁决可能另补「每篇章的 Finale 各为独立内容条目 `Id`」，以及 `:42` 那半句的措辞澄清。
- `systems/adventure-event/research/_index.md`：`:9`「起始批次中**必有**一个强制事件」→「**炼气新角色**的起始批次」；`### 开局构筑事件` 小节 `:69` 的判定式按 🔴-2 / 🔴-3 的裁决写实。
- （可能）`systems/game-progression.md`：仅当 🔴-4 选 (c) 时才触及 `:13-15`；按推荐 (b) 则**不动本文件**。

> **与其它分片的写入面重叠预警**：`future-event-service.md` · `adventure-event/common-properties.md` 是本库高频写入面，`future-event-generation-weighting` 那份草稿几乎必然同写前者（生成 / 加权段）。两者落笔须串行或合并给同一 worker。

## 待移出的 open-questions 条目

- `open-questions/02-event-options.md:10` —— 「**`Priority = 1` 依什么条件抬升（08-06c 收窄）**」**整条移出**（两个待定点——抬升条件、同档共现规则——本次均已裁决）。
  - answer log 文件名：`answer-logs/log-priority-elevation-conditions.md`（草稿为 `solution-draft-priority-elevation-conditions.md`）。
  - 拟记三条：① 抬升判据 = 「不抬升会使一条结构性规则失效」+ 三条与门子判据（→ `future-event-service.md`）；② 清单闭合为三条，Finale 采纳抬升、开局构筑事件收窄为炼气新角色首批（→ `future-event-service.md` / `research/_index.md` / `combat/_index.md`）；③ 同批多个 `1` 档不新增收窄规则（结构不可达 + 两档语义已含兜底）（→ `future-event-service.md`）。
- **新增待答（本次产生，须并回 `02-event-options.md`）**：「三条抬升子判据作为准入闸的密度成本 —— `[采纳推荐 — 待复核]`」（按批量契约，采纳推荐项不算用户拍板，须留在待答清单）。
- **不移出**：同分片的「生成 / 加权规则与叠加顺序」「批次规模区间两端由什么驱动」「五类配比」——本条与它们正交，且下方越界发现给它们**增加**了一条输入。

## 越界发现

1. **必须带进 `solution-draft-future-event-generation-weighting.md` 的连带输入（本稿自认的弱依赖，Finale 采纳抬升后已生效）：**
   > **满级后 Finale 条目恒进候选池，不参与类型加权。**

   它对 `future-event-service.md` 生成 / 加权段的**具体影响**（本 worker 不落笔，交 orchestrator 转给该分片）：
   - **必须写成「闸门式旁路」，而不是「给 Combat 一个很高的权重」。** 加权只能提高概率，抬升需要的是**必现**；抽漏一次 ⇒ 本批 `EffectivePriority` 仍为 0（无 Finale 可抬），满级角色白烧一格寿元且篇章边界被交给随机——这正是裁决项 1 采纳 A 时明写要避免的形态。形状与既有闸门分支同构：**在类型加权抽取之前判定，命中则该条目直接占一个槽位**。
   - **它给「类型修正能否修正到 0」这条待答项加了一条硬约束。** 分片现记「Travel 一行修正到 0 已确认安全，其余四类未定」——若 Finale 走旁路，则 **Combat 行修正到 0 在满级时不得把 Finale 一并挡掉**；不走旁路，则 Combat 行在满级时**不可修正到 0**。两条路必须择一明写。
   - **它同时是一条 PlotManager 越权面的封堵。** `PlotModulation` 能给白名单 / 权重（`plot-manager.md`）；若 Finale 只是「高权重的 Combat 条目」，剧本把 Combat 排除出白名单即可**间接封死篇章推进**——那正是「PlotManager 只调内容不调约束」明写要拒绝的事，只是换了个入口。旁路形态天然免疫（不经加权、不经白名单）。
   - **它占掉批次规模的一个槽位。** 满级那一批实际有效可选集 = 1（抬升后其余被封锁），与「批次规模区间两端由什么驱动」那条待答项相接：满级批的规模事实上被钉死为 1，可作为该条的一个已知端点。
2. **`common-properties.md:78` 的「剧情线的强制事件」这半句是一处既有内部漂移**（与同文件 `:76` 及 `future-event-service.md:87` 打架），🔴-1 只在**本次触及的小节内**顺手收口；若其它草稿也改这一小节，须避免两处对同一句给出不同改写。
3. **`combat/_index.md:42` 与 `:45` 的时点表述不一致**（「失败后可继续消耗寿元找事件」 vs 「篇章照常完成、境界照常突破」）。本条按 🔴-4 的推荐 (b) 可以**绕开**这处裁决；但它是一处独立存在的含糊，建议记为该分片之外的一条新待答（`open-questions/` 战斗分片），不在本次强行收口。
