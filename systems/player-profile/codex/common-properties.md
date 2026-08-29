# codex — 共有属性

> 七个图鉴的条目共有字段与解锁语义。族总览见 `_index.md`；敌人图鉴的具体词条见 `enemy-codex.md`，功法图鉴见 `technique-codex.md`——这两本另有各自的专属规则，其余各本只用本文档。

## 已定的约束

- **条目按对象的稳定 `Id` 索引。** 图鉴条目以对应内容条目（`EnemyData` / `PlayerPowerData` / `ItemData` …）的 `Id` 为键——与全库「稳定 `Id` 是一切引用的键」一致（见 `systems/common-properties.md`）。绝不用显示名或索引作键。
- **只记录静态知识。** 条目承载「这个东西是什么、会做哪些事」，**不承载任何运行态**（本回合意图、当前道念、场上状态）——那些属于 `combat-service` 的战斗内状态，战斗结束即消失。分层论证见 `_index.md`。
- **展示文案不进图鉴条目。** 显示名 / 描述 / 立绘 / 词条正文留在对应的 `Resource` 上；图鉴的**存档条目只带 `Id`**，呈现时由 ViewModel 组装。这是全库「运行时 / 存档态只带 `Id` + 可变状态」的直接应用。**推论：图鉴的存档负担接近一个 id 集合**，文案改版不触发存档迁移，也不撑大增量 push。
- **写入经 `profile-service.ProfileManager`。** 解锁是 `ProfileChangeSpec` 的变更目标，不绕过唯一写入面。
- **解锁是一次性的全量写入（由 EnemyCodex 确立）。** 触发一次即解锁该条目的**全部词条文案**——**逐项 / 逐招式解锁已否决**。因此解锁状态**只需表达「已解锁」这一态**；「已击败」「使用过 N 次」之类若需要，是额外的计数字段，**不是解锁前提**。
- **触发的共同内核 = 接触即记，不要求你从中获益。** EnemyCodex 是遭遇（不必击败），LocationCodex 是去过，四本能力 / 道具类是进入持有列表，TechniqueCodex 是习得或在敌人身上见过——失败的战斗、拿到还没用上就死掉的法宝，同样留下知识。逐本触发见下。

Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`

## `CodexEntry` 的字段面

```csharp
public readonly record struct CodexEntry(string Id);
```

| # | 字段 | 类型 | 层 | 默认值 | 写入通道 | 权威 |
|---|---|---|---|---|---|---|
| 1 | `Id` | `string` | 规则 | —（构造必填，无默认） | `CodexElements` | 本文档 |

**表只有一行是结论，不是遗漏。** 计数字段（遭遇 / 击败 / 败于其手 / 使用次数）与首次解锁元数据（篇章 / 境界 / 日期）两组候选**全部不落**，三条依据：

- **加法窗口已被 `CodexEntry` 这层包装本身买下了。** 不落裸 `IReadOnlyList<string>` 的理由正是「日后加一格是在 record 上加字段，老档补默认值、零迁移」（见 `../_index.md`）；既然加一格是零迁移的，首批就没有理由预先加。
- **计数字段与它所在的层不兼容（承重）。** 全部 Codex 字段属**规则字段层**——图鉴完成度一旦驱动发放即成为发放的输入；而「遭遇 / 击败 / 败于其手 / 使用次数」是纯读数，本属统计计数层。塞进同一个 record = 把两层混装，正是合并判据（语义 + 同步口径 + 篡改后果三者全同才允许合并）排除的形态。
- **首次解锁元数据三项各自被挡住：** **日期** —— 客户端时钟不可信，`X-Server-Time` 是纯诊断、不参与玩法判断也不校正本地时钟，由它写出的存档字段没有可依赖的语义；**境界 / 层级** —— 词条正文绝不写等级，实例信息只在战斗内动态页眉出现（见 `enemy-codex.md`），固化进账号级存档就是把实例信息写进静态知识面；**篇章** —— 同一模板在多篇章出场，对玩家无信息量。

**连锁解锁不加字段。** 一次敌人收录展开出的 1 + N 条，条目形态与任何一条单独的收录完全相同——同一个 `CodexEntry(string Id)`、同一条写入通道、同一套读档校验。展开规则见下。

**「你和他交手过多少次」这类读数的正确落点是 `PlayerStatistics` 的聚合项**（宽松同步、零迁移、后端零配合），不是每条 `CodexEntry` 上的计数器。**代价明写：逐条目的计数因此不可得**，图鉴页面不能显示「遭遇 7 次 / 败于其手 2 次」，只能显示「已解锁 / 未解锁」。

## 七本的解锁触发

**七本共用同一条写入通道 `ProfileChangeSpec.CodexElements`**（元素 `CodexUnlock(CodexKind Kind, string Id)`，零 `Op`、恒不经 modifier pipeline；语义与失败处置见 `systems/services/profile-service.md`）。

| 图鉴 | 触发 | 组装方 | 搭在哪一次已有提交上 |
|---|---|---|---|
| **EnemyCodex** | 遭遇（不必击败；战败与中途终局同样入账） | `CodexManager` | 该战斗事件 `eventEnd` 的那一次提交 |
| **LocationCodex** | 抵达（`CurrentLocationId` 被置值那一刻） | life-cycle-service | Travel 结算那一次提交；出生地随轮回创建那一次提交 |
| **CharacterPowerCodex** | 该神通进入角色的持有列表 | 结算侧组装方 | 同一次授予提交；自带的绑定神通随轮回创建那一次提交 |
| **CharacterItemCodex** | 该法宝进入角色的持有列表 | 同上 | 同上 |
| **PlayerPowerCodex** | 该法则进入账号的持有列表 | 同上 | 同上 |
| **PlayerItemCodex** | 该古宝进入账号的持有列表 | 同上 | 同上 |
| **TechniqueCodex** | 该功法进入角色的卡组（习得 / 商店购入）**∪** 所遭遇敌人套牌所含的功法 | 结算侧组装方 · `CodexManager` | 该次 `LearnTechnique` 提交；连锁那一路随该战斗事件 `eventEnd` |

- **「战斗事件的 `eventEnd`」这一时点只约束 EnemyCodex 与 TechniqueCodex，其余五行按本表各自的时点（承重）。** 让全族统一到 `eventEnd` 要为三处开例外：**出生地**与**角色自带的绑定神通**落在「轮回创建」那一次提交上，而那不是任何事件的 `eventEnd`；**Exchange 的购买**是逐笔即时提交、明令不攒到收口。一张可机械核对的触发表会因此变成三条例外规则，而收益为零——这两本之外，收录时点早一点晚一点对玩家不可观测。
- **这两本推迟到收口，是「本场遭遇不当场解锁」这条体验取向的落点。** 战斗中本就查不到图鉴（见 `_index.md`），若解锁仍写在战斗开始那一刻，则玩家要到战斗结束后才第一次能读它——时点提前没有任何可见收益，却使**下一次进场前才读到它**这件事失去干净的因果：**上一次遭遇换来的知识，在下一次进场前兑现**。

- **口径是「进入持有列表 / 被置值」，不是「经某一种 element 授予」（承重）。** **初始持有一并入图鉴**——角色自带的绑定神通、轮回的出生地都是玩家实实在在接触过的东西；把触发锁死在授予 element 上，会让玩家一直带着的神通与出生所在的地域在图鉴里是空的，而「去过即记」明写在 LocationCodex 上。
- **商店里见到但没买的不记（严格「获得即记」）。** 橱窗里看一眼不构成接触；更重的理由是 Exchange 库存可花灵石刷新，「见到即记」会把一个收集面挂到一个可用货币无限重试的按钮上，刷新按钮成为最高效的图鉴填充手段。它还要求**呈现层写存档**，新开一个此前不存在的写入点。
- **不取「使用过即记」。** 它对 `PlayerPower` 根本无法定义——法则是 always-available 的带开关能力，没有「使用」这个离散事件；七本无法用同一句话表述触发，就等于回到七套并行的解锁逻辑，正是「为何是一族而不是一个」要避免的形态。它还与「失败侧也应有产出」相抵：拿到了没来得及用就死掉，什么都不留下。
- **零新增提交点，这是最强的工程依据。** 上表七行全部搭在一次**已经存在**的提交上——不新增存档点、不新增 push、不新增决策点。任何其他触发口径都至少要新开一个提交点。
  - `eventEnd` 那一路落在收口五步组装的**「重算依据」列**里（与 `DeckElements` / `PlotElements` 同批），不是收口之后追加的列——图鉴解锁不参与新一批 eventOption 的重算，但新增列一律按默认落在投影之前。列的组装顺序与闭合性条件见 `systems/services/life-cycle-service.md`。
  - **战败路径同样落账**：角色在本场终结时，收口那一次 `TryApply` 已经提交成功，终结清理发生在其后。「死亡至少换来知识」因此不需要为失败侧另开分支。
- **可执行护栏（纪律阶梯第 3 级）：** 一批变更中出现使某条能力进入持有列表的 element，而同批没有对应的 `CodexElements` 条目 → `#if DEBUG` 下 `PushWarning`。**不由 `ProfileManager` 自动派生**——那会让 `AppliedChange` 记的账与组装方提交的 spec 不一致。

