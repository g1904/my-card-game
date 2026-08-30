# ADR-0129 — 隐藏属性推拉的方向落在 `HiddenStatGrant` 第三格，沿数值轴命名

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-hidden-stat-grant-direction.md

## 背景

模板侧的产出格 `HiddenStatGrant[] HiddenStatGrants` 原为两元组 `(Stat, Grade)`，写不出方向：道心是双臂属性（「静室枯坐」推高、「屠戮山门」压低，同一属性同一档、方向相反），煞气虽以上行为主但可被净化类事件下拉，而 `HiddenStatGrade` 的平衡表映射值是**正量**。方向位未定之前，`HiddenStatGrants` 这一格写不出一半正常的内容编排。

它不是「隐藏属性能不能为负」（取值域恒 `[0, 100]`），也不是「element 层如何表达增减」（`ChangeElement.BaseValue` 带符号早已定案）。悬着的只是**模板层的书写位**。

## 决策

**`HiddenStatGrant` 加第三格 `HiddenStatDirection Direction`，取新的二值封闭枚举 `{ Raise, Lower }`——沿数值轴命名，不含价值判断。**

**符号在物化组装时产生**：读平衡表取正量、按 `Direction` 取负，展开成一条 `ChangeElement(key, ±v, Add)`，与 `SelectCost` 的 `lifeSpanCost` 取负、`OutcomeRule.Direction` 取负在同一处。element 层、`AppliedChange` 层、存档层**一格都不用动**。

**不加 `Unset = 0` 哨兵。** `Stat` 保持宽类型 `HiddenStat`，由加载期校验收窄为可推拉的那几项，不另立近同义枚举。物化展开伪码与逐条校验 / 断言见 `systems/architecture.md`、`systems/adventure-event/common-properties.md` 与 `systems/services/future-event-service.md`。

## 理由

- **落点判据是既有的三级问法**（`decisions/ADR-0067-element-carrier-three-tier-criterion.md`）：配表只装「同一个 key 的**每一次**变更都取同一个值」的性质，而方向是**单次变更的属性**（同一个 `Faith` key，这个条目推高、那个条目压低）⇒ 方向落不进配表，只能落在内容作者可逐条书写的那一格。
- **零新概念**：与 `ChangeElement` 既有的有符号形态一致，「取负发生在物化组装」是逐字复用的既有纪律。
- **档位表条目数不变**：平衡表仍是 3 行，`HiddenStatGrade` 仍是 4 成员，`ExperienceGrade` ↔ `HiddenStatGrade`「形态同构而非同一张表」的关系不受扰动。
- **沿数值轴命名而非价值轴**：`Raise` / `Lower` 对每个属性一律无歧义。价值判断词（`Gain` / `Loss`）在煞气这类累积物 / 负面属性上有两个自洽读法，`.tres` 里读不出作者想的是哪一种。
- **不设哨兵**：`OutcomeRule.Direction` 同为二值方向枚举、全库无哨兵；本库对「为一个常态设一个必须显式置位的成员」判为反向的负担。
- **不收窄 `Stat` 的类型**：照 `OutcomeRule.PoolKind` 用宽枚举 + 校验收窄的既有先例——一条 `PushError` 比一个近同义枚举便宜；`HiddenStat` 正被 `HiddenStatBandData.Stat`、`PlotCondition.Kind`、EventBus 的 `PlotThresholdReached` 三处使用，多一个近同义枚举会让「该用哪个」成为每次新增字段都要回答一遍的问题。
- **方向位不引入任何新的钳制点**：逐步落位全部是既有形态（物化产生符号 → 存档记未截断值 → `Op == Add` 分支 → 两个 key 的两个修正列恒 `null`，pipeline 不介入 → `Clamp(raw, 0, 100)`）。截断不构成 `ApplyResult.Fail`。
- **既有校验已把「方向互相抵消」封死**：同一 `HiddenStat` 出现两条本就被拒 ⇒ 不需要为方向位新增任何去重校验。

## 备选方案

- **档位表分正负两套** — 否决：把单次变更的属性焊进 element 类型的量纲轴，两套值注定冗余却可被填成不一致。
- **复用 `OutcomeDirection { Gain, Loss }`** — 否决：价值判断词按到了语义双读的位置。
- **逐属性固定方向** — 否决：结构上表达不出道心的双向推拉。
- **加 `Unset = 0` 哨兵** — 否决：见理由。**代价明写**：忘填 `Direction` 会静默落成 `Raise`，而 `Raise` 对煞气恰是常见方向，比一般字段更难在测试中显形。
- **把 `Stat` 收窄为 `PushableHiddenStat`** — 否决：见理由。
- **方向位落 `HiddenStatBandData`** — 否决：档位判定读钳制后的当前值，触发规则已由「`BandIndex` = 离常态的距离」消掉方向维。

## 后果

- 内容作者每条 grant 多填一格；内容侧迁移面为**零**（`content/` 下当时尚无任何 AdventureEvent 条目）。
- **方向位与 modifier 语义零耦合**：两个可推拉 key 的 `CostModifier` / `GainModifier` 均为 `null`——一条法则能伪造隐藏属性，即等于伪造整条剧本线的触发条件。
- 两侧 `Elements` 的那两条恒相同、由同一段组装代码从同一个 `HiddenStatGrants` 展开，「不加顶层第三格 `Always`」的理由原样成立。
- 加载期与物化期各增两条校验 / 断言（`Grade == None` 拒绝，以及物化侧的两条对偶断言）。
- **本 ADR 只定结构与符号来源，不定量值**：`HiddenStatGrade` 的三个映射值与「隐藏属性的增减触发」逐条目映射仍未定。
- 因此必须这么写的文档：`systems/architecture.md`（枚举 + record + 三条承重论证）· `systems/adventure-event/common-properties.md`（字段行与校验）· `systems/services/future-event-service.md`（物化展开伪码）· `systems/balance.md`。
