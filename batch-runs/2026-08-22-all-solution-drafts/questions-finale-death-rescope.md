# 补充核查 — Finale 失败必死（用户 08-22 interview 新裁决）

> 只读核查。未写入任何设计库文件。

## 裁决逐字

> 「移除 finale 结算认定失败后存活的场景。finale 失败必死，章节立即结束，清除之前失败后存活的相关内容。」

解读：Finale（篇章终局战 / 天劫）失败 ⇒ 角色 `defeated`、本次轮回该角色终结、篇章不推进。
库中所有依赖「Finale 失败但 `lifeTotal` 未归零 ⇒ 篇章照常完成 / 继续消耗寿元找事件」的表述全部清除。

---

## 受影响处逐条

### A. 必须改写（承重表述被直接推翻）

| # | 路径:行 | 原话要点 | 判定 | 建议改法 |
|---|---|---|---|---|
| A1 | `systems/adventure-event/combat/_index.md:42` | 「**Finale 失败不直接 `defeated`（承重）**。不设 `DefeatReason.FinaleFailed`……死亡通道已经存在……失败后 `lifeTotal` 未归零即可继续消耗寿元找事件」 | 🔴 整条推翻 | 改写为「Finale 失败即 `defeated`（承重）」；点明**新增一条独立死亡通道**，不再借道 `LifeTotalExhausted`。`DefeatReason` 的处置见 B1。 |
| A2 | `systems/adventure-event/combat/_index.md:45–47` | 「**Finale 失败但存活（约 1%）⇒ 篇章照常完成、境界照常突破（承重）**」+ 承重推论「渡劫的胜负不是篇章推进的闸门」+ 叙事补白两版文案 | 🔴 整块删除 | 三个子条全删。反向补写：「**渡劫的胜负就是篇章推进的闸门**——胜则突破，败则轮回终结」。 |
| A3 | `systems/adventure-event/combat/_index.md:154` | 决策清单「……**失败但存活亦完成篇章**；Finale 是道统残卷的唯一累积源与兑现点」 | 🔴 改写 | 删「失败但存活亦完成篇章」，换为「**Finale 失败即角色终结**」。 |
| A4 | `systems/game-progression.md:13–15` | 「**篇章收口 = 一次性的 Finale，胜负不是推进闸门（承重）**」+「未被打穿的那约 1% 情形里角色存活并照常完成该篇章、照常突破境界」+「篇章推进本身不再由 Finale 的胜负把关」 | 🔴 整块反转 | 改为「篇章收口 = 一次性的 Finale，**胜负即推进闸门**」。删 1% 分支。保留「败后不可在同一篇章内再战 ⇒ 只能篇章重试」，但语义从「可选重走」变为「唯一出路」。 |
| A5 | `decisions/ADR-0004-realm-checkpoint-retry-model.md:16` | 「**输掉一场战斗本身不终结角色**（只按道念差扣 `lifeTotal`），故原先的『战斗失败』不再是独立的终结原因」；`defeated` 原因**收敛为三种** | 🔴 **实质推翻既有 ADR** | 改写 Decision 该条：`Standard` / `Practice` 失败仍不终结角色；**`Finale` 失败是一条独立终结原因**。原因由三种变四种（若采纳 B1 选项①）。Consequences 需补一条：ch3 重试上限 1 ⇒ Finale 失败的账号级容错只剩 1 次。 |
| A6 | `decisions/ADR-0002-adventure-event-taxonomy.md:42` | 「Practice / Finale 的既有设计**整体保留**……『一篇章一个 Finale、败后不可重战』、『**失败但存活仍完成篇章**』、残卷规则」 | 🔴 改写 | 从「整体保留」清单里剔除「失败但存活仍完成篇章」这一项。其余（天劫 Enemy · ±2 带 · WinMargin 初值 · 残卷）照旧。 |
| A7 | `systems/services/plot-manager.md:159–171` | 整节「Finale『失败但存活』的叙事补白落在本 manager 的叙事层」+ 两版文案「劫败而身存，破境亦有缺。」/「以败换境，以伤换生。」+ 择取规则 + 「不必带种子」推论 + 「绝不能暗示残卷」边界 | 🔴 整节删除 | 全删。若用户要为「Finale 失败致死」补新叙事 → 见新问题 Q6。 |
| A8 | `systems/services/life-cycle-service.md:150` | 「**失败**（含「失败但存活」的 1% 分支）：`PlayerPowerFragment.Accumulated` ……累加；不掷骰、不发放」 | 🟠 改写括注 | 去掉括注，改为「**失败**（此时角色同刻终结，见终态判定）：`Accumulated` 累加；不掷骰、不发放」。**并补一条写入顺序纪律**（见 Q4）。 |
| A9 | `systems/player-profile/player-power/_index.md:18` | 「**『失败但存活』的 1% 分支照常累积、但不掷骰不发放**——发放只认胜利」 | 🟠 删句 | 删该句。前半「累积 = Finale 战斗失败（**不论是否因此 `defeated`**）」中的括注也要删——现在恒 `defeated`。 |
| A10 | `systems/player-profile/_index.md:100` | `FinaleWinOrdinal` 说明「（失败与**「失败但存活」**都不自增）」 | 🟠 删括注内的分支 | 改为「（失败不自增）」。 |
| A11 | `systems/player-profile/_index.md:101` | `Ch*FirstWinDone`「首胜 100% 的判定源；**失败但存活不置位**」 | 🟠 删括注 | 改为「首胜 100% 的判定源；仅胜利置位」。 |
| A12 | `terminology.md:137`（`FinaleWinOrdinal` 条） | 「只在 Finale 胜利时 +1（失败、以及 **1% 的「失败但存活」**都不自增）」 | 🟠 删分支 | 同 A10。 |
| A13 | `ux/screen-flow.md:102` | 「渡劫成功次数**不计入 1% 的「失败但存活」**，因此它可能小于已完成的篇章数——**该差值是有味道的信息，不是 bug**」 | 🔴 改写（结论反转） | 失败必死后「完成篇章 ⟺ Finale 胜利」，该差值**恒为 0**，这句连同其「有味道的信息」论据整段作废。但**「渡劫成功次数 ≠ 总通关数」这条主结论仍成立**（一次通关贡献 3 次胜利；胜利可不伴随通关），只是理由只剩后一条。改写时保留主结论、删 1% 论据。 |
| A14 | `systems/services/content-service.md:37` | overlay「只改不增」清单举例：「状态转换触发的定性文案（隐藏属性跨档叙事、**Finale「失败但存活」补白**）」 | 🟠 换例 | 删掉 Finale 补白这个举例，保留「隐藏属性跨档叙事」。**规则本身不变，只是丢了一个例子。** |
| A15 | `ux/_index.md:18` | 内容 / UI 归属四问的举例：「……隐藏属性跨档叙事、**Finale 补白**」 | 🟠 换例 | 同上，删该举例。 |
| A16 | `system-overview.md:127` | 「卡面描述、事件正文、跨档叙事、**Finale 补白**走 `content/` 的条目内嵌 `LocalizedText`」 | 🟠 换例 | 同上。 |
| A17 | `decisions/ADR-0016-hidden-stat-band-model.md:29` | 「同类先例（**Finale「失败但存活」补白**）本就挂在状态转换上」——用它当**论据先例** | 🟠 改写论据 | 这是**唯一一处把补白当论据用**的地方：先例被删后论据悬空。改法：把「挂状态转换而非挂事件」的论据自足化（组合爆炸 + 泄露映射两条本已足够），去掉先例引用。**不要留一句指向已删内容的话。** |
| A18 | `open-questions.md:25` | 分片⑥导航行：「……**1% 存活分支的叙事补白落点**」 | 🟠 改写导航行 | 该焦点已随裁决消失；导航行需去掉这半句（分片⑥仍存在，另有两条在办项）。 |

