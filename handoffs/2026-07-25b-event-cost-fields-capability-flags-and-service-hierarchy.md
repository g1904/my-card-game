# AdventureEvent 成本 / 跳过字段 · PlayerPower 开关与能力标记体系 · 服务从属关系 · 架构闭环分析

- id: 2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy
- date: 2026-07-25
- topic: adventure-event/common-properties（eventType / selectCost / skipCost / ifMandatory / eventStart / eventEnd）, player-profile/player-power（status + capability flag 体系）, services/future-event-service ⊃ adventure-plot-service（从属关系）, architecture（展示层契约 + 闭环缺口）, balance / terminology（元婴 +500）, open-questions
- status: distilled
- distilled-to: terminology.md, systems/adventure-event/common-properties.md, systems/player-profile/player-power/common-properties.md, systems/player-profile/player-power/_index.md, systems/services/future-event-service.md, systems/services/adventure-plot-service.md, systems/services/life-cycle-service.md, systems/architecture.md, systems/common-properties.md, systems/balance.md, open-questions.md, handoffs/_index.md, `systems/player-profile/player-power/**`, `systems/_index.md`, `README.md`, `.claude/rules/Context.md`, `.claude/README.md`, `.claude/skills/analyze-new-ideas`, `.claude/skills/summarize-open-questions`, `.claude/skills/assess-derive-readiness(新增)`

## Intent（distilled）

一次以**类字段补全**为主的草稿：给 AdventureEvent 与 PlayerPower 补上共有字段与方法面，明确两个服务的从属关系，并附带两个架构层面的求解请求（展示数据归属、全局效果的系统化实现）与一次架构闭环体检。

### 1. 寿元阶梯闭合：元婴 +500（无玩法影响）

- **抵达元婴 lifeSpan +500**，寿元预算阶梯自此闭合：炼气起始 **100** → 筑基 **+100**（累计 200）→ 金丹 **+300**（累计 500）→ 元婴 **+500**（累计 **1000**）。
- **但元婴 = 游戏终点。** 抵达元婴即第三篇章通关（四境三篇章，见 `systems/game-progression.md`），轮回到此结束——因此 **+500 不产生任何可消耗的寿元预算**，它只是**最后一次数值更新并存档**。
- 推论（由上述直接得出）：元婴 +500 是**形式上的阶梯完整性**，不是平衡杠杆；调整它不改变任何一局的可玩长度。它在数值上唯一可能的用途是终局结算 / 成就展示所读取的最终寿元值（用途未定，见 Open questions）。
- 这解掉了 Open question「**元婴阶段是否再加预算**」 → **加，+500，但无玩法影响**。

### 2. AdventureEvent 共有属性补全（字段 + 方法面）

`AdventureEvent` 顶层 `common-properties` 补入以下共有成员：

| 成员 | 种类 | 含义 |
|------|------|------|
| `eventType` | 字段 | 事件类型（Combat / Explore / Research / …），即九类子类型枚举的字段化 |
| `selectCost` | 字段（**定制复合类型**） | **选择成本**——选中该事件所需付出的代价；**由若干成本 element 组成，`lifeSpanCost` 是其中一个 element** |
| `ifMandatory` | 字段 | **是否强制**（不可跳过） |
| `skipCost` | 字段（**同为该成本类型**） | **跳过成本**——跳过该事件所需付出的代价 |
| `eventStart(...)` | 方法 | 事件开始时的入口回调 |
| `eventEnd(...)` | 方法 | 事件结束 / 结算时的出口回调 |

由此**显式化的机制推论**（从上述字段逻辑上必然得出，非臆造）：

