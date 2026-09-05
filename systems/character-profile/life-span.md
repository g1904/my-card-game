# lifeSpan（寿元）

> **`lifeSpan` = 这个角色唯一的一条命** —— 既是寿命预算，也是失败惩罚的承受量。**两个扣减来源**：每个 AdventureEvent 按 `lifeSpanCost` 扣、战斗 / 修炼失败时按道念差 × `lossPerMomentum` 扣。**回复只走 outcome 侧三条通道。** **归 0 → 角色 `defeated`（大限将至）**。**单值，无上限字段、无上限截断**；炼气起始 1000，进入更高境界时一次性增授。**明文常驻，恒精确展示。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **一条命，两个消耗来源，一个回复口。** 角色只跟踪 `lifeSpan` 一个数：**走路要花**（每个 AdventureEvent 的 `lifeSpanCost`）、**打输要花**（战斗 / 修炼失败按道念差扣），回复由 outcome 侧统一承担。玩家需要理解的是一条尺，不是两条互不通约的线。
  - **推论 —— 战斗与非战斗事件第一次被定价在同一把尺子上。** 「打一场输了 = 花掉三到五个事件的时间」是可跨事件类型比价的判断。落到玩家语言就是一句话：**「输一场，白走三到五步。」**
- **定名 = `lifeSpan` / 寿元。** 领域词与**代码标识符**统一：`CharacterProfile.Status` 上是 **`lifeSpan`** 单值，**不设 `lifeSpanLimit` 一类的上限字段，也不写成 `currentLife / lifeLimit`**；`CombatResult` 上是 **`RemainingLifeSpan`**。
- **只有 `lifeSpan` 一个字段：没有上限字段、没有上限截断、也没有「上限推拉」这回事（承重）。** 回复类事件与道具直接给 `lifeSpan` 加值，事件成本与战斗失败直接扣值，归零即 `LifeSpanExhausted`。
  - **不设上界的理由（承重）：** 加上界会引出「补满时用丹浪费」这一整类挫败感——玩家把余量堆得很高是他自己攒来的容错，不是漏洞；攒它要花事件位，本身就有机会成本。同理，「提升上限」这一档奖励并入「回复」，**内容侧少一个旋钮、少一层解释**。
  - **与 mana 的非对称是有意的，必须连同理由写清**（否则日后极易被当作不一致而「顺手统一」，把寿元也拆成 `currentLifeSpan / lifeSpanLimit` 两字段）：**mana 是每回合重置的节奏资源**，故需要 `currentMana / manaLimit` 两个字段；**寿元是跨事件、跨篇章累积的容错资源**，只需要一个数。

    | | 字段 | 推拉对象 | 上限 | 境界增授 |
    |---|------|---------|------|---------|
    | **mana** | `currentMana` + `manaLimit` | 事件推拉 **`manaLimit`**（±1，长期成长） | `currentMana` 每回合恢复到 `manaLimit` | 每次大境界 **`+1`（增量）**，无基线表（见 `systems/character-profile/mana.md`） |
    | **寿元** | **`lifeSpan` 一个字段** | 事件 cost / reward、道具与战斗失败**直接加减** | **无上限** | **增量**授予（炼气起始 1000，抵达筑基 +1000 / 金丹 +3000 / 元婴 +5000） |

- **预算表与跨篇章结转。** 炼气起始 **1000**；抵达筑基 **+1000**、抵达金丹 **+3000**、抵达元婴 **+5000**（元婴为游戏终点，该增量无可消耗预算，仅作最后一次数值更新并存档）。篇章突破时**不清空剩余寿元**：下一篇章的可用预算 = **该篇章增量 + 上一篇章的剩余**。因此「省着花」有**跨篇章回报**，寿元是一条贯穿整个轮回的资源线，而非每章重置的计时器。结转是 ChapterManager 在篇章边界的一项明确职责，见 `systems/services/life-cycle-service.md`。
- **扣减来源恰两个（承重）。**
  1. **事件成本 `lifeSpanCost`** —— 每完成一个 AdventureEvent 按该事件的 `lifeSpanCost` 扣减（内容侧为正数量值，物化时已取负）。它是 `selectCost` 的唯一 element，**支付先于结算、无条件施加、不因失败退还**。分档是控制篇章时长的主旋钮之一，见 `systems/adventure-event/common-properties.md` 与 `systems/balance.md`。
  2. **战斗 / 修炼失败的收口扣减** —— 战斗结束时若判负，损失量由「**敌人道念 − 角色道念**」的差值乘以该篇章的 `lossPerMomentum` 系数决定。**第一篇章的系数锁定为 10**，即「落后 8 点 = 掉 80 点」——一次乘 10，玩家在战斗屏上读到道念差即可当场折出寿元代价；后两章由系数吸收 `baseMomentum` 的量纲膨胀（表与形状锚见 `systems/balance.md`）。**不设上限截断**：换算就是全部规则。
  - **这两个来源在同一次收口事务里落到同一个值上。** 一次战斗失败因此**同时**压缩「还能失败几次」与「本章还能做几个事件」——这是被接受的设计取向：一次惨败真的会滚雪球。内容侧的编排必须验证「即使发生若干次典型失败，按标准路线走仍能在预算内升满」，见 `systems/game-progression.md`。
  - **战斗失败的负向扣减由 combat-service 在代码侧组装进 `Spoils`**；内容侧的 `OutcomeSpec` **恒不得**写负向 `LifeSpan`。组装纪律与加载期校验见 `systems/services/profile-service.md`。
