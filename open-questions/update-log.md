# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

> **只保留最近 10 条。** 更早的条目原样移入 [`update-log-archive.md`](update-log-archive.md)（按时间正序），
> 一字未改、仅换了文件——本日志与归档合起来即全部历史（`decisions/ADR-0005`：台账不无限膨胀）。

## 2026-08-28c（用户指派的定点修复 · 两轮 · 手牌上限定案 7 · 三份根级横切同批改齐 · 陈旧 ADR 候选行全库清零 · `RelicData` 清零 · `balance.md` 补三问判据）

- **不是技能运行，是一次按 08-28 全量评估所列问题的定点修复。** 输入 = `open-questions.md`「本次新识别的三处问题」+「两处转手空洞」；**唯一一次裁决由用户直接给出：手牌上限定案 7**，其余全部是零决策的投影修正。
- **🔴 手牌上限 9 → 7**（`terminology.md` 词条），并补上推导回链。下游两处引用本就按 7 写，未动。
- **三份根级横切同批改齐**：`terminology.md`（`ProfileChangeSpec` 补 `ItemElements` / `ItemUseElements` 两列 · capability flag / modifier pipeline 两词条改两层共用形态 · **新增 11 条词条**覆盖 `ADR-0113` / `0115` / `0117` / `0118` / `0119` / `0122` · `Source:` 补至 08-28）· `program-overview.md`（回合数改 `EncounterSpec.TurnLimit` · 重试上限改两档表选行 · `EnemyManager` 删「意图生成」改 1-ply argmax · `CapabilityManager` 改两层聚合 · 补 `Project(spec)` 与批次层储物袋提交两处落点）· `system-overview.md`（补 `BattlefieldManager.cs` / `StackManager.cs` · `CombatantDeck.cs` → `DeckModule.cs` 消孤例 · `combat.csv` 注释删 `intent` · autoload 树补 combat-service 五个 manager）。
- **四份文档的陈旧「ADR 候选（待固化）」行改为指向已 Accepted 的 ADR**：`architecture.md` 10 条 → `0007` / `0008` / `0009` / `0010` / `0011` / `0012` / `0013` / `0014` / `0108`；`viewmodel.md` → `0010`；`scoring.md` → `0018` / `0086` / `0052` / `0088`（同批把「固定 10 回合」改写为 `TurnLimit` 遭遇参数）；`monetization.md` → `0023` / `0024` / `0101` / `0117`。
- **第二轮（同日，用户追加授权）：同型遗留一并清零，另 9 份文档 13 条** —— `adventure-event/common-properties.md` → `0021` · `exchange/_index.md` → `0020` · `research/_index.md` → `0022` · `enemies/_index.md` → `0113` · `player-power/common-properties.md` → `0017`（并另起一行记形态 `0116`）· `combat-service.md` 两条 → `0018` / `0019` · `content-service.md` → `0007`（「固化时须一并纳入两条」改写为「已一并纳入」，因 `ADR-0007` 决策段确已含剧本例外与「无云端内容通道」）· `life-cycle-service.md` → `0036` · `plot-manager.md` 四条 → `0007` / `0014` / `0016` / `0015`，并**补记一条** `0029`（剧本树不分包，此前决策段漏列）· `profile-service.md` 两条 → `0017` + `0116` / `0009`，并**补记一条** `0108` · `vision/scope.md` 两处 → `0006`。**逐条都回读了对应 ADR 的决策段核对覆盖面**（非按标题猜），`0007` / `0016` / `0036` 三条尤其确认了正文里那半句限定确实在 ADR 内。**全库主题文档现已零处「ADR 候选 / 待固化」措辞**；`ADR-0004` / `ADR-0005` 背景段里的「曾列为 ADR 候选」是史实叙述，未动。
- **`RelicData` 遗留清零**：`player-power/_index.md` 5 处 + `player-profile/_index.md` 1 处改写为 `PowerData` 并指向 `character-profile/power/_index.md` 的字段面权威；那条「relic / joker 字段清单尚未设计」的待决项随之改写为「类型面已闭合、缺的只是内容条目」。**`content/_index.md` 经复核已无该阻塞理由**（上次评估的这半条记录已过期）。
- **转手空洞闭合**：`systems/balance.md` 新增「不设 `GlobalBalanceData` 兜底大表；平衡资源按三问判据逐份切」一节（三问表 · 不设兜底大表的理由与代价 · 三处既有应用 · 「消费点早于 `LoadAll()` 不进注册表」准入边界）；`CombatRulesData` / `EnemyLevelingData` 各补注册形态回链；管线旋钮表为 overlay 下载重试 / 退避标注「不可线上调」。**`ADR-0074` 就地改写**（决策段补「不设兜底大表 + 三问判据」，后果里自陈的欠账关闭）——同一件事不另开编号，故「下一阶段」的**待固化候选由 1 条降为 0 条**。
- **未做（如实留痕）**：同一份 handoff 的另一半承接——`systems/game-progression.md` 的 `LocationMapData` 校验行改回链 + 类定义加 `ISingletonContent`。不阻塞任何 derive 步骤，已记在 `open-questions.md` 的转手空洞小节里。
- **未新增 / 未移出任何待答问题条目**（`answer-logs/` 无新条目）；判定表的判定一格未改，只更新了各行的「已修 / 未修」备注与「落笔前的修正」清单。

