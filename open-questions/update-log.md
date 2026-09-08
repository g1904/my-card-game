# 待答清单更新日志

> 每次 `/analyze-new-ideas` / `/summarize-open-questions` 运行后，在此**顶部**追加一条更新摘要：本次答结了什么、推翻了什么、新增待答落在哪个分片。问题条目本身在 `../open-questions.md` 的各分片里；已答定问题的逐条移出记录在 `../answer-logs/`。
>
> 本文件只记「发生了什么变化」，不承载问题条目本身。

> **只保留最近 10 条。** 更早的条目原样移入 [`update-log-archive.md`](update-log-archive.md)（按时间正序），
> 一字未改、仅换了文件——本日志与归档合起来即全部历史（`decisions/ADR-0005`：台账不无限膨胀）。

## 2026-09-07（`/analyze-new-ideas game` · solution-draft-achievement-schema-and-rewards · 移出 3 全条 + 1 部分 · 新增 0 条 · 单库）

- **范围：** `inbox/solution-draft-achievement-schema-and-rewards.md`，已批量评审、2 项裁决（1 取向 + 1 张力）写回草稿视同用户拍板，**无待问项**、直接落笔；其余 44 项按通行做法 / 既有推演采纳。另四项顺带机械落笔（答案已定）。
- **移出 3 全条：** ① 成就奖励的两档各给什么（`07-codex-monetization.md`）→ **60% 古宝 / 90% 法则**，每档恰一个成就限定专属条目，`Scope` 不进字段；② 成就两档奖励内容（`deferred-content.md`，与 ① 同源）→ 该条改写为只欠条目的内容编排项；③ AchievementManager 的触发采集面（`deferred-content.md` + 三处主题文档待决登记）→ **与 `CodexManager` 同构的第三形态**（服务内 spec 旁听 + EventBus 被动订阅两支，分界判据 = 是不是一次落档变更），`ReportProgress(AchievementSignal)` 整行取消。逐条见 `../answer-logs/log-achievement-schema-and-rewards.md`。
- **移出 1 部分（`deferred-content.md`「元进程持久化字段结构」）：** `Achievement` 条目 schema 那一半答定（两个顶层键 + 两条 record + 内容侧两个类 + 两条写入通道 + v1 清单补三行、仍属 v1 不 bump）；**各账号级条目的解锁 / 获取 / 失去触发仍留清单**。
- **两项 interview 裁决（草稿评审阶段已定）：** ① **隐藏成就计入组内进度分母** ⇒ 90% 档必须碰到约一半隐藏成就，`Hidden` 只承担渲染语义；② `ux/screen-flow.md` 篇章结束屏「成就零呈现」**松动措辞、不松动结论**——成就发放留在收口那一次 `TryApply` 事务内，零新增存档点 / flush 点，`life-cycle-service.md` 四步时序一字不改。
- **四项顺带的纯机械落笔：** ① `PlayerProfile` 字段表 `achievement` 行写入通道改 `AchievementElements` + 新增 `achievementGroup` 行（表行 16 → 17，序号顺延）；② 「两档奖励三选（PlayerPower / PlayerItem / 账号级）」的陈旧登记四处订正（`deferred-content.md` · `ux/screen-flow.md` 两处 · `profile-service.md` 待决区）；③ `content/_index.md` 的 `achievement/` 就绪度 🟠 → 🟢 并新增 `achievement-group/` 一行；④ 「采集面未定」的四处登记同批清空。
- **结构改动：** 新增顶层键 `achievementGroup` + `ProfileChangeSpec` 两条新列 ⇒ v1 清单 +3 行，**首发前仍属 `schemaVersion` 1、不 bump、零迁移**。事件面新增 `AchievementCompleted`。**未在对侧库补登条目**——两个顶层键是否进透明段属跨边界事实，本库倾向不进（成就不参与后端复算），已记为 handoff 的 Open question。
- **`## derive 就绪度` 小节原样未动**（归 `/assess-derive-readiness` 独占写入）。

## 2026-09-07（`/batch-analyze-new-ideas game` · 2 份 solution-draft · 移出 6 条 · 新增 3 条 · 单库）

