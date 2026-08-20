---
type: solution-draft
date: 2026-08-18
question: `CodexEntry` 的字段 schema、六本图鉴的解锁触发与词条深度、以及六处写入通道与序列化形态。
source: open-questions/07-codex-monetization.md → 「其余四个图鉴的解锁触发与词条深度」 · open-questions/01-combat.md → 「敌人图鉴的慷慨度是否该上调（承重）」 · open-questions.md「derive 就绪度」表中 `systems/player-profile/_index.md` / `systems/services/sync-service.md` / `codex/` 三行
targets: systems/player-profile/codex/common-properties.md · systems/player-profile/codex/_index.md · systems/player-profile/codex/enemy-codex.md · systems/player-profile/_index.md（15 字段表第 6–11 行的写入通道列）· systems/services/profile-service.md（`ProfileChangeSpec` 增列）· systems/services/sync-service.md（存档 schema bump 清单）
status: distilled
reviewed: 2026-08-19 — 用户逐条裁决完毕（取向零剩余）；批量提炼时的合并 interview 另有 48 项裁决，全部取推荐项
distilled-to: handoffs/2026-08-19-codex-entry-schema.md
---

# 方案 — `CodexEntry` 字段 schema 与六本图鉴的触发 / 词条深度

## 问题

图鉴族的**形状**早已定案（六本、账号级、按 `Id` 索引、静态文案挂 `Resource`、存档只记解锁状态、一次遭遇全量解锁），但**落地面整体悬空**，并且这一处悬空同时卡住三条链：

1. **`systems/player-profile/_index.md` 的 15 字段表第 6–11 行**（六个 Codex 字段）的「写入通道」列全部是 `⟨待定⟩`——该表其余 9 行已逐格定案，六个 `⟨待定⟩` 是表内唯一的空洞。
2. **`systems/services/sync-service.md`**：`CodexEntry` schema 未定 ⇒ 本地缓存与上行 diff 写不出这一块的具体类型与体积口径。
3. **`codex/common-properties.md` 的「待定的字段清单」整节**：计数字段、首次解锁元数据、四本能力 / 道具类图鉴的触发语义与词条深度。

另有一条来自 `01-combat.md` 的承重项与它同源：**意图机制整条移除后，敌人图鉴成为事前知识的唯一主通道**，那么「一次遭遇解锁三张关键卡」这个慷慨度是否还够。它与「其余四本的词条深度」是同一个问题的两面，故一并处理。

## 约束（来自既有设计）

以下是本方案不得违反的硬边界，逐条带来源：

- **条目存在 ⟺ 已解锁，不需要 `IsUnlocked` 布尔**；解锁是一次性全量写入，逐项 / 逐招式解锁**已否决**。→ `codex/common-properties.md`、`codex/_index.md`
- **`public readonly record struct CodexEntry(string Id);`**（首批只有解锁这一态）；六个 Codex 落**六个具名字段**，不落 `Dictionary<CodexKind, …>`、不落单表 + `Kind` 字段。→ `player-profile/_index.md`
- **展示文案不进图鉴条目**；显示名 / 描述 / 立绘 / 词条正文留在对应 `Resource` 上，呈现时由 ViewModel 组装。→ `codex/common-properties.md`
- **写入经 `profile-service.ProfileManager` 单点提交**，不绕过唯一写入面；`ProfileChangeSpec` 全有或全无。→ `codex/common-properties.md`、`systems/services/profile-service.md`
- **读档校验已定**：`Id` 经 `ContentRegistry` 解析不到 → **可选缺失** → `PushWarning` + **保留条目**（图鉴是历史知识，一条读不出的旧条目不该阻断登录）。→ `player-profile/_index.md`
- **`LocationCodex` 的连边不落存档**（连边随 location 内容条目静态给出）。→ `player-profile/_index.md`
- **EnemyCodex 已定案的四项**：触发 = 遭遇（不必击败）· 五项文案 · 关键卡 `EnemyData.KeyCardIds` 显式列 3 张 · 词条正文不含阿拉伯数字。→ `codex/enemy-codex.md`
- **账号级字段分两层，判据是「它有没有被规则读」**；统计计数层**绝不可被任何规则读取**，且**后端不得用统计数据驱动任何发放**。→ `player-profile/_index.md`、`sync-service.md`「宽松具体宽在哪五处」第 5 条
- **`PlayerProfileDiff` 中出现的顶层键即整键替换、不表达删除**；键值以下对后端完全不透明。→ `sync-service.md`「透明路径的稳定性纪律」
- **集合字段名恒为单数**；C# 字段名经 camelCase 单点策略机械映射为 JSON path。→ `player-profile/_index.md`、`sync-service.md`
- **枚举值序列化与 C# 枚举名逐字相同 ⇒ 重命名一个落存档的枚举值即破坏性变更。** → `sync-service.md`

