# ADR-0136 — 两层档案持有骨架：`PlayerProfile` 持有 `List<CharacterProfile>`

- **状态：** Accepted
- **日期：** 2026-07-15
- **来源：** handoffs/2026-07-15-adventure-event-profiles.md

## 背景

本作有两条生命周期截然不同的状态线：**跨轮回持久**的元进程（解锁、成就、图鉴、账号信息）与**单次轮回内**的角色状态（卡组、持有物、寿元、修行历程）。若把两者混在一个档案里，「轮回开始时干净重置」就无从下手——重置动作要么误删账号级解锁，要么漏清角色级残留。

## 决策

**两层持有骨架：`PlayerProfile`（账号级主档）持有 `List<CharacterProfile>`（轮回级），并列同名的字段表分列在两侧。**

- `PlayerProfile` 跨轮回持久，是**云端权威主档**；`PlayerPower` / `PlayerItem` / `Achievement` / Codex 一族独立于任何单次轮回。
- 每个 `CharacterProfile` 对齐 **CycleState** 概念——单次轮回、单角色的状态与历史全部住在它下面。
- **AdventureEvent 自足**：事件条目不持有指向其他事件的引用，事件之间的走向由服务现算。

字段表与逐字段权威 → `systems/player-profile/_index.md`、`systems/character-profile/_index.md`。

## 理由

- **它让「轮回开始时干净重置、结束时拆解」成为一个明确的对象操作**（换掉 / 清空一个 `CharacterProfile`），而非散落各处的逐字段清理。
- **它与「强制在线 · 云端权威」直接对齐**：`PlayerProfile` 是云端权威主档（`systems/player-profile/_index.md`），同步面因此有一个明确的根。
- **事件自足使走向可由服务现算**，从而事件内容不必在条目里维护一张连边图——这条后来被 `decisions/ADR-0012-materialization-model.md` 与 `decisions/ADR-0026-event-generation-weighting-pipeline.md` 落成完整管线。

## 备选方案

- **单一扁平档案，用字段前缀区分层** — 否决：轮回重置退化为一张必须手工维护的「哪些字段要清」清单，漏一格即跨轮回泄漏。
- **事件条目持有指向后继事件的引用（内容侧连边）** — 否决：走向要随剧本调制与权重管线变化，写死在条目里即无法调制。

## 后果

- 一切「这个字段属于哪一层」的问题都有唯一判据：**它跨不跨轮回** → `systems/player-profile/_index.md` 的分层通则、`decisions/ADR-0050-account-field-layering.md`。
- 同步与存档的根是 `PlayerProfile`；轮回级状态经它的 `characterProfile` 列表随行 → `systems/services/sync-service.md`。
- 事件内容永远写不出「打完这场去那场」——路由归服务 → `systems/services/future-event-service.md`。
