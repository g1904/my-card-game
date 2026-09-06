# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

> **只保留最近 10 条。** 更早的条目原样移入 [`update-log-archive.md`](update-log-archive.md)（按时间正序），
> 一字未改、仅换了文件——本日志与归档合起来即全部历史（`decisions/ADR-0005`：台账不无限膨胀）。

## 2026-09-06（`/batch-analyze-new-ideas` · 4 份已评审草稿 / 2 跨库 counterpart 对 · 单波并行 · 合并 interview 1 题 · 移出 3 条 · 新增 0 条 · 客户端半）

- **四份草稿均已批量评审、裁决回写**（视同用户拍板），Phase A 校验新增问题仅 1 题：**客户端购买域三个 HTTP 调用的后端接口落形**——草稿提议扩展 `IProfileBackend`，但 `architecture.md` 早已预告 `IPurchaseBackend`（清单 5→6）并点名否决前者，草稿「张力：无」属漏检。**用户裁 B：新增第四个窄接口 `IPurchaseBackend`，条件编译清单 5 → 6**（兑现既有预告、零 ADR 推翻；ADR-0011 / 0023 / 0024 预告行同批改当前事实）。跨草稿核对无矛盾。
- **移出 3 条：** `cross-boundary.md` 待承接两条（基线超集纪律 · 产包证明条目计数）→ `content-service.md` 新增「内容发版纪律（基线 `Id` 超集不变式）」节（只增不删 · 退役三分 · 归档步 `Id` 超集闸）+ `entryCountsByType` dormant 附注，`ADR-0141` 后果句订正（「只跑最新」经推演不成立，逐基线各跑为长期形态）；`07-codex-monetization.md` 的 SDK 选型与封装层一条 → `monetization.md` 唤起段收口 + `sync-service.md` 的 `StoreChannelManager` / `IStoreChannel` / `IPurchaseBackend`。另两条既定裁决落笔：非商店平台 Store 入口不渲染（前置条件表加行、计数措辞去计数）· iOS 部署下限 15（`vision/scope.md`）。
- 对应 answer logs：`../answer-logs/log-baseline-superset-and-pack-proof.md`（2 条）· `../answer-logs/log-iap-channel-integration.md`（1 条）；对侧库同批落笔（两对 handoff 互链），后端半摘要见 `backend-design-documents/open-questions/update-log.md`。本文件同批把最早两条摘要（08-30c · 08-30d）移入 `update-log-archive.md`，并修复 09-05c 条目丢失的标题行。

## 2026-09-05e（`/write-adr game`，范围 `all` · 固化 26 份新 ADR · 候选清单清空）

- **三条登记候选全部立档**（均出自 `handoffs/2026-09-05-currency-acquisition-and-pricing.md`）：`ADR-0133` 货币跨篇章结转与寿元同形 · `ADR-0134` 灵石 ≈ 战利品（战斗主产出口 + Travel 禁令扩三 key）· `ADR-0135` 仙玉不落可售出族。三条均先在 `systems/balance.md` / `character-profile/currency.md` / `services/life-cycle-service.md` / `adventure-event/common-properties.md` 核到落笔原文才建档。
- **另逐份核对 22 份未被任何 ADR 引为来源的 handoff**，补固化 23 条散落定案 → `ADR-0136` ~ `ADR-0158`。按批：09-02 六份（绑定功法恒第 1 层 · 图鉴单一入口三层浏览 · `CycleEndScreen` 一屏三变体 · 阵法启动式异能宿主 · 剧本段落结算面板 · `BranchLabel` ⟺ `BranchChosen` 焊死）· 09-03 七份（跨载体边界判据 · 神通强度上沿不设总闸 · 快照对侧 `faceDown` 按视角过滤 · 合规域切分判据 · `lifeSpanCost` 耗时正比定价 · 剧本层对外面 · schema 登记权威 + `ProfileShapeCheck`）· 09-05 八份（须改名 fail-open 流程门 · 未成年时长只呈现不判定 · `OpError.Purchase` · 打包工具产包证明与基线快照 · 灰态非禁用 · `ChapterEndScreen` · `FinaleDiff` 旋钮 · 登记表不写计数）· 早期两份（`ADR-0136` 两层档案持有骨架 · `ADR-0137` 设计库类模型化组织）。
- **未固化 2 项，如实留下：** ①「`terminology.md` 是术语事实来源」判为库内书写约定而非方向性设计决策，不建 ADR；②「结转是 ch2 的必要预算构成」属对 `ADR-0031` 既有决定的补强而非新决定，不另开编号（本次未改 `ADR-0031`，留待下次触及该 ADR 时就地补写）。
- **台账对账无残留**：建档前 `decisions/_index.md` 132 行 ↔ 132 份文件已一致，无孤儿 / 悬空行需修平；建档后 158 ↔ 158。
- **越界发现（未处理，归主题文档写入者）：** `systems/_index.md` 的 services 表内 combat-service 一行仍写「敌人 AI 与意图（三档揭示）」，与 `ADR-0059` 及同文件另一行的「行动不作事前预告」相抵。