## 建议方案

### 1. `CodexEntry` 首批就一格 `Id`，不加计数、不加首次解锁元数据

`[既有推演]`

**建议：本方案对已写下的 `public readonly record struct CodexEntry(string Id);` 不做任何改动**，并把「为什么就一格」正式写进 `common-properties.md`，替换掉那节「待定的字段清单」。

三条依据，逐条对上既有纪律：

- **加法窗口已被 `CodexEntry` 这层包装本身买下了。** `player-profile/_index.md` 明写：不落裸 `IReadOnlyList<string>` 的理由是「日后加一格是在 record 上加字段（老档补默认值、零迁移）」。**既然加一格是零迁移的，首批就没有任何理由预先加。** 这与 `PlayerStatistics`「首批就这两项……故首批清单的价值在于**小而无歧义**」逐字同构。
- **计数字段与它所在的层不兼容（承重）。** 15 字段表把六个 Codex 字段标为**规则字段层**——这不是笔误：`achievement/` 那条「收集完成度是否发放奖励」一旦答「是」，图鉴完成度就成为**发放的输入**，而 `sync-service.md` 第 5 条明写「一旦用它驱动发放，它就变成了规则字段，必须整体升层」。而「遭遇 / 击败 / 败于其手 / 使用次数」是纯读数，本属统计计数层。把它们塞进 `CodexEntry` = **把两层混装进同一个 record**，正是「合并判据」（语义 + 同步口径 + 篡改后果三者全同才允许合并）明确排除的形态。
- **首次解锁元数据三项各自被既有决策挡住：**
  - **日期** → 客户端时钟不可信；`X-Server-Time` 已明写为「**纯诊断**，不参与玩法判断，**也不用于校正本地时钟**」。一个由不可信时钟写出的存档字段没有任何可依赖的语义。
  - **境界 / 层级** → `enemy-codex.md` 明写「**词条正文绝不写等级**……实例信息只在**战斗内动态页眉**出现，元进程界面查阅时不显示」。把首次遭遇的境界固化进账号级存档，正是把实例信息写进静态知识面。
  - **篇章** → 同上一条的弱化版，且它对玩家无信息量（同一敌人模板在多篇章出场）。

**若日后确需「你和他交手过多少次」这类读数**，正确落点是 `PlayerStatistics` 的聚合项（如 `TotalEnemiesEncountered`，宽松同步、零迁移、后端零配合），**不是每条 `CodexEntry` 上的计数器**。代价明写：**逐条目的计数因此不可得**，图鉴页面不能显示「遭遇 7 次 / 败于其手 2 次」。这是本方案有意接受的取舍，见 `## 用户裁决（2026-08-19 · 全部定案）` 第 2 项。

### 2. 写入通道 = `ProfileChangeSpec` 新增第八列 `CodexElements`

`[既有推演]`

15 字段表第 6–11 行的六个 `⟨待定⟩` **全部填同一个值：`CodexElements`**。

```csharp
public enum CodexKind { Enemy, CharacterPower, PlayerPower, CharacterItem, PlayerItem, Location }

public readonly record struct CodexUnlock(CodexKind Kind, string Id);
// ProfileChangeSpec 增列：IReadOnlyList<CodexUnlock> CodexElements
```

