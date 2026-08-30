# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

> **只保留最近 10 条。** 更早的条目原样移入 [`update-log-archive.md`](update-log-archive.md)（按时间正序），
> 一字未改、仅换了文件——本日志与归档合起来即全部历史（`decisions/ADR-0005`：台账不无限膨胀）。

## 2026-08-30d（`/summarize-open-questions game` · 全量整理 · 移出 1 条 · 合并 2 处 · 清 3 处失真）

**范围与形态。** 客户端库全量（`vision/` · `systems/` · `art/` · `ux/` + 根级三份），10 份分片逐条对账。**先探明的一件事：本库的主题文档已无一份带 `## Open questions` 小节**——待答项全部集中在 `open-questions/` 分片里，故本次「从主题文档采集散落未决项」一步的产出为零，工作量全在**反向核对**（清单里的每条，主题文档是否已给出定论）。五个子代理并行核对，逐条给证据路径。

**移出 1 条** → `../answer-logs/log-0830.md`：

- **`experiencePoint` 的阈值曲线与产出分布**（`06-meta-progression.md`，标注为「承重」）。四问全部已答：阈值公式 `threshold(L) = 4 + floor((L−1)/2)`（L=12 特例取 10；ch1 合计 79 / ch2 32·38·44 / ch3 38·46·54）· 给予量走 `ExperienceGrade` 枚举 × 平衡表映射（ch1 4 / ch2 12 / ch3 16，与阈值同比放大）· 分布 = **带经验产出点约占事件总数 75%** 且档位偏置逐类给出 · 失败 = 同档 × `FailureRatio`（默认 50）向下取整下限 1。权威在 `systems/balance.md` 与 `systems/game-progression.md`，**清单一直未随之更新**。它的验收侧（「N 次典型失败仍能升满」的 N）仍待答，留在原分片。

**合并 2 处**（同一未知的两个面，文档自身已明写「同批处理 / 同一专场」）：

- `01-combat.md`：「逐项领取后的奖励厚度重估」并入「`RarityTier` 的分布与权重表」作从属项——`systems/balance.md` 明写战后奖励池各档取值与三档奖励厚薄**同批处理**。
- `01-combat.md`：「道具区 / 神通法则条 / 埋伏标记 / 卡牌类型标识的四项具体形态」并入「竖屏分区的整体排布」作从属项——两者本就归同一场已排期的战斗 UX 专场。

**清 3 处失真：**

- `03-adventure-event-types.md`「闭关构筑面板的**三个**数值格」→ **两个**。第三格「`Recuperate` 的 `lifeTotal` 回复量」随 `ADR-0127`（08-30，Accepted）作废——`Recuperate` 整条删除、Research 收敛为纯构筑事件的五类操作，回复只留三通道。分片此前仍在引用一个已被结构性删除的机制名。
- `06-meta-progression.md`「中长期规划感的来源」收窄：**进度感的时间那一半已被经验条常驻承接**（`ux/screen-flow.md` 明写这是本条的一个答复），仍待定的只剩「还有几步到 Finale」那一角。
- `deferred-content.md`「尚未设计（占位）」一节：`player-item/common-properties.md` 与 `achievement/` 均已成文，措辞由「仍是空占位或仅有骨架」改为逐份点名其**唯一剩余的子项**（`status` schema 编码 / 条目 schema 与进度模型）。

**索引侧：** 「最近更新」一行改写；「下一阶段」的 ADR 计数由 **121 份（`ADR-0002`~`ADR-0122`）** 订正为 **131 份（`ADR-0002`~`ADR-0132`）**——08-30c 那次 `/write-adr` 新立的 10 份没同步进这行。`## derive 就绪度` 小节原样未动（`/assess-derive-readiness` 独占）。本文件同批把最早的 4 条摘要（08-25d · 08-25f · 08-26×2）原样移入 `update-log-archive.md`，维持「只留最近 10 条」。

**跨边界：** 反向扫描 08-25~08-30 全部 21 份客户端 handoff 涉及后端义务的部分，逐条在 `backend-design-documents/contracts/` 与其待答清单中找到承载（或 handoff 自行明写「后端零改动」且可检索核实），**未发现「一侧已定案、另一侧零承载」的缺口**，故本次未在对侧库补登任何条目。`cross-boundary.md` 唯一那条待承接项（`ComplianceManager` 覆盖面切分）经核**未关闭**，原样保留。