## 2026-09-05d（`/summarize-open-questions game` · 全量整理 · 移出 1 条 · 归集 3 条 · 订正 2 处 · 报告 5 处矛盾）

- **采集面**：主题文档 `vision/` · `systems/**` · `art/**` · `ux/` + 根级三份共 **59 处 `## 待决问题`** 小节（本库范围内标题写法统一为中文「待决问题」，无英文写法）；`handoffs/` **152 份全部 `distilled`**（唯一 `raw` 是 `2026-07-12-example.md` 模板示例，自述「写好真实的之后请删除」），台账 ↔ frontmatter 零不一致 ⇒ **无「尚未进主题文档」的未决项**。
- **移出 1 条**：`deferred-content.md` 的**元婴界面（通关证书）的具体形态**——同日已随 `ChapterEndScreen` ch3 变体答结并从 `06-meta-progression.md` 移出，但本片留着一份重复登记。见 `../answer-logs/log-0905.md`。

- **归集 3 条**（此前只在主题文档侧登记、本清单零承载）：
  - `01-combat.md` ← **敌人台词的槽位清单 `LineSlot` 成员**（`enemies/common-properties.md` 的待决项**已点名回链本分片**，而本分片此前没有这一条——单向悬空）；并入竖屏专场。
  - `03-adventure-event-types.md` ← **Travel 一行的具体定价**（结构约束已定、绝对数字未定）；Explore 条由「两个待实测初值」扩为**三个待定取值**（补 `Explore` 行定价，随真身占比实测偏移须与 `t = 1.6` 一并重算）。
  - `06-meta-progression.md` ← **通用功法（空 `RequiredAffinities`）的占比口径**，与「全池指定的强度塌缩」「多灵根换算」同属灵根辨识度这条压力线的第三面。
- **订正 2 处清单自身的失真**：① `01-combat.md` 与 `deferred-content.md` 两处把 `lossPerMomentum` 写成既定的「三章 10 / 5 / 10」，而 `balance.md` 只锁定了 **ch1 = 10**，ch2 / ch3 的 **5 / 10 是候选值、尚未定案** —— 两处改为如实措辞。② `deferred-content.md`「尚未设计」区把**账号层** `player-profile/player-item/common-properties.md` 与**角色层** `character-profile/item/common-properties.md` 混为一谈，据前者「已写出机制面」宣布「本节已不再有空占位文档」；该文件自陈「共有字段……目前均为占位，无实质设计」⇒ 抬头措辞推翻为「仍有一处空占位」，欠的是整份共有字段面而非 `status` 一格。
- **`03-adventure-event-types.md` 的首条改版式**：主干「各类型的结算 / 机制细化」五类已全部收口，由待答子弹改为 `>` 前提说明（结论早在各 `log-*-mechanics.md` 归档，不重复计入本次移出），片内保留的只是收口后**只欠取值 / 只欠呈现形态**的残留。
- **`## derive 就绪度` 小节一字未动**（`/assess-derive-readiness` 独占）；本次报告不含就绪度结论。

## 2026-09-05c（`/batch-analyze-new-ideas game` · 3 份草稿 / 2 分片 · 单波并行 · 合并 interview 3 题 · 移出 4 全条 · 新增 1 条）

- **分区依据写入面而非主题**：barter 与 run-end 两份草稿都写 `ux/error-and-blocking-ux.md`（前者「灰态判据」小节、后者「键命名规范」分区表），合并给同一 worker 串行落笔；schema 分片写入面零交集，并行。Phase A 分级 🔴 1 · 🟠 2 · 🔵 28，必问过滤后问 3 题，一轮问齐。**跨草稿核对未发现矛盾**，且查出一处正向咬合：run-end 的「元婴证书只用已定字段 ⇒ 零 schema bump」恰好坐实 schema 草稿「本次不新增版本行 ⇒ 不触发后端矩阵」的前置。