## 2026-08-28b（`/write-adr all` 客户端库 · 全量扫描 · 固化 23 条 · 只写 `decisions/` 与「下一阶段」）

- **范围 = 客户端库全量。** 机械对出 **29 份未被任何 ADR 引为来源的 handoff**，分三片并行只读核查（早期 10 份 / 中段 10 份 / 最新 9 份），逐条判定「已覆盖既有 ADR / 已落地 / 查无实据 / 矛盾 / 已推翻 / 非方向性决策」，并逐条回主题文档抽查事实依据。
- **固化 23 份新 ADR（`ADR-0100` ~ `ADR-0122`）**，编号按定案日期升序分配、台账按日期降序置顶：
  - **sync 族三条**：`revision` CAS + `pushId` 幂等（`0103`）· `Immediate` flush 非阻塞（`0104`）· 缓冲闸门口径 = 事件级存档点（`0102`）。三者可各自单独推翻，故不合并。
  - **战斗族四条**：`combat` 单子流 + 初洗按 `sides[]` 序（`0112`）· 敌人 AI 权重向量（`0113`，08-26c 与 08-28 两次推进合成一份）· `ActivateAbility` 契约（`0114`，按 08-27 推翻后的口径落笔，有限性闸只作备选记一句）· 效果原语语法与五阶段流水线（`0115`）。
  - **内容 / 道具族四条**：`Artwork` + 敌人台词 + 不开音效字段（`0120`）· 道具使用效果面按世界分两格（`0121`）· 批次层储物袋提交与痕迹（`0122`）· `DeckOperation` 取池链（`0118`）与 `MoveCard` 抽牌堆插入位（`0119`）**刻意不合并**（两个子问题各自独立，同批落笔只因写入面重叠）。
  - **其余**：美术方向（`0100`）· `chapterRetry` 承载 + `attemptIndex` 删层（`0101`）· 单数命名通则（`0105`，来源两份 handoff）· `IgnoresProtection` 落内容编排层（`0106`）· 账号身份客户端承接（`0107`）· `Project(spec)` 只读投影（`0108`）· `lifeSpanCost` 定值（`0109`）· `EnemyData.ChapterScope`（`0110`）· `eventCountLimit` 剧本免疫（`0111`）· capability flag / modifier 形态（`0116`）· 重试上限载体（`0117`，与 `0116` 不合并——可单独推翻且承重论证不同源）。
- **候选清单移出 1 条**：「敌人 AI 策略 = 权重向量的重新加权」→ `ADR-0113`。**剩余 1 条**：「不设 `GlobalBalanceData` 兜底大表 + 三问判据」经复核**仍是查无实据**——`content-service.md:275` 明写把判据「归 `systems/balance.md`」，而后者只有该判据的逐处应用（`EnemyLevelingData` / `ChapterRetryLimitsData` 各自的「不并入」论证），没有一处陈述这个决定本身。按「台账绝不领先于事实」不建档，原样留下。
- **两处子代理误判已由主上下文抽查纠正**（如实留痕）：「`Charges == -1` 且含 `OutOfCombat` → `PushError`」被报为查无实据，实际在 `item/_index.md` 校验表 **I-12** 行（核查只到 I-9）；「敌人不开音效字段」同样被报为查无实据，实际在 `enemies/common-properties.md:41`。两条均已按「已落地」处理。
- **两处既有 ADR 与主题文档矛盾，本次不改、留报告交裁决**（改写既有决定归 `/analyze-new-ideas`，不在本技能范围）：`ADR-0019` 后果行仍写 `IgnoresProtection` 稀缺性靠「`PushWarning` 软检查」，而该加载期核对表已随 `ADR-0106` 删除；`ADR-0017` 决策段仍只写聚合 `PlayerPower` 一层，而 `ADR-0116` 已扩为两层。
- **台账**：`decisions/_index.md` 新增 23 行，重排后 **122 行 ↔ 122 个文件**、零不一致（本次运行前亦为零不一致）。「状态词汇」「约定」「ADR 形状」三节一字未动。
- **未碰任何主题文档、未碰 handoff、未碰 `content/`、未碰「derive 就绪度」小节、未碰后端库。**

## 2026-08-28（`/batch-analyze-new-ideas` 道具使用效果面 · 战斗外使用存档点与痕迹 · 内容资产字段 · 移出 6 条 · 新增 2 条）

- **一批三份 `decided` 草稿并行校验、三波串行落笔**（三片写入面两两相交——`item/_index.md` · `deck/common-properties.md` · `combat-service.md` · `systems/common-properties.md` · `profile-service.md`——故不并行）。Phase A 分级 🔴 7 · 🟠 1 · 🔵 54；必问过滤降级 3 项、去重合并 1 组（两个 worker 独立报出同一条跨草稿矛盾）后 **6 问**，分两轮问齐，**全部取推荐项**。

