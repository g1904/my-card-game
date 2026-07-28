# Open questions — 跨 session 待答清单

> 本文件是**客户端**（Godot 项目）的待答清单；后端侧的待答清单在 `backend-design-documents/open-questions.md`（`backend-design` 分支）。
>
> 每次 session 结束时，未答的 Open questions 汇总到此，供下次拾起；一旦答定，就从此处移除、归档进对应主题文档的 `## 待决问题` / `## 决策`，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。此文件**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；已答定问题的移出记录见 `answer-logs/`。最近更新：**2026-07-27b**（**七服务 API 契约定案**：八条总则——三种方法形态按边界划分（A 同步直返 / B `Task<OpResult<T>>`+`CancellationToken` / C `Task<T>` 由信号推进，B/C 带 `Async` 后缀）；三种失败语义与 null-check 一一对应（**业务失败返回 `OpResult` 绝不抛**）；服务门面固定骨架（manager `internal sealed`、不暴露 manager 引用、不返回可变集合）；**Bootstrap 启动契约**（`_Ready` 只装配，I/O 归 `IBootstrappable.InitializeAsync`）；**EventBus 改用 C# 泛型 `event` + `readonly record struct` 负载**（否决 Godot `[Signal]`：负载须继承 `GodotObject` → 每次广播分配 + `Variant` 装箱）；**后端接口化**（四个窄接口 × Http/Offline 两份实现，`[Export] bool UseOfflineBackend` 切换）；**结算阶段名取代事件自带钩子**（`eventStart`/`eventEnd` 是 `AdvanceEventAsync` 的流程阶段名 + 两个 `IEventResolver` 实现）。另：**AdventureEvent 物化模型**——`AdventureEventData` 是模板、future-event-service 是**唯一物化点**、`EventOption` **产出即定稿**（immutable、落存档、不回查模板重算）；`CostSpec`/`RewardSpec` **合并为 `ProfileChangeSpec`**（element 带符号）；`CapabilityFlag` 用 C# `enum`；`CombatResult.Spoils` 为 `ProfileChangeSpec`，由 life-cycle 在 `eventEnd` 合并为**一次** `TryApply`；跨服务纪律措辞收紧为「不读写对方字段、不伸手进对方 manager，**方法调用允许**」。）｜ 前次 2026-07-27（**内容管线 / 热更遗留六项 + 断线韧性全部裁决**：热更改用**内容共有字段 `ContentEnabled: bool`（默认 `true`）翻开关放量**、**否决预埋占位 `Id`**，**过滤只在产出侧**（抽取走 `AllEnabled()`、读取侧 `Get(id)` 不过滤，故存档引用零风险）；存档记**两个 `contentVersion`**（`StartContentVersion` 不变 / `LastContentVersion` 每存档点更新，二者不等 = 跨过内容更新）；增量下载 = **文件级粒度 + 文件级事务**（staging → 全集校验通过 → 原子写 manifest 作提交点，永不半套 overlay）+ **manifest 签名**（边界：防误不防作弊）；断线**绝不回退存档点**——push 缓冲不阻塞 / pull 硬阻塞 / 剧本事务前置，缓冲上限 3 个存档点或 180 s → 软阻塞，恢复时**先 pull 后 flush**、云端 `revision` 领先则丢弃本地缓冲；RNG 持久化 = `CycleSeed` + 具名子流 **`State`（恢复权威）+ `DrawCount`（迁移保险）**，战斗内每场再派生防 re-roll；**存档点与 push 解耦**（本地即时原子写、网络 5 秒防抖 + `PushPolicy { Debounced | Immediate }`），增量 push 按 **`CharacterProfile` 粒度 diff**；开发路线定为**框架 → 内容 → 平衡与体验 → 社交及其他**（每日种子 / 排行挑战归第 ④ 阶段，当前不预留结构）；存档 schema **bump 版本 + 立起空迁移骨架**。）｜ 前次 2026-07-26（新增 AdventureEvent 共有字段 **`eventPriority`（事件优先级）**：通常为 0 可自由择一，出现更高优先级则**有效可选集收窄为最高档**；**跳过通道玩法语义定案**——**单项补位**（补位可落空则本批少一项）、**通常不扣 `lifeSpanCost`**、**计入 `pastEvent`** 作为行为轨迹；**`ifMandatory` 由 future-event-service 产出时动态置位**，一批可全部 mandatory；**热更范围收窄为「只改不增」**（overlay 不得新增 `Id`）并据此**放弃跨内容版本的 seed 可复现**（以 overlay 更新为准、不冻结 `contentVersion`），同步修订 `.claude/rules/state-save-rules.md`；**player-profile 子系统落位**（`player-item/` / `player-power/` / `achievements/` 成文件夹，`account-info.md` / `game-setting.md` 为独立 markdown，新建四份文档）；**元婴 +500 的读者 = 元婴界面（通关证书）**；**寿元 <10% UX = 标红数值倒数**；架构闭环缺口 **8 处全部闭合**。）｜ 前次 2026-07-25c（确立**两级层次 service ⊃ manager**；**拆分轴定案 = 生命周期层 + 行为边界，非数据类型**（否决按 power / item / card / resource 各开 collection 服务、否决按事件类型各开服务）；服务清单收敛为**七个**，新增 account-service / content-service / sync-service / profile-service / combat-service，**adventure-plot-service 降级为 PlotManager**；**内容三层管线**（`res://` 基线 + `user://overlay/` 热更 + 云端版本校验）与**本地 / 云端内容分界**定案；**两条唯一入口**（ContentRegistry 读内容、ProfileManager 写档案）+ **编排顶点 game-progression**；**术语修正：全库废弃「微服务」措辞**（service = 进程内模块单例，唯一真实进程边界是客户端 ↔ 后端）；新增两份根级总览 `program-overview.md`（运行时视角）+ `system-overview.md`（工程视角：进程边界 / 文件夹布局 / autoload 注册 / 代码形态 / 离线 stub 策略）；架构 8 处缺口闭合 6 处、1 处部分闭合。）｜ 前次 2026-07-25b（AdventureEvent 补入 `eventType` / `selectCost` / `skipCost` / `ifMandatory` + `eventStart` / `eventEnd`，隐含引入**「跳过事件」通道**；PlayerPower 补入 `status`（启用 / 禁用）；**隐藏剧本层隶属于 future-event-service**（07-25c 进一步降级为其内部的 **PlotManager**）；元婴 lifeSpan +500（无玩法影响）；两项**提案待确认**：展示字段三层切分、capability flag + modifier pipeline；一次**架构闭环体检**列出 8 处缺口；`selectCost` 确认为**定制复合成本类型**、`lifeSpanCost` 为其 element；两项提案**均获采纳**；**derive 就绪度全量回滚**，改由 `/assess-derive-readiness` 手动评估。）｜ 前次 2026-07-25（寿元数值化：计数器模型 100 / +100 / +300、隐藏→<10% 显示、按 AdventureEvent 的 `lifeSpanCost`（基准 -1）扣减→0=defeated；服务层重命名 run-manager→**life-cycle-service**、adventure-plot→**adventure-plot-service**，新增 **future-event-service**（产出 eventOptions）；character-profile 结构定案；ADR 重构为九类 + 治理约定改为「一切皆可改：取消仅追加 / ADR 不可变」，全库遗留清理。）

