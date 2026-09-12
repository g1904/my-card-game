# `EncounterTighten` 的界常量取值；手牌上限移出增量面

- id: 2026-09-12-encounter-tighten-bounds
- date: 2026-09-12
- topic: systems/balance · systems/services/plot-manager · decisions/ADR-0077
- status: distilled
- distilled-to: systems/balance.md, systems/services/plot-manager.md, systems/services/future-event-service.md, systems/services/combat-service.md, decisions/ADR-0077-encounter-tighten-increments.md, decisions/ADR-0081-hidden-stats-outside-combat.md, decisions/ADR-0183-momentum-per-mana-exchange-rate.md

## Intent（distilled）

`EncounterTighten` 的牌流量各格此前只有结构、没有数字：没有下界，一条剧本条目写 `DrawPerTurnDelta = -2` 即可把每回合抽牌压到 `0`，遭遇从第 2 回合起完全断供；没有上界，加载期挡不住明显的编排失误。取值原本被「基准值本身仍待校准」阻塞，而基准 4 / 2 / 7 已校准并维持 ⇒ 前置不复存在。

本次同时改变了这套结构本身：**手牌上限整格移出 `EncounterTighten`**。

### 1. 手牌上限恒为 7，剧本改不动它

`MaxHandLimitTighten` 与 `MinHandLimit` **两个常量取消**（不存在，而非取 0）；`EncounterTighten` 由五格增量收敛为**四格**：回合数 · 胜负门槛 · 起手抽牌数 · 每回合抽牌数。手牌上限 7 降为一个普通的全局平衡常量。

理由：撞上限**不丢牌**（第 8 张从抽牌堆抬起一半后退回抽牌堆）⇒ 压低手牌上限实为一次**条件性的牌流收紧**，与起手 / 每回合两格直接的牌流量旋钮重叠，而玩家读不出它的来源。难度旋钮因此收在直接的牌流量上。

**代价：** 剧本失去「压低手牌上限」这一档加难手段，牌流量旋钮由三格减为两格。已知并接受。

### 2. 两格牌流量的四个界常量

| 格 | 内容侧上界 | 初值 | 物化期硬界 | 初值 |
|---|---|---|---|---|
| 起手抽牌数 | `MaxInitialDrawTighten` | **1** | `MinInitialDraw` | **3** |
| 每回合抽牌数 | `MaxDrawPerTurnTighten` | **1** | `MinDrawPerTurn` | **1** |

- **`MinInitialDraw = 3`** 由 `InitialDraw = 4` 的既有依据反推。那条依据是一条可复算的不等式——**起手张数 × 平均费用 > `manaLimit`**（`4 × 2 = 8 > 5`），语义是「首回合几乎必然打不满 mana，开局有一拍蓄势」。取 3 时 `3 × 2 = 6 > 5`，该性质仍成立（仍是「打不满」而非「打不出」）；取 2 时 `4 < 5`，首回合 mana 必然浪费，开局从「蓄势」翻转为「无牌可打」。判据形态与 `MinTurnLimit = 6`（「低于此即退化为纯起跑线检定」）同构。三章一致性：费用曲线与 `manaLimit` 同步上移 ⇒ `3 × 3 = 9`、`3 × 4 = 12` 均维持 `>` 关系。
- **`MinDrawPerTurn = 1`**：硬约束 `>= 1` 与基准 2 之间只剩两个候选，取 2（= 基准）会让这一格成为**死结构**（任何 delta 都被钳回、格位永不生效），与「每一格都必须能表达『更紧』」的立格判据相抵，也让那条明写的硬约束变成空文。
- **两个内容侧上界同取 1**：下界既已把有效 delta 锁成一档，写 `-2` 必被钳回，属明显的编排失误——挡住它正是内容侧上界的唯一职责；上界写 2 恰好挡不住那个失误，等于自废该格。

### 3. 可达值域与安全性核对（4 种组合全覆盖）

`InitialDraw ∈ {3, 4}` · `DrawPerTurn ∈ {1, 2}`；`HandLimit` 恒 7、不参与组合。

| 检查项 | 最紧组合下 | 结论 |
|---|---|---|
| `MinDrawPerTurn >= 1` | 1 | 牌流量永不断供 |
| 起手不撞手牌上限 | 7 ≥ 4 | 起手恒可全数入手 |
| 首个决策点前不少抽 | 7 ≥ 4 + 2 = 6 | 成立（此项在基准下最吃紧） |
| 手牌锁死（抽不进且出不掉） | 每回合恒入 ≥ 1；`manaLimit` 5 ≥ 平均费用 2 | 不出现 |
| 空堆疲劳提前引爆 | 收紧牌流即**减轻**疲劳压力 | 方向安全 |

