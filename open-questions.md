# Open questions — 跨 session 待答清单

> 本文件是**客户端**（Godot 项目）的待答清单；后端侧的待答清单在 `backend-design-documents/open-questions.md`（`backend-design` 分支）。
>
> 每次 session 结束时，未答的 Open questions 汇总到此，供下次拾起；一旦答定，就从此处移除、归档进对应主题文档的 `## 待决问题` / `## 决策`，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。此文件**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；已答定问题的移出记录见 `answer-logs/`。最近更新：**2026-07-25c**（确立**两级层次 service ⊃ manager**；**拆分轴定案 = 生命周期层 + 行为边界，非数据类型**（否决按 power / item / card / resource 各开 collection 服务、否决按事件类型各开服务）；服务清单收敛为**七个**，新增 account-service / content-service / sync-service / profile-service / combat-service，**adventure-plot-service 降级为 PlotManager**；**内容三层管线**（`res://` 基线 + `user://overlay/` 热更 + 云端版本校验）与**本地 / 云端内容分界**定案；**两条唯一入口**（ContentRegistry 读内容、ProfileManager 写档案）+ **编排顶点 game-progression**；**术语修正：全库废弃「微服务」措辞**（service = 进程内模块单例，唯一真实进程边界是客户端 ↔ 后端）；新增两份根级总览 `program-overview.md`（运行时视角）+ `system-overview.md`（工程视角：进程边界 / 文件夹布局 / autoload 注册 / 代码形态 / 离线 stub 策略）；架构 8 处缺口闭合 6 处、1 处部分闭合。）｜ 前次 2026-07-25b（AdventureEvent 补入 `eventType` / `selectCost` / `skipCost` / `ifMandatory` + `eventStart` / `eventEnd`，隐含引入**「跳过事件」通道**；PlayerPower 补入 `status`（启用 / 禁用）；**隐藏剧本层隶属于 future-event-service**（07-25c 进一步降级为其内部的 **PlotManager**）；元婴 lifeSpan +500（无玩法影响）；两项**提案待确认**：展示字段三层切分、capability flag + modifier pipeline；一次**架构闭环体检**列出 8 处缺口；`selectCost` 确认为**定制复合成本类型**、`lifeSpanCost` 为其 element；两项提案**均获采纳**；**derive 就绪度全量回滚**，改由 `/assess-derive-readiness` 手动评估。）｜ 前次 2026-07-25（寿元数值化：计数器模型 100 / +100 / +300、隐藏→<10% 显示、按 AdventureEvent 的 `lifeSpanCost`（基准 -1）扣减→0=defeated；服务层重命名 run-manager→**life-cycle-service**、adventure-plot→**adventure-plot-service**，新增 **future-event-service**（产出 eventOptions）；character-profile 结构定案；ADR 重构为九类 + 治理约定改为「一切皆可改：取消仅追加 / ADR 不可变」，全库遗留清理。）

## 待答（按主题）

### ⚠ 服务 API 契约（07-25c · 结构已定，契约待写 · 优先）
- **七个服务与其 manager 的职责边界已定，但具体 API 面未定义。** 方法签名、参数 / 返回类型、事件负载 schema 仍是意图草图。这是当前最大的结构性空白。→ `20-systems/architecture.md`、`20-systems/services/*`。
- **`player-profile/` 子系统范围仍待确认。** 服务归属已定（profile-service），但除 player-item / player-power 外是否还有 achievements / account-info / game-setting 各自成文件夹待确认。→ `20-systems/player-profile/`。

### 内容管线 / 热更（07-25c · 新增）
- **热更范围边界。** overlay 可覆盖哪些字段？允许热更**新增 `Id`**（新卡 / 新事件）还是仅改既有条目的数值 / 文案？新增 `Id` 会让旧版本客户端的存档引用到未知内容，需一条兼容规则。→ `20-systems/services/content-service.md`。
- **overlay 与存档的版本耦合（确定性张力）。** run 进行中 overlay 被更新时，是否需**冻结该 run 的 `contentVersion`** 以保证 seed 可复现？「同一 seed 复现同一 run」与热更存在张力。→ `20-systems/services/content-service.md`、`20-systems/common-properties.md`。
- **增量下载的粒度与失败恢复；overlay 防篡改。** 逐文件 hash vs 整包版本、断点续传 / 回滚（避免半套 overlay）、`user://` 可被玩家改写是否需签名校验。→ 同上。
- **断线降级的具体行为。** push / pull / 剧本请求失败时：阻塞玩家、本地缓冲重试、还是回退存档点？缓冲上限与超时未定。→ `20-systems/services/sync-service.md`、`account-service.md`、`plot-manager.md`。
- **RNG 状态的持久化形态。** 具名子流的状态如何编码进存档 schema 未定。→ `20-systems/services/sync-service.md`、`life-cycle-service.md`。
- **自动存档点频率。** 每个 AdventureEvent 后 push 是否过频（移动网络 / 电量），是否需合并窗口。→ `20-systems/services/sync-service.md`。

