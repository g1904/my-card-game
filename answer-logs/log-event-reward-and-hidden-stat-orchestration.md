# Answer log event-reward-and-hidden-stat-orchestration

- 日期：2026-09-09
- 来源：`inbox/solution-draft-event-reward-and-hidden-stat-orchestration.md`
- 移出条数：3

---

**`Practice` / `Finale` 档的奖励厚薄（`open-questions/03-adventure-event-types.md`）** → 分两格答定：

- **`RewardPoolId` 随档位如何调厚薄** = **换池**（不换权重表、不换抽数）。池的编排维度 = **篇章 × `combatTier` 九个具名池**，池是逐条编排的具名成员清单、一个条目可属多个池，每池 `Tier1`–`Tier5` 全五档非空；厚薄由**挂池率 × 池的族与价位构成 × `Practice` 的神通族排除**三者承担，V 值是可复算的书写口径而非进 `.tres` 的数字。（归 `systems/balance.md`、`systems/services/combat-service.md`、`systems/adventure-event/combat/_index.md`）
- **`BaseReward` 中其余 element 的量** = **不是待校准的数字，是一条结构结论：恒空**（默认 element 面 = 灵石一格）。该格由「待校准数字」降级为结构结论后关闭，不再进统计校准清单。（归 `systems/balance.md`）
- **剩余留待统计校准的部分**：池成分的绝对取值随战后奖励池权重表定稿后重算，属既有的统计校准面，不回填本清单。

**Combat 三档各推哪一档 `HiddenStatGrade`（`open-questions/03-adventure-event-types.md`）** → 三档默认阶梯给出：道心 `Practice` `Minor`(2) / `Standard` `Standard`(5) / `Finale` `Major`(10)；煞气 `Standard` 档杀伐类 `Major`(10)、`Practice` 不填、`Finale` 首批不填。煞气默认档比道心高一档，依据是两张档位表的几何。（归 `systems/adventure-event/combat/_index.md`、`systems/balance.md`）
- **剩余部分仍在待答清单**：`HiddenStatGrade` 三个映射值 2 / 5 / 10 的统计校准另有归属（`open-questions/04-hidden-attributes-plot.md`），不属本条。

**隐藏属性的推拉触发（`open-questions/04-hidden-attributes-plot.md`）** → 两半均答定：**语义 → `(Stat, Direction, Grade)` 的编排判据表**（覆盖五类事件 + 三条编排纪律，是编排口径不是校验）落 `systems/adventure-event/common-properties.md`；**两条剧情线的结构形态与内容大纲**（`SideStory` · `ChapterScope` 空 · 3–4 节点 · boss 走 `PlotModulation` 六字段 · 至少一处 `ChooseBranch`）落 `systems/services/plot-manager.md`。剩余的是逐条目 `.tres` 撰写与剧情线正文，属内容编排工作量，不是待答问题。
- 同分片内**就地改写 1 条**（不计入移出条数）：`HiddenStatGrade` 映射值的统计校准条，删去「校验依赖上一条的『增减触发』」这半句——该阻塞已由本次的编排判据表解除。