- **`ItemData` 使用效果面整条答结**：两格（战斗内 `EffectData[]` / 战斗外 `ProfileChangeSpec` 模板，只开 `Elements` / `CodexElements` / `Stats`）· **`Abilities` 整格移除**（三档异能都以「在场」为前提，而道具从不进场）· 新增本场配额格 `MaxUsesPerCombat`，把 `ItemUsesThisCombatExceeded` 从 `Charges` 上摘开 · 13 条加载期校验 · 存档零增量。
- **`RelicData` 条整条移出**（四子项各有权威落点；该类型名已不存在，全库四处同源表述随之改写为 `PowerData`）。**`item/common-properties.md` 与 `CardData` 两格占位条整条移出**；`PlayerItem` 条**部分答定**（只移出「战斗外的效果形态」，目录 / 次数补充 / 价格库存三项仍在）。
- **「战斗外道具的使用入口」整条答结**：一次使用**不是决策点**、是一次即时提交（一次 `TryApply` ⇒ 一次本地原子写）；push 走 `Debounced` + **新增第六个 `SavePointReason` 成员 `InventoryChanged`**，它同时补上随售此前空着的那个 reason。
- **`ProfileChangeSpec` 补两列**：`ItemElements`（次数扣减——此前**没有任何一列装得下它**，这是「消耗即时经 `TryApply` 写档」这条已定纪律长期悬空的根因）与 `ItemUseElements`（战斗外使用痕迹，新序列 `CharacterProfile.pastItemUse`）。三处合并为**一次** schema bump、空迁移。
- **`ItemUseEntry` 收为五字段、零派生量**：`LifeSpanAfter` / `ChargesAfter` 都不写，痕迹判据零松动、`ADR-0021` 的「不是先例」句一字未改；代价由一条写清楚的读取算法承接（从最近一条 `pastEvent` 锚点起、在归并的同一趟遍历内累加）。**`Source` 一个成员不加。**
- **`AbilityKind` 撞名拆分**：element 侧改名 `AbilityCarrierKind`，成员名不动 ⇒ 零迁移；连带补写「枚举类型名不参与序列化」这条库内此前缺失的承重句。
- **敌人 schema 三格答结**（出自主题文档待决项，不在任何分片）：立绘 → 新增**顶层共有字段 `Artwork : Texture2D`**（挂载面七类，功法不挂 · 可空是常态 · 缺失由 `LoadAll()` 收口汇总一行而非逐条目告警 · 占位回落只写一处）· 台词 → `Lines : EnemyLine[]` 形态落定（`LineSlot` 成员**收窄**待战斗 UX 专场）· 音效 → **判定不开字段**。另补齐 `AiWeightVector` 这处形式化残留（全库只被使用、从未被定义）。
- **`ADR-0099` 就地改写**（本批唯一一次 ADR 改写授权）：「`PowerData.Abilities` 取值域不收窄」限定为「不按启动式 / 被动式收窄」，战斗外触发式另受一条加载期校验约束。
- **新增待答 2 条**：用道具产生的栈条目落在 `StackEntryKind` 哪个成员上（`01-combat.md`）· 二进制资产是否可经 overlay / blob 通道下发（`deferred-content.md`，后端 `contracts/content-manifest.md` 留对侧承接项）。**收窄 1 条**（生成资产落地的命名与导入规则——寻址不再依赖命名约定）。
- **跨库对称落笔**：`SavePointReason` 扩为六值，后端 `contracts/profile-sync.md` 同批同改并明写未知取值宽容语义；资产下发通道的空白两侧对称登记。**本次不留跨库空悬项。**
- **纪律观察（供下次 `/summarize-open-questions` 收口）：两条承重缺口都从未进过任何 `open-questions/` 分片**——`ItemData` 的效果格缺口只活在 `content/_index.md` 登记表与一份 handoff 的 Open questions 里；`Charges` 扣减无 element 形态同理。两次同款发现值得一次专门对账。另：后端 `open-questions/cross-boundary.md` 的「待承接」长期为空，该分片的登记纪律本身可能已失效。
- **索引 `## derive 就绪度` 小节内有三处失真未修**（旧文本仍称「效果原语 / 异能语法未定案」并把它列为玩法侧欠账之首）——该小节由 `/assess-derive-readiness` 独占写入，本技能无权触碰，留待下一次全量重估。

## 2026-08-27（`/batch-analyze-new-ideas` 效果语法 · 取池链 · capability flag · 移出 5 条 · 新增 1 条）