**报告给用户、本技能不改的 3 处（权威在主题文档，编辑归用户 / `/analyze-new-ideas`）：** `exchange/_index.md` 仍标「ADR 候选，待 `/write-adr` 立档」而 `ADR-0126` 已立 · `game-progression.md` 的待决区未随 `screen-flow.md` 同步收窄「规划感」 · `combat-ux.md` 的意图区与待决区对战报文案体系双重记账。

## 2026-08-30c（`/write-adr game` · 固化 10 份 ADR）

**范围。** 客户端库全量：`## 下一阶段` 登记的 4 条 ADR 候选，外加逐份核对「未被任何 ADR 引为来源」的 handoff 后扫出的散落定案。每条先回主题文档核对事实是否已落地，查无实据 / 矛盾者不立档。

**固化 10 条（`ADR-0123` ~ `ADR-0132`）。** 登记候选 4 条：灵根与功法属性的硬性修习准入（`0123`）· `Artwork` 基数恒为单格 + `CharacterData.RealmArtworks` 稀疏覆写（`0124`）· 二进制资产不经 overlay / blob 下发（`0125`）· Exchange 支付侧二选一（`0126`）。散落定案 6 条：`lifeTotal` 并入 `lifeSpan` 并完全显性化（`0127`，全库最重的一条，波及 30 余份主题文档）· `ProfileChangeSpec` 增 `StatusChanges` 置值列（`0128`）· `HiddenStatGrant` 方向位（`0129`）· `ContentEnabled` 的 flags 第三层覆盖来源（`0130`）· `Upgrade` 类错误只在两处硬阻塞（`0131`）· `StackEntryKind.UsedItem`（`0132`）。

**台账对齐。** `decisions/_index.md` 新增 10 行（最新置顶、同日按编号降序），文件 ↔ 台账零不一致（132 : 132）。`ADR-0121` 的「待答：用道具产生的栈条目落在哪个成员」改为指向 `ADR-0132`；`ADR-0120` 的两条后果补指向 `ADR-0124` / `ADR-0125`；`ADR-0055` / `ADR-0052` / `ADR-0050` 补上漏写的来源 handoff。`## 下一阶段` 的候选清单清空。

**未固化 2 条**（已被既有 ADR 覆盖，只补来源行、不新开编号）：「购买次数不设 `StatKey` 成员」（`ADR-0050` 正文已点名本例）·「角色模板池首批 5 个 / 全池指定 / 不做账号级解锁」（`ADR-0055` 后果段已逐字写入）。

## 2026-08-30b（`/batch-analyze-new-ideas` · inbox 剩余两份 solution-draft · 合并 interview 3 题）

**范围与形态。** 客户端库 inbox 顶层清空：疲劳扣减是否进 `EncounterSpec` 覆写组 · 用道具的栈条目类型。Phase A 两分片并行只读校验（🔴 1 · 🟠 0 · 🔵 21），跨草稿核对确认两者虽同写 `combat-service.md` 但小节不重叠、结论不矛盾，Phase B 串行落笔。合并 interview 3 题（1 项真冲突 + 2 项此前标「采纳推荐 — 待复核」的确认题）。

**答结 2 条 · 新增 1 条。**

