# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

> **只保留最近 10 条。** 更早的条目原样移入 [`update-log-archive.md`](update-log-archive.md)（按时间正序），
> 一字未改、仅换了文件——本日志与归档合起来即全部历史（`decisions/ADR-0005`：台账不无限膨胀）。

## 2026-09-12b（`/summarize-open-questions --lib=game` · 全量整理 · `/progress-sync` 波次 3 · **移出 0 条** · 归拢 1 · 索引导航订正 3 · 矛盾登记 1 · 单库）

- **范围：** 该库全部主题文档区（`vision/` · `systems/**` · `art/**` · `ux/` · `narrative/` + 根级横切 3 份，**79 份 `.md` 全量机械提取 `## 待决问题` 小节**）+ `handoffs/` 未 `distilled` 项（唯一 `raw` 是示例占位 ⇒ 无未消化输入）+ 现有 8 份问题分片 + `answer-logs/` 全量文件名。**无人值守口径**：不 interview、不裁决，判不准的一律原样留下并进报告。
- **移出 0 条，故本次不建 answer log。** 逐条比对后确认：清单上的每一条在其权威主题文档中**仍无定论**。本波次前两轮（`/write-adr` 固化 16 份 ADR、`/assess-derive-readiness` 重估）**均未产生新的答定** —— `/write-adr` 只把已落进正文的决策补上编号，不改变任何待答项的状态；`ADR-0276` 更明写「在售窗口的具体承载形态**仍未定**」。
- **归拢 1 条（跨主题文档同题合一）：** `systems/character-profile/_index.md` 的「首批付费系列的 `SeriesId` 取值、系列名与五行构成」与 `systems/monetization.md` 的「各系列的具体名字与主题」是**同一个待决点**（同一前置：`narrative/` 世界观底稿），合并进 `06-meta-progression.md` 那一条，三份主题文档一并回链。
- **索引 `## 分片导航` 订正 3 处（描述与分片实况脱节）：** ① **②** 的描述仍列着七个主题，而该分片**只剩两条**（事件类型配比实测校准 · `LocationCodex` 词条深度）—— 改为如实列出；② **④** 的描述仍写「逐条目的推拉映射与两条剧情线的具体内容」为待答，而推拉触发已于 09-09 答结、余下是纯内容编排工作量 —— 收窄为**只剩三条**；③ **⑥** 的描述把「胜侧 `experiencePoint` 单价是否计入供给账」列为待答，而它已于 09-10 答结移出（`answer-logs/log-experience-supply-accounting.md`）—— 删去该项。
- **矛盾登记 1 条（`deferred-content.md`「数值标杆的取值」条内）：** 回寿量三档绝对点数上 `systems/balance.md:1240`（「折算不等于定案、仍欠取值」）与 `decisions/ADR-0248` + `systems/character-profile/life-span.md:50`（**50 / 100 / 200 已写死**，且该文档 `## 待决问题` 明写「无」）**正面相抵**。本清单**不裁决**：条目保留在待答区并加 ⚠ 标注与解读（大概率是 `balance.md` 陈旧措辞未清），待用户确认后方可移出。
- **`cross-boundary.md` 一处陈旧句订正：** 账号身份模型那条基线里「余下的 `deviceId` 落点与 refresh token 持有形态是本库自己的待决问题」—— 两条分别已于 08-19 / 08-22 答定，改为指向对应 answer log。**「待承接」仍为 2 条**（`backend ADR-0051` / `ADR-0052`，均 09-07 定案、连续三版一字未动，落点同为 `systems/services/content-service.md`）。
- **跨边界零新欠账，无需转交对侧库。** 本批 16 份 ADR 中涉及边界的 9 份（`ADR-0269` ~ `ADR-0277`）其后端半已于 09-12 同批落笔（`backend-design-documents/contracts/purchase.md` · `profile-sync.md` · `operations/purchase-ops.md` 均已命中 `characterSeries`）；`ADR-0278` ~ `ADR-0284` 为叙事分区，对后端零义务。故本次**未在对侧库补登任何条目**。
- **`## derive 就绪度` 与 `## 下一阶段` 两节一字未动**（分属 `/assess-derive-readiness` 与 `/write-adr` 独占写入）。
- **台账对账：** `open-questions/` **10 份文件 ↔ 索引分片导航 10 行**；`answer-logs/` **181 份 log ↔ `_index.md` 181 行**（台账表混用两种行式 —— 旧行 `` `log-x.md` ``、新行 `[log-x](log-x.md)`，两式合计恰好 181，零缺口零重号；**仅为版式不一，未强行统一**）。`update-log.md` 保留最近 10 条，溢出的 2 条（09-10 `/write-adr` · 09-09 `/batch-analyze-new-ideas`）原样移入 `update-log-archive.md` 尾部并按时间正序排好。

## 2026-09-12（`/write-adr game` · 范围 `all` · 固化 16 份 · 就地改写 1 份 · 候选清单零变动 · 单库）

