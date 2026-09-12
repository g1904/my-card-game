# Answer log encounter-tighten-bounds

- 日期：2026-09-12
- 来源：`inbox/solution-draft-encounter-tighten-bounds.md`（经 `handoffs/2026-09-12-encounter-tighten-bounds.md` 提炼）
- 移出条数：**1**

**`EncounterTighten` 三格牌流量的六个界常量取值** → 裁决同时改变了这套结构本身，故该条以「两格四常量 + 一次结构推翻」的形态答结。**① 手牌上限整格移出 `EncounterTighten`**：它恒为 7、剧本改不动，降为一个普通的全局平衡常量；`MaxHandLimitTighten` 与 `MinHandLimit` **两个常量取消**（不存在，而非取 0）；`EncounterTighten` 由五格增量改为**四格**（回合数 · 胜负门槛 · 起手抽牌数 · 每回合抽牌数），十常量表改**八常量表**。理由：撞上限**不丢牌**（第 8 张从抽牌堆抬起一半后退回）⇒ 压低它实为一次**条件性的牌流收紧**，与两格直接的牌流量旋钮重叠而玩家读不出来源。这是一次对既有决策的推翻，按根约定「决策可被推翻、以最新用户意图为准」**直接改写 `ADR-0077` 本体**，不新开取代 ADR。**② 两格牌流量的四个界常量**：`MaxInitialDrawTighten = 1` / `MinInitialDraw = 3`（下界由 `InitialDraw = 4` 的既有依据反推——起手张数 × 平均费用 > `manaLimit`，取 3 时 `6 > 5` 该性质仍成立，取 2 时 `4 < 5` 首回合 mana 必然浪费，判据形态与 `MinTurnLimit = 6` 同构；三章一致性由费用曲线与 `manaLimit` 同步上移保住）· `MaxDrawPerTurnTighten = 1` / `MinDrawPerTurn = 1`（取 2 即等于基准、格位变死结构，与「每格必须能表达『更紧』」的立格判据相抵，也让明写的硬约束变成空文）。两个内容侧上界同取 1，因为下界已把有效 delta 锁成一档，写 `-2` 必被钳回，属明显的编排失误——挡住它正是内容侧上界的唯一职责。**③ 「取值推迟到统计校准的理由」一条改写**：前置（基准 4 / 2 仍待校准）已消失，改为「取值为初值，随基准值**同式**重算，不按比例缩放」。**④ 可达值域 4 种组合逐条安全核对全过**；复合最紧 `Standard` `3 + 5×1 = 8`（−43%）· `Practice` `3 + 4×1 = 7`（−42%）· `Finale` 整档豁免。编排口径「一条 arc 不宜同时拧两格牌流量」只作指导，**不新开总量闸**。**⑤ 填数后 `plot-manager.md` 校验表末行的上界校验从此可执行**（此前因常量空缺无法跑）。（归档去向：`systems/balance.md` · `systems/services/plot-manager.md` · `systems/services/future-event-service.md` · `systems/services/combat-service.md` · `decisions/ADR-0077-encounter-tighten-increments.md` · `decisions/ADR-0081-hidden-stats-outside-combat.md` · `decisions/ADR-0183-momentum-per-mana-exchange-rate.md`）

**仍留在待答清单的部分：**

- 八个界常量随基准 4 / 2 的实测校准复核（校准输入：卡牌产 / 削道念的量纲基准 · starter deck 的实际平均费用），已改写为 `systems/balance.md` 待决问题里的一条实测复核项，不再是「只欠数字」的阻塞项。
- 若事件模板日后对某档写更宽的牌流量覆写（`InitialDraw = 5` / `DrawPerTurn = 3` 一类），界常量为定值 ⇒ 相对收紧幅度变小，且「首个决策前不少抽」在 `5 + 3 > 7` 时本就不成立——**那是模板编排问题，不是界常量问题**，模板侧编排出现时复核一次，不预先为它调界。
- `EnemyManaLimit` 初值 5 的校准与本条互不依赖，仍在清单内，未被本次触及。
