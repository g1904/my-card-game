# Open questions — 跨 session 待答清单

> 每次 session 结束时，未答的 Open questions 汇总到此，供下次拾起；一旦答定，就从此处移除并归档进对应主题文档的 `## 待决问题` / `## 决策`。此文件是导航 / 拾取清单，**权威归属在各主题文档**。最近更新：2026-07-23（`/summarize-open-questions AdventureEvent details`：归档单复数命名已答定；显式补入 AdventureEvent 分类法各类型机制与 possibleFutureEvent 图编码两组细节待答）。

## 已解决（历史移出）
- ~~在线存档是否纳入 MVP~~ → **已定并再次修订**：先定「离线 + 云同步混合模型」（07-16），**07-22 推翻为「强制在线 · 云端权威」**（`00-vision/scope.md`；ADR 候选）。
- ~~本地↔云端同步冲突解决~~ → **已定**：一切以云端为准（`00-vision/scope.md`、`20-systems/run-manager.md`）。
- ~~开发顺序~~ → **已定**：改良版——设计先行 + 垂直切片端到端 + 贯穿式占位数据轻量平衡 + 美术挂点末段替换（`00-vision/scope.md`；ADR 候选）。
- ~~篇章继承什么~~ → **已定**：**全部继承**上一篇章信息（`20-systems/run-manager.md`、`map-progression.md`）。**解锁了 run-manager / map-progression 的 derive。**
- ~~CharacterProfile 状态机（discarded vs defeated）~~ → **已定**：合并为单一终态 `defeated`，`discarded` 降为其原因子类型；`status = ongoing | defeated | completed`（`run-manager.md`）。
- ~~「每篇章至多一个 ongoing」精确语义~~ → **已确认**：该篇章有 ongoing 角色时不能用其他角色玩该篇章；不同篇章可并行（`run-manager.md`）。
- ~~篇章解锁触发条件~~ → **已定**：通关上一篇章即成为下一篇章可挑战角色；无可挑战角色则该篇章重新锁定（`40-ux/onboarding.md`、`run-manager.md`）。
- ~~战斗模型~~ → **已定**：**life + mana**（参考 MTG / Hearthstone）（`20-systems/adventure-event-combat.md`、`energy-economy.md`）。**解锁了 adventure-event-combat 的核心阻塞。**
- ~~节点 map 形态~~ → **已定**：月圆之夜风格（精心策划的事件菜单，非 StS 完全分支）（`map-progression.md`）。
- ~~成就自动发放：按数量还是加权~~ → **已定**：**组内加权进度**（`40-ux/screen-flow.md`）。
- ~~登录屏循环视频技术实现~~ → **已定**：`VideoStreamPlayer`（`40-ux/screen-flow.md`）。
- ~~篇章总数 / 重试上限矛盾~~ → **已定**：**四境三篇章**；重试上限 ch1=无限、ch2=3、ch3=1（草稿「第四章」为笔误）（`run-manager.md`、`map-progression.md`）。
- ~~强制在线是否连带改根约定~~ → **已定**：授权更改。`.claude/CLAUDE.md`、`state-save-rules.md` 及知识笔记已改为「强制在线 · 云端权威」，并确立**治理原则**：任何决策（含根约定）都可被后续更权威的用户意图推翻重构（`Context.md` 约定首条）。
- ~~强制在线 vs 移动手感张力~~ → **已定（07-23）**：允许**短暂断线缓冲、恢复后同步**，仍以云端为最终权威（`00-vision/scope.md`）。
- ~~游客态在强制在线下的语义 / 游客→登录迁移~~ → **已定（07-23）**：**彻底移除游客态**，强制账号登录，不存在游客迁移（`00-vision/scope.md`、`40-ux/screen-flow.md`、`40-ux/onboarding.md`、`run-manager.md`）。
- ~~节点选择界面 UI~~ → **已定（07-23）**：**可横向滑动的选择区**（滑动选中目标 AdventureEvent）（`20-systems/map-progression.md`）。
- ~~mana 曲线~~ → **已定（07-23）**：**无曲线**，采用「上限 + 逐步恢复」；炼气基线 life=10/10、mana=5/5（`20-systems/energy-economy.md`、`adventure-event-combat.md`、`30-content/balance.md`）。
- ~~境界突破复用 Combat 还是独立 / 是否入枚举~~ → **已完全定案（07-23）**：**`AdventureEvent-Finale` 作为第七类并入 ADR-0002 枚举**，独立于 Combat（已就地修订 `50-decisions/ADR-0002`）。
- ~~成就自动发放阈值 / 一次性 / 可见比例~~ → **已定（07-23）**：**60% / 90% 两档一次性奖励（两档不同）**；目录 **80% 可见、20% 隐藏**（`40-ux/screen-flow.md`）。仅剩「两档各发放何种奖励」未定（见下）。
- ~~faith 归可见还是隐藏~~ → **已定（07-23）**：`faith` = **道心，隐藏数值属性**（`terminology.md`、`run-manager.md`、`adventure-plot.md`）。
- ~~后端 / 账号系统路线~~ → **已定（07-23）**：**重账号**（为云端同步存档，参考三国杀 Online）；已固化 `50-decisions/ADR-0003`。**仅剩合规实现落地**（见下）。
- ~~AdventurePlot 层级结构 / 内容存放~~ → **已定（07-23）**：四级 **Story > Chapter >（SideChapter / SideStory）**；Character 只存 **key points**，完整剧本存云端**剧本服务**（`20-systems/adventure-plot.md`）。**仅剩数据编码 / 服务契约**（见下）。
- ~~强制在线 · 云端权威 / 境界存档 · 重试是否固化 ADR~~ → **已固化（07-23）**：`ADR-0003`（强制在线 · 云端权威 · 重账号）、`ADR-0004`（境界存档 · 篇章重试模型）。
- ~~「修行事件」单复数语义（单节点是否另用一词）~~ → **已定**：**`修行事件` = AdventureEvent（单个节点）**、**`修行历程` = `List<AdventureEvent>`（整段旅程 / 集合）**，两词已在术语表分列（`terminology.md` 核心结构表）。回答了 `10-handoffs/2026-07-15-adventure-event-profiles.md` 的命名 Open question。