- **范围：** 候选清单（`## 下一阶段`）**当时为空**，本次全部来自第 2.4 步逐份核对「未被任何 ADR 引为来源的 handoff」——扫出 5 份未引用 handoff，其中 3 份判定不建档（`2026-07-12-example` 模板示例 · `2026-08-02c` 意图族已被 `ADR-0059` 整条推翻 · `2026-08-12b` 已由 `ADR-0051` 承载，三份均沿用 09-07 的既有判定），实际来源为 09-12 的两份：`2026-09-12-premium-character-series-unlock.md` 与 `2026-09-12-series-packaging-and-narrative.md`。
- **固化 16 份新 ADR（`ADR-0269` ~ `ADR-0284`），全部 `Accepted`、日期均 2026-09-12：**
  - **付费角色系列的解锁与购买形态 9 条：** `ADR-0269`（`CharacterData` 加 `SeriesId` + `Track`，哨兵枚举而非 `bool`，配校验 #14~#18 与两条「不做」）· `ADR-0270`（`PlayerEntitlement.CharacterSeries` 只由后端写、无客户端通道、不配水位；`schemaVersion` v2 本库第一次真实 bump）· `ADR-0271`（回声路径「老档缺字段」分迁移 / 读档两时点，对 `Cosmetic` 同款适用）· `ADR-0272`（解锁过滤落 `GetSelectableCharacters()`，绝不落 `ContentRegistry`）· `ADR-0273`（`Track == Paid` 禁止永久退役、flags 临时关闭允许）· `ADR-0274`（购买段复用、**兑现段整段不存在**、跨启动补入口两条、购后不阻塞开新轮回）· `ADR-0275`（在售清单由内容层自给走 `AllIncludingDisabled()`、`productId` 机械变换、前置条件表两段化 + 三行）· `ADR-0276`（限时在售窗口三条语义：不绝版 · 已购永久可用 · 不进存档）· `ADR-0277`（推销面穷举：Store 三结果态、角色选择屏完全不出现未拥有项）。
  - **系列包装与叙事承载 7 条：** `ADR-0278`（新建顶层 `narrative/` 分区）· `ADR-0279`（碎片 lore 只撒轮回内、不进图鉴；与支柱 9 的边界）· `ADR-0280`（冷的残缺文献体；素语射程收窄为框架 / 系统文案）· `ADR-0281`（交叉纯隐式、成就不为 lore 串联开条目）· `ADR-0282`（系列 = 世界观切片、零规则强制；建 `CharacterSeriesData`）· `ADR-0283`（剧情不是付费面）· `ADR-0284`（推出次序：先付费进阶批、双灵根免费批在后）。
- **就地改写 1 份，不新增编号：`ADR-0255` 的棘轮由单向改双向。** `Free → Paid` 与 `Paid → Free` **都是违规**，`Track` 发布后完全不可变；禁反方向的理由是本作**没有补偿通道**。承「改决定直接改 ADR」，标题 / 决策 / 后果三处同改并同步 `decisions/_index.md` 该行标题；同时把该 ADR 原写「解锁载体归 `/provide-solution-draft` 推演，首批一格不落」改写为指向本批 8 份 ADR 的回链（推演已兑现）。
- **一条判定不建档（查无实据，原样留在报告）：** 「首批五角 = **互不相干的五个独行者、共享同一套世界观架构**」——该措辞在全库主题文档零命中，只活在 `inbox/archive/` 草稿与 handoff 正文；`narrative/_index.md` 从未点名首批五角的相互关系。其**另一半**（交叉是内容层编排义务）已落地并已由 `ADR-0281` 承载。
- **候选清单零变动**（本就为空，无条目可移出）；`## 下一阶段` 只更新 ADR 计数（267 → **283** Accepted）与追加本次运行摘要。**`derive 就绪度` 小节一字未动。**
- **台账对账：** `decisions/` **284 份文件 ↔ 284 行**，零孤儿、零悬空、零重号；`decisions/` 内 `单向棘轮` grep 零残留。
- **落笔前必清的两处陈旧副本（本技能范围外，交用户 / `/analyze-new-ideas` 处置）：** ① `terminology.md:123`「角色系列」词条仍写「『一旦免费永不改付费』是**单向棘轮**」，与 `character-profile/_index.md:102` 及 `content/character/_index.md:55` 的双向口径相抵；② `systems/monetization.md:196` 仍写「付费解锁角色系列……**ADR 候选待 `/write-adr` 立档**」，该批已于本次立档。

## 2026-09-12（`/analyze-new-ideas game` · design-draft-monetization-packaging-and-narrative · 移出 2 全条 · 新增 3 条 · 推翻 0 项 · 单库）

- **范围：** `inbox/design-draft-monetization-packaging-and-narrative.md`（`/design-direction-interview` 09-12 专场，十轴定案）→ `handoffs/2026-09-12-series-packaging-and-narrative.md`。逐轴裁决视同用户当面拍板，未重问；张力区为空，**未改写任何 ADR**。
- **移出 2 全条（均出自 `06-meta-progression.md`）→ `answer-logs/log-monetization-packaging-and-narrative.md`：** ① **推出时点与主题包装**（次序 = 先单灵根五角进阶付费批、双灵根免费批在后；系列 = 世界观切片、对成员零规则强制）· ② **付费角色与专属剧情的关系**（**剧情不是付费面**，两轨道叙事待遇一视同仁）。
- **一项库结构变更：新建顶层 `narrative/` 分区**（与 `vision/` · `systems/` · `content/` · `art/` · `ux/` 平级），放世界观设定 / 时间线 / 人物关系 / 碎片台账。它是**内部事实源、不是玩家可见面**——碎片 lore 只撒在轮回内、读过即过，不进图鉴、不做可回看档案面。连带两处结构登记同改：本库 `README.md` 文件夹图例、`.claude/rules/design-library-routing.md` 两库结构差异表（该表明写两库结构变更时须同改）。
- **一个内容类型开张就绪：`CharacterSeriesData`**（`Id` + `LocalizedText` 名称 + `LocalizedText` 概述 + 可空 `Artwork`，**无规则字段**）。`character-profile/_index.md` 原写「现在不建该内容类型」的悬置理由（主题包装未定）**已达成**，那处改写为字段面与校验；`content/_index.md` 类型登记表加一行（🟢 · 未开张），依赖链加一支。**开张仍需一轮 `/scaffold-content-type character-series`。**
- **加载期校验 +2：** `PlotArcData.CharacterIds` 悬空 → `PushError`（唯一一格此前无处置的引用）· `CharacterData.SeriesId` 悬空 → `PushError`（建类型后才有对象）。系列层既有两条（条目数 ∈ {5, 10}、`Track` 一致）不变。
- **三处笔误订正：** `character-profile/_index.md` 两处与 `player-profile/_index.md` 一处写作 `PlotNodeData.CharacterIds` → **`PlotArcData.CharacterIds`**（schema 权威把它放在 arc 上；gating 落 arc 才与「arc 是激活单元、node 是步骤」自洽）。`handoffs/` 与 `answer-logs/` 中的同一写法**未改**（会话档案）。
- **素语纪律的射程被澄清（不是修改）：** 框架 / 系统文案仍是纯数据陈述；lore 与剧本正文另属一档——冷的残缺文献体，允许语调与暗示但情绪必须冷、不用第一人称 ⇒ 「全作唯一一处第一人称是那三句终结台词」不破。支柱 9 与 lore 的边界同批写进 `pillars.md`：lore 不可换取、不影响决策、不进图鉴，不属支柱 9 管的「情报」。
- **新增 3 条：** `04-hidden-attributes-plot.md` 两条（**角色专属 SideStory 的激活口** —— 专属剧情一视同仁地铺已定案，而现有两条 arc 激活通路都不覆盖它；**`CharacterIds` 的 gating 语义**；两条同批归一次 `/provide-solution-draft`）· `deferred-content.md` 一条（`narrative/` 的内部结构与世界观底稿）。另 `06-meta-progression.md`「在售窗口的内容层承载形态」**收窄半条**（「类型建不建」已答定，剩 `CharacterData` / `CharacterSeriesData` 两个载体择一）。
- **零 schema 改动、零存档增量、后端零影响**（`CharacterData` 是模板、不落存档；`CharacterSeriesData` 同理）。

