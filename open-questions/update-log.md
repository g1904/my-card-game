# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

> **只保留最近 10 条。** 更早的条目原样移入 [`update-log-archive.md`](update-log-archive.md)（按时间正序），
> 一字未改、仅换了文件——本日志与归档合起来即全部历史（`decisions/ADR-0005`：台账不无限膨胀）。

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

