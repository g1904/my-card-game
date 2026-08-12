# 剧本内容本地化：撤销云端剧本服务，改由 content-service 的 overlay 通道承载

- id: 2026-08-11-plot-content-localization
- date: 2026-08-11
- topic: systems/services/plot-manager · systems/services/content-service · systems/architecture · program-overview · system-overview · terminology
- status: distilled
- distilled-to: `systems/services/plot-manager.md`, `systems/services/content-service.md`, `systems/services/future-event-service.md`, `systems/services/sync-service.md`, `systems/services/life-cycle-service.md`, `systems/services/_index.md`, `systems/architecture.md`, `systems/character-profile/_index.md`, `systems/adventure-event/finale/_index.md`, `program-overview.md`, `system-overview.md`, `terminology.md`, `open-questions/04-hidden-attributes-plot.md`, `open-questions/05-service-contracts.md`, `answer-logs/log-0811.md`

## Intent（原始提问）

> game & backend, why plot service is on backend side, can it be moved to game side so the game is mostly run locally other than syncing progress and auth ofc?

## Intent（distilled）

**一句话：剧本内容从「云端剧本服务按需下发」改为「本地内容层，走 content-service 已有的 overlay 通道」；客户端 ↔ 后端的跨进程边界由此收敛为「同步进度 + 鉴权 + 内容分发」，剧本不再是第四条边界。**

### 起因：这条决策此前从未被论证

盘点全库后确认，「剧本内容在云端」的既有依据只有两条，且都不成立为理由：

| 来源 | 说的是什么 | 强度 |
|------|-----------|------|
| `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` §3 | 「完整剧本与分支内容存于云端剧本服务，按 key points 请求」 | **纯断言，未给理由** |
| 本地 / 云端内容分界判据（07-25c） | 「按进度动态请求、一次性呈现、不被存档引用 → 云端剧本服务」 | **描述性、近乎循环**——「动态请求」是这个选择的*结果*，被当成了它的*理由* |

**且没有任何 Accepted ADR 覆盖剧本内容的归属**（ADR-0003 管的是存档 / 账号的云端权威，不涉及剧本文本）。因此本次改动**不推翻任何 ADR**，只是补上一条本该在 07-23 就做的论证，并得出相反结论。

### 撤销云端剧本服务的四项收益

1. **消除唯一的跨边界 manager。** `plot-manager.md` 原先明写「PlotManager 是本项目中唯一跨进程边界的 manager」。移走后，跨边界成分从 **4 个降到 3 个**，且**全部是服务本身**——manager 纪律不再有例外，「manager 不跨边界」成为无例外的结构性事实。
2. **删掉一整套为网络失败而生的复杂度。** 事务前置、`user://cache/plot/` 的 LRU 预取、延迟预算、超时兜底、断网降级文案——这些全部是「逐事件向云端请求文本」的派生物，随该请求一并消失。**剧本文本在事件发生之前就已在盘上。**
3. **后端少一个服务、少一份协议。** 后端 `systems/_index.md` 计划中的 `plot.md` 不再需要；`IPlotBackend` / `PlotRequest` / `PlotSegment`（字段至今 ⟨待定⟩）整套作废。剧本内容复用 content-service 已有的 manifest 通道——**已签名、文件级事务、断点即回退，全部现成**。
4. **闭合 5 条待答项**（后端 3 条 + 客户端 2 条），见「Clarifications」第 1 项与本文末。

### 落点：剧本文本是本地内容层的一员，但 overlay 对它**可新增 `Id`**

`content-service.md` 的热更纪律是「**overlay 只改不增**」。**为剧本文本开一个例外**，理由是这条纪律的**唯一**存在目的：

> 「旧版本客户端的存档引用到未知内容」这一风险从根上消失。

而剧本文本恰是内容类别里**唯一不被存档引用**的一类——`CharacterProfile` 只存 key points，剧本正文永不进存档。**因此为它放开新增 `Id`，不重新引入那条纪律要防的风险。** 例外的边界必须写窄：

