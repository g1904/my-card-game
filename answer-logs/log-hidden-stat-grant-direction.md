# Answer log hidden-stat-grant-direction

- 日期：2026-08-22
- 来源：`inbox/solution-draft-hidden-stat-grant-direction.md` → `handoffs/2026-08-22-hidden-stat-grant-direction.md`
- 移出条数：1

---

**`HiddenStatGrant` 的推拉方向如何表达（08-22 新增 · 轻）** → **`HiddenStatGrant` 加第三格 `HiddenStatDirection { Raise, Lower }`**（数值轴命名，不含价值判断）；符号在**物化组装**时按 `Direction` 取负，与 `SelectCost` 的 `lifeSpanCost`、`OutcomeRule.Direction` 同处。`HiddenStatGrade` 的三个映射值恒为正量，方向不进档位表。element 层 / `AppliedChange` 层 / 存档层一格未动 ⇒ 存档 schema 零增量、不 bump、无迁移；`content/` 下当前无 AdventureEvent 条目 ⇒ 内容迁移面为零。

否决的三条：① 档位表分正负两套（把单次变更的属性焊进 element 类型的量纲轴，违反三级判据的落点条件；两套值注定冗余却可被填成不一致）；② 复用 `OutcomeDirection { Gain, Loss }`（价值判断词按到语义双读的位置——`(Bloodlust, Major, Gain)` 有两个自洽读法，且让该枚举的含义不再是常量）；③ 逐属性固定方向的约定（结构上表达不出道心的双向推拉）。

归档去向：`systems/architecture.md`「共享核心类型」（类型定义 + 落点论证，唯一权威）· `systems/adventure-event/common-properties.md`（模板侧产出格 + 加载期校验 8 / 9）· `systems/services/future-event-service.md`（物化展开伪码 + 断言 11 / 12）· `systems/balance.md`（映射值恒为正量、方向不在本表）。

**本条只答定了主结构；三项 `[采纳推荐 — 待复核]` 仍留在待答清单**（`open-questions/02-event-options.md`）：`HiddenStatDirection` 不加 `Unset = 0` 哨兵 · 校验 9（`Stat == LifeSpan` → `PushError`）· `HiddenStatGrant.Stat` 保持宽类型 `HiddenStat` 以校验收窄。
