---
type: solution-draft
date: 2026-09-01
question: 做一次 `systems/architecture.md ↔ systems/services/*` 的待决问题与投影表系统性对账，产出差异清单 + 逐条处置建议
source: open-questions/05-service-contracts.md → ⑤-5（08-19 新增 · 轻）；同条亦登记于 systems/architecture.md:722 的 `## 待决问题`
targets: systems/architecture.md（主）· systems/services/_index.md · systems/services/life-cycle-service.md · systems/services/profile-service.md · systems/services/sync-service.md（各一处措辞）
status: distilled
reviewed: 2026-09-02 批量评审 —— D-1 取选项 A（层级词表跟真实承重走，拆分判据 3 的宿主口径放宽为「manager 或 module」，同批改 `ADR-0008`；连带 `GrantPoolPicker` → `GrantPoolManager`）；L-2 中 `character-profile/_index.md` 的 11 处 bump 自称**排除出本批次**，与 `sync-service.md` 清单补齐同批做；S-4 中「同步 derive 就绪度判定表」的建议**驳回**（该小节由 `/assess-derive-readiness` 独占）。落笔以复核结论为准，纠正草稿六处细节（含 P-3c 的处置本身有误）。
distilled-to: handoffs/2026-09-02-architecture-services-reconcile.md
---

# 方案草稿 — `architecture.md ↔ services/*` 系统性对账

## 问题

`architecture.md` 是「结构与边界的权威」，同时**持有若干张投影到下游服务文档的表**（服务 ↔ manager 表、五级层级词表、`ResourceElements` / `StatusFields` / `SettingFields` 三张封闭表、EventBus 负载契约表、纪律可执行化四处应用表、`## 决策(-> ADR)` 台账、闭环缺口表）。这类「上游持定义、下游持取值 / 现状」的结构有一个已被本库两次踩到的失败模式：**下游答定了，上游没人回头划掉**。

- 实例一：`architecture.md` 的三条结构残留（断线降级 / 热更「只改不增」连带项 / ViewModel 文档落位），其中两条的答案早已写死在下游，直到 08-19 才被整批清掉（`answer-logs/log-architecture-structural-residuals.md`）。
- 实例二：`ResourceElements` 表在 `architecture.md` 与 `profile-service.md` 之间曾出现投影漂移。

⑤-5 要求的是**一次系统性对账，而非逐次顺手修**。本草稿即那一次对账的产物：**差异清单 + 逐条处置建议**。

**本草稿不修任何文档。** 落笔归评审后的 `/analyze-new-ideas`。

## 约束（来自既有设计）

- **`architecture.md:722` 自陈：本条「是一项维护动作，不是设计缺口——本文件的设计面无未决项，对账不产出新的 FR，也不构成任何 derive 的前置」。** ⇒ 本对账的输出**不得**长出新的设计决定；凡对账中冒出真正的设计冲突，必须**单独标出**、不混进机械修订（见 D-1）。
- **投影纪律（`ADR-0005` / `systems/_index.md` 收尾约定）：定义在最小公共祖先、投影在各落点；投影只写落点 / 本层合法子集 / 本层消费点 / 回链，不得复述定义。** ⇒ 处置建议里凡「两侧都有一份完整副本」的，方向一律是**删下游副本或删上游副本、留回链**，不是「把两份改成一致」。
- **活文档只保留最新设计（重写替换，不留考古）**（`.claude/rules/Context.md` 根约定）。⇒ 过期登记一律**整条删除**，不写「原为 X / 已由 Y 取代」。
- **一切皆可改，包括 ADR 本身**（同上）。⇒ D-1 若裁决为「改判据措辞」，直接改 `ADR-0008` 与 `architecture.md`，不新开 ADR。
- **对账口径 = 已核实。** 下方每条差异均带文件 + 行号；凡由子代理报出而我未逐条复核的，明确标注 `[未复核]`。

## 建议方案

差异按性质分四族：**D · 设计面冲突**（唯一一条，需裁决）· **S · 过期登记 / 陈旧措辞**（机械删改）· **P · 投影漂移 / 副本**（结构性，需选一侧留）· **L · 台账缺口**（补录）。

---

### D-1 🔴 第四 / 第五级层级词「无实例」已被三份主题文档推翻，且下游形态与拆分判据第 3 条正面冲突

`[取向选择]` —— **本对账中唯一一条真正的设计面冲突，不是机械对账项。**

**上游（两处，口径一致且均为旧）：**
- `architecture.md:32` 层级表：`| 第四级 | processor | 预留 | — |` · `| 第五级 | handler | 预留 | — |`
- `architecture.md:34`：「**第四 / 第五级目前没有实例，且暂不落实例——保持空是健康的。**」
- `architecture.md:46` 校准样本：「效果施加（`StackManager` 内）**强候选**，其下**可能**是 handler 的第一处用武之地」——写成尚未发生。
- `services/_index.md:18`：「第四 / 第五级**目前无实例**，定名以免各处自造词。」

**下游（三份主题文档 + 一份 handoff，已写死）：**
- `services/combat-service.md:346`：「**主持者 = `EffectProcessor`**（`combat-service > StackManager > EffectProcessor > handler` **四级**，层级词表见 `systems/architecture.md`）」
- `character-profile/deck/common-properties.md:282`：「代码侧落点 = `combat-service > StackManager > EffectProcessor > handler`（**一原语一 handler**）」
- `character-profile/item/_index.md:52`：「战斗内经 `StackManager > EffectProcessor > handler` 的**五阶段流水线**」
- `handoffs/2026-08-27-ability-primitive-grammar.md:72`：「代码落点 … 与既定层级判据完全对齐，**无需再论证**」

**两层差异，第二层才是要害：**