## 连锁解锁：一次敌人收录展开为 1 + N 条

**收录一个敌人时，同时收录他套牌里的每一门功法。** 敌人的构筑面就是**功法引用列表**（`TechniqueRef[]`，见 `systems/enemies/`），所以「见过这个敌人」与「见过这几门功法」在玩家那一侧是同一次接触，不该被拆成两次收集。

- **展开依据 = 该敌人的功法引用列表本身。** 层数不入图鉴（词条不表达层数），**游离散牌不属任何功法，不展开出任何条目**——「敌人卡组 = 玩家可习得内容」原有的那一小块散牌例外，在知识面上原样承接，不新增例外。
- **组装方是 `CodexManager`**：触发采集与同批去重归它，写入仍组装 `CodexElements` 经 `ProfileManager` 单点提交。**不由 `ProfileManager` 自动派生**——自动派生会让 `AppliedChange` 记的账与组装方提交的 spec 不一致。
- **机制上零新增。** `CodexElements` 的语义是按 `(Kind, Id)` 的幂等收录、零 `Op`、重复收录是幂等空操作，故一次收录展开为 1 条 `(Enemy, enemyId)` + N 条 `(Technique, techniqueId)` 完全合法；「玩家已习得该功法，本场又遭遇用同门功法的敌人」天然是空操作，不需要另写去重规则。
- **玩家自己习得的那一路**沿用「进入持有列表」的通用口径，搭在 `DeckElements` 的 `LearnTechnique` 那次提交上。
- **它兑现的是敌我同源这条承诺：** 敌我共用同一套功法条目，**你在敌人身上见过的路数，就是你有机会习得的那一门**。若遭遇只解锁敌人本身、功法要另行习得才记，这条承诺在知识面上就只兑现一半。