- **eventOptions 中的事件是可以「跳过」的。** `skipCost` + `ifMandatory` 共同蕴含一条此前未记录的玩家通道：面对一批 eventOptions，玩家除了「选择其一」外，还可以**跳过**某个事件；`ifMandatory = true` 的事件封死这条通道（必须面对）。
- **选择与跳过都不是免费的。** `selectCost` / `skipCost` 把「推进」建模为一次**双向付费的取舍**，而非单纯的菜单点选——这与月圆之夜式事件菜单的策划取向一致。
- **`selectCost` 是一个定制的复合成本类型（用户确认）。** 它**不是单一数值**，而是由**若干成本 element 组成**的定制类；**既有的 `lifeSpanCost` 是其中一个 element**。因此一个事件的选择代价可同时涉及多种资源，由该成本类型统一承载，而非在 AdventureEvent 上平铺一堆并列成本字段。**`skipCost` 与 `selectCost` 同为该类型（用户确认）**——跳过与选择付的是同一套资源体系，只是数值取向不同。此举同时消解了「`selectCost` 与 `lifeSpanCost` 语义重叠」的疑似矛盾——二者是**包含关系**，不是并列或重复。
- **`eventType` 是既有分类法的字段化落地**，与 `terminology.md` 九类枚举、`decisions/ADR-0002` 一致；Mystery 作为元类型遮罩一个固定事件的语义不变（被遮罩事件的真实 `eventType` 在揭示前不可见）。
- **`eventStart` / `eventEnd` 是事件自身的生命周期钩子**，与 life-cycle-service 的 `AdvanceEvent(...)` 构成「服务驱动 → 事件自结算 → 服务收口」的两段式：服务负责状态机与 CharacterProfile 写入，事件负责自身内部流程。（两者的职责边界仍需细化，见 Open questions。）

### 3. PlayerPower 共有属性补全：`status`（启用 / 禁用）

- `PlayerPower` 补入共有字段 **`status`：启用 / 禁用**。这是既有「每个 PlayerPower 都 always-available 且**带开关**（默认开启）」这条设计的**字段化落地**——开关不再只是 UX 描述，而是 PlayerPower 类上的持久状态。
- 推论：`status` 与「**拥有 / 失去**」是**两个正交维度**。PlayerProfile 的 `List<PlayerPower>` 表达「拥有哪些」，`status` 表达「拥有的这些里哪些当前生效」——`AdventureEvent 过程中可能失去 PlayerPower`（见 `player-power/_index.md`）是把条目移出列表，而不是置 `status = 禁用`。存档需要同时表达这两态。

### 4. 服务从属关系：future-event-service ⊃ adventure-plot-service

- **adventure-plot-service 隶属于 future-event-service。** 二者不是并列的同级服务：**future-event-service 调用 adventure-plot-service 的接口**来计算 eventOptions，并把结果传给 `characterProfile`。
- 由此确定的调用链方向（此前架构文档把两者画为并列的兄弟服务，现予以修正）：

  ```
  future-event-service.ComputeEventOptions(characterProfile)
        └─▶ adventure-plot-service.<剧本接口>  （隐藏属性阈值 / key points → 调制）
        └─▶ location 框定  +  seeded RNG
        ──▶ eventOptions ──▶ characterProfile
  ```
- 推论：adventure-plot-service **不直接写 eventOptions**，也不直接对 game-progression / UI 暴露 eventOptions；它是 future-event-service 内部的一个**被调用的调制源**。对外呈现 eventOptions 的唯一出口是 future-event-service。

### 5. 求解请求 A：展示（充血）字段应放在哪一层？

**用户提问：** 这些类目前只携带编码（Id / 数值），前端要用的描述字段是否应包含进去，还是该为充血模型单独建一个对应的类供前端展示？

**方案（已由用户确认采纳）——三层分离，不为「充血」单建一套并行类：**

1. **静态展示文本留在数据资源上。** `XxxData : Resource`（`.tres`）除稳定 `Id` 与玩法数值外，**直接携带**显示名 / 描述 / 图标等静态展示字段——这本就是 `data-resource-rules.md` 的既有约定（显示字符串与 `Id` 分离，可改动 / 本地化而不破坏引用）。为它们另建一套并行类只会制造两份需要同步的真值。
2. **运行时 / 存档态只带 `Id` + 可变状态。** `CharacterProfile` 及其持有的运行态对象**不复制展示文本**——存档与上行云端负载保持轻量、可版本化，且本地化文案变更不触发存档迁移。
3. **需要「组装后」的描述时，用 UI 层的轻量 ViewModel。** 动态描述（数值代入「消耗 N 点寿元」、条件文案、按 capability flag 变化的可见性）由**展示层按需组装** `Data + 运行时状态 → ViewModel`，只存在于呈现期，不落存档、不进云端负载。