## 待答（按主题）

### 服务 API 契约（07-27b 主干全部定案，残留细节）
> 「七个服务的 API 面未定义」这条**已答结**——八条契约总则、共享核心类型、逐服务签名骨架、EventBus 负载 schema 均已定案，权威在 `20-systems/architecture.md`「API 契约总则」。移出记录见 `answer-logs/log-service-api-contracts.md`。以下为定案过程中新浮现的下一层问题。
- **`AdvanceEventAsync` / `RunCombatAsync` 的取消语义。** 形态 C 带 `CancellationToken`，但「谁会取消一场进行中的事件 / 战斗」以及取消后已施加的 `SelectCost` 如何处置（回滚？视同结算？）未定——这与「战斗中途断线 / 退出」是同一个问题的两面。→ `20-systems/services/life-cycle-service.md`、`combat-service.md`、`sync-service.md`。
- **`[Export] bool UseOfflineBackend` 的发布期防护。** 四个边界服务的离线 stub 开关默认 `true` 直到后端上线；正式包如何保证它不为 `true`（导出预设 / 编译期 `#if` / 启动期断言）未定——这是一个能悄无声息发到线上的开关。→ `system-overview.md`。
- **`OpError` → 玩家文案的映射归属。** `OpResult.Detail` 约定携带「面向玩家的原因串，由 UI 层决定文案」；这份映射表由谁持有（UI 层常量？本地化表？服务返回已本地化串？）未定。→ `40-ux/`。
- **EventBus 退订纪律的可执行性。** 「`_Ready` 订阅 / `_ExitTree` 退订」是约定；漏退订即泄漏，且在 C# 事件上不会报错。是否需要 EventBus 侧的调试期订阅计数 / 泄漏检查未定。→ `20-systems/architecture.md`。