1. **「无实例」已失真** —— 机械项，删改即可。
2. **宿主层级与 `architecture.md:43` 的判据 3 冲突** —— `EffectProcessor` 的宿主是 `StackManager`（一个 **manager**），而判据 3 逐字写着「拆出后调用入口仍只有**宿主 module** 一个——不产生第二个调用方、**不越层被 manager 直呼**」。下游形态**正是被 manager 直呼**。08-27 handoff 断言「与既定层级判据完全对齐、无需再论证」，但逐字读判据 3 并不支持它。

**建议处置（供裁决，两个方向）：**

- **方向 A（推荐）—— 改判据 3 的措辞，承认 processor 的宿主可以是 manager 或 module。** 改为：「**拆出后调用入口仍只有宿主一个（manager 或 module）**——不产生第二个调用方、不越层被更上层直呼。」
  依据：`architecture.md:45` 的三条反判据里已明写「**层数不是成熟度指标**——「抽象层次不封顶在两级」这句话同时也意味着**不封底**」。要求 processor 必须挂在一个 module 之下，等于强制在 `StackManager` 与 `EffectProcessor` 之间造一个只有一个实例、永不变体的 module——正中反判据 ②③。
  代价：`architecture.md:36` 那句「顺着这条轴」的层级递进叙述需微调，因为链条从此可以跳级。
- **方向 B —— 保留判据 3 原文，在 `StackManager` 与 `EffectProcessor` 之间补一层 module。** 代价：三份主题文档 + 一份 handoff 的既定措辞全部改写，且造出一个反判据明确禁止的 module。**不推荐。**

**同批必改（无论选哪个方向）：** `architecture.md:32` 层级表第四 / 五级的「现有实例」列填 `EffectProcessor` / 效果 kind handler · `:34` 删「暂不落实例、保持空是健康的」· `:46` 把「强候选 / 可能」改为已落地的陈述 · `services/_index.md:18` 同步 · `open-questions/05-service-contracts.md:29` 的「第四 / 第五级层级词是否过早」一条（登记语「首次真要拆一个 processor 时回头验证那三条与门判据」）**其触发条件已发生**，该条应据本次裁决结果关闭或改写。

---

### S-1 🟠 「剩余的结构性未决项」三项全部已答（`architecture.md:715`）

`[既有推演]`

**上游 `:715`：**「**剩余的结构性未决项**已下沉为各服务文档的待决问题（`EventOption` 完整物化字段清单、内容分桶粒度、协议报文字段），见下节与 `services/*`。」

**逐项现状：**

| 项 | 下游现状 | 证据 |
|---|---|---|
| `EventOption` 完整物化字段清单 | 已由一条物化判据收口 | `answer-logs/log-event-option-materialized-fields.md:7`；判据本体在 `architecture.md:205` 自身。`future-event-service.md` 的 `## 待决问题` 现只剩 `BaseTypeWeights` 配比一条 |
| 内容分桶粒度 | 已答「**分桶规则哪也不放在客户端**」 | `content-service.md:167`（我已复核原文）· `ADR-0130:22` · `answer-logs/log-0811_2.md:16`。`content-service.md` 待决问题现只剩 disabled 条目 UX 一条 |
| 协议报文字段 | 已定，权威在后端 `contracts/envelope.md` | `sync-service.md:373` 明写；该文档待决问题只剩后端侧的 `pushId` 记忆窗口 |

**建议：整句删除**，不留替代回链——三项各自的权威都已在下游成文，上游再指一次只会成为下一次漂移的种子。若确要留一句导航，改为一句不点名具体项的「各服务的残留待决项见其各自文档」（与 `services/_index.md:76-78` 同形）。

---

### S-2 🟠 `ADR-0002` 的「待补订 Explore / Travel」批注已过期（`architecture.md:684`）

`[既有推演]`

- 上游 `:684`：「→ `decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted；**待补订 Explore / Travel**）。」
- 下游 `decisions/ADR-0002-adventure-event-taxonomy.md`：`status: Accepted` / `date: 2026-08-15`，Decision 段的五类表中 **Explore（`:21`）与 Travel（`:22`）各占正式一行**，另有 `:33` / `:35` 两段专门论述，**无任何待补订标记**。（我已逐行复核。）

**建议：删「待补订 Explore / Travel」六字**，该行改为纯 `→ ADR-0002（Accepted）`。

---

### S-3 🟠 `life-cycle-service.md:307` 仍把「AdventurePlot 树的数据编码」挂为待定（反向漂移）

`[既有推演]`

- 下游登记 `services/life-cycle-service.md:307`：「隐藏属性细节：…… 仍待定：**隐藏属性完整清单**、**增减触发**、**AdventurePlot 树的数据编码**。」（我已复核原文。）
- 实际已答：`decisions/ADR-0015-plot-tree-data-shape.md`（**Accepted**，2026-08-16，「剧本树的数据形态：纯调制、两个内容类型、key points 每 arc 一条」）；本体在 `services/plot-manager.md:222`（`PlotArcData` + `PlotNodeData`）· `:231` / `:240` 字段 · `:256` 恒启用校验 · `:259` 正文内嵌 · `:203` 不分包。`[子代理核实 · 我未逐行复核 plot-manager 的这五处行号]`
- 同一分片的**权威**文档 `plot-manager.md` 的 `## 待决问题`（`:537-539`）**已不含该项**——上下两份文档对同一条目的状态不一致。

**建议：从 `life-cycle-service.md:307` 删去「AdventurePlot 树的数据编码」一项**，保留另两项（隐藏属性完整清单 / 增减触发——它们在 `plot-manager.md:538` 亦有登记，属重复登记而非矛盾，见 L-3）。**这是本对账中唯一一条方向为「上游对、下游错」的差异**，其余均是上游落后于下游。

---

### S-4 🟠 `profile-service.md:418` 的「`status` 与拥有 / 失去的存档表达」候选过期

`[既有推演]` + **一处需评审确认边界**

