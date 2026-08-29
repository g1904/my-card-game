# ADR-0117 — 重试上限不新增任何存档结构，读既有 `PlayerEntitlement` 选行；载体收为 `ChapterRetryLimitsData`

- **状态：** Accepted
- **日期：** 2026-08-27
- **来源：** handoffs/2026-08-27-capability-flag-and-entitlement.md

## 背景

重试上限由礼包从「无限 / 3 / 1」改写为「无限 / 9 / 3」之后，它落成什么存档形状成为一个待答项。三个候选被提出：做成一个 `CapabilityFlag`、做成一条具名 modifier、或在 `PlayerEntitlement` 上新开一个字段。

## 决策

**三个候选一个都不采纳：不新增任何存档结构，读既有的 `PlayerEntitlement`。** `RetryChapter` 的上限判定读 `profile-service.HasPremiumBundle`（`=> Entitlement.BundleGrantOrdinal > 0`，单点查询、不缓存），两档上限表两行住 `systems/balance.md`，life-cycle-service **选行**。

**存档 schema · `CostKey` · `ResourceElements` · 透明路径 · sync-service · 后端契约全部零改动。**

唯一新增的是**载体形状** `ChapterRetryLimitsData : Resource, ISingletonContent` + 内嵌行类型（`Chapter1/2/3` 具名字段，`-1` = 无限），经 `Content.Single<T>()` 取、调用方不写 `Id` 字面量，加载期校验两行非 `null` 且各字段 `>= -1`。**数值一格不动。**

形态与校验 → `systems/balance.md`；否决理由的权威句 → `systems/monetization.md`。

## 理由

三条否决各自独立成立：

- **`CapabilityFlag`（候选 A）致命的一条**——生效能力集受轮回级禁用截断，把付费凭证放进一个**设计上允许被截断**的聚合面，等于给「花钱买的东西被事件拿走」留后门。另有两条：唯一授予源是 `PowerData` 条目而礼包没有宿主条目；上限是每篇章一格的三元组，布尔承载不了。
- **modifier（候选 B）**：modifier 明写不作用于序号与付费凭证，且上限是**选行**不是**算数**。
- **独立 `Entitlement` 字段（候选 C）**：`PlayerEntitlement` 只放付费凭证本身与其兑现水位、不放任何派生量；一个 `HasExtendedRetry` 就是 `BundleGrantOrdinal > 0` 的第二份拷贝——**派生态不能承载原始事实**。

**具名篇章字段而非索引数组**：篇章数是固定的游戏结构，与 `EnemyLevelingData` 的既定判据一致；且内嵌行类型一律 `Resource` 派生。

**不并入 `CombatRulesData` / `EnemyLevelingData`**：消费者不同（ChapterManager vs combat-service / future-event-service），与 `EnemyLevelingData` 拒绝并入 `CombatRulesData` 同判据。

## 备选方案

- **候选 A：做成 `CapabilityFlag`** — 否决：受轮回级禁用截断（致命）· 无宿主条目 · 布尔承载不了三元组。
- **候选 B：做成一条具名 modifier** — 否决：modifier 不作用于付费凭证，且这是选行不是算数。
- **候选 C：`PlayerEntitlement` 上新开 `HasExtendedRetry`** — 否决：它是 `BundleGrantOrdinal > 0` 的第二份拷贝，派生量不进凭证层。

## 后果

- `systems/balance.md` 是载体形状与两行取值的权威；`systems/services/life-cycle-service.md` 承载选行链路；`systems/monetization.md` 承载三条否决理由。
- 本条与 `ADR-0116` 可各自单独推翻：换一种载体不牵动 flag / modifier 体系。
- 上限的**数值本身**是否随实测调整，仍是 `systems/balance.md` 的一条待决项；本条只定形态。
- 单例内容的注册与加载期条数校验 → `ADR-0030`。