### B. 需要对称补写（新的失败支需要形状）

| # | 落点 | 现状 | 需要补什么 |
|---|---|---|---|
| B1 | `systems/architecture.md:468` · `systems/services/life-cycle-service.md:139–145` · `systems/character-profile/_index.md:21,67,234` · `decisions/ADR-0004:16` | `DefeatReason { Discarded, LifeSpanExhausted, LifeTotalExhausted }`，且**枚举旁明写注释**「战斗失败本身不终结角色，只扣 lifeTotal」 | **枚举本身与那条行内注释都要动**（见 Q1）。注意 `defeatReason` 是存档字段（`DefeatReason?`），新增成员按既定纪律**只增不删、code 不复用**。 |
| B2 | `systems/services/life-cycle-service.md:139–145`（终态判定伪码） | 判定**完全查表驱动**：`foreach (key, spec) in ResourceElements where spec.DepletionDefeat != null: if 读取 == spec.Min → DefeatCharacter(...)` | Finale 失败**不由任何资源触底触发** ⇒ 表驱动路径表达不了它，必须补一条**显式旁路**（在 `eventEnd` 合并之后、终态判定②之前，或作为判定②的第一分支）。这是本次改动**唯一一处真正的结构新增**，必须明写，否则实现侧会以为「照表走就行」。 |
| B3 | `program-overview.md:199–201`（阶段 4 流程图） | 「CycleStateManager 判定：寿元 ≤ 0 或 lifeTotal ≤ 0 → DefeatCharacter() → 阶段 5 ／ **Finale 通关 → CompleteChapter() → 阶段 5**」 | 补一条并列分支：「**Finale 失败 → DefeatCharacter(FinaleFailed) → 阶段 5**」。现图里 Finale 只有「通关」一条出口，失败支隐含走 lifeTotal ≤ 0——该隐含现在不成立。 |
| B4 | `systems/adventure-event/combat/_index.md:36`（成功支） | 「通过后角色进入新境界，**等级归位为新境界的初期**」 | 与新的失败支对称改写：「**通过后**……；**未通过则角色终结、本篇章不推进**」。两支写在一起，读者一眼看全篇章边界的两个出口。 |
| B5 | `systems/adventure-event/combat/_index.md:41` · `systems/balance.md:174`（Finale 三重压迫叠加） | 「（c）失败时道念差最大 ⇒ **扣 `lifeTotal` 最狠**」 | (c) 的量纲从「扣得最狠」跃升为「**直接死**」——三重压迫的顶点质变。需重写该条，并连带重估 `WinMargin` 初值口径（见 Q5）。 |
| B6 | `systems/adventure-event/combat/_index.md:170`（待决问题「失败后果的其余部分」） | 「**`Finale` 档失败 = 不另开终结通道**，见上」 | 该括注已作废，须改为「`Finale` 档失败 = 独立终结通道」。 |