- 下游登记 `services/profile-service.md:418`：「**`status` 与「拥有 / 失去」两态的存档表达。** 两个正交维度如何编码进 schema 未定。」
- 同一列表 `:421` 却写着「（**`PlayerPower` / `PlayerItem` 的持有条目形态** …… **已定**，见 `systems/player-profile/_index.md`）」——**同一份 `## 待决问题` 内部自相矛盾**。
- 编码实际已成文（我已复核）：`player-profile/_index.md:65` `public readonly record struct PlayerPower(string PowerId, bool Status, Source SourceCode);` · `:64` 同形的 `PlayerItem`；语义在 `player-profile/player-power/common-properties.md:13`：「持有 = 列表成员 / 生效 = 条目上的 `status`；**失去 = 移出列表，而非置 `status = 禁用`**」。

**建议：改写而非直接删除。** 「两个正交维度如何编码」这一问确已答（record 三格 + 移出列表语义）；若该条实际想问的是**别的东西**（例如：失去后是否留痕、`SourceCode` 在移出时如何处理），则应把措辞收窄到那一点。**评审时请确认这一条到底还剩什么没答**——若什么都不剩即整条删除，同时 `:421` 的括注也随之失去对照对象、可一并简化。同批：`open-questions.md` 判定表里 `profile-service.md` 与三份 power 文档的卡点均含此条（`:95` / `:96` / `:99` / `:100`），关闭后须同步。

---

### P-1 🟠 存储分界图缺 flags 第三层（`architecture.md:83-88`）

`[既有推演]`

- 上游 `:83-88` 的代码块只有两层：`res://content/**.tres` → `user://overlay/**.tres` → 合并 → `ContentRegistry`。
- 下游 `content-service.md:8-19`（我已复核原文）小节名即「**存储形态：三层覆盖来源**」，图中第三行 `flags（运行时态，不落 .tres）　按账号解析后的开关结果，只覆盖 ContentEnabled`，合并序 `flags > overlay > res://`；`:19` 明写「**overlay 不是唯一热更层**」。
- 连带：`architecture.md:691` 对 `ADR-0007` 的括注写「（随包基线 + `user://overlay/` 热更 + 云端版本校验）」，而 `content-service.md:427` 对**同一个 ADR** 的括注写「（随包基线 + `user://overlay/` + **flags 三层覆盖** + 云端版本校验）」——同一 ADR 在两处的括注不一致。
- `architecture.md` 别处（`:167` 总则 4 的 `RefreshFlagsAsync`）**确实认识 flags**，故这是**局部投影未跟上**，不是整体缺失。

**建议：** 在 `:83-88` 的图中补第三行 flags（**只补一行 + 合并序，不复述 flags 的语义**——语义权威在 `content-service.md`，此处依投影纪律只写落点与回链）；`:691` 的括注与 `content-service.md:427` 对齐。

---

### P-2 🟠 `ResourceElements` 表在 `architecture.md` 与 `profile-service.md` 之间有**两份完整副本**（当前值一致，结构性隐患仍在）

`[既有推演]` —— **这正是 ⑤-5 点名的那处漂移的当前形态：值已对齐，副本没消。**

- 逐行比对结果：`architecture.md:399-415` 与 `profile-service.md:249-263` 的 **15 行 × 6 列全部一致**，**当年的那处漂移已不存在**。`[子代理逐格核对 · 结论我采信]`
- 但分工声明是互相委派的：`architecture.md:554` 明写「逐行取值 …… 见 `systems/services/profile-service.md`」，`profile-service.md:245` 反向写「类型定义与配表理由见 `systems/architecture.md`」。**双方都说对方持有取值，而 `architecture.md` 事实上仍带着完整的 15×6 值集。**
- 同族第二例：`SettingFields` 的 4 行含默认值在 **三处**各有一份（`architecture.md:432-435` · `profile-service.md:177-180` · `player-profile/game-setting.md:25-28`），而 `profile-service.md:182` 自称「**默认值就住在这张表里，是唯一一处**——各写一份必然漂移」——**这句唯一性断言按字面为假**。
- 同族第三例（同文件内）：`StatusFields` 的取值域在 `architecture.md:421-425` 的表里一份、`:544` 的正文里又用散文复述一份（`[-2,2]` / `[0,3]` / `[0,∞)`）。

**建议（三条同一方向）：**
1. `architecture.md` 的 `ResourceElements` 只保留 **`ElementSpec` 类型声明 + 一行「逐行取值见 `profile-service.md`」**，删去 15 行注释值。这与它自己 `:554` 的委派一致，也是「定义在最小公共祖先、投影不复述定义」的直接应用。
2. `SettingFields` 同款：默认值只留在 `profile-service.md`（它自称是唯一一处，就让这句话成真）；`architecture.md` 与 `game-setting.md` 只留字段名 + 回链。
3. `architecture.md:544` 删去散文里重复的三个区间，改为指回同文件的表。

> **可预见的反对意见与回应：** 「上游带着值读起来方便」。但本库已经为此付过一次代价（⑤-5 的存在本身），且这三张表**每一张都自称封闭表 + 有启动期断言**——副本不会被断言发现，只会被下一次对账发现。

---

### P-3 🟠 `ResourceElements` 的**列数**在同一份 `architecture.md` 内部三处不一致（计数式表述失真）

`[既有推演]` —— `architecture.md:516` 已明写「同批还要复核散在各处的**计数式表述**（「全表 N 行」「`Status` 前 N 格」一类），它们不会因为删了一行而自动改」。这三条正是该纪律被违反的实例。

| # | 位置 | 声称 | 实际 |
|---|---|---|---|
| a | `architecture.md:554`（两处：「并成同一张表的**五列**」「**五列**合成一张表而非拆成几张」） | 5 列 | **6 列** —— `ElementSpec`（`:388-394`）= `Min, Max, DepletionDefeat, CostModifier, GainModifier, AllowedOps`。同文件 `:514` 与 `profile-service.md:245` / `:302` 均写「六列」 |
| b | `architecture.md:560`（「**五列**没有一列是平衡旋钮——`Min` 是取值域、`DepletionDefeat` 是终态语义、两个修正列是……准入」） | 5 列，且散文只点名 4 列 | **6 列**；`Max` 与 `AllowedOps` 在计数与列举中双双缺席 |
| c | `architecture.md:475`（「**前三项** = 资源触底，由 `ResourceElements` 表驱动判定；`FinaleFailed` = 篇章闸门，走显式旁路」） | 前 3 项 | `DefeatReason`（`:474`）**共 3 个成员**，「前三项」把被同句排除的 `FinaleFailed` 也框了进去。**自相矛盾**，是四值时代的残留（`ADR-0127:19` 记录了四值 → 三值） |