- **篇章结束屏 `ChapterEndScreen` = 一屏三变体**（移出 `06-meta-progression.md` 2 条：篇章通关那一刻的呈现 · 元婴界面的具体形态）。变体轴取 `chapter`，**ch3 变体即元婴通关证书**；与 `CycleEndScreen` 合成轮回收尾族两屏——不合并为一屏五变体，判据是失败侧「账号级收获零呈现」与元婴「必须有统计区」互相否定。出口只有「返回主菜单」，允许一次入场演出（≈1.2s + 短音效 + 任意触点跳过）。`CompleteChapter` 组装只读摘要 `ChapterEndSummary`，时点两条硬要求：境界寿元增量之后、`TeardownCycle` 与任何角色数据处置之前。零新增存档字段 / 零 schema bump / 后端零配合。「通关」口径分离：ch1 / ch2 写「突破」。
- **新增 1 条待答（`06-meta-progression.md`）：`completed` 是否清理角色数据。** 库内两处写「两条出口的数据都会被清理」，而「篇章继承：全部继承 + 读档续章」与 `program-overview.md` 阶段 5 的 `completed` 分支要求它不被清理。用户裁决**本次不拍板**：`life-cycle-service.md` 用中性措辞（摘要在任何角色数据处置之前组装，两种读法下均成立），矛盾另立待答项。
- **barter 灰态补进权威判据表**（移出索引「台账 / 投影缺口」1 条）。判据表 4 → 6 行：新增「barter 格：不持有 `PayItemId` 或产出目标已持有（能力族）」（两条触发条件写一行）与用户裁决一并补的「Exchange 商店买不起」。两个新键 `EVENT_BARTER_UNAVAILABLE_NOT_HELD` / `_ALREADY_OWNED`（`<CONTEXT>` 取 `BARTER` 不取 `EXCHANGE`），买不起那行**零新增键**（说明由 `ApplyResult.MissingElement` 机械映射）。新增落地纪律「**灰态是视觉降级不是禁用，灰格必须继续接收触控**」。顺手修同一张分区表内 `COMBAT_` 行残留的已删机制 `intent`。
- **schema 登记表：原条目所指四批漏登经核实已不成立**（移出 `05-service-contracts.md`，改写后降级留档）。真残留是登记表**自身**的覆盖空缺——由草稿说的 7 处**修正为 11 处**（另有 `magicPack` / `characterPower` / `playerPower` / `playerItem` 四个顶层键零登记），追加 v1 行 #28–#33；#18 错归属订正（`disabledAbility` 属 `CharacterProfile`、已由 #10 登记）；`AccountInfo` 补登依据由形态纪律 ⑤ 第三档改挂 ①（`AccountId` 不受回声约束）。**立形态纪律 ⑥「本表不写任何计数」**并同批清掉表内既有六处计数（否则新纪律在自己表内当场不成立），⑥ 加射程限定句以免规则吃掉自己；`ADR-0127` 两处「22 格」与登记表 #12 删计数改回链，ADR 的决定 / 理由链一字未动。`ProfileShapeCheck` 补一条 `/sync-knowledge` 条目 ↔ 字段表行双向对账断言（第 3 级，不造工具 / 不抬管线闸）。
- **两处边界裁决。** ① 草稿要撤销的三处 derive 前置标注全在 `## derive 就绪度` 小节内——该小节由 `/assess-derive-readiness` 独占，故**小节一字不碰**，改写后的条目移入 `05-service-contracts.md` 并在正文写明那三处已失效、待下次全量评估清理。② 草稿断言「对侧无残留错指」**不成立**：后端 `open-questions.md` 两处仍按 09-03 之前的事实陈述，本次一并删除（纯删除，不新增后端义务、不触碰契约）。

## 2026-09-05b（`/batch-analyze-new-ideas game` · 1 份 decided 草稿 · 未触发 interview · 移出 4 全条 · 新增 0 条）

- **批次范围只有一份草稿**（`inbox/` 顶层唯一在办项），批量编排退化为一次单会话提炼；无跨草稿核对可做。Phase A 分级 🔴 0 · 🟠 0 · 🔵 全部——草稿以 `status: decided` 进入，两项真取向已在同日的批量评审中裁决，其余各节自带 `[既有推演]` / `[通行做法]` 标注且经复核成立，故按必问过滤**一题未问**。