### C. 不受影响（已核实，备案）

- **后端设计库零改动。** `backend-design-documents/` 全部 Finale 相关内容（`contracts/profile-sync.md:154,270–302` · `ADR-0005-anti-cheat-recompute-boundary.md` · `handoffs/2026-08-12`、`2026-08-14`）**只覆盖胜利路径**（`lastRoll` / `lastEffectiveChance` / `finaleWinOrdinal` / `sourceCode == "FinaleWin"`）。全库 grep `defeatReason` **零命中**——后端从未登记该字段。三条校验（逐位比对 · 单向蕴含 · 结构不变式）的成立前提全在胜利侧，不受失败语义变化影响。**⚠ 唯一需盯的一点**：若日后 `characterProfile` 的 `defeatReason` 进入上行透明段，枚举名须与客户端逐字一致（`envelope.md` §2）——目前不在契约面内，**本次不构成跨库承接项**。
- **残卷的防刷结构不受影响，反而更硬。** 「每篇章至多累积一次**或**掷骰一次且二者互斥」原本靠「一篇章一个 Finale + 败后不可重战」保证；失败必死后，失败侧连「活着走完本篇章」都不可能，界更紧。`player-power/_index.md:19` 的结构性简化③照旧成立。
- **`WinMargin` 的单字段形态、`CombatOutcome` 三值、`VictoryRule` 无策略枚举** —— 结构不变（但取值口径变，见 Q2 / Q5）。
- **`chapterRetry` 的字段形态**（三个具名 `Ch*RetryUsed`、`Used` 后缀、非字典）—— 完全不受影响，只是被触发的频次上升。
- **Travel / `eventCountLimit` / location 继承 / 三章共用同一张图** —— 与 Finale 胜负无耦合（`game-progression.md:151–154` 已明写解耦），不受影响。
- **`Practice` / `Standard` 两档的失败语义** —— 原样保留（失败只扣 `lifeTotal`、经 `LifeTotalExhausted` 通道）。**新裁决只收窄到 Finale 一档**，不要顺手扩到三档。
- **`inbox/solution-draft-priority-elevation-conditions.md`（Finale 抬升 `Priority = 1`）的裁决本身** —— 抬升结论不受影响；但其**退让位论证**要重写（见 Q5）。
- **`answer-logs/log-0810b.md` · `log-0810b_2.md`**（补白落点与择取规则的答案档案）—— 归档层，按库内约定**不追改历史 answer-log**；本次不动。同理 `handoffs/2026-08-10b-*:71–77`、`open-questions/update-log-archive.md`。