## 2026-09-12（`/batch-analyze-new-ideas` · 5 份已评审草稿 · 移出 4 全条 · 新增 1 条 · 推翻 1 项 · **跨两库**）

- **范围：** 客户端 4 份 + 后端 1 份（其中付费角色系列是一对 counterpart，成对提炼、两侧互相回链）。三个 worker 单波次并行，run 目录 `.claude/batch-runs/2026-09-12-five-reviewed-drafts/`。**五份草稿的取向项已于 2026-09-11 批量评审全部裁定并写回草稿正文，本次视同用户当面拍板：无 Phase A、无合并 interview、零重开。**
- **移出 4 全条 → 四份 answer-log：** ① `01-combat.md`「**灵石账 `I(ch1)` 与战斗场数口径**」（含三条子项）· ② `01-combat.md`「**`EncounterTighten` 三格牌流量的六个界常量取值**」· ③ `01-combat.md`「**法宝置换在上层 ≈1.0 分子里占多少份额**」· ④ `06-meta-progression.md`「**付费角色系列的解锁载体与购买流程形态**」。
- **推翻 1 项（结构层）：`EncounterTighten` 五格 → 四格。** 手牌上限恒 7、**不可被剧本改动**，`MaxHandLimitTighten` / `MinHandLimit` 两常量**取消**（不存在，而非取 0），十常量表 → **八常量表**，手牌上限降为普通全局平衡常量。按根约定「决策可被推翻，以最新用户意图为准」**就地改写 `ADR-0077`**（不新开取代 ADR、不留考古句），`decisions/_index.md` 该行标题同改。连带收口 `plot-manager.md`（删 `HandLimitDelta` 字段与合并算子行）· `future-event-service.md` · `combat-service.md` · `ADR-0081` · `ADR-0183` 的悬空引用。
- **两处授权订正（只改数字、决定与理由链一字不动）：** `ADR-0247` 的 `I(c)` ≈127/300/480（ch1 占 31%）→ **150/300/480（27%）**；`ADR-0134` 的战斗场数 7/8/8 → **11/11.9/14**。`handoffs/` 与 `answer-logs/` 中的 `127` **一处未改**（会话档案，且在当时口径下可完整复算）。
- **一次预算重新配平（不是填空）：** 法宝一族份额 ≈0.35 只能从已占满 ≈1.0 的既有三支里割 ⇒ **守住 ≈1.0 天花板、其余三支等比压缩 ×0.65**（神通 ≈0.32 · 法则置换 ≈0.20 · 法则禁用 ≈0.13）。落位**并入既有支、不开第五行**——原「神通置换 + 禁用」行改写为「**轮回级能力损失**」一支内部分列 ⇒ `ADR-0265`「不扩为五支」逐字成立。已接受的代价：法则禁用 0.13 略低于 `ADR-0161` 判为「几乎不可见」的 0.143（用户在评审中已知悉并选定）。
- **跨库对称落笔（付费角色系列）：** 客户端落解锁载体与购买流程（`CharacterData` 两格 · `PlayerEntitlement.CharacterSeries` · 取池过滤 · **`schemaVersion = 2`** 本库第一次真实 bump · Store 三结果态），后端同批落 SKU 粒度与机械变换、验票写入、`profile-sync` 两张表各加一行（**后端写入字段封闭表成文以来首次扩表**）、兼容矩阵版本行。两侧各一份互相回链的 handoff，`cross-boundary.md` 两侧各记一条对账基线，**两侧无遗留欠账**。
- **评审中新增的一条机制：付费系列有购买时限（限时销售窗口）。** **不绝版**（窗口关闭后可重上架或转常驻仅失去限时优惠价）· **已购玩家永久可用**（下架的只是购买入口）· 限时的是价格与销售节奏、不是可得性。客户端侧落为内容层属性（零新增下发面），后端侧落 SKU 表一格 + verify 侧拒绝窗口外新购；**窗口不进存档、不进 `PlayerEntitlement`**。
- **新增 1 条 → `06-meta-progression.md`：** 付费系列「在售窗口」在内容层的具体承载形态（落 `CharacterData` 一格、还是随日后可能建的 `CharacterSeriesData` 给出）。同分片「双灵根批与付费系列的推出时点与主题包装」一条**补上依赖说明**（首批 `SeriesId` slug / 系列名 / 五行构成在它答定前无法定稿）。
- **`01-combat.md` 的一处悬空指向已修**：「道具的种类目录本身」条末句原写「见下一条」，所指条目本次已移出。
- **一处以直读裁决的事实矛盾（worker 报告有误，未采信）：** W1 报称 `balance.md:237` 的 `R_event,1` = 67 与 handoff 的 66 矛盾、按 Σ 恒等「应为 66」。**直读 `:238` 后为准**：正文 `R_item,1` 记的是 **33**（不是 worker 引用的 34），`33 + 67 = 100` ⇒ Σ 恒等**成立**，且与当前回代式 `:376` 的 `33.1` 取整一致；handoff 的 66/34 是旧回代值 `33.9` 的取整。**正文无误，一字未改。**
- **一处用户授权的例外落笔：** `../open-questions.md` `## derive 就绪度` 小节（本属 `/assess-derive-readiness` 独占写入）中，「付费角色系列的后端承接零承载」与「后端库 `cross-boundary.md` 的待承接为空」两句已随本批闭合而过期，经用户点名授权作**纯机械订正**，不重新评估任何就绪度判定。
- **零 schema 改动来自前三份**；付费系列那份带来本库第一次真实 `schemaVersion` bump（v2）+ 一个 v1 → v2 迁移器 + 一份 golden 快照的待建项。
- **收尾时用户裁决的两项（本批呈报的未闭合项，同批落笔）：**
  ① **手牌上限任何编排面都动不了** —— 不止剧本，**事件模板也不能覆写**：`EncounterSpec` 的可空覆写组由**四格减为三格**（`InitialDraw` / `DrawPerTurn` / `EnemyManaLimit`），`HandLimit` 一格删除；`combat-service.md` 的 record 定义与覆写组表、`future-event-service.md` 的物化代入面（代入五格 → **四格**）、`plot-manager.md` 的措辞、`balance.md` 的手牌上限行与「不进覆写组」理由条、`ux/combat-ux.md` 的 `n/7` 呈现（原写「由 `EncounterSpec.HandLimit` 覆写驱动」，该字段已不存在 ⇒ 改为恒取全局常量、呈现侧仍不写死 7）逐处收口。
  ② **`ADR-0161` 备选段的否决理由改写** —— 「每 7 轮回一次 ⇒ 几乎不可见、等于机制不存在」**不成立并被撤下**：本作是 roguelike，玩家反复开轮回，**小概率事件在深度游玩下必然发生**，可见性不由单轮回概率判定。该备选（合计取 ≈0.83）仍否决，但理由换成「总额是承重表述，压低它会同批压低全部持久支」。`player-power/_index.md` 的「已接受的代价」一段随之改写——法则禁用 0.13 / 神通禁用 0.11 **不再被记为可见性代价**。