- **为什么 element 上带 `Kind` 而存档落六个具名字段，不自相矛盾。** `AbilityChangeElement` 已是同一形态的先例：element 带 `(Kind, Scope)` 做路由，持有条目落 `playerPower` / `characterPower` / `playerItem` / `characterItem` **四个具名字段**。「否决 `Dictionary<CodexKind, …>`」约束的是**存档形态**，不是 element 的路由键。
- **为什么不复用既有的 `(Kind, Scope)` 二元组。** 该二元组的值域是 Power / Item × Character / Player 四个取值，恰好覆盖四本能力 / 道具图鉴，但 **Enemy 与 Location 落在值域外**。复用会逼出「二元组 + 两个特例」的畸形值域；另设六值 `CodexKind` 更便宜。
- **为什么必须新开一列，不能塞进既有列。** 判据与 `EventStateChanges` 分列时逐字相同——`Elements` 只装带符号的量，`AbilityElements` 的载荷带 `(Kind, Scope, Source, Op, PairKey)` 且改变**持有**，`StatusChanges` 的值是标量或 id；**没有一列装得下 `(CodexKind, Id)` 且语义对得上**。
- **`profile-service.CodexManager` 负责触发采集与去重，写入仍组装 `CodexElements` 经 `ProfileManager.TryApply` 单点提交**——与 `AchievementManager`「进度采集与奖励发放归本服务，写入仍经 ProfileManager 单点提交」逐字同构。

**失败语义（补进 profile-service 的失败语义表）：**

| 情形 | 分类 | 处置 |
|---|---|---|
| 该本图鉴中 `Id` 已存在 | **正常** | 该 element **空操作，不告警**。重复遭遇 / 重复获得是常态，不是缺陷；告警会刷屏 |
| 同一批 `CodexElements` 内出现两条同 `(Kind, Id)` | 正常 | 去重保留一条，**不告警**（同批多次授予同一条目是合法的） |
| `Id` 经 `ContentRegistry` 解析不到 | **必需缺失** | `PushError` + 整批拒绝（与 `DeckChangeElement.Id` / `PlotKeyPointAssignment.ArcId` 同档：悬空 `Id` 写进 Profile 会污染存档）。**注意与读档侧相反**——读档侧 `PushWarning` + 保留，这条读写不对称与 `PlotElements` 的先例同款、同理由 |
| `CodexElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 同款、独立成行）。理由同构：成本侧只放**可如实计价的量**，而「解锁一条图鉴词条值多少寿元」无法回答 |

- **恒不经 modifier pipeline。** 一条法则若能改写图鉴解锁，等于内容改写玩家的知识资产；与 `PlotElements` / `StatusChanges` 同源同重。
- **零 `Op`，因为永不删除。** 图鉴只增不删（`PlayerProfile` 整体亦然，故 diff 不表达删除）。

### 3. 六本的解锁触发：四本能力 / 道具类取「获得即记」

`[既有推演]`（「商店见到但没买」那一面**已定案为不记**，见 `## 用户裁决（2026-08-19 · 全部定案）` 第 1 项）

| 图鉴 | 触发 | 状态 | 组装方 | 搭在**哪一次已有提交**上 |
|---|---|---|---|---|
| **EnemyCodex** | **战斗开始**（遭遇，不必击败） | 已定案 | `combat-service` | `activeCombat` 初始化那一次 `TryApply` |
| **LocationCodex** | **抵达**（`CurrentLocationId` 置值那一刻） | 已定案（去过即记） | `life-cycle-service` | Travel 结算那一次 `StatusChanges` 提交 |
| **CharacterPowerCodex** | **获得**（`AbilityChangeElement.Op == Grant`，`(Power, Character)`） | **本方案建议** | 结算侧组装方 | 同一次授予提交 |
| **CharacterItemCodex** | 同上，`(Item, Character)` | 本方案建议 | 同上 | 同上 |
| **PlayerPowerCodex** | 同上，`(Power, Player)` | 本方案建议 | 同上 | 同上 |
| **PlayerItemCodex** | 同上，`(Item, Player)` | 本方案建议 | 同上 | 同上 |

**「获得即记」的四条依据：**

1. **它是「遭遇即记，不必击败」这句话在四本上的直接实例。** 那句话的内核是**接触即记，不要求你从中获益**——死亡至少换来知识。「使用过即记」正是它的反面：拿到了没来得及用就死掉，什么都不留下，与「失败侧也应有产出」的取向直接相抵。
2. **「使用过即记」对 `PlayerPower` 根本无法定义。** 法则是 always-available 的带开关能力，**没有「使用」这个离散事件**（`player-profile/_index.md`）。六本无法用同一句话表述触发，就等于回到「六套并行的解锁逻辑」——正是「为何是一族而不是一个」明确要避免的形态。
3. **「见到即记（含商店中见到）」把图鉴收集变成刷新按钮的副产物。** Exchange 库存是可花灵玉刷新的（`RerolledCount` 已在册），玩家刷十次商店即可刷满图鉴；这与「知识 = 力量、图鉴是跨轮回积累的资产」相悖。它还要求**呈现层写存档**（库存物化 / eventOption 呈现时提交 profile），会新开一个此前不存在的写入点。
4. **零新增提交点，这是最强的工程依据。** 上表六行的「搭在哪一次已有提交上」全部指向一次**已经存在**的 `TryApply`——不新增存档点、不新增 push、不新增决策点，完全落在「不新增存档点类型」这条既定纪律内。任何其他触发口径都至少要新开一个提交点。