### AdventureEvent 新字段 / 跳过通道（07-25b）
- **成本类型的 element 清单：** `selectCost` 为定制复合成本类型、`lifeSpanCost` 为其一个 element 已定；其余 element（gold / mana / 道具 / 隐藏属性推拉？）、各 element 的数据形态（固定值 / 区间 / 公式）、付不起某个 element 时的判定（整体不可选？部分抵扣？）未定。→ `20-systems/adventure-event/common-properties.md`、`20-systems/character-profile/currency.md`、`20-systems/balance.md`。
- **跳过是否也扣 `lifeSpanCost` element：** 结构上可以（`skipCost` 与 `selectCost` 同类型已定），但「跳过时时间是否照样流逝」属玩法取向，未定。→ `20-systems/adventure-event/common-properties.md`。
- **跳过机制的完整语义：** 付 `skipCost` 后是移除该项还是整批刷新？是否计入修行历程 / `pastEvent`？能否整批全跳？是否照扣 `lifeSpanCost`（时间照样流逝？）？付不起时如何表现？→ `20-systems/adventure-event/common-properties.md`、`20-systems/services/future-event-service.md`。
- **`ifMandatory` 由谁置位：** 内容作者在 `.tres` 写死，还是服务在产出 eventOptions 时动态置位（剧情线关键节点强制）？一批能否全部 mandatory？→ `20-systems/services/future-event-service.md`。
- **`eventStart` / `eventEnd` 与 `AdvanceEvent` 的职责边界：** 谁写 CharacterProfile、谁扣成本、谁推拉隐藏属性、谁触发重算；签名与返回形态未定。→ `20-systems/adventure-event/common-properties.md`、`20-systems/services/life-cycle-service.md`。

### 架构闭环缺口（07-25c 更新：8 处闭合 6 处、1 处部分闭合）
- 缺口 1（PlayerProfile 无服务）/ 2（战斗）/ 3（存档同步）/ 4（内容分界）/ 6（成本重叠）/ 7（编排顶点）/ 8（UI 契约层）**均已闭合**——移出记录见 `answer-logs/log-0725c.md`。
- **缺口 5 仅部分闭合：** skip 的 **API 归属已定**（`AdvanceEvent` 的 `mode = Skip`），**玩法语义仍未定**（见下「AdventureEvent 新字段 / 跳过通道」）。
- 状态表见 `20-systems/architecture.md` 的「闭环缺口」小节。

### 隐藏属性 / 寿元（07-25）
- **寿元 `lifeSpanCost` 分档 / 增长途径：** 消耗机制已定（按 AdventureEvent 的 `lifeSpanCost` 扣减，基准 -1）；预算阶梯已闭合（100 / +100 / +300 / +500）。仍待定：哪些事件类型 / 具体事件应覆写基准（更大 / 更小 / 回寿）、是否有非境界突破的寿元增长途径。→ `20-systems/adventure-event/`、`20-systems/balance.md`。
- **元婴 +500 的用途：** 既已确认无玩法影响，最终寿元值是否被终局结算 / 成就 / 排行读取？若否，是否值得保留该字段更新？→ `20-systems/balance.md`、`40-ux/screen-flow.md`。
- **寿元 <10% 显示的 UX 形态：** 低于 10% 时「在屏上显示」的具体呈现（常驻条？告警？）未定。→ `40-ux/`（combat-ux / screen-flow）。
- **隐藏属性清单与阈值：** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏；仍待定：是否还有其他隐藏属性、各自阈值、增减触发（哪些 AdventureEvent 推拉）、剧情线目录。→ `20-systems/services/plot-manager.md`、`20-systems/services/life-cycle-service.md`。

### future-event-service / eventOptions（07-25）
- **eventOptions 生成 / 加权规则：** 服务化架构已定，但从 CharacterProfile **生成 / 加权抽取**下一批 eventOptions 的具体规则（月圆之夜式策划 vs 随机权重、每批数量、node 类型配比、带种子 RNG 派生）、以及 location 框定 / AdventurePlot 调制 / seeded RNG 的**叠加顺序**未定。→ `20-systems/services/future-event-service.md`、`20-systems/game-progression.md`。
- **eventOptions 与 possibleFutureEvent 图的关系：** 服务产出 eventOptions 后，`AdventureEvent` 上原 `List<possibleFutureEvent>` / `List<pastEvent>` 图字段是保留（服务读写它）还是被服务态取代？两者关系待厘清。→ `20-systems/services/future-event-service.md`、`20-systems/adventure-event/common-properties.md`。

### AdventurePlot 数据编码 / 剧本服务（层级已定，细节待定）
- **AdventurePlot 数据编码与剧本服务契约：** 四级结构与「Character 只存 key points、内容在剧本服务」已定；仍待定：树的数据表达（**调制** eventOptions 还是并行结构）、key points 粒度 / schema、剧本服务请求 / 下发 / 缓存 / 离线降级协议、DnD 式选分支触发点与 UI。→ `20-systems/services/plot-manager.md`。

