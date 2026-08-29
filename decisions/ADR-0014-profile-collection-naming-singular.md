# ADR-0014 — 透明路径的集合字段名恒为单数，改名做一次性切换不设兼容期

- **状态：** Accepted
- **日期：** 2026-08-17
- **来源：** `handoffs/2026-08-17-profile-field-naming.md` · `answer-logs/log-profile-field-schema.md`

## 背景

客户端把两层 Profile 的集合字段统一为单数，而**透明路径本身是契约的一部分**（`contracts/profile-sync.md` §5）——白名单与排除清单里写的那些 JSON path 必须同批改名，否则边界两侧对同一个字段有两个名字。

## 决策

**透明路径中的集合字段名恒为单数**（`playerPower` · `playerItem` · `achievement` · `disabledAbility`），条目键取 `powerId`（原 `id`）。

**本次改名做一次性切换、不设兼容期**，并入客户端 Profile 字段面收口的同一次 `schemaVersion` bump。切换成立的**三个前提，缺一即不成立**：线上无真实账号数据 · 两侧同批落笔 · 一次性不留双读期。

通则、例外边界（`characterDiffs` / `playerDiff` 是 diff 报文结构键，不由字段映射产生，不受本通则约束）与白名单四行 → `contracts/profile-sync.md` §5 §5b。

## 理由

映射是**机械的**：存档字段名经客户端 camelCase 单点策略逐字变成 JSON path。任一侧留一个复数例外，边界上就得挂一张例外表——**而那张表本身即第二权威**（`contracts/profile-sync.md` §5b）。

不设兼容期的理由来自 `contracts/profile-sync.md` §7a 的既定处置「仅记账、不拒绝、不改写」：双读期内**没有任何信号**能告诉任一侧对方还没改，不一致的症状是风控噪声而非报错，会随双读分支长期存活而**永久不可见**。而三个前提中最要紧的「线上无真实账号数据」当前为真。

## 备选方案

- **带版本判别的双读期（两侧各接受新旧两种路径一段时间）** — 见理由段：不一致永久不可见。
- **只改容器段（`/playerPower[*]/id` 保持不变）** — 客户端四类持有条目的键名已全族改为 `<类型>Id`，只改一半会让边界上出现新的例外。
- **`characterDiffs` 一并改名** — 它是 diff 报文的结构键，不由字段映射产生，改它是给通则强行扩边界。

## 后果

- `contracts/profile-sync.md` §3a 示例 · §5 白名单与排除清单 · §5b · §7 与 `contracts/envelope.md` §8 可见性表的路径示例**必须**用单数形态。
- 契约侧任何后续的路径重命名仍是**破坏性变更**，须重新满足上述三个前提；一旦线上有真实账号数据，第一个前提即永久失效，届时改名必须另找机制。
- `/playerPower[*]/sourceCode` 的**取值表示**（字符串枚举名 · 名与 code 双双冻结）属 `ADR-0012`，本 ADR 只定字段名形态。
- 客户端侧对位权威在 `game-design-documents/systems/player-profile/_index.md`、`game-design-documents/systems/character-profile/_index.md`，bump 清单权威在 `game-design-documents/systems/services/sync-service.md`。
- 后续同族扩员（如客户端图鉴族增员）按**后缀判据**恒定覆盖、不列举也不计数，那是本通则的直接应用而非新决定 → `contracts/profile-sync.md` §5 排除清单。