- **范围：** `inbox/solution-draft-combat-scale-baseline.md` 与 `inbox/solution-draft-cosmetic-monetization-shape.md`，两份均已批量评审、裁决写回草稿（视同用户拍板），故**无待问项**、直接落笔。两份写入面不相交，无跨草稿矛盾。另顺带两项纯机械落笔（答案已定）。
- **移出 5 条（`01-combat.md`「内容与数值的残留」）：** 卡牌产 / 削道念的量纲基准 · 卡组规模的实际取值 · 功法的规模参数 · 卡牌费用曲线是否随境界上移（含 `RealmBreakthroughManaBonus` 初值 1）· 牌流三个基准值 4 / 2 / 7 的取值校准。**它们本就是同一个未知的五个面**，由四条硬约束（牌流恒 14 张 · `manaLimit` 三章末 · `baseMomentum` 与 `E[道念差]` · 追分锚点）联立反推出唯一自洽解，逐条见 `../answer-logs/log-combat-scale-baseline.md`。
- **移出 1 条（收窄为事实确认，`07-codex-monetization.md`）：** 「纯外观付费点做成什么」两半（品类 / 字段形状）均答定，仅余「牌堆背面在竖屏战斗屏上是否有稳定可见面」一项待确认，已改写为一条轻量条目并入竖屏 UX 专场。
- **两项 interview 裁决（草稿一）：** ① **ch3 的越阶追分改由神通 / 战斗内法则 / 道具承担**（接受「光靠卡组追不平」；`baseMomentum` 表、`±2` 赋级带、`MaxTier` 上界 5 三者均不改动）；② **「常规遭遇永不疲劳」被接受**，不触发「疲劳几乎从不触发」这条重开判据（疲劳在每一场天劫与每一个轻量敌人上现身即算咬合），起始 15 张维持。
- **两项 interview 裁决（草稿二）：** ① **品类选 A**（角色皮肤首个 · 卡背第二 · 界面主题不做）；② **松动「`PlayerEntitlement` 用具名字段而非集合」这条既定判据**，收口为「禁的是以付费点种类为 key 的开放容器；内容条目实例的持有集仍是 id 集合」——该判据的**原文已就地改写**（`systems/player-profile/_index.md`），不新开取代条目。
- **顺带答定（草稿一牵出）：** 神通的战斗内强度闸门 **X = 25%**（读法：单条神通的上沿 ≈ 老账号全部法则合计的上沿）。它是 `01-combat.md` 神通条**三个定量格之外**的一格，故该条**收窄而未移出**。
- **新增 3 条（均为落笔牵出的标定复核项，不阻塞结构，全落 `01-combat.md`）：** ① 量纲基准落笔牵出的三条复核（`itemPowerRatio` 的 ×1.10 建议上调至 1.15–1.20 · 以 `baseMomentum` 计的法则闸门在产出面上逐章加重约 3 倍 · `advantage` 三档分布右偏 ch1）；② `E[道念差]` ch3 的 35% 偏高；③ `07-codex-monetization.md` 的牌背可见面确认（形式上是原条目的收窄，计入移出）。
- **两处既有条目就地更新（前提已变）：** `EncounterTighten` 六个界常量条——**「被 4 / 2 / 7 校准阻塞」这条阻塞已解除**；`EnemyManaLimit` 初值 5 条——代价现已可算（ch3 敌方摆幅约为玩家的 44%）。
- **顺带的两项纯机械落笔：** ① `vision/scope.md`「范围之外」的外观装饰一行措辞改齐为「架构预留、首批不做」（答案定于 08-19，见 `../answer-logs/log-bundle-grant-ordinal-authority.md`）；② `systems/scoring.md` 两处「固定 10 个回合」订正为三档口径（终止条件 = `EncounterSpec.TurnLimit`、`Practice` 8 / `Standard` 10 / `Finale` 12），与同文件其余处收敛一致。
- **零结构改动：** 两份草稿合计无新字段、无新枚举、无新平衡资源、无存档 schema 变更、无迁移；外观付费点首批一格不落。**未在对侧库补登任何条目**（外观首批不做 ⇒ 当前不产生后端承接项）。
- **`## derive 就绪度` 小节原样未动**（归 `/assess-derive-readiness` 独占写入）。