即：**「贫血 vs 充血」的答案不是二选一，而是按生命周期切分**——静态展示归数据资源（已充血），可变状态归运行时/存档（保持贫血），组合展示归 UI ViewModel（一次性）。

### 6. 求解请求 B：如何系统性地实现「更改全局设定」类的 PlayerPower 效果？

**用户提问：** 像「让玩家看见角色隐藏属性数值」这类改变全局设定的 PlayerPower，如何系统性定制，而不是在每个受影响的层去加定制条件？

**方案（已由用户确认采纳）——注册 → 中心聚合 → 单点查询，分两条通道：**

**通道一：布尔型「能力标记 / capability flag」**（可见性、解锁、QoL）

- 每个此类效果定义为一个**具名能力标记**（例：`RevealHiddenStats`、`ShowMysteryType`、`ShowSkipCost`）。PlayerPower 的效果定义里**声明它授予哪些 flag**——即 flag 是 `.tres` 数据字段，新增能力 = 新增数据，不改系统代码。
- 一个 **capability 聚合面**（归 player-profile 服务侧）在启动及 PlayerProfile 变更时，把所有 **拥有且 `status = 启用`** 的 PlayerPower 所授予的 flag 聚合为一份**生效能力集**，并在变更时经 **EventBus** 广播 `CapabilitiesChanged`。
- **消费侧收敛为「一个 flag ↔ 一处消费点」。** 关键不在于把 `if` 写得更短，而在于**让受影响的那个组件自己订阅**：隐藏属性的显示组件默认隐藏，自己查询 `Has(RevealHiddenStats)` 并响应 `CapabilitiesChanged` 重绘。业务逻辑层完全不知道这个 power 存在——因为「是否显示」本就是呈现层的单一职责。**散落条件的根因是把呈现决策写进了业务层**；把决策点归位，条件自然只剩一处。

**通道二：具名数值「修正管线 / modifier pipeline」**（平衡修正）

- 对非布尔的全局修正（例：`lifeSpanCost`、`skipCost`、商店价格、掉落权重），PlayerPower 注册**具名 modifier**（key + 运算 + 数值，同样是 `.tres` 字段）。
- 系统在读取该数值时**统一走一个入口**——`Apply(key, baseValue)`——而不是在各消费层写 `if (hasPowerX) value -= 1`。新增一个修正 = 新增一条数据，受影响系统零改动。

两条通道共享同一形状：**数据声明 → 中心聚合（随 `status` / 拥有状态实时重算）→ 单点查询**。这满足 `data-resource-rules.md` 的「内容保持可加性：新增 = 新增 `.tres`，而非编辑 switch」。

### 7. 求解请求 C：架构闭环体检（当前缺口）

**用户提问：** 当前架构是否合理，有何缺失的逻辑尚未闭环？

**评价：** 类模型化（core 数据类 + services 操作面）的骨架**方向合理**——CharacterProfile / PlayerProfile 作为被操作的数据核心、服务不持有独立数据、跨系统走 EventBus，这套划分与 Godot/C# 侧的约定自洽。本次确立的 future-event-service ⊃ adventure-plot-service 也让 eventOptions 有了**唯一出口**，消除了先前两个并列服务都可能改写 eventOptions 的歧义。

**尚未闭环的缺口（按严重度排序，均登记为 Open questions）：**

