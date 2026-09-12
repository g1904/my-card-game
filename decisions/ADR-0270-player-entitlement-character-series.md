# ADR-0270 — 付费系列解锁落 `PlayerEntitlement.CharacterSeries`：只由后端写、客户端无写入通道；本库第一次真实 `schemaVersion` bump（v2）

- **状态：** Accepted
- **日期：** 2026-09-12
- **来源：** handoffs/2026-09-12-premium-character-series-unlock.md · answer-logs/log-premium-character-series-unlock.md

## 背景

`decisions/ADR-0255-paid-character-series-track.md` 把解锁载体（`PlayerProfile` 具名集合 + 取池过滤 + 一次 `schemaVersion` bump）整块留给方案推演。这一格落在哪个持久层、谁能写它、要不要配一个兑现水位、要不要 bump —— 四问互为前提，必须一并答，否则客户端与后端会各自假设一套写入语义。

## 决策

**`PlayerEntitlement` 新增一格 `CharacterSeries : IReadOnlyList<CharacterSeriesEntry>`**，元素 `readonly record struct CharacterSeriesEntry(string SeriesId)`，JSON path `/entitlement/characterSeries`，默认空列表。

- **写入方只有后端**（验票事务内尾部追加）。**客户端无写入通道**：不进任何 `ProfileChangeSpec` 列、`ResourceElements` **不加行** ⇒ 日后误写的置位当场在施加时 `PushError` + 整批拒绝。
- **不配兑现水位、不加 `Status` / `Charges` / `SourceCode`。**
- **受回声校验约束**；**客户端对该 path 不改写、不去重、不归一化**（承重）—— 对侧对它取有序逐元素比较，前提正是后端恒在尾部追加、客户端原样回声。
- 读档校验三情形：非数组 / 缺 `SeriesId` → `PushError` + `entitlement` 本次不进 diff + 触发一次 pull、不钳制；`SeriesId` 解析不到内容条目 → `PushWarning` + 保留条目；同 `SeriesId` 重复 → `PushWarning` + 呈现层去重、不改写存档值。

**`schemaVersion` bump 到 v2 —— 本库第一次真实 bump。** `/entitlement/characterSeries` 落在受回声约束的顶层键 `entitlement` 内 ⇒ 命中形态纪律 ⑤ 第三档（两侧同批落笔并进版本行），不能走「不透明段内追加不 bump」那一档。**条件分支如实写下：** 若付费系列改在首发之前落地，按「首发前的一切改动全部归入 v1」并入 v1 清单，不产生 bump；两条路径的结构一字不差，只是登记位置不同。

字段表、读档表与逐版登记行的权威在 `systems/player-profile/_index.md` 与 `systems/services/profile-schema-versions.md`（**本 ADR 不复述**）。

## 理由

`systems/player-profile/_index.md`：**照抄一个 `CharacterSeriesRedeemedOrdinal` 是最诱人的错误答案。** 水位存在的唯一理由是「发货动作在客户端，需要一个云端可见的已发货记号」；本付费点的发货在后端，验票成功那一刻货已在云端 ⇒ 水位无对象可记。

存系列 id 而非角色 id：解锁粒度已由 `ADR-0255` 定为整系列 → 判据见 `decisions/ADR-0269-character-series-id-and-track-fields.md`。

「不去重、不归一化」与「后端尾部追加」是一对必须同时成立的条款：任一侧单独破，回声比对会在**正常账号**上稳定失败——那是一类无从复现的线上故障。

## 备选方案

- **配一个 `CharacterSeriesRedeemedOrdinal` 水位** — 否决：本付费点无客户端发货动作，水位没有对象可记。
- **开一条客户端写入通道（进 `ProfileChangeSpec`）** — 否决：授予的权威在后端验票事务内，客户端多一条写入面即多一处可伪造的解锁。
- **客户端读档时去重 / 归一化** — 否决：破坏有序逐元素回声比对。
- **走「不透明段内追加不 bump」档** — 否决：该格是受回声约束的透明路径，命中形态纪律 ⑤ 第三档。

## 后果

- 客户端整个兑现段不存在 → `decisions/ADR-0274-character-series-no-redemption-stage.md`。
- 取池过滤读的就是这一格 → `decisions/ADR-0272-character-unlock-filter-in-life-cycle-service.md`。
- 后端承接（SKU、验票写入报文与幂等 / 事务语义、`profile-sync` 两张表各加一行、兼容矩阵 `schemaVersion = 2` 登记）归 `backend-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`，**矩阵先加、客户端后发**。
- `profile-shape-v2.json` golden 形状快照待建。
