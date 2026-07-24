# AdventurePlot / 隐藏属性 + 一批玩法澄清

- id: 2026-07-23-adventure-plot-hidden-stats-and-clarifications
- date: 2026-07-23
- topic: 承接并裁定多份既有 Open questions（断线缓冲、游客态、属性模型、成就细化、境界突破、选择界面、mana 模型），并引入新抽象 **AdventurePlot（隐藏剧情线）** 与**隐藏属性模型**；feeds terminology、scope、screen-flow、onboarding、run-manager、encounter-combat、energy-economy、map-progression、events、balance
- status: distilled
- distilled-to: terminology.md, 00-vision/scope.md, 00-vision/pillars.md, 00-vision/references.md, 40-ux/screen-flow.md, 40-ux/onboarding.md, 20-systems/run-manager.md, 20-systems/adventure-event-combat.md, 20-systems/energy-economy.md, 20-systems/map-progression.md, 20-systems/adventure-plot.md, 30-content/events.md, 30-content/balance.md, 30-content/adventure-events.md, 50-decisions/ADR-0002-adventure-event-taxonomy.md, 50-decisions/ADR-0003-online-cloud-authority.md, 50-decisions/ADR-0004-realm-checkpoint-retry-model.md

## Intent（你的原话，已提炼）

一批集中裁定 + 一个重要新抽象。既回答了 `2026-07-22` 遗留的多份 Open questions，也首次提出 **AdventurePlot（隐藏剧情线）** 这一贯穿背景的叙事驱动层。

### 1. 强制在线 vs「移动优先、随时可玩」张力（**回答既有 Open question**）
- **裁定：允许短暂断线缓冲，联网后再同步；仍以云端为最终权威。** 即「必须在线」不是逐帧硬性——短暂掉线可缓冲本地操作、恢复网络后回传，冲突仍以云端为准。这缓解了移动端「随时可玩」与强制在线之间的张力。

### 2. 删除游客态，强制登录账号（**回答既有 Open question · 取代先前「游客」入口**）
- **移除游客（Guest）入口：所有玩家必须登录账号后才能游玩。**
- **取代**先前 `scope.md` / `screen-flow.md` / 平台优先级中出现的「游客登录 / Guest」条目，以及 `2026-07-22` 遗留的「游客态在强制在线下的语义」这一 Open question（现由**彻底移除游客态**来回答）。
- 登录渠道优先级相应收敛为：**手机 / 邮箱**（移动端优先）→ **微信 / QQ** 其次 → **海外 / 跨平台**最后。（原「手机 / 邮箱 / **游客**」去掉游客。）

### 3. 后端 / 账号系统选型与合规（**求助 · 仍为 Open question**）
- 请求：**后端 / 账号系统选型、合规**的行业标准参考。以 **Balatro / Slay the Spire / 三国杀 Online / 月圆之夜** 等游戏为例，它们各自作了什么选择？
- 仍未拍板；为待答项，附调研结论供参考（见 Open questions）。

### 4. PlayerPower 定位为「轻度提升」（**细化既有 Open question**）
- **PlayerPower 提供轻度增益（light improvement）。** 承认它会影响平衡，但因为**本作无 PvP、纯 PvE**，让 PlayerPower 带来一定强度是**可容忍的**，并且**打开了更大的设计空间**去设计有趣的 power。
- 这为「PlayerPower 平衡边界」Open question 定了**方向**：轻度、PvE-only 语境下可接受；但具体获取 / 失去触发、是否影响 seed / 计分仍待细化。

### 5. AdventurePlot（隐藏剧情线）与隐藏属性模型（**新抽象 · 部分回答「属性模型」Open question**）
- **属性模型改为隐藏。** 借鉴 **Reigns** 的属性模型，但与 Reigns 不同：Reigns 让属性**可见**、成为玩家主要关注的仪表；**本作让这些属性隐藏**，在背后影响 AdventureEvent。
- **新抽象 AdventurePlot（修行剧情 / 隐藏剧情线）：** 一棵由不同分支可能性构成的**树**，影响角色的 `possibleFutureEvent`（未来可能出现的修行事件）。它像一条在背景中运行的**隐藏故事线**；也可像 **DnD** 那样，在某些节点**让玩家选择要走哪条分支**。
- **隐藏属性驱动剧情线（示例）：**
  - **煞气点数（malefic qi）** 作为隐藏属性——积累到一定阈值会触发**「煞气反噬」**故事线。
  - **寿元（lifeSpan）**——注意**不是生命 / life（血量）**，而是一个隐藏的**寿命数值**；增长到一定值会触发**「大限将至」**故事线。