**建议：** a / b 一律改为「六列」，b 的列举补上 `Max` 与 `AllowedOps`；c 改为「**前两项**」。
**同批附带（严格说超出 `architecture ↔ services` 面，但属同一句话的下游）：** `life-cycle-service.md:16` 写「前两种是资源触底、由资源表驱动判定」——而表中只有 `LifeSpan` 一行带非 null 的 `DepletionDefeat`，`Discarded`（主动弃置）既无 `CostKey` 也无表行，**表驱动的实为 1 项**。建议同批把该句改为「`LifeSpanExhausted` 由资源表驱动；`Discarded` 与 `FinaleFailed` 各走一条显式旁路」。`[子代理发现 · 我未复核 life-cycle-service.md:16 原文]`

---

### P-4 🟠 EventBus 负载表：`PlotThresholdReached` 的第三格字段名三方不齐

`[既有推演]` —— **投影表逐格对账的直接产物。** EventBus 负载契约表（`architecture.md:587-602`，15 行）**其余 12 条逐格一致**（`CycleStarted` / `EventResolved` / `ChapterCompleted` / `CharacterDefeated` / `EventOptionsChanged` / `CapabilitiesChanged` / `AchievementTierReached` / `CombatTurnStarted`·`Ended` / `CombatFeedEntry` 9 格 / `CombatFinished` / `SyncStateChanged` / `ContentUpdateFinished` / `SessionChanged`），零过期登记。唯一分歧在这一条：

| 侧 | 第三格 |
|---|---|
| `architecture.md:594` | `int Threshold` |
| `future-event-service.md:529` | `int Threshold`（「本服务代 PlotManager 广播」） |
| **`plot-manager.md:520`** | **`int BandIndex`** —— 我已复核原文 |

**建议：统一为 `BandIndex`（改上游两处，而非改 `plot-manager.md`）。** 依据两条：① 广播的值实际是**档位序号**而非阈值原始数——`plot-manager.md:390` 的 `PlotCondition.Kind == HiddenStatBand` 参数同样写作 `HiddenStat + BandIndex + 比较向`，`BandIndex` 是该分片的既有词；② `Threshold` 会让订阅者以为拿到的是隐藏属性的原始阈值，而档位边界配置住在别处——**这是一个会误导消费方的名字，不只是不一致**。

**同批附带（🔵 待核实，不建议现在处置）：** `plot-manager.md:520` 同句还写着「**分支揭示 / 选择、key point 推进同样由宿主服务代为广播**」，但**未给出事件名与负载**，`architecture.md` 的 15 行表中亦无对应行。它究竟是不是 EventBus 事件、叫什么、负载几格——**下游没写，无从对账**。建议在补 `PlotThresholdReached` 的同批**只登记一条待答**（「plot 分支揭示 / key point 推进是否走 EventBus，若走则事件名与负载为何」），**不臆造事件名**。

---

### L-8 🟠 服务 ↔ manager 表：`profile-service` 少登记两项，且其一的层级词不合词表

`[既有推演]`

服务 ↔ manager 表（`architecture.md:53-61`，7 行）与 `services/_index.md:46-52` **逐行一致**（服务名 / 判据编号 ③③②③②①①① / manager 名单），六个服务与各自文档自述**亦一致**；`DeckModule` 作为全库唯一 module 实例在六处口径一致。唯一缺口在 profile-service：

- 上游两表（`architecture.md:58` + `services/_index.md:49`）**同时**只写三项：`ProfileManager、CapabilityManager、AchievementManager`。
- 下游 `profile-service.md:344-348` 的「管理器」表共 **5 行**，多出（我已复核原文）：
  - **`CodexManager`**（`:347`）——「图鉴族的收录触发采集、连锁展开与同批去重；写入仍组装 `CodexElements` 交 ProfileManager 单点提交」
  - **`GrantPoolPicker`（`internal`）**（`:348`）——「账号级 / 轮回级能力条目的**唯一抽取处**」；`content-service.md:327` 亦称其为「第二级 `GrantPoolPicker`（profile-service 内 `internal`）」

**建议（两条）：**
1. **两张上游表各补 `CodexManager` 与 `GrantPoolPicker`**，与下游对齐。
2. **`GrantPoolPicker` 的名字不合层级词表 —— 建议改名为 `GrantPoolManager`。** 依据：`architecture.md:24` 与 `terminology.md:107` 同写「**名字的后缀即宣告它在第几层**」，而 `Picker` 不在五个层级词内；`content-service.md:327` 已明确称它「第二级」，第二级的层级词就是 `manager`。**这是词表本身给出的答案，不是取舍**——留一个不带层级后缀的名字在「管理器」表里，正是词表要防的「各处自造词」。
   若评审认为它其实**住在 `ProfileManager` 内部**（而非与之平级），那它就不该占「管理器」表一行——**两种收法都比现状好，评审时二选一**；本草稿推荐第一种（改名保留平级），因为 `content-service.md:327` 已经把它登记为第二级。

---

### L-9 🔵 纪律可执行化四处应用表：**四行全部一致**（登记以免下次重查）