- **疲劳扣减维持不进 `EncounterSpec` 覆写组，也不开 `EncounterTighten` 第六格。** 三条既有理由重估：① 仍成立且被加强（削堆条目只是又一个**内容侧**决定因素，档位侧仍是零条）· ② 未被削弱（「`MoveCard` 能搬对手抽牌堆」本就写在该理由正文里，不是新事实；重开判据 ① 要的是**已签核条目**，而 `content/` 零条目 ⇒ 字面未触发）· ③ 结论不变、论据换成「常规抽牌预算已被覆写组三格 + `Tighten` 两格覆盖，`DrawEffect` 能抬高实际次数但逐条有限，终止性归 `TurnLimit`」（原论据靠「极端不会发生」取信，不再可靠）。**新增第 ④ 条否决论据「方向不单调」**——疲劳打抽牌方而非玩家，正向 delta 对小卡组加压、对大卡组送礼，过不了 `EncounterTighten` 的全序 + 单调难度方向判据；它同时是五格封闭性的第一个具体实证。原重开判据 ②「某遭遇档需显式调节疲劳压力」由**三条既有承接通道表**取代；判据 ① 收紧为「`Pool` 覆盖敌人侧 · 以削堆为主要效果 · **已签核** · 密度足以让一方在 `TurnLimit` 前 40%（待实测占位）内空堆」，并明写**结构可写性不构成触发**。零字段零数值零存档。
  - **🔴 裁决：`ADR-0052` / `ADR-0077` / `plot-manager.md` 三处「无覆写基准可拧」措辞一处不动。** 草稿称该句「读起来是错的」，但 `ADR-0052` 破折号从句已界定此处指 per-encounter 基准，且 `FatiguePerDraw` 在两份 ADR 落笔时已是具名常量 ⇒ 无新事实支撑改写。新论据只进 `balance.md`，与既有论据并行共存。
  - **确认：`ModifierTarget.FatigueAmount` 保持双向、不加方向约束**（落地面零动作；`deck/common-properties.md` 因此不改）。
- **用道具的栈条目类型：`StackEntryKind` 增第五个成员 `UsedItem`。** 不复用 `ActivatedAbility`（复用会让 `sourceEntryId` 与 `abilityId` 两格同时变可空，抹掉该成员全部不变式）。连带：栈条目**新增 `itemId` 一格**（与 `kind == UsedItem` 互为双向不变式）· `CombatFeedKind` 增 `ItemUse`、战报引言五类 → **六类**、`## 决策(-> ADR)` 的「四类共用」同改 · 读档校验 ② 扩入栈条目 `itemId`，并写明 **②/⑥ 分档**（`CombatItemSave.ItemId` 走 ⑥，被丢弃时该栈条目照常结算）· 存档「新增字段一格」改为**两格** · `UseItem` 段补齐 **mana 扣费与 `InsufficientMana`**（`ItemData.ManaCost` 早已存在，是既有缺口）与入栈填法、敌人侧路径 · `card.played` 不由 `UseItem` 广播，`deck/common-properties.md` 校验表新增第 20 条软检查。
  - **确认：`TimingIds.ItemUsed` 不开**（时点随广播点增长，当前无内容需要它；开它要给 `SubjectKind` 增一档并扩 `TriggerFilter` 相容矩阵，日后是纯加法）。
- **新增待答（01-combat「结构与配置的残留」）：`MoveCardEffect` 缺一格方位声明**——`ADR-0119` 断言 `From` 可取对手抽牌堆，但原语表未给它 `Side : SideConstraint`，而同表另五个原语逐个都有。「削减对手抽牌堆」在字段面尚未闭合；三种收法各有代价，需一次独立推演。
- **承接项（交 `/write-adr`）：** `ADR-0121` 末行「待答：用道具的栈条目落在哪个成员上」已失效，应在固化本决策时清理。`decisions/` 本批零改动。

## 2026-08-30（`/batch-analyze-new-ideas` · 一次提炼六份 decided 草稿 · 合并 interview 15 题 · 跨库 1 对）

**范围与形态。** 客户端库六份草稿一次清完（寿元合并 · 灵根与角色池 · Artwork 基数 · 以物易物 · flags 缓存），其中 flags 那份与后端库同名草稿**成对落笔、互相回链**。Phase A 五个分片并行只读校验（🔴 18 · 🟠 8 · 🔵 74），复核降级 3 项后合并去重为 **15 题**，分四轮问齐后才落笔。

**答结 8 条 · 新增 8 条 · 改写既有条目 14 处。**

