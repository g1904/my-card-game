# 角色（`CharacterData`）—— 类型档案

- type: character
- code-type: `CharacterData`
- class-authority:
    - systems/character-profile/_index.md
    - systems/common-properties.md
- opened: 2026-09-12
- id-form: `character.<snake_case_slug>`
- readiness: 🟠 部分阻塞

> **本档案不定义字段。** 下表只列**字段名 + 该条目需要作答什么 + 权威回链**；类型、取值域、枚举成员、校验语义一律在回链那侧，此处不复述（越界判据见 `../_index.md`「硬边界」）。

Source: `handoffs/2026-09-12-premium-character-series-unlock.md` · `handoffs/2026-09-12-series-packaging-and-narrative.md`

## 字段核对清单

> `/author-content` 逐行核对：条目文档里这一行有没有被作答。**缺一行即不能翻 `ready`。**

| 字段 | 必填 | 这个条目需要作答什么 | 权威回链 |
|---|:--:|---|---|
| `Id` | ✅ | 稳定唯一标识符，形态见上方 `id-form` | `systems/common-properties.md`「稳定 Id 键」 |
| `ContentEnabled` | ✅ | 是否随本次放量开启 | `systems/common-properties.md`「`ContentEnabled`」 |
| `Artwork` | ✅ | 该角色的基础形象（全部境界的回落底） | `systems/character-profile/_index.md` |
| `RealmArtworks` | — | 哪几档境界要换图（稀疏覆写；留空 = 全程用基础图） | 同上 |
| `PowerId` | ✅ | 绑定的那一个神通 | 同上 · `content/character-power/` |
| `TechniqueIds` | ✅ | 两门绑定功法 | 同上 · `content/cultivation-technique/` |
| `Affinities` | ✅ | 该角色的先天灵根 | `systems/character-profile/_index.md`「灵根」 |
| `DefeatLines` | ✅ | 三因各一句的第一人称终结台词 | 同上「角色终结台词」 |
| `SeriesId` | ✅ | 该角色属哪个角色系列（`character_series.<snake_case_slug>`） | 同上「角色模板池的形态」 |
| `Track` | ✅ | 免费还是付费轨道；**同系列必须一致** | 同上「角色轨道 `CharacterTrack`」 |

## 条目形状与写作要点

- **角色条目不能脱离系列单写。** 系列是最小编排单位（5 或 10 个、全免费或全付费），写一个角色就要同批把它整个系列的兄弟条目与下方系列台账那一行一起写出来——否则同系列条目数与轨道一致这两条加载期校验必然先失败。
- **一句动词级玩法概括 + 起始功法名**是选择屏的简介来源，必须写实；**不写「推荐」「更强」一类措辞**（首批五角刻意压平在同一复杂度档）。
- **神通与两门绑定功法必须已有条目**，否则引用悬空 ⇒ 加载期 `PushError`。

## 交叉引用

| 本类型的字段 | 指向的类型 | 悬空的后果 |
|---|---|---|
| `PowerId` | `content/character-power/` | 加载期 `PushError` + 抛，该角色开不了局 |
| `TechniqueIds` | `content/cultivation-technique/` | 同上 |
| `SeriesId` | `content/character-series/` | 加载期 `PushError` + 双方 `Id`；另在下方系列台账登记一行（台账是棘轮核对的基线，缺行 ⇒ `/audit-content` 提示补登） |

## 系列台账

> 一个角色系列一行。它是 `/audit-content` **轨道棘轮核对项的基线** —— `/audit-content` 对的是当前库、没有历史，基线只能由本表承载。**系列首次发版后本表那一行不得改写 `track`**。

| `seriesId` | `track` | 五行构成 | 首次发版的 `appVersion` |
|---|---|---|---|
| _(暂无)_ | | | |

- **`track` 发布后完全不可变（双向棘轮）。** 语义与代价的权威在 `systems/character-profile/_index.md`「角色模板池的形态」。
- **首批付费系列的 `seriesId` 取值、系列名与五行构成尚未定稿**，故本表当前为空。次序与构成已定（第一个付费系列 = 单灵根五角进阶批），欠的是**取哪个世界观实体**——需先有 `narrative/` 的世界观底稿。系列的名与概述由 `content/character-series/` 的条目承载（本表只记 `seriesId` / `track` / 构成 / 首发版本，不复述名与概述）。

### `/audit-content` 新增核对项（两条）

| 核对项 | 对账方式 | 判定 |
|---|---|---|
| **轨道棘轮（双向）** | 本表登记的 `track` ↔ 该系列各 `.tres` 的 `Track` | `Free → Paid` ⇒ 🔴 违规，报错 · `Paid → Free` ⇒ 🔴 违规，报错 · 本表缺该 `seriesId` ⇒ 提示补登（新系列） |
| **五行对称** | 同一 `seriesId` 下各条目的 `Affinities` 构成 | 5 人系列五行各一 / 10 人系列双灵根各一种组合 —— **只报告不阻断**（未来 10 人系列未必按 C(5,2) 铺） |

**两条都不做运行时机制**，只活在 `/audit-content` 与发版清单里，一行代码不进客户端。与它们相邻的那批会打崩启动的机械校验（同系列轨道一致、同系列条目数 ∈ {5, 10}、付费角色禁止永久退役）落在加载期，清单见 `systems/character-profile/_index.md`。

## 就绪度与阻塞

- **当前 readiness：** 🟠 —— 字段表已成文（含 `SeriesId` / `Track` 两格），仍阻于上游的功法与神通条目。
- **阻塞项：** `content/cultivation-technique/`（本身阻于 `content/card/`）· `content/character-power/` · `content/character-series/`（`SeriesId` 的引用目标，须先开张）；付费系列的具体取值另需 `narrative/` 的世界观底稿。

## 条目台账

> 最新的置顶。每个条目一行。**内容不进 `requirements/_index.md`，完成度只在这里追踪。**

| id | 标题 | status | blueprint | 备注 |
|---|---|---|---|---|
| _(暂无)_ | | | | |

## Open questions

- **首批付费系列的 `seriesId` 具体 slug、系列名与五行构成。** 结构与次序已定，取值待 `narrative/` 的世界观底稿。→ `narrative/_index.md` · `systems/character-profile/_index.md` · `systems/monetization.md`。
