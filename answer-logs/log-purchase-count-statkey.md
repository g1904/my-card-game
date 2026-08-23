# Answer log purchase-count-statkey

- 日期：2026-08-22
- 来源：`inbox/solution-draft-purchase-count-statkey.md` → `handoffs/2026-08-22-purchase-count-statkey.md`
- 移出条数：1

**是否为「购买次数」设一个 `StatKey` 成员** → **不设**。交易侧不向 `Stats` 列贡献任何 `StatDelta`，`StatKey` 不增成员，交易不产生统计依赖。四条判据同向：零规则消费点（且成就发放作为规则恒不可读统计层，「为成就预留」不成立）· 无展示落点（统计层字段的唯一合法消费方是 UI，而档案统计区只列渡劫成功次数与总通关数）· 轮回内的购买笔数已可由 `pastEvent` 的 `AppliedChange`（`Op == Grant` 且 `Source == ExchangePurchase`）推导，落字段即第二真值 · 与完全同形的「篇章重试的账号级累计」同处置，首批统计清单保持「小而无歧义」。层归属顺带判死在统计侧，`CostKey` 不在选项内。**代价被接受且已明写**：账号级累计购买数没有字段回答且事后无法追溯重建，日后要它只能从加上成员那一刻起计数、历史归零。（归档去向：`systems/adventure-event/exchange/_index.md`「交易不产生统计依赖」一节与 `## 决策(-> ADR)`；`systems/services/profile-service.md` 统计计数一条留回链。）

草稿中的两个条件项——「是否同批补回篇章重试的账号级累计」与「成员名确认 `TotalItemsPurchased`」——仅在选「设」时成立，随本裁决消解，不进待答清单。
