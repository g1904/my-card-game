# ADR-0110 — 敌人池的篇章框定 = `EnemyData.ChapterScope` 顶层字段，切叙事归属而非强度

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-enemy-pool-chapter-scoping.md

## 背景

敌人取池的第三层「篇章框定」此前只是一句没有字段支撑的注释。同时，赋级带（`ADR-0044`）使**任何敌人在任何篇章数值上都可用**——若不给篇章一格，炼气期的凡俗山贼会以「金丹初期」赋级出现在第三篇章，图鉴与实际遭遇当场对不上，而图鉴是敌人可读性的主通道。

## 决策

载体 = `EnemyData` 上与 `EncounterScopes` 平级的**顶层字段 `ChapterScope : int[]`**（取值 `1..3`，对位 `CharacterProfile.chapter`；**空 = 不限，三章通用**），沿用 `PlotArcData.ChapterScope` 的字段名、类型与语义。

取池第三层与前两层同形、全部叠在 `AllEnabled()` 之后，入参 `currentChapter` 是**单值**（角色恒处于恰一个篇章，与 `activeArcIds` 必须是集合形成对照）。

通用池空池校验由单维扩到 `(combatTier × 篇章)` 九组合；`Finale` 三格放宽为「含专属条目非空」。新增两条加载期校验：越界值 `PushError`、重复值 `PushWarning`（只告警、取池不受影响）。

字段表、伪码、校验清单与「空 = 不限」的不对称理由 → `systems/enemies/_index.md`、`systems/enemies/common-properties.md`。

## 理由

**它切的不是强度而是叙事归属**——强度那一维已由赋级带承担。它把一条本来只能靠人工评审的内容纪律变成一格可机械过滤的框定。

选顶层字段而非塞进 `PoolScope`，三条理由任一条单独成立即封死另一选项：`PoolScope == null` 是「通用池」的判据且它恒进池，一个「三章通用但只在某章出现」的敌人会被迫把 `PoolScope` 改成非 `null`，通用池的定义被篇章这一维污染；`PoolScope` 非 `null` 但两字段皆空是既定的 `PushWarning` 形状，而「只填篇章、不限地点与 arc」正是这个形状，一条正当写法会稳定触发告警；通用池空池校验枚举的就是「`PoolScope == null` 的池在某组合下是否为空」，篇章若住在 `PoolScope` 里这句话自相矛盾。

**篇章与池归属不是同一维度**：`PoolScope` 表达「在哪个空间 / 哪条剧情线」（横向切分），篇章表达「在修行的哪个阶段」（纵向进度门）。

「空 = 不限」与 `EncounterScopes`「空 = `PushError`」的不对称是有意的：空数组下 `Contains` 恒假 ⇒ `EncounterScopes` 漏填即死条目；`Length == 0 ||` 恒真 ⇒ `ChapterScope` 漏填只是范围偏宽。

## 备选方案

- **塞进 `PoolScope`** — 否决：三条理由见上，任一条单独成立。
- **设「`ChapterScope` 长度必须 < 3」校验** — 否决：显式写 `[1,2,3]` 与留空语义相同，而显式写是内容侧表达「我确认过三章都出」的正当方式。
- **重复值去重后继续** — 否决：去重若读作就地改写数组，即在加载期写回共享只读单例；且重复值对 `Contains` 的结果无任何影响，去重在功能上是空操作。
- **靠境界词做文案子串扫描来发现漏填** — 否决：图鉴词条是 `LocalizedText`，子串规则在非中文语言下全部失效、中文侧也会误命中。漏填的缓解改为纯结构判定，落 `content/enemy/` 的评审清单。

## 后果

- `systems/enemies/_index.md` 与 `systems/enemies/common-properties.md` 是权威；`systems/services/future-event-service.md` 的取池链与之对位。
- `EncounterScopes` 的类型随本次订正为 `CombatTier[]`、取值 `{ Practice, Standard, Finale }`，与 `ADR-0002` 对齐；九组合的轴因此是 `combatTier` 而非 `EventType`。
- 事件侧的 `AdventureEventData.ChapterScope`（含 Travel 豁免与启动期断言）归 `ADR-0026`，不在本条范围。
- **无存档迁移**：`ChapterScope` 是内容侧字段，`EnemyInstance` 七字段中无篇章格。
- `content/enemy/` 开张时字段核对清单须含 `ChapterScope` 一行，**回链而不复述**取值域与校验语义。
