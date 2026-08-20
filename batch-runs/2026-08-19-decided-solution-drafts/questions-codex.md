# Phase A — codex

来源草稿：`game-design-documents/inbox/solution-draft-codex-entry-schema.md`（`status: decided`）
目标库：`game-design-documents/`（orchestrator 已给定 `game`）

## 一句话摘要

`CodexEntry` 首批只有 `Id`（零计数、零元数据）；六本图鉴的写入通道统一为 `ProfileChangeSpec` 新增的 `CodexElements` 列（元素 `CodexUnlock(CodexKind, string Id)`，零 `Op`、恒不经 modifier pipeline）；四本能力 / 道具图鉴取「获得即记」且词条不套用敌人的五项规格、只加一个可选 `CodexFlavor: LocalizedText`；EnemyCodex 慷慨度维持 3 张关键卡并保留退让阶梯；序列化落六个顶层键、整键替换、不进透明路径白名单、追加进已有的那一次 schema bump。

## 已定案项（用户已裁决，不进 interview）

草稿 `## 用户裁决（2026-08-19 · 全部定案）` 四项，逐条与既有权威核对**均无抵触**：

| # | 定案 | 核验结论 |
|---|---|---|
| 1 | 商店见到不记，严格「获得即记」 | 与 `codex/enemy-codex.md`「遭遇即记，不必击败」的内核一致；与「呈现层不写存档」一致 |
| 2 | `CodexEntry` 首批只有 `Id`，计数一个都不要；将来落 `PlayerStatistics` 聚合项 | 与 `player-profile/_index.md`「两层判据」「合并判据」「加一格是零迁移」逐条对得上 |
| 3 | EnemyCodex 维持 3 张关键卡 + 五项文案，旋钮交给 ③④ 写作厚度；退让阶梯 3→5→全表 | 与 `enemy-codex.md`「总长 150–280 字、一屏读完」「关键卡 3 张」一致 |
| 4 | `CodexFlavor` 做，且可选 | 挂载面与 `systems/common-properties.md` 的 `LocalizedText` 顶层挂载表相容（**但缺失语义有一处冲突，见 🔴-1**） |

另有两条草稿内已答定、须走 answer-log 的：
- **前置依赖「图鉴是否与成就 / 奖励挂钩」→ 答定「不挂钩」**（序列化那一节因此不再是悬的）。
- **跨草稿裁决：`ProfileChangeSpec` 由 7 列推到 11 列，接受；四份草稿单批收口、共用同一次 `schemaVersion` bump。**

## 🔴 冲突

### 🔴-1 `CodexFlavor` 缺失「不告警」✗ `LocalizedText` 默认语言缺失 = `PushError` + `throw`

- 草稿 `## 内容侧新增字段`：`CodexFlavor: LocalizedText`，必填 = 否，**缺失 → 不渲染风味段，不告警**（且明写「内容侧可先全部留空」）。
- 既有权威 `systems/services/content-service.md`「内容文本的语言校验与覆盖率审计」失败语义表第 1 行（**无字段级例外**）：
  > **默认语言（`zh`）缺失 / 空串** ｜ 必需缺失——一条没有正文的内容就是坏数据 ｜ **合并后强校验** `GD.PushError` + `Id` + 字段名 + `throw`，**启动期早失败**
- 冲突实质：`CodexFlavor` 会是**全库第一个「可选的 `LocalizedText` 字段」**。按现行表的字面口径，一条留空风味文案的 `PowerData` 会在启动期抛异常——而草稿正好把「先全部留空」写成推荐做法。这不是措辞问题：现行表是**启动期硬失败**，落地即整包起不来。

  - **选项 (a)** 「缺失」定义为**字段本身为 `null`**（未挂 `LocalizedText` 子资源），强校验只对**非 `null` 的 `LocalizedText` 字段**执行；挂了却 `zh` 空串 → 仍 `PushError`。
    后果：`content-service.md` 该表加一句适用范围；`CodexFlavor` 留空 = `.tres` 里不挂这个子资源，语义干净可判，与「缺 `en` 键 = 未翻译」同一种「干脆没有这个键」的判据风格。**不引入新概念。**
  - **选项 (b)** 在 `systems/common-properties.md` 的 `LocalizedText` 一节引入**必填 / 可选**两类字段的显式区分，校验表按类分行。
    后果：多一条要逐字段维护的清单（哪些字段可选），`content-service.md` 与 `common-properties.md` 两处同改；后续每加一个展示文本字段都要先回答「它属哪一类」。
  - **选项 (c)** `CodexFlavor` 改为**必填**，内容侧必须为每条 power / item 写 40–80 字风味。
    后果：与草稿裁决 4「可选、可先全部留空」直接相抵，且把内容制作成本从「可后补」变成「第一批就得写满」。