**配套的可执行护栏（纪律阶梯第 3 级）：** `TryApply` 中出现 `Op == Grant` 的 `AbilityChangeElement` 而同批**没有**对应的 `CodexElements` 条目 → `#if DEBUG` 下 `PushWarning`。与「施加 `Disable` 时 `activeCombat != null` 走 `#if DEBUG` PushWarning」同款——组装方显式带上，断言只做兜底。**不由 `ProfileManager` 自动派生**：那会让 `AppliedChange` 记的账与组装方提交的 spec 不一致，违反「提交的是已算好的整块，本 manager 不做合并 / 增量」。

### 4. 词条深度：四本能力 / 道具类**不套用**敌人的五项规格

`[既有推演]` + `[通行做法]`

**建议：四本能力 / 道具图鉴的词条 = 该内容条目自身已有的字段 + 一段可选的图鉴专属风味文案，不新增结构化的多项写作规格。**

| 词条构成 | 来源字段 | 是否新增 |
|---|---|---|
| 名称 · 描述 · 立绘 | `PowerData` / `ItemData` 的 `DisplayName` / `Description`（`LocalizedText`）与既有美术挂点 | **不新增** |
| 稀有度 | `Rarity: RarityTier` | **不新增** |
| 风味 / 出处传说 | **新增一个可选字段 `CodexFlavor: LocalizedText`**，2–3 句 / 40–80 字，缺失即不渲染该段 | 新增 1 格 |

**为什么不照抄敌人的五项规格（承重）：** 敌人词条昂贵（150–280 字 × 五项 + 过「无阿拉伯数字」的审阅）**是因为它要在不给数值的前提下传达路数**——那条约束的存在理由是「不侵蚀越级黑箱」。**能力 / 道具没有这条约束**：玩家持有它们时，效果与数值本就在储物袋 / 法则面板上完整可见。把一条对**敌人**成立的遮蔽纪律套到**自己的东西**上，是把内容成本抬高一个量级却换不来任何信息。

- **也因此，四本词条不适用「不含阿拉伯数字」的口径纪律**——那条纪律的适用范围就是 EnemyCodex，须在 `common-properties.md` 里明写边界，否则会被后来者当成全族通则。
- **与「展示文案不进图鉴条目」完全一致**：`CodexFlavor` 挂在 `PowerData` / `ItemData` 上，存档侧仍然只有 `Id`。
- **分不分档解锁：六本一律不分档**（`[既有推演]`，直接来自「解锁是一次性的全量写入，逐项解锁已否决」）。四本能力 / 道具类的词条本就短，分档在它们身上尤其没有意义。

**LocationCodex 的词条深度本方案只写通用部分**：它与其余五本共用同一个 `CodexEntry(string Id)`、同一条写入通道、同一套读档校验。**「去过 A 之后词条列出 A 的全部邻接、还是只列已走过的边」不在本方案范围内**——见 `## 前置依赖`。

### 5. EnemyCodex 的慷慨度：建议维持 3 张关键卡，把旋钮交给 ③④ 的写作厚度

`[已定案]` — 取 A（维持 3 张关键卡），完整理由与退让阶梯见 `## 用户裁决（2026-08-19 · 全部定案）` 第 3 项。

**建议维持现状（3 张关键卡 + 五项文案），不给样本卡组完整列表**，理由三条：

1. **完整 15 张列表把词条从「事前知识」推向「事中情报」。** 知道全表的玩家可以在战斗中做「他还剩哪些牌」的推算——那是读牌堆，属**事中情报**，而「事前知识 vs 事中情报」这条分层是图鉴与战斗信息体系共存的**前提**，不是可微调的旋钮。3 张关键卡只勾勒路数，不支持这种推算。
2. **它会同时推翻两条已定案。** 「关键卡 3 张（5 张变成背卡表）」与「总长 150–280 字、一屏读完不需滚动」是同一次裁决的两面；15 张卡名 + 说明必然突破一屏，进而逼出分页或分档解锁，而分档解锁本身已被否决。
3. **慷慨度上调有一个更便宜、可回退的旋钮：③「运作方式」与 ④「特点与弱点」的写作厚度。** ④ 已被要求「必须可行动」；若实测知识不足，先把 ③④ 写厚（**纯内容侧调整、零机制成本、可逐条回退**），远早于动机制。

