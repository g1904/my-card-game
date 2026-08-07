# location 三字段建模 · eventCountLimit → Travel 闸门 · 跳过与补位的产出侧闭合

- id: 2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure
- date: 2026-08-05
- topic: systems/game-progression.md, systems/services/future-event-service.md, systems/adventure-event/common-properties.md, systems/adventure-event/travel/, systems/balance.md, terminology.md
- status: distilled
- distilled-to: terminology.md, systems/game-progression.md, systems/services/future-event-service.md, systems/adventure-event/common-properties.md, systems/adventure-event/travel/（_index.md, common-properties.md）, systems/balance.md, systems/player-profile/codex/_index.md, open-questions.md, open-questions/（02-event-options.md, 06-meta-progression.md, deferred-content.md, update-log.md）, answer-logs/（log-0805b.md, log-0805b_2.md）

**一行摘要：** **location 由「抽象概念」升格为带三个字段的内容条目**（事件类型概率修正 · 敌人模板集合 · `eventCountLimit`）；**配额用尽时本批收窄为仅剩 Travel**，使 Travel 由可选路由变成结构性闸门；**跳过的两条残留细节改由产出侧保证一次性闭合**（不生成付不起 `skipCost` 的事件、不生成整批全跳的批次），**补位落空的判据由此挂在 `eventCountLimit` 上**、死局兜底随之闭合。

## Intent（distilled）

### 一、location 携带三组字段 = 它是内容条目，不再只是一个标签

> **一个 location 承载：① 一组特定的事件类型出现概率修正（event type possibility modifiers）；② 一组特定的敌人模板（`EnemyTemplate`）；③ 一个 `eventCountLimit`（该地域的事件容量上限）。**

| 字段 | 框定强度 | 作用面 |
|------|----------|--------|
| 事件类型概率修正 | **软**（改权重，不改可及性） | 物化时的类型配比：荒野多 Combat、坊市多 Exchange、洞天多 Research |
| 敌人模板集合 | **硬**（限定取池） | 战斗类事件物化时「派谁来」 |
| `eventCountLimit` | **硬**（计数闸门） | 玩家在该地域最多经历几个事件 |

- **「location 框定事件池」这句旧措辞由此收窄。** 事件侧**不是硬分池**——不是「这个地点只开放这一批事件」，而是**对候选池的类型出现概率施加修正**。硬分池只发生在**敌人**那一侧（模板集合是限定的）。一软一硬是两种不同的框定形态，此前被同一句话笼统覆盖。
- **推论 ①：location 已具备内容条目的形态。** 它携带字段集合、要被内容作者编写、要被物化读取——按既有的数据即资源纪律，它应有稳定 `Id`、经 `ContentRegistry` 索引、受 `ContentEnabled` 与 overlay 热更管辖。**数据载体的定名与形态仍待答**（`LocationData : Resource`？枚举 + 资源两件套？），见 Open questions。
- **推论 ②（承重）：敌人物化的两条轴至此正交且齐全。** **location 决定「派谁来」**（模板池），**角色等级 ±2 决定「有多强」**（赋级带，08-05 已定）。这答结了「物化时充实 / 改写规则」中**取池**的那一半——先前只知道「取出一份模板」，不知道从哪个池取。**剩下的一半（带内五档的分布权重、卡组怎么改）仍未定。**
- **推论 ③：地域获得了生态与风味的载体。** 同一个 `EnemyTemplate` 只在持有它的地域出现，同一类事件在不同地域的出现频率不同——**地域之间的差异不再需要另设机制，两个字段就是它的全部表达**。
- **具体数值归内容制作阶段。** 各 location 的类型修正取值、模板清单、`eventCountLimit` 的具体数字，**在内容制作阶段定**，不在本次机制层给。

### 二、`eventCountLimit` 达成 → 本批只剩 Travel

> **玩家在当前 location 选够了事件、达到 `eventCountLimit` 后，最后剩下的 eventOption 应当是「前往另一个 location」。**