- **两条货币的产出曲线一同定下**（移出 `deferred-content.md` 2 条、`03-adventure-event-types.md` 1 条收窄）。**灵石 ≈ 战利品**：战斗是主产出口，`Research` / `Exchange` / `Travel` / `Explore` 一律不给，篇章缩放落在「一场给多少」（`S(c)` = 15 / 35 / 60，`Practice` 0.5× / `Finale` 2.0×）。**仙玉**每章 1–2 次、单次 1 / 2 / 4 枚，载体是既有的 `SelectionWeightGrades.Rare` 档，不加字段。25 格定价表按「族系数 × 稀有度基价」外积给出初值，回收率 40% / 15%，载体新开 `ExchangePriceTableData`。**货币量不引入档位枚举**——定价表不设篇章维 ⇒ 绝对值本身跨章可比，套档位只增书写位不增分辨率。
- **「货币每章重置」改为跨篇章结转（用户裁决）。** 该措辞全库零机制承载，改为与寿元同形后 `ChapterManager` 不新增任何职责、不新增存档点。三处镜像句同批改写——草稿只登记了 `currency.md` / `balance.md` 两处，**校验查出第三处在 `exchange/_index.md`**。「定价表不设篇章维」的理由随之换成「跨章结转要求价格跨章稳定，否则余额被通胀稀释」；`currency.md`「不由 Finale 发放」的旧理由（收口发放随后即被清理）整条失效，结论保留、理由重立为「Finale 的 `BaseReward` 本就是战斗货币通道的一部分，另设一条即重复记账」。
- **仙玉不落 `CharacterItem` 行，净产出敞口结构性关闭（用户裁决）。** 可售出 ⟺ `Kind == CharacterItem` 是代码级常量 ⇒ 仙玉不落该族即让「售出产仙玉」不可能发生，`balance.md` 原先「被接受的取舍 + 归统计校准把关」整条删除。代价如实写下：**永远编排不出以仙玉计价的法宝**，含顶级消耗品。
- **校验面纯加法**：Travel 禁令的 `ResourceKey` 集合扩为三 key（**`Direction == Gain` 保留**——草稿的写法会连带误禁 Travel 的货币扣减向，如「路上被劫」）· 新增软校验「非 Combat 条目产货币 → `PushWarning`」（校验表第 9 行）与「`BaseReward` 灵石量 > `2.5 × S` → `PushWarning`」。零字段增量、零 schema bump。
- **三处推翻草稿自身的主张**：`ADR-0089` 并非自相冲突（草稿引的 `:38` 是五条否决通道的列举，不含「稀有 AdventureEvent 产出」，冲突方在 ADR 与系统文档之间）· `balance.md` 待决第 10 条与货币无关（其「定价表」指寿元 `lifeSpanCost` 表）、第 4 条方向相反（`RarityTier` 分布权重是本方案的**前置**而非产物）· 校验 6 的谓词是合取而非单条件。
- **顺带订正三处历史残留**：`ADR-0089` 的「唯一主动获取通道是商店」（商店是花销出口）· 同 ADR 的「`CostKey` 15 → 16」（`LifeTotal` 退役后恒为 15，08-30 漏改此处）· `terminology.md` 仙玉词条漏掉的「主动」二字。

## 2026-09-05（`/batch-analyze-new-ideas game` · 2 份草稿 / 2 分片 · 单波并行 · 合并 interview 5 题 · 移出 3 全条 · 新增 2 条）

- **两分片写入面零交集**（S1 = 平衡面 Finale 赋级 · S2 = 合规 / 购买 / 打包工具），单波并行，跨草稿核对**未发现矛盾**。Phase A 分级 🔴 4 · 🟠 2 · 🔵 30，必问过滤后**问 5 题**，两轮问齐，用户五项均取推荐。**批次范围顺带核实出一处事实**：用户圈选的「一并处理后端 counterpart 四份」无事可做——那四份已于 2026-09-03 全部提炼完毕、后端 inbox 顶层为空，故本次是补上客户端欠的那一半。

- **Finale 的指派等级改为平衡资源上的旋钮 `FinaleDiff`**（移出 0 条、新增 0 条）。草稿自称「与既有决策的张力：无」**不成立**，校验查出两处真冲突：① 装等级旋钮正面撞 `balance.md`「绝境感永远不由等级差表达」与 `combat/_index.md` 推论 ②「特殊性不落在等级上」——裁决为**收窄这两句的作用域**（剧本 / 内容侧禁用等级差，平衡面独占该旋钮），依据 `ADR-0077` 的能力检查点论据；② 草稿的取值域 `[末级−2, 末级+2]` 下半段会让天劫等级 ≤ 角色等级，与「必然越阶 / 渡劫 = 突破到下一境界」相抵，**收窄为 `[末级+1, 末级+Upper]`**，既有承重链一字未动。
- **收窄后的实际收益如实写下、未粉饰**：ch1 / ch2 各 2 档，**ch3 受 `Upper` 与全局序 22 双重截断恒为单值——旋钮在第三篇章不可拧**，恰是草稿开篇点名的那个「全作压迫顶点」。用户在知悉这一点后仍选择装旋钮。
- **字段形态由绝对改相对**：`FinaleLevel : int` → `FinaleDiff : int`，初值三章恒 `+1`（绝对 14 / 18 / 22 降为推导结果）。理由是校验退化为纯本地断言、不外借住在境界枚举里的「篇章末级」常量，与 `EnemyLevelRange` 全行的相对语义一致。另订正草稿两处机械错误：下界写成 `末级 − Upper`（应为 `Lower`，本次定为常量 1）· 点名要改的 `future-event-service.md`「恒为 `diff = +1`」**该串不在此文件**。改动面由草稿宣称的 3 处扩到 8 处。