**预留的退让位（属实测调整，不是重新裁决）：** 若加厚 ③④ 后仍不足，**下一档是把 `KeyCardIds` 的数量上界从 3 放宽到 5**（加载校验的 `> 3 → PushError` 改为 `> 5 → PushError`，纯数据改动，词条仍在一屏内），**再之后**才考虑全表。给出这条阶梯，是为了让「慷慨度不够」将来有一条不必重开分层裁决的出路。

### 6. 序列化形态：六个顶层键、整键替换、不进透明路径白名单

`[既有推演]`

**上行 diff 与本地缓存的具体形态**（这一段直接答掉 `sync-service.md` 那条「本地缓存序列化写不出这两块的具体类型」）：

```jsonc
// PlayerProfileDiff 的六个顶层键（camelCase 单点策略 · 集合字段名恒单数）
"enemyCodex":         [ { "id": "enemy_qingfeng_01" }, { "id": "enemy_..." } ],
"characterPowerCodex":[ { "id": "power_..." } ],
"playerPowerCodex":   [ ... ],
"characterItemCodex": [ ... ],
"playerItemCodex":    [ ... ],
"locationCodex":      [ { "id": "loc_..." } ]        // 连边不落存档
```

- **六个键都是 `PlayerProfileDiff` 的顶层键 ⇒ 整键替换**（契约明写「顶层键即整键替换、未出现的保持不变、空对象 = 无变化、不表达删除」）。**推论：解锁一条 = 整本图鉴的 id 列表全量上行。**
- **体积口径（承重，须写进 sync-service）：** 单条 `{"id":"..."}` 约 25–35 B。设某类内容条目总数 N，则该本图鉴的**上限**约 `N × 30 B`；六本合计在内容规模成型后估计落在 **20–40 KB** 量级。它**小于**单轮回 `pastEvent` 的 ~150 KB，但与 `pastEvent` 同形——**随账号年龄单调增长且永不收缩**。
  - **建议加一条与 `pastEvent` 同款的体积护栏（软上限告警）：** 任一本图鉴的条目数 **>** 该内容类型经 `AllIncludingDisabled()` 得到的条目总数 → `GD.PushWarning` 带图鉴名与两个数值。它抓的是**重复条目 / 悬空条目**这类真实缺陷（正常账号永远达不到上限），成本近乎为零。
  - **明确不做：** 不为图鉴引入分页 / 冷热分离 / 独立存档段——与 `pastEvent` 那条否决同理由、同证据强度（无证据需要，且会重开「云端权威 · 整聚合 pull」这条语义）。
  - **图鉴统计读取走 `AllIncludingDisabled()`**（「已解锁 X / 共 Y」的分母必须含 disabled 条目，否则线上关一条内容会让玩家的完成度百分比跳变）。`content-service.md` 已把「图鉴统计」列为该方法的正当调用方之一，本条只是把它落实。
- **不进透明路径白名单。** 后端不复算图鉴、不据它发放任何东西 ⇒ 六个键不需要进 `backend-design-documents/contracts/profile-sync.md` §5。**但字段名仍受 camelCase 单点策略约束**（六个名已合规：单数、camelCase）。
  - **⚠ 若「收集完成度发放奖励」将来答「是」**，图鉴即成为发放输入，**六个键须整体升为透明路径并与后端同批落笔**——见 `## 前置依赖`。
- **`CodexKind` 会随 `PastEventEntry.AppliedChange` 落存档。** `AppliedChange` 是 `ProfileChangeSpec` 的快照，故枚举成员名进存档；虽然它落在 `CharacterProfileDiff` 的**不透明**部分（后端不解析），**成员名仍应在第一批存档写下前冻结**，与 `SavePointReason` / `Source` 同档对待。
- **本地缓存无独立文件。** 图鉴随整个 `PlayerProfile` 走 `LocalCacheManager` 的原子写（临时文件 → rename），不新增缓存文件、不新增序列化路径。
- **schema 版本：不另起一次 bump。** 六个 Codex 字段已在 `sync-service.md`「两层 Profile 的字段面收口」清单内（"增六个 Codex 字段（元素 `CodexEntry`）"）；`ProfileChangeSpec` 增 `CodexElements` 一列 **追加进同一次 bump**——该清单明写「后续同批新增的字段追加进本清单，不另起一次 bump」。老档补默认值 = 空列表。当前无线上存档 ⇒ 空迁移。