---

## 与既有承重设计的抵触核实（逐条结论）

**① `DefeatReason` 能否表达「Finale 失败致死」？——不能，必须新增（或借道，见 Q1）。**
现枚举三值 `{ Discarded, LifeSpanExhausted, LifeTotalExhausted }`，且 `architecture.md:468` 的**行内注释就是那条被推翻的纪律**。更关键的是 **`life-cycle-service.md:139–145` 的终态判定是纯查表驱动**（`ResourceElements` 的 `DepletionDefeat` 列）——该设计的自诩优点正是「新增一个终态资源 = 表里加一行 + 枚举加一个成员」。**但 Finale 失败不是资源触底**，它没有对应的 `CostKey`，塞不进 `ResourceElements` 表。⇒ **必须在查表之外补一条显式旁路**（B2）。这是本次唯一的结构性新增，不能被「加个枚举成员就完了」掩盖。

**② 篇章重试（`chapterRetry` / ADR-0004）语义受影响 —— 但库里现有规则**能**回答「下一步是什么」。**
ADR-0004:15 明写「篇章途中死亡 → 从该篇章起始存档重试」。Finale 在篇章末尾，故 Finale 失败 ⇒ 消耗一次 `Ch{n}RetryUsed`、从**本篇章起始**重走（30–55 分钟）。**规则闭合，不是新的待答问题。**
**但它带出一个需要用户明确接受的后果**：此前「1% 存活」是唯一一处避开重走全章的口子，现已关闭。ch3 重试上限 **1**（持礼包 3）⇒ **金丹→元婴的 Finale，免费档账号一生只有 1 次容错**，第二次失败即该篇章重新锁定。ADR-0004 的 Consequences 需明写这条（A5）。→ 是否接受见 Q3。

**③ `lifeTotal` 归零与「Finale 失败」成为两条独立死亡路径 —— 是，且结算 / UX 需要区分。**
- **存档面**：两者写同一格 `CharacterProfile.defeatReason`，只是取值不同 ⇒ **存档 schema 零变化**（除非按 Q1 选项②借道，那样连取值都不变）。
- **结算面**：需要裁决「Finale 失败时那笔按道念差 1:1 扣的 `lifeTotal` 还扣不扣」（Q4）。
- **UX 面**：两条路径的死亡屏文案应当不同（「寿元耗尽 / 耐久归零」vs「渡劫身死」），但 `ux/` **目前根本没有死亡 / 结算屏的设计**（全库 grep 只在 `combat-ux.md:86` 提到一句「lifeTotal 归 0 即角色终结」）。⇒ **这是一个既有空白，不是本次裁决造成的**，但本次裁决让它更急。