## 待答（按主题）

### 强制在线 · 后端（路线已定，仅剩合规落地）
- **后端 / 账号系统合规落地**（PIPL、实名、防沉迷、渠道审核、账号注销 / 数据导出）——路线已定为**重账号**（`ADR-0003`，参考三国杀 Online）；**删除游客态后强制实名 / 登录，合规门槛进一步抬高**。仅剩具体选型与合规实现。→ `ADR-0003`、`run-manager.md`。

### AdventureEvent 分类法与图编码（结构已定，逐类型机制待定）
- **各类型的结算 / 机制细化：** 七类分类法（修炼 / 战斗 / 闭关 / 交易 / 社交 / 未知 / 境界突破）已定案（`ADR-0002`），但各类型的具体玩法机制仍待设计（ADR-0002「Consequences / 待办」）：**Mystery** 进入时映射到其余类的**揭示权重 / 机制**；**Practice 与 Combat** 的**风险 / 回报差异**（Practice = 低风险比试）；**Finale** 区别于 Combat 的**独立境界突破结算规则**（渡劫 / 存档转场形态）。→ `50-decisions/ADR-0002`、`20-systems/adventure-event-combat.md`、未来的 `30-content/adventure-events.md` / `30-content/balance.md`。
- **possibleFutureEvent 图的生成与呈现：** `AdventureEvent` 持 `List<possibleFutureEvent>` / `List<pastEvent>` 的图编码已定（向前 DAG、向后面包屑），选择 UI 已定为**横向滑动选择区**、形态为**月圆之夜式策划菜单**；仍待定：**从当前可用项如何生成 / 加权抽取**下一批 possibleFutureEvent（月圆之夜「事件菜单」的策划 vs 随机权重、带种子 RNG 派生）、节点类型路径导航规则。→ `20-systems/map-progression.md`。（注：AdventurePlot 如何**调制**这张图，见下一小节，勿重复。）