## 具体形态（可 derive 的落地面）

### `CodexEntry` 字段表（逐格 · 与 `PlayerProfile` 15 字段表同列口径）

| # | 字段 | 类型 | 层 | 默认值 | 写入通道 | 权威 |
|---|---|---|---|---|---|---|
| 1 | `Id` | `string` | 规则 | —（构造必填，无默认） | `CodexElements` | `codex/common-properties.md` |

> **表只有一行是本方案的结论，不是遗漏。** 计数字段与首次解锁元数据两组候选**全部不落**，理由见「建议方案 1」。

### `PlayerProfile` 15 字段表第 6–11 行的填空

| # | 字段 | 类型 | 层 | 写入通道 | 权威 |
|---|---|---|---|---|---|
| 6 | `enemyCodex` | `IReadOnlyList<CodexEntry>` | 规则 | **`CodexElements`** | `codex/_index.md` |
| 7 | `characterPowerCodex` | `IReadOnlyList<CodexEntry>` | 规则 | **`CodexElements`** | `codex/_index.md` |
| 8 | `playerPowerCodex` | `IReadOnlyList<CodexEntry>` | 规则 | **`CodexElements`** | `codex/_index.md` |
| 9 | `characterItemCodex` | `IReadOnlyList<CodexEntry>` | 规则 | **`CodexElements`** | `codex/_index.md` |
| 10 | `playerItemCodex` | `IReadOnlyList<CodexEntry>` | 规则 | **`CodexElements`** | `codex/_index.md` |
| 11 | `locationCodex` | `IReadOnlyList<CodexEntry>` | 规则 | **`CodexElements`** | `codex/_index.md` |

### 新增类型

```csharp
public enum CodexKind { Enemy, CharacterPower, PlayerPower, CharacterItem, PlayerItem, Location }

// ProfileChangeSpec 的第八列元素；零 Op（图鉴只增不删）
public readonly record struct CodexUnlock(CodexKind Kind, string Id);
```

### 内容侧新增字段

| 挂载对象 | 字段 | 类型 | 必填 | 缺失处置 |
|---|---|---|---|---|
| `PowerData` · `ItemData` | `CodexFlavor` | `LocalizedText` | **否** | 缺失 → 图鉴详情页不渲染风味段，**不告警**（可选缺失且属编排选择） |

> `EnemyData` **不加字段**——五项文案与 `KeyCardIds` 已在册。

## 后果

- **文档影响：** `codex/common-properties.md`（「待定的字段清单」整节被替换为定案的字段表 + 触发表 + 词条深度分野）· `codex/_index.md`（六本触发表、待决问题移除三条）· `codex/enemy-codex.md`（慷慨度结论 + 退让阶梯 + 计数字段待决项移除）· `player-profile/_index.md`（15 字段表六格填空、待决问题移除「六个 Codex 的计数字段是否要」）· `profile-service.md`（`ProfileChangeSpec` 增列 + 四行失败语义 + `CodexManager`）· `sync-service.md`（序列化形态、体积护栏、bump 清单追加一行）· `systems/common-properties.md`（`CodexFlavor` 进 `LocalizedText` 的挂载面清单）。
- **存档 schema：** 追加进已有的那一次 bump，空迁移。老档缺六个字段 → 空列表；缺 `CodexElements` 列 → 空列表。
- **无跨库影响**（现阶段）：后端不复算、不解析图鉴，六个键不进透明路径白名单，故**不需要后端配套改动、不需要对侧库草稿**。⚠ 该结论的成立前提是「收集完成度不驱动发放」——见 `## 前置依赖`。
- **内容制作成本：** 每条 power / item 多一段 40–80 字可选风味文案（可后补、可留空）；**敌人侧成本不变**。

## 备选方案（已考虑并否决）

