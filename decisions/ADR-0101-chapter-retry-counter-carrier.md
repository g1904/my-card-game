# ADR-0101 — 篇章重试计数归 `CharacterProfile.chapterRetry`，`attemptIndex` 派生层整层删除

- **状态：** Accepted
- **日期：** 2026-08-06
- **来源：** handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md · handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md

## 背景

篇章重试相当于重开一局，因此重试时必须换一套战斗随机流。此前的做法是在战斗子流上再派生一层 `Hash64(combatStreamSeed, eventId, attemptIndex)`，由 `attemptIndex` 区分第几次尝试。同时 ch2 / ch3 有重试上限，需要一个地方记「用掉了几次」。

## 决策

**重试计数只有一种：篇章重试，由 `CharacterProfile.chapterRetry` 承载**，形态 = 三个具名篇章字段、通关后保留计数。它是**计数器容器，不是上限持有者**——上限值仍在别处，凡读取处不得硬编码常量（`ADR-0004`）。

**`attemptIndex` 这一层 RNG 派生整个删除。** 重试换随机流的实现是「给这一次重试一套新的随机流」，不是在既有流上再派生一层。

ch1 的重试语义不变（重开即随机生成新角色），其重开次数以账号级统计计数承载，与 ch2 / ch3 的角色级计数不同层。

字段清单与逐条语义 → `systems/services/life-cycle-service.md`、`systems/character-profile/_index.md`。

## 理由

`attemptIndex` 的两个动机都已消解：防「退出重进重掷」由决策点存档 + RNG `State` 持久化关闭（`ADR-0036`）；「篇章重试是否换一套战斗随机」答定为换，而换法是新流而非再派生。**派生层因此没有任何剩余职责**——留着它就是留一个无人消费却必须被每处 seed 派生代码携带的参数。

三个具名字段而非索引数组 / 字典：篇章数是固定的游戏结构，具名字段让「读哪一篇章的计数」在编译期成立。通关后保留计数而非清零，是因为它同时是履历的一部分。

## 备选方案

- **ch1 计数也挂角色级** — 否决：ch1 重试即换新角色，角色级的 ch1 计数对每个新角色恒为 0，是个死字段。
- **改写 ch1 重试语义为「可重试同一个角色」以让角色级计数有意义** — 否决：那会推翻既定的 ch1 重开模型并影响元进程压力模型。
- **保留 `attemptIndex` 派生层** — 否决：见理由，两个动机均已消解。

## 后果

- `systems/services/life-cycle-service.md` 是重试计数的权威；`systems/common-properties.md` 的 RNG 子流派生式因此写作 `Hash64(CycleSeed, streamName)`，不含 `attemptIndex` 层。
- 重试上限的取值与载体是另一件事 → `ADR-0117`。
- ch1 的账号级重开统计落 `PlayerProfile` 的纯读数层，不参与任何规则判定 → `systems/player-profile/_index.md`。