### 内容管线 / 热更 · 同步韧性（07-27 主干全部裁决，残留细节）
> 07-25c / 07-26 遗留的六条已全部答结，移出记录见 `answer-logs/log-0727.md`。以下为 07-27 裁决过程中新浮现的下一层问题。
- **`AllEnabled()` 纪律的可执行性。** 约定已立（抽取必走 `AllEnabled()`），但如何在代码评审之外强制未定：`All()` 是否应改名为 `AllIncludingDisabled()` 让默认路径就是安全路径？还是靠 Roslyn 分析器 / 评审清单？→ `20-systems/services/content-service.md`。
- **`ContentEnabled` 的粒度是否够用。** 单一布尔只支持「全开 / 全关」；**灰度与分批放量**需要按玩家分桶（百分比 / 白名单 / 篇章档位），布尔字段本身不携带分桶信息。分桶信息放哪（overlay 的另一层配置？后端下发的 bucket 列表？）未定。→ 同上。
- **disabled 条目被存档引用时的 UX。** 读取侧不过滤故存档能正确解析；但玩家手中一张「已被线上关闭」的卡 / 道具是否应有提示，还是完全静默照常可用？→ `20-systems/services/content-service.md`、`40-ux/`。
- **`manifestSchema` 的版本化。** 它触发整包全量重下，但自身版本号形态、与 `contentVersion` / `appVersion` 的关系未定。→ `20-systems/services/content-service.md`。
- **`revision` 的产生方与语义。** 断线合并依赖比较云端与本地基线的 `revision`（单调递增计数？服务端时间戳？ETag？），由谁分配、客户端如何持有基线值未定——属**客户端 ↔ 后端协议契约**，应同步登记进 `backend-design-documents/open-questions.md`。→ `20-systems/services/sync-service.md`。
- **软阻塞与「进入战斗前强制 flush」的交互。** 进入战斗前是 Immediate flush 点；若此时已处于断线缓冲超限态，玩家是被挡在战斗外（软阻塞发生在 AdventureEvent 选择前）还是可以进入？两条规则的先后顺序未明写。→ 同上。
- **`attemptIndex` 的来源。** 防 re-roll 派生式 `Hash64(combatStreamSeed, eventId, attemptIndex)` 中 `attemptIndex` 的语义未定：同一事件的第几次进入（需落存档计数）还是篇章重试的第几次（复用既有重试计数）？**不落存档则退出重进仍会重掷，防护落空。**→ `20-systems/services/life-cycle-service.md`、`combat-service.md`。
- **剧本预取与事务前置的边界。** 预取降低失败率但不消除它；**LRU 容量上限**、**预取失败是否静默**（留待实际请求时再报）未定。→ `20-systems/services/plot-manager.md`。