1. **PlayerProfile 侧没有任何服务（最大缺口）。** 现有三个服务全部围绕 CharacterProfile（轮回内）。账号级的行为——PlayerPower 的获取 / 失去、`status` 开关持久化、PlayerItem 使用次数扣减、成就进度累计与奖励发放、登录 / 云端同步——**没有任何服务归属**，目前只能散落到调用方。第 6 节的 capability 聚合面也需要一个宿主。→ 缺一个 **player-profile-service（账号级服务）**。
2. **战斗内部没有归属。** `AdventureEvent-Combat` 被选中之后，回合循环、出牌结算、deck 抽 / 弃 / 洗、敌人意图——由谁驱动**未定**。life-cycle-service 只到 `AdvanceEvent` 这一粒度，`eventStart` / `eventEnd` 也只是事件自身的钩子。→ 缺一个 **combat-service（或明确由事件自持）**。
3. **存档 / 云同步没有归属。** 架构数据流图里出现了 `SaveManager` 与云端，但它既不是核心类也不是服务，无文档。强制在线 · 云端权威（ADR-0003）下，**同步时机、冲突以云端为准的落地、断线缓冲、原子写 + schema 版本迁移**都无归属。→ 缺一个 **save/sync 服务**。
4. **本地内容与云端内容的分界未定。** DataRegistry 在启动时加载本地 `.tres`；剧本服务在云端下发剧本内容。**AdventureEvent 的定义本身属于哪一侧？**（本地 `.tres` 还是云端下发？）若在本地，云端剧本服务只下发文本；若在云端，DataRegistry 的启动期校验模型（缺失 / 悬空 id 立即失败）就不成立。这条分界不定，两套加载路径都无法定稿。
5. **skip 通道没有结算归属。** 本次新引入的「跳过事件」是玩家推进轮回的一条新路径，但它走哪个 API 未定：是 life-cycle-service 新增 `SkipEvent(character, event)`，还是复用 `AdvanceEvent` 的一个分支？跳过后是否也触发 eventOptions 重算（大概率是）？跳过是否计入 `List<AdventureEvent>` 修行历程？均未闭环。
6. **`selectCost` / `lifeSpanCost` 疑似语义重叠（见下方矛盾）。**
7. **life-cycle-service 与 future-event-service 的调用方向未定。** 事件结算完成后，是 life-cycle-service 主动调 future-event-service 重算，还是 game-progression 编排两者，还是走 EventBus 通知？三者的编排顶点缺失。
8. **UI 与服务之间没有契约层。** 第 5 节的 ViewModel 一旦确认，架构图里需要显式的呈现层，否则「服务 → 屏幕」之间的数据形态无定义。

### 8. 流程治理：derive 就绪度全量回滚 + 独立评估技能

- **现有 derive 就绪度判定全量作废。** 先前逐次 handoff 顺带下的逐文档就绪度结论（07-22 ~ 07-25）**全部回滚**——**本库目前尚未进入可以 derive 的阶段**。
- **`/analyze-new-ideas` 不再评估或更新 derive 就绪度。** 理由：设计仍在快速演进，顺带下的判定会迅速过时且互相矛盾；就绪度只有**基于全库一次性全量扫描**才有意义。技能已更新（新增第 8 步「不评估 derive 就绪度」这一强制边界，并从输出形态中移除「下一阶段」）。
- **新增技能 `/assess-derive-readiness`。** 全量扫描全部主题文档，逐份判定 ready / partial / blocked，并**整体重写** `open-questions.md` 的「derive 就绪度」小节（它是该小节的**唯一写入者**，其余一切只读）。判定在 `/derive-requirements` 的三条就绪性门之上，叠加两条**横切**检查——**依赖闭合**（不能把关键机制甩给仍空白的文档）与**无孤儿路径**（每条玩家路径都有归属系统）。判定纪律：宁可判 blocked，「用占位数值先 derive」不构成 ready。
- **由用户手动调用。** 时机成熟时由用户主动跑，不由任何其他技能自动触发。

## Open questions

