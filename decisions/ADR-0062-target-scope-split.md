# ADR-0062 — 目标 target 与作用域 scope 分开建模、共用 `EntryFilter`；结算时逐槽重检，采部分 fizzle

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** handoffs/2026-08-16c-effect-keywords-and-targeting.md

## 背景

「打击一个敌方单位」与「打击全部敌方单位」看起来是同一个维度上的两个取值，但它们的语义完全不同：前者需要玩家在出牌时**选**，后者在结算时**算**。把两者塞进一个字段，结算逻辑就要不断分辨「这是选出来的还是算出来的」。

## 决策

**目标 target 与作用域 scope 分开建模，共用同一个 `EntryFilter`。**

- **target** — 出牌时由玩家指定，落 `EventOption` / 动作的槽位。
- **scope** — 结算时按过滤器现算。

结算时**逐槽重检**：某个槽位的目标已不合法（已离场 / 已不满足过滤条件）→ 该槽 fizzle，**其余槽照常结算**（MTG 式**部分 fizzle**，不是整张牌作废）。

`EntryFilter` 形态与结算流程 → `systems/character-profile/deck/common-properties.md` 与 `systems/services/combat-service.md`。

## 理由

共用 `EntryFilter` 是这条设计的经济性所在：两者要表达的「哪些实体算数」是同一件事，只是求值时机不同。分开建模而共用过滤器，得到的是两个清晰的时机 + 一份过滤逻辑。

部分 fizzle 而非整张作废：整张作废意味着「打两个目标其中一个跑了 ⇒ 这张牌白打」，对玩家过于苛刻，且它使多目标牌在混乱局面下不可用。

## 备选方案

- **target 与 scope 合为一个字段** — 否决：结算逻辑要不断分辨取值来源。
- **整张牌 fizzle** — 否决：多目标牌在混乱局面下不可用。
- **两者各用一套过滤器** — 未采纳：表达的是同一件事，两套必漂移。

## 后果

- `ActionResult` 的拒绝理由与 `CombatFeedEntry` 的 `FizzledSlots` 都以**槽位**为粒度（→ `ADR-0087`）。
- 「多目标槽位类别告知」不落在卡面上，交给选目标态的指令条（→ `ADR-0083`）。