- **后端 09-02 批量评审落给客户端的四项义务全部承接**（移出 `cross-boundary.md` 3 条，全条移出）。三处推翻草稿：① A 项「复用既有的**改名屏**」是**臆造**——本库没有改名屏，昵称编辑是 PlayerProfile 屏内的一个区，改为**启动链内 fail-open 全屏模态**，并就地改写 `account-service.md` 的边界句消歧（同一句里既写「下次会话再拦」又写「升级成启动阻塞就会新增一处阻塞点」）；② C 项「在 `code → (OpError, 处置)` 表补四行」**作废**——核实发现本库根本没有逐 `code` 表，只有按 `class` 的默认表，且 09-03b 已定案「开半张表即制造与对侧台账重复的第二权威」，改为只加一行枚举、处置落 `monetization.md`；③ **客服可达面草稿完全未提**（对侧刻意把「有 / 无客服入口」分列为一个维度），裁决为复用既有的 `#requestId` 长按复制，不新增入口、不引入客服地址配置面。
- **新增两条待答**（均落 `cross-boundary.md`「待承接」）：更高版本客户端基线是否恒为更低版本基线的超集（取决于本库尚未定的「发版能否删除随包内容条目」纪律，成立则打包工具可只跑最新基线）· 产包证明是否增设「按类型的条目计数」一格（对侧一条尚未采纳的优化路径需要它，须两侧同批落地）。
- 关闭 `cross-boundary.md` 购买域那条时**顺手订正其落点登记**：原写「本库需改 `systems/services/sync-service.md`（`OpError` 枚举）」，该枚举实际住 `systems/architecture.md`。

## 2026-09-03c（`/batch-analyze-new-ideas` · 4 份 decided 草稿 / 4 分片 · 两波 · 合并 interview 8 题 · 移出 5 全条 + 1 部分 · 新增 0 条）

- **四分片两波**：Wave 1 = S1 战斗快照 `faceDown` ∥ S2 剧本广播面 ∥ S3 神通机制（三片写入面两两不交）· Wave 2 = S4 寿元定价表（其量纲扫荡波及六份 Wave 1 也在改的文件，故放最后）。Phase A 分级 🔴 8 · 🟠 6 · 🔵 43，必问过滤降 6 条为标准默认后**问 8 题**，两轮问齐，用户八项均取推荐。**跨草稿核对产出一条归并动作**（见下 X1），未产生新的裁决题。

- **`CombatSnapshot` 的 `faceDown` 按视角填充纪律**（移出 `01-combat.md` 1 条）。待答项原文只并列两条候选（内容格置空 / 哨兵值、另立对侧专用视图），实际取**第三路**：对侧 `faceDown == true` 条目**整条不入** `Battlefield`，公开面由 `AmbushCount` 唯一承载——与本库对手牌 / 道具 / 启动可供性三次取的「对侧那份内容在类型层不存在」同型。连带：`Battlefield.Count` 不再等于场上条目总数（须写进文档）· 视图内 `entryId` 引用不得假定可解析 · `TargetSlot` 侧加一条加载期闸把前提机械化。
- **校验推翻草稿两处论证**：① 草稿称 `PendingTargetRequest.SourceCardId`「不是泄漏面」的理由是**假命题**——双视角投影下 `ViewerSide == Enemy` 时该格承载的正是玩家侧的牌，实际不泄漏靠时序而非结构，故给 `PendingTarget` 补了第四条同型填充纪律；② 草稿称揭示时刻有「既有两条」承接面，实际 `CombatFeedEntry` 没有 `CardId`、落账后永久失去「那张埋伏是哪张」，故它与 `StackEntryView` 各补一格 `SourceCardId`。

- **剧本层的广播面**（移出 `04-hidden-attributes-plot.md` 1 条）。答案是**不走 EventBus**：剧本层事件保持恰好一条 `PlotThresholdReached`（只补广播时点 = `eventEnd` 五步组装 ⑤ 提交之后那一批），分支揭示改走 future-event-service 门面的只读查询 `TryGetPlotSegment`，分支选择与 key point 推进零跨系统消费方。负载契约表**零新增行**，`PlotArcAdvanced` 只留路标。`plot-manager.md`「事件面」现文经裁定为占位表述、整段改写；PlotManager 门面投影 1 → 2，**三处措辞 + 一处计数句**同步松动（草稿只点了两处）。

- **神通 `CharacterPower` 的机制细节五子项全部收口**（移出 `07-codex-monetization.md` 1 条）。**零结构增量**：不新增字段 / element 列 / 枚举成员 / EventBus 事件 / 存档格，不 bump `schemaVersion`。跨载体三行边界判据表（按「这个效果要付什么代价才能生效」排序）+ 四条推论落 `power/_index.md`，`item/` 与 `deck/` 各留回链。裁决三项：绑定神通**不填** `ExclusiveSource`（辨识度被稀释这一代价明写不掩饰）· 战斗内强度上沿取 `baseMomentum` 比例刻度且**不设合计总闸** · 校验 P-b 改写为 `PowerId` 唯一性硬规则。草稿两条新校验**都不能照抄**：P-a 挂在只有两个成员的 `ModifierKey` 上恒不触发，P-b 与既有校验 #3（`PushWarning` + 退池）正面相抵且恒真。**不含**「`status` 与拥有 / 失去两个正交维度的 schema 编码」，该条仍待答。