- **例外只覆盖剧本内容类型本身**（AdventurePlot 的节点 / 分支 / 文本条目）。`CardData` / `AdventureEventData` / `ItemData` / `EnemyData` / `PlayerPowerData` / 平衡表**照旧「只改不增」**。
- **新增的剧本条目不得引用本次 overlay 之外的新 `Id`。** 一条新剧本 arc 若需要一张新卡或一个新 AdventureEvent，那两者仍只能随版本发版——剧本条目只能引用**已存在**的非剧本 `Id`。这保住合并后强校验的「交叉引用不悬空」。
- **由此，新剧情可热更不发版**——这正是原先云端剧本服务提供的能力，现在由 overlay 通道提供，且不需要运行时请求。

### 承重：悬空 key point → PushWarning + 叙事降级，不阻塞轮回

**这是本次改动唯一新生的风险，也是它能成立的前提。**

`CharacterProfile` 上的 key points 是**指向剧本结构的持久化锚点**。所以「剧本文本不被存档引用」只对**文本**成立，对**节点**不成立：玩家在带新剧本 arc 的 overlay 下存了 key point，随后 overlay 回退或客户端版本回退 ⇒ **key point 悬空**。今天这个风险不存在，是因为云端服务负责解析 key point。

**规则（已定案）：读取侧不因剧本条目缺失而失败。** 遇到当前合并结果里不存在的剧本节点 →

- `GD.PushWarning` 带上悬空的 key point 标识；
- **跳过该段叙事，以及该分支对 eventOptions 的调制**；
- **轮回照常继续**，`CharacterProfile` 不因此进入任何异常态。

这与 content-service 已定的**「读取侧不过滤」不对称原则同构**（产出侧过滤 `ContentEnabled`、读取侧 `Get(id)` 不过滤，使存档引用到已关闭条目仍能解析）。代价明写：**玩家会静默失去一段剧情与它带来的调制**，这被接受——剧本调制是塑造倾向而非硬性玩法结算，缺一段不会让轮回不可继续。

**这条不变式反向约束 key points 的 schema**（其粒度与 schema 仍是待答项）：**key point 必须能在其引用的剧本节点缺失时被安全跳过**，不得设计成「解析失败即无法确定当前剧本位置」的形态。

### 剧本是预写式内容库（已定案）

后端 `05-plot-service.md` 原有的「生成式还是预写式」未定项**答定为预写式**：剧本文本是人工 / 离线写就的静态内容。这是上述一切的前提——运行时生成（LLM）无法本地化（密钥、成本、内容审核都必须在服务端）。**由此该待答项整条闭合，且不留「未来可能改成生成式」的预留结构**（若将来要改，那是一次新的方向性决策，届时重开）。

### 剧透 / datamine 可接受（已定案）

剧本文本落到玩家磁盘上即可被提取。这与 `content-service.md` 已定的完整性边界**同调**：

> 客户端完整性做到「防误 / 防随手改」为止，**不承诺防作弊**。

纯 PvE，剧透只损失提取者自己的体验。**「隐藏剧本 + 隐藏属性」这层张力面向的是正常游玩的玩家，不面向 datamine 者**——为了防提取而承担一整条跨进程边界的复杂度，不成比例。

### 边界不变的部分（避免误读）

- **强制在线 · 云端权威（ADR-0003）原样成立。** 本次改的是**剧本内容的载体**，不是账号 / 存档模型。仍然必须登录、进度仍实时同步云端、冲突仍以云端为准。
- **「游戏基本本地运行」的准确含义**：跨进程边界只剩**鉴权（account-service）· 进度同步（sync-service）· 内容分发（content-service）**三处，且后者只在启动期比对 manifest。玩法回路（物化 eventOptions、结算、战斗、剧本调制）**全程零网络请求**。
- **状态转换触发的定性文案**（隐藏属性跨档叙事、Finale「失败但存活」补白）此前已定为内容层（08-10b）。本次改动使 `plot-manager.md` 内部**原有的那条「剧本正文走云端 / 定性文案走内容层」分界整体消失**——两者现在同属内容层，只是剧本条目可由 overlay 新增 `Id`，定性文案条目照旧只改不增。

## Clarifications（interview 产物）

