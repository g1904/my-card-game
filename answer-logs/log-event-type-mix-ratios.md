# Answer log event-type-mix-ratios

- 日期：2026-09-06
- 来源：`inbox/solution-draft-event-type-mix-ratios.md`（2026-09-06 批量评审 decided）→ `handoffs/2026-09-06-event-type-mix-ratios.md`
- 移出条数：1 全条（另关闭同一条待决在主题文档的四处登记）

## 逐条

- **五类之间的配比，以及 Combat 内 `combatTier` 三档的配比（08-15c 新增 · 08-22 收窄，`open-questions/02-event-options.md`）** → 全面定案：`BaseTypeWeights` 五格初值 **0.35 / 0.13 / 0.13 / 0.32 / 0.07**（三章同值仍写三行，Combat 最高频、幅度略高于 Exchange，由 2026-09-06 篇章时长重标定反推）；载体为新平衡资源 **`BaseTypeWeightsData`**（`ISingletonContent` + 内嵌行、三条加载期校验、刻意不校验和 = 1）；location / arc 调制零新增结构，补编排建议区间 `[0.5, 2.0]` / 占比 `[5%, 55%]`（`/audit-content` 汇总，只报告不阻断，不加运行期钳制）；**`combatTier` 配比 = `Practice : Standard = 1 : 1` 三章统一**，为内容编排口径而非运行期旋钮（无新字段 / 无 `CombatTierWeights` / 管线零改动），Finale 旁路不进分母。（归档：`systems/balance.md`「`BaseTypeWeights`」条目 · `systems/adventure-event/combat/_index.md` · `systems/game-progression.md`）
  - 同一条待决的主题文档登记四处一并关闭：`systems/adventure-event/_index.md`（两条）· `systems/services/future-event-service.md` · `systems/adventure-event/common-properties.md` · `systems/game-progression.md`；`systems/balance.md` 的对应待决改写为「统计校准复核」项（实现分布校准 · ch2 / ch3 构成复核 · 1:1 依赖条目池铺开），**剩余部分仍留在待决问题**。