## 2026-09-11（`/analyze-new-ideas game` · design-draft-failure-and-punishment · 移出 2 全条 · 新增 0 条 · 推翻 3 项 · 单库）

- **范围：** `inbox/design-draft-failure-and-punishment.md`（`/design-direction-interview` 09-11 专场，十轴定案）→ `handoffs/2026-09-11-failure-and-punishment-identity.md`。逐轴裁决视同用户当面拍板，未重问。
- **触发了一轮 interview（草稿自陈「张力：无」，与事实不符）。** 轴 6「`EnemyCodex` 写到招式与行为模式级」的后果句「每个敌人须写清会出什么牌」与两处既有承重决策直接相抵：`enemy-codex.md` 的「慷慨度维持『关键卡 3 张、不给样本卡组完整列表』」及其退让阶梯，以及 `ADR-0095` 的**理由承重段**（功法图鉴不列卡表，正为封住「敌人词条 → 功法图鉴」的反查通道）。分两轮问齐 4 题。
- **推翻 3 项（用户裁决）：** ① 敌人词条**由五项改四项**——「关键卡牌」一格撤销，词条②由「主功法」单引用改为**核心功法引用列表**（多门、不含层数）；② **`ADR-0095` 就地改写、不新增编号**——功法图鉴词条**列出逐层卡表**，反查通道由被封堵改为**设计目标**（它是「同一个敌人第二次遇到就该能打赢」最强的兑现形式），台账行标题与影响文档同改；③ 敌人词条的**一屏纪律让路**——③④ 不设字数上限、总长 150–280 字上限撤销、词条页允许纵向滚动。
- **未松动的三条（明写防连带推翻）：** 图鉴**战斗中一律不可查** · 词条**不含动态情报** · 词条正文**绝不写等级**（后者是反查界的承担者：层数提升是整组替换，故反查只能停在「这门功法大致长什么样」）。
- **`EnemyData.KeyCardIds` 字段保留、职能收窄为仅供敌人 AI 的 `KeyCardBias`**（用户裁决取推荐项）；`ADR-0113` / `ADR-0090` 零改动，两处「它是图鉴数据源」的理由句改写。
- **移出 2 全条 → `../answer-logs/log-failure-and-punishment.md`：** ① **`lossPerMomentum` 的 ch2 / ch3 系数**定为 **5 / 10**、三章三格全为定值（形状锚逐格 9% / 10.0% / 11.3% 通过；走恒定占比而非递进；N = 2、21 格定价表、λ 台账零改动）——`balance.md` 与 `life-span.md` 的待决条同批删除，`deferred-content.md` 的从属项一并移出；② **赋级带 `±2` 与层数散布 `±1 档` 维持不放宽**，依据换挂**可归因性**（遇到超纲敌人而输不属于「你哪步错了」），`01-combat.md` 与 `balance.md` 两处同批删除。
- **十项方向裁决（视同用户拍板）：** 失败是代价不是学费 · `lossPerMomentum` 恒定占比 · 主要可归因于决策 · ch1 的死就该这么轻（不加软代价） · 角色第一人称终结台词 · `EnemyCodex` 招式与行为模式级 · 进入 ch2/ch3 明示剩余重试 · 赋级带维持 ±2 · 台词射程只在终结 / 三因各一句 / 只给死亡 · 台词以外一律素语。
- **十一项标准默认（未出题、直接落笔）：** `DefeatLines` 稀疏数组 + `LocalizedText` · 缺项 `PushWarning` + 省略台词位 / 重复 `Reason` `PushError` · 台词不落存档（ViewModel 呈现期对象） · 首批 15 句归内容层 · **轴 7 不新增屏**（落篇章切换面的 `ongoing` 篇章行，三条键与弃置确认共用口径） · 深度加厚不开战斗内查询入口 · 素语不改 `ERR_*` 机械变换规则 · **素语射程限于框架文案**（不覆盖事件正文 / 跨档叙事 / 定性文案 / 敌人台词） · 「全作唯一开口处」精确到**可玩角色侧**（`EnemyData.Lines` 不受影响） · `Discarded` 定性文案仍留空（与台词两格并存） · 台词位无配音 / 无逐字动画 / 无第二次音效。
- **顺带清理的陈旧副本 8 处**（推翻 ①②③ 的连带）：`terminology.md` 两行（敌人图鉴 / 功法图鉴）+ `EnemyData` 行 · `combat/_index.md` 两处（AI 偏向关键卡的理由句 · 决策段的慷慨度行） · `enemies/common-properties.md` 两处（五项词条 → 四项 · 关键卡校验理由改写并补 `CoreTechniqueIds` 校验） · `future-event-service.md` 两处 · `codex/common-properties.md` 两处（小节标题 · TechniqueCodex 那条） · `ux/screen-flow.md` 三处（词条载体分野 · 战斗前确认页摘要区 · `CodexEntryScreen` 行）。
- **零结构改动（除一格字段）：** 新增 `CharacterData.DefeatLines` 与 `EnemyData.CoreTechniqueIds` 两格**模板静态字段** ⇒ 零 schema / 零迁移 / 零存档增量 / 零契约 / 后端零配合（不跨库，后端库一字未动）。
- **`## derive 就绪度` 小节原样未动**（归 `/assess-derive-readiness` 独占写入）。

