# ADR-0262 — Exchange 逐族库存深度上界 = 3 / 2 / 1 / 1 / 0，Σ 7 ≤ 8 刻意留一格余量

- **状态：** Accepted
- **日期：** 2026-09-10
- **来源：** handoffs/2026-09-10-item-family-supply-guardrails.md · answer-logs/log-item-family-supply-guardrails.md

## 背景

L-2（库存深度）此前只对 `CharacterItem` 一族给了上界（Σ`SlotCount` ≤ 3）。其余四族没有任何逐族上界，只受「槽位总数上界 ≤ 8」这一条总闸约束——而总闸是**快照体积护栏**，它不知道某一族的取池分母有多薄。

## 决策

**单个 Exchange 条目内按 `Kind` 分组的 Σ`SlotCount` 上界 = 3 / 2 / 1 / 1 / 0**（法宝 / 散牌 / 神通 / 功法 / 古宝），**Σ = 7**。

- **不为逐族上界新开字段**：按 `ExchangeSpec.StockRules` 的 `Kind` 分组求和即得，与闸 ① 是同一次分组。
- 处置同 L-2：`/audit-content` 一项汇总、**只报告不阻断**（编排口径不是不变式，硬失败会在铺内容中途持续 `PushError`）。

→ `systems/balance.md`「Exchange 逐族库存深度」· `systems/adventure-event/exchange/common-properties.md`。

## 理由

逐族上界的依据各不相同，全都落在**分母有多薄**上（`systems/balance.md`）：`Card` ≤ 2——池分母只剩游离散牌，且卡组规模口径里战后奖励已占大半；`CharacterPower` ≤ 1——池只有 4 条，逐档核算 + `ExchangePoolMargin` 下深度 2 即被闸 ① 拦在启动期；`CultivationTechnique` ≤ 1——池首批 1 条，分母须按可修条目最少的那个灵根收缩，另有「一次轮回至多一门功法从任一通道进组」的硬约束；`PlayerItem` = 0——「规则层开放、首批内容不编排」是既定内容口径。

**Σ 7 ≤ 8 留一格余量是有意的**：逐族上界之和顶死槽位总数上界会让两条校验**永远同时触发**，其中一条从此没有独立信息。

## 备选方案

- **只留槽位总数上界一条** — 否决：总闸是体积护栏，看不见逐族分母的薄厚。
- **为逐族上界新开字段** — 否决：按 `Kind` 分组求和即得，与闸 ① 同一次分组，新字段是纯冗余。
- **Σ 顶满 8** — 否决：两条校验永远同时触发，其中一条失去独立信息。

## 后果

- 补齐了 `decisions/ADR-0247-lifespan-item-orchestration-guardrails.md` 只覆盖法宝一族的那半张 L-2。
- `ExchangePoolMargin` / `K` 取值给出后须**复核**这五个数在闸 ① 上是否仍留得下余量；`CharacterPower` 族的 ≤ 1 是按「池只有 4 条」反推的硬下限、不是按该族供给目标反推，「一次轮回预期获得几条神通」答定后须复核。两条均已登记为待答项。
- 登记进 `content/_index.md` 的跨类型对账表（第三列只写目标值权威回链，不复述数值）。