- **承载机制无需新增——既有的两条约束轴恰好表达它。** Travel 选项以**最高 `eventPriority`**（封锁同批其余选项）+ **`ifMandatory = true`**（封死跳过通道）出场即可。**这是「一批 eventOptions 可以全部为 mandatory」这条既定语义的第一个真实用例**，先前它只是一条抽象的可能性。
- **推论 ①（承重）：Travel 由「可选路由」升格为结构性闸门。** 先前 Travel 是玩家想换图时才选的一个事件类型；现在**地域迁移是被规则驱动的必经节点**——每个 location 都有一个确定的出口时刻。**进程的形状由此变得清晰**：一次篇章 = 若干 location 的串联，每个 location 内是一段定长的 eventOptions 循环，location 之间由 Travel 缝合。
- **推论 ②：`eventCountLimit` 成为篇章节奏的结构单位。** 篇章的事件总数 ≈ 途经各 location 的容量之和，因此它与既有的时长主旋钮 `lifeSpanCost` **互相约束**——两者必须一同反推目标时长（30–40 / 35–45 / 45–55 分钟），不能各调各的。归 `systems/balance.md`。
- **计数口径（推论，待确认）：** 原话是「**selected** enough events」，故计数应只计**选择进入并结算**的事件；**跳过不计入**。这与「跳过通常不流逝时间（不扣 `lifeSpanCost`）」同向——跳过既不耗时间也不耗地域配额。**Travel 事件本身是否计入该 location 的配额**未言明。

### 三、跳过语义的两条残留细节 = 两条产出侧保证

> **① 不会生成付不起 `skipCost` 的事件。② 不会生成整批全跳的 eventOptions。**

- **两条都是「产出侧保证」而非「消费侧处理」。** 它们不给玩家新的规则去理解，而是约束 future-event-service 物化时能产出什么——**问题在源头被消解，下游不需要任何分支**。这与既有的「成本取负只在物化处发生一次」是同一种取向。
- **① 直接答结「付不起 `skipCost` 时如何表现」：不会发生。** 物化组装 `SkipCost` 时对照当时的角色资源（`ProfileService.CanAfford`）；付不起就不给这个事件带 `skipCost`（或不选它进这一批）。**判定时点 = 每一次物化，含 `TryRefill` 补位那一次**——补位实例按补位当时的资源判定，而不是沿用本批开批时的判定。
- **② 直接答结「能否整批全跳」：不能。** 每一批 eventOptions **至少有一个 `IsMandatory == true` 的选项**。
  - **推论：`EventOptionBatch` 多出一条恒真不变式** —— 既有的 `AnySkippable`（= 任一 `IsMandatory == false`）之外，`Options.Any(o => o.IsMandatory)` 恒为真。这条不变式在**批次产出**与 **`TryRefill` 补位后**都必须保持。
  - **推论：批次不可能被跳空。** 「eventOptions 被跳到只剩 0 个」这一情形在规则层被排除，不再需要兜底。
- **推论（承重 · 反向抬高一条待答）：`selectCost` 的死锁问题变得更紧迫。** 既然每批必有一个不可跳过的选项，若玩家**付不起那个选项的 `selectCost`**，轮回就卡死。`skipCost` 这条已经给出了对称的先例（产出侧保证可负担），**但用户本次只对 `skipCost` 表态**——`selectCost` 是否同样给保证仍待答。

### 四、补位落空的判定规则 = 地域配额，不是事件池耗尽

> **补位落空的判定，参照 `eventCountLimit` 与「travel to another location」这条出口。**

- **判据由此明确：** 补位不是无条件的——**当前 location 的事件容量用尽时，就补不出新事件**。此前猜测的「事件池耗尽」「优先级 / 剧本约束不允许」不是主判据。
- **死局兜底随之闭合。** 配额用尽 → Travel 选项顶上（第二节）；批次不会被跳空（第三节）。**「若剩 0 个玩家如何推进」这个问题在两条规则的合力下不成立**——任何时刻至少有一个可推进的选项，且它不可被跳过。
- **`TryRefill` 的 `bool` + `out` 形态因此更贴切了：** 返回 `false` 不再是「运气不好没抽到」，而是一条**有明确语义的地域状态**——本地域已满，该走了。

### 五、流程意图

- **`pastEvent` 的痕迹 schema 与其余 eventOptions 相关待答，走 `/provide-solution-draft`** 产出提案式草稿，人工评审后再回流。它们**不在本次答结**。
- **事件出现概率（event odds）的具体数值留待内容制作阶段**，与既有的「内容充实整体搁置」一致。