### AdventureEvent 选择约束 / 跳过通道（07-25b · 07-26 更新）
- **成本类型的 element 清单：** `selectCost` 为定制复合成本类型、`lifeSpanCost` 为其一个 element 已定；**代码形态已定为 `ProfileChangeSpec`**（element 带符号，成本与产出合一，物化时组装 —— 07-27b）。仍待定：`CostKey` 的其余成员（jade / mana / 道具 / 隐藏属性推拉？）、各 element 的数据形态（固定值 / 区间 / 公式）、是否允许**部分抵扣**（「整体不可选」已由全有或全无的事务语义确定）。→ `20-systems/adventure-event/common-properties.md`、`20-systems/character-profile/currency.md`、`20-systems/balance.md`。
- **`eventPriority` 与 `ifMandatory` 的叠加规则（07-26 新增）：** 高优先级事件**能否被跳过**？若被跳过，本轮是否解除对低优先级事件的封锁？二者都限制选择权，是否语义重叠（高优先级是否应蕴含 mandatory）？→ `20-systems/adventure-event/common-properties.md`、`20-systems/services/future-event-service.md`。
- **`eventPriority` 的取值域与置位方（07-26 新增）：** 两档（0 / 1）还是任意整数档位？是否也由 future-event-service / PlotManager 动态置位（用户仅明确了 `ifMandatory`）？→ 同上。
- **跳过语义的残留细节（07-26 收窄）：** 主干已定（单项补位 / 通常不扣寿元 / 计入 `pastEvent`）；仍待定：**能否整批全跳**、**付不起 `skipCost` 时如何表现**。→ `20-systems/adventure-event/common-properties.md`、`20-systems/services/life-cycle-service.md`。
- **补位落空的判定规则（07-26 新增）：** 何种条件下 future-event-service 补不出新事件？eventOptions 是否允许被跳到只剩 0 个？若剩 0 个玩家如何推进（死局兜底）？→ `20-systems/services/future-event-service.md`。
- **`pastEvent` 的痕迹 schema（07-26 新增 · 07-27b 加约束）：** 持久化**方式**已定（存**物化后的定稿实例快照**、按 `InstanceId` 索引，不重算）；仍待定：如何区分「进入并结算」与「跳过」两种痕迹及各自成本、快照存哪些字段、**快照体积对增量 push 粒度的影响**。→ `20-systems/adventure-event/common-properties.md`、`services/sync-service.md`。
- **全部 mandatory + 付不起 `selectCost` 的死锁（07-26 新增）：** 一批可全部 mandatory 且高优先级封锁其余选项；若付不起唯一可选事件的 `selectCost`，轮回无法推进。是否需产出侧「至少一个可负担选项」的保证或兜底降级？**07-27b 收窄：** 既然 `selectCost` 是**物化时组装**的，这条保证天然有落点（物化阶段即可对照 `CanAfford` 调整）；剩下的只是「要不要给」与兜底形态。→ `20-systems/services/future-event-service.md`。

### 架构闭环缺口（07-26 更新：8 处**全部闭合**）
- 缺口 1 ~ 8 **均已闭合**——1/2/3/4/6/7/8 的移出记录见 `answer-logs/log-0725c.md`；**缺口 5（skip 通道）** 的玩法语义主干于 07-26 补齐，移出记录见 `answer-logs/log-0726b.md`。残留细节已下沉为上节的普通待决问题。
- 状态表见 `20-systems/architecture.md` 的「闭环缺口」小节。

### 隐藏属性 / 寿元（07-25）
- **寿元 `lifeSpanCost` 分档 / 增长途径：** 消耗机制已定（按 AdventureEvent 的 `lifeSpanCost` 扣减，基准 -1）；预算阶梯已闭合（100 / +100 / +300 / +500）。仍待定：哪些事件类型 / 具体事件应覆写基准（更大 / 更小 / 回寿）、是否有非境界突破的寿元增长途径。→ `20-systems/adventure-event/`、`20-systems/balance.md`。
- **隐藏属性清单与阈值：** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏；仍待定：是否还有其他隐藏属性、各自阈值、增减触发（哪些 AdventureEvent 推拉）、剧情线目录。→ `20-systems/services/plot-manager.md`、`20-systems/services/life-cycle-service.md`。