### 6. 成就发放细化（**回答既有 Open question**）
- **每个类别的成就按加权进度分两档一次性奖励：** 加权进度达 **60%** 发放一次奖励；达 **90%** 再发放一次奖励；**两档奖励不同，且都为一次性。**
- **每个类别的成就目录：80% 条目可见，20% 为隐藏成就**，达成后才显示。

### 7. Combat 是 AdventureEvent 的子类型（**命名细化**）
- 把 **encounter-combat 概念重命名为 AdventureEvent-Combat**：**Combat 是 AdventureEvent 的一个子类型**（与 ADR-0002 六类分类法一致——Combat 本就是其中一类）。此条把「combat 从属于 AdventureEvent」这一关系在命名上显式化。

### 8. 境界突破 = AdventureEvent-Finale（**回答既有 Open question**）
- **境界突破**定义为 **AdventureEvent-Finale**，**区别于 Combat**。这回答了 `adventure-event-combat` 中「境界突破复用 Combat 还是独立」的 Open question：**独立类型 Finale，而非 Combat**。

### 9. 选择界面 = 横向滑动选择区（**回答既有 Open question**）
- **选择界面用一个可横向滑动（horizontal scrolling area）的选择区**，玩家滑动以选中要继续的目标 AdventureEvent。这回答了「从可用修行事件中选择」的 UI 呈现方式（此前只定了「月圆之夜风格」的形态，未定具体交互）。

### 10. 无 mana 曲线；上限 + 逐步恢复；炼气基线（**回答既有 Open question**）
- **没有 mana curve 的概念。** 不采用 Hearthstone 式每回合 +1 上限、也不采用 MTG 式打地的**递增曲线**；改为**「上限 + 逐步恢复」**模型：mana 有一个上限，每回合逐步恢复（而非按曲线爬升）。
- **炼气期标准基线（起始满值）：** 生命 **life = 10 / 10**，法力 **mana = 5 / 5**。

## Open questions

- **AdventurePlot 的编码与授权方式（新，未定）。** 「一棵分支可能性的树，影响 possibleFutureEvent」如何用数据表达？它与 `map-progression` 已定的 `AdventureEvent.possibleFutureEvent` 图编码如何耦合——AdventurePlot 是**改写 / 加权** possibleFutureEvent 的上层调制器，还是另一套并行结构？DnD 式「让玩家选分支」在何处、以何 UI 触发？
- **隐藏属性的清单与阈值（新，未定）。** 除 煞气、寿元 外还有哪些隐藏属性？各自阈值、增减触发（哪些 AdventureEvent 推拉它们）、以及触发的故事线目录未定。既有 `faith`（信仰，先前定为「即时属性 · 类 Reigns 平衡」）现在也应归入**隐藏**属性吗？还是 faith 可见、另一批隐藏？需澄清 faith 与新隐藏属性的关系。
- **寿元 / lifeSpan 与 life 的边界（新，需确认）。** 明确 寿元 是独立于血量 life 的隐藏数值；但它是否有上限、如何随 run 推进增长、「大限将至」触发后果（角色 defeated？转入 Finale？）未定。
- **境界突破 Finale 是否扩展 ADR-0002 的六类枚举（需确认）。** `AdventureEvent-Finale` 是作为**第七类**加入分类法枚举，还是**独立于六类之外**的篇章边界特殊转场（此前倾向「独立于分类法的存档转场」）？ADR-0002 已 Accepted，若新增类型需一份**取代 / 修订 ADR**。→ **ADR 候选。**
- **mana 逐步恢复的具体速率（未定）。** 「每回合逐步恢复」的**恢复量 / 恢复规则**（固定 +N？按上限比例？）、manaLimit 随境界的成长曲线、以及更高境界（筑基 / 金丹 / 元婴）的 life / mana 基线未给出——炼气仅给了 10/10 与 5/5。
- **成就奖励的具体内容（部分仍开）。** 阈值（60% / 90%）、一次性、80/20 可见比例已定；但**60% 与 90% 两档各发放何种奖励**（PlayerPower / PlayerItem / 账号级？）仍待定。
- **PlayerPower 获取 / 失去触发与公平性（沿用，未闭合）。** 方向已定为「轻度、PvE-only 可容忍」；但具体在哪些 AdventureEvent 获取 / 失去、是否影响 run seed / 计分公平仍待定。
- **后端 / 账号系统选型与合规（沿用，未定）。** 见第 3 条；PIPL / 实名 / 渠道审核 / 账号注销 / 数据导出。删除游客态后**强制实名 / 登录**进一步抬高合规门槛。

## Notes / triage