### AdventurePlot / 隐藏属性（07-23，层级已定，细节待定）
- **AdventurePlot 数据编码与剧本服务契约：** 四级结构（Story / Chapter / SideChapter / SideStory）与「Character 只存 key points、内容在剧本服务」已定；仍待定：树的数据表达（**调制** `possibleFutureEvent` 图还是并行结构）、key points 粒度 / schema、剧本服务请求 / 下发 / 缓存 / 离线降级协议、DnD 式选分支触发点与 UI。→ `20-systems/adventure-plot.md`。
- **隐藏属性清单与阈值：** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏；仍待定：是否还有其他隐藏属性、各自阈值、增减触发（哪些 AdventureEvent 推拉）、剧情线目录。→ `20-systems/adventure-plot.md`、`20-systems/run-manager.md`、`30-content/events.md`。
- **寿元 / lifeSpan：** 是否有上限、如何增长、「大限将至」触发后果（defeated？转入 Finale？）待定。→ `20-systems/adventure-plot.md`、`30-content/events.md`。

### run-manager / 元进程
- **元进程持久化字段结构：** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清，但各自字段与解锁 / 获取 / 失去触发待定；账号级 meta 或值得单独系统文档。→ `run-manager.md`。
- **PlayerPower 获取 / 失去触发与公平性：** 方向已定为**轻度提升、PvE-only 可容忍**；但具体在哪些 AdventureEvent 获取 / 失去、是否影响 run seed / 计分公平仍待定。→ `run-manager.md`、`40-ux/screen-flow.md`。

### adventure-event-combat / energy-economy（战斗细化 · 收窄）
- **mana 逐步恢复速率 / 上限成长：** 每回合恢复量（固定 +N？按比例？）、manaLimit 随境界成长、更高境界 life / mana 基线未定（炼气仅给 10/10 · 5/5）。→ `20-systems/energy-economy.md`、`30-content/balance.md`。

### UX（screen-flow）
- **成就两档奖励内容：** 阈值（60% / 90%）、一次性、80/20 可见已定；仅剩**两档各发放何种奖励**（PlayerPower / PlayerItem / 账号级）待定。→ `40-ux/screen-flow.md`。

### 尚未设计（占位，暂无具体问题）
- 以下主题文档仍是空占位，尚无成形问题，待后续 handoff 播种：
  - 系统：`deck-hand`、`card-resolution`、`scoring`、`shop-rewards`、`relics-jokers`。
  - 内容：`cards`、`relics`、`enemies`、`adventure-events`、`blinds-antes`（`events` 已有 AdventurePlot 内容；`balance` 已有炼气基线）。
  - UX：`combat-ux`。

## 下一阶段
- **derive 就绪度：`map-progression` / `run-manager` 已足够详尽，可 derive。** 「篇章继承」「篇章总数 / 重试上限」「状态机」「篇章解锁」均已定案；本轮再补「横向滑动选择界面」（map-progression）。`map-progression` 唯一残余项 AdventurePlot 是**加性上层调制**，不阻塞核心 progression → 可 `/derive-requirements 20-systems/map-progression.md`。`run-manager` 核心（两层持有 / 状态机 / 重试 / 篇章解锁）亦可 derive；隐藏属性 / AdventurePlot 字段可后补。
- **`adventure-event-combat` 收窄但仍暂缓 derive：** life + mana、无曲线 · 上限 + 逐步恢复、炼气基线、七类分类法（含 Finale）均已定；仅剩恢复速率 / 更高境界基线（平衡数值）与**逐类型机制**（Mystery 揭示权重、Practice vs Combat 风险回报、Finale 独立结算规则）——均属内容 / 平衡设计而非结构，核心战斗结构已足够，若接受占位数值 / 机制亦可尝试 derive。
- **AdventureEvent 图编码不阻塞 `map-progression` derive：** possibleFutureEvent 生成 / 加权与节点路径导航是**内容级策划细节**（可占位实现），图结构骨架（前向 DAG / 后向面包屑、横向滑动选择）已足够 derive。
- **`adventure-plot`（新）：** 层级 + 剧本服务方向已定，但数据编码 / 服务契约 / 隐藏属性阈值待细化——暂缓 derive。
- **ADR 状态：** 已固化 **ADR-0003**（强制在线 · 云端权威 · 重账号）、**ADR-0004**（境界存档 · 重试模型）；**ADR-0002 已修订**为七类。仅 **开发顺序** 仍为可选 ADR 候选。
