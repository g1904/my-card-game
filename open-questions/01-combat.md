# ① 战斗机制（焦点之首 · 08-06d 后的残留）

> 本分片属 `../open-questions.md` 的当前焦点区。焦点判据见索引文件。

> 本片区历次答结问题的逐条移出记录见 `../answer-logs/`（归档权威在那里，本处不复述）。

> **⚠ 治理提示（08-15d 更新）：** **敌人意图机制已整条移除**（三档揭示 · `IntentCategory` · 快照语义 · 探查通道全部作废），敌人回合的可读性改由逐步执行呈现 + 敌人图鉴 + 战场承担。凡在别处读到「意图三档 / 越阶黑箱 / 仅类别 / 探查」的表述，一律以 `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` 为准；`±2` 赋级带**保留**（其消费点是 `baseMomentum` 起跑线）。

## 能力剥夺与统计计数的残留（08-10c 后）

> 「本轮回禁用」与置换型剥夺片区的**四条并列待答已全部答结**（承载字段 `disabledAbility` · 三档时长与生效判据 · 置换候选池与对价 · `ProfileChangeSpec` 三列表 element 形态 · `PlayerStatistics` 与首批两项 · 宽松同步口径五条 · `PushWarning` 对称落点归内容加载侧），见 `../answer-logs/log-ability-deprivation-and-player-statistics.md`。

- **`RarityTier` 的取池余量三格与功法维分母（08-10c 新增 · 09-09 收窄）。** 五档已定名并挂上四个内容类型；**授予池与战后奖励池的权重表均已定**（战后奖励九行 = 优势档三档 × 篇章三章，非战斗产出侧固定取「优胜那一行 × 本篇章乘数」），**内容侧「每档应有多少条目」的编排口径与首批矩阵已定**，**池的数据载体已定**（逐条编排的具名成员清单，一个条目可属多个池，每池五档非空），**置换候选池不需要权重表**（同档等概率）。仍待定：**三格取池余量**（`GrantPoolMargin` / `ResearchPoolMargin` / `ExchangePoolMargin`）与 `K` 的取值（结构已定，可先填 0 而不阻塞落地）——其中 `GrantPoolMargin` 那格的口径为「**支撑 K 次重复购买 + 留给第 K+1 次的缓冲**」（礼包可重复购买，闸 ① 的结构已定），数值随第一批内容规模一并给。**功法这一维的分母按灵根收缩后的最小可修子集重估；`ADR-0073` 三段处置的边界同按新口径复核。** `ExchangePoolMargin` / `K` 取值给出后，另须复核 **Exchange 逐族库存深度（3 / 2 / 1 / 1 / 0，Σ 7）在闸 ① 上是否仍留得下余量**。**已分场：`PlayerPower` 的通道与边界口径已单独收口，本条只余数值**——两者的解锁条件不同（数值这一条要等内容规模明朗，口径那一条不等），且结构与断言均不依赖取值、可先填 0。→ `systems/balance.md`、`systems/monetization.md`、`systems/services/combat-service.md`。

## 结构与配置的残留

- **`EnemyManaLimit` 初值 5 的校准（08-22 新增）。** 玩家侧 `manaLimit` 随大境界 +1，第三章差距达 4~7 点（玩家约 9~12 / 敌人 5），敌人的行动空间是否仍够用需实测——**代价现已可算：ch3 敌方摆幅约为玩家的 44%**（`systems/balance.md` 规模口径末条）；**参战方对称在 mana 这一项已被明写打破**，该「已知例外」的措辞同待复核。校准顺位已定：先逐条 `EncounterSpec.EnemyManaLimit` 覆写，改全局常量是第二顺位。→ `systems/balance.md`、`systems/services/combat-service.md`、`systems/character-profile/mana.md`。

## 内容与数值的残留（多数留待内容扩充后的统计校准）

