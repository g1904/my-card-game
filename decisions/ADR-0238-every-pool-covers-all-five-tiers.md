# ADR-0238 — 每个具名奖励池五档全非空：表管分布，池管族成分与具体条目

- **状态：** Accepted
- **日期：** 2026-09-09
- **来源：** handoffs/2026-09-09d-combat-rarity-and-reward-scale.md · handoffs/2026-09-09f-event-reward-and-hidden-stat-orchestration.md · answer-logs/log-combat-rarity-and-reward-scale.md

## 背景

原本设想用**池的档幅上下界**表达档位与篇章差异：`Practice` 池只放 Tier1–2、`Crushing` 场次的池放 Tier2–4，逐章上移。这套写法把「能拿到多好的东西」编码进池成分。

用户对「碾压档奖励怎么给」的裁决否定了这条路：**「让每个 Tier 都有一定可能性，只是碾压给更好东西的概率更大点」。**

## 决策

**每个具名奖励池的成员覆盖 `Tier1`–`Tier5` 全五档，任一档非空。**

**承重的机制事实：** 混合池上只按 `RarityTier` 加权 ⇒ **某一档的抽中概率就是权重表给的那个数，与该档在池里有几条条目无关**（只要非空）。

⇒ **权重表管分布，池管族成分与具体条目。**

**这一口径覆盖三处产出面**（战后奖励池 · 商店库存 · 事件掉散牌）：**五档一律可达**；`RarityFilter` 只用于逐条编排的族 / 档**倾向**，**不用来把某一整档整体排除**。

→ `systems/balance.md` · `systems/services/combat-service.md` · `systems/adventure-event/exchange/common-properties.md` · `systems/adventure-event/common-properties.md`。

## 理由

用户要的语义是「概率差异」，而档幅上下界表达的是「可达 / 不可达」——两者不是程度差别，是类型差别。

一旦五档全非空，篇章维就**必须**落在权重表上（否则篇章对稀有度零影响），这反过来逼出了 `m(c)` 这个旋钮（→ `ADR-0237`）。

三张表因此**全程有效**：`Crushing` 表的 Tier4 / Tier5 两格不是死配置，碾压确实能拿到高档东西，只是概率更大而非必然。

## 备选方案

- **用池的档幅上下界表达差异** — 否决：把概率差异写成可达性差异，且使篇章维无处安放。
- **靠 `RarityFilter` 卡掉整档来区分篇章** — 否决：同上，且会让同一个过滤格身兼「倾向」与「排除」两义。

## 后果

- **代价：逐条稀有度过滤格的编排自由度收窄，商店没有独立的稀有度旋钮。**
- `Practice` 池**不在成分上重复表达神通排除**——生成侧的族级排除（→ `ADR-0169`）已机械兜底，池里写不写都不影响结果，写了即两处真值。
- 每池五档非空成为 `/audit-content` 的一项汇总核对（只报告不阻断）。
