# ADR-0051 — `SourceCode` 记账、`ExclusiveSource` 准入，两者方向相反；`Source` 成员的分野判据 = 谁组装出这条 element

- **状态：** Accepted
- **日期：** 2026-08-10
- **来源：** handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md, handoffs/2026-08-12e-ability-grant-draw-pool.md, handoffs/2026-08-16h-grant-source-assembler-criterion.md

## 背景

「这个东西是从哪来的」在本作有两个用途，方向相反：① **记账**——已持有的条目记住它的来源（残卷分档的 `x` 要数它，→ `ADR-0049`）；② **准入**——某个条目只允许从某个渠道获得（成就专属奖励不该出现在普通抽取池里）。

而 `Source` 枚举本身的成员该怎么切分，最初按「属于哪类事件」表述，被 Explore 真身与 Exchange 非购买 outcome 两处打穿。

## 决策

两个字段，方向相反：

- **`SourceCode : Source`** 落在**持有条目**上——记账，回答「它是怎么来的」。
- **`ExclusiveSource : Source?`** 落在**内容定义**上——准入，回答「它只能怎么来」。

**`Source` 成员的分野判据 = 谁组装出这条 element**（承重 · **不看它属于哪类事件、也不看它最后被谁写进去**）。`EventOutcome` 与 `CombatReward` 因此**不合并**，并在 `eventEnd` 加一条**单向组装校验**：未走过 combat-service 的事件出现 `CombatReward` → 整批拒绝；反向不判非法。

账号级能力授予的**三条渠道共用同一段抽取**，排重发生在**取池阶段**；成就奖励改走「指定条目 + 成就限定」以保证**恒不落空**。

枚举成员表、合法子集表与投影纪律 → `systems/common-properties.md`。

## 理由

按事件类型切分会被「同一类事件里有多个组装者」和「同一个组装者服务多类事件」两侧同时打穿；按组装者切分则两侧都闭合，因为组装者是代码里唯一确定的位置。

施加路径相同**不构成合并理由**——否则 `ExchangePurchase` 与 `InitialGrant` 也该合并，而它们的记账含义完全不同。

## 备选方案

- **按事件类型表述 `Source` 分野** — 否决：被 Explore 真身与 Exchange 非购买 outcome 打穿。
- **`EventOutcome` 与 `CombatReward` 合并** — 否决：见上。
- **命名为 `GrantChannelLock`** — 否决（08-12e）：它不是锁，是准入声明。
- **新开一个布尔 `AchievementExclusive`** — 否决：一个布尔只能表达一个渠道，下次再来一个渠道就要第二个布尔。

## 后果

- 单向校验只挡一个方向：`CombatReward` 出现在非战斗事件是错，`EventOutcome` 出现在战斗事件是对的（战斗事件也有非战斗产出）。
- `ExclusiveSource` 只覆盖 `PowerData` / `ItemData` 两个类，但落点横跨两棵子树 ⇒ 定义写在顶层（→ `ADR-0057`）。
- 后续新增 `Source.PackSell`（→ `ADR-0098`）沿用同一判据。