## 2026-09-11（`/summarize-open-questions --lib=game` · 全量整理 · `/progress-sync` 波次 3 · 移出 1 部分 · 去重 1 · 合并 1 · 新增 2 · 单库）

- **范围：** 客户端库全量（`vision/` · `systems/**` · `art/**` · `ux/` + 根级三份 + `content/_index.md`，共 76 份主题文档）+ 全部 8 个分片 + `handoffs/`。三个只读采集代理并行：`systems/`（51 份含待决小节）· `vision` / `art` / `ux` / 根级 · ADR 闭合核验（`ADR-0248` / `ADR-0255` ~ `ADR-0268`）。`handoffs/` 无 `raw` / `triaged` 件（唯二命中是 `_TEMPLATE.md` 与 `2026-07-12-example.md`）⇒ 无未消化输入。
- **移出 1 条（部分）→ `../answer-logs/log-0911.md`：** **每章回寿事件次数** 答定为「每章 1 次小档 + 点名给回寿法宝的事件产出补足至本格，三章统一不加 ch3 例外」（`ADR-0266`，权威落 `systems/balance.md`「λ 的反推式」）。同一条目里的**回寿三档绝对点数仍留清单**。
- **去重 1 条：** `03-adventure-event-types.md` 的 Explore 由三格并为两格——「定价表 `Explore` 行的取值」是真身占比的下游、且该行已有取值，不是独立待答项。同处**订正一个陈旧读数**：清单原写「现有 37 / 40 / 101」，那是篇章时长重标定**之前**旧 λ 下的值；现行权威是 `systems/balance.md` 21 格定价表的 **24 / 27 / 70**（`t = 1.6`）。
- **合并 1 条：** `01-combat.md` 的「`I(ch1) ≈ 127` 账目缺口」与「战斗场数三个并存读数」并为一条带两个从属项的条目——两者共用同一格输入「胜场数 × `E[道念差]`」，分开裁必然互相推翻（两条原文本就各自写着「同源、宜同批」）。
- **改写 1 条：** `03-adventure-event-types.md` 的 Travel 定价由「未填格」改为「已有初值 **6 / 7 / 18** 待实测校准」（`t = 0.4`，`Travel ÷ Exchange` 落在 1/3 ~ 1/2，见 21 格表的七条自校验）。
- **新增 2 条（均为主题文档已登记、此前未进清单的项）：** ① `01-combat.md`：**法宝置换在「失去能力」上层 ≈1.0 分子里占多少份额**——`ADR-0265` 定了归账（并入上层分子 · 不适用自持口径 · 四支枚举不扩为五支）却自陈份额本身待裁；② `deferred-content.md`：**战斗奖励三档厚薄的逐条目绝对取值与挂池 + Finale 加厚幅度取值**。
- **一处以直读裁决的事实冲突（结论与本次 `/assess-derive-readiness` 相反，故单列）：** 就绪度小节把 `balance.md:1208` 的「折算不等于定案——三档点数仍欠取值」列为**必清的陈旧措辞**，理由是 `ADR-0248` 已把 50 / 100 / 200 写死。**直读 `ADR-0248` 后果段原句：「回寿量三档的绝对点数（50 / 100 / 200）仍是折算初值，归内容扩充后的统计校准……改的是数，不是形状。」** ⇒ `balance.md:1208` 与 ADR **一致、并不陈旧**；`ADR-0248` 决策表里没有「初值」二字的那一行与 `life-span.md:50` 的决策段是形状层（三档与 `RarityTier` 一一绑定、三章通用、`Charges = 1`），两者不冲突。**本次据此只移出「每章回寿事件次数」那半，未移出点数。** 就绪度小节按纪律一字未改，该条留给用户裁决。
- **只报告、未改动的主题文档问题**（本技能不写主题文档）：`monetization.md:196` 与 `content-service.md:490` 的「ADR 候选，待 `/write-adr` 立档」已过期（分别应回链 `ADR-0255` / `ADR-0182`）· `life-cycle-service.md:384` 的三条待决含已被 `ADR-0196`~`0200` / `ADR-0250`~`0254` 推翻的表述 · `profile-service.md:512` 的泛指措辞须收窄至 `PlayerItem` · `player-power/_index.md:156` ① 是已被 `ADR-0237` / `ADR-0242` 关闭的陈旧副本 · `game-progression.md:214` 的 `## 待决问题` 小节整节为空（既无条目也未明写「无」）· `vision/scope.md` 仍无 `## 待决问题` 小节且 `包体` / `授权` / `版权` / `商用` 四词零命中。
- **跨边界：本次未写对侧库。** `ADR-0255` 在后端库的零承载欠账（付费角色系列的 SKU / 验票写入 / 封闭表加行）属本技能有权补登的形态，但本波次另有 worker 独占后端库的 `open-questions/` 分片 ⇒ 按「绝不让两个并行 worker 写同一份文件」让位，承接项原文交由 orchestrator 代笔。
- **`## derive 就绪度` 与 `## 下一阶段` 两节一字未动**（分别归 `/assess-derive-readiness` 与 `/write-adr` 独占写入）。

