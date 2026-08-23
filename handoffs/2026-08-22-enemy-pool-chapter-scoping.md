# 敌人池的篇章框定载体 —— `EnemyData.ChapterScope`

- id: 2026-08-22-enemy-pool-chapter-scoping
- date: 2026-08-22
- topic: systems/enemies/_index.md · systems/enemies/common-properties.md · systems/services/future-event-service.md
- status: distilled
- distilled-to: systems/enemies/_index.md, systems/enemies/common-properties.md, systems/services/future-event-service.md, terminology.md

## Intent（distilled）

敌人取池的第三层「篇章框定」此前只是一句没有字段支撑的注释。本次给它一格：

**1. 载体 = `EnemyData` 上与 `EncounterScopes` 平级的顶层字段 `ChapterScope : int[]`**（取值 `1..3`，对位 `CharacterProfile.chapter`；**空 = 不限，三章通用**）。沿用 `PlotArcData.ChapterScope` 的字段名、类型与语义，一字不改。

选顶层字段而非塞进 `PoolScope`，三条理由任一条单独成立即封死另一选项：① `PoolScope == null` 是「通用池」的判据且它恒进池、`Matches` 不被调用——一个「三章通用但只在某章出现」的敌人会被迫把 `PoolScope` 改成非 `null`，通用池的定义被篇章这一维污染；② `PoolScope` 非 `null` 但两字段皆空是既定的 `PushWarning` 形状，而「只填篇章、不限地点与 arc」正是这个形状，一条正当写法会稳定触发告警；③ 通用池空池校验枚举的就是「`PoolScope == null` 的池在某组合下是否为空」，篇章若住在 `PoolScope` 里这句话自相矛盾。**篇章与池归属不是同一维度**：`PoolScope` 表达「在哪个空间 / 哪条剧情线」（横向切分），篇章表达「在修行的哪个阶段」（纵向进度门）。

**2. 取池第三层落成一行**，与前两层同形，全部叠在 `AllEnabled()` 之后：`e.ChapterScope.Length == 0 || e.ChapterScope.Contains(currentChapter)`。入参 `currentChapter` 是**单值 `int`**——与 `activeArcIds` 必须是集合形成对照（角色恒处于恰一个篇章，`Active` arc 可有多条），须写明否则实现会照抄 arc 那一层的集合形状。

**3. 空 = 不限，与 `EncounterScopes` 空 = `PushError` 的不对称是有意的，理由必须写进活文档**：空数组下 `Contains` 恒假 ⇒ `EncounterScopes` 漏填即死条目；`Length == 0 ||` 恒真 ⇒ `ChapterScope` 漏填只是范围偏宽。不写这条理由，日后必被当成漏写而「修正」。

**4. 通用池空池校验从单维扩到两维 `(combatTier × 篇章)`**（3 × 3 = 9 个组合，枚举面封闭且极小）。通用池的判据**保留既有口径**：`PoolScope == null` **或两字段皆空**，篇章维在其后以与门叠加。`Finale` 三格**放宽为「该 `(Finale, chapter)` 下的池（含专属条目）非空」**——天劫写成某条 arc 的专属条目是正当编排，按通用池口径枚举会误伤。

**5. 新增两条加载期校验**：越界值 → `PushError`（带 `Id` + 越界值）；重复值 → `PushWarning`，**只告警、取池不受影响**（重复值对 `Contains` 无影响，且校验绝不写回共享只读单例）。**不设「长度必须 < 3」**——显式写 `[1,2,3]` 是内容侧表达「我确认过」的正当方式。

**6. `EncounterScopes` 的类型订正（超出原草稿范围的顺手订正）。** `systems/enemies/*` 两处写的 `EncounterScopes : EventType[]`、取值 `{ Practice, Combat, Finale }` 与 `ADR-0002`（`eventType` 是五值、Practice / Standard / Finale 是 `combatTier` 三档）、`combat/_index.md`、`EncounterSpec.Tier` 全部相抵。就地订正为 **`EncounterScopes : CombatTier[]`，取值 `{ Practice, Standard, Finale }`**，九组合随之写成 `(combatTier × 篇章)`。不订正而把它固化进一张 3×3 校验表，会让 `EventType.Combat`（五值枚举成员）与「Standard 档」在同一份校验里指同一个东西。