`[既有推演]` —— `architecture.md:640-643` 的四行与下游逐项对应：离线后端 ↔ `system-overview.md:325-330` 的四行手段表（级别 1/1/3/3）· `AllEnabled()` ↔ `content-service.md:309-313` 成员表 + `:317-321` 的 `DrawPool<T>` 排期 + `:410` 的 `[Obsolete(error: true)]` 代码 · EventBus 退订 ↔ `system-overview.md:332` 条件编译清单 + `common-properties.md:119` · `newIds` 双闸 ↔ `content-service.md:42-49` 闸 A/B 表 + `:53` 的发布侧等价第 2 级论证。通用补注（`:628-634`）与 `content-service.md:53` 逐点同构。**无差异，不需处置。** `[子代理逐条核对 · 结论我采信]`

---

### L-1 🟠 `architecture.md` 的 `## 决策(-> ADR)` 台账漏登 **12 条**以本文件为落点的 ADR

`[既有推演]` —— 判据是机械的、可双向核对的：**以 `decisions/_index.md` 的「落点」列为准**。

- `architecture.md:684-696` 现列 **13 条**：ADR-0002 / 0003 / 0004 / 0005 / 0007 / 0008 / 0009 / 0010 / 0011 / 0012 / 0013 / 0014 / 0108。
- `decisions/_index.md` 中把 `systems/architecture.md` 列为落点的共 **21 条**：ADR-0007 / 0008 / 0009 / 0010 / 0011 / 0012 / 0013 / 0014 / **0015** / **0017** / **0063** / **0067** / **0103** / 0108 / **0116** / **0121** / **0122** / **0128** / **0129** / **0130** / **0131**。（我已用 grep 逐条核对 `_index.md`。）
- ⇒ **漏登 12 条**（加粗者）。其中承重正文确实住在 `architecture.md` 的至少有：`ADR-0063`（`ResourceElements`，`:388-416` / `:554`）· `ADR-0067`（三级判据，`:524-540`）· `ADR-0128`（`StatusChanges` 列，`:336` / `:544`）· `ADR-0129`（`HiddenStatGrant` 方向格，`:494-503`）· `ADR-0122`（`ItemElements` / `ItemUseElements` 两列，`:345-346`）· `ADR-0017` / `ADR-0116`（`ModifierKey` / `ModifierEntry` / `ModifierOp`，`:461-464` / `:477-479`）。
- 反向：`architecture.md` 列了 4 条而 `_index.md` 未把本文件列为落点（ADR-0002 / 0003 / 0004 / 0005）。这**不算错**——它们是被引用的上位决策，不是落点。

**建议：** 按 `decisions/_index.md` 的落点列**全量补齐 12 条**，每条一行、只写一句结论 + 链接（台账形态，不复述正文）。**取「全量补齐」而非「只补承重的那几条」**：后者会让「哪些算承重」变成每次新增 ADR 都要重答一遍的问题，而落点列是现成的、双向可机械核对的判据。
**同族缺口（已在 `open-questions.md:66` 登记，此处只作交叉确认）：** `future-event-service.md` 与 `balance.md` 的 `## 决策(-> ADR)` **整节为空**；`content-service.md` 未收录 `ADR-0125` / `ADR-0130`；`life-cycle-service.md` 未收录 `ADR-0127` / `ADR-0128`。ADR-0123~0132 十份在全部主题文档中**零反向引用**（引用只来自 `open-questions` 台账与另外两份 ADR）。这一族**范围大于本对账面**，建议作为一次独立的批量补录，不塞进本次。

---

### L-2 🟡 `sync-service.md` 的 schema bump 清单自称「只有一份」却已漏三批，且与 `character-profile/_index.md` 的第二处 bump 断言互斥

`[通行做法]` —— **已在 `open-questions.md:65` 登记为 🟠 derive 前置**，此处只作**归属确认**：它是否属本对账面。

- 清单位置：`services/sync-service.md:318`（小节「存档 schema 版本」），条目 `:320-339`；`:334` 自陈「**bump 清单只有上表一份**——别处提到「增列 ⇒ bump」指的都是**这同一次**，不构成第二次」。
- 已核实**不在清单内**的四批：`pastItemUse` / `ItemElements` / `ItemUseElements`（`ADR-0122`）· `ProfileChangeSpec.StatusChanges` 列（`ADR-0128`）· `Status` 删 `lifeTotal` / `LifeSpanBand` / `ChapterLifeSpanBudget` 三格（`ADR-0127:19`）· 栈条目 `itemId`（`combat-service.md:306` / `:670`，`ADR-0132`）。
- 互斥断言：`character-profile/_index.md:160`「随 `immortalJade` 落定 **bump schema 版本**」（我已复核原文），而 `spiritStone` / `immortalJade` 在 sync 清单中一处未提。同文件另有 10 余处同形的「随本次落定 bump」自称，均未登记。`[子代理统计 · 我复核了 :160 一处]`
- 对侧 `backend-design-documents/contracts/profile-sync.md:187` 明写「bump 清单的权威在客户端 `sync-service.md`」⇒ **两侧都以为对方在记。** `[子代理转述 · 未复核]`

**归属判断：** 它是 `services/*` **内部**与 `character-profile/` 之间的台账漂移，`architecture.md` 侧的对位只有 `:95`（「schema 版本 + 迁移路径按判据决定谁需要 …… 逐份落点与各自的处置见 `sync-service.md` / `content-service.md` / `account-service.md` / `game-setting.md`」）——**上游的委派本身是正确的、无需改**。故：

**建议：不纳入本对账的修订批次**，按 `open-questions.md:65` 已有的登记，作为 `sync-service.md` derive 前的独立补齐动作处理。本草稿只在此确认「上游 `architecture.md:95` 无需改动」这一点——否则下一次对账还会再问一遍。
**但有一条应纳入：** `character-profile/_index.md` 内那 10 余处「随本次落定 bump」的自称，与 `sync-service.md:334` 的「只有一份」是**结构性互斥**。建议在补齐清单的同批，把 `character-profile/_index.md` 侧的所有 bump 自称改为「计入 `sync-service.md` 的 bump 清单（回链）」，让「唯一清单」这句话重新成真。

---

