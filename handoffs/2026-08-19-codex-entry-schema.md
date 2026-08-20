# `CodexEntry` 字段 schema、六本图鉴的触发与词条深度

- id: 2026-08-19-codex-entry-schema
- date: 2026-08-19
- topic: systems/player-profile/codex/common-properties.md · systems/player-profile/codex/_index.md · systems/player-profile/codex/enemy-codex.md · systems/player-profile/_index.md · systems/services/profile-service.md · systems/services/sync-service.md · systems/services/content-service.md · systems/common-properties.md · terminology.md
- status: distilled
- distilled-to: systems/player-profile/codex/common-properties.md, systems/player-profile/codex/_index.md, systems/player-profile/codex/enemy-codex.md, systems/player-profile/_index.md, systems/services/profile-service.md, systems/services/sync-service.md, systems/services/content-service.md, systems/common-properties.md, terminology.md

## Intent（distilled）

图鉴族的**形状**早已定（六本、账号级、按 `Id` 索引、静态文案挂 `Resource`、存档只记解锁状态、一次遭遇全量解锁），但落地面整体悬空：`PlayerProfile` 15 字段表第 6–11 行的「写入通道」列是表内唯一的空洞；`CodexEntry` 的字段 schema 未定使本地缓存与上行 diff 写不出这一块；四本能力 / 道具类图鉴的触发语义与词条深度未定。本次一次性收口这三条，并连带答掉「敌人图鉴的慷慨度是否该上调」。

### 一、`CodexEntry` 首批就一格 `Id`

`public readonly record struct CodexEntry(string Id);` 不做任何改动；计数字段（遭遇 / 击败 / 败于其手 / 使用次数）与首次解锁元数据（篇章 / 境界 / 日期）两组候选**全部不落**。三条依据：

- **加法窗口已被 `CodexEntry` 这层包装本身买下了。** 不落裸 `IReadOnlyList<string>` 的理由正是「日后加一格是在 record 上加字段，老档补默认值、零迁移」；既然加一格零迁移，首批就没有理由预先加。
- **计数字段与它所在的层不兼容。** 六个 Codex 字段是**规则字段层**（图鉴完成度一旦驱动发放即成为发放输入），而「遭遇 / 击败 / 使用次数」是纯读数、本属统计计数层；塞进同一个 record = 两层混装，正是合并判据（语义 + 同步口径 + 篡改后果三者全同才允许合并）排除的形态。
- **首次解锁元数据三项各自被挡住：** 日期 → 客户端时钟不可信，`X-Server-Time` 是纯诊断、不校正本地时钟；境界 / 层级 → 词条正文绝不写等级，实例信息只在战斗内动态页眉出现；篇章 → 同一模板在多篇章出场，对玩家无信息量。

「你和他交手过多少次」这类读数的正确落点是 `PlayerStatistics` 的聚合项（宽松同步、零迁移、后端零配合）。**代价照录：逐条目计数不可得**，图鉴页只能显示「已解锁 / 未解锁」。

### 二、写入通道 = `ProfileChangeSpec` 新增一列 `CodexElements`

```csharp
public enum CodexKind { Enemy, CharacterPower, PlayerPower, CharacterItem, PlayerItem, Location }
public readonly record struct CodexUnlock(CodexKind Kind, string Id);
```

15 字段表第 6–11 行六格全部填 `CodexElements`。

- **element 带 `Kind` 而存档落六个具名字段不自相矛盾**：`AbilityChangeElement` 已是同形先例（element 带 `(Kind, Scope)` 做路由，持有条目落四个具名字段）。否决 `Dictionary<CodexKind, …>` 约束的是**存档形态**，不是 element 的路由键。
- **不复用 `(Kind, Scope)` 二元组**：它的值域恰好覆盖四本能力 / 道具图鉴，但 Enemy 与 Location 落在值域外，复用会逼出「二元组 + 两个特例」的畸形值域。
- **必须分列**：`Elements` 只装标量值、`AbilityElements` 的载荷带 `(Kind, Scope, Source, Op, PairKey)` 且改变持有、`StatusChanges` 的值是标量或 id——没有一列装得下 `(CodexKind, Id)` 且语义对得上。
- **零 `Op`**（图鉴只增不删）· **恒不经 modifier pipeline**（一条法则若能改写图鉴解锁，等于内容改写玩家的知识资产）· 采集与去重归 `CodexManager`，写入仍组装 `CodexElements` 经 `ProfileManager` 单点提交。
- **失败语义四行**：已存在 → 空操作不告警；同批重复 → 去重不告警；`Id` 解析不到 → `PushError` + 整批拒绝（与读档侧的 `PushWarning` + 保留相反，读写不对称同 `PlotElements` 先例）；出现在 `SelectCost` 内 → `PushError` + 整批拒绝。

