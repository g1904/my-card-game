# ADR-0004 — 境界存档 · 篇章重试模型

- status: Accepted
- date: 2026-07-23
- supersedes:
- superseded-by:

## Context
roguelike 的轮回需要一套明确的**境界阶梯 / 篇章存档 / 重试**契约，以驱动进程、读档续章、篇章解锁与元进程。此前经多份 handoff 逐步定案（四境三篇章、篇章继承、状态机、重试上限、解锁触发），数值也已在 `2026-07-22` 确认；`open-questions.md` 已将其列为 ADR 候选。现固化为 ADR。参见 `handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`、`handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。

## Decision
- **四境三篇章。** 境界阶梯：炼气 → 筑基 → 金丹 → 元婴（四境）；一次轮回为三个篇章，每个篇章是相邻两境之间的攀登。
- **境界存档点。** 篇章通关即在所达境界落一个**存档点**；可读档从该境界起始下一篇章。三个篇章边界是持久存档点，元婴为奖杯。
- **篇章继承 = 全部继承。** 读档续章时角色带入上一篇章的**全部信息**（deck、法宝、属性、叙事标记等），无逐项筛选。
- **重试上限（定案 · 基线值）：** 第一章（炼气→筑基）= **无限**；第二章（筑基→金丹）= **3**；第三章（金丹→元婴）= **1**。篇章途中死亡 → 从该篇章起始存档重试；挑战成功进入下一境界，**不能重试之前篇章**。**这三个数是基线值而非常量**——持有 **premium bundle** 的账号为 **无限 / 9 / 3**（见 `systems/monetization.md`）。
- **角色状态机。** `status = ongoing | defeated | completed`；`defeated` 为单一终态，**原因恰四种**：主动弃置 `discarded`、**寿元 / lifeSpan 归 0（大限将至）**、**`lifeTotal` 归 0**、**渡劫失败 `FinaleFailed`**。前三种是资源触底，由资源表驱动判定；末一种是篇章闸门，走终态判定上的一条显式旁路。终态数据清理。
  - **`Practice` / `Standard` 档输掉一场战斗本身不终结角色**（只按道念差扣 `lifeTotal`，见 `systems/scoring.md`）——这两档的失败不是独立的终结原因。
  - **`Finale` 档失败即终结**：篇章边界的胜负就是篇章推进的闸门，败则该角色当场终结、本篇章不推进（见 `systems/adventure-event/combat/_index.md`）。那笔按道念差扣的 `lifeTotal` 照常扣，只是不再是死亡判据。
  - **⚠ 终态数据清理的顺序约束：** 角色终结时并发的**账号级**写入（道统残卷的失败累积）必须在清理之前提交完成，见 `systems/services/life-cycle-service.md`。
- **每篇章至多一个 ongoing。** 某篇章内有 ongoing 角色时，不能用其他角色玩该篇章；不同篇章可并行。
- **篇章解锁触发。** 角色通关上一篇章即成为下一篇章可挑战角色；某篇章无可重试 / 可挑战角色时，该篇章重新进入锁定（隐藏）——解锁是「有可挑战角色」的动态状态，而非一次性永久标志。

## Consequences
- **存档角色是有限资源。** 落过境界存档的角色在后续篇章重试有限（3 / 1；持礼包 9 / 3），耗尽即该篇章重新锁定——构成元进程压力。**付费可放宽这条压力线（∞ / 9 / 3），这是有意的口径变化**；平衡时以**免费档为「应当可通关」的基准**，付费档是宽松化而非必需品。见 `systems/monetization.md`。
- **免费档账号在终局的容错次数是明写接受的（承重）。** Finale 失败即终结、且败后不可在同一篇章内重战 ⇒ **一次 Finale 失败恰好消耗一次篇章重试**。代入基线值：ch1 无限、**ch2 3 次、ch3 仅 1 次**——即免费档账号在金丹→元婴这一关**一生只有 1 次容错**，第二次失败该篇章即重新锁定，需要另一个已落存档点的角色。**这条压力是有意保留的**，不为它补偿重试次数；缓解手段全在难度侧（Finale 的通过条件已是「不落后即通过」，见 `systems/balance.md`）与付费档（∞ / 9 / 3）。
- **重试上限的读取要经一层。** 上限既然可被账号级持有状态改写，凡读取它的地方（`RetryChapter` 判定、篇章解锁 / 重新锁定、剩余次数展示）都不得硬编码常量。
- **数据模型对齐。** PlayerProfile 持 `List<CharacterProfile>`；CharacterProfile 持 `status`、`chapter`、`Status`、`pastEvent: IReadOnlyList<PastEventEntry>` 等（见 `systems/services/life-cycle-service.md`）。
- **存档实现须原子 + 版本化**（见 ADR-0003 与 `state-save-rules.md`）；云端权威下存档为上行云端负载。
- **待办：** 重试上限若后续视作可调平衡项，归 `systems/balance.md`；篇章衔接的「可用结束点」具体数据表达见 `systems/game-progression.md`。