**复合最紧的牌流账：** `Standard` `3 + 5×1 = 8`（基准 14，**−43%**）· `Practice` `3 + 4×1 = 7`（基准 12，−42%）· `Finale` 整档豁免。单格 `DrawPerTurnDelta = -1` 已是 −36%（基准只有 2 的算术后果，一格整数在小基数上天然粗粒度），对比 `MaxTurnLimitTighten` 的 `10 → 8` 只有 −20%。

**编排口径（建议，不落成结构）：一条 arc 不宜同时拧两格牌流量。** 不为它新开「总量闸」——那是新结构，且 `min` 合并算子已保证幅度不会被多条 arc 叠加放大。

### 4. 八个数是初值，随基准值同式重算

三条判据都是**跟着基准走的式子**（mana 不等式 · 非死结构 · 下界锁定有效 delta 档数），故基准 4 / 2 被实测改写时按同式重算，**不是按比例缩放**。校准输入与本表其余初值同源：卡牌产 / 削道念的量纲基准、starter deck 的实际平均费用。

**已接受的代价：** 两格的可调幅度都只有一档（各 2 个合法值），剧本在牌流量上的表达力很粗；要更细的粒度只能先抬基准。

### 5. 连带闭合

填数后，`plot-manager.md` 校验表末行「任一 delta 绝对值超出该格的内容侧上界常量 → `PushWarning`」**从此可执行**（此前因常量空缺无法跑）。呈现侧无需改动但语义跟随：见底预警阈值 `DrawPerTurn × 2` 在最紧遭遇里 = 2 张（预警窗口减半），该值本就明写「不写死」。

## Clarifications（interview 产物）

- **手牌上限那一格取哪条线（1/6 保守 vs 2/5 中间）→ 两条线均不采纳：整格移出 `EncounterTighten`。** 这推翻了 `ADR-0077` 的五格结构，按根约定「决策可被推翻，以最新用户意图为准」**直接改写那份 ADR**（不新开取代 ADR）。
- **「取值推迟到统计校准」那句是否松动 → 松动，改写为「取值为初值，随基准值同式重算」。** 前提（基准 4 / 2 仍待校准）已消失；返工风险原本来自基准漂移，而三条判据本就是跟着基准走的式子。

**标准默认（自动采纳，不进 Open questions）：**

- `EncounterTighten` 类定义删去 `HandLimitDelta` 字段、合并算子表删去对应行、方向校验行去掉该字段名、物化期施加式删去 `HandLimit` 那一行、物化日志去掉 `<handΔ>` 一段——两个界常量既已不存在，留着即悬空引用。
- 「五格」措辞在受影响的活文档中一律改「四格」；`ADR-0081` 的「剧本只能走 `EncounterTighten` 五格」与 `ADR-0183` 背景段的界常量计数同批订正（两处均只是计数，结论与理由链不动）。
- **`EncounterSpec` 的可空覆写组同批删去手牌上限一格（用户裁决：任何编排面都动不了）。** 覆写组由四格减为三格（`InitialDraw` / `DrawPerTurn` / `EnemyManaLimit`）——手牌上限不止剧本收紧不了，**事件模板也覆写不了**，它恒取 `CombatRulesData` 的全局常量 7。连带收口：`combat-service.md` 的 `EncounterSpec` record 与覆写组条 · `future-event-service.md` 的物化代入面（代入五格 → **四格**，手牌上限不再是被代入的遭遇参数）· `ux/combat-ux.md` 的 `n/7` 呈现（原写「由 `EncounterSpec.HandLimit` 覆写驱动」，该字段已不存在 ⇒ 改为恒取全局常量；呈现侧**仍不写死 7**，那个数可经 overlay 热更）。

## Open questions

- 八个界常量随基准 4 / 2 的实测校准复核（校准输入：卡牌产 / 削道念的量纲基准、starter deck 的实际平均费用）。
- 若事件模板日后对某档写更宽的牌流量覆写（如 `InitialDraw = 5` / `DrawPerTurn = 3`），界常量为定值 ⇒ 相对收紧幅度变小，且「首个决策前不少抽」在 `5 + 3 = 8 > 7` 时本就不成立——**那是模板编排问题，不是界常量问题**，模板侧编排出现时复核一次，不预先为它调界。

## Notes / triage

零结构性改动于存档面：`EncounterTighten` 不进 `EncounterSpec`、不落存档 ⇒ schema 零改动、零迁移。八个常量同住 `CombatRulesData`，**是取值不是结构 ⇒ 可 overlay 线上改**。

ADR 候选（不立档）：无——被推翻的 `ADR-0077` 按根约定就地改写，不新增编号、不动 `decisions/_index.md` 的排序（该台账的标题一行需同步，见本次报告）。