- **寿元合并（最重）：** `lifeTotal` 整体并入 `lifeSpan`，寿元**退出隐藏属性体系**（Band 门控整体退役、明文常驻恒精确）。结构收缩：`DefeatReason` 4 → 3 · `CostKey` 16 → 15 · `OutcomeDirection` 5 → 4 · `Status` 子表 12 → 9 行 · 隐藏属性 12 → 9 档 · Research 六类操作 → **五类**（`Recuperate` 退役，直接改写 `ADR-0022`）。负侧换算 ch1 = 1 + 一维 `lossPerMomentum`（按篇章，三个 `combatTier` 共用；形状锚 8%–12%）。`life-total.md` 退役 → 新建 `life-span.md`；`ADR-0045` 连文件名一起改挂寿元。
  - **接受的取向三条：** 失败正反馈螺旋（grimdark 滚雪球，`FailureRatio` 保持 50%）· 寿元预算从此可被玩家精确规划 · 压力线由两条并为一条。
  - **保结论、改理由六处：** `ADR-0016` 减档禁令射程收窄为「不得为文案密度而减档」· `ADR-0081` 管辖收窄为道心 / 煞气，「寿元战斗内不读写」升格为落 `life-span.md` 的资源纪律 ·「1:1 不得分档」收窄为「不按 `combatTier` 分档」· 境界基线公式删除但赋级带 `±2` 与层数散布 `±1 档` **取值全不变**、改挂非数值理由且护栏整条迁往 `enemies/_index.md` ·「战斗内回寿道具 → 拒」换新理由（防 StS 式 HP 战从后门回来）· `profile-service.md` 明写两条组装纪律。
  - **`pillars.md` 第 9 条不松动**：Explore 的定价指纹泄漏改由「Explore 行的独立定值」恒常堵死，护栏由呈现门控升为定价结构。
  - **跨档叙事不做补偿**：余量已明文常驻 ⇒ 预警型文案失去存在理由，寿元三条 Band 文案条目一并删除，「大限将至」不另找载体；终态 `DefeatReason` 呈现照旧。
- **灵根与角色池：** 五行 `Affinity` 挂 `CharacterData`，功法侧 `RequiredAffinities` / `MaxCharacterAffinityCount` 构成**硬性修习准入**（契合度三态 / 层数折减 / 取池加权全部否决）。角色池**全池指定 · 规模 5**（覆盖 08-28 的 4）。**`CharacterData` 字段表首次成文**（六格 + 十一条加载期校验）。撞名回避：AI 侧 `KeyCardAffinity` → `KeyCardBias`（四处）。
- **`Artwork` 基数收口：** 恒为一条内容一格，境界维度不进该字段；敌人与其余五类不换相，玩家角色随境界换（稀疏 `CharacterData.RealmArtworks` + 两级回落）。「境界越高画面越沉」收窄为**按条目自身的叙事定位取沉**（`ADR-0100` 与 `art-direction.md` 同改）。`common-properties.md` 的 ⚠ 前置依赖行删除。
- **以物易物落地：** 支付侧二选一（货币 element 或点名的轮回级法宝），定值不经取池链、不掷 `Shop`、不参与刷新与三道闸；白送漏洞以门面 `Holds()` 前置拒绝堵死，**不扩 `CanAfford`**；新增 `Source.ExchangeBarter = 10`；不持有 → 灰显 + 支付要求可见 + 一条 `EVENT_` 说明。
- **flags 缓存 + 二进制不经 overlay（跨库成对）：** `flags.json` 补 `schemaVersion` 与写入时点；overlay 只承载 `.tres`；后端补 `no-cache` 层次澄清与零义务表、新增「blob 通道不承载二进制资产」一节，并纠正 `ADR-0002` 里同一句「以支撑离线开局」的错误前提。
- **新增待答项 8 条**：`01-combat.md` 1（赋级带是否可放宽）· `06-meta-progression.md` 4（角色强度塌缩 / 多灵根换算 / 绑定功法初始层数 / 失败螺旋容错量）· `deferred-content.md` 3（`lossPerMomentum` ch2/ch3 · 回寿量三档点数 · 通用功法占比）。
- **新增 ADR 候选 4 条**（见索引「下一阶段」）。**旧 answer log 一份未改**，被取代的结论只在新 log 里登记取代关系。
- answer logs：`log-life-lifespan-merge.md`(2) · `log-character-template-pool.md`(1) · `log-realm-progression-artwork-basis.md`(2) · `log-exchange-barter-support.md`(1) · `log-client-flag-cache-and-binary-overlay.md`(2，对侧同批 2)。

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

