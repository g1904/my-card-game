# ADR-0049 — 道统残卷整条焊到 Finale 上；掷骰走与 `CycleSeed` 解耦的账号级 RNG

- **状态：** Accepted
- **日期：** 2026-08-09
- **来源：** handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md, handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md

## 背景

元进程需要一条**失败侧**的产出线——否则一个打不过天劫的玩家除了时间什么也没得到。但任何「失败也给奖励」的机制都要回答：怎么防止玩家靠反复失败刷奖励。

## 决策

**道统残卷 `PlayerPowerFragment` 整条焊到 Finale 上**：Finale **失败**累积概率、Finale **胜利**掷骰并在**同一次 eventReward** 兑现。

分档自变量 `x` = **已拥有且 `SourceCode == Source.FinaleWin` 的法则数**（礼包 / 成就渠道**不计入**）。

掷骰走**与 `CycleSeed` 完全解耦的账号级 RNG**：客户端掷、后端可复算。

概率表与分档 → `systems/balance.md`；字段与不变式 → `systems/player-profile/player-power/_index.md`；与付费的关系 → `systems/monetization.md`。

## 理由

焊在 Finale 上使刷取代价恒等于「打完一整个篇章」，而 Finale 本身有寿元成本——刷不划算。胜利才兑现则保证玩家至少赢过一次。

`x` 只数渡劫来源的法则，含义是**「靠渡劫拿得越多，后续越难再从渡劫拿到」**——这是一条只作用于该渠道内部的收敛，不惩罚从其他渠道获得的法则。付费礼包给的法则因此**不压低上限**：付费收益是纯净收益，这是设计意图。

账号级 RNG 必须与 `CycleSeed` 解耦，否则**篇章重试会换 `CycleSeed`，等于让玩家靠重试换掷骰**。

## 备选方案

- **走 `SeedManager` 的四条轮回级子流** — 否决：篇章重试换种子 = 重掷。
- **跨轮回待发放字段（这次失败，下次开局补给你）** — 否决：新增跨轮回状态与一套发放时机。
- **礼包 +1 法则压低残卷上限** — 推翻（08-10b 明确推翻 08-09b §6）：付费收益应为纯净收益。
- **给残卷设账号级硬上限 / 删掉闸 ① / 序号区间隔离** — 均否决（08-12e）。

## 后果

- 账号级 RNG 是 SplitMix64，测试向量在 `backend-design-documents/contracts/profile-sync.md` §6a，验收可逐位对表。
- `SourceCode` 的记账语义因此成为承重设计（→ `ADR-0051`）：`x` 的口径直接读它。
- 这是元进程失败侧目前**唯一**已定案的产出线。