### future-event-service / eventOptions（07-25）
- **eventOptions 生成 / 加权规则：** 服务化架构已定，但从 CharacterProfile **生成 / 加权抽取**下一批 eventOptions 的具体规则（月圆之夜式策划 vs 随机权重、每批数量、node 类型配比、带种子 RNG 派生）、以及 location 框定 / AdventurePlot 调制 / seeded RNG 的**叠加顺序**未定。→ `20-systems/services/future-event-service.md`、`20-systems/game-progression.md`。
> 跳过补位、`eventPriority` / `ifMandatory` 的产出侧规则见上方「AdventureEvent 选择约束 / 跳过通道」。
- **`EventOption` 的完整物化字段清单（07-27b 收窄）：** 骨架九字段已定（`InstanceId` / `EventId` / `EventType` / `Priority` / `IsMandatory` / `SelectCost` / `SkipCost` / `IsRevealed` / `RevealedEventId`），先前问的「是否携带已结算的 cost 实例与 Mystery 揭示状态」**答案是携带**。但既定的物化模型说「**多数**属性由物化决定」，故仍待定：还有哪些字段由物化产出（哪些数值可被情境改写？风味文案是否也物化？outcome 权重是否在物化时固化？）——**需要一次内容侧 handoff**。→ `20-systems/services/future-event-service.md`、`20-systems/adventure-event/common-properties.md`。
> eventOptions 的持久化形态已答结（落**物化后的定稿实例快照**，不重算），移出记录见 `answer-logs/log-service-api-contracts.md`；剩余的快照字段形态见上方「AdventureEvent 选择约束」的 `pastEvent` 痕迹 schema 一条。

### AdventurePlot 数据编码 / 剧本服务（层级已定，细节待定）
- **AdventurePlot 数据编码与剧本服务契约：** 四级结构、「Character 只存 key points、内容在剧本服务」、**离线降级**（事务前置 + `user://cache/plot/` LRU 预取，07-27 定案）均已定；仍待定：树的数据表达（**调制** eventOptions 还是并行结构）、key points 粒度 / schema、剧本服务**请求 / 下发协议与版本化**、DnD 式选分支触发点与 UI。→ `20-systems/services/plot-manager.md`。

### AdventureEvent 分类法（结构已定，逐类型机制待定）
- **各类型的结算 / 机制细化：** 九类分类法已定（`50-decisions/ADR-0002` 九值枚举），但各类型的具体玩法机制仍待设计（ADR-0002「Consequences / 待办」）：**Mystery** 揭示权重 / 机制；**Practice 与 Combat** 的风险 / 回报差异；**Finale** 区别于 Combat 的独立境界突破结算规则。→ `50-decisions/ADR-0002`、`20-systems/adventure-event/`、`20-systems/balance.md`。
- **location 机制细节：** 地域的枚举 / 层级、Travel 如何映射到具体 location、一个 location 开放哪些修行事件池、location 是否随篇章 / 境界变化——均尚未陈述。→ `20-systems/game-progression.md`。

### 元进程 / player-profile
- **元进程持久化字段结构：** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清、服务归属已定（profile-service）、**文档落位已定**（前三者成文件夹，后两者为独立 markdown），但**各自字段 schema 与解锁 / 获取 / 失去触发**待定；`status`（启用 / 禁用）与「拥有 / 失去」两态的存档表达未定。→ `20-systems/services/profile-service.md`、`20-systems/player-profile/`。
- **GameSetting 的设备本地项 vs 账号级项切分：** 画质 / 震动等设备强相关设置是否应留在本地 `user://` 而不上行云端。→ `20-systems/player-profile/game-setting.md`。
- **AccountInfo 字段 schema：** 账号 id / 绑定渠道 / 昵称头像 / 注册时间 / 封禁实名状态等未设计；多渠道绑定同一账号的模型未定。→ `20-systems/player-profile/account-info.md`。
- **AchievementManager 的触发采集面：** 成就进度靠订阅 EventBus 被动采集（解耦但易漏）还是各服务主动上报（可靠但反向依赖）？→ `20-systems/services/profile-service.md`。
- **capability flag 的叠加 / 冲突规则：** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 的**运算顺序**（加法先于乘法？声明序？优先级字段？）。→ `20-systems/player-profile/player-power/common-properties.md`。
- **PlayerPower 获取 / 失去触发与公平性：** 方向已定为**轻度提升、PvE-only 可容忍**；具体在哪些 AdventureEvent 获取 / 失去、是否影响 cycle seed / 计分公平仍待定。→ `20-systems/player-profile/player-power/`。