**④ `WinMargin` 的含义在「失败必死」下确实改变 —— 而且改变的方向是变重，不是变轻。**
原本 `WinMargin` 是「奖励与推进的门槛」，退让位是下调它。现在它**同时是处决线的位置**：`d` 差一点没够到 `N`，角色就死。`balance.md:174` / `combat/_index.md:41` 那条「三重压迫叠加」的第 (c) 项（失败扣 `lifeTotal` 最狠）升格为「直接死」。
**推论：`WinMargin` 作为「双向第一旋钮」的地位更承重**，`solution-draft-priority-elevation-conditions.md:188` 把「下调 `WinMargin`」列为 Finale 抬升的退让位这条**仍然成立且更必要**，但它的**理由要重写**（原理由是「已有三重压迫」，现在是「压迫的顶点已是死亡」）。初值 3 / 5 / 8 是否要下调 → Q5。

**⑤ 需要改写的 ADR —— 三份，其中一份是实质推翻。**
- **`ADR-0004`（Accepted）：实质推翻。** Decision 第 4 条「输掉一场战斗本身不终结角色……原先的『战斗失败』不再是独立的终结原因」被直接推翻。按根约定（一切皆可改、直接改这份 ADR、不新开 ADR 取代），**直接重写该条 + 补 Consequences**。
- **`ADR-0002`（Accepted）：局部改写。** :42 的「整体保留」清单剔除一项。
- **`ADR-0016`（Accepted）：论据换例。** :29 引用了即将被删的补白作为先例，须自足化论据。
- `ADR-0005`（后端 · 防作弊复算边界）**不受影响**（纯胜利侧）。

---

## 新引出的待裁问题（供 orchestrator 补一轮 interview）

> 按阻断程度排序：Q1 / Q2 会改变契约与机制形状，必须先问。

### Q1 —— `DefeatReason` 怎么表达 Finale 失败？【🔴 阻断 · 改契约形状】

- **① 新增 `DefeatReason.FinaleFailed`**（枚举四值）+ 在 `eventEnd` 后补一条显式旁路调用 `DefeatCharacter(FinaleFailed)`。
  - 后果：存档枚举 +1 成员（按纪律只增不删、code 不复用）；`architecture.md:468` 的行内注释改写；终态判定从「纯查表」变成「查表 + 一条旁路」——**该设计自诩的「纯表驱动」被开了第一个口子，必须明写这个口子**；死亡屏可据此给专属文案；后端零影响（未登记该字段）。
- **② 借道 `LifeTotalExhausted`**：Finale 失败时把 `lifeTotal` 直接置 0，让既有查表路径自然判负。
  - 后果：零新增成员、零结构变化。**但代价大**：与「失败按道念差 1:1 扣」的既定语义冲突（要么额外置 0，要么伪造一个足够大的扣减）；`Status.lifeTotal` 只有 `Add` 通道、**无置值通道**（`profile-service.md:204` 明写「同样无置值通道」）⇒ 得为它开一个 `Set`，那是更大的口子；且玩家 / 客服 / 数据侧永远分不清「打穿死」和「渡劫死」。
- **③ 不新增成员，改由 `status` 侧表达**（如新增 `CycleStatus` 值）。
  - 后果：`status` 是三值终态收敛状态机（`ongoing | defeated | completed`），动它的代价远大于动 `DefeatReason`。