- **一批三份 `decided` 草稿并行校验、两波串行落笔**（波 1 = `ability` + `card-pool` 合并，因两者共写 `deck/_index.md` 的 `MoveCard` 同一行与 `combat-service.md`；波 2 = `capability`，与波 1 共写 `balance.md` 故排后）。Phase A 分级 🔴 5 · 🟠 2 · 🔵 41，去重合并 + 跨草稿追加 1 条后 **8 问**，分三轮问齐。
- **效果原语 / 异能语法整条答结**（移出 `01-combat.md` 1 条 · 另 `CardData` 字段清单部分答定）：`EffectData` = 抽象基类 + 一原语一 `[GlobalClass]` 子类树（否决 `Op` 枚举扁平表与表达式串）· 静止式修正另立并列定义体 `StaticModifierData`，**不是 `EffectData` 子类** · 首批八原语 + `TimingIds` 十时点 + 三谓词条件 · `AbilityData` 的占位 `Effect` 落为 `Effects` / `StaticModifiers` 两格 + XOR 校验 · `CardData` 收口（`ManaCost` 独立格、取消触发器格、新增 `OnPlay`）· 加载期校验 19 条 · 存档零新增字段。
- **效果流水线定形，条件求值取「逐 element 就地求」**：阶段序 `重检/挂起 → 关键字展开 → 数值求值 → 逐 element{条件 → 施加} → 收口`；规则「element 顺序是规则、前一条改了道念后一条读到改后的值」保留，代价是 **AI 试算须补一条例外规则**（按进入本动作前的局面求条件，明写试算与真实结算可能分支不同），`combat-service.md` 的试算措辞相应改写；「阶段 1–4 全路径无副作用」收窄为「`Evaluate` 与条件求值无副作用」。
- **启动式的有限性闸整条推翻**：删除加载期校验「`Kind == Activated` ⇒ `ManaCost >= 1` 或 `MaxActivationsPerCombat >= 1`」，**组合技达成无限升为被接受的设计面**，非本意的无限由内容侧纪律承接；工程侧改设**单次动作链的栈条目总数上限 N**（落 `CombatRulesData`，超限中止 + `PushError`），它只阻止进程不返回、不约束任何设计面。触发式异能携带回堆效果因此**不加任何闸**。`TimingIds` 首批据此保留十个（含 `momentum.changed`）。
- **疲劳的「可被取消」全库改为「可被削减至 0」**：`ADR-0088`（标题 / 决策 / 理由 / 备选四处）· `combat-service.md` 四处 · `scoring.md` · `terminology.md`。终止性由 `TurnLimit` 承接，故不需要「不可削减」这条特权。
- **事件产出的卡牌取池链答结**（移出 `03-adventure-event-types.md` 1 条）：走池抽收窄为**仅 `AddLooseCard`**，其余四个 `Op` 的 `TargetId` 必填；取池链逐字沿用商店 `Card` 族那一条、子流复用 `RngStream.Reward`、**抽取在物化时掷定并随定稿实例落存档**；只新增 `CardTypeFilter` 一格（`RarityFilter` / `Count` 与 `GrantFromPool` 共用）；池容量校验为**清单式 `PushWarning`**、短缺仍走物化期降级；权重表挂**战后奖励池**（族维度已含卡牌），事件侧固定取一档、不按优势档选表。
- **卡牌效果把牌送回抽牌堆：开口**（移出 `01-combat.md` 1 条）。形态 = `MoveCard` 的目的地扩展 —— `To : CardZone` 保持四值 + 独立一格 `InsertPosition { Top, Bottom }`，**不开随机位**；校验放宽为「`From == To` 且 `To != DrawPile` → `PushError`」故**允许抽牌堆内重排**。护栏落在载体消耗性与 `TurnLimit` 上，`ADR-0052` 只在「后果」补一条边界说明。连带收掉 `deck/_index.md` 内 `⇄` 与「只减不增」的自相矛盾（改的是后者）。
- **capability flag 体系与重试上限的存档表达答结**（移出 `deferred-content.md` 与 `06-meta-progression.md` 各 1 条）：扁平 `enum` 不分区 · 命名 = 动词三词表 `{Reveal, Show, Unlock}` + 禁否定式（它是「union 即全部叠加规则」这条不变式的可机械检查护栏）· 叠加 = 集合并幂等不告警、**冲突结构上关死** · `HashSet` 而非 `[Flags]` · 宿主 = `profile-service.CapabilityManager`，**注册面两层共用**（神通与法则皆可授予）· `PowerData` 追加 `GrantedFlags` / `Modifiers` 两字段 · 重试上限三候选全否，读既有 `PlayerEntitlement.BundleGrantOrdinal`，存档 schema / `CostKey` / `ResourceElements` / 后端契约零改动，仅补载体 `ChapterRetryLimitsData`（具名篇章字段，不用索引数组）。
- **跨草稿量纲对齐**（批量独有）：战斗内 `ModifierTarget` 与 Profile 侧 `ModifierKey` 两套 key 空间分立不合并，但**量纲统一万分比整数、合并算法统一「同层求和 → 只乘一次 → 只取整一次」**，两波逐字落齐。
- **新增 1 条**（`01-combat.md`）：疲劳扣减是否进 `EncounterSpec` 覆写组 —— `MoveCardEffect` 的 `From` 可取抽牌堆使「削减对手抽牌堆」结构上成立，`balance.md` 那条的重开判据 ① 触发，本次不答定。
- **就地改写三份 Accepted ADR**（用户当场授权）：`ADR-0017` 收窄失真的「仍未定三项」· `ADR-0088` 四处措辞 · `ADR-0052` 后果补边界说明。均不新增编号、不改台账排序。
- **对应 answer log**：`answer-logs/log-ability-primitive-grammar.md` · `log-card-pool-and-reshuffle.md` · `log-capability-flag-and-entitlement.md`。

## 2026-08-26（`/batch-analyze-new-ideas` 战斗三题 · 移出 3 条 · 新增 1 条 · 追加 1 处）