## 词条深度：五本能力 / 道具 / 功法类不套用敌人的五项规格

**五本的词条 = 该内容条目自身已有的字段 + 一段可选的图鉴专属风味文案**，不新增结构化的多项写作规格。

| 词条构成 | 来源字段 | 是否新增 |
|---|---|---|
| 名称 · 描述 | `PowerData` / `ItemData` / `CultivationTechniqueData` 的显示名 / 描述（`LocalizedText`） | 不新增 |
| 立绘 | **`Artwork : Texture2D`**（共有字段，见 `systems/common-properties.md`），**仅 `PowerData` / `ItemData` 两类**——功法没有独立的视觉资产 | 不新增结构 |
| 稀有度 | `Rarity: RarityTier` | 不新增 |
| 风味 / 出处传说 | **`CodexFlavor: LocalizedText`**，可选，2–3 句 / 40–80 字；字段为 `null` 即不渲染该段、不告警 | 新增一格 |

- **为什么不照抄敌人的五项规格（承重）。** 敌人词条昂贵（150–280 字 × 五项 + 过「无阿拉伯数字」的审阅）**是因为它要在不给数值的前提下传达路数**，而那条约束的存在理由是不侵蚀越级黑箱。**能力 / 道具 / 功法没有这条约束**——玩家持有它们时，效果与数值本就在储物袋 / 法则面板 / 构筑界面上完整可见。把一条对敌人成立的遮蔽纪律套到自己的东西上，是把内容成本抬高一个量级却换不来任何信息。
- **推论：「词条正文不含阿拉伯数字」这条口径纪律的适用范围只及 EnemyCodex**，不是全族通则。整族通用的是**「给静态知识，不给动态情报」**——两者不是同一条。不明写这条边界，后来者会把这五本词条也做成结构化文案。
- **`CodexFlavor` 挂在 `PowerData` / `ItemData` / `CultivationTechniqueData` 的顶层**，一格覆盖这五本（`Player*` 与 `Character*` 共用同一内容类）。挂载面与可选字段的校验口径见 `systems/common-properties.md`；功法侧的字段登记见 `systems/character-profile/deck/_index.md`。**与「展示文案不进图鉴条目」完全一致**：存档侧仍然只有 `Id`。
- **七本一律不分档解锁**，直接来自「解锁是一次性的全量写入」。这五本的词条本就短，分档在它们身上尤其没有意义。
- **LocationCodex 只共用上述通用部分**：同一个 `CodexEntry(string Id)`、同一条写入通道、同一套读档校验；其余词条深度仍待答，见 `_index.md`。
  - **连边不是存档态。** `locationCodex` 的每条 `CodexEntry` 只对应**一个去过的地域**（`Id == LocationData.Id`），连边由呈现层从 `LocationMapData` 现算——存档 / 写入通道 / 校验 / schema 版本一格不动，无迁移面、后端零配合。派生式与显影口径见 `_index.md`。
  - **因此本文档的四条既有约束对它逐条成立**：`Id` 是可经 `ContentRegistry` 解析的稳定 `Id`（不用复合键）· 触发是抵达、搭在已有提交上（零新增提交点）· 条目数恒 ≤ location 条目总数，体积护栏与完成度分母口径不破 · `CodexEntry` 不加格，各本形状仍然相同。
- **TechniqueCodex 同样只共用上述通用部分**：词条 = 功法名 / 描述 / `Rarity` + 可选 `CodexFlavor`，**不含立绘、不列该功法的卡牌清单**；理由与两条解锁路径见 `technique-codex.md`。功法侧无视觉资产这一点在上表的「立绘」一行与 `art/visuals/_index.md` 的资产类目表上同样成立。

Source: `handoffs/2026-08-19-codex-entry-schema.md` · `handoffs/2026-08-22-locationcodex-edge-granularity.md` · `handoffs/2026-08-25-info-economy-and-codex-expansion.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md`

## 对应
提炼至：`.claude/knowledge/systems/player-profile/codex/common-properties.md`（待建）。