- **推荐：①。** 依据：`life-cycle-service.md:145` 自己写的扩展路径就是「表里加一行 + `DefeatReason` 加一个成员」，成员那半照做；表那半做不到（Finale 失败不是资源触底），故补旁路是最小改动。②被 `LifeTotal` 无置值通道这条既有硬约束挡死。

### Q2 —— Finale 档的 `Draw`（`0 ≤ d < WinMargin`）算不算「失败」？【🔴 阻断 · 这是本次最容易被漏掉的一条】

**背景（既有的一处含糊，被新裁决顶成承重）：** `combat/_index.md:80` 写「`d >= WinMargin` → `Victory`；**否则 → `Draw`**」——字面上**根本没有 `Defeat` 分支**；`combat-service.md:255` 写「差额未达 `WinMargin` → Draw」；`scoring.md:33` 又写「平局 = 道念**相等**」。三处口径不一致。在 Finale 档（`WinMargin` = 3 / 5 / 8）这个区间**很宽**：领先 1~7 点都落在里面。原设计下这不要紧（`Draw` 只是不加厚、不扣血）；**失败必死后，它决定生死。**

- **① Finale 档二值化：非 `Victory` 即 `Defeat`（`Draw` 在 Finale 永不可达）。**
  - 后果：语义最干净——「没渡过劫就是没渡过」。与 `Practice` 档 `Draw` 永不可达形成**对称的两端退化**（一端恒不可达因为门槛为 0，一端恒不可达因为不够即死）。需在 `combat/_index.md:80` 与 `combat-service.md:255` 把 `Defeat` 分支补写明确。
  - 代价：领先 7 点却死，玩家观感刺人 —— 但这正是 `WinMargin` 作为「必须领先 N 点」的字面含义。
- **② 保留 `Draw` 为「不死但不突破」的中间态。**
  - 后果：**等于重建了「失败后存活」**，与本次裁决直接冲突（角色活着、篇章没过、又不能重战本篇章的 Finale ⇒ 只能耗寿元耗到死或主动弃置，比死更难受）。**不推荐。**
- **③ `d < 0 → Defeat`（死）；`0 ≤ d < N → Draw`（不死，视同失败但仍终结章节）。**
  - 后果：把「章节结束」和「角色死亡」拆成两件事，与裁决「失败必死」的字面相悖。
- **推荐：①。** 理由：裁决原文「finale 失败必死」中的「失败」最自然的读法就是「没达成胜利条件」；且②会把被删掉的分支从后门放回来。

### Q3 —— ch3 重试上限 1 是否要随之放宽？【🟠 影响元进程压力线】

失败必死后，ch3（金丹→元婴）Finale 一败 ⇒ 消耗唯一那 1 次重试；第二败即该篇章重新锁定、需要另一个存档角色。此前「1% 存活」是这条压力线上唯一的软垫。

- **① 维持 ∞ / 3 / 1（付费 ∞ / 9 / 3）不动。** 后果：终局压力显著上升，且**平衡基准是免费档**（ADR-0004:21 明写），意味着「免费档应当可通关」这条要靠 `WinMargin` 与内容侧承担全部让步。付费档相对价值被动抬高——需正视这是**不经意的商业化倾斜**。
- **② 上调 ch3 上限（例：1 → 2）。** 后果：抵消掉失败必死带来的部分终局压迫；但 ADR-0004 与 `monetization.md` 的礼包价值主张（∞/9/3 的相对优势）需重算。
- **③ 不动上限，改由下调 `WinMargin` 初值补偿**（与 Q5 合并处理）。
- **推荐：③ → 若实测仍过苛再考虑 ②。** 理由：`WinMargin` 已被库内两处明写为「双向第一旋钮，两个方向都优先于动回合数」，动它是既定的第一顺位；重试上限则牵动 ADR-0004 + 礼包定价两条线。**但这条必须让用户明确表态**——它是「玩家一生只有 1 次容错」的接受与否，不是纯数值题。

### Q4 —— Finale 失败时那笔按道念差 1:1 扣的 `lifeTotal` 还扣不扣？【🟠 影响结算链路与写入顺序】