- **一批三份 `decided` 草稿并行校验、串行落笔**（`substream` → `enemy-ai` → `ability`）。三份写入面两两相交（`combat-service.md` 三份共写、`enemies/common-properties.md` 两份共写），故 Phase B 不并行。合并 interview 去重后 **2 问**，用户裁决**两项均与推荐相反**。
- **战斗随机收口为单一 `combat` 子流**（移出 `01-combat.md` 1 条）：五处互不相容的表述横跨四份文档，统一为「两侧共用 `combat` 子流、其上不派生任何层」，连带删除 `Hash64(combatStreamSeed, eventId)` 派生层。`RngStream` 枚举与 `rng.stream[]` schema **一字不改、零迁移**。台账原先登记的代价「放弃玩家额外抽牌不打乱敌人牌序」**订正为代价实为零**——该性质由「抽牌堆不重洗 + 参战方组装时一次初洗」提供，与子流数无关。同批明写洗牌顺序规则（按 `sides[]` 序初洗、`sides[0]` = 玩家侧、掷先后手排其后）与确定性验收断言三条。
- **敌人 AI 的决策形态整条答结**（移出 `01-combat.md` 1 条，五项未定一次答齐）：表达形态 = 独立可复用资源 `EnemyAiProfileData` + 权重向量（`[Export]` 直接类型引用，可空即回落兜底）· 算法 = 1-ply 加权效用评分 + 确定性 argmax · 粒度 = 逐张、每次重算候选集 · 多回合倾向 = **零记忆纯局面函数**（`ActiveCombat` 一格不加）· 强弱差 = 三条结构性上界（只给权重不给代码 · 深度恒 1-ply · `Value` 钳在 `[AiWeightMin, AiWeightMax]` 越界 `PushError`）。同批：AI 全流程**零随机**；**AI 读取面 = `CombatSnapshot` 双视角化**（新增 `ViewerSide`，缓存按视角分持，**不新增第二个投影类型**）——字段语义不变（仅 viewer 己方非空），故「不读玩家手牌内容」仍是结构性做不到，未降为纪律级；profile 逐条取值归内容层，`content/enemy-ai/` 待 `/scaffold-content-type` 开张。
- **`ActivateAbility` 的服务契约答结**（移出 `05-service-contracts.md` 1 条）：签名 `ActionResult ActivateAbility(entryId, abilityId, targets)`（**按战场条目寻址，不寻址 `Power`**）· 代价 = `AbilityData.ManaCost` 一格，首版不开 Profile 侧代价列 · 每场配额 = `MaxActivationsPerCombat`（`-1` = 不限、`0` 非法），运行期落既有 `entry.counters`，`ActiveCombat` 零新增字段 · 拒绝语义走 `ActionResult`，新增 `AbilityNotAvailable` / `AbilityQuotaExceeded` 两个成员。连带：加载期校验由「有费用」放宽为「有有限性闸」，`CombatFeedKind` 增 `AbilityActivation`，灰态预判由 `BattlefieldEntryView.ActivatableAbilities` 承载（只填 `ViewerSide` 己方）。
- **新增 1 条**（`01-combat.md`）：卡牌效果重洗牌库是否开口——全库从未讨论，却已被两条全称推论顺带排除，与子流数量正交。**追加 1 处**：`01-combat.md` 既有的竖屏专场条目追加「阵法上启动式异能的 UI 宿主」。
- **跨草稿口径统一**：`enemy-ai` 引用的 `ActivateAbility` 准入条件以 `ability` 稿为准；末波另修正了一处会把不限次异能整个排除出 AI 候选集的 `-1` 语义漏洞。

## 2026-08-26（`/write-adr all` · 新建 69 份 ADR · 移出候选 0 条 · 待答项零改动）

- **一次全量扫描把「已落笔但无档案」的定案补齐**：逐份精读 `handoffs/` 下 07-12 ~ 08-26 的全部 handoff（约 100 份，全部 `status: distilled`），逐条打开它指向的权威主题文档**查证是否已落笔**，去重后得 **81 条**候选，按「能否被单独推翻」合并为 **69 份 ADR**（`ADR-0031` ~ `ADR-0099`）。`decisions/` 由 30 份增至 99 份，Accepted 由 29 增至 98。
- **承重的漏网件**（此前无任何 ADR 承载）：功法 = 卡组构筑单位（`ADR-0054`）· 敌人赋级带 `±2` 无例外硬规则（`ADR-0044`）· 跳过通道整体移除（`ADR-0046`）· 寿元递减预算模型（`ADR-0031`）· 敌人意图整条移除（`ADR-0059`）· 借 stack 不借交互 + 三步回合（`ADR-0039`）· 「信息靠遭遇获得」升格为支柱（`ADR-0093`）。
- **待答清单本体一字未动**：本次只写 `decisions/`、台账与「下一阶段」的 ADR 计数句。各分片的问题条目、分片导航、当前焦点与 `/assess-derive-readiness` 独占的「derive 就绪度」全部原样保留。
- **候选清单移出 0 条**：唯一在册候选「不设 `GlobalBalanceData` 兜底大表，平衡资源按三问判据逐份切」经核对**查无实据**——`systems/services/content-service.md` 把判据转手给 `systems/balance.md`，而后者「单例」零命中。按「台账绝不领先于事实」**不建档**，原样留在「下一阶段」。补 `balance.md` 那一小节后再固化。
- **11 条判为不够 ADR 门槛**（落笔位置 / 字段增删 / 数值待定），见本次报告；`ADR-0083` 收窄了 `ADR-0019`「五类靠卡框色 + 类型角标区分」的适用面，已写在其「后果」内，`ADR-0019` 本体未改。