- **`CodexEntry` 首批带计数字段（遭遇 / 击败 / 败于其手 / 使用次数）** — 两层混装（规则字段层的 record 里放纯读数），且加一格本就是零迁移的，预先加没有收益。
- **计数落 `CodexEntry` 但单独走宽松同步口径** — 直接撞上「一个字段不为『部分落点无规则消费点』而拆出第二套同步口径」（`SourceCode` 先例）。
- **图鉴解锁不进 spec，由 `CodexManager` 直接写 `PlayerProfile`** — 绕过唯一写入面，且解锁会脱离「获得 / 遭遇」那次提交的事务边界，出现「拿到了法宝但图鉴没记」的半套状态。
- **`ProfileManager` 看到 `Op == Grant` 自动派生 codex element** — 零遗漏很诱人，但会让 `AppliedChange` 记的账与组装方提交的 spec 不一致，违反「提交的是已算好的整块，本 manager 不做合并 / 增量」。改用显式组装 + `#if DEBUG` 断言兜底。
- **复用 `(Kind, Scope)` 做 codex 路由键** — Enemy 与 Location 落在值域外，会造出「二元组 + 两个特例」的畸形值域。
- **四本能力 / 道具图鉴照抄敌人的五项写作规格** — 五项规格的成本来自「不给数值地传达路数」这条约束，而该约束只对敌人成立；照抄是把内容成本抬高一个量级换不来信息。
- **触发取「使用过即记」** — 对 `PlayerPower` 无法定义（它没有离散的使用事件），且与「失败侧也应有产出」相抵。
- **触发取「见到即记（含商店中见到）」** — 商店可花灵玉刷新，图鉴收集退化为刷新按钮的副产物；且要求呈现层写存档，新开一个此前不存在的写入点。
- **给敌人样本卡组完整 15 张列表** — 见「建议方案 5」三条理由；该取向**已定案为不采纳**，见 `## 用户裁决（2026-08-19 · 全部定案）` 第 3 项。
- **为图鉴做分页 / 冷热分离 / 独立存档段** — 与 `pastEvent` 那条否决同理由：无证据需要，且会重开「云端权威 · 整聚合 pull」的语义。

## 与既有决策的张力

1. **「不要计数字段」与 `codex/_index.md` 的「图鉴衡量见过什么」这条收集感取向存在轻微张力。** 没有逐条目计数，图鉴页面无法呈现「你和他交手过 12 次 / 败于他手 2 次」这类有味道的信息。本方案的立场是：该信息属统计层，正确落点是 `PlayerStatistics` 的聚合项，**逐条目计数以「两层混装」为代价买这条展示不划算**。**该取舍已定案取本方案的立场**（首批零计数字段，聚合项作为将来的加法方向），见 `## 用户裁决（2026-08-19 · 全部定案）` 第 2 项。
2. **`ProfileChangeSpec` 增至八列，列数增长本身是成本。** 反驳：每一列的准入判据都是「既有列装不下它的载荷形状」，`CodexUnlock(CodexKind, string)` 满足该判据；且本列**零 `Op`、零 modifier pipeline、零可负担性参与**，是八列里最简单的一列。但如果用户认为列数已经过多，替代路径只有「`CodexManager` 直接写」，而那条已被上方否决。
3. **「四本不适用『不含阿拉伯数字』纪律」是对一条现有纪律的显式收窄。** 该纪律目前写在 `enemy-codex.md` 内，本就只约束敌人词条；但 `codex/_index.md` 的「共同形状」一节写着「给静态知识，不给动态情报……对整族适用」。**本方案主张「不给动态情报」对整族适用，而「不含阿拉伯数字」只对敌人适用**——两者不是同一条。须在 `common-properties.md` 里把这条边界明写下来，否则后来者会把它当成全族通则并因此把四本词条也做成结构化文案。
4. **「给完整卡组列表」已被否决（`## 用户裁决（2026-08-19 · 全部定案）` 第 3 项）——它会同时推翻两条已定案**（关键卡 3 张的裁决 · 词条 150–280 字一屏读完），且很可能连带逼出分档解锁——而分档解锁已被明确否决。它是**一次重开三条裁决的改动**，代价过高，故不采纳。

## 前置依赖