### adventure-event/combat / character-profile 资源（战斗细化 · 收窄）
- **mana 逐步恢复速率 / 上限成长：** 每回合恢复量、manaLimit 随境界成长、更高境界 life / mana 基线未定（炼气仅给 10/10 · 5/5）。→ `20-systems/character-profile/mana.md`、`life.md`、`20-systems/balance.md`。

### UX（screen-flow）
- **成就两档奖励内容：** 阈值（60% / 90%）、一次性、80/20 可见已定；仅剩**两档各发放何种奖励**待定。→ `40-ux/screen-flow.md`、`20-systems/player-profile/achievements/`。
- **元婴界面（通关证书）的具体形态（07-26 新增）：** 用途已定（读取并显示最终寿元）；展示哪些字段（最终寿元、用时、修行历程摘要、成就？）、何时弹出、能否回看 / 分享未定。→ `40-ux/screen-flow.md`。
- **寿元红字倒数的呈现细节（07-26 新增）：** 形态已定（<10% 转为显示，标红数值倒数，非常驻条）；仍待定：是逐格递减还是持续跳动、常驻哪些屏幕（选择区 / 战斗内 / 全局 HUD）、是否伴随音效 / 震动。→ `40-ux/screen-flow.md`、`40-ux/combat-ux.md`。

### 知识层 / 杂项
> 服务 API 契约的残留细节见上方「服务 API 契约」小节。知识层形态已定（`50-decisions/ADR-0005`：薄引用）。
- **`.claude/rules/*` 与本库的主从关系：** ADR-0005 只覆盖 `.claude/knowledge/*`，**未涉及 `.claude/rules/*`**。规则文件是本库主题文档的强制执行摘要，还是独立于本库的工程约束？二者冲突时以谁为准？→ `20-systems/common-properties.md`。
- **scoring.md 去向：** 是否并入某系统（战斗 / game-progression），或在 life+mana 模型下被废弃，待确认。→ `20-systems/scoring.md`。
- **enemies 归属：** 现归 `adventure-event/combat/`；若未来 Practice 等也用敌人，是否应升为共享内容层待确认。→ `20-systems/adventure-event/combat/`。

### 尚未设计（占位，暂无具体问题）
- 以下主题文档仍是空占位，尚无成形问题，待后续 handoff 播种：
  - 角色档案：`20-systems/character-profile/deck/`、`20-systems/character-profile/item/`。
  - 玩家档案：`20-systems/player-profile/player-item/`、`20-systems/player-profile/player-power/`、`20-systems/player-profile/achievements/`、`account-info.md`、`game-setting.md`（后三者 07-26 新建，仅有骨架）。
  - 战斗内容：`20-systems/adventure-event/combat/`、其余 AdventureEvent 子类型 `finale/ mystery/ practice/ exchange/ research/ explore/ social/ travel/`。
  - UX：`40-ux/combat-ux.md`。

## derive 就绪度

> **当前：全量回滚，本库尚未进入可 derive 的阶段。** 先前逐文档的 derive 就绪度判定（07-22 ~ 07-25）已**全部作废**——设计仍在快速演进，逐次 handoff 顺带下的就绪度结论会迅速过时且互相矛盾。
>
> **就绪度不再由 `/analyze-new-ideas` 顺带评估或更新。** 它由专门的 **`/assess-derive-readiness`** 全量扫描产出，**由用户在时机成熟时手动调用**；该技能是本小节的**唯一写入者**。在它跑过之前，本小节保持「尚未就绪」。

## 下一阶段
- **ADR 状态：** 已固化 **ADR-0002**（修行事件九类分类，九值枚举）、**ADR-0003**（强制在线 · 云端权威 · 重账号）、**ADR-0004**（境界存档 · 重试模型，含寿元归 0=defeated）、**ADR-0005**（`.claude/knowledge` 为薄引用层，含副本判据与 sync-knowledge 语义）。ADR 候选：**开发顺序**（07-27 定案：框架 → 内容 → 平衡与体验 → 社交及其他，见 `00-vision/scope.md`）；**内容载体形态**（随包基线 + overlay + 版本校验，见 `20-systems/services/content-service.md`）。（注：ADR 现可自由编辑，改决定直接改 ADR，不再新开取代 ADR。）