### L-3 🔵 `plot-manager.md` 与 `life-cycle-service.md` 对「隐藏属性完整清单 / 增减触发」**重复登记同一条待决**

`[通行做法]`

- `life-cycle-service.md:307` 与 `plot-manager.md:538` 各挂一条同内容的待决项。**这是重复而非矛盾**，两者都成立。
- 但按本库「权威唯一」的一贯纪律：该条的权威文档是 `plot-manager.md`（`life-cycle-service.md:307` 自己写着「权威均在 `systems/services/plot-manager.md`」）。

**建议：** `life-cycle-service.md:307` 整条收缩为一句回链（「隐藏属性细节的待决项见 `plot-manager.md` 的 `## 待决问题`」），不再自列条目——与 S-3 的删除同批做，正好该条其余内容也要改。

---

### L-4 🔵 `plot-manager.md` 是一份 **manager 级文档住在 `services/` 下**，这一形态无明文说明

`[通行做法]`

- `services/_index.md:51` 已登记：`[future-event-service](future-event-service.md) ⊃ [plot-manager](plot-manager.md)`——形态由表格的 `⊃` 符号**隐含**表达。
- `architecture.md` 只登记 manager **名**（`:60` 的「EventOptionManager、PlotManager」与 `:692` 的 `ADR-0014`），**全文零次引用 `services/plot-manager.md` 这份文件**。（我已复核。）
- 但 `architecture.md` 对 `combat-service.md` 同样零链接——**它本就不负责逐份索引服务文档**，那是 `services/_index.md` 的职责。

**建议：`architecture.md` 侧不动**（补链接反而制造第二份索引，撞投影纪律）。**只在 `services/_index.md` 的层级小节补一句**：「manager 级文档在内容量足够时可单列一份，仍住在 `services/` 下并由宿主服务行的 `⊃` 表达归属（现有唯一实例：`plot-manager.md`）」——把隐含形态写成明文，成本一句话，收益是下一个想拆 manager 文档的人不必重新发明规则。

---

### L-5 🔵 三处留口经核实**仍是真留口**，不需处置（登记以免下次重查）

`[既有推演]` —— 对账必须包含「查了，没问题」的部分，否则下一次对账会把同样的三处再查一遍。

| 位置 | 留口 | 核实结论 |
|---|---|---|
| `architecture.md:425` | `⟨其余 Status 规则字段随各自专场逐条补⟩` | **仍是真留口**。当前 4 行与 `character-profile/_index.md:153-156` 的 `Status` 子表中 `StatusChanges` 通道的 4 格**逐行对齐**（我已复核）；`profile-service.md:123-127` 亦为同 4 个。无下游增量 |
| `architecture.md:456` | `enum StatusKey { … /* ⟨随各专场逐条补⟩ */ }` | 与 `:425` 同一件事，同结论 |
| `architecture.md:461` | `enum ModifierKey { LifeSpanCost, ShopPrice, /* ⟨待定：其余具名修正⟩ */ }` | **仍是真留口**。全库 `ModifierKey.*` 实际只出现这两个成员 `[子代理全库检索 · 我未复核]` |

**建议：三处原样保留**，但在 `:425` / `:456` 各加半句锚定：「当前四行与 `character-profile/_index.md` 的 `Status` 子表 `StatusChanges` 通道逐行对齐，新增须同批」——把「留口」与「当前已对齐」两件事分开写，下次对账可一眼确认。

---

### L-6 🔵 回链存在性：**零悬空**

`[既有推演]` —— `architecture.md` 引用的全部文档路径（13 个 ADR、38 个 handoff、`systems/*`、`ux/error-and-blocking-ux.md`、`vision/scope.md`、`terminology.md`、`program-overview.md`、`system-overview.md`、`systems/enemies/`）**逐一存在，零悬空**；点名的小节锚点（`sync-service.md`「断线降级」`:76`、「三条不变式」`:102`、「存档 schema 版本」`:318`；`account-service.md`「refresh token 的持有与失效」`:66`；`content-service.md`「flags：`ContentEnabled` 的第三层」`:120` 等）亦逐一存在。`[子代理逐条验证 · 结论我采信]`

一处**弱指向**（不算悬空，只作登记）：`future-event-service.md:539` 的待决项指向 `systems/balance.md` 的 `BaseTypeWeights` 取值，而 `balance.md` 全文零次出现 `BaseTypeWeights`——目标文档在、目标行不在。该项本就标为待定，**建议不处置**，只在 `balance.md` 的相应小节留一个占位行以便日后落值时有落点。

---

### L-7 🔵 三条结构残留的处置已全部兑现（对账的收尾确认）

`[既有推演]` —— ⑤-5 的问题陈述称「三条结构残留里有两条的答案早已写死在下游」。**逐条复查确认那三条现已全部兑现，`architecture.md` 侧无残留**：

| 残留 | 08-19 的处置 | 下游现状 |
|---|---|---|
| 断线降级的具体行为 | 主体已答，push 侧退避补进 `sync-service.md`；`architecture.md` 只留一行导航 | `sync-service.md:96-101` 退避阶梯 + 只向上抖动 + **无放弃阈值** + 挂起期不补偿；`architecture.md:94` 现为纯回链、零复述 ✅ |
| 热更「只改不增」的连带项 | 整条删除、不留替代回链 | `content-service.md:55`（不预埋占位 Id）· `:169-174`（记两个 `contentVersion`）；`architecture.md` 的 `## 待决问题` 确已无该条 ✅ |
| ViewModel 文档落位 | 单列 `systems/viewmodel.md` | 该文件存在，五项契约逐项落地，`## 待决问题` 为空；`architecture.md:103-105` 保留三层定义 + 一句回链 ✅ |

**⇒ ⑤-5 陈述中的那两个历史实例都已闭合；本次对账新发现的是 D-1 · S-1~S-4 · P-1~P-4 · L-1~L-4 · L-8 这一批（另有 L-5 / L-6 / L-9 三组「查过、无问题」的登记）。** 这本身印证了该条的判断：**需要的是周期性的系统性对账，而不是逐次顺手修。**