## 2026-09-11（`/write-adr game` 范围 `all` · 固化 14 份新 ADR · 改写 1 份 ADR · 候选清单清空 · 单库）

- **固化 `ADR-0255` ~ `ADR-0268`。** 台账对账：`decisions/` **268 份文件 ↔ 268 行**，双向零缺口（267 份 Accepted + `ADR-0001` Proposed 示例占位）。
- **登记候选 4 条全部立档、从 `## 下一阶段` 移除，该处候选清单归零**：付费解锁角色系列 `ADR-0255` · 全角色「可通关」验收目标 `ADR-0256` · 通用 / 专属功法按稀有度分层梯度 `ADR-0257` · 多灵根免费轨道与双机制卡池区分 `ADR-0258`。候选 ④ 里的「首批五角同档压平」可被单独推翻，故拆出 `ADR-0259`。
- **补固化散落定案 9 条**（来自两份未被任何 ADR 引为来源的 handoff）：`2026-09-10-item-family-supply-guardrails` → `ADR-0260` ~ `ADR-0266`（`I-13` 白名单 · 族护栏判据 · Exchange 逐族库存深度 · 事件侧产出量与 `X-1` · barter 两格护栏 · 法宝置换并入上层 ≈1.0 · `R_c` 重填与回代式条件概率修正）；`2026-09-10-player-power-acquisition-and-balance` → `ADR-0267` / `ADR-0268`（三条获取通道 + 三格规则层封死 · 账号级法则获取速率派生表）。
- **`ADR-0218` 就地改写、不新增编号**（承根约定「改决定直接改 ADR」）：候选条目构件由「六个位」改为「六个位两条轴共用 + 纵向侧第七位『行尾操作控件』」，并写入外溢判据（仅幂等的账号级开关才开放）；台账行标题与影响文档同步更新。
- **不建档项 3 条（判定与前次一致）**：`2026-07-12-example`（模板示例）· `2026-08-02c`（意图族已被 `ADR-0059` 整条推翻）· `2026-08-12b`（已由 `ADR-0051` 承载）。
- 本次**不裁决任何待答问题、不改任何主题文档**；`## 下一阶段` 只删已固化的候选行，其余小节（含「derive 就绪度」）一字未动。

## 2026-09-10（`/batch-analyze-new-ideas game` · 三份 solution-draft 一批 · 移出 3 条 · 新增 2 条 · 改写 1 份 ADR · 单库）

- **范围：** `inbox/solution-draft-experience-supply-accounting.md` · `inbox/solution-draft-player-power-acquisition-and-balance.md` · `inbox/solution-draft-item-family-supply-guardrails.md` → 三份同日 handoff。三份草稿各自的取向已由用户在 09-10 批量评审中裁决，视同当面拍板，未重问。
- **合并 interview 8 项（🔴 7 · 🟠 1），全部取推荐项。** Phase A 三个 worker 另自动采纳 22 项标准默认（🔵），不占 interview。
  - **经验单价改 `K = 5 / 6 / 9`（不是评审时按标准默认采纳的 5 / 8 / 12）。** 原因是一处承重算术：草稿表头写 `floor(E/K)` 而 ch2 / ch3 填的是未取 floor 的 1.5，取 floor 后 A3 跌回 1.141 / 1.146 ✗，「算术唯一锁定」的前提不成立。新取值令 `K` 整除 `E[道念差]`（5|5 · 6|12 · 9|18），两种读法重合。锁定值：`p_c` = 1 / 2 / 2 · `G_c` = 103 / 314 / 488 · `X_c` = 4 / 11 / 14 · A2 = 95 / 292 / 460 · **A3 = 1.203 / 1.182 / 1.176 ✓（首次三章全部落带）** · 全胜比（导出量）= 1.30 / 1.27 / 1.25。`N = 2` 三章统一不受影响（三章一律由寿元侧封顶 5.30 / 4.97 / 2.69）。**诚实边界已写进正文：`K | E` 只消除文档内的口径分歧，`E[floor(d/K)] ≤ E[d]/K` 的估计偏差仍在，实测拿到分布后须复算。**
  - **`ADR-0176` 就地改写**（根约定「决策可被推翻 → 直接改写那份 ADR」）：A3 落带后「不达标如实入账、台账不得写成三条全过」与「台账里会长期留着三个 ✗」两句作废，改为「偏紧由补记一个从未入账的产出项收口 —— 调构成，不提高阈值、不加旋钮」。**保留** ch3 最薄不加旋钮与两层验收两条。
  - **`R_event,3` 保 264，ch3 改写为「1 次小档 + 点名产出补足 ≈105 点」。** 裁决自身两半在 ch3 上算不平（2 次小档 ≈ 317 vs 账上 264，超供 +20%，会让 λ₃ 由 44 变 45）；改后三章口径统一（补足量 +16 / +19 / +105），Σ 恒等 100 / 116 / 317 ⇒ λ 与 21 格 `lifeSpanCost` 定价表真的零改动。
  - **法宝置换并入「失去能力」上层 ≈1.0 的分子，不设自持口径**（跨分片矛盾，经直读三处权威裁决）：`ADR-0161` 的自持判据首条是「不写 Profile」，而法宝置换写 `CharacterProfile`；同层的神通置换在合计内占 ≈0.5。`ADR-0161` 的四支枚举不扩为五支；份额归 `character-profile/item/` 侧裁定。
  - **候选项列表语言的构件加第七位「行尾操作控件」（仅纵向侧）**，触控目标那句改写为「纵向侧允许行尾一个独立操作热区，其余区域仍为整行」，并写明外溢判据（仅幂等的账号级开关才开放第七位）。先例是启动区的逐行启动键。
  - **barter 对价改档差口径 `产出物 RarityTier ≤ 支付物 RarityTier + 1`**（原案的价值比跨币种相除，会给「售出侧同币回收、不产生事实汇率」这条结构性纪律开一个书写口径级的汇率；且 `≤ 2.0` 在五个族系数下对应的档差从 −1 到 +2 不等）。
  - **barter 条数写「≤ 1 条 / 店」作编排口径**，`exchange/common-properties.md` 那句「不另设条数上界」随之改写（保留「加载期不设上界」，理由从「问题不存在」更新为「问题已具名」）。
  - **不与 `GrantPoolMargin` / `K` 合场**（索引原写「宜合场」）：两者解锁条件不同，且结构与断言不依赖取值、可先填 0。