- **「图鉴是否与成就 / 奖励挂钩」（→ `systems/player-profile/achievement/`）。** 本方案按「**不挂钩**」写：六个 Codex 字段不进透明路径白名单、后端不复算。**若答「挂钩」**，图鉴完成度即成为发放输入，六个键须整体升为透明路径、与后端同批落笔，并新增一条完成度的复算口径——**「建议方案 6」的序列化结论会有实质变化**。
- **「LocationCodex 记连边的显影粒度」（→ `codex/_index.md` 待决问题）。** 本方案**不裁决**它。它只影响 LocationCodex 的**呈现**与 location 内容条目的连边字段，**不影响 `CodexEntry` schema**（连边不落存档已定案），故两者可各自独立答定。
- **「图鉴的入口与浏览形态」（→ `ux/screen-flow.md`、`ux/combat-ux.md`）。** 主菜单现有五个一等入口（PlayerProfile / PlayerPower / Achievement / Settings / Store），图鉴族尚无入口。本方案不裁决入口形态；但「建议方案 6」的**图鉴统计走 `AllIncludingDisabled()`** 这一条会被浏览界面消费，须一并落地。
- **`GameSetting` 的 schema 与设备本地 / 账号级切分**（15 字段表第 15 行的第七个 `⟨待定⟩`）。它与本方案**互不依赖**，只是同属该表的空洞；本方案不碰它。

## 用户裁决（2026-08-19 · 全部定案）

**四项取向全部按本方案的推荐定案（各取 A）**：取向 3 沿用 2026-08-18 批量评审的裁决，取向 1 / 2 / 4 于本次一并采纳。本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| 1 | 商店里见到但没买的法宝 / 古宝要不要记 | **取 A —— 不记，严格「获得即记」** | 既定的「遭遇即记」内核是「接触即记，不要求你从中获益」，而「在商店橱窗看了一眼」不构成接触；更重要的是 B 会把一个收集面挂到一个**可用货币无限重试的按钮**上（刷新按钮成为最高效的图鉴填充手段）。触发口径六本统一，零新增写入点 |
| 2 | 逐条目计数字段 | **取 A（首批）—— 一个都不要，`CodexEntry` 只有 `Id`**；**C 作为将来的加法方向**（计数落 `PlayerStatistics` 的聚合项） | 分层通则 + 选项 B 那条被低估的上行成本：`EncounterCount` 随每次遭遇变化 ⇒ **每场战斗都会让整本 `enemyCodex` 整键替换上行一次**（当前方案下只有「首次解锁」才产生 diff）。代价照录：图鉴页只能显示「已解锁 / 未解锁」，日后要加是零迁移的加法 |
| 3 | EnemyCodex 的慷慨度（承重） | **取 A —— 维持 3 张关键卡 + 五项文案**，慷慨度旋钮交给 ③④ 的写作厚度<br>*（2026-08-18 已裁，照录）* | 慷慨度不够是一个**可以先用内容侧手段试探、且随时可回退**的问题，而 B / C 都是一次性推翻既有裁决的机制变更；把便宜可逆的旋钮用完之前不动贵且不可逆的。**退让阶梯原样保留**：写厚 ③④ → `KeyCardIds` 上界 3→5 → 才考虑全表。**已知代价照录**：首次面对陌生敌人的信息劣势维持现有水平，而该水平在意图机制移除后尚未经实测检验 |
| 4 | `CodexFlavor` 是否真做 | **取 A —— 做，且可选**（缺失不渲染、不告警；内容侧可先全部留空） | 做与不做的**结构成本相同**（不做 = 全部留空），而留出这一格让内容侧日后有地方发力；符合「加法窗口在写下第一批 `.tres` 时关闭」的窗口判断 |

**前置依赖「图鉴是否与成就 / 奖励挂钩」→ 已答定：不挂钩。** 本方案正是按此写的，故**序列化那一节不再是悬的**：六个键不进透明路径白名单、后端零配合，结论成立。

**跨草稿裁决（`ProfileChangeSpec` 总列面）：** 本批四份草稿各自独立增列，合计由 7 推到 **11** 列（本方案的 `CodexElements`，另加 `RngElements` · `TraceElements` · `SettingChanges`）。**已裁决为接受** —— 「张力 2」所担心的「列数是否已过多」由此答结；硬要求：四份**单批收口、共用同一次 `schemaVersion` bump**。

**落笔提醒：** 本方案与 `solution-draft-game-setting-schema.md` 都要求追加进 `sync-service.md` **同一次**既有 bump 的清单 —— 须合并写进同一张表，**不得写成两次 bump**。
