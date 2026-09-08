# `blind` / `ante` 缩放曲线的形态收口

- id: 2026-09-06-blind-ante-scaling-curve
- date: 2026-09-06
- topic: systems/game-progression · systems/balance · systems/_index
- status: distilled
- distilled-to: systems/game-progression.md, systems/balance.md, systems/_index.md

## Intent（distilled）

一句话：**「blind / ante 缩放曲线」这条待答项本身不成立**——`blind` 已由 `combatTier` 三档完整承载且取值缺口另有登记；`ante` 在本作没有对应物且被结构性否决（**定案：不设 ante 原语、不设章内绝对难度阶梯**）；「缩放曲线」的实体改写为一张既有曲线登记表 + 两条分格轴纪律。占位句是 2026-07-24 文档重构（`blinds-antes.md` 并入 `game-progression.md`）时搬过来、此后各机制在别处逐条落定而没被清掉的残留——与同日「敌人道念产出缩放曲线」的收口同型（同为待决项的转发终点写着相反结论）。

来源：`inbox/solution-draft-blind-ante-scaling-curve.md`（2026-09-06 批量评审 status: decided）。

### 一、`blind` 侧：由 `combatTier` 完整承载，无第三条缺口

借词侧的四个问法逐项已有承载：过关条件 = `EncounterSpec.TurnLimit + VictoryRule(WinMargin)`（8/0 · 10/1 · 12/0 已定）；出场条件 = 类型权重掷出 / `Finale` 满级 `eventPriority = 1`（已定）；难度缩放 = `±2` 赋级带 + `FinaleDiff`（已定，八条校验）；奖励 = 支路 A 线性单价 + 支路 B `advantage` 三档（形态已定）。**残余缺口只有两处取值**——三档 `BaseReward` / `RewardPoolId` 厚薄（`scoring.md` / `combat/_index.md` 待决已登记）与战后奖励池各档权重（`balance.md` 待决已登记）——删本条零信息损失。

连带：活文档正文里把 `blind` 当**本作实体**谈的位置全部改写为 `combatTier`；`terminology.md` / `references.md` / 各档位表的**对位括注**（说明 Practice 对位 small blind 这一借鉴来源）保留不动。判据：**注释里的 blind 指 Balatro 的东西，正文里的 blind 指本作的东西**，只清后者。

### 二、`ante` 侧：本作无对应物，正式记为「不设」（用户裁决确认 · ADR 候选）

Balatro ante 的三个构成要件在本作一个都不成立：① 没有可被抬高的阈值（道念是双方对抗的相对量，chips × mult 结构已否决）；② 难度缩放是相对量且自动跟随（`±2` 带 + `baseMomentum` 跨度内生兑现「越往后越难」），再叠一条随进度递增的绝对阶梯 = 在唯一可见的难度刻度之外开一条不可见强度轴，且任何实现都必须产出带外 `diff`、直接撞 `±2` 硬规则；③ 没有可对位的循环单位（Finale 只在篇章边界出现一次，无固定节律）。最接近 ante 的单位是「篇章」，但它已有名字与权威，起别名只会同页两义（与 `Tier` / `RarityTier` 不复用、`EnemyLevelRange` 不叫 `LevelBand` 同一条纪律）。

**ADR 候选：** 不设 ante 式章内绝对难度阶梯；随进度变化的数值分格轴只有**全局等级序（1–22）**与**篇章（ch1–ch3）**两条，需要第三条轴（章内进度 / 已走 location 数 / 已完成事件数）须先立 ADR。归 `/write-adr` 立档。

### 三、「缩放曲线」的实体 = 十一条既有曲线登记表 + 两条分格轴纪律

十一条曲线（`baseMomentum` 22 格 · 赋级带 + `FinaleDiff` · `combatTier` 遭遇参数 · `lossPerMomentum` · `rewardPerMomentum` · `advantage` 三档 · `S(c)` + 档偏置 · `lifeSpanCost` 21 格 · 经验阈值曲线 · `BatchSizeWeights` · `RealmBreakthroughManaBonus`）逐条已在各自权威文档成文，从无一份总表——这正是它读起来像「连形态都没有」的原因。登记表落 `game-progression.md`「难度与数值缩放的分格轴」小节（进程侧持形态，取值权威留各处，登记表只写指路 + 状态、不复制数字）。

两条轴的分工一句话：轴 ①（全局等级序）承载「谁比谁强」（相对，敌人跟随角色）；轴 ②（篇章）承载「数字量纲膨胀多少」（绝对量纲吸收）。十一条曲线逐条可归入其一、无例外——这是纪律不是臆造的证据。纪律的落点是设计评审（第 4 级：零成本、零保证，如实标注），`/audit-content` 无从检查、不进自动校验。

### 已知代价（如实写下）

- 第三条分格轴从此需要一次 ADR 才能引入；若实测发现「章中段太平」，补救限定为调既有曲线（`BatchSizeWeights` / 赋级权重的剧本乘性调制 / `eventCountLimit` 序列），关掉了「补一条轻量阶梯」的快速手段——这正是本条要的约束力。
- ch2 / ch3 中段的节奏缺口（每 12–14 个事件才升一级）只由经验进度条补一半，维持现状。
- `.claude/knowledge/systems/_index.md` 与 `dictionary.md` 的 ante / blind 摘要随之失真，归 `/sync-knowledge` 后续对账。

### 备选方案否决（摘记）

保留待答等内容阶段（不是取值缺口，等不来输入，反而持续制造虚假承重卡点）· `ante` 作篇章别名（同页两义）· 登记表进 `balance.md`（表回答的是进程侧问题，维持「进程侧归 game-progression、数值归 balance」既有分工）· 轻量「按进度递增」阶梯（用户裁决确认不设；唯一不撞硬规则的形态也会引入第三条分格轴并与越阶规则重复施压，重提须走新增 ADR）。

## Clarifications（评审裁决）

- 「blind / ante 缩放曲线」是待补的设计还是占位残留 → **占位残留，待答项整条撤销**；`blind` 侧由 `combatTier` 承载、`ante` 侧**裁决确认不设**（含备选④「轻量阶梯」一并否决）。

## Open questions

- 无新增。残余三处缺口（三档 `BaseReward` / `RewardPoolId` 厚薄 · 战后奖励池各档权重 · 卡牌道念量纲与 `lossPerMomentum` ch2 / ch3）全部另有登记，不因本条改变。

## Notes / triage

- `systems/game-progression.md`：`:3` 抬头去 ante / blind；「blind / ante 缩放」小节改写为「难度与数值缩放的分格轴」（登记表 + 两条轴纪律 + 不设 ante 正面陈述）；待决条目整条删除。
- `systems/balance.md`：抬头与集中管理句的「ante 曲线」改「篇章 / 等级维度的缩放曲线」；「blind / ante 缩放曲线」待决整条删除。
- `systems/_index.md`：两行摘要去 ante / blind。
- 保留不动：`terminology.md:187-189` · `vision/references.md:12` · `scoring.md:60` · `combat-service.md:38` · `combat/_index.md` 与 `adventure-event/_index.md` 的对位括注 · `balance.md` 档位表括注 · ADR-0002 / ADR-0005 内的提及。
- open-questions 侧（就绪度卡点 ③ / 第 17 步排除面 / 最短解锁路径第 6 条 / `deferred-content.md` 半句）由台账通道统一撤条。
