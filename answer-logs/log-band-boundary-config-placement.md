# Answer log band-boundary-config-placement

- 日期：2026-08-22
- 来源：`inbox/solution-draft-band-boundary-config-placement.md` → `handoffs/2026-08-22-band-boundary-config-placement.md`
- 移出条数：2

**三章的 `±2` 带边界放在平衡资源里还是服务配置里？** → 平衡资源。「服务配置」这一层在本库不存在（七服务无一持有可调数值配置面，七处先例零反例）。带边界与带内分布权重表**同住一份新资源**：容器 `EnemyLevelingData`，三章各一行具名字段 `EnemyLevelRange`（`Lower` / `Upper` / `Weights`），当前三行同值 `(−2, +2)` 与 `0.05 / 0.20 / 0.40 / 0.25 / 0.10`；权重存归一化小数（和为 1），文档表保持百分数呈现。五条加载期校验与资源形态全部落 `systems/balance.md`；`future-event-service.md` 只写「本服务只读当前篇章的带」+ 回链，并补「PlotManager 不得改带边界，只能乘性调制权重」。行类型刻意避开 `Band`（该词在本库已被隐藏属性档 / 寿元档独占），`terminology.md` 新增「赋级带」一行。（`systems/balance.md`、`systems/services/future-event-service.md`、`systems/enemies/_index.md`、`terminology.md`）

> 剩余部分：三项 `[采纳推荐 — 待复核]`（三行具名字段 / 新开 `EnemyLevelingData` / 权重存归一化小数）**仍留在待答清单**，不随本次移出。

**「下界不得使 `diff` 门槛不可达」一致性检查是否保留？** → 不保留，且在文档中**显式写明不设此校验**（被检查对象随意图机制移除而不存在；沉默地不实现会让它日后被重新捡起）。连带清理库内三处仍在正面陈述该门槛存在的残留，并删除 `future-event-service.md` 中重复且失效的那条「推论 ⑦」。（`systems/balance.md`、`systems/services/future-event-service.md`）