- **寿元定价表 21 格 + 预算量纲 ×10**（移出 `04-hidden-attributes-plot.md` 与 `02-event-options.md` 各 1 条；`03-adventure-event-types.md` 部分移出，改写为只剩风险档权重一格）。定价形状 = `round(t(type) × λ(chapter))`——耗时正比是唯一不产生套利的定价形状，三条各自论证过的既定相对关系统一为它的推论。预算四格 → **1000 / +1000 / +3000 / +5000**，但**放大落在 λ 层不落已取整的格子上**（字面 ×10 会让 ch1→ch2 的变化率一位不改，取向要买的分辨率完全落空）。
- **草稿的波及面自述严重偏低**：它只点了 4 处，实际活文档 **21 份 / 60 余处**。三个最危险的遗漏：`lossPerMomentum` 九处 · `ADR-0127` 三处 · `research/_index.md` 的「全类型最贵一档」（它是走火入魔风险档「承重不可省」的前提，收窄解读后字面为假）。
- **推翻两份 Accepted ADR 的决策本体**（用户确认）：`lossPerMomentum` ch1 由 **1 改为 10**，`ADR-0018` / `ADR-0127` 里「锁定为 1 · 落后 8 点 = 掉 8 点、当场可算」这条被四处引用的设计卖点随之降级为 ×10 换算——仍属心算可及，但论证强度下降这一点已如实写出，不掩饰。共改写 7 份 ADR。
- **ch1 经验阈值曲线 79 → 55**：事件数下修到 ≈25 后供给 / 需求跌到 0.78（验收 1.15–1.20），且草稿引用的收口方向（提高阈值 + 降覆盖率）针对的是供给**过剩**、与本次方向相反。按「阈值曲线本就是事件数的从属量」重算，落定后对账为 **1.13**——**未完全达到 1.15**，已在 `balance.md` 明写对账，未擅自跌出用户给的 55–65 区间。
- **「结转是 ch2 的必要预算构成」写进设计库、不留暗账**：「ch2 略微上调」这条既定取向此前从未经过算术检验，不计结转时 λ₂ < λ₁；它成立的唯一通道是 ch1 留下约 15% 结转，故一个把 ch1 花光的玩家在 ch2 面对的是结构性偏紧的预算——这是**有意的**失败面。

- **X1 · 跨草稿归并（批量独有）**：S3 往「失去能力」的 1% 频次预算里加了第四支（神通的置换 / 禁用），而 S4 同时把这份预算的**分母**缩小约 25%（一轮回战斗场数 30–36 → 约 23、事件总数 86–102 → 约 84）。分子加一支、分母缩四分之一，`balance.md` 的两处频次换算同时失真。`06-meta-progression.md` 那条已**一次改全两件事**（三支 → 四支 + 分母缩小须复核），并同步订正 `player-power/_index.md` 的镜像口径——分两次写会让两条各自漂移而无机制发现。顺带发现该处「每 6~7 场撞 1 次」原本就与 5% 对不上（应为每 18–20 场），属既有算术错误，已按新场次改为「一次完整轮回内约 1 次」。

## 2026-09-03b（`/batch-analyze-new-ideas` · 3 份 decided 草稿 / 2 分片 · 跨库 1 对 · 合并 interview 4 题 · 移出 5 条 · 新增 0 条）

- **两分片两波串行**：S1 = 存档 schema bump 登记权威（**跨库 counterpart 对**，game + backend 同批落笔）· S2 = 合规域客户端呈现面。写入面唯一相交处经裁决后落在 `sync-service.md`，故 Phase B 不并行。Phase A 分级 🔴 2 · 🟠 6 · 🔵 24，必问过滤降 4 条为标准默认后**问 4 题**，一轮问齐，用户四项均取推荐。

- **存档 schema bump 的登记权威整条收口**（移出 `05-service-contracts.md` 1 条）。病因是「一次 bump 的内容清单被当成所有 bump 的登记簿」，故不只补漏、而是换形态：清单拆出为 **`systems/services/profile-schema-versions.md`** 逐版登记表（一行一版），`sync-service.md`「存档 schema 版本」整节收为一句回链，全部回链一次性写对、不经中转。**登记表语义取「每一版的形状」**，与 `ProfileShapeCheck` 的 golden 快照严格同构、逐行对得上。
- **改动面比登记时大得多**：核实后就地 bump 自称实为 **24 处 + 5 份 ADR**（`profile-service.md` 一家 8 处，`player-profile/_index.md`、`future-event-service.md`、`ADR-0021` 等此前完全未登记），v1 行补齐 **27 条**首发形状。三类非自称表述（否定式 / 假设式 / 纪律式）按判据一律不动——它们讲规则，回链掉会毁掉规则本身；三处「五步」流程只把「bump」改为「在登记表新增 / 追加一行」。
- **裁决三项**：① 统计层——区分「引入顶层键」（进表）与「键内追加」（不 bump），两侧各补一句分界，**不推翻任何一侧**（此前客户端与后端契约对此写反）；② 删除类改动只描述形状、不进 v1 行，处置口径落说明区，`ADR-0127` 据此补上漏执行的删除五步第 ⑤ 步；③ 后端矩阵本批即登 `schemaVersion = 1`，不等首个客户端版本。
- **漏登的机制发现面 = `ProfileShapeCheck`**：由 `PlayerProfile` 递归导出序列化形状与签入的 golden JSON 快照比对，落打包 / 发布管线（不通过即不产包）+ `#if DEBUG` 启动期，一份实现两个触发点；它是「纪律的可执行化」阶梯的**第五处应用**。落地时点仍挂在 `05-service-contracts.md` 既有的 `.csproj` 实测前置上，**未标记答结**。