## 2026-08-26（`/batch-analyze-new-ideas draft-0823e` · 作废 2 条 · 改写 1 条 · 收窄 2 条 · 新增 0 条）

- **一份草稿按写入面切三分片并行**（`pack-core` / `sell-balance` / `ux`）。草稿 `status: decided`，但本轮校验查出 08-25 那轮未触及的三条真冲突与两条真取向，合并 interview 5 问全部由用户裁决；另有 5 项被必问过滤降级为标准默认直接落笔。
- **储物袋改为跨两个持久层的呈现视图**：轮回级法宝（`magicPack`）与账号级古宝同时呈现、条目带 `AbilityScope` 标识；`magicPack` 只是它的轮回级那一半。这同时收口了一处**先于本次存在的三口径漂移**（`item/` 说纯 `CharacterItem` 容器、`player-item/` 说古宝「存于储物袋」、`terminology.md` 说「存放全部法宝 / 古宝」）。
- **容量上限整条取消**，界面由既有的纵向滚动网格承载。连带清理散在 **13 份文档**里的 9 格 / 99 项残留（草稿的「后果」清单只列了 6 份，另 7 份由分片校验查出）。
- **作废 2 条**（前提消失，**非答定**，不入 answer log）：「储物袋满时获得新道具的处理」与「满袋时能否购买道具」；`PROFILE_MAGICPACK_FULL` 文案键随之失效，`error-and-blocking-ux.md` 的举例换为 `PROFILE_ITEM_COMBAT_ONLY`。
- **改写 1 条**：「9 格对道具经济的回压」→「回寿法宝的总量护栏在内容编排面的口径未定（承重）」。**取消上限把回寿法宝的第三道软闸一并拆掉了**——这是草稿未察觉的连带后果，用户裁定护栏交给内容编排面（出现频率 / 库存深度 / 定价），规则层不设持有上限；另两道加载期条目合法性校验原样保留。
- **售出通道由一条扩为两条**：Exchange 商店内售出（权威留 `exchange/`）+ 储物袋随售（权威落 `character-profile/item/`）。回收率分两档（商店档 `SellRatePercent` 逐条目 · 随售档 `PackSellRatePercent` 全局单值），**相对关系由一条加载期硬校验固定**（`SellEnabled == true` 且 `SellRatePercent <= PackSellRatePercent` → `PushError`）。
- **两档回收率的论证基底被推翻重写**：草稿写「保住『跑一趟商店』的规划价值」，但用户指出 Exchange 大部分不提供回收 ⇒ 随售才是**常态的弃置途径**（低回收率使清仓不构成经济来源），提供收购的商店是**罕见的更优机会**。`SellEnabled` 首批以 `false` 为常态（内容编排口径）。
- **仙玉「唯一获取通道」措辞订正**：同币回收 ⇒ 落在收仙玉那一格的法宝随售即产出仙玉，且免费取得者是**净产出**。两处改为「唯一**主动**获取通道」，净产出敞口正面写下，量级归「定价表哪几格填仙玉 × 掉率」的统计校准（并入既有那条待答项）。草稿 §1 的「换取基础货币灵石」是错的。
- **新增 `Source.PackSell`**（code 9，仅 `(Item, Character)` 的 `Remove` 开），落 `systems/common-properties.md`；两处「`ExchangeSell` 是**唯一一个**只出现在 `Op == Remove` 上的成员」改为两个成员。**订正草稿一处论证**：`PackSell` 不是「随售唯一的痕迹载体」——随售无 `PastEventEntry`、不落 `SourceCode`，它一个字节也不进存档，只进日志与客服溯源，事后不可重建（代价正面写下）。
- **战斗内持有物面板定为「可操作 / 只读」两层**；启动式 `Power` 的启动入口落在**长按升起的弹层**内（bottom sheet），图标条本体保持纯只读。**草稿写的「点按查看详情」被推翻**——既有「可拖拽用点按、不可拖拽用长按」的手势判据被明确标为承重，一字未改。**收窄 1 条**：`01-combat.md` 的四项形态条删掉启动入口那半句；竖屏分区专场条**追加三项待容纳形态**。
- **收窄 1 条**：「战斗外道具的使用入口」——入口形态已由 `screen-flow.md` 给出，剩余两问（是否单独构成存档点 · 事件外使用的痕迹落点）保留。
- **新增 UI 落点**：`PlayerProfile` 屏内增一区「持有的古宝」（只读 + 剩余 `Charges`，不新增主菜单入口）——储物袋只在轮回内存在，付费主要交付物在轮回外此前不可见。储物袋详情卡片加「售出」键（仅法宝、就地二段确认、同币回收价预览、售出后移出列表）。
- **未收口，已记为待答项**：用户在裁决中提到「Exchange event 是以物易物或资源换取道具」，但**以物易物在本库零承载**（`ExchangeOffer` 支付侧恒为货币 element，`ExchangeStockRule` 无「以什么换」的书写位）。写下它 = 新增一种交易形态（支付侧形状 + 库存规则字段 + `CanAfford` 语义三处都要动），超出本次授权，故只记入 `03-adventure-event-types.md` 待用户拍板。

## 2026-08-26（`/analyze-new-ideas draft-0823g` · 移出 1 条 · 收窄 1 条 · 新增 1 条）

