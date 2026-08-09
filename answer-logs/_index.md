# Answer logs — 已答定问题的归档台账

待答清单（`open-questions.md` 索引 + `open-questions/` 分片）只跟踪**仍待答**的问题。一旦某个问题被拍板，它就从那份清单**移出**，并写入本文件夹的一份 `log-<draftSuffix>.md`。

## 命名：`log-<draftSuffix>.md`

`draftSuffix` = 触发本次移出的那份输入的后缀：

- 处理 `inbox/draft-<suffix>.md` → `log-<suffix>.md`（例：`draft-0725_2.md` → `log-0725_2.md`）。
- 无草稿来源（粘贴文本、或 `/summarize-open-questions` 独立运行）→ 用当天 `MMDD`；若同名已存在，追加 `_2`、`_3`。
- **每次移出新建一个文件**，不追加进旧 log。一次运行若没有任何问题被答定，则不建文件。

## 内容形态

每份 log 是一次移出的快照：日期、来源 handoff / 草稿、以及逐条「问题 → 结论（归档去向）」。log 是**只读的历史记录**，不是权威——结论的权威归属仍在各主题文档的 `## 决策` / `## 意图` 与 `decisions/ADR-*`。

## 台账

| Log | 日期 | 来源 | 移出条数 |
|-----|------|------|----------|
| `log-discipline-enforceability.md` | 2026-08-09 | `inbox/solution-draft-discipline-enforceability.md`（已评审）：**三条「靠约定执行」的工程纪律一次答结** —— 立**「纪律的可执行化」四级阶梯**（写不出来 / 编译不过 / 大声失败 / 评审清单）+ 两条选级判据（**能上线且线上不可见 → 必须第 1 或第 2 级**）为八条 API 契约总则的共同上位判据；离线后端 → **`BackendSelector` 唯一选择点 + `OfflineXxxBackend` 整类 `#if DEBUG`**（连带**作废 `[Export] bool UseOfflineBackend`**、「autoload 直接指向 `.cs`」升为无例外约定、服务级配置改走 ProjectSettings）；`AllEnabled()` → **删除中性诱饵名 `All()`** + `AllIncludingDisabled()` + `[Obsolete(error: true)]` 过渡闸，`DrawPool<T>` 采纳但排期到第二阶段开工前；EventBus 退订 → **切屏后 `#if DEBUG` 订阅审计**（定位取 `d.Method` 不取 `d.Target` ⇒ `+=` 惯用形态不变；豁免 autoload 订阅）。附穷举纪律「条件编译共 6 处，不得扩张」 | 3（另新增 1 条） |
| `log-finale-win-ordinal-vs-statistics.md` | 2026-08-09 | `inbox/solution-draft-finale-win-ordinal-vs-statistics.md`（已评审 · 用户裁定三项取向）：**`FinaleWinOrdinal` 与账号级统计计数的边界靠三条结构性纪律关死** —— **① 分层通则升格并补上合并判据**（可以合并**当且仅当**「语义 + 同步口径 + 篡改后果」三者全同；跨层永远不满足；依赖方向单向；被 UI 读到不改变分层）· **② 统计侧不设「Finale 胜利数」字段**，渡劫成功次数展示直读 `FinaleWinOrdinal`（让重复字段从一开始就不存在）· **③「通关」= 完成整个轮回 `TotalCyclesCompleted`**，与 ordinal 天然不等，**首批不设篇章完成数** · **④ `Ordinal` 后缀立为规则字段层的命名硬约定**（统计层禁用，可机械检查）· **⑤ 两层同走一条写入 / push 通道，只在校验强度上分开，且不做交叉一致性校验** | 1（另 1 条收窄） |
| `log-past-event-trace-schema.md` | 2026-08-09 | `inbox/solution-draft-past-event-trace-schema.md`（已评审）：**`pastEvent` 痕迹 schema 的四个子问题一次答结** —— 快照字段由**判据**给出（「重算不出来的存，重算得出来的不存」，文本类一律留模板侧）+ 条目类型 **`PastEventEntry`**（含 `AppliedChange` 与写明为例外的 `LifeSpanAfter`）+ `EventOutcome` 四值 · **未选项归档轻摘要 `UnchosenOptionRef`**（只求可回溯，不求可重建）· 与 key points **零结构耦合、单向只读**（推论：两者各自定稿）· 单事件 ~770 B **落在既有预算内 ⇒ push 粒度不变**，新增「只追加」不变式与软上限告警。连带答结「**风味文案不物化，跟随模板**」 | 1（另 3 条收窄、1 条新增） |
| `log-legacy-fragment-chance.md` | 2026-08-09 | `inbox/solution-draft-legacy-fragment-chance.md`（已评审）：**道统残卷 / `PlayerPowerFragment` 整条焊到 Finale 上** —— Finale 失败累积 · Finale 胜利掷骰 · 该 Finale 的 eventReward 界面即时发放；上限 / 基础概率 / 适格篇章按已拥有法则数 `x` 分档且**闸门逐档移除**（适格 ⟺ 增量 > 0，两表合一）；**首胜 100% 优先于闸门**；掷骰走 `Hash64(AccountSeed, FinaleWinOrdinal)`、**与 `CycleSeed` 完全解耦**、序号即幂等键、客户端掷后端可复算；状态落 `PlayerProfile.PlayerPowerFragment`（5 字段，不并入统计计数）；**礼包不重置概率但压低上限**（有意的负反馈）。连带**推翻「Finale 失败后可再挑战」**、新增「失败但存活亦完成篇章」 | 2（另 2 条收窄） |
| `log-sync-revision-and-soft-block.md` | 2026-08-09 | `inbox/solution-draft-sync-revision-and-soft-block.md`（已评审）：`revision` = **后端分配的账号级单调递增 `long`** + 客户端只持传输层 `baseRevision`（不进 Profile、不 bump schema）+ **CAS 三分支** + **幂等键 `pushId`**；**`Immediate` flush 是「尝试」不是「必须成功」** ⇒ **进战斗前 flush 失败不挡玩家**；连带修订总则 7 的 `IProfileBackend` 返回类型，UX 两项取向签核（不加额外提示 / 设置屏「同步版本 #N」） | 2 |
| `log-combat-solutions.md` | 2026-08-06 | `inbox/combat-solutions.md`（战斗待答方案草稿汇总，五组 · 已带用户逐节裁决）：**`01-combat.md` 的 38 条战斗待答一次性全部答结** —— 意图三档阈值整体收紧一级且**赋级带回退三章统一的对称 `±2`**（推翻 08-06 / 08-06b 的 `[−4, +2]` 与降阶碾压硬门）/ **`lifeTotalLimit` 概念整体删除** / `ActiveCombat` 存档 schema 与 D0–D6 决策点清单 / 卡牌侧数值与效果系统三层骨架 / 遭遇参数收进 `EncounterSpec` / **enemies 升为与 adventure-event 平级的系统** / 经验曲线与分布 / 道具折价分层与法则强度闸门 / 1% 分母口径 / 九项呈现形态定稿 | **38** |
| `log-0806b.md` | 2026-08-06 | `inbox/draft-0806b.md`（eventOptions 专场第二场）：**`LocationCodex` 记连边**（跨轮回重建整张 `locationMap` 是设计目标）/ **`skipCost` 概念整体移除** / **跳过通道与 `ifMandatory` 整体移除**（选一个即等价于跳过其余，`TryRefill` 一并删除）/ **付不起 `selectCost` 改为「照付 → 判定 → 判负进失败流程」** / **`eventPriority` = 两档，future-event-service 独占置位、PlotManager 不可改** | 5（另 2 条收窄） |
| `log-0806_2.md` | 2026-08-06 | `inbox/draft-0806.md`（08-06 三条 ⚠ 承重裁决项的收口）：ch1 赋级带定为**非对称 `[−4, +2]`**（连带答结 `lifeTotal` 算术冲突）/ 三章带边界 = **内容配置** / 降阶碾压**不需要**独立呈现语言 / **法则不会被强制剥夺**（自愿置换才真移除，其余降级为「本轮回禁用」）/ `chapterRetry` = **三个具名字段 + 通关后保留 + 账号级另有统计计数** | 5 |
| `log-0805b_2.md` | 2026-08-06 | 直接对话（`handoffs/2026-08-05b-...` 的追加拍板）：Travel 闸门给**多个**目的地 / `eventCountLimit` 只计选择进入并结算（跳过与 Travel 均不计） / 连通关系由全局不变的 **`locationMap`** 承载（三篇章共用、玩家不可见） / **每批必有不可跳过项是设计意图不是死锁**。新增结构：`locationMap` + **`LocationCodex`（图鉴族第六本）** | 4（另 2 条收窄） |
| `log-0806.md` | 2026-08-06 | 直接对话（对 08-05 遗留待裁决项的回应）：ch1 赋级带放宽至 ±4 且新增「降阶 = 碾压」硬门（收口意图阈值冲突，取向 = 调带不调阈值） / 失去法则的 1% 分母 = 全部 event 且不限于战斗（带出「移除 `Power` 两条通道」的新结构） / sync 缓冲闸门口径 = 事件级存档点 / `attemptIndex` 整层删除，改由 `CharacterProfile.chapterRetry` 承载 | 4 |
| `log-0805b.md` | 2026-08-05 | `inbox/draft-0805b.md`（location 携带三组字段：事件类型概率修正 · 敌人模板集合 · `eventCountLimit`；配额用尽 → 本批仅剩 Travel；跳过的两条残留细节改由产出侧保证闭合；补位落空判据 = 地域配额用尽） | 2（另 3 条部分答定） |
| `log-0805.md` | 2026-08-05 | `inbox/draft-0805.md`（敌人赋级重定义为角色等级 ±2 的对称带，连带答结 lifeTotal 算术冲突与天劫等级档位 / 栈必须落存档，栈上的目标选择即决策点 / 埋伏进敌人卡池但不计入意图 / `IgnoresProtection` 配额 ≈1% 的游戏场景 / 不会有凭空生成的牌） | 6（其中 1 条部分答定） |
| `log-mtg-loanwords-and-card-types.md` | 2026-08-04 | `inbox/solution-draft-mtg-loanwords-and-card-types.md`（MTG 借词第一批全部定名，含卡牌类型六分 / 异能三分 / 永久物 / 次类型；触发条件可跨归属方；法则能承载战斗内触发；意图 = 快照故偏差不做处理；战场与参战方的边界判据） | 5（另 1 条部分答定） |
| `log-0804.md` | 2026-08-04 | `inbox/draft-0804.md`（`animations/` 归 `visuals/` 之内、一级分区确定为两个；另：音频工具倾向 Suno 但未定案） | 1（另 1 条部分答定） |
| `log-0803.md` | 2026-08-03 | `inbox/draft-0803.md`（满手抽不进 / 触发载体开放 / 道念下限 0 逐次结算截断 / 敌人赋级上界 = 高一个大境界的初期 / 引入 battlefield 及 BattlefieldManager · StackManager / 法则 · 古宝 · 神通 · 法宝 中文重定名） | 6 |
| `log-0802c_2.md` | 2026-08-02 | 粘贴文本（`handoffs/2026-08-02c-...` 的追加拍板：意图即承诺、公布后不因玩家行动重算 / 敌人回合内意图区收起） | 2 |
| `log-0802c.md` | 2026-08-02 | 粘贴文本 → `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md`（`diff ≥ 3` 仍为无信息 / 篇章分档保留且 ch2·ch3 两端各收紧一级 / 跨类别 = 主类别并行陈列 / 综合数值 = 合并后的最终结果 / 意图仅在玩家回合显示敌人下一回合 / 同级归第二档为有意为之、不做补偿） | 6 |
| `log-0802b_2.md` | 2026-08-02 | 粘贴文本（`handoffs/2026-08-02b-...` 的追加拍板：栈深由触发式能力入栈撑起 / 回合开始与结束是有归属方的时点、双方不同时进行 / 手牌上限是恒定不变式、无弃牌机制） | 3 |
| `log-0802b.md` | 2026-08-02 | 粘贴文本 → `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`（stack 保留但交互与优先权移除 / 响应窗口细则整条消解 / 交互式回合的移动端形态与时长约束消解 / 回合结构 = 起始步 · 主阶段 · 结束步三步） | 4 |
| `log-0802.md` | 2026-08-02 | `inbox/draft-0802.md`（道念差 → lifeTotal 损失 = 1:1 / 奖励计算归 combat-service 且发放属战斗流程 / 失败仍发 baseReward、额外惩罚包在 reward 内 / 奖励分强制与可选两类 / Practice·Combat·Finale = blind 三档，回合数与胜负条件可变 / 越级追分可能但难 / momentum = 非负整数；追加：不设截断改由内容侧赋级上界规避、奖励选择不是决策点、`experiencePoint` 为新字段、stack 连响应窗口一并借入使回合交互式） | 11（另 2 条部分答定） |
| `log-0801b.md` | 2026-08-01 | `inbox/draft-0801b.md`（战斗定长 10 回合 / 道念产出途径与起始 `baseMomentum` / 胜利侧读道念差 / `life` → `lifeTotal` 归 0 = defeated / 意图分界值 = 越阶硬门 + 同阶差值 / 敌人等级 = `EnemyTemplate` 物化产物 / 全局等级序基数无跳变 / 图鉴五项文案一次全解锁 / 抽象层级五级定名；追加：ch1 分档 1–2 / ≥3、`baseMomentum` 补齐、CharacterPower 定性、平局只发基础奖励、付费口径确认、`lifeTotal` 字段改名） | 15 |
| `log-0801.md` | 2026-08-01 | `inbox/draft-0801.md`（玩法循环整体评审后的逐条裁决：道念 = 计分 = 胜负判据 / 寿元定价按目标时长分档 + 跨篇章结转 / 跳过限可选事件 / `manaLimit` 不设护栏 / 隐藏属性跨档定性反馈 / 等级成长 = 事件产出 + 敌人等级精确标注 / 失败侧产出） | 6（另 3 条部分答定） |
| `log-0730b.md` | 2026-07-30 | `inbox/draft-0730b.md`（意图三档揭示取代「通常不揭示」/ 例外条件反转 / EnemyManager 不再细分 + CharacterManager 平级 / mana 每回合恢复至上限 / 决策点存档与 `selectCost` 不回滚 / Finale 为战斗变体） | 6 |
| `log-0730.md` | 2026-07-30 | `inbox/draft-0730.md`（`.claude` 工程层定位与主从关系 / 寿元红字倒数呈现细节 / IntentManager 并入 EnemyManager） | 3 |
| `log-0728.md` | 2026-07-28 | 直接对话（无草稿来源）：`.claude/knowledge` 引用层形态 → 薄引用，固化为 ADR-0005 | 1 |
| `log-service-api-contracts.md` | 2026-07-27 | `inbox/solution-draft-service-api-contracts.md`（七服务 API 契约总则 / 结算阶段名 / CombatResult 归属 / 跨服务调用措辞 / eventOptions 持久化形态） | 5 |
| `log-0727.md` | 2026-07-27 | `inbox/draft-0727.md`（内容放量开关 / 双 contentVersion / 增量下载与签名 / 断线韧性 / RNG 持久化 / 存档点频率） | 9 |
| `log-0726b.md` | 2026-07-26 | `inbox/draft-0726b.md`（事件优先级 / 跳过语义 / 热更范围 / player-profile 落位） | 8 |
| `log-0725c.md` | 2026-07-25 | 历史累积（07-16 ~ 07-25c 全部批次的一次性迁移） | 35 |