- **合规域的客户端呈现面整条收口**（移出 `cross-boundary.md` 1 条 + `account-service.md` 待决 1 条 + 本次裁决 2 条）。`ComplianceManager` 切分判据 = 「一段流程归 manager、一次失败归发起它的那一屏」，四域十环节逐格归属落表 + 四件明确不做的事（**任何判定都不做**）。
- **七条 `compliance.*` 逐条核过阻塞屏变体表准入，一条也不进**：四条拦截码落登录屏就地呈现 + 各自主动作，三条端点码落发起屏。`BlockingNoticeKind` 一格不动——准入若在此松动就会新增第三处由 `code` 触发的硬阻塞。
- **三条新码的处置落 `account-service.md`「失败映射」段，`systems/architecture.md` 零改动**：核实发现本库此前**没有任何逐 `code` 表**（只有 `class` 默认表），开一张只有合规三条的半张表即制造与对侧台账重复的第二权威。`ERR_*` 键全为机械变换，**本库不建对照表、不复述 `reasonKey` 取值**。
- **裁决两项**：① 强制改名维持 **fail-open** 并明写边界（客户端不是强制点，兜底在后端存量扫描与复核通道），不要求对侧补 `signin` 拦截；② `GET status` 失败归入不变式③ **第二形状**，「已知好值」就地澄清为含**缺省值**——不变式仍是三条。
- **同批订正三处**：`ComplianceManager` 职责行的「防沉迷时长**校验**」去「校验」（与「不做任何判定」相抵）· status 调用时点由「`signin` 成功之后」改为「**会话到手之后**」（静默续期不走 `signin`，照字面写会让续期玩家永不取 status）· `ExportTaskInfo.RequestedAtUtc` 改可空并补 `Deduplicated`（非空会逼客户端填本地时钟，撞「设备时钟不可信」）。
- **零增量四项**：主菜单 · `OpError` 成员 · 存档 schema · `user://` 文件。

- **新增待答：无。** 剩余时长呈现与改名落屏两项仍在 `cross-boundary.md`，归在办草稿 A / B。
- **对应 answer log**：`answer-logs/log-schema-bump-ledger-authority.md` · `log-compliance-client-surface.md`。

## 2026-09-03 — 后端五份草稿批量提炼的对侧半：`cross-boundary.md` 新增三条待承接

后端库本日跑 `/batch-analyze-new-ideas backend`，一次清空其 `inbox/` 的五份 solution-draft（技术栈落定 · 合规域六端点报文与错误码 · 三渠道验票接入面 · 内容分发运维形态 · 昵称审核与风控）。其中三处定案**给本库新增了义务**，按跨库纪律在本侧对称落笔为**待承接项**（提案形态，裁决权仍在本库）：

- **首版即内置 active + standby 两把内容签名公钥** —— 对侧的紧急轮换形态以此为前提；契约面本就写的是「一组 `keyId → publicKey` 映射」，报文零改动。与已收在 `inbox/solution-draft-backend-batch-client-obligations.md` 的另两项（产包证明 · 基线快照归档）**须成对采纳**。
- **新增五条 `purchase.*` 错误码，其中四条需要一个现有 `OpError` 八成员都不承载的处置轴**（对侧台账按 `OpError.Purchase` 登记）。本库需裁决是否新增该成员及各码的呈现与处置。
- **合规域三条新 `code` 与两个新报文字段的落屏** —— `ERR_*` 键由 `code` 机械变换、不手写；另有 `playtimeRemainingSeconds` 倒计时与 `nicknameChangeRequired` 的改名流程落屏。

**本次移出 0 条、新增 3 条**（全部落 `cross-boundary.md`「待承接」区），本库无主题文档改动。**`ComplianceManager` 覆盖面切分那条待承接项不由本次关闭**——它是本库自己的取向，不等对侧输入。对侧的落笔见 `backend-design-documents/open-questions/update-log.md` 同日条目。

## 2026-09-02（`/batch-analyze-new-ideas game` · 8 份 solution-draft 一批提炼 · 移出 9 条 · 收窄 1 条 · 新增 7 条）

