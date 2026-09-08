# 五类事件配比与 `combatTier` 三档配比

- id: 2026-09-06-event-type-mix-ratios
- date: 2026-09-06
- topic: systems/balance · systems/adventure-event（顶层 + combat）· systems/services/future-event-service · systems/game-progression
- status: distilled
- distilled-to: systems/balance.md, systems/game-progression.md, systems/adventure-event/_index.md, systems/adventure-event/combat/_index.md, systems/adventure-event/common-properties.md, systems/services/future-event-service.md

## Intent（distilled）

一句话：**五类事件配比与 Combat 内 `combatTier` 配比全面定案**——`BaseTypeWeights` 五格初值 0.35 / 0.13 / 0.13 / 0.32 / 0.07（三章同值仍写三行）、载体为新平衡资源 `BaseTypeWeightsData`（三条加载期校验、刻意不校验和 = 1）、`Practice : Standard = 1 : 1` 三章统一且为**内容编排口径而非运行期旋钮**、调制侧只补编排建议区间（`[0.5, 2.0]` / 占比 `[5%, 55%]`），管线与 schema 零改动。

来源：`inbox/solution-draft-event-type-mix-ratios.md`（2026-09-06 批量评审 status: decided）；取值由同日 `handoffs/2026-09-06-chapter-duration-rescale.md` 的新口径反推定案（`T_c` 55 / 58 / 68 · 事件数 35 / 36 / 43 合 114）。

### 一、`BaseTypeWeights` 五格初值（定案）

三章同值 `Combat 0.35 · Research 0.13 · Explore 0.13 · Exchange 0.32 · Travel 0.07`，仍写三行（分格轴留着，校准时直接填——与 `BatchSizeWeights` / `EnemyLevelingData` 同款）。要点：

- `Combat 0.35 > Exchange 0.32` 满足「Combat 最高频、幅度略高于 Exchange」的裁决；差 0.03 刻意取小（`t` 比 2.25 倍，每挪 0.01 一轮回少约 0.7 个事件）。
- `Travel 0.07`：location 数升至 7–9，管线内主动换图须跟上，否则「换图是可选策略」退化为被迫。
- 三条验算全过：Combat 最高频三口径 · ch1 购买力（`BaseReward = 9.5S`，`S(ch1) = 10` ⇒ 95，25 格商店表零改动）· 三章时长 55.5 / 57.5 / 68.2 分钟。
- 逐类跨章推算（`P` = 管线事件数 30 / 31 / 37）：Combat 常规 10.5 / 10.9 / 13.0（+3 Finale ≈ 37 场）· Research 与 Explore 各 ≈ 12.7 · Exchange ≈ 31.4 · Travel（加权 + 闸门）≈ 20。

### 二、载体与校验

- 新开 `BaseTypeWeightsData : Resource, ISingletonContent` + 内嵌 `BaseTypeWeightsRow`（五个具名 `float`），三章各一行具名字段（篇章数是固定结构，不用索引数组）；经 `Content.Single<T>()` 取。五格具名而非数组：基础权重表五格必须齐全，具名字段让缺行在编译期即不可能。
- 加载期校验三条（`PushError` + 抛，带章号 / 类型名）：某章五格全 0（归一化除零）· 存在负值 · 任一格 `== 0`（静默改支撑集，与「类型修正只改权重不改支撑集」正面冲突）。
- **刻意不校验「五格和 = 1」**（与 `BatchSizeWeights` 相反，必须写明）：归一化在类型分布层发生，乘完修正后和本就不为 1；和 = 1 断言是自证冗余，且会逼作者每调一格重算另外四格。初值取和为 1 只是呈现约定。

### 三、调制编排口径（零新增结构）

单条 location / arc 的类型修正建议落 `[0.5, 2.0]`；乘完全部修正并归一化后任一类型占比建议落 `[5%, 55%]`。护栏咬在占比而非系数上（两个大格实际可用约 ×1.7 / ×1.5，三个小格可用满区间）。落点 = `/audit-content` 汇总、只报告不阻断（与 `lifeSpanCost` 条目级偏移同款）；**不加运行期钳制**——钳制会把「只改权重」变成「有时也改权重的大小关系」，`> 0` 校验已封死唯一的结构性风险。