## 追加拍板（08-06）：locationMap · locationCodex · 必做项不是死锁

### 六、`locationMap` = 一张全局不变的地域图（新概念）

> **确实存在 `locationMap` 这个概念。它是一份不变的数据，future-event-service 会经常调用；每个篇章的 `locationMap` 是一样的。**

- **它答结「连通关系由谁承载」：** 地域之间的连边**既不挂在 Travel 事件的内容条目上，也不在运行时算**——由一份**独立的 `locationMap` 数据**承载。Travel 事件的目的地是**从当前 location 在图上的邻接集合中取**的。
- **推论 ①（承重）：三个篇章共用同一张图 ⇒ location 不随篇章 / 境界变化。** 这答结了挂在 `game-progression.md` 的旧待答。**难度的篇章差异不由「换一张更难的图」承载，而由敌人赋级带（相对角色当前等级）承载**——同一张图在三个篇章重走，敌人强度自动跟着角色走。这与「全局等级序是一把简单的直尺、境界鸿沟由 `baseMomentum` 承载」是同一种分工取向：**结构保持简单，难度放进数值**。
- **推论 ②：熟悉度成为跨轮回的资产。** 图不变 ⇒ 同一个玩家在不同轮回走的是**同一片世界**。地名、地域的事件倾向、哪片区域出什么敌人——这些都会被记住并复用。**这是把「重复游玩」转化为「越玩越懂」的结构基础**，也正是 `locationCodex` 的存在理由（见下）。
- **推论 ③（工程形态）：不变 + 高频读 ⇒ 只读静态数据，启动加载一次、常驻内存。** 它进 `ContentRegistry`（受 overlay 热更管辖，但**一次轮回内视为不变**），future-event-service **只读不写**；**存档不存图本身，只存「当前所在 location 的 `Id`」**。这与「模板是共享只读单例、服务不得写回」的既有纪律一致。
- **推论 ④：`locationMap` 对玩家不可见，这不是遗漏而是与既定取向一致。** 「进程是逐批择一的线性推进，不是可俯瞰的分支地图」这条一直成立；**图存在但不呈现**，玩家仍然看不到全景。

### 七、`locationCodex` = 图鉴族第六本（玩家可见的那一面）

> **`locationMap` 玩家不可见，但需要新增 `locationCodex`，它是可见的。**

- **图鉴族由五本扩为六本**（Enemy / CharacterPower / PlayerPower / CharacterItem / PlayerItem **+ Location**）。它完全落在图鉴族的既有共同形状里：账号级、跨轮回持久、归 PlayerProfile、按稳定 `Id` 索引、条目是静态文案、存档只记解锁状态。
- **推论 ①（承重）：这是 `locationMap` 向玩家显影的唯一通道，且是「走过才记」的。** 与 EnemyCodex 的「遭遇即记」同构——**不给全景图，只给已经去过的地方的知识**。玩家的世界地图是**在多次轮回中一格一格拼出来的**，而不是一开始就发下来的。
- **推论 ②：它给「中长期规划感 / 方位感的来源」这条长期待答提供了第一个具体候选。** 方位感**不来自轮回内的俯瞰视图**（那条已被否），而来自**跨轮回积累的地理知识**。配合「Travel 给多个目的地并列」（见第八节），**跨轮回的知识增长直接转化为轮回内的决策质量**：第一次玩是盲选路线，玩多了就知道往哪走。
- **推论 ③：它是失败侧产出的又一条通道。** 一次失败的轮回同样把去过的地域写进了图鉴——与「EnemyCodex 遭遇即记、不必击败」同向。
- **待答：词条深度与「记不记连边」。** locationCodex 记什么（地名与风物文案？该地域的事件类型倾向？敌人清单？`eventCountLimit`？），尤其是**记不记它通向哪些地域**——若记连边，玩家就能跨轮回把 `locationMap` 完整重建出来。**这到底是设计目标（知识 = 力量）还是要避免的泄露，需要定。**

### 八、Travel 闸门给**多个**目的地（取宽松读法）

> **上限达成时的 Travel 选项 = 多个。**