## 2026-09-07（`/summarize-open-questions game` · 全量整理 · 4 个只读采集代理并行 · 移出 1 条（部分）· 新增 3 条 · 订正 1 条 · 单库）

- **范围：** 客户端库全部主题目录（`vision/` · `systems/` · `art/` · `ux/` + 根级三份）共约 60 份带 `## 待决问题` 的文档，加 169 份 handoff 的 status 复扫、9 个分片与两库 `cross-boundary.md`。**不引入新想法、不裁决任何问题**。
- **handoff 复扫结论：** 169 份中 **166 份真实 handoff 全部 `distilled`**，`triaged` 0 份；剩余 2 份 `raw` 是 `_TEMPLATE.md` 与自述「写好真实的之后请删除」的 `2026-07-12-example.md`（其示例内容描述「回合结束弃牌 / 手牌上限初始 5」与现行设计的「没有弃牌机制」直接冲突，属应删残留）。⇒ **无未消化输入**。
- **跨库对账：** 两库 `cross-boundary.md` 的「待承接」**双双为空**，无一侧已定案而另一侧零承载的情形 ⇒ 本次**未在对侧库补登任何条目**，只写主库。
- **移出 1 条（部分）：** `deferred-content.md` 的「PlayerPower 获取 / 失去触发与公平性」——「**是否影响 cycle seed / 计分公平**」与 pay/grind-to-win 的**定性边界**已由 `systems/player-profile/player-power/_index.md` 的「意图」答定（账号级 RNG 不派生自 `CycleSeed`、不消耗子流 ⇒ **两者不相交**；边界为定性四条，随附的 10% / 25% 两个百分比自标为评审参考、非承重）。**获取 / 失去的具体触发仍留清单。** 见 `../answer-logs/log-0907.md`。
- **新增 3 条（均为「主题文档有、清单零承载」的归集，非新问题）：** ① `01-combat.md` —— **牌流三个基准值 4 / 2 / 7 本身的取值校准**（此前只作为 `EncounterTighten` 六个界常量的阻塞因素被提及，未立条）；② `01-combat.md` —— **神通（角色级 `Power`）强度尺度的定量三格与获取侧内容口径**（一次轮回预期几条 · 相对同 `ManaCost` 法术的效果量系数 · 各 `RarityTier` 条目数）；③ `02-event-options.md` —— **事件类型配比的实测校准复核**（配比初值 09-06 已答结移出，校准尾巴仍挂 `balance.md`，且校准对象是**实现分布**而非供给分布）。
- **订正 1 条：** `05-service-contracts.md` 中 `schemaVersion` 登记表残留的第二件登记错了对象——此前写「那条 `/sync-knowledge` 对账断言的实际生效」，而该断言在 `profile-schema-versions.md` 中已是既定纪律、不在其待决小节内；主题文档实际留在待决的第二件是 **v1 的 golden 形状快照 `profile-shape-v1.json` 待建**（与本片三项 `.csproj` 实测同批落地）。已就地改写。
- **充实 1 条：** `deferred-content.md` 的 `visuals/animations/` 条目补上「制作方式（自制 / 外包 / 工具生成）」，并把「须可跳过 / 可加速」改写为现行事实——战斗内演出**无跳过控件**、时长由三重护栏收敛，本条待定的是**护栏内每类动画的时长上界与缓动**。
- **未动的分片：** `03` · `04` · `06` · `07` · `cross-boundary`（逐条与主题文档比对后无增删）。
- **索引：** 「最近更新」行更新；「下一阶段」的待固化 ADR 候选由 1 条增至 2 条（新增 `content-service.md` 自标的「随包基线条目永不删除；退役 = 永久禁用 + 掏空，基线快照归档步机械核对 `Id` 超集」）。**`## derive 就绪度` 小节原样未动**（归 `/assess-derive-readiness` 独占写入）。
- **⚠ 本次报告了 7 处主题文档自身的错漏 / 矛盾，均未擅自改动**（含 `terminology.md` 的 `lossPerMomentum` ch1 = 1 陈旧值、`combat-service.md` 的「固定 10 回合」与三档 8/10/12 冲突、`profile-service.md` 的成就采集面待决与 API 契约表 `ReportProgress` 抵触等）。详见本次运行报告。