### 三、六本的解锁触发

| 图鉴 | 触发 | 搭在哪一次已有提交上 |
|---|---|---|
| EnemyCodex | 遭遇（不必击败） | 战斗开始那一次 profile 提交 |
| LocationCodex | 抵达（`CurrentLocationId` 被置值那一刻，含轮回创建时的出生地） | Travel 结算那一次提交 / 轮回创建那一次提交 |
| CharacterPowerCodex · CharacterItemCodex · PlayerPowerCodex · PlayerItemCodex | 进入持有列表（含角色创建时的初始持有） | 同一次授予提交 / 轮回创建那一次提交 |

**四条依据：** ① 它是「遭遇即记，不必击败」在四本上的直接实例——内核是**接触即记，不要求你从中获益**；②「使用过即记」对 `PlayerPower` 根本无法定义（法则是 always-available 的带开关能力，没有离散的使用事件），六本无法用同一句话表述触发就等于回到六套并行的解锁逻辑；③「见到即记（含商店中见到）」把图鉴收集变成刷新按钮的副产物，且要求呈现层写存档；④ **零新增提交点**——六行全部搭在一次已经存在的提交上。

**配套护栏（纪律阶梯第 3 级）：** 一批变更中出现使某条能力进入持有列表的 element 而同批没有对应的 `CodexElements` 条目 → `#if DEBUG` 下 `PushWarning`。**不由 `ProfileManager` 自动派生**——那会让 `AppliedChange` 记的账与组装方提交的 spec 不一致。

### 四、词条深度：四本能力 / 道具类不套用敌人的五项规格

四本的词条 = 该内容条目自身已有的字段（名称 · 描述 · 立绘 · 稀有度）+ 一段**可选**的 `CodexFlavor: LocalizedText`（2–3 句 / 40–80 字，挂 `PowerData` / `ItemData` 顶层，一格覆盖四本）。

敌人词条昂贵（150–280 字 × 五项 + 过「无阿拉伯数字」审阅）**是因为它要在不给数值的前提下传达路数**，而该约束的存在理由是不侵蚀越级黑箱。能力 / 道具没有这条约束——玩家持有它们时效果与数值本就在储物袋 / 法则面板上完整可见。因此：

- **「不含阿拉伯数字」的口径纪律只适用于 EnemyCodex**，须在共有属性里明写边界，否则会被当成全族通则。
- **六本一律不分档解锁**（直接来自「解锁是一次性全量写入」）。
- `CodexFlavor` 挂内容 `Resource`，存档侧仍然只有 `Id`。

### 五、EnemyCodex 的慷慨度：维持 3 张关键卡

维持 3 张关键卡 + 五项文案，不给样本卡组完整列表。三条理由：完整列表把词条从事前知识推向事中情报（读牌堆），而「事前知识 vs 事中情报」是图鉴与战斗信息体系共存的前提；15 张卡名 + 说明必然突破一屏，逼出分页或分档解锁，而分档解锁已被否决；慷慨度上调有一个更便宜、可回退的旋钮——③「运作方式」与 ④「特点与弱点」的写作厚度。

**退让阶梯：** 写厚 ③④ → `KeyCardIds` 数量上界由 3 放宽到 5（下界 2 不动）→ 才考虑全表。**已知代价照录：** 首次面对陌生敌人的信息劣势维持现有水平，该水平尚未经实测检验。

### 六、序列化形态

六个顶层键（`enemyCodex` / `characterPowerCodex` / `playerPowerCodex` / `characterItemCodex` / `playerItemCodex` / `locationCodex`），camelCase 单点策略、集合字段名恒单数。

