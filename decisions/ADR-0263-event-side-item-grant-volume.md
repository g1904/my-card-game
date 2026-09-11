# ADR-0263 — 事件侧给法宝的产出量 ≈ 1.5 件 / 完整轮回，每条规则 `Count == 1`；软校验 `X-1`

- **状态：** Accepted
- **日期：** 2026-09-10
- **来源：** handoffs/2026-09-10-item-family-supply-guardrails.md · answer-logs/log-item-family-supply-guardrails.md

## 背景

法宝的四条获取通道里，通道 ③（事件产出）此前只有载体、没有量。载体是既有的 `OutcomeRule.Kind == GrantFromPool` + `PoolKind == CharacterItem`，不缺机制——缺的是编排目标，否则内容侧无从判断「铺几条这样的事件才算对」。

## 决策

**事件侧给法宝的期望到手量 ≈ 1.5 件 / 完整轮回**，**每条规则 `Count` 恒 1**（编排口径，不改 `Count >= 1` 的既有校验）。

- 旋钮 = 带该规则的 `AdventureEventData` 条目数 × 各条 `SelectionWeight` 档 —— **零字段、零校验、零状态位**，与失去频次的旋钮同款。首批等价形态 = 每篇章 1 条 `Rare` 档条目 × `Count = 1`。
- 它**并入事件侧一本账**，不单列旋钮。
- **新增软校验 `X-1`：`eventType == Exchange` 的条目携带 `OutcomeRule(Kind == GrantFromPool)` → `PushWarning` + 条目 `Id`。**

→ `systems/balance.md`「事件侧给法宝的产出量」· `systems/character-profile/item/_index.md` 通道 ③ · `systems/adventure-event/exchange/common-properties.md` 校验 `X-1`。

## 理由

`systems/balance.md`：**事件位是全局最稀缺的资源**（一章约 35 批次、每批至多 5 项候选），而通道 ④（战后奖励）一轮回已白给约 18.5 件法宝 ⇒ 占掉一个事件位去发一件消耗品，收益远低于让那个事件承载一次决策或一段叙事。量级同时与回寿事件（每章 1 次小档）对齐——同为「事件位换一件消耗品」，不该差一个数量级。

`Count` 恒 1 的依据是「一颗 = 一档」的可读性纪律：数量语义已由储物袋按 `ItemId` 堆叠 `×N` 承载，规则层再给一个数量是第二处表达。

`X-1` 取软校验而非拒绝：**消费点白给商品 = 给定价表打一个不可见的折**，但赠礼式风味条目是正常例外，本行的职责是让每个例外被看见。`eventType == Travel` 的排除由既有禁令承担，不重述。

## 备选方案

- **给事件侧更高的法宝产出量** — 否决：事件位是最稀缺资源，且通道 ④ 已白给约 18.5 件。
- **放开 `Count > 1`** — 否决：与储物袋的 `×N` 堆叠构成第二处数量表达。
- **`X-1` 写成硬拒绝** — 否决：赠礼式风味条目是合理例外，硬失败会把它一并挡住。

## 后果

- 约束 `systems/character-profile/item/_index.md` 四条获取通道表的通道 ③ 行只写「由编排决定 · 并入事件侧一本账、不单列旋钮」。
- `X-1` 与 Exchange 既有九条校验并列，处置为 `PushWarning`，不进闸 ①。