## 2026-09-07（`/write-adr game`，范围 `all` · 固化 24 份新 ADR · 候选清单清空）

- **两条登记候选全部立档：** `ADR-0163` 不设 ante 式章内绝对难度阶梯 + 随进度数值的分格轴只有两条（来源 `handoffs/2026-09-06-blind-ante-scaling-curve.md`，事实依据 `systems/game-progression.md:184-204`）· `ADR-0182` 随包基线 `Id` 超集不变式与退役三分（该条由 `systems/services/content-service.md` 自标、2026-09-07 归集入清单，事实依据 `:88-114`）。
- **另逐份核对 19 份未被任何 ADR 引为来源的 handoff**，补固化 22 条散落定案 → `ADR-0159` ~ `ADR-0162`、`ADR-0164` ~ `ADR-0181`。按批：09-06 共 20 条（失去能力频次预算取绝对次数 · 主动放弃角色入口与 `ongoing` 限定 · 篇章时长上移 ≈60 分钟 · 轮回出口三层处置 + 痕迹跨篇章只追加 · `AbilityStatusChanges` 列与 `SetAbilityStatus` 门面 · 隐藏属性收口两项 + 准入四问 · 战后奖励四族与 `Practice` 档族级排除 · 演出跳过权按作用域分档 · 敌人产出同因不设独立曲线 · `BaseTypeWeightsData` 三条校验与不校验和为一 · `combatTier` 1:1 编排口径 · 类型修正护栏咬占比只审计 · 失败容错 N = 2 + 偏紧如实入账 · 不给「距 Finale」前瞻读数 · IAP 选型 / 渠道封装 / `IPurchaseBackend` / Store 入口不渲染四条）· 09-02 共 2 条（`MoveCardEffect` 补 `Side` 格 · 平台密钥库五条触发条件与不引入平台分支）。
- **三份历史 handoff 判定不建档：** `2026-08-02c`（整个意图族已被 `ADR-0059` 明文推翻）· `2026-08-12b`（`Source` 分域已由 `ADR-0051` 承载）· `2026-07-12-example`（模板示例文件）。
- **台账：** `decisions/_index.md` 新增 24 行（09-06 组 22 行置顶、09-02 组 2 行插入既有 09-02 段首）；建档前双向对账 **158 文件 ↔ 158 行零缺口**，建档后 **182 ↔ 182**。`open-questions.md`「下一阶段」的 ADR 候选清空（移除 2 条，剩余 0 条）。**`## derive 就绪度` 与其余各节一字未动**（`/write-adr` 不碰它们）。
- **未随本次收口、留给 `/analyze-new-ideas` 或用户的三处主题文档失真**（本技能不改主题文档）：`systems/enemies/common-properties.md:26` 仍写 `IgnoresProtection` ≈5%（权威已降为 ≈3%）· `terminology.md:91` 与 `systems/adventure-event/common-properties.md:85` 仍留旧目标时长 30–40 / 35–45 / 45–55 · `systems/services/content-service.md:490` 的「ADR 候选，待 `/write-adr` 立档」行应改为回链 `ADR-0182`；另 `systems/services/account-service.md:241` 的 `Source:` 行漏列 `handoffs/2026-09-02-platform-keystore-upgrade-triggers.md`。

## 2026-09-06c（`/batch-analyze-new-ideas` · 7 份 decided solution-draft / 5 分片 · Phase A 并行 + Phase B 五波串行 · 合并 interview 1 题 · 移出 3 条 · 新增 1 条 · 单库）