- **起始卡组的具体内容。** `CardData` 的字段清单已收口（类型五分、异能三分、次类型、`Pool`、`Subtypes`、目标声明与效果引用、`ManaCost`、`OnPlay`）；**设计取向亦已给出**（`ADR-0228` 三条高光通道 · `ADR-0229` 不设统一底盘 · `ADR-0230` 极限精简为受支持路线 · `ADR-0231` 拆解不得稀有化 · `ADR-0235` ch1 业障低频但沉重，见 `systems/character-profile/deck/_index.md`「内容性格」）；**starter deck 装哪些牌**仍空白——**它正是内容扩充后统计校准的切入点**。规模与量纲的分母已就位（起始 15 张 = 3 门 × 5 · 兑换率 1 · 平均费用 2 · 一份 ch1 费用分布样例见 `handoffs/2026-09-07-combat-scale-baseline.md`）。→ `systems/character-profile/deck/`。
- **关键字与次类型的首批清单（08-16c 新增）。** 两套机制均已完整定案、两套清单均为空；填什么条目要从「哪些组合真的重复了 ≥3 次」倒推，切入点同为 starter deck 的设计过程。→ `systems/character-profile/deck/common-properties.md`、`systems/balance.md`。
- **神通（角色级 `Power`）的强度尺度剩余定量格与获取侧内容口径（09-07 归集 · 09-07 收窄）。** 定性面已答（单条显著强于法则 · 不得累积 · 不设持有数量硬上限）、**战斗内强度闸门已给出初值 25%**、机制面已闭合（四个合法 `Source` · `AbilityChangeSlot` 三种失去形态 · 失去侧频次份额已归 `player-power/_index.md` 的四支目标频次表）。仍欠三个数字：**一次轮回预期获得几条** · **单条相对同 `ManaCost` 法术的效果量系数** · **各 `RarityTier` 应有多少条目**；另欠「各开放通道每轮回出产几条」的 ch1 编排口径。前置是 starter deck 与功法规模落地，故与本片其余数值项同属一次校准。**「一次轮回预期获得几条」答定后须同批重算战后奖励池条目数矩阵的神通行与族占比**（按既有反推式，改的是两格不是形状），并复核「轮回级能力损失」支内部的 神通 ≈0.32 : 法宝一族 ≈0.35 是否仍成立；ch1 的神通供给当前集中在 `Finale`，该数答定后须复核这一编排是否仍成立；另须复核 **`CharacterPower` 族的商店库存深度 ≤ 1**——该格现按池只有 4 条反推的硬下限，不是按供给目标反推。→ `systems/character-profile/power/_index.md`、`systems/balance.md`。
- **道具的种类目录本身（08-26 改写 · 09-10 收窄）。** **三格供给口径已全部答定**——回寿法宝一族的四条通道闸与 L-0…L-3、其余族的可写 key 白名单 `I-13`（战斗外只余回寿一族进账）、Exchange 逐族库存深度五格、事件侧产出量、置换与 barter 的对价，见 `../answer-logs/log-lifespan-item-supply-guardrail.md` 与 `../answer-logs/log-item-family-supply-guardrails.md`。**仍待答的只有目录本身**：`ItemData` 首批该编排哪些条目。目录设计时须把回寿三条与 `I-13` 的白名单一并计入。法宝一族在上层 ≈1.0 分子里的份额**已答定**（≈0.35，逐格见 `../answer-logs/log-treasure-swap-share.md`），不在本条。→ `systems/character-profile/item/_index.md`、`systems/adventure-event/exchange/`、`systems/balance.md`。
- **九行稀有度权重表与篇章乘数的实测校准（09-09 新增 · 不阻塞结构）。** 九行取值已定并落 `systems/balance.md`，但 Tier5 的「≈2.1 次 / 轮回」量级回代假设 `advantage` 三档各占三分之一，而三档分布随篇章右偏 ch1（三档边界三章恒定）⇒ 实际次数会略高。实测样本出来后按同一条式子重算篇章乘数——**改的是三个数，不是形状**；`r_eff < 1` 这条上界在任何重算下都必须成立。→ `systems/balance.md`。
- **`E[道念差]` ch3 的 35% 偏高（09-07 新增）。** 代入本次摆幅口径后，三章的 `E[道念差]` 占一方摆幅 17% / 30% / 35%，ch3 一格偏高。它与 `lossPerMomentum` ch2 / ch3 系数、λ 反推式共用同一格输入，**实测改写它须按同一条式子重算兑换率**（改的是一个数，不是形状）。它另与经验单价 `K` 强耦合：`K` 三格取 5 / 6 / 9 正是为整除 `E[道念差]`（`floor(E/K) = E/K` 靠它成立），故 `E_3` 一改 `K_3` 须按同一条式子重算并保住该性质。**先后已明确：单价先落，`E_3` 实测改写时由同式自动重算**，与「反推输入格被实测改写时 `N` 自动重算」同款处置。→ `systems/balance.md`。

## 呈现的残留

- **战斗屏形态的实测校准项（09-08 新增 · 轻）。** 竖屏分区与叠加元素的形态已整体定案（见 `ux/combat-ux.md` 的两个子块）；仍为初值、须在 18:9 / 19.5:9 / 平板三档竖屏上实测的有：分区总表的各档屏高百分比 · 手牌重叠扇的 40% 露出宽度 · 只读层图标条的 `K = 5` · 己方战场带两侧同挂时的净可用宽度（约 84%，退让位已定）· 台词气泡 ≈1.5 s · 详情 sheet 上界屏高 60% · 见底预警阈值 `DrawPerTurn × 2`。`vision/scope.md` 未给目标分辨率或宽高比，故当前只能给比例。→ `ux/combat-ux.md`。
- **五类卡框色的色相与两枚战报符号的字形（09-08 新增 · 轻）。** 约束已定且可机械核对（缩略尺寸下两两可辨 · 灰度化后仍两两可辨 · 不与呼吸描边 / 上浮描边 / 灰态降饱和三套状态视觉相撞；符号须非数字 · 单字宽 · 两枚互不相似）。**色彩语汇已定**——仙侠意象色、不套五行、意象服从可辨性（`art/visuals/art-direction.md` 的「色彩」）；**本条只剩在该语汇内取值**，归 guide 编写期。→ `art/`、`ux/combat-ux.md`。