- **移出 3 条：** `06-meta-progression.md` 的「胜侧 `rewardPerMomentum[experiencePoint]` 是否计入经验供给账」· 索引 `## 当前焦点` 的「`PlayerPower` 的获取 / 失去具体触发与平衡边界（五投影）」+ `deferred-content.md` 的同题分片条 · `01-combat.md` 的「道具整体的获取频率、库存深度与置换对价」。逐条见三份 answer log。
- **新增 2 条（均落 `01-combat.md`）：** `I(ch1) ≈ 127` 的账目缺口（隐含加成分量 32 复算不出，应为全胜 55 / 败率 20% 折 44 ⇒ `I(ch1)` 应 ≈150 / ≈139，灵石账与经验账须共用同一个「胜场数 × `E[道念差]`」口径）· 战斗场数在库内有三个并存读数（11 · 11.5/11.9/14 · `0.35 × P + 1`，相差最大 20%）。另在既有三条上就地追加复核挂钩（`E[道念差]` ch3 ↔ `K_3` 耦合与先后 · `ExchangePoolMargin`/`K` ↔ Exchange 逐族深度 · 神通供给 ↔ `CharacterPower` 族深度）。
- **顺带的机械落笔：** 回代式 `P` 补「回寿只占 Tier2/3/4 权重和」这层条件概率（`R_item,c` = 33.9 / 38.9 / 52.7）· `item/_index.md` 的 `itemPowerRatio` 旧值压回现值（0.52 / 0.62 / 0.72 / 0.87）· 六条失败代价表 ④⑤ 在经验一列补「两笔不重叠」· 首批条目数矩阵**四格**（法宝 Tier5 1→2 · 法宝行合计 39→40 · 档内合计 3→4 · 总计 48→49）· `06-meta-progression.md` 归档块的「75%」中性化为「≈55%」· 索引「零决策修正清单」删去已收窄的一处点名（十八处 → 十七处）。
- **`open-questions.md` 的结构性违规如实记录、本次未扩大改动面修：** 被移出的 `PlayerPower` 那条原本写在**索引正文**（`## 当前焦点` 与 `## 最短解锁路径`）而非分片，与「问题条目一律落分片」相抵。本次按实际位置删除，未把余下的索引正文条目下沉。

## 2026-09-10（`/analyze-new-ideas game` · design-draft-character-technique-identity · 移出 3 条部分 · 新增 3 条 · 推翻 2 项 · 单库）

- **范围：** `inbox/design-draft-character-technique-identity.md`（`/design-direction-interview` 09-10 专场，十轴定案）→ `handoffs/2026-09-10-character-series-identity-and-monetization.md`。逐轴裁决视同用户当面拍板，未触发新 interview；「张力」区两项推翻已获用户确认。
- **推翻 2 项（用户确认，权威已改写）：** ① **付费解锁角色系列成为商业化第三支**——改写 `systems/character-profile/_index.md`（「解锁绝不可做成付费点」负面边界撤销，系列 / 轨道 / 单向棘轮成文）· `systems/monetization.md`（商业化三支 + 第三支整节）· `vision/scope.md`（范围之外改列「后续角色系列 = 确定项」）；ADR 侧就地改写 `ADR-0023`（决策 ⑤）· `ADR-0055`（后果段）· `ADR-0024`（「唯一付费点」收窄为 MVP 口径）——草稿猜测的 `ADR-0191`~`0195` 经核查为外观族、不受影响；付费面五项排除原样成立。② **首批五角复杂度压平**推翻「复杂度差异本身是产品特色」——改写三处正文副本（`character-profile/_index.md` · `deck/_index.md` · `ux/onboarding.md`）与 `ADR-0229` / `ADR-0234` 的理由句；「不标推荐项」「不设统一底盘」结论保留、理由改为「同档无需推荐」。
- **移出 3 条部分（`06-meta-progression.md`，均收窄未整移）：** 强度塌缩（验收目标 + 内容向修正基准已定，余实测半）· 多灵根换算（双机制组合模式已定，余两类专属内容对铺量）· 通用功法占比（稀有度分层梯度口径已定，余逐档数值）。见 `../answer-logs/log-character-technique-identity.md`。
- **新增 3 条（`06-meta-progression.md`）：** 付费角色系列的解锁载体与购买流程形态（归 `/provide-solution-draft`）· 双灵根批与付费系列的推出时点与主题包装 · 付费角色与专属剧情的关系。分片抬头范围行随之改写（商业化那半不再为零条）。
- **其余落笔：** `deck/_index.md` 通用 / 专属梯度与复合功法义务成文 · `character-profile/_index.md` 多灵根确定项 / 具名人物 / 逐角色自由定两口径 · `terminology.md` 新登「角色系列」「复合功法」并改写 premium bundle 行 · `currency.md` 付费面口径措辞对齐。
- **跨库对账：** 付费轨道的后端承接（SKU / 验票写入 / 封闭表加行）随 `/provide-solution-draft` 的形态推演一并产生，本次未在对侧库补登（与外观「首批不做 ⇒ 不产生承接项」同一先例）。
- **索引：** 「最近更新」行更新；「下一阶段」新增 ADR 候选 4 条。**`## derive 就绪度` 小节原样未动**（归 `/assess-derive-readiness` 独占写入；其对 `ux/onboarding.md` 的陈旧复述仍留待下次全量评估刷新）。
- **本日志溢出维护：** 追加本条后超出「只保留最近 10 条」，最早一条（2026-09-07 `/batch-analyze-new-ideas game`）原样移入 `update-log-archive.md` 末尾。