- **七份草稿均为已评审 `decided`**，Phase A 五分片并行只读校验共报 🔴 0 · 🟠 1 · 🔵 31——唯一 interview 题：rescale 稿自留的 `balance.md`「C1 ≳ 140」句处置，**用户裁 (a) 按自洽重算值改写为 C1 ≳ 83（≈ ch1 预算 8%）**。跨分片核对无矛盾（rescale 与配比稿关键数字逐格一致；`player-power` vs `balance` 的编排规则既有矛盾由频次预算稿收口）。
- **落笔主体（Phase B 按写入面五波串行）：** 篇章时长上移 ≈60 分钟的连锁重标定（21 格定价表 λ 层重算 15/17/44 · 事件数 114 · 经验曲线 79/247/391 · `S(c)` 10/23/39）→ 失败容错 **N = 2 三章统一**（balance.md 新增反推台账整节）→ `BaseTypeWeights` 五格初值 + `combatTier` **1:1 编排口径**（覆盖率 75% → ≈55% 同批）→ **blind / ante 待答项判定为占位残留整条撤销**（ante 确认不设，登记 ADR 候选）→ 失去能力四支频次预算配平（持久三支合计 ≈1.0 次 / 轮回，`IgnoresProtection` 移出上层分子 5% → 3%）→ 五条机制矛盾收口（战后奖励池改四类混合 + `Practice` 档整族排除 `PowerData` 为唯一结构性后果）→ 六条过时措辞收口（含「战斗外演出默认可跳过」的选项 A 裁决落 `animations/_index.md`）。
- **移出 3 条：** `06-meta-progression.md` 的「失败螺旋的容错量验收」与「失去能力四支频次预算」· `02-event-options.md` 的「五类配比与 `combatTier` 三档配比」。**新增 1 条：** `06-meta-progression.md` 的「胜侧 `rewardPerMomentum[experiencePoint]` 是否计入经验供给账」（容错量标定牵出的既有账目缺口）。另撤 `deferred-content.md` 的 blind / ante 半句。
- **索引台账同批收口：** 「仍在的承重卡点」三条降两条（blind / ante 撤条）· 此前登记的十条 🟠 / 🟡 台账失真**全部收口或确认已修**（`lossPerMomentum`「三种口径」经直读判不成立）· 「落笔前的零决策修正」五项全部完成清零 · `profile-schema-versions.md` 三个标准小节补齐 · `account-info.md` 待决撤销。
- 对应 answer logs：`../answer-logs/log-chapter-duration-rescale.md` · `log-failure-spiral-tolerance.md` · `log-event-type-mix-ratios.md` · `log-blind-ante-scaling-curve.md` · `log-ability-loss-frequency-budget.md` · `log-mechanism-contradiction-roundup.md` · `log-stale-wording-roundup.md`。**`## derive 就绪度` 小节本批仅应用草稿授权的台账更正**（失实登记删除 / 收窄），全量重估仍归 `/assess-derive-readiness`——本批落笔量大，建议尽快跑一次。

## 2026-09-06b（`/batch-analyze-new-ideas game` · 6 份 solution-draft / 4 分片 · 两波次 · 合并 interview 7 题 · 移出 6 条 · 新增 0 条 · 单库）

