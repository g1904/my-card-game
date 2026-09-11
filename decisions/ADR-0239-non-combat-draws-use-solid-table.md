# ADR-0239 — 非战斗产出侧固定取「`Solid` 表 × 本篇章 `m(c)`」

- **状态：** Accepted
- **日期：** 2026-09-09
- **来源：** handoffs/2026-09-09d-combat-rarity-and-reward-scale.md · answer-logs/log-combat-rarity-and-reward-scale.md

## 背景

三张稀有度权重表由战斗的**优势档** `Tier` 选定（→ `ADR-0237`）。但另外两处产出面根本没有这个量可填：事件产出侧 `OutcomeRule.DeckOperation` 的 `AddLooseCard` 池抽，以及商店库存 `ExchangeStockRule` 的抽取。

## 决策

**事件掉散牌与商店库存的稀有度抽取，固定取「优胜 `Solid` 那一张 × 本篇章的篇章乘数 `m(c)`」**，不按战斗优势档选表。

**零新增结构、零新字段。**

→ `systems/adventure-event/common-properties.md`（事件侧）· `systems/adventure-event/exchange/common-properties.md`（商店侧）。

## 理由

两侧都**没有 `advantage` 这个量可填**，取三档中的中间档是唯一不引入新语义的选法。

篇章差异由已有的 `m(c)` 承担，因此不需要为这两条通道另建任何表。

## 备选方案

- **给商店 / 事件各配一张独立的稀有度权重表** — 否决：新增两张表却没有任何选表依据，且商店从此有一个独立的稀有度旋钮，与「表管分布」的单一来源相抵。
- **按 `RarityFilter` 卡档来区分篇章** — 否决：`RarityFilter` 只表达倾向，不表达可达性（→ `ADR-0238`）。

## 后果

- **商店没有独立的稀有度旋钮**；库存的档位倾向只能靠 `RarityFilter` 表达族 / 档偏好，不能整档排除。
- 三处产出面共用同一套分布语义，`/audit-content` 的稀有度对账因此只需一套口径。