- **推荐：(a)**。理由：它不新增概念、不新增清单，只把现行表里本就隐含的「一条内容的正文」收窄为「一个已存在的 `LocalizedText`」；`en` 占位形态既定为「该 locale 干脆没有这个键」，(a) 是同一条判据在字段层的复用。(b) 的可选清单正是本库反复否决的「要读上下文才能判」的形态。

## 🟠 含糊

### 🟠-1 轮回 / 角色创建那一刻的**初始持有**是否进图鉴，草稿未交代

- 草稿的四本触发一律取 `AbilityChangeElement.Op == Grant`，并把「零新增提交点」列为**最强的工程依据**。
- 但既有设计里有两处初始持有**不经 `Grant` element**：
  - `systems/character-profile/power/_index.md`：「**每个角色自带一个绑定神通**」（起手那一份已定），随角色创建而存在。
  - `systems/character-profile/_index.md`：`CurrentLocationId`「**仅由 Travel 结算改写**」+「不需要『起始地域』这个概念」——新轮回的第一个地域从何置值未明写；若不是一次 Travel 结算，草稿的 LocationCodex 触发（「`CurrentLocationId` 置值那一刻」）就落空。
- 两种解读会写出不同的 `codex/common-properties.md` 触发表：
  - **(a)** 触发口径不变，初始持有**不入图鉴**（玩家的绑定神通不在自己的图鉴里；起始地域要等下一次 Travel 才显影）。
  - **(b)** 触发口径扩为「凡进入持有列表 / 凡 `CurrentLocationId` 被置值（含创建时）即记」，角色创建那一次提交也带 `CodexElements`。
- 后果差异：(b) 需要在轮回创建路径上明写一次 `CodexElements` 组装点；若创建路径本就走一次 `TryApply`，仍是零新增提交点，(b) 几乎无成本。(a) 会产生一个**玩家一眼可见的怪状**——自己一直带着的神通、出生所在的地域，图鉴里是空的。
- **推荐：(b)**。理由：草稿自己写下的内核是「**接触即记**，不要求你从中获益」；「自带的东西不算接触过」比「商店橱窗看一眼不算接触」难自圆其说得多。且 `codex/_index.md` 明写 LocationCodex「**去过即记**」——出生地也是去过的地方。

### 🟠-2 EnemyCodex 搭车的那次 `TryApply` 依赖一个**未定的写入通道**

- 草稿触发表：EnemyCodex 搭在「`activeCombat` 初始化那一次 `TryApply`」上。
- 但 `systems/services/profile-service.md` 待决问题明写：**「`activeCombat` 的写入通道未明写（承重）。**`activeEvent` 已定走 `EventStateChanges`，形态相同的 `activeCombat` 仍来路不明」。
- 两种解读：
  - **(a)** 战斗开始确实存在一次 `TryApply`（只是它落哪一列未定）⇒ 草稿的「零新增提交点」成立，触发表原样写下，只在 `codex/common-properties.md` 注明该次提交的列面另见 profile-service 待决问题。
  - **(b)** 战斗开始尚未确定有 `TryApply` ⇒ EnemyCodex 需要**自带一次提交**，草稿最强的那条工程依据（六行全部搭车、零新增提交点）在 EnemyCodex 这一行不成立，须在 handoff 中如实降格。
- **推荐：(a)**，并在落笔时把这一行写成「随战斗开始那一次 profile 提交」而**不点名 `activeCombat`**——`activeCombat` 的列面是别人的待决问题，点名它会把一条未定结论抄进图鉴文档，制造第二权威。

## 🔵 可推演（无需回答）

1. **落笔时不得写「第八列」这个序数。** `profile-service.md` 与 `terminology.md` 同款明写：`ProfileChangeSpec`「**列表数不进承重表述**——它随字段族增长，把数字写死等于每加一列就要改一次这条纪律」。草稿正文的「第八列」是草稿语，活文档一律写作「新增一列 `CodexElements`」。（本批四份草稿共增四列，更不能写死数字。）
2. **`CodexElements` 满足既有三级准入判据。** `systems/architecture.md` 的三级判据（分列 ⟺ 六面核对全不对齐）：`Elements` 只装带符号的量、`AbilityElements` 载荷带 `(Kind, Scope, Source, Op, PairKey)` 且改变**持有**、`StatusChanges` 的值是标量或 id ——确无一列装得下 `(CodexKind, Id)`。分列成立。
3. **`CodexElements` 在 `SelectCost` 内恒为空**已被既有措辞自动覆盖：`terminology.md` 的 `ProfileChangeSpec` 词条写着「`selectCost` 内除 `Elements` 外各列恒为空」，新列自动落入；仍按草稿在失败语义表独立成行（与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 同款）。
4. **既有两处「计数」措辞须随裁决 2 一并改写**（属本次触及小节内的顺手修，非扩大改动面）：
   - `codex/common-properties.md`：「存档条目只带 `Id` + 解锁状态 + **计数类可变字段**」「解锁**与计数更新**是 `ProfileChangeSpec` 的变更目标」；
   - `codex/_index.md`「共同形状」：「解锁**与计数更新**是 `ProfileChangeSpec` 的变更目标」。
   两处的「计数」在首批为空，留着会让后来者以为计数字段已定。