- **顶层键即整键替换 ⇒ 解锁一条 = 整本图鉴的 id 列表全量上行。**
- **体积口径：** 单条约 25–35 B，某本的上限约 `条目总数 × 30 B`，六本合计在内容规模成型后落在 20–40 KB 量级；它随账号年龄单调增长且永不收缩。
- **体积护栏（软上限告警）：** 任一本的条目数 > 该内容类型经 `AllIncludingDisabled()` 得到的总数 → `PushWarning` 带图鉴名与两个数值。它抓的是重复 / 悬空条目，正常账号永远达不到。
- **不做分页 / 冷热分离 / 独立存档段**；**不进透明路径白名单**（后端不复算图鉴、不据它发放）。
- 图鉴统计的分母走 `AllIncludingDisabled()`，否则线上关一条内容会让完成度百分比跳变。
- `CodexKind` 随 `AppliedChange` 落存档 ⇒ 成员名在第一批存档写下前冻结。
- schema：`CodexElements` 与 `CodexEntry` 并入既有那一次 bump，老档补默认值 = 空列表。

## Clarifications

- **可选 `LocalizedText` 字段的「缺失」定义** → 定为**字段本身为 `null`**（未挂子资源），语言强校验只对非 `null` 的 `LocalizedText` 执行；挂了却 `zh` 空串仍 `PushError`。这细化了原始输入「`CodexFlavor` 缺失 → 不渲染、不告警、内容侧可先全部留空」一句——按语言校验表的字面口径，一条留空风味文案的 `PowerData` 会在启动期抛异常，整包起不来。否决了「引入必填 / 可选字段分类清单」（那是要读上下文才能判的形态）与「`CodexFlavor` 改必填」（与可选的定案直接相抵）。
- **初始持有是否进图鉴** → **进**。触发口径扩为「凡进入持有列表 / 凡 `CurrentLocationId` 被置值即记」，覆盖角色创建时自带的绑定神通与出生地。这推翻了原始输入把四本触发一律锁死在 `AbilityChangeElement.Op == Grant` 的措辞——按那种写法，玩家一直带着的神通与出生所在的地域在图鉴里是空的，而内核是「接触即记」、LocationCodex 明写「去过即记」。若创建路径本就走一次提交，仍是零新增提交点。
- **EnemyCodex 搭车的那次提交如何表述** → 写作「随**战斗开始那一次 profile 提交**」，**不点名承载它的那一列**。原始输入的触发表点名了 `activeCombat` 初始化那一次提交；该字段的列面归 profile-service 自己收口，在图鉴文档里点名它等于把别处的结论抄一份，制造第二权威。
- **四项取向照原始输入定稿**：严格「获得即记」（商店见到不记）· 首批零计数字段（聚合项作为将来的加法方向）· EnemyCodex 维持 3 张关键卡 · `CodexFlavor` 做且可选。
- **前置依赖「图鉴是否与成就 / 奖励挂钩」→ 答定：不挂钩。** 序列化那一节因此不再是悬的：六个键不进透明路径白名单、后端零配合。
- **原始输入两处措辞需收紧**：① 「关键卡显式列 3 张」与加载校验「数量 > 3 或 < 2 → `PushError`」并存，退让阶梯只放宽上界、下界 2 不动；② 「第八列」这类序数不进活文档——`ProfileChangeSpec` 的列表数不写进承重表述。
- **两处顺手修**：`enemy-codex.md`「首遇即全知」的三条论据之一引用了已不存在的意图机制，删该分句后另两条独立成立；`terminology.md` 的图鉴族词条写「共五个」，与同文件「地域图鉴 = 图鉴族第六本」自相矛盾。

## Open questions

- **「记连边」的显影粒度**：去过 A 之后，词条列出 A 的全部邻接（含从未去过的 B），还是只记已实际走过的边？它只影响 LocationCodex 的呈现与 location 条目的连边字段，不影响 `CodexEntry` schema。
- **LocationCodex 的其余词条深度**：除连边外还写什么（风物文案？事件类型倾向？敌人清单？）。
- **图鉴的入口与浏览形态**：六本在主菜单如何组织、战斗内能否查阅（EnemyCodex 尤其相关）。
- **EnemyCodex 慷慨度的实测检验**：退让阶梯给出了出路，但触发它需要真实的游玩数据。