## 具体形态（可 derive 的落地面）

**无。** 本对账**不产出任何 FR**，也不构成任何 derive 的前置——这与 `architecture.md:722` 的自陈一致。它的落地面是**一批文档修订**：

| 文件 | 改动 | 差异编号 |
|---|---|---|
| `systems/architecture.md` | 层级表第四 / 五级填实例 + 删「暂不落实例」+ `:46` 改陈述 + `:43` 判据 3 措辞（**待 D-1 裁决**） | D-1 |
| 同上 | 删 `:715` 整句 | S-1 |
| 同上 | 删 `:684` 的「待补订 Explore / Travel」 | S-2 |
| 同上 | `:83-88` 补 flags 第三行 + `:691` 括注对齐 | P-1 |
| 同上 | 删 `:399-415` 的 15 行值 + 删 `:432-435` 的默认值 + `:544` 删重复区间，各留回链 | P-2 |
| 同上 | `:554` / `:560` 五列 → 六列（`:560` 补列举）· `:475` 前三项 → 前两项 | P-3 |
| 同上 | `:594` 的 `Threshold` → `BandIndex` | P-4 |
| 同上 | `:58` 服务表补 `CodexManager` / `GrantPoolManager` | L-8 |
| 同上 | `## 决策(-> ADR)` 补 12 条 | L-1 |
| 同上 | `:425` / `:456` 各加半句锚定 | L-5 |
| `systems/services/_index.md` | `:18` 同步第四 / 五级实例；`:49` 补两个 manager；层级小节补一句 manager 级文档的形态说明 | D-1 · L-8 · L-4 |
| `systems/services/future-event-service.md` | `:529` 的 `Threshold` → `BandIndex` | P-4 |
| `systems/services/profile-service.md`（另一处） | `:348` `GrantPoolPicker` → `GrantPoolManager`（或移出管理器表，评审二选一）；`content-service.md:327` 同批改名 | L-8 |
| `systems/services/life-cycle-service.md` | `:307` 删「AdventurePlot 树的数据编码」并收缩为回链；`:16` 改「前两种由表驱动」 | S-3 · L-3 · P-3 |
| `systems/services/profile-service.md` | `:418` 改写或删除（**待评审确认还剩什么**）；`:421` 括注随之简化；`:177-180` 保留为默认值唯一处 | S-4 · P-2 |
| `systems/player-profile/game-setting.md` | `:25-28` 删默认值副本、留回链 | P-2 |
| `systems/character-profile/_index.md` | 10 余处「随本次落定 bump」改为回链 `sync-service.md` 的清单（**与 L-2 的补齐同批**） | L-2 |
| `systems/balance.md` | 补 `BaseTypeWeights` 占位行 | L-6 |

**不在本批次内（明写以免被顺手带走）：** `sync-service.md` bump 清单的补齐（L-2 主体，已有独立登记）· ADR-0123~0132 的全库反向引用补录（L-1 同族，范围更大）· `power/_index.md:60` 的「23 字段表」失真（**越界，见下**）。

## 后果

- **对设计的影响：零。** 除 D-1 外全部是措辞 / 副本 / 台账层面的修订；D-1 的方向 A 也只改一条判据的措辞以承认既成事实，不改变任何已落地的结构。
- **对存档 schema：零。** 本批次不动任何字段面。
- **对后端：零。** 无契约面改动。**唯一的边界提示**：L-2 涉及的 bump 清单，对侧 `profile-sync.md:187` 把权威指回客户端——补齐动作发生时对侧无需改，但**两侧「都以为对方在记」这一状态本身值得在对侧留一条登记**。本草稿**不写对侧库文件**（worker 范围锁死），仅作建议交回。
- **对 derive：零阻塞。** `open-questions.md:88` 判定 `architecture.md` 为 **ready**，本对账不改变该判定。
- **反向收益：** 本批次落笔后，`architecture.md:722` 那条待决项与 `open-questions/05-service-contracts.md:24` 的 ⑤-5 可一并移出并记入 `answer-logs/`。

## 备选方案（已考虑并否决）

- **把差异逐条顺手修掉、不出草稿。** 否决：⑤-5 明确要求「一次系统性对账而非逐次顺手修」；且 D-1 是真设计冲突，顺手修等于替用户拍板。
- **把 `architecture.md` 的全部投影表改成纯回链（一张表都不留）。** 否决：过头。层级表、服务 ↔ manager 表、EventBus 负载表是**结构与边界**本身，正是本文件的职责所在（`:4` 自陈「本文件是结构与边界的权威」）；要删的只是**取值域 / 默认值**这类下游持权威的东西（P-2 三条）。
- **同批把 ADR-0123~0132 的全库反向引用一并补上。** 否决：那是一次覆盖十余份主题文档的批量动作，与本对账的写入面几乎不重叠，混在一起会让两件事都难评审。已在 `open-questions.md:66` 独立登记。
- **为本次对账新开一份 ADR。** 否决：`architecture.md:722` 自陈这是维护动作而非设计决定；D-1 若裁决为方向 A，改的是既有 `ADR-0008` 的措辞——按根约定「要改一份 ADR 的决定，就直接改这份 ADR」。
- **建立一条「每次改 `services/*` 都回头查 `architecture.md`」的评审纪律。** 否决：按 `architecture.md:616` 的可执行化阶梯，这是**第 4 级（评审清单）——零成本、零保证**，而本条的违规症状恰是「一切正常」。周期性对账（本技能这类动作）是更诚实的形态。

## 与既有决策的张力

**一处，即 D-1。**