- **草稿 `status: decided`，三条取向已由 08-25 批量 interview 逐条裁决，本次校验通过、未再触发 interview。**
- **移出 1 条**：「隐藏属性与战斗资源的共存面」（`01-combat.md`）→ **战斗层不读写隐藏属性**，全部交互在事件层（生成期调制 · 结算期 outcome 求值 · `eventEnd` 推拉）；`lifeSpanCost` 与失败扣 `lifeTotal` 两处相邻情形明写为非反例。权威落 `plot-manager.md`（**不落 `scoring.md`** —— 该文件零处提及隐藏属性，写进去即造第二权威），`combat/_index.md` 呼应并删同题待决项，`scoring.md` 只加一行回链。
- **收窄 1 条**：「战后奖励面板的形态」交互层答定（逐项列出 + 逐项领取 / 跳过 · 不可反悔 · 候选恒 3 项），呈现层仍待战斗 UX 专场。
- **推翻三条既有定案**（用户 08-25 明确裁定）：`combat-service.md` 的「不设放弃全部候选通道」·「固定 3 项候选」的**择一**语义 ·「战后奖励选择不是决策点」；`combat-ux.md` 对应一处表述同改。
- **连带定义**：`activeCombat.reward` 承载逐项领取进度（`RewardPickState` 三值）；战斗内决策点清单 **D0–D6 → D0–D7**（新增 `D6 = 一次领取 / 跳过`，收口顺延 `D7`），六处跨文档引用同步改名。**「是决策点」与「reroll 已封死」并存**：封死 reroll 的是候选预先算定，新增落点的是领取进度这段重算不出来的中途状态。
- **核对结论（不改动）**：置换 / 禁用面板本就是逐槽接受 / 拒绝，与逐项领取 / 跳过同构，「形状与战后奖励面板完全同构」这条定案更成立而非更不成立；Research 构筑面板的同构收窄为**呈现层**（它仍是选完再一次确认提交）。
- **新增 1 条**：逐项领取后的奖励厚度重估（`01-combat.md`），随内容扩充后的统计校准同批。
- **另定**：`art/visuals/` 资产类目表新增「事件背景板」行（按地域、前期每地域一张），「事件插图」行保留并注明前期不产出。

## 2026-08-25f（`/batch-analyze-new-ideas draft-0823f` · 单草稿切四片并行 · 移出 0 条 · 新增 2 条 · 收窄 3 条 · 补句 3 条）

- **单份草稿按写入面切四片**（ux / combat-service / art / terminology）。Phase A 四片并行只读校验（🔴 6 · 🟠 7），orchestrator 必问过滤后压到 **5 题**：其中 3 条 🔴 经核实是**草稿对既有原文的转述失实**（把「战斗屏没有任何图鉴入口」降级成「按态禁用」· 声称答掉了一条名字不存在的待答项 · 声称服务侧已推广适用面而实则未推），按既有定案直接修正、不出题。
- **interview 中用户主动推翻 / 提出两项，均超出草稿范围**：① **疲劳改为入栈的完全一等条目**（可监听 / 可响应 / 可被取消），推翻「疲劳不入栈、不产生 `PlayResult`」，无限对局风险由既有 `TurnLimit` 封顶；② **`PlayResult` → `ActionResult`**，按玩家动作产生，本次一并做完（补 `UseItem` 签名、`EndTurn` 改为有返回值、枚举扩充、主体字段泛化；抓牌经核不属玩家动作，不纳入）。
- **裁决**：战报展开态在选目标态**禁用**（判据由「有无可供性」改为「是否与决策面争抢**屏幕或语义**」——原判据漏了半屏遮挡维度）· `CombatFeedEntry` **取代** `CardResolved`（用户选择，非推荐项）· `Declared`/`Actual` **两级粒度并存**（状态视图无法重建 `Declared`）· 插画禁文字**收窄为「承载可翻译语义的文字」并提为全类目**（否则砍掉符箓 / 匾额 / 碑文等中式语汇）· 演出 4 s 硬上界**只约束敌人回合**（草稿漏引了既有节奏条的第四项）。
- **跨分片核对的独有收获**：ux 分片发现栈条目已有 `sourceEntryId`，orchestrator 据此裁定沿用；service 分片复核后**推翻该裁定**——该字段实指「载体所在的战场条目」、从不表达因果父，故因果父定名 `CauseEntryId` 是真实缺口而非第二权威。orchestrator 据此回改了 `terminology.md`。
- **落笔面 15 份活文档**：`ux/combat-ux.md`（9 处 `ticker` 清零）· `systems/services/combat-service.md` · `systems/architecture.md` · `systems/scoring.md` · `systems/adventure-event/{common-properties,combat/_index}.md` · `terminology.md` · `program-overview.md` · `art/visuals/**` 四份 · `art/_index.md` · `vision/references.md` · `decisions/ADR-0011`（范例名）· `decisions/ADR-0018`（类型名 + 适用面）。后两者只改被本次改名波及的引用，不动其决定本体。
- **新增待答**：卡牌详情页的内容清单与排布（`01-combat.md`）· 启动式异能没有 API 方法（`05-service-contracts.md`，由 `ActionResult` 重构暴露）。**收窄**：战报条目的文案体系 · 栈与战场的同屏呈现（连锁可读性改由因果树承担，**不移出**）· 疲劳的呈现（收窄到飘字侧）。答定条目记于 `answer-logs/log-0823f.md`（17 条）。