角色反正要终结，残值不再被任何规则读取。

- **① 照常扣**（合进 `eventEnd` 那一次 `TryApply`），只是不再是死亡判据。
  - 后果：链路形状零变化（`life-cycle-service.md:146` 的「一次事务一个存档点」原样成立）；结算屏可如实呈现「你损失了 N 点耐久，且渡劫失败」；`CombatResult.RemainingLifeTotal` 仍有定义。
- **② 跳过扣减**（Finale 失败直接终结）。
  - 后果：省一次计算，但要在合并逻辑里加一个 tier 分支——**为省一次无害的加法引入一条条件分支**，与库内「结构保持简单」的一贯取向相悖。
- **推荐：①。**
- **⚠ 同时必须裁定一条写入顺序纪律（无论选哪个）：** `life-cycle-service.md:150` 的残卷 `Accumulated` 累加是**账号级写入**（`PlayerProfile`），而 `DefeatCharacter` 会走**角色终态数据清理**（ADR-0004:16「终态数据清理」）。**必须保证账号级的残卷累加在角色终结之前提交**，否则「Finale 失败累积残卷」这条承重机制在**每一次**失败上都会丢——而失败现在恒等于死亡，即**这条机制会 100% 失效**。这是本次裁决**最危险的一处隐性后果**，必须在 `life-cycle-service.md` 明写顺序。

### Q5 —— `WinMargin` 初值 3 / 5 / 8 是否要下调？【🟠 数值口径】

- **① 不动数值，只在 `balance.md` 明写「口径已变（未达门槛 = 死），初值需在 ch1 数值标杆专场重估」。** 后果：把数值决策留在它该在的地方（数值标杆专场），本次只改口径描述。
- **② 本次即下调**（例 2 / 4 / 6）。 后果：在没有实测数据时凭直觉动数值，与库内「数值归 ch1 标杆专场」的既定分工相悖。
- **③ 维持数值但补一条内容侧让步**（如 Finale 前必有一个 `Recuperate` 事件）—— 但注意：`priority-elevation` 草稿已把这条列为**退让位**而非默认编排。
- **推荐：①。** 同时把 `combat/_index.md:41` / `balance.md:174` 的「三重压迫叠加」第 (c) 条重写为「失败即终结」，并在 `priority-elevation` 草稿的退让位论证里换掉旧理由。

### Q6 —— 是否为「Finale 失败致死」补一条新的定性叙事？【🔵 呈现层】

删掉的两版补白（「劫败而身存」/「以败换境」）留下一个叙事空位；且 `ux/` 目前**没有任何死亡屏 / 轮回结束屏的设计**。

- **① 不补，走通用死亡屏。** 后果：最省；但「渡劫身死」是本作叙事上最重的一刻，与「寿元耗尽」共用一句文案有点浪费。
- **② 补一条挂在 `ResolveOutcome` 上的定性文案**（复用刚被腾空的那条链路：`ResolveOutcome` → `eventEnd`，内容层、`LocalizedText`、启动期校验、overlay 只改不增）。 后果：结构成本≈0（链路现成，A7 删掉的正是它），只是把两版「侥幸活下来」换成一版「身死道消」。
- **③ 归入尚未设计的死亡 / 结算屏专场，本次只记一条待答。**
- **推荐：② 或 ③**，取决于用户是否想在本批次内收口。**注意**：若选①，A14 / A15 / A16 / ADR-0016 那四处「内容层举例」会彻底失去这个例子，须一并换例（已在 A 段列出）。

### Q7 —— `ux/screen-flow.md:102` 那条呈现纪律怎么改？【🔵 文档层，答案基本确定】

「渡劫成功次数 ≠ 总通关数」的主结论仍成立（一次通关贡献 3 次胜利），但其**第二条论据**（1% 存活导致胜利数 < 完成篇章数）作废，且现在**胜利数恒等于完成篇章数**。