- **成本类型的 element 清单是什么？**（`selectCost` = 定制复合成本类型、`lifeSpanCost` 为其一个 element 已确认。）其余有哪些 element（jade？mana？道具？隐藏属性推拉？）、各 element 的数据形态（固定值 / 区间 / 公式）、付不起某个 element 时的判定（整体不可选？部分抵扣？）均未定。→ `systems/adventure-event/common-properties.md`、`systems/character-profile/currency.md`、`systems/balance.md`。
- **跳过是否也扣 `lifeSpanCost` element？**（`skipCost` 与 `selectCost` 同类型已确认，故寿元在结构上可以是跳过的代价之一。）但「跳过一个事件时时间是否照样流逝」属玩法取向，未定。→ `systems/adventure-event/common-properties.md`。
- **跳过机制的完整语义未定。** 付出 `skipCost` 后：被跳过的事件是从本批 eventOptions 移除、还是整批刷新？是否计入修行历程 `List<AdventureEvent>` / `pastEvent`？能否跳过整批（全部跳过）？跳过是否也扣 `lifeSpanCost`（时间照样流逝？）？付不起 `skipCost` 时的表现？→ `systems/adventure-event/common-properties.md`、`systems/services/future-event-service.md`。
- **`ifMandatory` 的产出侧规则。** 强制事件由谁标记——是内容作者在 `.tres` 上写死，还是 future-event-service / adventure-plot-service 在产出 eventOptions 时动态置位（例如剧情线关键节点强制）？一批 eventOptions 里能否**全部**为 mandatory（等于取消选择权）？→ `systems/services/future-event-service.md`。
- **`eventStart` / `eventEnd` 与 life-cycle-service `AdvanceEvent` 的职责边界。** 谁写 CharacterProfile、谁扣成本、谁推拉隐藏属性、谁触发 eventOptions 重算？签名与返回（结算结果对象？）未定。→ `systems/adventure-event/common-properties.md`、`systems/services/life-cycle-service.md`。
- **ViewModel 层是否需要单独一份文档？**（第 5 节方案已采纳并在 `systems/architecture.md` 显式化。）单列文档还是归 `ux/` 待定。
- **capability flag / modifier 的落地细节？**（第 6 节方案已采纳。）仍需定：flag 的枚举 / 命名空间、聚合面的宿主服务（见缺口 1）、`status` 与「拥有 / 失去」两态的存档表达、冲突 / 叠加规则（两个 power 授予同一 flag、modifier 的运算顺序）。→ `systems/player-profile/player-power/common-properties.md`。
- **PlayerProfile 侧待完善（用户已确认为待办）。** 账号级的服务与结构需一次专门设计：是否新增 **player-profile-service**、其 API 面（PlayerPower 获取 / 失去与 `status` 持久化、PlayerItem 次数扣减、成就进度与奖励发放、登录 / 云端同步）、capability 聚合面的宿主归属。→ `systems/player-profile/`、`systems/architecture.md`。
- **元婴 +500 的用途。** 既然无玩法影响，最终寿元值是否被终局结算 / 成就 / 排行读取？若否，是否值得保留该字段更新？→ `systems/balance.md`、`ux/screen-flow.md`。
- **架构缺口 2–7 各自的归属与优先级**（见第 7 节；缺口 1 = PlayerProfile 侧已确认为待办，缺口 8 已由 ViewModel 定案闭合）：是否新增 combat-service / save-sync-service？本地 `.tres` 与云端下发内容的分界如何划？life-cycle-service ↔ future-event-service 的编排顶点是谁？→ `systems/architecture.md`。

## Notes / triage

- 第 5 / 6 节是**应用户要求给出的方案**，**已由用户确认采纳**，在主题文档中记为已定案并登记为 **ADR 候选**（展示层三层切分、capability flag + modifier pipeline、服务从属）。第 7 节的体检结论作为「闭环缺口」小节落入 `systems/architecture.md`。
- 第 1 节解掉了 `open-questions.md` 中「元婴阶段是否再加预算」；第 4 节修正了 `systems/architecture.md` 与各服务文档中「三个服务并列」的表述。
- 「跳过事件」是本次输入**隐含引入的新玩法通道**，先前全库无任何记载——已在 `adventure-event/common-properties.md` 与 `future-event-service.md` 双向登记，其语义空白量较大（见 Open questions）。