## 2026-09-10（`/summarize-open-questions --lib=game` · 全量整理 · `/progress-sync` 波次 3 · 移出 1 条 · 去重 1 条 · 分片 ⑦ 并入 ⑥ · 单库）

- **范围：** 客户端库全部主题目录（`vision/` · `systems/` · `art/` · `ux/` · `content/` + 根级三份）中 **61 份带 `## 待决问题` 的文档**（其中 17 份该节为空或明写「无」），加 9 个分片与两库 `cross-boundary.md`。对账基线含波次 1 固化的 `ADR-0224` ~ `ADR-0254` 共 31 份。**不引入新想法、不裁决任何问题**（无人值守口径，本次零 `AskUserQuestion`）。
- **移出 1 条（部分）：** `05-service-contracts.md` 的「存档 `schemaVersion` 登记表的覆盖对账」条 —— 第 ① 件「`PlayerProfile.achievement` 待补入 v1 清单」**已答定并落笔**（`ADR-0196` ~ `ADR-0199` 定 schema / 进度模型 / 采集面；v1 清单据此补入 `#35` / `#36` / `#37` 三行，仍属 `schemaVersion` 1、无新 bump）。第 ② 件 golden 形状快照 `profile-shape-v1.json` 仍留清单。见 `../answer-logs/log-0910.md`。
- **同批清理（非问题条目）：** 同条末尾那条「备注（指向索引）」删除 —— 它指出的三处陈旧前提随 09-10 的 `derive 就绪度` 全量重写已消失，机械核实「derive 前置」/「schema bump 清单」两词在索引中零命中。
- **去重 1 条 + 分片合并：** `07-codex-monetization.md` 的 `GrantPoolMargin` / `K` 与 `01-combat.md` 的「取池余量三格」是**同一条问题**（`balance.md` 的待决条本就把三格 margin 与 `K` 写成一条），合并为 `01-combat.md` 的单一条目并补上礼包侧「支撑 K 次重复购买 + 第 K+1 次缓冲」的口径与 `monetization.md` 回链。⑦ 由此零条 ⇒ **并入 ⑥**（`06-meta-progression.md` 抬头补范围行，图鉴族 / 商业化的新问题今后落 ⑥）；`LocationCodex` 词条深度本就在 ②。分片数 9 → 8。
- **归拢 3 处（主题文档有、清单只有上位条目，作为从属项并入而非新立条）：** ① `deferred-content.md` 成就条目目录条补 **`AchievementSignalIds` 首批清单**（`achievement/common-properties.md:107`）；② 同片「内容目录整体未编写」条补**账号级法则 / 古宝（`PlayerPower`）条目目录**（`player-power/_index.md:130`，类型面已闭合、开张归 `/scaffold-content-type player-power`）；③ 同片「数值标杆」条把 **`lossPerMomentum` ch2 / ch3 系数**（候选 5 / 10 待定案）由半句提为显式从属项。
- **就地更新 1 条：** `01-combat.md` 的 starter deck 条补上已给出的**设计取向**（`ADR-0228` ~ `ADR-0231`、`ADR-0235`），仍待定的只有「装哪些牌」。
- **一处刻意不回填：** `combat/_index.md:211` 与 `combat-service.md:697` 仍登记「三档奖励厚薄 / Finale 加厚幅度的逐条目绝对取值」，但 09-09 的 `log-event-reward-and-hidden-stat-orchestration.md` 明写该残留「属既有的统计校准面，**不回填本清单**」⇒ 本次不立条，只在报告中点出主题文档侧的登记仍在。
- **跨库对账：** 客户端 `cross-boundary.md`「待承接」**2 条**（`backend ADR-0051` / `ADR-0052`，均对侧 09-07 定案、本库未落笔）原样保留；波次 1 的 31 份新 ADR 逐份核对**无一产生后端义务**（`ADR-0251` / `ADR-0254` 明写「后端零参与」）⇒ **未在对侧库补登任何条目**。
- **索引：** 「最近更新」行更新、分片导航表由 9 行减为 8 行、`当前焦点` 的「分片 ①–⑦」改为「①–⑥」、③ 与 ⑤ 的一句话描述随内容变化改写。**`## derive 就绪度` 与 `## 下一阶段` 两节一字未动**（分属 `/assess-derive-readiness` 与 `/write-adr` 独占）。
- **本日志溢出维护：** 追加本条后超出「只保留最近 10 条」，最早一条（2026-09-07 `/summarize-open-questions game`）原样移入 `update-log-archive.md` 末尾。