- **战斗过程中不被读写，只在收口时刻被扣（资源纪律 · 承重）。** 战斗内的可读资源是**道念、mana** 两条；寿元既不被消耗也不被读取，胜负由**道念（momentum）**判定（见 `systems/scoring.md`）。
  - **理由：** 战斗内一旦能读写这条命，「留血打」「回血续航」这套以生命值为终止条件的战斗从后门回来，而本作的战斗终止条件是道念比拼。故**战斗内可用的道具与法则不得产出 `LifeSpan`**（加载期校验见 `systems/character-profile/item/_index.md` 与 `systems/character-profile/power/_index.md`）。
  - **战斗结算只会向下推这个值，永不向上。** 胜利不回升；向上只由事件产出与道具承担。
- **回复三通道。** A 回寿事件产出 · B 补天丹类法宝 · C 商店购入 B —— 三条共用同一条施加路径 `ChangeElement(CostKey.LifeSpan, +n)`，权威见 `systems/adventure-event/common-properties.md`。回复只走 outcome / reward 侧：`selectCost` 内 `LifeSpan` 的取值域收紧为非负。护栏是三道软闸 + 一条 Travel 禁令，**不设硬上限**。
  - **推论：回复类事件有明确的玩法位置**——它是玩家在「继续冒险」与「买回容错」之间的常态权衡。回寿事件本身也要付 `selectCost`，故净收益恒小于回寿量。
- **归 0 = `defeated`（大限将至）。** 取值域 `[0, ∞)`，归 0 构成终态。`lifeSpan` 在 `ResourceElements` 表中占一行 `(Min = 0, Max = null, DepletionDefeat = DefeatReason.LifeSpanExhausted, CostModifier = ModifierKey.LifeSpanCost, GainModifier = null, AllowedOps = Add)`：**下界截断到 0**，**上界明确为空**——这正是「只跟踪单值、无上限截断」在施加侧的落地，表里的 `Max = null` 不是待填项而是定值。终态判定读表而非硬编码检查本字段，见 `systems/services/life-cycle-service.md`。
  - **`DefeatReason` 里没有「输掉一场普通战斗」这一项**——`Practice` / `Standard` 档的战斗失败本身不终结角色，扣的是寿元；**`Finale` 档失败另走 `FinaleFailed` 这条独立通道**（它不是资源触底，见 `systems/adventure-event/combat/_index.md`）。
  - **`CostModifier` 同时作用于两个扣减来源（已知耦合，接受）。** 一条「事件消耗 −20%」的法则会同时减轻 20% 的战斗失败惩罚。拆成两个 `CostKey` 就等于没有合并；叙事上「延寿」同时减轻两类损耗也是通顺的。依据列的完整表述见 `systems/services/profile-service.md`。
- **呈现 = 明文常驻、恒精确。** 余量常驻 EventOption 选择界面的角色状态条（`❤` 位），**恒显示精确数值**；余量低于本章预算 10% 时转红字（纯视觉强调）。`selectCost`、回寿收益标注、道具描述与结算面板的寿元行**一律恒精确展示**，不设任何门控。
  - **它不常驻战斗屏。** 战斗屏只呈现道念对比与差值；余量在进入战斗前的确认页已知，结算面板如实展示本次扣减量与扣后余量。常驻显示一个战斗内不可改变的量只增噪音，还会诱导「留血打」的错误心智。见 `ux/combat-ux.md`。
  - **可被精确规划是被接受的取向。** 玩家能算清整章的寿元开销；要算的东西从「两条互不通约的线」变成「一条线上的取舍」，决策的深度不降、只是从模糊变清晰。
  - **它不是隐藏属性。** 隐藏属性收敛为**道心 / faith** 与**煞气 / Bloodlust** 两项，归 `systems/services/plot-manager.md`；寿元不在其列。
- **履历上的寿元曲线。** `PastEventEntry` 带一格 `LifeSpanAfter`（逐事件的结算后余量），使修行历程能画出这条曲线——它现在就是角色的完整生命曲线，回升段与战斗失败的下跌段同图。读取算法见 `systems/character-profile/_index.md`。

Source: `handoffs/2026-09-03-lifespan-cost-table-and-budget-scale.md` · `handoffs/2026-08-30-life-lifespan-merge.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **`lifeSpan` 是角色唯一的资源命线；两个扣减来源（事件成本 · 战斗失败）、一个回复口；归 0 → `defeated`**。
- **只跟踪单值、无上限字段、无上限截断；境界增授是给它加一笔** → `decisions/ADR-0045-life-span-single-value.md`。
- **战斗过程中不读写寿元，只在收口时刻扣减** → `decisions/ADR-0081-hidden-stats-outside-combat.md`（隐藏属性侧）与本文件（资源侧）。
- **道念差 → 寿元损失的换算与 `lossPerMomentum` 逐篇章系数** → `decisions/ADR-0018-momentum-scoring-model.md`。
- **寿元明文常驻、恒精确展示，不属于隐藏属性体系** → `decisions/ADR-0016-hidden-stat-band-model.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`lossPerMomentum` 的 ch2 / ch3 系数取值。** ch1 = 10 已锁定；后两章已由形状锚解出候选值 5 / 10，定案待反推，口径见 `systems/balance.md`。
- **回复的幅度与来源分布。** 「通过 outcome 侧恢复」已定；三档的绝对点数（按本章可用预算的 5% / 10% / 20% 折算，ch1 即 50 / 100 / 200）仍待定案，归内容扩充后的统计校准。→ `systems/adventure-event/`、`systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/life-span.md`（待建）。