- **① 保留主结论、删 1% 论据、补一句「完成篇章数 ⟺ Finale 胜利数」。** **推荐。**
- ② 整条重写。 后果：过度改动，主结论本身没问题。

---

## 写入面清单与波次建议

### 本改动的写入目标文件集合（铁律③分区用）

**客户端库（`game-design-documents/`）——共 15 份主题 / 决策文档：**

```
systems/adventure-event/combat/_index.md          ← A1 A2 A3 B4 B5 B6   【与 priority-elevation 分片同面】
systems/game-progression.md                       ← A4
systems/services/plot-manager.md                  ← A7（整节删除）
systems/services/life-cycle-service.md            ← A8 B2 + Q4 写入顺序纪律
systems/services/combat-service.md                ← Q2（Defeat 分支补写，:253–258）
systems/architecture.md                           ← B1（DefeatReason 枚举 + 行内注释）
systems/character-profile/_index.md               ← B1（:21 :67 :234 的枚举描述）
systems/player-profile/_index.md                  ← A10 A11
systems/player-profile/player-power/_index.md     ← A9
systems/balance.md                                ← B5 + Q5 口径句
terminology.md                                    ← A12
program-overview.md                               ← B3
system-overview.md                                ← A16
ux/screen-flow.md                                 ← A13 / Q7
ux/_index.md                                      ← A15
systems/services/content-service.md               ← A14
decisions/ADR-0004-realm-checkpoint-retry-model.md ← A5（实质推翻）
decisions/ADR-0002-adventure-event-taxonomy.md     ← A6
decisions/ADR-0016-hidden-stat-band-model.md       ← A17
```

**共享台账（orchestrator 单写者，worker 不碰）：**
`open-questions.md`（A18 导航行）· `open-questions/06-meta-progression.md`（补白焦点移出）· `open-questions/01-combat.md`（若 Q2 / Q6 留作待答则新增条目）· `open-questions/update-log.md` · `answer-logs/`（本次裁决的答案档案）· `decisions/_index.md`（三份 ADR 的状态行）

**后端库：零写入。**（核实见 C 段）

### 波次建议

- **⚠ 不能与 `solution-draft-priority-elevation-conditions` 分片并行。** 两者都写 `systems/adventure-event/combat/_index.md`，且**都触及 `WinMargin` 的论证**（该草稿把「下调 `WinMargin`」列为退让位，本改动改变了退让位的理由）。按铁律③ ⇒ **合并给同一个 worker，或串行**。
- **本改动的写入面远大于任何一个 solution-draft 分片**（19 份主题 / 决策文档 + 3 份 ADR），且**改的是承重结论而非新增内容**，与 `game-progression` / `life-cycle-service` / `player-power` / `balance` / `terminology` / 两份 overview / 两份 ux 全都相交——这些文件很可能也被别的分片触及。
- **建议：单独成一个波次，串行执行，排在所有 solution-draft 分片之前。**
  理由：① 它推翻的是**别的分片正在引用的承重前提**（残卷、篇章推进闸门、`WinMargin` 压迫叠加、内容层举例），先落笔可避免后续分片基于旧前提写出立刻过时的内容；② 写入面与几乎所有分片相交，做不到干净分区；③ 三份 ADR 的改写属于全库根级影响，不适合与常规提炼混在同一波。
- **若必须并行**：唯一安全的做法是把 `combat/_index.md` + `balance.md` + `game-progression.md` 三份的**全部写入**（含 priority-elevation 分片的那一份）交给同一个 worker。

### 一条给 Phase B worker 的提醒

按「活文档只保留最新设计（重写替换，不留考古）」的根约定：删除「失败但存活」时**不要留任何「原 X / 已取代 / 曾经如此」的痕迹**，直接重写为新语义。`answer-logs/` 与 `handoffs/` 的历史记录**不追改**（它们是归档层，历史归 git）。
