# ADR-0269 — `CharacterData` 加 `SeriesId` + `Track` 两格；轨道用带哨兵的枚举而非 `bool`，配五条加载期校验

- **状态：** Accepted
- **日期：** 2026-09-12
- **来源：** handoffs/2026-09-12-premium-character-series-unlock.md · answer-logs/log-premium-character-series-unlock.md

## 背景

`decisions/ADR-0255-paid-character-series-track.md` 开了付费解锁角色系列这一支，但明写「`CharacterData` 的轨道标记字段形态归 `/provide-solution-draft` 推演，首批一格不落」。轨道要落成内容层的什么形状、系列要不要一个可引用的键、漏填怎么办 —— 这三问必须在内容开张之前答完，否则第一批条目写下去就没有可校验的对象。

## 决策

**`CharacterData` 新增两格模板静态字段**（`Id` 之外的内容层标记，**存档增量为 0**）：

- **`SeriesId : string`** —— 两段式 `character_series.<snake_case_slug>`，该角色所属的角色系列。
- **`Track : CharacterTrack`** —— 枚举 `Unspecified = 0` / `Free = 1` / `Paid = 2`。

**轨道必须是带哨兵的枚举，不能是 `bool IsPaid`。** Godot 的 `[Export]` 未填即取 0：`bool` 的漏填会**静默落进免费轨道**，而轨道发布后不可变 ⇒ 一次漏填不可逆。哨兵把「漏填」变成加载期可检出的一档。

**加载期校验新增五条（#14 ~ #18）**：`Track == Unspecified` · `SeriesId` 形态不合 · 同系列 `Track` 不一致 · 同系列条目数 ∉ {5, 10} · `Track == Paid` 且基线 `ContentEnabled == false`。**#16 / #17 / #18 一律走 `AllIncludingDisabled()`。**

配套两条否定：**五行对称不做代码校验**（归 `/audit-content`）· **不新增「解锁过滤后可选池为空」这条校验**。

字段表、枚举体与十八条校验表的权威在 `systems/character-profile/_index.md`（**本 ADR 不复述**）。

## 理由

`systems/character-profile/_index.md`：三条后置校验必须走 `AllIncludingDisabled()` —— **flags 不参与合并后强校验**，按 `AllEnabled()` 统计会让「线上秒关一个问题角色」把启动打崩，把一次运营动作变成一次启动事故。

存系列而非存角色：解锁粒度已由 `ADR-0255` 定为整系列，若持有集合存角色 id，边界另一侧就必须持一张「SKU → 该系列的 5 / 10 个 `character.<slug>`」的表 —— 那是内容编排知识，抄到另一侧即制造第二权威而本库无发现机制（与 `decisions/ADR-0005-knowledge-thin-reference-layer.md` 的副本判据同源）。

不立「池为空」那条校验：首批五角恒免费恒可用 ⇒ 该情形永不可达，而一条永不可达的校验只会误导后来者以为免费轨道可能为空。

## 备选方案

- **`bool IsPaid`** — 否决：`[Export]` 漏填静默落进免费轨道，且轨道不可逆。
- **把轨道放进存档 / 账号侧** — 否决：轨道是内容模板属性，不随账号变化；放存档即凭空制造迁移义务。
- **同系列条目数不设校验，只靠 `/audit-content`** — 否决：{5, 10} 是定价锚的记账单位，机械可判，落代码零成本。
- **五行对称也做代码校验** — 否决：它是内容编排纪律而非结构不变式，与轨道棘轮判给内容纪律是同一条处置。

## 后果

- 内容层开张必须先有这两格：`content/character/_index.md` 的类型档案与系列台账据此建立。
- `SeriesId` 的两段式前缀为 `CharacterSeriesData` 留好引用键 → `decisions/ADR-0282-character-series-as-worldbuilding-slice.md`。
- **存档零增量、后端零影响**：两格都是模板字段，`schemaVersion` 的 bump 由 `PlayerEntitlement` 那一格产生 → `decisions/ADR-0270-player-entitlement-character-series.md`。
- `systems/character-profile/_index.md` 的校验表编号自此以 18 为最大值；`CharacterData.SeriesId` 悬空那条另落 `systems/services/plot-manager.md` 同批的悬空校验族。