**7. 为什么留这一格（承重取向）。** 赋级带使**任何敌人在任何篇章数值上都可用**，故 `ChapterScope` 切的不是强度而是**叙事归属**——炼气期的凡俗山贼以「金丹初期」赋级出现在第三篇章时图鉴会与实际遭遇当场对不上，而图鉴是敌人可读性的主通道。它把一条本来只能靠人工评审的内容纪律变成一格可机械过滤的框定。代价：内容侧多一格要填、多一条编排考量。

**8. 漏填的缓解手段是纯结构判定**：`ChapterScope` 为空的条目在 `content/enemy/` 类型档案的评审清单里逐条过一遍。**不按境界词做文案子串扫描**——图鉴五项词条是 `LocalizedText`，子串规则在非中文语言下全部失效、中文侧也会误命中。

**无存档迁移**：`ChapterScope` 是内容侧字段，存档只记 `EnemyId` / `EnemyInstance`，`EnemyInstance` 七字段中无篇章格。

## Clarifications（interview 产物）

- **事件侧 `AdventureEventData.ChapterScope` 由谁落笔** → 事件侧（含 Travel 豁免与 `(chapter, EventType)` 启动期断言）归 `generation-weighting` 一侧；本份**只写 `EnemyData` 侧**。这细化了草稿「事件侧的落笔见另一份草稿」那句的编排归属。
- **`EncounterScopes` 的取值域** → 就地订正为 `CombatTier[]` / `{ Practice, Standard, Finale }`。**推翻了草稿 §4 逐字照抄的 `{ Practice, Combat, Finale }`**，并把九组合的轴由 `EventType` 改为 `combatTier`。
- **通用池的判据** → **保留既有的「`PoolScope == null` 或两字段皆空」**。草稿 §4 的改写静默删掉了「或两字段皆空」这一支，属行文压缩而非有意裁决；空壳条目语义上确实等同通用池（这正是它只 `PushWarning` 的理由）。
- **Travel 兜底** → Travel 一类豁免 `ChapterScope`，由事件侧落笔，本份不写。
- **闸 ② 的池计数口径** → 在篇章过滤**之后**计数（既有纪律：闸 ② 的计数必须与实际抽取链同口径）；落在事件侧。
- **「重复值 → `PushWarning`，去重后继续」** → 措辞改为「**只告警、取池不受影响**」。「去重」若读作就地改写数组，即在加载期写回共享只读单例，与既有纪律相抵；且重复值对 `Contains` 的结果无任何影响，去重在功能上是空操作。
- **`Finale` 行的空池校验** → 放宽为「该 `(Finale, chapter)` 下的池（含专属条目）非空」，并写明与另两行口径不同的理由。草稿原写「通用池非空」会拦下把天劫写成 arc 专属条目这一正当编排。
- **境界词文案扫描** → 改为纯结构判定，落 `content/enemy/` 的评审清单，不做子串扫描。
- **`content/_index.md`** → 本次不改（`content/enemy/` 尚未开张，且 `content/` 硬边界禁止复述字段的取值域与校验语义）。

## Open questions

- **`ChapterScope` 与 `PlotArcData.ChapterScope` 同名是否会造成跨类型混淆** `[采纳推荐 — 待复核]`。已按推荐取同名（同名同义同类型，读者一次学会两处；备选 `ChapterScopes` 会与 `PlotArcData` 的单数形式分叉）。**这不是用户拍板，仍留在待答清单。**

## Notes / triage

- **`content/enemy/` 开张时**（`/scaffold-content-type enemy`），字段核对清单须含 `ChapterScope` 一行，**回链 `systems/enemies/common-properties.md`，不复述取值域与校验语义**。这是开张时的输入，不是回填。
- **越界发现（未处理）**：样本卡组规模在 `enemies/_index.md`（「规模逐条编排、不设硬限」）与 `enemies/common-properties.md`（「规模 15」）两处结论不同；`open-questions/01-combat.md` 另有在办条目。不在本次改动触及的小节，且改哪一侧是设计裁决。