## 2026-08-25d（`/batch-analyze-new-ideas draft-0823d` · 单草稿切三片并行 · 移出 0 条 · 新增 1 条 · 改写 2 条）

- **本次是单份草稿按写入面切三片的批量运行**（货币核心 / 事件与 Exchange / 其余改名面）。Phase A 三片并行只读校验（🔴 2 · 🟠 1 · 🔵 37），orchestrator 合并后发现**两片的推荐互相打架**（币种该写在表上还是写在库存规则上），去重合并为**一题** interview，用户拍板取表驱动。Phase B 三片并行落笔，**改动面 26 份活文档**。
- **单层货币拆为两层，`jade` 标识符整体退役。** 灵石 `spiritStone` 承接原单一货币的全部角色，仙玉 `immortalJade` 是高阶货币、**同为轮回级**（归 `CharacterProfile`、随轮回清理）。**不把 `jade` 改派给仙玉**——库中每一处 `Jade` / `jade` 今天都指基础货币，改派后每一处漏改的引用都静默变成错的意思且无任何机制能发现。落点是纯加法：`CostKey` 15 → 16 值 · `ResourceElements` 加一行 · `CharacterProfile` 字段表加一行（camelCase `immortalJade`，bump schema、老档缺字段取 0）· `currency.md` 扩为双币文档。**「本作没有账号级可支配货币」那条取向的四处承载（付费面排除表 · `player-power` 的「为何不是货币」· `ADR-0023`）语义零改动**——轮回级路线不触碰它。
- **计价币种的书写位定在「族 × 稀有度」定价表上（interview 唯一一题）。** 草稿自陈「加一种支付币种是在既有表上加一列」，实测**前提不属实**：Exchange 全链没有任何币种载体（定价表格值是纯 `int`、`ExchangeOffer` 七格与 `ExchangeStockRule` 五格均无币种格、购买 spec 写死单一币种）。裁定：**格值由 `int` 变为 (支付币种, 基准价)**，`ExchangeOffer` 增一格 `Currency` 作物化快照，`ExchangeStockRule` / `ExchangeSpec` **零字段增量**，内容侧零新增书写位；`CanAfford` / `TryApply` pipeline 确实零改动（本就对 `CostKey` 泛化）。**被否的规则驱动**：币种会成为内容可配，一个填错的条目就把高阶商品变成灵石可买而校验无从判断是否故意；且物品脱离 offer 后无处读币种。**被接受的代价**已写成正面陈述：币种与「族 × 稀有度」绑死，编排不出同档双币与「专收仙玉的商贾」。
- **「完全不可兑换」在售出侧原本有个敞口，随表驱动零机制闭合。** `SellRatePercent` 的折算基准本就取定价表基准价，币种既在表上 ⇒ **卖出所得恒与买入同币**，回收率不会变成事实汇率。「可售出 ⟺ `Kind == CharacterItem`」那条代码级常量判据一字未加。
- **获取与花销不新增任何机制。** 获取 = 稀有 AdventureEvent 产出，走既有 `OutcomeSpec.Elements`：`ResourceKey` 校验集合两处同步扩为五值（含 `future-event-service.md` 正文「四个」那个数字，漏改即两侧断言打架）· 合法子集表加一格。「稀有」由内容侧的出现权重与编排承载，**不加字段、不加加载期校验**。Research 的产出禁令由「不给灵玉」**扩为「不给任何货币」**——两币的价值出口都在 Exchange，不扩会让仙玉从最贵且必然赚的那类事件流出。刷新是店级动作、不落在任何一格上，**恒以灵石计价**。
- **顺手订正两处既有漂移：** `DefeatReason` 的权威是**四值**（含 `FinaleFailed`），`currency.md` 沿用的「三值封闭」已改（只改本次触及的句子）；`profile-service.md` 被草稿归为「纯改名」实测不成立——它是 `ResourceElements` 的逐行权威，本次新增整行并把三处计数 15 改 16。
- **呈现面补两处承载：** 仙玉的非战斗查看落点定为**储物袋单一落点**，而储物袋面板此前只描述道具网格 ⇒ 补「面板内同时呈现灵石与仙玉持有量」，否则该裁决在库中无承载；角色状态条**只常驻灵石、不加仙玉栏位**。表驱动后同一家店可同时出现两种币计价的商品 ⇒ Exchange 价签**必须标明币种**。
- **未动**：`open-questions.md` 的「derive 就绪度」小节（由 `/assess-derive-readiness` 独占，其中多处旧币名已失真，待其下次全量重估）· `.claude/knowledge/` 3 处（归 `/sync-knowledge`）· `handoffs/` · `inbox/archive/` · `answer-logs/` 等过程档案约 146 处旧币名（历史归 git）。
- **移出 0 条**（本次答定的四项均是草稿内部的待决，从未占清单条目，故不建 answer log）。**新增 1 条**（仙玉的获取量与价格量级 → `deferred-content.md`，与灵石那条标注互相约束）。**改写 2 条**（灵石获取渠道条改名；Exchange 四组数值格条追加「定价表逐格还要填支付币种」）。