- 冲突的是 `architecture.md:43` 的 processor 拆分判据第 3 条（「调用入口仍只有**宿主 module** 一个 …… 不越层被 manager 直呼」），其 ADR 载体是 `ADR-0008-service-hierarchy-vocabulary`。
- 需要它松动的原因：下游三份主题文档 + 一份 handoff 已把 `EffectProcessor` 的宿主定为 `StackManager`（manager），且 08-27 handoff 自称与判据对齐——**既成事实与判据字面冲突**。
- 松动的代价：判据 3 从「宿主必须是 module」放宽到「宿主恰一个（manager 或 module）」，理论上使层级链可跳级。
- 不松动的替代：在 `StackManager` 与 `EffectProcessor` 之间补一个 module——但那个 module 只有一个实例、永不变体，正中 `architecture.md:45` 的反判据 ②③。
- **裁决权在用户**，见「仍需用户决定」。

**明确不构成张力的两条（写下来以免被误读为冲突）：**
- `architecture.md:292`「硬阻塞仍然只有两处」 vs `sync-service.md:103`「阻塞点是穷举的四处」——前者限定「**由后端 `code` 触发**」且括注已指向后者，逐字读不矛盾。`[子代理判断 · 我未复核 sync-service.md:103]` 建议评审时顺带确认一眼；若确认无误则**不改**。
- `architecture.md:715` 与 `services/_index.md:76-78` 的措辞差异——后者已是正确形态，前者按 S-1 向它靠拢即可。

## 前置依赖

- **D-1 的裁决是本批次的唯一前置**：它决定 `architecture.md:43` 与 `:32` / `:34` / `:46` 以及 `services/_index.md:18` 四处的最终措辞。其余各条**互不依赖，可与 D-1 并行落笔**。
- **S-4 依赖一次评审确认**（`profile-service.md:418` 到底还剩什么没答）——这不是待答的设计问题，是一次读文档的确认动作，评审时即可完成。
- **L-2 依赖 `sync-service.md` bump 清单的补齐**（已独立登记，不在本批次内）。本批次中属于 L-2 的那一半（`character-profile/_index.md` 的 bump 自称改回链）须与那次补齐同批，**单独做会让「唯一清单」暂时指向一份仍不全的表**。
- 不依赖任何仍待答的设计问题。

## 仍需用户决定 → **已全部裁决（2026-09-02 · 批量评审）**

1. **D-1 —— `EffectProcessor` 的宿主是 manager，与 `architecture.md:43` 判据 3「不越层被 manager 直呼」冲突。改判据，还是改结构？**
   - **选项 A（推荐）—— 改判据 3 的措辞。** 改为「拆出后调用入口仍只有宿主一个（**manager 或 module**）——不产生第二个调用方、不越层被更上层直呼」，同批改 `ADR-0008`。
     **后果：** 三份主题文档 + 一份 handoff 的既定措辞一字不动；层级链从此允许跳过 module 层；`architecture.md:36` 那段「顺着这条轴」的递进叙述需微调一句。
   - **选项 B —— 保留判据 3 原文，在 `StackManager` 与 `EffectProcessor` 之间补一层 module。**
     **后果：** `combat-service.md:346` · `deck/common-properties.md:282` · `item/_index.md:52` 三处的层级链措辞全部改写；造出一个单实例、永不变体的 module。
   - **选项 C —— 判据 3 与下游都不动，只把「无实例」改成有实例，把这条冲突原样留着。**
     **后果：** 零改动成本，但下一次对账会把同一条再报一遍，且第一个照判据 3 拆 processor 的人会拆错。
   - **推荐 A，理由：** `architecture.md:45` 的三条反判据已明写「层数不是成熟度指标——「不封顶在两级」同时也意味着**不封底**」，B 造出的正是它禁止的那种 module（②只被调用一次且无变体 / ③为了让层级看起来更完整）。判据 3 的本意是「**不产生第二个调用方**」，「宿主必须是 module」只是当时唯一存在的形态被写成了通则——改措辞恢复本意，语义一字未松。**但它改的是一条承重判据 + 一份 Accepted 的 ADR，故不替用户拍板。**
   - → **已裁决（2026-09-02 · 批量评审）：选项 A —— 将文档的层级命名方式与承重对齐。** 用户原话：「将文档的层面命名方式与承重对齐。」即以真实承重（`EffectProcessor` 确由 manager 直接持有）为准，改判据 3 的措辞 + 同批改 `ADR-0008`，而**不**为迁就判据去造一层 `architecture.md:45` 反判据 ②③ 所禁止的 module。**同一裁决覆盖 L-8 的命名对齐建议**（`GrantPoolPicker` → `GrantPoolManager`：层级词表应跟着真实承重走）。

---

## 越界发现（不在本分片范围内，只记录不处理）

- **`character-profile/power/_index.md:60`** 写「见 `../_index.md` 的 **23 字段表**」，而 `character-profile/_index.md:116-142` 的该表现为 **25 行**（表头 `:116`，数据行 `:118-142`；第 17 格 `pastItemUse`、第 24/25 格 `startContentVersion` / `lastContentVersion`）。「23 字段」的历史出处是 `answer-logs/log-profile-field-schema.md:7`（当时确为 23 行）。**已在 `open-questions.md:71` 登记**，且属 `character-profile/` 内部而非 `architecture ↔ services` 面。
- **`ADR-0123`~`ADR-0132` 十份 ADR 在全部主题文档中零反向引用**（引用只来自 `open-questions.md` / `update-log.md` 与另外两份 ADR）。`future-event-service.md:533-535` 与 `balance.md:559-561` 的 `## 决策(-> ADR)` **整节为空**。**已在 `open-questions.md:66` 登记**；其中落点为 `architecture.md` 的四条（0128 / 0129 / 0130 / 0131）**已纳入本草稿的 L-1**，其余不属本对账面。
- **`character-profile/_index.md:160` 等 10 余处「随本次落定 bump schema 版本」** 与 `sync-service.md:334`「bump 清单只有上表一份」结构性互斥。**已在 `open-questions.md:65` 登记**；本草稿在 L-2 中只作归属确认（`architecture.md:95` 的委派本身正确、无需改），修订主体不在本批次。