**范围与形态。** inbox 顶层 8 份 `solution-draft-*` 全部入批，五个 worker 分片并行：三份 UX / 剧本（图鉴入口与浏览 · 轮回结束屏 · DnD 式选分支）· 两份数据面（绑定功法初始层数 · `MoveCardEffect` 补 `Side`）· 一份架构对账（18 条差异）· 一份战斗 UX（阵法启动式异能宿主）· 一份存储安全（平台密钥库后置评估）。Phase A 只读校验汇出 🔴 1 · 🟠 3，合并为**一场 4 题的 interview**，用户逐题裁决后才落笔；写入面相交的分片排成两个波次串行（`life-cycle-service.md` 与 `character-profile/_index.md` 各被两个分片触碰）。

**答结 9 条**（逐条见各 answer log）：

- **`MoveCardEffect` 缺方位声明** → 补单格 `Side : SideConstraint`，与同表五个方位原语同构；两端恒同侧、跨方转移结构上不可表达；加载期校验新增第 21 条。`ADR-0119` 被兑现而非修改。→ `log-move-card-effect-side.md`
- **两门绑定功法的初始层数** → 恒为 1，`CharacterData` 不加字段；逐条编排写成纯加法退路、首批不做。→ `log-bound-technique-initial-tier.md`
- **图鉴的入口与浏览形态** → 主菜单一等入口（恒排末位、不显完成度、轮回内不设入口）+ 三层浏览；敌人本用 `EnemyData.Artwork`，只有功法本用统一占位图。→ `log-codex-entry-and-browse.md`
- **死亡 / 轮回结束屏** → 一屏三变体 `CycleEndScreen`，极简三行回顾、不呈现账号级收获、唯一主按钮返回主菜单；死亡文案改按 `DefeatReason` 定位（只换定位键不换通道）。→ `log-cycle-end-screen.md`
- **DnD 式选分支的触发点与 UI** → 触发点 = `eventEnd` 那次 `TryApply` 提交之后，落在事件结算面板内的「剧本段」、不加标识；**剧本段 = 正文（可空）+ 分支（可空）**，纯叙事节点一并定在同一落点。→ `log-plot-branch-choice-ui.md`
- **阵法启动式异能的 UI 宿主** → 己方战场区内该条目自身，长按升起「详情 + 启动」合一弹层；**三态一律禁用整个弹层入口**，与 `Power` 弹层 / 随身抽屉完全同规格（弹层是否只读不影响判定，禁用理由是半屏弹层争屏幕）。→ `log-enchantment-activated-ability-host.md`
- **平台密钥库的后置评估** → 四端能力矩阵 + 五条触发条件（命中即须当次同批裁决，可裁为仍不升级但不得再记为后置）+ 四条非触发 + **不引入平台分支**（判据 = 本端有无可用凭据存储实现的运行期探测）。→ `log-platform-keystore-upgrade.md`
- **`architecture.md ↔ services/*` 系统性对账**（⑤-5）+ **第四 / 第五级层级词是否过早** → 两条一并关闭：层级词表跟真实承重走，第四 / 第五级填实例、拆分判据 3 的宿主口径放宽为「manager 或 module」，同批改 `ADR-0008`；投影纪律上游只留声明（`ResourceElements` 值与 `SettingFields` 默认值从 `architecture.md` 删除、留回链）。→ `log-architecture-services-reconcile.md`

**收窄 1 条：** `LocationCodex` 的「呈现形态」那半已答结（五层套用边界已定，只有单本页内容区不套用），条目收窄为只剩词条深度与那张图怎么画。

**新增 7 条：** `01-combat` 的 `CombatSnapshot.Battlefield` 缺 `faceDown` 按视角填充纪律 · `04` 的 plot 侧 EventBus 事件名与负载未定 · `05` 的 `character-profile/_index.md` 11 处 bump 自称改回链（**本批明确排除**，须与 `sync-service.md` 清单补齐同批做）与平台能力三项事实并入 `.csproj` 后实测批次 · `06` 的主动弃置发起入口与篇章通关那一刻的呈现。

**顺手修两处失真：** `04` 仍把寿元列为隐藏属性（已合并为明文常驻资源、退出该体系）；`02` 把图鉴族说成「其余五本」（应为六本）。

**未触碰 `## derive 就绪度`（强制边界）。** 该小节由 `/assess-derive-readiness` 独占写入，本批答结的多条（尤其 `CharacterData` 字段表与 `MoveCardEffect` 的排除面）已使其中若干行陈旧——刷新方式是择时手动重跑一次该技能，不在本批范围内。

**连带的机械收尾：** `GrantPoolPicker → GrantPoolManager` 在活文档中全量替换完成（9 处，跨 `systems/` 与两份 ADR），过程档案（`handoffs/` · `inbox/` · `answer-logs/`）按溯源三条不改。