- **⚠ 单数措辞的歧义就此裁定：** 本批收窄后剩下的是**若干个并列的 Travel 选项**（各指向 `locationMap` 上当前 location 的一个邻接地域），**「去哪」本身是一次真实的玩家决策**。
- **推论：闸门是路线决策点，不只是过场。** 它是逐批择一的线性进程里**唯一一个带地理含义的分岔**；结合 locationCodex，它是玩家把跨轮回知识变现的地方。**候选数量、是否全部邻接都给、是否 seeded 抽取**仍未定。

### 九、`eventCountLimit` 的计数口径定案

> **只计「选择进入并结算」的事件；跳过不计入，Travel 也不计入。**

- 先前的推论获确认，并**多答了一条**：**Travel 不占用所在 location 的配额**。
- **推论：这让闸门的算术干净。** 配额是「在这个地域做了几件事」的纯计数——**离开的动作本身不算做事**，跳过的事情也不算做事（与「跳过通常不流逝时间」完全同向）。三条口径（不扣寿元 / 不占配额 / 计入 `pastEvent`）合起来给出跳过的完整定位：**它只在行为轨迹上留痕，在任何资源与进度刻度上都不计。**

### 十、「每批必有不可跳过项」是设计意图，不是死锁

> **即便玩家打不过也得打；如果没能承压，则输掉这局很合理。**

- **`selectCost` 的「死锁」这条待答被以否定前提的方式答结：** 不需要产出侧的「至少一个可负担 / 可战胜选项」保证。**必须面对的遭遇打不过 → 输掉这一局，是正常且合意的结果**，不是需要被规则规避的故障。
- **推论 ①：这条与失败侧的既有建制自洽。** 输掉一局有产出（EnemyCodex 遭遇即记、道统残卷概率累积、失败也可能给经验），且篇章重试模型（无限 / 3 / 1）本就为失败留了位置。**「输」是这个游戏的一个正常出口，不是设计缺陷。**
- **推论 ②：它同时约束了产出侧不要过度保护。** 既然承压失败是合意的，物化时就**不应**为了「保证玩家过得去」而压低必做项的强度——难度的界由赋级带给出，已经足够。
- **剩余的一小块（形态不同，仍待答）：** 用户裁决的是**战斗打不过**；**付不起 `selectCost` 因而连进入都不能**在形态上不同——前者是「推进后失败」，后者是「无法推进」，后者不产生任何终态。故仍需一句：付不起唯一必做项的 `selectCost` 时，是**直接判负结束轮回**（与「输掉很合理」同向的自然收口），还是允许无成本进入？

## Open questions

- **location 的数据载体与定名。** `LocationData : Resource` + `.tres`？还是枚举 + 资源两件套？稳定 `Id` 形态、是否与 `AdventureEventData` 一样受 `AllEnabled()` 与 overlay 管辖。**`locationMap` 的载体同问**（邻接表资源？单份 `.tres`？）。
- **`locationCodex` 的词条深度，尤其是记不记连边。** 记连边 = 玩家可跨轮回重建整张 `locationMap`——是设计目标还是要避免的泄露？其余词条内容（风物文案 / 事件类型倾向 / 敌人清单 / 配额）亦未定。
- **Travel 闸门给几个候选、怎么选。** 是否把当前 location 的全部邻接都列出、还是 seeded 抽取其中几个；候选是否受剧本调制。
- **事件类型概率修正的形态。** 乘性权重 / 加性偏移 / 「白名单 + 权重」？某个类型能否被修正到 0（= 该地域不出这类事件，等价于软框定退化为硬框定）？**数值归内容阶段，但形态是机制。**
- **付不起必做项 `selectCost` 时的终态。** 「打不过就输」已定；「付不起因而无法进入」是另一种形态，需要一个明确出口（判负？无成本进入？）。
- **已定稿批次存续期间资源下降怎么办。** `SkipCost` 在物化时冻结、可负担性也在那一刻判定；若角色资源在这批存续期间下降（例如某个事件结算后的负向条目），已定稿的「可跳过」承诺可能失真。发生窗口很窄（一批只做一次操作），但需一句明确态度：重判、还是承认冻结即承诺。

## Notes / triage

- 本次是 **eventOptions 专场**的第一次 session（草稿首行即「let's discuss eventOptions this session」），焦点分片 ② 的多条待答由此收敛。
- 顺带把 `open-questions/02-event-options.md` 中被答结的两条移出（见 `answer-logs/log-0805b.md`），并把三条被收窄的条目改写为剩余部分。