5. **`enemy-codex.md` 有一句引用了已被移除的机制**：「越级的信息压迫由**意图三档独占承载**（既定的分层分工）」——意图机制整条移除已定（`open-questions/01-combat.md`「信息面的残留（意图移除后）」）。该句是「首遇即全知」的三条论据之一，删掉它后另两条（静态知识的价值不在藏起来 · 词条分级可见会打破「一次遭遇全文案解锁」）仍独立成立 ⇒ 直接删该分句，不需要新论据。本次正好改写该文件的慷慨度结论，顺手修。
6. **`terminology.md` 的「图鉴（族）」词条写着「共五个」**，与同文件「地域图鉴 = 图鉴族**第六本**」自相矛盾（LocationCodex 加入后未同步）。本次触及该词条，顺手改为六个。
7. **`AllIncludingDisabled()` 作图鉴统计分母**无需新增任何设计：`content-service.md` 与 `systems/common-properties.md` 均已把「图鉴统计」列为该方法的正当调用方，草稿只是落实。
8. **schema 追加进已有 bump 成立**：`sync-service.md`「两层 Profile 的字段面收口」清单已含「`PlayerProfile` 增六个 Codex 字段（元素 `CodexEntry`）」，且明写「**后续同批新增的字段追加进本清单，不另起一次 bump**」。`ProfileChangeSpec` 增列照 `DeckElements` / `PlotElements` / `EventStateChanges` 的先例并入同一行。
9. **不进透明路径白名单成立**：`sync-service.md` 的透明路径纪律只约束后端会解析 / 复算的 path；「不挂钩」已答定 ⇒ 后端零配合。六个键名（`enemyCodex` 等）合规（单数 · camelCase）。
10. **`CodexKind` 成员名随 `AppliedChange` 落存档**成立：`AppliedChange` 是 `ProfileChangeSpec` 快照，`sync-service.md` 已明写「枚举值序列化与 C# 枚举名逐字相同 ⇒ 重命名一个落存档的枚举值即破坏性变更」。
11. **`CodexFlavor` 挂 `PowerData` / `ItemData` 覆盖四本**：`systems/common-properties.md` 的挂载面表把 `PowerData` / `ItemData` 记在**顶层**（`Player*` 与 `Character*` 共用同一内容类），故一个字段覆盖四本能力 / 道具图鉴，无需分两套。
12. **草稿一处措辞需要在落笔时收紧**：草稿「约束」一节写「关键卡 `EnemyData.KeyCardIds` **显式列 3 张**」，而 `enemy-codex.md` 的加载校验是「数量 **> 3 或 < 2** → `PushError`」（即 2–3 张合法，词条规格写 3 张）。退让阶梯按草稿写作「上界 3 → 5」，**下界 2 不动**。

## 拟改动文档清单与各自新增要点

