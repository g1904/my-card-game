# Answer log singleton-balance-resource-registry

- 日期：2026-08-22
- 来源：`inbox/solution-draft-singleton-balance-resource-registry.md` → `handoffs/2026-08-22-singleton-balance-resource-registry.md`
- 移出条数：1（另有 1 条部分答定，剩余部分仍留在待答清单）

---

**散落平衡旋钮怎么落：设一份 `GlobalBalanceData` 兜底大表，还是按判据逐份切？**（批量运行第 1 轮阻断题 R1-2）
→ **不设兜底大表，按三问判据（消费者是谁 · 覆写纪律是什么 · 有没有跨字段不变式）逐份切。****正式拍板。**
理由：兜底表必然成为默认倾倒处，随后「哪些字段可被 `EncounterSpec` 一类覆写」退化为逐字段记忆——与「`EnemyLevelingData` 不并入 `CombatRulesData`」同一条否决理由。代价如实记下：短期内会出现若干份字段很少的小资源，每份都要各自命名。
（归档去向：`systems/balance.md` 的「平衡资源的切分三问判据」；机制侧回链见 `systems/services/content-service.md`「单例内容的注册与校验」。）

---

**单例平衡资源如何进 ContentRegistry**（`open-questions/01-combat.md` → 结构与配置的残留，08-22 新增）
→ **部分答定。**机制面已定并归档进 `systems/services/content-service.md`「单例内容的注册与校验」：进注册表不另开通道 · 走既有泛型仓储 · 单例归入「结构性查表类恒启用」· `AllEnabled()` 对它无意义但不为它改仓储形状 · 加载期条数与启用态校验 · 准入边界「全部消费点须晚于 `LoadAll()`」。
**剩余部分仍留在待答清单**（四项 `[采纳推荐 — 待复核]`，用户授权按推荐落笔但未拍板）：两段式 `Id` `<类型>.default` · 标记接口 `ISingletonContent` + `Single<T>()` 编译期约束 · 早于 `LoadAll()` 的旋钮写死为代码常量并在 `balance.md` 标注不可线上调 · 两处措辞澄清（`content/_index.md` 的「不建 `content/` 类型 ≠ 不进 ContentRegistry」、`content-service.md`「是否被存档引用」表脚注）。
另：**完整的单例平衡资源清单**依赖各散落旋钮的消费者定名，不在本次范围内，作为新增待答项。