承接式批量裁定 + 一个新抽象。路由：
- 断线缓冲、删除游客态 → `00-vision/scope.md`（平台约束 · 登录渠道去游客）、`40-ux/screen-flow.md`（登录入口去 Guest）、`40-ux/onboarding.md`、`20-systems/run-manager.md`（账号 / 同步维度）。
- PlayerPower 轻度提升 → `20-systems/run-manager.md`、`40-ux/screen-flow.md`。
- AdventurePlot + 隐藏属性（煞气 / 寿元）→ `30-content/events.md`（隐藏剧情线 / 分支）、`20-systems/run-manager.md`（隐藏属性归入 `Status`）、`terminology.md`（新术语）。
- 成就 60% / 90% 双档一次性、80/20 可见 → `40-ux/screen-flow.md`。
- Combat 子类型命名、Finale 独立类型 → `20-systems/adventure-event-combat.md`、`terminology.md`；**ADR 候选**（Finale 是否入六类枚举 → 需修订 ADR-0002）。
- 横向滑动选择区 → `20-systems/map-progression.md`（选择 UI）。
- 无 mana 曲线 · 上限 + 逐步恢复 · 炼气基线 10/10 · 5/5 → `20-systems/energy-economy.md`、`20-systems/adventure-event-combat.md`、`30-content/balance.md`。
- **文件 / 代码重命名（triage 任务，待确认）：** 第 7 条要把「encounter-combat」概念更名为「AdventureEvent-Combat」。设计文档 / 知识笔记 / 代码中残留的 `encounter` → `AdventureEvent` 重构此前已多次重申；本次进一步涉及 `encounter-combat.md` 文档名本身。文档 / 知识文件改名会级联影响交叉引用与 `.claude/knowledge/systems/` 的一一对应，故先保留文件名、在正文显式化「Combat = AdventureEvent 子类型」，机械改名留作后续统一处理 / 确认。
  - **[更新 2026-07-24]** 上述「先保留文件名」已被后续用户指示取代:`encounter-combat.md` → `adventure-event-combat.md`、`encounters.md` → `adventure-events.md` 已执行改名,全库(含本历史 handoff)路径引用同步更新。

## 更新（同 session 用户裁定，2026-07-23）

用户就上文 Open questions 逐条拍板，并追加新结构。已按此重新提炼：

1. **Finale 纳入 ADR-0002 作为第七枚举（定案）。** 分类法由六类 → **七类**：修炼 / 战斗 / 闭关 / 交易 / 社交 / 未知 + **境界突破 Finale**（独立于 Combat）。已**就地修订 ADR-0002**（依 `Context.md` 治理原则允许，附「修订历史」溯源），并更新 `terminology.md`、`adventure-event-combat.md`。
2. **`faith` = 道心，隐藏数值属性（定案）。** 原「信仰 / 即时属性」归为**隐藏属性 道心**，与 煞气 / 寿元 同列——回答了「faith 归可见还是隐藏」。→ `terminology.md`、`run-manager.md`、`adventure-plot.md`。
3. **AdventurePlot 是剧本体系，四级结构（定案 + 充实）。** **Story**（贯穿三大篇章的主线）> **Chapter**（单篇章剧本，三个相连成 Story）> 篇章内穿插 **SideChapter** / 跨篇章穿插 **SideStory**。**Character 只记录 key points**；**完整剧本与分支内容存于云端剧本服务（script service）**，按 key points 请求。→ **新建 `20-systems/adventure-plot.md`**；`terminology.md`、`events.md`、`run-manager.md`、`map-progression.md`。
4. **后端 / 账号 = 重账号（定案，参考三国杀 Online）。** 为支撑云端同步存档采用**重账号**路线。→ `00-vision/scope.md`、`ADR-0003`。
5. **encounter 术语全库覆写（执行）。** 把**全部设计活文档**中的 `encounter` 覆写为 `AdventureEvent`（唯一术语）。**历史 handoff 作为不可变时间线保留原文**；代码 / 知识笔记的 `encounter` / `EncounterData` 改名留待 blueprint / implement 与 `/sync-knowledge`。文档文件名 `encounter-combat.md` / `encounters.md` **暂不改名**（避免打断历史 handoff 交叉引用与知识 1:1 对应），已在正文标注待统一改名。**[更新 2026-07-24]** 该「暂不改名」已被后续用户指示取代——已改名为 `adventure-event-combat.md` / `adventure-events.md`,全库路径引用(含历史 handoff)同步更新。
6. **固化 ADR（执行）。** 新建 **`ADR-0003` 强制在线 · 云端权威（含重账号）** 与 **`ADR-0004` 境界存档 · 篇章重试模型**；ADR-0002 修订为七类。

**仍开放（细节 / 实现级）：** AdventurePlot 数据编码与剧本服务契约、隐藏属性完整清单与阈值、mana 逐步恢复速率与更高境界基线、成就两档奖励内容、PlayerPower 获取 / 失去触发、后端合规落地。