### AdventureEvent 分类法（结构已定，逐类型机制待定）
- **各类型的结算 / 机制细化：** 九类分类法已定（`50-decisions/ADR-0002` 九值枚举），但各类型的具体玩法机制仍待设计（ADR-0002「Consequences / 待办」）：**Mystery** 揭示权重 / 机制；**Practice 与 Combat** 的风险 / 回报差异；**Finale** 区别于 Combat 的独立境界突破结算规则。→ `50-decisions/ADR-0002`、`20-systems/adventure-event/`、`20-systems/balance.md`。
- **location 机制细节：** 地域的枚举 / 层级、Travel 如何映射到具体 location、一个 location 开放哪些修行事件池、location 是否随篇章 / 境界变化——均尚未陈述。→ `20-systems/game-progression.md`。

### 元进程 / player-profile
- **元进程持久化字段结构：** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清、服务归属已定（profile-service），但**各自字段 schema 与解锁 / 获取 / 失去触发**待定；`status`（启用 / 禁用）与「拥有 / 失去」两态的存档表达未定。→ `20-systems/services/profile-service.md`、`20-systems/player-profile/`。
- **AchievementManager 的触发采集面：** 成就进度靠订阅 EventBus 被动采集（解耦但易漏）还是各服务主动上报（可靠但反向依赖）？→ `20-systems/services/profile-service.md`。
- **capability flag 的叠加 / 冲突规则：** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 的**运算顺序**（加法先于乘法？声明序？优先级字段？）。→ `20-systems/player-profile/player-power/common-properties.md`。
- **player-profile 子系统范围：** 除 player-item / player-power 外是否还有 achievements / account-info / game-setting 等子系统各自成文件夹待确认。→ `20-systems/player-profile/`。
- **PlayerPower 获取 / 失去触发与公平性：** 方向已定为**轻度提升、PvE-only 可容忍**；具体在哪些 AdventureEvent 获取 / 失去、是否影响 run seed / 计分公平仍待定。→ `20-systems/player-profile/player-power/`。

### adventure-event/combat / character-profile 资源（战斗细化 · 收窄）
- **mana 逐步恢复速率 / 上限成长：** 每回合恢复量、manaLimit 随境界成长、更高境界 life / mana 基线未定（炼气仅给 10/10 · 5/5）。→ `20-systems/character-profile/mana.md`、`life.md`、`20-systems/balance.md`。

### UX（screen-flow）
- **成就两档奖励内容：** 阈值（60% / 90%）、一次性、80/20 可见已定；仅剩**两档各发放何种奖励**待定。→ `40-ux/screen-flow.md`。

### 知识层 / 杂项
> 服务 API 契约见上方「⚠ 服务 API 契约」优先条目。
- **`.claude/knowledge` 引用层改造形态（ADR 候选）：** 逐文件替换为薄引用还是保留提炼摘要 + 回链？影响 sync-knowledge 语义——建议以 ADR 固化。→ `20-systems/architecture.md`。
- **scoring.md 去向：** 是否并入某系统（战斗 / game-progression），或在 life+mana 模型下被废弃，待确认。→ `20-systems/scoring.md`。
- **enemies 归属：** 现归 `adventure-event/combat/`；若未来 Practice 等也用敌人，是否应升为共享内容层待确认。→ `20-systems/adventure-event/combat/`。

### 尚未设计（占位，暂无具体问题）
- 以下主题文档仍是空占位，尚无成形问题，待后续 handoff 播种：
  - 角色档案：`20-systems/character-profile/deck/`、`20-systems/character-profile/item/`。
  - 玩家档案：`20-systems/player-profile/player-item/`、`20-systems/player-profile/player-power/`。
  - 战斗内容：`20-systems/adventure-event/combat/`、其余 AdventureEvent 子类型 `finale/ mystery/ practice/ exchange/ research/ explore/ social/ travel/`。
  - UX：`40-ux/combat-ux.md`。

## derive 就绪度

> **当前：全量回滚，本库尚未进入可 derive 的阶段。** 先前逐文档的 derive 就绪度判定（07-22 ~ 07-25）已**全部作废**——设计仍在快速演进，逐次 handoff 顺带下的就绪度结论会迅速过时且互相矛盾。
>
> **就绪度不再由 `/analyze-new-ideas` 顺带评估或更新。** 它由专门的 **`/assess-derive-readiness`** 全量扫描产出，**由用户在时机成熟时手动调用**；该技能是本小节的**唯一写入者**。在它跑过之前，本小节保持「尚未就绪」。

## 下一阶段
- **ADR 状态：** 已固化 **ADR-0002**（修行事件九类分类，九值枚举）、**ADR-0003**（强制在线 · 云端权威 · 重账号）、**ADR-0004**（境界存档 · 重试模型，含寿元归 0=defeated）。ADR 候选：**开发顺序**；**`.claude/knowledge` 引用层形态**。（注：ADR 现可自由编辑，改决定直接改 ADR，不再新开取代 ADR。）