1. **「生成式还是预写式」** → **预写式内容库**。这答定了后端 `05-plot-service.md` 的一条待答项，并使本地化成为可能。
2. **归属取向四选** → **overlay 可新增 `Id`**（走 content-service 通道），而非「纯本地随包发布」「保持云端现状」「留云端但复用 manifest 通道」。理由：既拿到本地运行的全部收益，又保住「新剧情不发版」的运营能力。
3. **本次运行的目标库** → **`game-design-documents/`**（改动量在客户端侧最重）。**后端侧需要一份对应的 handoff**——见「Notes / triage」。
4. **剧透 / datamine 是否可接受** → **可接受**，与既有「不承诺防作弊」边界同调。
5. **悬空 key point 的处理**（本次裁定引出的新冲突）→ **`PushWarning` + 叙事降级，不阻塞轮回**，而非「overlay 对剧本只增不删」或「key point 不引用节点 `Id`」。此裁定推翻了原始提问未涉及的一处隐含前提（「剧本文本不被存档引用」对剧本**节点**并不成立）。

## Open questions

- **剧本内容类型的数据形态。** 剧本条目是一种 `XxxData : Resource`（进 ContentRegistry、按 `Id` 索引、有自己的仓储），还是别的载体？若进 ContentRegistry，则合并后强校验对它生效——而「新增剧本条目不得引用本次 overlay 之外的新 `Id`」这条约束需要一个**可机械检查**的形态（按 `.claude/rules/*` 的「纪律的可执行化」阶梯，它属「能上线且线上不可见」，应做到第 1 / 2 级，而非仅约定）。
- **剧本内容的体积与分发粒度。** 全部三篇章的剧本树随包 + overlay 会有多大？是否需要按篇章分包、按进度增量下载（复用 manifest 的文件级事务即可，但**分包边界**未定）。原云端方案的「按需请求」天然回避了这个问题，本地化后它变成一个真实的包体 / 下载量问题。
- **key points 的粒度与 schema**（沿用，且**新增一条前置约束**）：必须满足「引用的剧本节点缺失时可安全跳过」。
- **AdventurePlot 树的数据表达**（沿用）：是**调制** eventOptions，还是并行结构。
- **DnD 式选分支**（沿用）：触发点、UI、玩家可见 / 不可见分支的边界。
- **隐藏属性的档位划分**（沿用，承重）：分几档、阈值在哪——跨档定性叙事完全依赖它。

## Notes / triage

**路由：**

- 归属反转 + overlay 新增 `Id` 例外 + 悬空降级 → `systems/services/plot-manager.md`（大改）、`systems/services/content-service.md`（分界表 + 「只改不增」例外）。
- 跨边界成分 4 → 3、`IPlotBackend` 作废、总则 7 由四接口降为三接口、条件编译清单 6 → 5 处 → `systems/architecture.md`、`system-overview.md`。
- 调用链与服务清单 → `program-overview.md`、`systems/services/_index.md`、`systems/services/future-event-service.md`（PlotManager 不再跨边界，形态 B 降为 A）、`systems/services/sync-service.md`（降级表删「剧本请求」一行）。
- 存档字段描述 → `systems/character-profile/_index.md`、`systems/services/life-cycle-service.md`。
- 术语 → `terminology.md`：**删除「剧本服务 / script service」词条**（该服务不再存在），改写「剧情节点」与「隐藏剧本管理器」。
- Finale 补白的「不随剧本服务下发」措辞 → `systems/adventure-event/finale/_index.md`（该分界整体消失）。

**ADR 候选：** 「剧本内容属本地内容层 · overlay 对剧本可新增 `Id`」是一条方向性决策，且它反转了 07-25c 的本地 / 云端分界判据。建议固化为 ADR，并在其中修订「内容载体形态」这条既有 ADR 候选。**本次不写 ADR**（归 `decisions/` 的步骤）。

**⚠ 另一侧需要一份对应的 handoff。** 本次只写客户端库。后端库需要同步执行：

- `systems/_index.md`：从「计划中的服务」表中**删除 `plot.md` 一行**及其「对位客户端成分 = PlotManager」。
- `open-questions/05-plot-service.md`：**整个分片作废删除**（3 条待答项：协议 / 生成式还是预写式 / 延迟预算——第 2 条已答定为预写式，第 1、3 条随剧本服务撤销而消失）；索引的分片导航表同步。
- `open-questions/01-contracts.md`、`README.md`：「跨越这条边界的客户端成分有四个」→ **三个**，删去 `PlotManager`。
- `contracts/`：剧本契约不再需要；剧本内容改由已有的 `content-manifest.md` 通道承载，需在该契约中说明剧本条目也走它。