| 文档 | 新增 / 修改要点（供跨草稿核对） |
|---|---|
| `systems/player-profile/codex/common-properties.md` | 「待定的字段清单」整节 → 替换为：`CodexEntry` 一格字段表 + 「为什么就一格」三条依据 + 六本触发表（含 🟠-1 的裁决）+ 词条深度分野（四本不套五项规格）+ **「不含阿拉伯数字」纪律边界只及 EnemyCodex** 的明写 + 六本一律不分档；顺手改「计数类可变字段」措辞（🔵-4） |
| `systems/player-profile/codex/_index.md` | 六本触发表落地；「共同形状」去掉「与计数更新」；**待决问题移除三条**（其余图鉴触发 · 词条深度是否一致 · 是否与成就挂钩），保留三条（记连边显影粒度 · LocationCodex 其余词条深度 · 入口与浏览形态） |
| `systems/player-profile/codex/enemy-codex.md` | 慷慨度结论（维持 3 张）+ 退让阶梯（写厚 ③④ → `KeyCardIds` 上界 3→5 → 才考虑全表）+ 已知代价照录；删「意图三档独占承载」分句（🔵-5）；**待决问题两条全移除** |
| `systems/player-profile/_index.md` | 15 字段表第 6–11 行写入通道 `⟨待定⟩` → `CodexElements`（六格）；`CodexEntry` 代码块处补「首批零计数字段」的结论与代价；**待决问题移除「六个 Codex 的计数字段是否要」** |
| `systems/services/profile-service.md` | `ProfileChangeSpec` 各列枚举**增一列** `CodexElements`（**不写序数**，🔵-1）+ `CodexUnlock` 语义段（零 `Op` · 恒不经 modifier pipeline · 由 `CodexManager` 采集去重、写入仍经 `ProfileManager` 单点提交）+ **失败语义表增 4 行**（已存在 = 空操作不告警 · 同批重复 = 去重不告警 · `Id` 解析不到 = `PushError` 整批拒绝 · 出现在 `SelectCost` 内 = `PushError`）+ `#if DEBUG` 兜底断言（`Grant` 无配套 codex element）+ 管理器表增 `CodexManager` 一行 |
| `systems/services/sync-service.md` | 六个顶层键的序列化形态 + 整键替换推论 + 体积口径（20–40 KB 量级、随账号年龄单调增长）+ **体积护栏软上限告警**（条目数 > `AllIncludingDisabled()` 总数）+ 明确不做分页 / 冷热分离 + 不进透明路径白名单 + **bump 清单该行追加 `CodexElements`**（⚠ 与本批另三份草稿写同一张表、同一次 bump） |
| `systems/common-properties.md` | `LocalizedText` 挂载面清单补 `CodexFlavor`；**若 🔴-1 取 (b) 则另加必填 / 可选分类** |
| `systems/services/content-service.md` | **仅当 🔴-1 取 (a) 或 (b)**：语言校验失败语义表补一句适用范围（可选 `LocalizedText` 字段的「缺失」定义） |
| `terminology.md`（草稿未列，**必须补**） | ① `ProfileChangeSpec` 词条的列枚举增 `CodexElements`（⚠ **本批四份草稿的共同热点行**，四列须合并为一次改写）；② 新增词条 `CodexUnlock` / `CodexKind`（酌情）+ `CodexFlavor`；③ 顺手修「图鉴（族）……共**五个**」→ 六个（🔵-6） |

### 台账行 / 条目增删（交 orchestrator 代笔，本 worker 不写）

- **`open-questions/07-codex-monetization.md`**：移出「其余四个图鉴的解锁触发与词条深度」整条；「图鉴的入口与浏览形态」一条**部分移出**——其中「是否与成就 / 奖励挂钩」已答定（不挂钩），须**重写该条**只留「主菜单如何组织 · 战斗内能否查阅」。
- **`open-questions/01-combat.md`**：移出「敌人图鉴的慷慨度是否该上调（承重）」整条（在「信息面的残留（意图移除后）」小节内）。
- **`answer-logs/log-codex-entry-schema.md`**（新建）：来源 = `inbox/solution-draft-codex-entry-schema.md`；移出条数约 3（含 1 条部分移出）。`answer-logs/_index.md` 追加一行。
- **`handoffs/_index.md`**：新增 handoff 行（建议 id `2026-08-19-codex-entry-schema-and-unlock-triggers`）。
- **`inbox/_index.md`**：该草稿从待处理表移入已归档表（前置条件三条须先成立）。
- **`open-questions/update-log.md`**：本次摘要（由 orchestrator 与其余三份草稿合并成一条）。

## 越界发现

1. **`terminology.md` 的 `ProfileChangeSpec` 列枚举是本批四份草稿的共同写入点**（本草稿 `CodexElements`、另三份 `RngElements` / `TraceElements` / `SettingChanges`）。它是**单行文本**，四个 worker 并行写必然互相覆盖 ⇒ 建议 orchestrator 按写入面分区规则**收归自己或单一 worker 串行改写**。
2. **`sync-service.md` 的「两层 Profile 的字段面收口」bump 清单**同理——四份草稿都要求追加进**同一次** bump（草稿末尾「落笔提醒」已点名与 `solution-draft-game-setting-schema.md` 冲突）。**必须单写者**。
3. **`profile-service.md` 的 `ProfileChangeSpec` 各列枚举句 + 失败语义表**同为四份草稿的共同写入面。
4. **`profile-service.md` 待决问题「RNG 状态的写入通道形态未定」** 属本批 rng 草稿的范围，本 worker 不动；但它与 `activeCombat` 那条互相牵动（见 🟠-2），若 rng 分片把 `activeCombat` 一并收口，本分片的 🟠-2 可直接落 (a)。
5. **`ux/screen-flow.md` / `ux/combat-ux.md` 的图鉴入口**：草稿明确不裁决，本 worker 不碰；但「图鉴统计走 `AllIncludingDisabled()`」这条会被浏览界面消费，已记在 sync-service 侧。
6. **内容条目层**：`CodexFlavor` 的实际文案属 `/author-content` 范围，本技能只承接类型级字段定义。
