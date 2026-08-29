# ADR-0087 — 玩家动作统一返回 `ActionResult`；呈现事件统一为一条 `CombatFeedEntry` 流，取代 `CardResolved`

- **状态：** Accepted
- **日期：** 2026-08-25
- **来源：** handoffs/2026-08-25-combat-presentation-and-action-result.md

## 背景

combat-service 的 API 面此前是按「出牌」这一个动作长出来的：`PlayResult`、`PlayRejection`、`CardResolved` 三个类型都以卡牌为主体。而实际有四个玩家动作（出牌 / 用道具 / 结束回合 / 提供目标），且呈现层要消费的不止卡牌结算（还有触发式异能、疲劳、目标落空）。

## 决策

**`ActionResult` 是玩家动作的统一返回类型，不专属出牌。** `PlayResult` 更名 `ActionResult`，覆盖 `PlayCard` / `UseItem` / `EndTurn` / `ProvideTarget` 四个方法；`PlayRejection` 更名 `ActionRejection` 并扩充道具拒绝理由；动作主体字段泛化为 `Kind` + `SubjectId`。**「抓牌」不是玩家动作，没有 `ActionResult`。**

**呈现事件流统一为一条广播 `CombatFeedEntry`**（卡牌结算 / 触发式异能 / 疲劳 / fizzle 四类共用，fizzle 是条目上的 `FizzledSlots` 一格而非独立类别），**取代既有的 `CardResolved`**。负载只带 `Id` 与值类型；**存结构化数据不存格式化字符串**；条目自带 **`EntryId` / `CauseEntryId` 构成因果树**；**不落存档**。

**`Declared` / `Actual` 两级粒度并存**：`ActionResult` 承载一次动作链路的汇总，`CombatFeedEntry` 每条承载本次结算增量，呈现层只读 feed。

类型定义与枚举 → `systems/services/combat-service.md`。

## 理由

一个统一返回类型使调用方（UI）只有一条处理路径，且新增动作不新增类型。而 fizzle 做成条目上的一格而非第四类条目，是因为它是**结算的一种结果**，不是一种事件。

`Declared` / `Actual` 必须两处都留：**状态视图无法重建 `Declared`**——对方剩 5 点时打 8 与打 5 的快照序列完全相同，但玩家宣告的意图不同，而战报要显示宣告值。

`CauseEntryId` 不复用既有 `sourceEntryId`：后者指「载体所在的战场条目」，**从不表达因果父**。

## 备选方案

- **`CombatFeedEntry` 与 `CardResolved` 并存** — 否决（用户裁决，推荐项本是并存）：两条流的消费者会各自演化。
- **目标落空独立成第四类条目** — 否决：改为条目上的类别值 + 槽位掩码。
- **`Declared` / `Actual` 只放一处** — 否决：状态视图无法重建 `Declared`。
- **抓牌纳入 `ActionResult`** — 经核不纳入：它不是玩家动作。

## 后果

- `ADR-0011` 的热路径范例名已随之改写（字面更新，不改契约总则本身）。
- 疲劳不产生 `ActionResult` 但**照常广播一条 `CombatFeedEntry`**（→ `ADR-0088`）。
- 战报与飘字读同一条流（→ `ADR-0086`），不各自组装。