- **六份草稿均已批量评审**（前五份 `decided`、裁决回写视同用户拍板；第六份 `awaiting-review` 经用户当场放行）。Phase A 四分片并行只读校验，合并去重后 **7 题**分两轮问齐，全部当场答定、**零 `[采纳推荐 — 待复核]` 项**。
- **移出 6 条：**
  - `06-meta-progression.md` **3 条**：**中长期规划感的来源** → 空间那一角**不补**，三章一律不显示任何「距 Finale / 距圆满」读数（草稿主体提案 A–G 整体被否），同批把 Finale 触发条件 `level == 该境界末级`（13 / 17 / 21）钉进 `game-progression.md`（只回链 `future-event-service.md`，不复述抬升条件表）· **主动弃置的发起入口** → 主菜单「切换篇章」面上 `ongoing` 角色行的次级动作 + 就地二段确认 + 无冷静期无撤销，只对 `ongoing` 开放（不新增 `completed → defeated`，代价 = 已通关角色档无清理通道），`RetriesLeft == 0` 走新增第三条键，`DefeatCharacter` 扩为 `(reason, characterId)`，中文 UI 措辞改「放弃」· **`completed` 是否清理角色数据** → 「清理」拆三层，L1+L2 两条出口一视同仁、L3 只在 `defeated` 上做；单记录 + 新字段 `chapterStartSnapshot`，`defeated` 留墓碑（snapshot **只回收 ch1 墓碑**）、**ch3 通关档永久保留**，**`pastEvent` / `pastItemUse` 跨篇章只追加、重试也不回滚**（推翻草稿原案），两屏摘要的 `PastEventCount` 改由篇章起始 `Seq` 锚点求差。
  - `04-hidden-attributes-plot.md` **1 条（部分）**：**是否还有第三项隐藏属性** → **否，定稿为道心 / 煞气两项**；正面产物 = 准入四问（scope 之内 · 不可替代 · 必须连续且必须隐藏 · 消费方是调制），不留占位枚举成员、不预留 band 字段。同条另两项（逐条目映射 · 剧情线内容）不再被「清单未定」阻塞，转为纯内容编排工作量。
  - `deferred-content.md` **1 条（部分）**：「元进程持久化字段结构」的 **`status` × 拥有 / 失去那一半 + 整个 ⚠ 矛盾段**。直读裁定该「矛盾」**不成立**——`profile-service.md:420` 那对括号是显式排除、明写已成文，被索引读成了未定。编码本体零改动，**唯一真实缺口 = 无写入通道**，补为 `ProfileChangeSpec.AbilityStatusChanges` 新列 + 门面收敛 `SetAbilityStatus(kind, scope, abilityId, enabled)`，四类一律对玩家开放开关。该条的 `Achievement` schema 与账号级触发那一半**仍留清单**。
  - `01-combat.md` **1 条**：**敌人各等级的道念产出缩放曲线** → **`systems/balance.md` 侧成立**，敌人侧不存在独立产出缩放曲线，产出决定因素与玩家完全一致，等级只经 `baseMomentum` 决定起跑线。三份主题文档 `## 待决问题` 内的「未定」残留各一条随之删除，`balance.md` 补一句 `ADR-0090` 档案回链。**本条为回归登记**（08-25 已答结归档），故**不新建 answer log**——`answer-logs/log-0823b.md` 已是它的归档条目。
- **新增 0 条。** 七题全部在合并 interview 当场答定。
- **附带清理：** `architecture.md` 的 `enum HiddenStat` 由三成员收为 `{ Faith, Bloodlust }`、「三个属性」→「两个属性」、已随 ADR-0127 退役的「宽类型 + 加载期校验收窄」口径改写（`ADR-0129:19`/`:28` 同步订正）· `balance.md` 跨档叙事目标密度 6–10 → **≈2–4 条 / 轮回**、文案总量 8–12 → **4–6 条**、派生量「每 8–14」→「每 21–42 个事件一条」· `item/_index.md:3` 与 `item/common-properties.md:3` 的「占位结构，细节待定」抬头（三次点名）**本批闭合** · `character-profile/_index.md` 的「隐藏属性完整清单是否还有第三项」残留待决条删除 · 四份下游文档指向「`profile-service.md` 同名待决项」的悬空回链全部清理 · `ux/screen-flow.md` 两处写死的 `pastEvent.Count` 改为锚点求差口径。
- **就地订正三处 ADR 措辞**（用户当场授权，结论一格不动、不新增编号、`decisions/_index.md` 零改动）：`ADR-0129:19`/`:28` · `ADR-0148:16`/`:45` · `ADR-0004:16`。
- 对应 answer logs：`../answer-logs/log-completed-data-retention.md` · `log-status-vs-ownership-encoding.md` · `log-character-discard-entry.md` · `log-third-hidden-stat.md` · `log-finale-distance-foresight.md`（各 1 条）。**`## derive 就绪度` 小节本批未动**（`/assess-derive-readiness` 独占），其中至少六处判据已因本批落笔过期，建议下一步跑一次全量就绪度扫描。

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
