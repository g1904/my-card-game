# ADR-0004 — 境界存档 · 篇章重试模型

- status: Accepted
- date: 2026-07-23
- supersedes:
- superseded-by:

## Context
roguelike 的 run 需要一套明确的**境界阶梯 / 篇章存档 / 重试**契约，以驱动进程、读档续章、篇章解锁与元进程。此前经多份 handoff 逐步定案（四境三篇章、篇章继承、状态机、重试上限、解锁触发），数值也已在 `2026-07-22` 确认；`open-questions.md` 已将其列为 ADR 候选。现固化为 ADR。参见 `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`、`10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。

## Decision
- **四境三篇章。** 境界阶梯：炼气 → 筑基 → 金丹 → 元婴（四境）；一次 run 为三个篇章，每个篇章是相邻两境之间的攀登。
- **境界存档点。** 篇章通关即在所达境界落一个**存档点**；可读档从该境界起始下一篇章。三个篇章边界是持久存档点，元婴为奖杯。
- **篇章继承 = 全部继承。** 读档续章时角色带入上一篇章的**全部信息**（deck、法宝、属性、叙事标记等），无逐项筛选。
- **重试上限（定案）：** 第一章（炼气→筑基）= **无限**；第二章（筑基→金丹）= **3**；第三章（金丹→元婴）= **1**。篇章途中死亡 → 从该篇章起始存档重试；挑战成功进入下一境界，**不能重试之前篇章**。（草稿中的「第四章」为笔误，已废弃。）
- **角色状态机。** `status = ongoing | defeated | completed`；`defeated` 为单一终态（原因子类型含主动弃置 `discarded`、战斗失败、**寿元 / lifeSpan 归 0（大限将至）** 等），终态数据清理。
- **每篇章至多一个 ongoing。** 某篇章内有 ongoing 角色时，不能用其他角色玩该篇章；不同篇章可并行。
- **篇章解锁触发。** 角色通关上一篇章即成为下一篇章可挑战角色；某篇章无可重试 / 可挑战角色时，该篇章重新进入锁定（隐藏）——解锁是「有可挑战角色」的动态状态，而非一次性永久标志。

## Consequences
- **存档角色是有限资源。** 落过境界存档的角色在后续篇章重试有限（3 / 1），耗尽即该篇章重新锁定——构成元进程压力。
- **数据模型对齐。** PlayerProfile 持 `List<CharacterProfile>`；CharacterProfile 持 `status`、`chapter`、`Status`、`List<AdventureEvent>` 等（见 `20-systems/services/life-cycle-service.md`）。
- **存档实现须原子 + 版本化**（见 ADR-0003 与 `state-save-rules.md`）；云端权威下存档为上行云端负载。
- **待办：** 重试上限若后续视作可调平衡项，归 `20-systems/balance.md`；篇章衔接的「可用结束点」具体数据表达见 `20-systems/game-progression.md`。