### 四、`combatTier` 配比

- **Finale 不作任何扣除**：它在 ④ 之前旁路、恒占一槽，`Combat` 格只标定非 Finale 战斗（实际战斗数 = `0.35 × P + 1`）；`Practice : Standard` 分母同样不含 Finale。
- **`Practice : Standard = 1 : 1` 三章统一**，两条独立依据：Explore 的 `t = 1.6` 标定已内含 1:1（改它要重算定价表）；新 ch1 参考构成 5 / 5 同时过时长、结转、购买力三道验收。「后期更险」不由配比承载（已由越阶末两级 + `baseMomentum` 跨度独立承载）。
- **载体 = 内容池编排口径，不是运行期旋钮（承重）**：`combatTier` 是模板常量，十步管线没有任何一步掷 tier ⇒ 实际比例 = Combat 条目池组成 × `SelectionWeight` 的涌现结果，与 Explore 真身分布同构。不新增字段 / 表 / 管线步骤；台账落 `adventure-event` 类型档案 Combat 分区，`/audit-content` 汇总比对（只报告不阻断）。调制侧推论：location / 剧本改得动「有多少 Combat」，改不动「其中多少是切磋」——只能经 `PlotModulation.EventWeights` 间接影响，落内容面而非约束面。

### 五、供给分布 ≠ 实现分布（校准须知）

`BaseTypeWeights` 决定**摆在玩家面前的**分布；实际走过的构成 = 供给 × 玩家偏好。实测统计要同时记录「供给了什么」与「选了什么」；不为此加机制——偏好是玩法信息，不是要抹平的噪声。

### 备选方案否决（七条，摘记）

旧初值 0.28/0.14/0.14/0.39/0.05（与「Combat 最高频」矛盾，被裁决取代）· `CombatTierWeights` / 管线加 tier 掷骰（撞「一个条目只有一个档」）· `Practice : Standard` 逐章右移（定价表 Explore 行要按章重算，代价失配）· 并入 `LifeSpanCostTableData`（行粒度不同，三问判据不同住）· 逐章分行（为估算量做分化是把噪声焊进配置）· Travel 填 0（校验拦 + 自愿换图被预设存在）· 每章硬性配额（撞「本服务不持有跨批次状态」）。

## Clarifications（评审裁决）

- 「Combat 是最高频的一类」vs 旧反推 `Exchange` 最高 → **保措辞、改配比迁就，幅度 = 略高于 `Exchange`**；篇章时长整体上移以容纳增量（时长裁决见 `handoffs/2026-09-06-chapter-duration-rescale.md`）。
- `Practice : Standard` 比例 → **1 : 1 三章统一，载体为内容编排口径**（无运行期旋钮、不新增字段）。
- Finale 的「扣除方式」→ **不作任何扣除**（Combat 格只标定非 Finale 战斗）。
- 调制形态 → **零新增**（乘性已定），只补编排建议区间，不加运行期钳制。

## Open questions

- ch2 / ch3 的逐类型参考构成尚不存在 ⇒ 跨章推算是同一行权重的外推；两章构成表补齐后「三章同值」须复核（已在 `systems/balance.md` 统计校准项登记）。
- 闸门 Travel 数（4 / 4 / 5）是外推估算，ch2 / ch3 的 location 数与 `eventCountLimit` 归内容制作阶段。
- `Practice : Standard` 的实测校准依赖 Combat 条目池铺开；在类型档案建起之前 1:1 只作为编排目标挂着。

## Notes / triage

- `systems/balance.md`：`BaseTypeWeights` 条目补齐载体形状 + 三条校验 + 不校验和 = 1 + 供给 ≠ 实现；`Practice : Standard = 1 : 1` 由 Explore 标定的局部假设升格为全库编排口径（与 `t(Explore)` 处互相回链）；待决条目改写为统计校准项。
- `systems/game-progression.md`：类型修正建议区间补入 location 小节；「五类配比未定」待决删除；经验覆盖率按新构成改 ≈55%。
- `systems/adventure-event/_index.md` `:44-45`、`combat/_index.md`（新增编排口径意图）、`common-properties.md` `:409`、`services/future-event-service.md` `:544`：同一条待决的四处登记一并关闭。
